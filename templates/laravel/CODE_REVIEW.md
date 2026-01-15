# Code Review — Laravel Template

## Цель

Комплексный code review Laravel приложения. Действуй как Senior Tech Lead.

---

## 0. QUICK CHECK (5 минут)

| # | Check | Command | Expected |
|---|-------|---------|----------|
| 1 | PHP Syntax | `php -l app/**/*.php` | No errors |
| 2 | Pint (style) | `./vendor/bin/pint --test` | No changes |
| 3 | PHPStan | `./vendor/bin/phpstan analyse` | Level OK |
| 4 | Build | `npm run build` | Success |
| 5 | Tests | `php artisan test` | Pass |

---

## 0.1 AUTO-CHECK SCRIPT

```bash
#!/bin/bash
# code-check.sh

echo "📝 Code Quality Check..."

# 1. PHP Syntax
php -l app/**/*.php 2>&1 | grep -q "error" && echo "❌ PHP Syntax errors" || echo "✅ PHP Syntax"

# 2. Pint
./vendor/bin/pint --test > /dev/null 2>&1 && echo "✅ Pint" || echo "🟡 Pint: needs formatting"

# 3. Build
npm run build > /dev/null 2>&1 && echo "✅ Build" || echo "❌ Build failed"

# 4. God classes (>300 lines)
GOD_CLASSES=$(find app -name "*.php" -exec wc -l {} \; | awk '$1 > 300 {print $2}' | wc -l)
[ "$GOD_CLASSES" -eq 0 ] && echo "✅ No god classes" || echo "🟡 God classes: $GOD_CLASSES files >300 lines"

# 5. TODO/FIXME
TODOS=$(grep -rn "TODO\|FIXME" app/ resources/js/ --include="*.php" --include="*.vue" --include="*.js" 2>/dev/null | wc -l)
echo "ℹ️  TODO/FIXME: $TODOS comments"

# 6. dd() / dump() left in code
DD_CALLS=$(grep -rn "dd(\|dump(" app/ --include="*.php" 2>/dev/null | wc -l)
[ "$DD_CALLS" -eq 0 ] && echo "✅ No dd()/dump()" || echo "❌ dd()/dump(): $DD_CALLS calls found"

# 7. console.log in Vue
CONSOLE=$(grep -rn "console.log" resources/js/ --include="*.vue" --include="*.js" 2>/dev/null | wc -l)
[ "$CONSOLE" -lt 10 ] && echo "✅ console.log: $CONSOLE" || echo "🟡 console.log: $CONSOLE (много)"

echo "Done!"
```text

---

## 0.2 PROJECT SPECIFICS — [Project Name]

**Принятые решения (не нужно исправлять):**

- [Осознанные architectural decisions]

**Ключевые файлы для review:**

- `app/Services/` — бизнес-логика
- `app/Http/Controllers/` — должны быть тонкими
- `resources/js/Pages/` — Inertia страницы (если используется)
- `app/Jobs/` — фоновые задачи

**Паттерны проекта:**

- FormRequest для валидации
- Services для бизнес-логики
- Jobs для долгих операций

---

## 0.3 SEVERITY LEVELS

| Level | Описание | Действие |
|-------|----------|----------|
| CRITICAL | Баг, security issue, data loss | **БЛОКЕР** — исправить сейчас |
| HIGH | Серьёзная проблема в логике | Исправить до merge |
| MEDIUM | Code smell, maintainability | Исправить в этом PR |
| LOW | Style, nice-to-have | Можно отложить |

---

## 1. SCOPE REVIEW

### 1.1 Определи scope проверки

```bash
# Последние изменения
git diff --name-only HEAD~5

# Незакоммиченные изменения
git status --short
```text

- [ ] Какие файлы изменены
- [ ] Какие новые файлы созданы
- [ ] Связь изменений между собой

### 1.2 Категоризация

- [ ] Controllers (app/Http/Controllers/*)
- [ ] Services (app/Services/*)
- [ ] Models (app/Models/*)
- [ ] Jobs (app/Jobs/*)
- [ ] Migrations (database/migrations/*)
- [ ] Config (config/*)
- [ ] Routes (routes/*)

---

## 2. ARCHITECTURE & STRUCTURE

### 2.1 Single Responsibility Principle

```php
// ❌ Плохо — Controller делает всё
class SiteController extends Controller
{
    public function store(Request $request)
    {
        // Валидация здесь
        $validated = $request->validate([...]);

        // Бизнес-логика здесь
        $html = Http::get($validated['url'])->body();
        preg_match('/<title>(.*?)<\/title>/', $html, $matches);
        $title = $matches[1] ?? null;

        // Сохранение здесь
        $site = Site::create([...]);

        // Отправка уведомления здесь
        Mail::to($request->user())->send(new SiteCreated($site));

        return redirect()->route('sites.show', $site);
    }
}

// ✅ Хорошо — Controller только координирует
class SiteController extends Controller
{
    public function store(StoreSiteRequest $request, SiteService $service)
    {
        $site = $service->create($request->validated());
        return redirect()->route('sites.show', $site);
    }
}
```text

- [ ] Controllers < 100 строк
- [ ] Методы контроллеров < 20 строк
- [ ] Бизнес-логика в Services, не в Controllers
- [ ] Валидация в FormRequest, не в Controller

### 2.2 Dependency Injection

```php
// ❌ Плохо — хардкод зависимостей
class ParserService
{
    public function parse(string $url): array
    {
        $client = new GuzzleHttp\Client(); // Хардкод
        $response = $client->get($url);
    }
}

// ✅ Хорошо — DI через конструктор
class ParserService
{
    public function __construct(
        private ClientInterface $client
    ) {}

    public function parse(string $url): array
    {
        $response = $this->client->get($url);
    }
}
```text

- [ ] Зависимости инжектятся через конструктор
- [ ] Нет `new ClassName()` внутри методов (кроме DTO)
- [ ] Нет статических вызовов сервисов

### 2.3 Правильное расположение файлов

```text
app/
├── Http/
│   ├── Controllers/        // Только routing
│   └── Requests/           // Валидация
├── Services/               // Бизнес-логика
├── Models/                 // Только Eloquent
├── Jobs/                   // Фоновые задачи
├── DTOs/                   // Data Transfer Objects
└── Enums/                  // Перечисления
```text

- [ ] Файлы в правильных директориях
- [ ] Нет God-классов (> 300 строк)
- [ ] Логика вынесена из Models

---

## 3. CODE QUALITY

### 3.1 Naming Conventions

```php
// ❌ Плохо — непонятные имена
$d = Site::find($id);
$res = $this->proc($d);

// ✅ Хорошо — говорящие имена
$site = Site::find($siteId);
$parsedData = $this->parseContent($site);
```text

- [ ] **Переменные** — существительные, camelCase: `$siteUrl`, `$parsedContent`
- [ ] **Методы** — глаголы, camelCase: `getSite()`, `parseContent()`
- [ ] **Классы** — существительные, PascalCase: `SiteService`, `ParsedResult`
- [ ] **Boolean** — is/has/can/should: `$isActive`, `$hasLabels`

### 3.2 Method Length & Complexity

```php
// ❌ Плохо — длинный метод с высокой вложенностью
public function process(array $data): array
{
    foreach ($data as $item) {
        if ($item['type'] === 'site') {
            if ($item['status'] === 'active') {
                if (!empty($item['url'])) {
                    // глубокая вложенность...
                }
            }
        }
    }
}

// ✅ Хорошо — разбито на методы, early returns
public function process(array $data): array
{
    return collect($data)
        ->filter(fn($item) => $this->shouldProcess($item))
        ->mapWithKeys(fn($item) => $this->processItem($item))
        ->filter()
        ->toArray();
}

private function shouldProcess(array $item): bool
{
    return $item['type'] === 'site'
        && $item['status'] === 'active'
        && !empty($item['url']);
}
```text

- [ ] Методы < 20 строк (идеально < 10)
- [ ] Вложенность < 3 уровней
- [ ] Используются early returns

### 3.3 DRY (Don't Repeat Yourself)

```php
// ❌ Плохо — дублирование
$active = Site::where('status', 'active')
    ->where('user_id', auth()->id())
    ->orderBy('created_at', 'desc')
    ->get();

$pending = Site::where('status', 'pending')
    ->where('user_id', auth()->id())
    ->orderBy('created_at', 'desc')
    ->get();

// ✅ Хорошо — scope в модели
class Site extends Model
{
    public function scopeForUser($query, ?User $user = null)
    {
        return $query->where('user_id', ($user ?? auth()->user())->id);
    }

    public function scopeStatus($query, string $status)
    {
        return $query->where('status', $status);
    }
}

// Использование
$active = Site::forUser()->status('active')->latest()->get();
```text

- [ ] Нет copy-paste кода
- [ ] Повторяющиеся запросы вынесены в scopes

### 3.4 Type Safety

```php
// ❌ Плохо — нет типизации
function process($data) {
    $result = [];
}

// ✅ Хорошо — полная типизация
declare(strict_types=1);

public function process(array $sites, ?ParserOptions $options = null): ProcessedResult
{
}
```text

- [ ] Все методы имеют return type
- [ ] Параметры типизированы
- [ ] Nullable типы явно указаны (`?string`, `?int`)

---

## 4. LARAVEL BEST PRACTICES

### 4.1 Eloquent Usage

```php
// ❌ Плохо
$site = Site::where('id', $id)->first();
$sites = Site::all()->where('status', 'active');
$count = Site::get()->count();

// ✅ Хорошо
$site = Site::find($id);
$sites = Site::where('status', 'active')->get();
$count = Site::count();
```text

- [ ] Используется `find()` вместо `where('id', $id)->first()`
- [ ] Используется `findOrFail()` когда запись должна существовать
- [ ] Фильтрация в Query Builder, не в Collection

### 4.2 Request Validation

```php
// ❌ Плохо — валидация в контроллере
public function store(Request $request)
{
    $request->validate([
        'url' => 'required|url|max:255',
    ]);
}

// ✅ Хорошо — FormRequest
class StoreSiteRequest extends FormRequest
{
    public function rules(): array
    {
        return [
            'url' => ['required', 'url', 'max:255'],
            'labels' => ['array'],
            'labels.*' => ['exists:labels,id'],
        ];
    }

    public function messages(): array
    {
        return [
            'url.required' => 'URL сайта обязателен',
        ];
    }
}
```text

- [ ] Валидация в FormRequest классах
- [ ] Кастомные сообщения об ошибках
- [ ] `authorize()` проверяет права доступа

### 4.3 Config & Environment

```php
// ❌ Плохо — env() в коде
class ScreenshotService
{
    public function capture(string $url): string
    {
        $apiKey = env('SCREENSHOT_API_KEY'); // Сломает config:cache!
    }
}

// ✅ Хорошо — через config
// config/services.php
'screenshot' => [
    'api_key' => env('SCREENSHOT_API_KEY'),
],

// В сервисе
$this->apiKey = config('services.screenshot.api_key');
```text

- [ ] `env()` только в config файлах
- [ ] Все настройки через `config()`

---

## 5. ERROR HANDLING

### 5.1 Exception Handling

```php
// ❌ Плохо — глушение ошибок
try {
    $result = $this->parse($url);
} catch (Exception $e) {
    // Тишина...
}

// ✅ Хорошо — специфичные exceptions с логированием
try {
    $result = $this->parser->parse($url);
} catch (ConnectionException $e) {
    Log::warning('Failed to connect', [
        'url' => $url,
        'error' => $e->getMessage()
    ]);
    throw new SiteUnreachableException($url, $e);
}
```text

- [ ] Специфичные exception типы
- [ ] Логирование с контекстом
- [ ] Нет пустых catch блоков

### 5.2 User-Facing Errors

```php
// ❌ Плохо — технические ошибки пользователю
return response()->json([
    'error' => $e->getMessage() // "SQLSTATE[23000]..."
], 500);

// ✅ Хорошо — понятные сообщения
if ($e instanceof SiteUnreachableException) {
    return back()->with('error', 'Не удалось подключиться к сайту.');
}
```text

- [ ] Пользователь видит понятные сообщения
- [ ] Технические детали только в логах

---

## 6. SECURITY & PERFORMANCE CHECK

### 6.1 Security Quick Check

- [ ] Нет SQL injection (raw queries без биндингов)
- [ ] Нет XSS (v-html с user data, {!! !!})
- [ ] Нет mass assignment уязвимостей
- [ ] Авторизация проверяется
- [ ] Нет dd()/dump() в production коде

### 6.2 Performance Quick Check

- [ ] Нет N+1 queries
- [ ] Eager loading используется
- [ ] Пагинация для списков
- [ ] Тяжёлые операции в queue

---

## 7. САМОПРОВЕРКА

**Перед добавлением проблемы в отчёт:**

| Вопрос | Если "нет" → не включай |
|--------|-------------------------|
| Это влияет на **работоспособность** или **maintainability**? | Косметика не критична |
| **Исправление принесёт пользу** разработчикам/пользователям? | Рефакторинг ради рефакторинга — пустая трата |
| Это **нарушение** принятых в проекте conventions? | Проверь существующие паттерны |
| **Стоит ли время** на исправление? | 5 минут фикса vs 1 час ревью |

**НЕ включай в отчёт:**

| Кажется проблемой | Почему может не быть |
|-------------------|---------------------|
| "Нет комментариев" | Код может быть self-documenting |
| "Длинный файл" | Если логически связан — нормально |
| "Можно было бы лучше" | Без конкретики это не actionable |
| "Service большой" | Если логика связана — это нормально |

---

## 8. ФОРМАТ ОТЧЁТА

```markdown
# Code Review Report — [Project Name]
Дата: [дата]
Scope: [какие файлы/коммиты проверены]

## Summary

| Категория | Проблем | Критичных |
|-----------|---------|-----------|
| Architecture | X | X |
| Code Quality | X | X |
| Laravel | X | X |
| Security | X | X |
| Performance | X | X |

## CRITICAL Issues

| # | Файл | Строка | Проблема | Решение |
|---|------|--------|----------|---------|
| 1 | SiteController.php | 45 | 200 строк бизнес-логики | Вынести в SiteService |

## Code Suggestions

### 1. SiteController — вынести логику

```php
// Было (app/Http/Controllers/SiteController.php:45-120)
public function store(Request $request) {
    // 75 строк...
}

// Стало
public function store(StoreSiteRequest $request, SiteService $service) {
    $site = $service->create($request->validated());
    return redirect()->route('sites.show', $site);
}
```text

## Good Practices Found

- [Что хорошо]

```text

---

## 9. ДЕЙСТВИЯ

1. **Запусти Quick Check** — 5 минут
2. **Определи scope** — какие файлы проверять
3. **Пройди по категориям** — Architecture, Code Quality, Laravel
4. **Самопроверка** — отфильтруй ложные срабатывания
5. **Приоритизируй** — Critical → High → Medium
6. **Покажи fixes** — конкретный код до/после

Начни code review. Покажи scope и summary первым.
