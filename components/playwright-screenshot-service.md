# Playwright Screenshot Service Configuration

## Overview

Конфигурация Firecrawl Playwright сервиса для массового создания скриншотов сайтов.

## Расположение файлов

| Файл | Путь | Назначение |
|------|------|-----------|
| Docker Compose | `/opt/firecrawl/docker-compose.yaml` | Конфигурация контейнеров |
| Environment | `/opt/firecrawl/.env` | Переменные окружения |

## Ключевые настройки

### Environment Variables (.env)

```bash
# Количество параллельных страниц Playwright
CRAWL_CONCURRENT_REQUESTS=50

# Максимум параллельных джобов
MAX_CONCURRENT_JOBS=20
```

### Docker Resources (docker-compose.yaml)

```yaml
playwright-service:
  environment:
    MAX_CONCURRENT_PAGES: ${CRAWL_CONCURRENT_REQUESTS:-10}
  cpus: 4.0        # CPU лимит
  mem_limit: 32G   # RAM лимит
  memswap_limit: 32G
```

## Команды управления

### Проверка статуса

```bash
curl http://127.0.0.1:3001/health
# Ответ: {"status":"healthy","maxConcurrentPages":50,"activePages":50}
```

### Перезапуск сервиса

```bash
cd /opt/firecrawl
docker compose stop playwright-service
docker rm -f firecrawl-playwright-service-1
docker compose up -d playwright-service
```

### Просмотр логов

```bash
docker logs -f firecrawl-playwright-service-1
```

## Оптимизация производительности

### Bottleneck: maxConcurrentPages

Главный ограничитель — `maxConcurrentPages`. По умолчанию 10, что создаёт очередь даже при 100 воркерах.

**Рекомендации:**
- Увеличивать `CRAWL_CONCURRENT_REQUESTS` пропорционально количеству воркеров
- Мониторить `activePages` в health endpoint
- При `activePages == maxConcurrentPages` — увеличить лимит

### Docker CPU Limitation

**ВАЖНО:** Docker может не видеть все CPU хоста после апгрейда VM.

```bash
# Проверить CPU хоста
nproc  # 36

# Проверить CPU в Docker
docker info | grep CPUs  # CPUs: 4

# Если расхождение — нужен рестарт Docker daemon
sudo systemctl restart docker
```

## Troubleshooting

### Скриншоты не делаются / медленно

1. Проверить health: `curl http://127.0.0.1:3001/health`
2. Если `activePages == maxConcurrentPages` — увеличить `CRAWL_CONCURRENT_REQUESTS`
3. Проверить логи: `docker logs firecrawl-playwright-service-1`

### cURL error 52: Empty reply from server

Playwright сервис перегружен или упал. Решение:
- Перезапустить контейнер
- Уменьшить `CRAWL_CONCURRENT_REQUESTS` или увеличить ресурсы

### Container conflict on restart

```bash
docker rm -f firecrawl-playwright-service-1
docker compose up -d playwright-service
```
