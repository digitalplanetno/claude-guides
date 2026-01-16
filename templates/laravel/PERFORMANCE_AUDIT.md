# Performance Audit — Laravel Template

## Цель

Комплексный аудит производительности Laravel приложения. Действуй как Senior Performance Engineer.

> **⚠️ Рекомендуемая модель:** Используй **Claude Opus 4.5** (`claude-opus-4-5-20251101`) для проведения аудитов — лучше работает с анализом кода.

---

## 0. QUICK CHECK (5 минут)

| # | Check | Command | Expected |
| --- | ------- | --------- | ---------- |
| 1 | Build | `npm run build` | Success, no warnings |
| 2 | N+1 queries | `grep -rn "->each\|->map" app/Http/Controllers/ \| grep -v "with("` | Минимум |
| 3 | Model::all() | `grep -rn "::all()" app/Http/Controllers/` | Пусто или с пагинацией |
| 4 | Missing indexes | `grep -rn "where(" app/Http/Controllers/ \| grep -v "index"` | Проверить индексы |
| 5 | Job timeouts | `grep -rn "ShouldQueue" app/Jobs/ \| xargs -I{} grep -L "timeout" {}` | Пусто |

---

## 0.1 AUTO-CHECK SCRIPT

```bash
#!/bin/bash
# performance-check.sh

echo "⚡ Performance Quick Check..."

# 1. Build test
npm run build > /tmp/build.log 2>&1
[ $? -eq 0 ] && echo "✅ Build: Success" || echo "❌ Build: Failed"

# 2. N+1 patterns
N_PLUS_1=$(grep -rn "\->each\|->map" app/Http/Controllers/ 2>/dev/null | grep -v "with(" | wc -l)
[ "$N_PLUS_1" -eq 0 ] && echo "✅ N+1: No obvious patterns" || echo "🟡 N+1: Found $N_PLUS_1 potential N+1"

# 3. Model::all() without pagination
ALL_CALLS=$(grep -rn "::all()" app/Http/Controllers/ 2>/dev/null | wc -l)
[ "$ALL_CALLS" -eq 0 ] && echo "✅ all(): No Model::all() in controllers" || echo "❌ all(): Found $ALL_CALLS Model::all() calls"

# 4. Jobs without timeout
JOBS_NO_TIMEOUT=$(find app/Jobs -name "*.php" -exec grep -L 'timeout' {} \; 2>/dev/null | wc -l)
[ "$JOBS_NO_TIMEOUT" -eq 0 ] && echo "✅ Jobs: All jobs have timeout" || echo "🟡 Jobs: $JOBS_NO_TIMEOUT jobs without timeout"

# 5. Missing eager loading in controllers
MISSING_EAGER=$(grep -rn "->get()\|->first()\|->find(" app/Http/Controllers/ 2>/dev/null | grep -v "with(" | wc -l)
echo "ℹ️  Queries without with(): $MISSING_EAGER (check if needed)"

# 6. Config cache status
php artisan config:cache --dry-run 2>/dev/null
[ $? -eq 0 ] && echo "✅ Config: Cacheable" || echo "❌ Config: env() outside config files"

echo "Done!"
```

---

## 0.2 PROJECT SPECIFICS — [Project Name]

**Что уже оптимизировано:**

- [ ] MySQL connection pooling (Laravel default)
- [ ] Redis для очередей и кэша
- [ ] Supervisor для queue workers
- [ ] Vite для сборки фронтенда

**Команды для анализа:**

```bash
# Bundle analysis
npx vite-bundle-visualizer

# Cache status
php artisan cache:status
```

---

## 0.3 SEVERITY LEVELS

| Level | Описание | Действие |
| ------- | ---------- | ---------- |
| CRITICAL | N+1 на главных страницах, memory leaks | Исправить немедленно |
| HIGH | Отсутствующие индексы, jobs без timeout | Исправить до деплоя |
| MEDIUM | Неоптимальные запросы, большой bundle | Следующий спринт |
| LOW | Микрооптимизации | Backlog |

---

## 1. DATABASE PERFORMANCE

### 1.1 N+1 Query Detection

```php
// ❌ N+1 — запрос в каждой итерации
@foreach($sites as $site)
    {{ $site->labels->count() }}  // SELECT * FROM labels WHERE site_id = ?
@endforeach

// ✅ Правильно — eager loading
$sites = Site::with('labels')->get();
// или с подсчётом
$sites = Site::withCount('labels')->get();
```

- [ ] Все `@foreach` с обращением к связям
- [ ] Все `->map()`, `->each()` с обращением к связям
- [ ] Вложенные циклы с DB запросами

### 1.2 Missing Indexes

Проверь индексы на:

- [ ] **Foreign keys** — все `*_id` поля
- [ ] **WHERE поля** — `status`, `type`, `is_active`, `created_at`
- [ ] **ORDER BY поля** — `created_at`, `updated_at`, `sort_order`
- [ ] **Уникальные поля** — `email`, `url`, `slug`
- [ ] **Составные индексы** — для частых комбинаций WHERE

```php
// Пример миграции с правильными индексами
Schema::create('sites', function (Blueprint $table) {
    $table->id();
    $table->string('url')->index();                    // Часто ищем
    $table->string('status')->index();                 // Фильтруем
    $table->foreignId('import_id')->constrained()->index(); // FK
    $table->timestamps();

    // Составной индекс для частого запроса
    $table->index(['status', 'created_at']);
});
```

### 1.3 Query Optimization

```php
// ❌ Плохо — загружает всё
$sites = Site::all();

// ✅ Хорошо — только нужные поля + пагинация
$sites = Site::select(['id', 'url', 'title', 'status'])
    ->paginate(50);

// ❌ Плохо — подсчёт через коллекцию
$count = Site::all()->count();

// ✅ Хорошо — подсчёт на уровне БД
$count = Site::count();

// ❌ Плохо — фильтрация в PHP
$active = Site::all()->filter(fn($s) => $s->status === 'active');

// ✅ Хорошо — фильтрация в SQL
$active = Site::where('status', 'active')->get();
```

- [ ] Нет `Model::all()` для таблиц > 100 записей
- [ ] Нет `->get()` без `->select()` для больших таблиц
- [ ] Нет обработки в PHP того, что можно сделать в SQL

### 1.4 Pagination

- [ ] Все списки > 50 записей используют `->paginate()` или `->cursorPaginate()`
- [ ] API endpoints возвращают пагинированные данные

---

## 2. LARAVEL OPTIMIZATION

### 2.1 Caching Strategy

```php
// ❌ Плохо — запрос при каждом обращении
$settings = Setting::all();

// ✅ Хорошо — кэширование
$settings = Cache::remember('settings', 3600, function () {
    return Setting::all();
});
```

- [ ] Статичные данные кэшируются (настройки, справочники)
- [ ] Тяжёлые вычисления кэшируются
- [ ] Dashboard статистика кэшируется

### 2.2 Eager Loading по умолчанию

```php
class Site extends Model
{
    // Автоматически загружать связи
    protected $with = ['labels', 'import'];
}
```

- [ ] Часто используемые связи в `$with`
- [ ] Нет избыточных связей в `$with`

### 2.3 Config & Route Caching

```bash
php artisan config:cache   # Кэш конфигов
php artisan route:cache    # Кэш роутов
php artisan view:cache     # Кэш views
php artisan event:cache    # Кэш events
composer dump-autoload -o  # Оптимизация autoload
```

- [ ] Команды добавлены в deploy script
- [ ] Нет `env()` вызовов вне config файлов (ломает config:cache)

---

## 3. QUEUE & JOBS OPTIMIZATION

### 3.1 Job Configuration

```php
class ParseSiteJob implements ShouldQueue
{
    public $timeout = 120;           // ✅ Обязательно
    public $tries = 3;               // ✅ Обязательно
    public $backoff = [60, 120, 300]; // ✅ Экспоненциальный backoff
    public $maxExceptions = 3;       // ✅ Лимит исключений

    // ✅ Уникальность — не дублировать одинаковые jobs
    public function uniqueId(): string
    {
        return $this->site->id;
    }

    // ✅ Обработка failed
    public function failed(Throwable $exception): void
    {
        Log::error('Job failed', [
            'site_id' => $this->site->id,
            'error' => $exception->getMessage()
        ]);
    }
}
```

- [ ] Все jobs имеют `$timeout`
- [ ] Все jobs имеют `$tries` и `$backoff`
- [ ] Все jobs имеют `failed()` метод
- [ ] Долгие jobs используют `$uniqueId` против дублирования

### 3.2 Batch Processing

```php
// ❌ Плохо — создаёт 10000 jobs сразу
Site::where('status', 'pending')->each(function ($site) {
    ParseSiteJob::dispatch($site);
});

// ✅ Хорошо — chunk dispatch
Site::where('status', 'pending')
    ->chunk(100, function ($sites) {
        foreach ($sites as $site) {
            ParseSiteJob::dispatch($site)->delay(now()->addSeconds(rand(1, 60)));
        }
    });
```

- [ ] Массовые операции используют `chunk()`
- [ ] Есть delay между jobs для rate limiting

### 3.3 Queue Memory Leaks

```php
// ❌ Memory leak — модель в памяти всё время
class ParseSiteJob implements ShouldQueue
{
    public function __construct(public Site $site) {}
}

// ✅ Лучше — только ID, загрузка при выполнении
class ParseSiteJob implements ShouldQueue
{
    public function __construct(public int $siteId) {}

    public function handle(ParserService $parser): void
    {
        $site = Site::find($this->siteId);
        if (!$site) return;

        $parser->parse($site);
    }
}
```

- [ ] Jobs хранят только ID, не модели целиком

---

## 4. HTTP & EXTERNAL API OPTIMIZATION

### 4.1 HTTP Client Configuration

```php
// ❌ Плохо — нет timeout, может висеть вечно
$response = Http::get($url);

// ✅ Хорошо — полная конфигурация
$response = Http::timeout(30)
    ->connectTimeout(10)
    ->retry(3, 100, function ($exception, $request) {
        return $exception instanceof ConnectionException;
    })
    ->get($url);
```

- [ ] Все внешние запросы имеют `timeout()`
- [ ] Есть `retry()` с разумной логикой
- [ ] Есть `connectTimeout()` отдельно от общего timeout

### 4.2 Concurrent Requests

```php
// ❌ Плохо — последовательно
foreach ($urls as $url) {
    $responses[] = Http::get($url);
}

// ✅ Хорошо — параллельно
$responses = Http::pool(fn (Pool $pool) =>
    collect($urls)->map(fn ($url) =>
        $pool->timeout(30)->get($url)
    )
);
```

- [ ] Где возможно — используются параллельные запросы

---

## 5. FRONTEND OPTIMIZATION

### 5.1 Inertia.js Optimization (если используется)

```php
// ❌ Плохо — передаём всё
return Inertia::render('Sites/Index', [
    'sites' => Site::with('labels', 'import', 'screenshots')->get()
]);

// ✅ Хорошо — только нужные данные
return Inertia::render('Sites/Index', [
    'sites' => Site::select(['id', 'url', 'title', 'status'])
        ->with('labels:id,name,site_id')
        ->paginate(50)
]);

// ✅ Lazy loading props
return Inertia::render('Sites/Show', [
    'site' => $site,
    'statistics' => Inertia::lazy(fn () => $this->getStatistics($site))
]);
```

- [ ] Props содержат только необходимые данные
- [ ] Используется `Inertia::lazy()` для тяжёлых данных
- [ ] Связи загружаются с `select()` нужных полей

### 5.2 Bundle Size

- [ ] JavaScript < 500KB gzipped
- [ ] CSS < 100KB gzipped
- [ ] Code splitting используется
- [ ] Тяжёлые компоненты загружаются лениво

---

## 6. САМОПРОВЕРКА

**Перед добавлением проблемы в отчёт:**

| Вопрос | Если "нет" → исключить из отчёта |
| -------- | ---------------------------------- |
| Это влияет на **runtime**? | Если только на deploy time — не критично |
| **Eager loading** уже есть в модели `$with`? | Проверь модель перед N+1 |
| Это **реально используется** в production paths? | Dev-only код не влияет |
| У меня есть **измеримые данные** о влиянии? | "Может быть медленно" ≠ проблема |
| **Исправление** даст ощутимый эффект? | Микрооптимизации < 50ms не нужны |

---

## 7. ФОРМАТ ОТЧЁТА

```markdown
# Performance Audit Report — [Project Name]
Дата: [дата]

## Summary

| Метрика | До | После | Улучшение |
|---------|-----|-------|-----------|
| Avg page load | Xms | Xms | X% |
| DB queries per page | X | X | X% |
| Bundle size | XKB | XKB | X% |

## CRITICAL Issues

| # | Проблема | Файл:строка | Влияние | Решение |
|---|----------|-------------|---------|---------|
| 1 | N+1 в SiteController@index | app/.../SiteController.php:45 | ~500ms | Добавить `with('labels')` |

## HIGH — N+1 Queries найдены

| Controller | Method | Связь | Решение |
|------------|--------|-------|---------|
| SiteController | index | labels | `Site::with('labels')` |

## MEDIUM — Отсутствующие индексы

| Таблица | Поле | Тип запроса | Миграция |
|---------|------|-------------|----------|
| sites | status | WHERE | `$table->index('status')` |
```

---

## 8. ДЕЙСТВИЯ

1. **Запусти Quick Check** — 5 минут
2. **Просканируй проект** — собери все проблемы
3. **Самопроверка** — отфильтруй ложные срабатывания
4. **Приоритизируй** — критические, важные, рекомендации
5. **Измерь** — по возможности, укажи влияние
6. **Предложи** — конкретные исправления с кодом

Начни аудит. Сначала покажи summary найденных проблем.
