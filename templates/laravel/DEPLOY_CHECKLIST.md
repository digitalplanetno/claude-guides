# Deploy Checklist — Laravel Template

## Цель
Комплексная проверка перед деплоем Laravel приложения. Действуй как Senior DevOps Engineer.

---

## 0. QUICK CHECK (5 минут)

| # | Check | Command | Expected |
|---|-------|---------|----------|
| 1 | PHP Syntax | `php artisan --version` | No errors |
| 2 | Pint | `./vendor/bin/pint --test` | No changes |
| 3 | PHPStan | `./vendor/bin/phpstan analyse` | Level passed |
| 4 | Tests | `php artisan test` | Pass |
| 5 | Build | `npm run build` | Success |
| 6 | Migrations | `php artisan migrate --pretend` | Expected changes |

**Если все 6 = OK → Можно деплоить!**

---

## 0.1 AUTO-CHECK SCRIPT

```bash
#!/bin/bash
# deploy-check.sh — запусти перед деплоем

set -e

echo "Pre-deploy Check for Laravel..."

# 1. PHP Artisan
php artisan --version > /dev/null 2>&1 && echo "✅ PHP Artisan" || { echo "❌ PHP Artisan"; exit 1; }

# 2. Pint
./vendor/bin/pint --test > /dev/null 2>&1 && echo "✅ Pint" || echo "🟡 Pint has changes"

# 3. PHPStan
./vendor/bin/phpstan analyse 2>&1 | grep -q "error" && echo "🟡 PHPStan errors" || echo "✅ PHPStan"

# 4. Tests
php artisan test --stop-on-failure > /dev/null 2>&1 && echo "✅ Tests" || echo "🟡 Tests failed"

# 5. NPM Build
npm run build > /dev/null 2>&1 && echo "✅ Build" || { echo "❌ Build"; exit 1; }

# 6. Debug code check
grep -rn "dd(" app/ routes/ | grep -v ".blade.php" && echo "🟡 dd() found" || echo "✅ No dd()"
grep -rn "dump(" app/ routes/ && echo "🟡 dump() found" || echo "✅ No dump()"

echo ""
echo "Ready to deploy!"
```

---

## 0.2 PROJECT SPECIFICS — [Project Name]

**Deployment target:**
- **Server**: [IP/hostname]
- **Path**: [/path/to/app]
- **URL**: [https://...]
- **Process manager**: [PM2/Supervisor/systemd]

**Database:**
- **Name**: [db_name]
- **User**: [db_user]
- **Password**: см. `.env` → `DB_PASSWORD`

**Важные файлы:**
- `.env` — переменные окружения
- `/etc/supervisor/conf.d/...` — Supervisor config (если есть)

---

## 0.3 DEPLOY TYPES

| Тип | Когда | Чеклист |
|-----|-------|---------|
| Hotfix | Критичный баг | Quick Check только |
| Minor | Мелкие изменения | Quick Check + секция 1 |
| Feature | Новая функциональность | Секции 0-6 |
| Major | Архитектурные изменения | Весь чеклист |

---

## 1. PRE-DEPLOYMENT CODE CLEANUP

### 1.1 Debug Code Removal

```bash
grep -rn "dd(" app/ resources/ routes/
grep -rn "dump(" app/ resources/ routes/
grep -rn "var_dump" app/ resources/
grep -rn "console.log" resources/js/
```

- [ ] Нет `dd()`, `dump()`, `var_dump()`
- [ ] Нет `console.log()` в production
- [ ] Нет `Log::debug()` с sensitive данными

### 1.2 Commented Code

- [ ] Нет закомментированного кода
- [ ] Нет `// TODO: remove` блоков

### 1.3 Temporary Files

```bash
find . -name "*.bak" -o -name "*.tmp" -o -name "*.old"
```

- [ ] Нет `.bak`, `.tmp`, `.old` файлов

---

## 2. CODE QUALITY CHECKS

### 2.1 Tests

```bash
php artisan test
php artisan test --coverage --min=80
```

- [ ] Все тесты проходят
- [ ] Нет skipped тестов без причины
- [ ] Критичный функционал покрыт

### 2.2 Static Analysis

```bash
./vendor/bin/phpstan analyse --memory-limit=2G
./vendor/bin/pint --test
```

- [ ] PHPStan без ошибок
- [ ] Code style OK

### 2.3 Build

```bash
npm ci && npm run build
```

- [ ] Build проходит без ошибок

---

## 3. DATABASE PREPARATION

### 3.1 Migrations Review

```bash
php artisan migrate:status
php artisan migrate --pretend
php artisan migrate:rollback --pretend
```

```php
// ✅ Хорошо — безопасные изменения
Schema::table('sites', function (Blueprint $table) {
    $table->string('new_column')->nullable();  // nullable для существующих записей
});

// ❌ Опасно — NOT NULL без default
$table->string('required_column');  // Сломает существующие записи!
```

- [ ] Все миграции имеют `down()` метод
- [ ] Новые NOT NULL колонки имеют default или nullable
- [ ] Индексы добавлены для новых foreign keys
- [ ] Rollback работает

### 3.2 Seeders Check

```php
// ❌ КРИТИЧНО — удалит production данные!
class DatabaseSeeder extends Seeder
{
    public function run(): void
    {
        Site::truncate();  // НИКОГДА в production!
    }
}

// ✅ Безопасно — проверка окружения
if (app()->environment('production')) {
    $this->command->error('Cannot seed in production!');
    return;
}
```

- [ ] Seeders не выполняются в production
- [ ] Нет `truncate()` без проверки environment

### 3.3 Backup

```bash
# Backup перед миграциями
mysqldump -u $DB_USERNAME -p$DB_PASSWORD $DB_DATABASE > backup_$(date +%Y%m%d_%H%M%S).sql
```

- [ ] Backup БД создан перед миграциями
- [ ] Backup проверен на восстановимость

---

## 4. ENVIRONMENT CONFIGURATION

### 4.1 Production .env

```ini
# ОБЯЗАТЕЛЬНЫЕ настройки
APP_NAME=[Name]
APP_ENV=production          # НЕ local!
APP_DEBUG=false             # НЕ true!
APP_URL=https://[domain]

LOG_LEVEL=error             # Не debug в production

CACHE_DRIVER=redis          # Не file в production
SESSION_DRIVER=redis        # Не file в production
QUEUE_CONNECTION=redis      # Не sync в production

SESSION_SECURE_COOKIE=true
```

- [ ] `APP_ENV=production`
- [ ] `APP_DEBUG=false`
- [ ] `APP_URL` — правильный URL с HTTPS
- [ ] `LOG_LEVEL` — не `debug`
- [ ] `CACHE_DRIVER` — redis (не file)
- [ ] `SESSION_DRIVER` — redis (не file)
- [ ] `QUEUE_CONNECTION` — redis (не sync)

### 4.2 Config Cache Compatibility

```bash
# Найти env() вне config/
grep -rn "env(" app/ routes/ resources/ --include="*.php" | grep -v "config/"
```

- [ ] Нет `env()` вызовов вне `config/` директории
- [ ] `php artisan config:cache` работает

---

## 5. BUILD PROCESS

### 5.1 Composer Production

```bash
composer install --no-dev --optimize-autoloader --no-interaction
```

- [ ] `composer install --no-dev` успешен
- [ ] Нет missing dependencies

### 5.2 NPM Production Build

```bash
rm -rf node_modules
npm ci
npm run build
```

- [ ] `npm ci` успешен
- [ ] `npm run build` успешен
- [ ] Bundle size разумный (< 500KB gzipped)

---

## 6. SECURITY PRE-CHECK

### 6.1 Sensitive Files

- [ ] `.env` недоступен через web
- [ ] `.git/` недоступен через web
- [ ] `storage/logs/` недоступен через web

### 6.2 File Permissions

```bash
chmod -R 755 storage bootstrap/cache
chown -R www-data:www-data storage bootstrap/cache
```

- [ ] `storage/` — 755, владелец www-data
- [ ] `bootstrap/cache/` — 755, владелец www-data

### 6.3 Dependencies Audit

```bash
composer audit
npm audit
```

- [ ] `composer audit` — нет critical/high уязвимостей
- [ ] `npm audit` — нет critical/high уязвимостей

---

## 7. DEPLOYMENT COMMANDS

### 7.1 Full Deploy Script

```bash
#!/bin/bash
set -e

APP_DIR="/var/www/[app]"
BACKUP_DIR="/opt/backups"
DATE=$(date +%Y%m%d_%H%M%S)

cd $APP_DIR

# 1. Maintenance mode
php artisan down --secret="deploy-$DATE"

# 2. Backup database
source .env
mysqldump -u $DB_USERNAME -p$DB_PASSWORD $DB_DATABASE > "$BACKUP_DIR/db_$DATE.sql"

# 3. Pull code
git pull origin main

# 4. Install PHP dependencies
composer install --no-dev --optimize-autoloader --no-interaction

# 5. Build assets
npm ci && npm run build

# 6. Run migrations
php artisan migrate --force

# 7. Clear and cache
php artisan config:cache
php artisan route:cache
php artisan view:cache
php artisan event:cache

# 8. Restart queues
php artisan queue:restart
supervisorctl restart [worker-name]:  # если используется Supervisor

# 9. Permissions
chown -R www-data:www-data storage bootstrap/cache
chmod -R 755 storage bootstrap/cache

# 10. Disable maintenance
php artisan up

echo "Deployment completed!"

# 11. Health check
HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" https://[domain])
if [ "$HTTP_CODE" -eq 200 ]; then
    echo "Health check passed!"
else
    echo "Health check failed! HTTP: $HTTP_CODE"
    exit 1
fi
```

---

## 8. POST-DEPLOYMENT VERIFICATION

### 8.1 Smoke Tests

```bash
curl -I https://[domain]
curl -I https://[domain]/login
curl -I https://[domain]/api/health
```

- [ ] Homepage загружается
- [ ] Логин работает
- [ ] Dashboard отображается
- [ ] Основной функционал работает
- [ ] Очереди обрабатываются

### 8.2 Error Monitoring

```bash
tail -f storage/logs/laravel.log
grep -i "error\|exception\|fatal" storage/logs/laravel.log | tail -20
php artisan queue:failed
```

- [ ] Нет новых ошибок в логах
- [ ] Нет failed jobs
- [ ] Error rate не вырос

---

## 9. ROLLBACK PLAN

### 9.1 Quick Rollback

```bash
#!/bin/bash
set -e

cd /var/www/[app]

php artisan down
git reset --hard HEAD~1

# Restore database if needed
# source .env
# mysql -u $DB_USERNAME -p$DB_PASSWORD $DB_DATABASE < /opt/backups/db_YYYYMMDD_HHMMSS.sql

composer install --no-dev --optimize-autoloader
npm ci && npm run build

php artisan config:cache
php artisan route:cache
php artisan view:cache

php artisan queue:restart
php artisan up

echo "Rollback completed!"
```

### 9.2 Rollback Triggers

Откатывай если:
- Error rate > 5% после деплоя
- Critical функционал не работает
- Database corruption

---

## 10. САМОПРОВЕРКА

**НЕ блокируй деплой из-за:**

| Кажется блокером | Почему не блокер |
|------------------|------------------|
| "PHPStan warnings" | Если код работает — OK |
| "Deprecated package" | Если работает — обнови позже |
| "Нет тестов" | Если функционал работает — OK |
| "console.log в коде" | Не влияет на пользователей |
| "Pint показывает изменения" | Code style не блокер |

**Градация готовности:**
```
READY (95-100%) — Деплой сейчас
ACCEPTABLE (70-94%) — Деплой возможен
NOT READY (<70%) — Блокируй
```

---

## 11. ФОРМАТ ОТЧЁТА

```markdown
# Deploy Checklist Report — [Project Name]
Date: [дата]
Version: [git commit hash]

## Summary

| Step | Status |
|------|--------|
| Pre-checks | ✅/❌ |
| Backup | ✅/❌ |
| Deploy | ✅/❌ |
| Verify | ✅/❌ |

**Readiness**: XX% — [READY/ACCEPTABLE/NOT READY]

## Blockers
- [Если есть]

## Warnings
- [Если есть]

## Post-Deploy
- [ ] Monitor for 24h
- [ ] Check queues
```

---

## 12. ДЕЙСТВИЯ

1. **Проверь** — пройди чеклист
2. **Backup** — создай backup
3. **Deploy** — выполни deployment
4. **Verify** — проверь что работает
5. **Monitor** — следи за логами

Ответь: "OK: Готов к деплою (XX%)" или "FAIL: Проблемы: [список]"
