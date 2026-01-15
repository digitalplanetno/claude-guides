# Claude Guides

Переиспользуемые инструкции, аудиты, subagents, skills и шаблоны для Claude Code.

[![Quality Check](https://github.com/digitalplanetno/claude-guides/actions/workflows/quality.yml/badge.svg)](https://github.com/digitalplanetno/claude-guides/actions/workflows/quality.yml)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

## 🚀 Быстрый старт

```bash
# Инициализировать .claude/ в новом проекте
curl -sSL https://raw.githubusercontent.com/digitalplanetno/claude-guides/main/scripts/init-claude.sh | bash

# С указанием фреймворка
curl -sSL https://raw.githubusercontent.com/digitalplanetno/claude-guides/main/scripts/init-claude.sh | bash -s -- laravel

# Dry-run (посмотреть что будет создано)
curl -sSL https://raw.githubusercontent.com/digitalplanetno/claude-guides/main/scripts/init-claude.sh | bash -s -- --dry-run
```

## ✨ Что нового в v2.0

- 🤖 **Subagents** — специализированные агенты для code review, тестирования, безопасности
- 🧠 **Skills** — глубокая экспертиза по Laravel и Next.js
- ⚡ **Hooks** — автоматическое форматирование, аудит команд, логирование
- 📋 **Plan Mode** — инструкции для планирования перед кодом
- 🔧 **Новые команды** — /plan, /tdd, /context-prime, /checkpoint

## 📁 Структура

```
claude-guides/
├── templates/
│   ├── base/                    # Framework-agnostic шаблоны
│   │   ├── CLAUDE.md            # Базовый шаблон
│   │   ├── settings.json        # Hooks и permissions
│   │   ├── SECURITY_AUDIT.md
│   │   ├── PERFORMANCE_AUDIT.md
│   │   ├── CODE_REVIEW.md
│   │   ├── DEPLOY_CHECKLIST.md
│   │   └── agents/              # Базовые subagents
│   │       ├── code-reviewer.md
│   │       ├── test-writer.md
│   │       └── planner.md
│   ├── laravel/                 # Laravel + Vue + Inertia
│   │   ├── CLAUDE.md
│   │   ├── settings.json
│   │   ├── agents/
│   │   │   └── laravel-expert.md
│   │   ├── skills/
│   │   │   └── laravel/SKILL.md
│   │   └── ... (audits)
│   └── nextjs/                  # Next.js + TypeScript
│       ├── CLAUDE.md
│       ├── settings.json
│       ├── agents/
│       │   └── nextjs-expert.md
│       ├── skills/
│       │   └── nextjs/SKILL.md
│       └── ... (audits)
├── commands/                    # Slash-команды
│   ├── audit.md
│   ├── plan.md                  # 🆕 Планирование
│   ├── tdd.md                   # 🆕 Test-Driven Development
│   ├── context-prime.md         # 🆕 Загрузка контекста
│   ├── checkpoint.md            # 🆕 Сохранение прогресса
│   ├── handoff.md               # 🆕 Передача задачи
│   └── ... (existing)
├── components/                  # Переиспользуемые блоки
│   ├── plan-mode-instructions.md  # 🆕
│   ├── git-worktrees-guide.md     # 🆕
│   ├── severity-levels.md
│   ├── self-check-section.md
│   └── ...
├── examples/                    # Готовые конфигурации
└── scripts/                     # Скрипты инициализации
```

## 🤖 Subagents

Subagents — специализированные агенты для делегирования задач:

| Agent | Файл | Описание |
|-------|------|----------|
| Code Reviewer | `agents/code-reviewer.md` | Глубокий code review с чеклистом |
| Test Writer | `agents/test-writer.md` | TDD-style написание тестов |
| Planner | `agents/planner.md` | Создание implementation plans |
| Security Auditor | `agents/security-auditor.md` | Фокус на безопасности |

**Использование:**
```
/agent:code-reviewer app/Http/Controllers/
/agent:test-writer UserService
```

## 🧠 Skills

Skills — глубокая экспертиза по конкретным технологиям:

| Skill | Путь | Описание |
|-------|------|----------|
| Laravel Expert | `skills/laravel/SKILL.md` | Eloquent, паттерны, производительность |
| Next.js Expert | `skills/nextjs/SKILL.md` | App Router, SSR, оптимизация |
| Shadcn UI Expert | `skills/shadcn/SKILL.md` | Компоненты, cn(), формы, темы |
| Tailwind CSS Expert | `skills/tailwind/SKILL.md` | Утилиты, порядок классов, responsive |

Skills автоматически активируются когда контекст релевантен.

## ⚡ Hooks

Автоматизация рутинных задач через `.claude/settings.json`:

```json
{
  "hooks": {
    "PostToolUse": [
      {
        "matcher": "Edit|Write",
        "hooks": [
          {
            "type": "command",
            "command": "./vendor/bin/pint $FILE_PATH --quiet"
          }
        ]
      }
    ]
  }
}
```

**Включённые hooks:**
- ✅ Auto-format PHP (Pint) после редактирования
- ✅ Auto-format JS/Vue (Prettier) после редактирования
- ✅ Аудит bash команд в лог
- ✅ Логирование сессий

## 📋 Slash-команды

### Новые команды

| Команда | Описание |
|---------|----------|
| `/plan` | Создать план реализации (Plan Mode) |
| `/tdd` | Test-Driven Development workflow |
| `/context-prime` | Загрузить контекст проекта |
| `/checkpoint` | Сохранить прогресс в scratchpad |
| `/handoff` | Подготовить передачу задачи |

### Существующие команды

| Команда | Описание |
|---------|----------|
| `/audit` | Запустить аудит проекта |
| `/test` | Написать тесты |
| `/refactor` | Рефакторинг кода |
| `/doc` | Документация |
| `/fix` | Исправить проблему |
| `/explain` | Объяснить код |
| `/migrate` | Помощь с миграциями |

## 🎯 План перед кодом (ВАЖНО!)

Главная рекомендация от Anthropic — **всегда планировать перед написанием кода**.

### Workflow

1. **Активируй Plan Mode** — `Shift+Tab` дважды
2. **Используй уровни размышления:**
   - `think` — простые задачи
   - `think hard` — средняя сложность
   - `think harder` — архитектурные решения
   - `ultrathink` — критические решения
3. **Сохрани план** в `.claude/scratchpad/`
4. **Получи подтверждение** перед написанием кода

### Пример

```
"Проанализируй задачу добавления OAuth. 
Think harder о edge cases и безопасности.
НЕ ПИШИ КОД — только план в .claude/scratchpad/oauth-plan.md"
```

## 📊 Аудиты

### Framework-специфичные

**Laravel:**
- SQL Injection, Mass Assignment, CSRF
- Eloquent N+1, Query optimization
- Services, FormRequests, Policies

**Next.js:**
- API Routes security, SSRF protection
- Bundle size, SSR/CSR optimization
- Server Components, Edge functions

### Quick Check (30 секунд)

```bash
# Security
grep -rn "DB::raw\|whereRaw" app/
grep -rn '$guarded.*=.*\[\]' app/Models/

# Performance
grep -rn "->get().*foreach" app/

# Code Quality
grep -rn "dd(\|dump(\|console.log" app/ resources/
```

## 🔧 Использование

### 1. Ручная установка

```bash
# Для Laravel проекта
cp -r templates/laravel/* your-project/.claude/

# Для Next.js проекта
cp -r templates/nextjs/* your-project/.claude/
```

### 2. Автоматическая инициализация

```bash
# Из локального клона
cd your-project
/path/to/claude-guides/scripts/init-local.sh

# С GitHub
curl -sSL https://raw.githubusercontent.com/digitalplanetno/claude-guides/main/scripts/init-claude.sh | bash
```

### 3. Обновление

```bash
curl -sSL https://raw.githubusercontent.com/digitalplanetno/claude-guides/main/scripts/update-claude.sh | bash
```

## 📚 Триггеры в CLAUDE.md

Добавь в свой `CLAUDE.md`:

```markdown
## ДОСТУПНЫЕ ИНСТРУКЦИИ

| Триггер | Действие |
|---------|----------|
| "security audit" | Выполни `.claude/prompts/SECURITY_AUDIT.md` |
| "performance audit" | Выполни `.claude/prompts/PERFORMANCE_AUDIT.md` |
| "code review" | Выполни `.claude/prompts/CODE_REVIEW.md` |
| "deploy checklist" | Выполни `.claude/prompts/DEPLOY_CHECKLIST.md` |

## SUBAGENTS

| Команда | Агент |
|---------|-------|
| `/agent:code-reviewer` | Code review с чеклистом |
| `/agent:test-writer` | Написание тестов (TDD) |
| `/agent:planner` | Планирование задач |
```

## 🏗️ Поддерживаемые фреймворки

| Framework | Templates | Skills | Auto-detection |
|-----------|-----------|--------|----------------|
| Laravel | ✅ Full | ✅ Yes | `artisan` file |
| Next.js | ✅ Full | ✅ Yes | `next.config.*` |
| Django | 🔄 Base | 🔜 Soon | `manage.py` |
| Rails | 🔄 Base | 🔜 Soon | `Gemfile` |
| Go | 🔄 Base | — | `go.mod` |
| Rust | 🔄 Base | — | `Cargo.toml` |

## 💡 Принципы

1. **Plan First** — Всегда планируй перед написанием кода
2. **DRY** — Не дублируй инструкции между проектами
3. **Специфичность** — Framework-specific детали отдельно
4. **Самопроверка** — Фильтруй false positives
5. **Actionable** — Конкретные команды и примеры

## 🔗 Полезные ресурсы

- [Официальные best practices от Anthropic](https://www.anthropic.com/engineering/claude-code-best-practices)
- [awesome-claude-code](https://github.com/hesreallyhim/awesome-claude-code) — коллекция ресурсов
- [Claude Code Documentation](https://docs.anthropic.com/en/docs/claude-code)

## 🤝 Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md) for guidelines.

## 🔒 Security

See [SECURITY.md](SECURITY.md) for reporting vulnerabilities.

## 📄 License

MIT — see [LICENSE](LICENSE)
