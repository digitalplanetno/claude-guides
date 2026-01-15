# Security Audit — Base Template

## Цель

Комплексный аудит безопасности веб-приложения. Действуй как Senior Security Engineer / Penetration Tester.

---

## 0. QUICK CHECK (5 минут)

**Перед полным аудитом — пройди эти критические пункты:**

| # | Check | Expected |
|---|-------|----------|
| 1 | Debug mode отключен | `false` в production |
| 2 | Нет hardcoded secrets в коде | Все ключи в env |
| 3 | Нет SQL injection паттернов | Параметризованные запросы |
| 4 | Dependency audit | Нет critical уязвимостей |
| 5 | Auth на sensitive endpoints | Все защищено |

Если все 5 = ✅ → Базовый уровень безопасности OK.

---

## 0.1 PROJECT SPECIFICS — [Project Name]

**Заполни перед аудитом:**

**Что уже реализовано:**

- [ ] Authentication mechanism: [какой]
- [ ] Authorization: [policies/middleware/etc]
- [ ] Input validation: [где]
- [ ] CSRF protection: [как]

**Публичные endpoints (by design):**

- `/api/health` — health check
- `/webhooks/*` — webhooks (проверь signature!)

**Известные особенности:**

- [Project-specific notes]

---

## 0.2 SEVERITY LEVELS

| Level | Описание | Действие |
|-------|----------|----------|
| 🔴 CRITICAL | Эксплуатируемая уязвимость: SQLi, RCE, auth bypass | **БЛОКЕР** — исправить немедленно |
| 🟠 HIGH | Серьёзная уязвимость, требует auth или сложной эксплуатации | Исправить до деплоя |
| 🟡 MEDIUM | Потенциальная уязвимость, низкий риск | Исправить в ближайшем спринте |
| 🔵 LOW | Best practice, defense in depth | Backlog |
| ⚪ INFO | Информация, не требует действий | — |

---

## 1. INJECTION ATTACKS

### 1.1 SQL Injection

- [ ] Все запросы используют параметризацию
- [ ] Нет конкатенации user input в SQL
- [ ] Dynamic column/table names через whitelist

### 1.2 Command Injection

- [ ] Нет прямого выполнения user commands
- [ ] Whitelist разрешённых команд
- [ ] Аргументы санитизируются

### 1.3 XSS (Cross-Site Scripting)

- [ ] User input экранируется при выводе
- [ ] Нет unsafe HTML rendering без санитизации
- [ ] CSP headers настроены

---

## 2. AUTHENTICATION

### 2.1 Password Security

- [ ] Пароли хэшируются (bcrypt/argon2)
- [ ] Минимум 10 rounds для bcrypt
- [ ] Нет plain text паролей

### 2.2 Session Security

- [ ] Secure cookies в production
- [ ] HttpOnly cookies
- [ ] SameSite policy

### 2.3 Rate Limiting

- [ ] Login endpoint имеет rate limiting
- [ ] Password reset имеет rate limiting
- [ ] API endpoints имеют rate limiting

---

## 3. AUTHORIZATION

### 3.1 Access Control

- [ ] Все protected routes требуют auth
- [ ] Проверка ownership на update/delete
- [ ] Нет IDOR (Insecure Direct Object Reference)

### 3.2 Role-Based Access

- [ ] Roles проверяются на server-side
- [ ] Admin routes дополнительно защищены
- [ ] Нет privilege escalation

---

## 4. DATA PROTECTION

### 4.1 Sensitive Data

- [ ] Secrets только в env, не в коде
- [ ] Debug mode отключен в production
- [ ] Пароли/ключи не логируются

### 4.2 Error Handling

- [ ] Пользователь не видит stack traces
- [ ] Пользователь не видит SQL ошибки
- [ ] Детальные ошибки только в логах

### 4.3 HTTPS

- [ ] HTTPS обязателен в production
- [ ] HTTP редиректит на HTTPS
- [ ] HSTS header

---

## 5. FILE HANDLING

### 5.1 File Upload

- [ ] File type валидируется (не только extension)
- [ ] File size ограничен
- [ ] Filename генерируется (не user-provided)

### 5.2 Path Traversal

- [ ] Нет `../` в user paths
- [ ] Paths санитизируются
- [ ] Проверка что path в разрешённой директории

---

## 6. API SECURITY

### 6.1 CORS

- [ ] `allowed_origins` — конкретные домены, не `*`
- [ ] Credentials настроены правильно

### 6.2 Rate Limiting

- [ ] Все API endpoints имеют rate limiting
- [ ] Rate limit по user, не только по IP

### 6.3 Response Filtering

- [ ] Sensitive поля не возвращаются
- [ ] Используются API Resources/DTOs

---

## 7. DEPENDENCIES

### 7.1 Audit

- [ ] Package manager audit без critical/high
- [ ] Dependencies обновлены

---

## 8. SECURITY HEADERS

- [ ] X-Content-Type-Options: nosniff
- [ ] X-Frame-Options: DENY или SAMEORIGIN
- [ ] X-XSS-Protection: 1; mode=block
- [ ] Referrer-Policy: strict-origin-when-cross-origin
- [ ] Content-Security-Policy (если применимо)

---

## 9. САМОПРОВЕРКА

**Перед добавлением уязвимости в отчёт:**

| Вопрос | Если "нет" → пересмотри severity |
|--------|----------------------------------|
| Это **эксплуатируемо** в реальных условиях? | Теоретическая ≠ реальная угроза |
| Есть **путь атаки** для злоумышленника? | Internal-only ≠ CRITICAL |
| **Какой ущерб** при успешной атаке? | Утечка публичных данных ≠ утечка паролей |
| Требуется ли **auth** для эксплуатации? | Auth-required снижает severity |

---

## 10. ФОРМАТ ОТЧЁТА

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
[Детали...]

## 🟠 High Severity Issues
[Детали...]

## ✅ Security Controls in Place
[Что уже хорошо...]

## 📋 Remediation Checklist
[Что исправить...]
```

---

## 11. ДЕЙСТВИЯ

1. **Quick Check** — пройди 5 пунктов
2. **Сканируй** — пройди все секции
3. **Классифицируй** — Critical → Low
4. **Самопроверка** — фильтруй false positives
5. **Документируй** — файл, строка, код
6. **Исправляй** — предложи конкретный fix

Начни аудит. Сначала Quick Check, потом Executive Summary.
