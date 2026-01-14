# [Project Name] — Claude Code Instructions

## 🎯 Project Overview

**Stack:** [Framework] + [Frontend] + [Database]
**Type:** [SaaS/API/Dashboard/etc.]
**Description:** [Brief description]

---

## 🧠 WORKFLOW RULES (ОБЯЗАТЕЛЬНО!)

### Plan Mode — ВСЕГДА ИСПОЛЬЗУЙ ПЕРЕД КОДОМ

1. **Активируй Plan Mode** — `Shift+Tab` дважды
2. **Исследуй** задачу и существующий код
3. **Создай план** в `.claude/scratchpad/current-task.md`
4. **Дождись подтверждения** перед написанием кода

**Уровни размышления:**

| Слово | Когда использовать |
|-------|-------------------|
| `think` | Простые задачи |
| `think hard` | Средняя сложность |
| `think harder` | Архитектурные решения |
| `ultrathink` | Критические решения, безопасность |

**Пример промпта:**
```
"Проанализируй задачу [описание]. Think harder о edge cases.
НЕ ПИШИ КОД — только план."
```

### Git Workflow

- **Branch naming:** `feature/xxx`, `fix/xxx`, `refactor/xxx`
- **Commits:** Conventional Commits (`feat:`, `fix:`, `refactor:`)
- **НИКОГДА** не пушь напрямую в `main`

---

## 📁 Project Structure

```
[Customize for your project]
src/
├── components/    # UI components
├── services/      # Business logic
├── models/        # Data models
└── utils/         # Helper functions
```

---

## ⚡ Essential Commands

```bash
# Development
[command]          # Start dev server

# Testing
[command]          # Run tests

# Code Quality
[command]          # Lint/format

# Build
[command]          # Build for production
```

---

## 🔒 Security Rules (НИКОГДА НЕ НАРУШАЙ!)

1. **Input Validation** — ВСЕГДА валидируй пользовательский ввод
2. **SQL Injection** — НИКОГДА не конкатенируй user input в запросы
3. **XSS** — НИКОГДА не выводи user data без экранирования
4. **Authorization** — ВСЕГДА проверяй права перед операциями
5. **Secrets** — НИКОГДА не хардкодь ключи и пароли

---

## 🎨 Code Style

### Naming Conventions
- **Files:** `kebab-case.ts` или `PascalCase.tsx` для компонентов
- **Variables:** `camelCase`
- **Constants:** `UPPER_SNAKE_CASE`
- **Functions:** `camelCase`, глаголы (`createUser`, `validateInput`)

### Best Practices
- Максимум 200 строк на файл
- Одна ответственность на функцию/класс
- Типизация везде где возможно
- Комментарии для сложной логики

---

## 🤖 Available Agents

| Command | Agent | Purpose |
|---------|-------|---------|
| `/agent:code-reviewer` | Code Reviewer | Глубокий code review |
| `/agent:test-writer` | Test Writer | TDD-style тесты |
| `/agent:planner` | Planner | Планирование задач |

---

## 📋 Available Audits

| Trigger | Action |
|---------|--------|
| `security audit` | Run `.claude/prompts/SECURITY_AUDIT.md` |
| `performance audit` | Run `.claude/prompts/PERFORMANCE_AUDIT.md` |
| `code review` | Run `.claude/prompts/CODE_REVIEW.md` |
| `deploy checklist` | Run `.claude/prompts/DEPLOY_CHECKLIST.md` |

---

## 📝 Scratchpad

Для сложных задач используй `.claude/scratchpad/`:

- `current-task.md` — текущий план с чекбоксами
- `findings.md` — заметки исследования
- `decisions.md` — лог архитектурных решений

---

## ⚠️ Project-Specific Notes

### Known Gotchas
- [List project-specific issues]

### Public Endpoints (by design)
- `/api/health` — Health check
- `/webhooks/*` — External webhooks

---

## 🔗 Resources

- Documentation: [link]
- API Reference: [link]

---

## 👥 Contacts

- **Maintainer:** [Name]
- **Slack:** #channel
