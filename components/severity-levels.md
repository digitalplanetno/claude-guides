# Severity Levels

Стандартные уровни критичности для аудитов и code review.

## Таблица уровней

| Level | Emoji | Описание | Действие |
|-------|-------|----------|----------|
| CRITICAL | 🔴 | Эксплуатируемая уязвимость, data loss, RCE | **БЛОКЕР** — исправить немедленно |
| HIGH | 🟠 | Серьёзная проблема, требует auth или сложной эксплуатации | Исправить до merge/deploy |
| MEDIUM | 🟡 | Потенциальная проблема, низкий риск | Исправить в ближайшем спринте |
| LOW | 🔵 | Best practice, defense in depth | Backlog |
| INFO | ⚪ | Информация, не требует действий | — |

## Когда использовать

### 🔴 CRITICAL
- SQL Injection без auth
- Remote Code Execution
- Authentication bypass
- Sensitive data exposure (passwords, API keys)
- Data corruption/loss

### 🟠 HIGH
- SQL Injection с auth required
- XSS в authenticated area
- CSRF на критичных операциях
- Missing authorization checks
- Insecure file upload

### 🟡 MEDIUM
- Information disclosure (версии, stack traces)
- Missing rate limiting
- Weak password policy
- Clickjacking potential
- Missing security headers

### 🔵 LOW
- Missing HSTS
- Verbose error messages (non-sensitive)
- Outdated dependencies (no CVE)
- Code style issues
- Documentation gaps

### ⚪ INFO
- Informational findings
- Design decisions
- Recommendations for future
