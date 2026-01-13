# Deploy Checklist — Base Template

## Цель
Комплексная проверка перед деплоем. Действуй как Senior DevOps Engineer.

---

## 0. QUICK CHECK (5 минут)

| # | Check | Expected |
|---|-------|----------|
| 1 | Build | Success |
| 2 | Tests | Pass |
| 3 | Linter | No errors |
| 4 | Debug code | Removed |
| 5 | Migrations | Reviewed |
| 6 | Env vars | Set |

**Если все 6 = OK → Можно деплоить!**

---

## 0.1 PROJECT SPECIFICS — [Project Name]

**Deployment target:**
- **Server**: [IP/hostname]
- **Path**: [/path/to/app]
- **URL**: [https://...]
- **Process manager**: [PM2/Supervisor/systemd]

**Database:**
- **Host**: [host]
- **Name**: [db_name]

**Важные файлы:**
- `.env` — переменные окружения
- [Другие важные файлы]

---

## 0.2 DEPLOY TYPES

| Тип | Когда | Чеклист |
|-----|-------|---------|
| Hotfix | Критичный баг | Quick Check только |
| Minor | Мелкие изменения | Quick Check + секция 1 |
| Feature | Новая функциональность | Секции 0-6 |
| Major | Архитектурные изменения | Весь чеклист |

---

## 1. CODE CLEANUP

### 1.1 Debug Code
- [ ] Нет console.log / dd() / dump()
- [ ] Нет debugger statements
- [ ] Нет TODO/FIXME в критичном коде

### 1.2 Commented Code
- [ ] Нет закомментированного кода
- [ ] Нет backup блоков

### 1.3 Temporary Files
- [ ] Нет .bak, .tmp, .old файлов

---

## 2. CODE QUALITY

### 2.1 Tests
- [ ] Все тесты проходят
- [ ] Нет skipped тестов без причины
- [ ] Критичный функционал покрыт

### 2.2 Linting
- [ ] Код проходит linter
- [ ] Нет errors (warnings OK)

### 2.3 Build
- [ ] Build проходит без ошибок
- [ ] Assets собраны и минифицированы

---

## 3. DATABASE

### 3.1 Migrations
- [ ] Migrations имеют rollback
- [ ] NOT NULL колонки имеют default
- [ ] Индексы добавлены
- [ ] Dry run проверен

### 3.2 Backup
- [ ] Backup создан перед миграциями
- [ ] Backup проверен на восстановимость

### 3.3 Seeders
- [ ] Seeders НЕ выполняются в production
- [ ] Нет truncate без проверки env

---

## 4. ENVIRONMENT

### 4.1 Production Config
- [ ] APP_ENV=production
- [ ] DEBUG=false
- [ ] LOG_LEVEL не debug
- [ ] HTTPS обязателен

### 4.2 Secrets
- [ ] Все API keys — production версии
- [ ] Пароли сильные и уникальные
- [ ] Нет secrets в коде

### 4.3 Cache Config
- [ ] Cache driver настроен (не file)
- [ ] Session driver настроен
- [ ] Queue driver настроен

---

## 5. SECURITY

### 5.1 Files
- [ ] .env недоступен через web
- [ ] .git недоступен через web
- [ ] Logs недоступны через web

### 5.2 Permissions
- [ ] Правильные права на директории
- [ ] Owner правильный (www-data/nginx)

### 5.3 Dependencies
- [ ] Нет critical уязвимостей
- [ ] Dependencies обновлены

---

## 6. DEPLOYMENT

### 6.1 Pre-Deploy
```bash
# 1. Maintenance mode
# 2. Backup database
# 3. Pull code
# 4. Install dependencies
```

### 6.2 Deploy
```bash
# 5. Run migrations
# 6. Clear caches
# 7. Rebuild caches
# 8. Restart workers
```

### 6.3 Post-Deploy
```bash
# 9. Verify site works
# 10. Check logs for errors
# 11. Disable maintenance
```

---

## 7. VERIFICATION

### 7.1 Smoke Tests
- [ ] Homepage loads
- [ ] Login works
- [ ] Core functionality works

### 7.2 Monitoring
- [ ] Нет новых ошибок в логах
- [ ] Error rate не вырос
- [ ] Response time в норме

---

## 8. ROLLBACK PLAN

### 8.1 Готовность
- [ ] Rollback script готов
- [ ] Database backup доступен
- [ ] Знаешь commit hash для отката

### 8.2 Триггеры
Откатывай если:
- Error rate > 5%
- Critical функционал не работает
- Database corruption

---

## 9. САМОПРОВЕРКА

**НЕ блокируй деплой из-за:**

| Кажется блокером | Почему не блокер |
|------------------|------------------|
| "Linter warnings" | Если код работает — OK |
| "Deprecated package" | Если работает — обнови позже |
| "Нет тестов" | Если функционал работает — OK |
| "console.log в коде" | Не влияет на пользователей |

**Градация готовности:**
```
READY (95-100%) — Деплой сейчас
ACCEPTABLE (70-94%) — Деплой возможен
NOT READY (<70%) — Блокируй
```

---

## 10. ФОРМАТ ОТЧЁТА

```markdown
# Deploy Checklist Report — [Project]
Дата: [дата]
Version: [commit hash]

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

## 11. ДЕЙСТВИЯ

1. **Проверь** — пройди чеклист
2. **Backup** — создай backup
3. **Deploy** — выполни deployment
4. **Verify** — проверь что работает
5. **Monitor** — следи за логами

Ответь: "OK: Готов к деплою (XX%)" или "FAIL: Проблемы: [список]"
