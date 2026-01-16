# DevOps Checklist: Laravel + Redis + Playwright (Highload)

Чеклист для production-систем с парсингом, скриншотами и тяжёлыми воркерами.

---

## Критические настройки

### 1. Redis Memory Policy

**Проблема:** `allkeys-lru` удалит задачи из очереди при нехватке памяти — молча, без ошибок.

**Решение:**

```bash
# Для очередей (Queues) — НИКОГДА не allkeys-lru!
redis-cli CONFIG SET maxmemory 2gb
redis-cli CONFIG SET maxmemory-policy noeviction  # Лучше ошибка, чем потеря данных
redis-cli CONFIG REWRITE

# Или разделить Redis: один для кэша (allkeys-lru), другой для очередей (noeviction)
```

| Policy | Для чего | Поведение при переполнении |
| ------ | -------- | -------------------------- |
| `noeviction` | Очереди | Ошибка записи (данные сохранены) |
| `volatile-lru` | Сессии | Удаляет только ключи с TTL |
| `allkeys-lru` | Кэш | Удаляет любые "старые" ключи |

**Идеальный сетап:** Два инстанса Redis:

- `redis:6379` — очереди (`noeviction`)
- `redis:6380` — кэш (`allkeys-lru`)

---

### 2. Worker Self-Healing (Защита от утечек памяти)

**Проблема:** PHP накапливает память, воркеры "толстеют" и падают.

**Решение:** Использовать встроенные флаги Laravel:

```ini
# /etc/supervisor/conf.d/workers.conf

[program:main-worker]
command=php /var/www/app/artisan queue:work redis \
    --sleep=3 \
    --tries=3 \
    --timeout=120 \
    --max-jobs=100 \      # Перезапуск после 100 задач
    --max-time=3600 \     # Перезапуск каждый час
    --queue=default,parsing
```

| Флаг | Значение | Описание |
| ---- | -------- | -------- |
| `--max-jobs=N` | 50-200 | Перезапуск после N задач (сброс утечек) |
| `--max-time=N` | 1800-3600 | Жёсткий перезапуск через N секунд |
| `--timeout=N` | 60-300 | Таймаут одной задачи |

**Backup cron:** Оставь cron-перезапуск как страховку на случай deadlock:

```bash
@reboot sleep 30 && /usr/bin/supervisorctl restart all
```

---

### 3. Timeout Cascade (Лесенка таймаутов)

**Проблема:** Supervisor убивает воркер раньше, чем завершится задача — нет логов, данные потеряны.

**Правило:** `External Service < Job Timeout < Supervisor stopwaitsecs`

```text
┌─────────────────────────────────────────────────────────────┐
│  Playwright: 60s                                            │
│  ├── Laravel Job $timeout: 120s (больше Playwright)         │
│  │   └── Supervisor --timeout: 120s (= Job)                 │
│  │       └── Supervisor stopwaitsecs: 150s (> timeout)      │
└─────────────────────────────────────────────────────────────┘
```

**В Laravel Job:**

```php
class TakeScreenshotJob implements ShouldQueue
{
    public $timeout = 120;  // Должен быть >= внешнего сервиса

    // Exponential backoff: 1 мин → 5 мин → 30 мин → 2 часа
    public $backoff = [60, 300, 1800, 7200];
}
```

---

### 4. Zombie Process Killer (Chrome/Playwright)

**Проблема:** При падении PHP-воркера процессы Chrome остаются висеть и едят память.

#### Решение 1: Cron

```bash
# Убивать Chrome-процессы старше 30 минут
*/10 * * * * /usr/bin/pkill -9 -f "chrome.*--type=renderer" --older 1800 2>/dev/null || true
```

#### Решение 2: Docker с dumb-init

```dockerfile
FROM node:20-slim
RUN apt-get update && apt-get install -y dumb-init
ENTRYPOINT ["dumb-init", "--"]
CMD ["node", "app.js"]
```

---

### 5. Docker Memory Limits

**Проблема:** Утечка в одном сервисе кладёт весь сервер.

```yaml
# docker-compose.yml
services:
  redis:
    image: redis:7
    deploy:
      resources:
        limits:
          memory: 2G
    command: redis-server --maxmemory 2gb --maxmemory-policy noeviction

  app-worker:
    build: .
    deploy:
      resources:
        limits:
          memory: 4G
```

---

## Playwright / Screenshots

### 6. Fonts in Docker (Квадратики вместо текста)

**Проблема:** В Docker нет шрифтов для CJK (китайский, японский), арабского, эмодзи — вместо текста `□□□`.

**Решение:**

```dockerfile
# Dockerfile
RUN apt-get update && apt-get install -y \
    fonts-liberation \
    fonts-noto-cjk \
    fonts-noto-color-emoji \
    fonts-freefont-ttf \
    --no-install-recommends \
    && rm -rf /var/lib/apt/lists/*
```

---

### 7. Real User-Agent

**Проблема:** Playwright палится как `HeadlessChrome` → 403 ошибки.

**Решение:**

```javascript
// Playwright
const browser = await chromium.launch();
const context = await browser.newContext({
    userAgent: 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36'
});
```

```php
// Laravel HTTP
Http::withHeaders([
    'User-Agent' => 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36',
])->get($url);
```

---

### 8. Playwright Tracing (Debug на стероидах)

**Проблема:** В логах сухое `TimeoutError` — непонятно, что случилось (капча? белый экран? 500?).

**Решение:** Сохранять trace только при ошибке:

```javascript
const context = await browser.newContext();
await context.tracing.start({ screenshots: true, snapshots: true });

try {
    // ... делаем скриншот
    await context.tracing.stop(); // Не сохраняем если успех
} catch (error) {
    // Сохраняем trace только при ошибке
    await context.tracing.stop({ path: `traces/failed-${Date.now()}.zip` });
    throw error;
}
```

Открыть trace: <https://trace.playwright.dev/>

**Важно:** Ограничить хранение traces (7 дней max), они тяжёлые.

---

### 9. Screenshot Compression

**Проблема:** PNG скриншоты весят 1-3MB каждый.

**Решение:** WebP = -70% размер:

```php
// Laravel + Intervention Image
$image = Image::make($screenshot)
    ->encode('webp', 80);  // качество 80%

Storage::disk('s3')->put("screenshots/{$id}.webp", $image);
```

---

## Storage

### 10. Storage Strategy

**Проблема:** Скриншоты забивают диск, `inode` заканчиваются.

#### Решение A: S3/R2 (рекомендуется для >1000 скриншотов/день)

```php
// Сразу в S3, без локального хранения
Storage::disk('s3')->put("screenshots/{$id}.webp", $imageData);
```

#### Решение B: Локально + cleanup (для малых объёмов)

```bash
# Удалять скриншоты старше 30 дней
0 4 * * * find /var/www/app/storage/screenshots -mtime +30 -delete

# Удалять temp файлы Playwright
0 4 * * * find /tmp -name "playwright*" -mtime +1 -delete 2>/dev/null
```

---

### 11. Disk Space Alert

```bash
#!/bin/bash
# /opt/scripts/disk-alert.sh

DISK_FREE=$(df -BG / | tail -1 | awk '{print $4}' | tr -d 'G')
if [ "$DISK_FREE" -lt 10 ]; then
    curl -X POST "$SLACK_WEBHOOK" -d '{"text":"⚠️ Disk < 10GB free!"}'
fi
```

```bash
*/30 * * * * /opt/scripts/disk-alert.sh
```

---

## Database

### 12. Prune Failed Jobs

**Проблема:** Таблица `failed_jobs` разрастается до миллионов строк.

```bash
# Удалять failed jobs старше 7 дней
0 5 * * * cd /var/www/app && php artisan queue:prune-failed --hours=168
```

---

## Resilience Patterns

### 13. Circuit Breaker

**Проблема:** Внешний сервис лёг — все воркеры висят в ожидании.

```php
// Если 5 ошибок подряд — пауза 5 минут
public function handle()
{
    $failures = Cache::get('playwright_failures', 0);

    if ($failures >= 5) {
        $this->release(300); // Отложить на 5 минут
        return;
    }

    try {
        $this->takeScreenshot();
        Cache::forget('playwright_failures');
    } catch (\Exception $e) {
        Cache::put('playwright_failures', $failures + 1, 300);
        throw $e;
    }
}
```

---

### 14. Rate Limiting (Не DDoS'ить сайты)

```php
// App/Providers/AppServiceProvider.php
RateLimiter::for('parsing', function ($job) {
    return Limit::perMinute(10)->by($job->site->domain);
});

// В Job
public function middleware()
{
    return [new RateLimited('parsing')];
}
```

---

### 15. Proxy Rotation

```php
// Для массового парсинга
$proxies = config('services.proxies'); // ['proxy1:8080', 'proxy2:8080']
$proxy = $proxies[array_rand($proxies)];

Http::withOptions(['proxy' => $proxy])->get($url);
```

---

## Monitoring

### 16. Health Endpoint

```php
// routes/api.php
Route::get('/health', function () {
    return response()->json([
        'status' => 'ok',
        'timestamp' => now()->toIso8601String(),
        'checks' => [
            'redis' => rescue(fn() => Redis::ping() ? 'ok' : 'fail', 'fail'),
            'database' => rescue(fn() => DB::connection()->getPdo() ? 'ok' : 'fail', 'fail'),
            'queue_parsing' => Redis::llen('queues:parsing'),
            'queue_screenshots' => Redis::llen('queues:screenshots'),
            'disk_free_gb' => round(disk_free_space('/') / 1024 / 1024 / 1024, 1),
            'memory_usage_mb' => round(memory_get_usage(true) / 1024 / 1024, 1),
        ],
    ]);
});
```

---

### 17. Alert Thresholds

| Метрика | Warning | Critical |
| ------- | ------- | -------- |
| RAM usage | > 80% | > 90% |
| Disk free | < 20GB | < 10GB |
| Queue size | > 5000 | > 10000 |
| Failed jobs/hour | > 50 | > 200 |
| Redis memory | > 70% | > 90% |

---

## Supervisor Full Config

```ini
[program:parsing-worker]
process_name=%(program_name)s_%(process_num)02d
command=php /var/www/app/artisan queue:work redis --sleep=3 --tries=3 --timeout=120 --max-jobs=100 --max-time=3600 --queue=parsing
autostart=true
autorestart=true
stopasgroup=true
killasgroup=true
user=www-data
numprocs=10
redirect_stderr=true
stdout_logfile=/var/www/app/storage/logs/parsing-worker.log
stdout_logfile_maxbytes=50MB
stdout_logfile_backups=5
stopwaitsecs=150

[program:screenshot-worker]
process_name=%(program_name)s_%(process_num)02d
command=php /var/www/app/artisan queue:work redis --sleep=3 --tries=2 --timeout=180 --max-jobs=50 --max-time=1800 --queue=screenshots
autostart=true
autorestart=true
stopasgroup=true
killasgroup=true
user=www-data
numprocs=4
redirect_stderr=true
stdout_logfile=/var/www/app/storage/logs/screenshot-worker.log
stdout_logfile_maxbytes=50MB
stdout_logfile_backups=5
stopwaitsecs=210
```

---

## Maintenance Cron Jobs

```bash
# Перезапуск воркеров при рестарте сервера
@reboot sleep 30 && /usr/bin/supervisorctl restart all

# Чистка старых логов Laravel
0 3 * * * find /var/www/app/storage/logs -name "*.log" -mtime +7 -delete

# Чистка temp файлов Playwright
0 4 * * * find /tmp -name "playwright*" -mtime +1 -delete 2>/dev/null

# Zombie Chrome killer
*/10 * * * * /usr/bin/pkill -9 -f "chrome.*--type=renderer" --older 1800 2>/dev/null || true

# Очистка failed_jobs старше 7 дней
0 5 * * * cd /var/www/app && php artisan queue:prune-failed --hours=168

# Disk space alert
*/30 * * * * /opt/scripts/disk-alert.sh

# Health check
*/5 * * * * /opt/scripts/health-check.sh >> /var/log/health-check.log 2>&1
```

---

## Quick Diagnostic Commands

```bash
# Статус воркеров
supervisorctl status

# Размер очередей
redis-cli LLEN 'queues:parsing'
redis-cli LLEN 'queues:screenshots'

# Память Redis
redis-cli INFO memory | grep used_memory_human

# Zombie Chrome
pgrep -f "chrome.*--type=renderer" | wc -l

# Топ по памяти
ps aux --sort=-%mem | head -10

# Failed jobs
php artisan tinker --execute="echo DB::table('failed_jobs')->count();"

# Disk usage
df -h /
```

---

## Финальный Checklist

```markdown
## Production Readiness Checklist

### Redis
- [ ] maxmemory установлен (2-4GB)
- [ ] noeviction для очередей (НЕ allkeys-lru!)
- [ ] Мониторинг memory usage

### Workers
- [ ] --max-jobs=100 --max-time=3600
- [ ] Cascade: External < Job timeout < stopwaitsecs
- [ ] stopasgroup=true, killasgroup=true
- [ ] Log rotation (stdout_logfile_maxbytes)

### Playwright/Chrome
- [ ] Zombie killer cron
- [ ] Fonts: noto-cjk, noto-emoji, liberation
- [ ] Real User-Agent (не HeadlessChrome)
- [ ] Tracing on failure (с лимитом хранения)
- [ ] WebP compression

### Docker
- [ ] mem_limit для контейнеров
- [ ] dumb-init (убивает дочерние процессы)

### Storage
- [ ] S3 или cleanup cron
- [ ] Disk alert < 10GB
- [ ] Temp files cleanup

### Database
- [ ] queue:prune-failed ежедневно
- [ ] Бэкап
- [ ] Slow query log

### Resilience
- [ ] Circuit breaker для внешних сервисов
- [ ] Exponential backoff ($backoff = [60, 300, 1800])
- [ ] Rate limiting per domain

### Monitoring
- [ ] /health endpoint
- [ ] Queue size alerts
- [ ] Error rate alerts
- [ ] Disk space alerts
```

---

## Типичные проблемы и решения

| Симптом | Причина | Решение |
| ------- | ------- | ------- |
| RAM 100%, сервер не отвечает | Redis/Chrome без лимита | maxmemory + mem_limit |
| Задачи пропадают | allkeys-lru | noeviction |
| Воркеры падают без логов | stopwaitsecs < timeout | Увеличить stopwaitsecs |
| Память растёт со временем | Утечки PHP | --max-jobs=100 |
| Chrome копятся | Zombie processes | pkill --older cron |
| Квадраты на скриншотах | Нет шрифтов | fonts-noto-cjk |
| 403 при парсинге | HeadlessChrome UA | Real User-Agent |
| Диск забился | Скриншоты/логи | S3 + cleanup cron |
| Непонятно почему упал | Нет debug info | Playwright tracing |

---

## Альтернативы

### Laravel Horizon вместо Supervisor

Для Laravel-проектов Horizon даёт:

- Web-dashboard для очередей
- Метрики из коробки
- Auto-balancing воркеров
- Лучше интеграция

```bash
composer require laravel/horizon
php artisan horizon:install
php artisan horizon
```

---

## См. также

- [API Health Monitoring](./api-health-monitoring.md) — мониторинг внешних API
- [Quick Check Scripts](./quick-check-scripts.md) — скрипты проверки
