# Performance Audit — Base Template

## Цель

Комплексный аудит производительности веб-приложения. Действуй как Senior Performance Engineer.

> **⚠️ Рекомендуемая модель:** Используй **Claude Opus 4.5** (`claude-opus-4-5-20251101`) для проведения аудитов — лучше работает с анализом кода.

---

## 0. QUICK CHECK (5 минут)

| # | Check | Target |
| --- | ------- | -------- |
| 1 | Homepage TTFB | < 500ms |
| 2 | Bundle size (gzipped) | < 500KB |
| 3 | No N+1 queries | 0 |
| 4 | Database indexes | All FKs indexed |
| 5 | Caching enabled | Yes |

---

## 0.1 PROJECT SPECIFICS — [Project Name]

**Текущие метрики:**

- Homepage load time: [X]ms
- Bundle size: [X]KB
- Database queries per page: [X]

**Что уже оптимизировано:**

- [ ] Caching: [что закэшировано]
- [ ] CDN: [используется ли]
- [ ] Lazy loading: [где]

---

## 0.2 SEVERITY LEVELS

| Level | Описание | Действие |
| ------- | ---------- | ---------- |
| 🔴 CRITICAL | Блокирует работу, > 5s load time | **БЛОКЕР** |
| 🟠 HIGH | Заметное замедление, > 2s | Исправить до деплоя |
| 🟡 MEDIUM | Можно улучшить, > 1s | Ближайший спринт |
| 🔵 LOW | Микро-оптимизация | Backlog |

---

## 1. DATABASE PERFORMANCE

### 1.1 N+1 Queries

```text
❌ Плохо: 1 query + N queries для связанных данных
✅ Хорошо: 1-2 queries с eager loading
```text

- [ ] Нет N+1 паттернов
- [ ] Eager loading используется
- [ ] Joins вместо множественных запросов

### 1.2 Query Optimization

- [ ] Индексы на часто используемых колонках
- [ ] Индексы на foreign keys
- [ ] Нет SELECT * где не нужно

### 1.3 Slow Queries

- [ ] Нет queries > 100ms
- [ ] EXPLAIN для сложных queries
- [ ] Pagination для больших datasets

---

## 2. CACHING

### 2.1 Application Cache

- [ ] Часто читаемые данные кэшируются
- [ ] Cache invalidation настроен
- [ ] TTL разумный

### 2.2 HTTP Cache

- [ ] Static assets имеют cache headers
- [ ] ETags или Last-Modified
- [ ] CDN для статики

### 2.3 Query Cache

- [ ] Тяжёлые queries кэшируются
- [ ] Cache key включает параметры

---

## 3. FRONTEND PERFORMANCE

### 3.1 Bundle Size

- [ ] JavaScript < 500KB gzipped
- [ ] CSS < 100KB gzipped
- [ ] Code splitting используется

### 3.2 Loading Strategy

- [ ] Critical CSS inline
- [ ] Non-critical CSS lazy
- [ ] JavaScript defer/async

### 3.3 Images

- [ ] Оптимизированы (WebP, AVIF)
- [ ] Lazy loading
- [ ] Правильные размеры (srcset)

### 3.4 Core Web Vitals

- [ ] LCP < 2.5s
- [ ] FID < 100ms
- [ ] CLS < 0.1

---

## 4. API PERFORMANCE

### 4.1 Response Time

- [ ] API endpoints < 500ms
- [ ] Нет blocking operations в handlers

### 4.2 Payload Size

- [ ] Pagination для списков
- [ ] Только нужные поля в response
- [ ] Gzip compression

### 4.3 Rate Limiting

- [ ] Protection от abuse
- [ ] Graceful degradation

---

## 5. BACKGROUND JOBS

### 5.1 Queue Usage

- [ ] Тяжёлые операции в queue
- [ ] Email отправка async
- [ ] File processing async

### 5.2 Job Configuration

- [ ] Timeout настроен
- [ ] Retry policy
- [ ] Failed job handling

---

## 6. INFRASTRUCTURE

### 6.1 Server

- [ ] Достаточно RAM
- [ ] CPU не перегружен
- [ ] Disk I/O в норме

### 6.2 Database

- [ ] Connection pooling
- [ ] Read replicas (если нужно)
- [ ] Query monitoring

---

## 7. MONITORING

- [ ] APM инструмент настроен
- [ ] Slow query logging
- [ ] Error rate tracking
- [ ] Uptime monitoring

---

## 8. САМОПРОВЕРКА

**НЕ оптимизируй:**

- Код который редко выполняется
- Микросекунды на горячем пути
- Premature optimization

**Фокусируйся на:**

- Частые операции
- User-facing performance
- Database bottlenecks

---

## 9. ФОРМАТ ОТЧЁТА

```markdown
# Performance Audit Report — [Project]
Дата: [дата]

## Summary

| Метрика | Текущее | Цель | Статус |
|---------|---------|------|--------|
| TTFB | Xms | <500ms | ✅/❌ |
| Bundle | XKB | <500KB | ✅/❌ |
| LCP | Xs | <2.5s | ✅/❌ |

**Overall Score**: X/10

## Critical Issues
[Детали...]

## Recommendations
[Что улучшить...]

## Quick Wins
[Быстрые улучшения...]
```text

---

## 10. ДЕЙСТВИЯ

1. **Измерь** — текущие метрики
2. **Профилируй** — найди bottlenecks
3. **Приоритизируй** — impact vs effort
4. **Исправь** — начни с quick wins
5. **Измерь снова** — подтверди улучшение

Начни аудит. Покажи текущие метрики и summary.
