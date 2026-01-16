# Security Audit — Laravel Template

## Цель

Комплексный аудит безопасности Laravel приложения. Действуй как Senior Security Engineer.

> **⚠️ Рекомендуемая модель:** Используй **Claude Opus 4.5** (`claude-opus-4-5-20251101`) для проведения аудитов — лучше работает с анализом кода.

---

## 0. QUICK CHECK (5 минут)

**Перед полным аудитом — пройди эти критические пункты:**

| # | Check | Command | Expected |
| --- | ------- | --------- | ---------- |
| 1 | Debug mode | `grep "APP_DEBUG" .env` | `false` в production |
| 2 | Secrets в коде | `grep -rn "sk-\|password.*=.*['\"]" app/ --include="*.php"` | Пусто |
| 3 | $guarded = [] | `grep -rn 'guarded.*=.*\[\]' app/Models/` | Пусто |
| 4 | Raw SQL injection | `grep -rn 'DB::raw\|whereRaw' app/ --include="*.php"` | Проверить биндинги |
| 5 | composer audit | `composer audit` | No vulnerabilities |

Если все 5 = OK → Базовый уровень безопасности OK.

---

## 0.1 AUTO-CHECK SCRIPT

```bash
#!/bin/bash
# security-check.sh — запусти для автоматической проверки

echo "🔐 Security Quick Check — Laravel..."

# 1. Debug mode
DEBUG=$(grep "APP_DEBUG=true" .env 2>/dev/null)
[ -z "$DEBUG" ] && echo "✅ Debug: APP_DEBUG=false" || echo "❌ Debug: APP_DEBUG=true в production!"

# 2. Hardcoded secrets
SECRETS=$(grep -rn "sk-\|api_key.*=.*['\"][a-zA-Z0-9]" app/ config/ --include="*.php" 2>/dev/null | grep -v ".env\|config(")
[ -z "$SECRETS" ] && echo "✅ Secrets: No hardcoded keys" || echo "❌ Secrets: Found hardcoded keys!"

# 3. Mass assignment vulnerability
GUARDED=$(grep -rn 'guarded\s*=\s*\[\]' app/Models/ 2>/dev/null)
[ -z "$GUARDED" ] && echo "✅ Models: No \$guarded = []" || echo "❌ Models: Found \$guarded = [] (mass assignment risk)"

# 4. Raw SQL patterns (need manual review)
RAW_SQL=$(grep -rn 'DB::raw\|whereRaw\|selectRaw\|orderByRaw' app/ --include="*.php" 2>/dev/null | wc -l)
[ "$RAW_SQL" -eq 0 ] && echo "✅ SQL: No raw queries" || echo "🟡 SQL: Found $RAW_SQL raw queries (verify bindings)"

# 5. CSRF exceptions
CSRF=$(grep -A5 'except' app/Http/Middleware/VerifyCsrfToken.php 2>/dev/null | grep -v "^--$")
echo "ℹ️  CSRF exceptions (verify webhooks only):"
echo "$CSRF"

# 6. composer audit
composer audit 2>/dev/null | grep -q "No security" && echo "✅ Composer: No vulnerabilities" || echo "❌ Composer: Run 'composer audit' for details"

# 7. npm audit
npm audit --production 2>/dev/null | grep -q "found 0" && echo "✅ NPM: No vulnerabilities" || echo "🟡 NPM: Run 'npm audit' for details"

echo "Done!"
```

---

## 0.2 PROJECT SPECIFICS — [Project Name]

**Заполни перед аудитом:**

**Что уже реализовано:**

- [ ] Authentication mechanism: [Laravel Sanctum / Breeze / Jetstream]
- [ ] Authorization: [Policies / Gates / Middleware]
- [ ] Input validation: [FormRequest classes]
- [ ] CSRF protection: [автоматически в web routes]

**Публичные endpoints (by design):**

- `/api/health` — health check
- `/webhooks/*` — webhooks (проверь signature!)

---

## 0.3 SEVERITY LEVELS

| Level | Описание | Действие |
| ------- | ---------- | ---------- |
| 🔴 CRITICAL | Эксплуатируемая уязвимость: SQLi, RCE, auth bypass | **БЛОКЕР** — исправить немедленно |
| 🟠 HIGH | Серьёзная уязвимость, требует auth или сложной эксплуатации | Исправить до деплоя |
| 🟡 MEDIUM | Потенциальная уязвимость, низкий риск | Исправить в ближайшем спринте |
| 🔵 LOW | Best practice, defense in depth | Backlog |
| ⚪ INFO | Информация, не требует действий | — |

---

## 1. SQL INJECTION

### 1.1 Raw Queries

```bash
# Поиск потенциально опасных паттернов
grep -rn "DB::raw" app/
grep -rn "DB::select" app/
grep -rn "whereRaw\|selectRaw\|orderByRaw\|havingRaw" app/
```

```php
// ❌ КРИТИЧНО — SQL Injection
DB::select("SELECT * FROM sites WHERE url = '$url'");
DB::raw("WHERE status = $status");
Site::whereRaw("url LIKE '%$search%'");
Site::orderByRaw($request->sort); // Пользователь контролирует ORDER BY!

// ✅ Безопасно — параметризованные запросы
DB::select("SELECT * FROM sites WHERE url = ?", [$url]);
Site::whereRaw("url LIKE ?", ["%{$search}%"]);
Site::orderByRaw("FIELD(status, ?, ?, ?)", ['active', 'pending', 'error']);

// ✅ Ещё лучше — Query Builder
Site::where('url', $url)->get();
Site::where('url', 'like', "%{$search}%")->get();
```

- [ ] Все `DB::raw()` используют биндинги
- [ ] Все `whereRaw()` используют биндинги
- [ ] Пользовательский ввод НИКОГДА не конкатенируется в SQL
- [ ] `orderBy`, `groupBy` не принимают raw user input

### 1.2 Dynamic Column/Table Names

```php
// ❌ КРИТИЧНО — пользователь контролирует имя колонки
$column = $request->input('sort_by');
Site::orderBy($column)->get();

// ✅ Безопасно — whitelist
$allowed = ['created_at', 'url', 'title', 'status'];
$column = in_array($request->sort_by, $allowed) ? $request->sort_by : 'created_at';
Site::orderBy($column)->get();
```

- [ ] Имена колонок валидируются через whitelist
- [ ] Имена таблиц никогда не из user input

---

## 2. CROSS-SITE SCRIPTING (XSS)

### 2.1 Laravel Blade

```bash
# Найти опасные паттерны
grep -rn "{!!" resources/views/
grep -rn "@php" resources/views/
```

```php
// ❌ КРИТИЧНО — XSS
{!! $site->description !!}
{!! $userComment !!}

// ✅ Безопасно — автоэкранирование
{{ $site->description }}

// ✅ Если нужен HTML — санитизация
{!! clean($site->description) !!}  // С HTML Purifier
{!! Str::markdown($site->description) !!}
```

- [ ] Нет `{!! !!}` с пользовательскими данными
- [ ] Если `{!! !!}` необходим — данные санитизированы

### 2.2 Vue / Inertia (если используется)

```bash
grep -rn "v-html" resources/js/
```

```vue
// ❌ КРИТИЧНО — XSS
<div v-html="site.description"></div>

// ✅ Безопасно — текст
<div>{{ site.description }}</div>

// ✅ Если нужен HTML — DOMPurify
import DOMPurify from 'dompurify'
<div v-html="DOMPurify.sanitize(site.description)"></div>
```

- [ ] Нет `v-html` с user-controlled данными
- [ ] Если `v-html` необходим — используется DOMPurify

---

## 3. CSRF PROTECTION

### 3.1 Forms & Routes

```php
// Проверь VerifyCsrfToken middleware
// ❌ Плохо — отключен CSRF
protected $except = [
    'api/*',        // Весь API без CSRF!
];

// ✅ Хорошо — только webhooks
protected $except = [
    'webhooks/stripe',  // Только webhook с signature verification
];
```

- [ ] `VerifyCsrfToken::$except` содержит только webhooks
- [ ] Webhooks проверяют signature
- [ ] Нет `withoutMiddleware('csrf')` на web routes

---

## 4. MASS ASSIGNMENT

### 4.1 Model Protection

```bash
grep -rn "guarded\s*=\s*\[\]" app/Models/
grep -rn "fillable" app/Models/
```

```php
// ❌ КРИТИЧНО — всё разрешено
class Site extends Model
{
    protected $guarded = [];  // Любое поле можно изменить!
}

// ❌ Плохо — sensitive поля в fillable
class User extends Model
{
    protected $fillable = [
        'name', 'email', 'password',
        'is_admin',     // ОПАСНО!
        'role',         // ОПАСНО!
    ];
}

// ✅ Хорошо — только безопасные поля
class Site extends Model
{
    protected $fillable = [
        'url',
        'title',
        'description',
        'status',
    ];
}
```

- [ ] Нет `$guarded = []` в production моделях
- [ ] `$fillable` не содержит sensitive поля (role, is_admin, etc.)

### 4.2 Controller Validation

```php
// ❌ Плохо — передача всего request
Site::create($request->all());

// ✅ Хорошо — только validated данные
Site::create($request->validated());
```

- [ ] Используется `$request->validated()` или `$request->only()`
- [ ] Нет `$request->all()` в create/update

---

## 5. AUTHENTICATION

### 5.1 Password Security

```php
// Проверь config/hashing.php
// ✅ Должно быть bcrypt или argon2
'driver' => 'bcrypt',
'bcrypt' => [
    'rounds' => 12,  // Минимум 10, рекомендуется 12
],
```

- [ ] Пароли хэшируются через `Hash::make()` или cast
- [ ] Bcrypt rounds >= 10
- [ ] Нет plain text паролей в БД или логах

### 5.2 Session Security

```php
// config/session.php
return [
    'secure' => env('SESSION_SECURE_COOKIE', true),  // ✅ HTTPS only
    'http_only' => true,         // ✅ Недоступно из JS
    'same_site' => 'lax',        // ✅ Защита от CSRF
];
```

- [ ] `SESSION_SECURE_COOKIE=true` в production
- [ ] `http_only` = true
- [ ] `same_site` = 'lax' или 'strict'

### 5.3 Rate Limiting

```php
// ❌ Плохо — нет rate limiting на login
Route::post('/login', [AuthController::class, 'login']);

// ✅ Хорошо — throttle
Route::post('/login', [AuthController::class, 'login'])
    ->middleware('throttle:5,1');  // 5 попыток в минуту
```

- [ ] Login endpoint имеет rate limiting
- [ ] Password reset имеет rate limiting
- [ ] API endpoints имеют rate limiting

---

## 6. AUTHORIZATION

### 6.1 Policy Implementation

```php
// ❌ КРИТИЧНО — нет проверки владельца
public function update(Request $request, Site $site)
{
    $site->update($request->validated());  // Кто угодно может редактировать!
}

// ✅ Хорошо — Policy
public function update(UpdateSiteRequest $request, Site $site)
{
    $this->authorize('update', $site);
    $site->update($request->validated());
}
```

- [ ] Все update/delete операции проверяют ownership
- [ ] Policies зарегистрированы в AuthServiceProvider
- [ ] `$this->authorize()` используется в контроллерах

---

## 7. FILE UPLOAD SECURITY

### 7.1 Validation

```php
// ❌ Плохо — недостаточная валидация
$request->validate([
    'file' => 'required|file',  // Любой файл!
]);

// ✅ Хорошо — строгая валидация
$request->validate([
    'file' => [
        'required',
        'file',
        'mimes:jpg,jpeg,png,pdf,csv,txt',  // Только разрешённые типы
        'max:10240',                        // Максимум 10MB
    ],
]);
```

- [ ] Все uploads валидируют `mimes`
- [ ] Установлен `max` размер

### 7.2 Storage Security

```php
// ❌ КРИТИЧНО — оригинальное имя файла
$path = $request->file('file')->storeAs('uploads', $request->file('file')->getClientOriginalName());
// Имя файла: "../../../config/app.php" = path traversal!

// ✅ Хорошо — безопасное имя
$path = $request->file('file')->store('uploads');  // Авто-генерация имени
```

- [ ] Никогда не используется `getClientOriginalName()` для хранения
- [ ] Файлы хранятся с UUID/hash именами
- [ ] Нет path traversal (`../`)

---

## 8. API SECURITY

### 8.1 API Response Filtering

```php
// ❌ Плохо — возврат всей модели
return response()->json($site);  // Включает все поля!

// ✅ Хорошо — Resource
return new SiteResource($site);
```

- [ ] Используются API Resources
- [ ] Sensitive поля не возвращаются
- [ ] Модели имеют `$hidden` для sensitive полей

### 8.2 CORS Configuration

```php
// config/cors.php
return [
    'allowed_origins' => [
        env('FRONTEND_URL'),
        // ❌ НЕ использовать '*' в production!
    ],
    'supports_credentials' => true,
];
```

- [ ] `allowed_origins` — конкретные домены, не `*`

---

## 9. SENSITIVE DATA EXPOSURE

### 9.1 Environment Variables

- [ ] `.env` в `.gitignore`
- [ ] `.env.example` не содержит реальных ключей
- [ ] Production credentials только на сервере

### 9.2 Debug Mode

```php
// ❌ КРИТИЧНО в production
APP_DEBUG=true  // Показывает stack traces с sensitive данными!

// ✅ Production
APP_DEBUG=false
APP_ENV=production
```

- [ ] `APP_DEBUG=false` в production
- [ ] `APP_ENV=production`
- [ ] Нет `dd()`, `dump()` в production коде

### 9.3 Error Messages

```php
// ❌ Плохо — технические детали пользователю
return back()->with('error', $e->getMessage());

// ✅ Хорошо — generic сообщения
return back()->with('error', 'Произошла ошибка. Попробуйте позже.');
```

- [ ] Пользователь не видит stack traces
- [ ] Пользователь не видит SQL ошибки

---

## 10. SECURITY HEADERS

### 10.1 Middleware

```php
// app/Http/Middleware/SecurityHeaders.php
class SecurityHeaders
{
    public function handle($request, $next)
    {
        $response = $next($request);

        $response->headers->set('X-Content-Type-Options', 'nosniff');
        $response->headers->set('X-Frame-Options', 'DENY');
        $response->headers->set('X-XSS-Protection', '1; mode=block');
        $response->headers->set('Referrer-Policy', 'strict-origin-when-cross-origin');

        return $response;
    }
}
```

- [ ] Security headers middleware добавлен
- [ ] X-Frame-Options = DENY

### 10.2 HTTPS

```php
// app/Providers/AppServiceProvider.php
public function boot()
{
    if (app()->environment('production')) {
        URL::forceScheme('https');
    }
}
```

- [ ] HTTPS принудительный в production

---

## 11. DEPENDENCY SECURITY

```bash
# PHP
composer audit

# NPM
npm audit
```

- [ ] `composer audit` не показывает уязвимостей
- [ ] `npm audit` без critical/high уязвимостей

---

## 12. САМОПРОВЕРКА

**Перед добавлением уязвимости в отчёт:**

| Вопрос | Если "нет" → пересмотри severity |
| -------- | ---------------------------------- |
| Это **эксплуатируемо** в реальных условиях? | Теоретическая ≠ реальная угроза |
| Есть **путь атаки** для злоумышленника? | Internal-only ≠ CRITICAL |
| **Какой ущерб** при успешной атаке? | Утечка публичных данных ≠ утечка паролей |
| Требуется ли **auth** для эксплуатации? | Auth-required снижает severity |

---

## 13. ФОРМАТ ОТЧЁТА

Создай файл `.claude/reports/SECURITY_AUDIT_[DATE].md`:

```markdown
# Security Audit Report — [Project Name]
Дата: [дата]
Auditor: Claude (Senior Security Engineer)

## Executive Summary

| Severity | Count | Status |
|----------|-------|--------|
| 🔴 Critical | X | X fixed |
| 🟠 High | X | X fixed |
| 🟡 Medium | X | X fixed |
| 🔵 Low | X | - |

**Overall Risk Level**: [Critical/High/Medium/Low]

## 🔴 Critical Vulnerabilities

### CRIT-001: [Название]
**Location**: `app/Http/Controllers/xxx.php:XX`
**Description**: ...
**Impact**: ...
**Remediation**: ...
**Status**: ✅ Fixed / ❌ Pending

## ✅ Security Controls in Place
- [x] CSRF protection enabled
- [x] Password hashing with bcrypt
- [ ] Rate limiting on all endpoints

## 📋 Remediation Checklist

### Immediate (24h)
- [ ] ...
```

---

## 14. ДЕЙСТВИЯ

1. **Quick Check** — пройди 5 пунктов из секции 0
2. **Сканируй** — пройди все секции
3. **Классифицируй** — Critical → Low
4. **Самопроверка** — фильтруй false positives
5. **Документируй** — файл, строка, код
6. **Исправляй** — предложи конкретный fix

Начни аудит. Сначала Quick Check, потом Executive Summary.
