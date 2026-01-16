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
|--------|----------|----------------------------|
| `noeviction` | Очереди | Ошибка записи (данные сохранены) |
| `volatile-lru` | Сессии | Удаляет только ключи с TTL |
| `allkeys-lru` | Кэш | Удаляет любые "старые" ключи |

---

### 2. Worker Self-Healing (Защита от утечек памяти)

**Проблема:** PHP накапливает память, воркеры "толстеют" и падают.

**Решение:** Использовать встроенные флаги Laravel вместо cron-костылей:

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
|------|----------|----------|
| `--max-jobs=N` | 50-200 | Перезапуск после N задач (сброс утечек) |
| `--max-time=N` | 1800-3600 | Жёсткий перезапуск через N секунд |
| `--timeout=N` | 60-300 | Таймаут одной задачи |

---

### 3. Timeout Cascade (Лесенка таймаутов)

**Проблема:** Supervisor убивает воркер раньше, чем завершится задача — нет логов, данные потеряны.

**Правило:** `External Service < Job Timeout < Supervisor stopwaitsecs`

```
┌─────────────────────────────────────────────────────────────┐
│  Playwright: 60s                                            │
│  ├── Laravel Job $timeout: 120s (больше Playwright)         │
│  │   └── Supervisor --timeout: 120s (= Job)                 │
│  │       └── Supervisor stopwaitsecs: 150s (> timeout)      │
└─────────────────────────────────────────────────────────────┘
```

**Пример для screenshot-worker:**

```ini
[program:screenshot-worker]
; Playwright 60s < Job 120s < stopwaitsecs 150s
command=php artisan queue:work --timeout=120 --queue=screenshots
stopwaitsecs=150
```

**В Laravel Job:**

```php
class TakeScreenshotJob implements ShouldQueue
{
    public $timeout = 120;  // Должен быть >= внешнего сервиса
}
```

---

### 4. Zombie Process Killer (Chrome/Playwright)

**Проблема:** При падении PHP-воркера процессы Chrome остаются висеть и едят память.

**Решение 1: Cron**

```bash
# Убивать Chrome-процессы старше 30 минут
*/10 * * * * /usr/bin/pkill -9 -f "chrome.*--type=renderer" --older 1800 2>/dev/null || true
```

**Решение 2: Docker с dumb-init**

```dockerfile
FROM node:20-slim
RUN apt-get update && apt-get install -y dumb-init
ENTRYPOINT ["dumb-init", "--"]
CMD ["node", "app.js"]
```

`dumb-init` автоматически убивает дочерние процессы при завершении контейнера.

---

### 5. Docker Memory Limits

**Проблема:** Утечка в одном сервисе кладёт весь сервер (нельзя даже по SSH зайти).

**Решение:**

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
        reservations:
          memory: 1G
```

Без Docker (systemd):

```ini
# /etc/systemd/system/redis.service.d/override.conf
[Service]
MemoryMax=2G
```

---

## Supervisor Best Practices

### Полный конфиг для парсинг-системы

```ini
[program:parsing-worker]
process_name=%(program_name)s_%(process_num)02d
command=php /var/www/app/artisan queue:work redis --sleep=3 --tries=3 --timeout=120 --max-jobs=100 --max-time=3600 --queue=parsing
autostart=true
autorestart=true
stopasgroup=true        # Убивать всю группу процессов
killasgroup=true        # SIGKILL всей группе
user=www-data
numprocs=10
redirect_stderr=true
stdout_logfile=/var/www/app/storage/logs/parsing-worker.log
stdout_logfile_maxbytes=50MB
stdout_logfile_backups=5
stopwaitsecs=150        # > timeout

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

### Важные опции

| Опция | Значение | Зачем |
|-------|----------|-------|
| `stopasgroup=true` | bool | Убивать дочерние процессы (Chrome!) |
| `killasgroup=true` | bool | SIGKILL для всей группы |
| `stdout_logfile_maxbytes` | 50MB | Ротация логов |
| `stdout_logfile_backups` | 5 | Количество архивов |

---

## Мониторинг

### Что отслеживать

| Метрика | Порог | Действие |
|---------|-------|----------|
| RAM usage | > 85% | Alert |
| Redis memory | > 80% maxmemory | Alert |
| Queue size | > 10000 | Alert (очередь растёт) |
| Failed jobs | > 100 | Alert |
| Disk usage | > 90% | Alert |
| Zombie Chrome | > 10 процессов | Auto-kill |

### Простой мониторинг через cron

```bash
#!/bin/bash
# /opt/scripts/health-check.sh

# RAM check
RAM_USED=$(free | grep Mem | awk '{print int($3/$2 * 100)}')
if [ $RAM_USED -gt 85 ]; then
    echo "ALERT: RAM usage $RAM_USED%" | mail -s "Server Alert" admin@example.com
fi

# Redis queue check
QUEUE_SIZE=$(redis-cli LLEN 'laravel-queues:parsing' 2>/dev/null || echo 0)
if [ $QUEUE_SIZE -gt 10000 ]; then
    echo "ALERT: Queue size $QUEUE_SIZE" | mail -s "Queue Alert" admin@example.com
fi

# Zombie Chrome check
ZOMBIES=$(pgrep -f "chrome.*--type=renderer" | wc -l)
if [ $ZOMBIES -gt 20 ]; then
    pkill -9 -f "chrome.*--type=renderer" --older 1800
    echo "Killed $ZOMBIES zombie Chrome processes"
fi
```

```bash
# crontab
*/5 * * * * /opt/scripts/health-check.sh >> /var/log/health-check.log 2>&1
```

---

## Maintenance Cron Jobs

```bash
# Перезапуск воркеров при рестарте Redis (30 сек задержка)
@reboot sleep 30 && /usr/bin/supervisorctl restart all

# Чистка старых логов Laravel
0 3 * * * find /var/www/app/storage/logs -name "*.log" -mtime +7 -delete

# Чистка temp файлов
0 4 * * * find /tmp -name "playwright*" -mtime +1 -delete 2>/dev/null

# Zombie Chrome killer
*/10 * * * * /usr/bin/pkill -9 -f "chrome.*--type=renderer" --older 1800 2>/dev/null || true

# Очистка failed_jobs старше 7 дней
0 5 * * * cd /var/www/app && php artisan queue:prune-failed --hours=168
```

---

## Quick Diagnostic Commands

```bash
# Статус воркеров
supervisorctl status

# Размер очередей
redis-cli LLEN 'laravel-queues:parsing'
redis-cli LLEN 'laravel-queues:screenshots'

# Память Redis
redis-cli INFO memory | grep used_memory_human

# Zombie Chrome процессы
pgrep -f "chrome.*--type=renderer" | wc -l

# Топ процессов по памяти
ps aux --sort=-%mem | head -10

# Failed jobs count
cd /var/www/app && php artisan tinker --execute="echo DB::table('failed_jobs')->count();"
```

---

## Типичные проблемы и решения

| Симптом | Причина | Решение |
|---------|---------|---------|
| RAM 100%, сервер не отвечает | Redis без лимита | `maxmemory` + `noeviction` |
| Задачи пропадают из очереди | `allkeys-lru` policy | Сменить на `noeviction` |
| Воркеры падают без логов | `stopwaitsecs` < `timeout` | Увеличить `stopwaitsecs` |
| Память растёт со временем | Утечки в PHP | `--max-jobs=100` |
| Chrome процессы копятся | Zombie processes | Cron с `pkill --older` |
| Очередь растёт, не обрабатывается | Воркеры отвалились от Redis | Рестарт после Redis restart |

---

## См. также

- [API Health Monitoring](./api-health-monitoring.md) — мониторинг внешних API
- [Quick Check Scripts](./quick-check-scripts.md) — скрипты проверки
