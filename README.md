# Claude Guides

Переиспользуемые инструкции, аудиты и шаблоны для Claude Code.

[![Quality Check](https://github.com/digitalplanetno/claude-guides/actions/workflows/quality.yml/badge.svg)](https://github.com/digitalplanetno/claude-guides/actions/workflows/quality.yml)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

## Быстрый старт

```bash
# Инициализировать .claude/ в новом проекте
curl -sSL https://raw.githubusercontent.com/digitalplanetno/claude-guides/main/scripts/init-claude.sh | bash

# С указанием фреймворка
curl -sSL https://raw.githubusercontent.com/digitalplanetno/claude-guides/main/scripts/init-claude.sh | bash -s -- laravel

# Dry-run (посмотреть что будет создано)
curl -sSL https://raw.githubusercontent.com/digitalplanetno/claude-guides/main/scripts/init-claude.sh | bash -s -- --dry-run
```

## Структура

```
claude-guides/
├── templates/
│   ├── base/           # Базовые шаблоны (framework-agnostic)
│   ├── laravel/        # Laravel + Vue + Inertia
│   └── nextjs/         # Next.js + TypeScript
├── components/         # Переиспользуемые блоки
├── commands/           # Slash-команды для Claude
├── scripts/            # Скрипты инициализации
└── examples/           # Примеры готовых конфигураций
    ├── laravel-saas/   # SaaS на Laravel
    ├── nextjs-dashboard/ # Dashboard на Next.js
    └── monorepo/       # Turborepo monorepo
```

## Доступные шаблоны

### Аудиты

| Шаблон | Описание |
|--------|----------|
| `SECURITY_AUDIT.md` | Комплексный аудит безопасности |
| `PERFORMANCE_AUDIT.md` | Аудит производительности |
| `CODE_REVIEW.md` | Code review чеклист |
| `DEPLOY_CHECKLIST.md` | Чеклист перед деплоем |

### Framework-специфичные версии

**Laravel** (`templates/laravel/`):
- SQL Injection, Mass Assignment, CSRF
- Eloquent N+1, Query optimization
- Services, FormRequests, Policies
- Artisan commands, Queue workers

**Next.js** (`templates/nextjs/`):
- API Routes security, SSRF protection
- Bundle size, SSR/CSR optimization
- React hooks, Server Components
- Vercel deployment, Edge functions

### Поддерживаемые фреймворки

| Framework | Templates | Auto-detection |
|-----------|-----------|----------------|
| Laravel | ✅ Full | `artisan` file |
| Next.js | ✅ Full | `next.config.*` |
| Django | 🔄 Base | `manage.py` + requirements |
| Rails | 🔄 Base | `Gemfile` with rails |
| Go | 🔄 Base | `go.mod` |
| Rust | 🔄 Base | `Cargo.toml` |
| Node.js | 🔄 Base | `package.json` |

## Использование

### 1. Ручная установка

```bash
# Для Laravel проекта
cp -r templates/laravel/* your-project/.claude/prompts/

# Для Next.js проекта
cp -r templates/nextjs/* your-project/.claude/prompts/
```

### 2. Автоматическая инициализация

```bash
# Из локального клона
cd your-project
/path/to/claude-guides/scripts/init-local.sh

# Или с GitHub
curl -sSL https://raw.githubusercontent.com/digitalplanetno/claude-guides/main/scripts/init-claude.sh | bash
```

### 3. Обновление шаблонов

```bash
# Обновить шаблоны в существующем проекте
curl -sSL https://raw.githubusercontent.com/digitalplanetno/claude-guides/main/scripts/update-claude.sh | bash

# С бэкапом (по умолчанию)
./update-claude.sh

# Без бэкапа
./update-claude.sh --no-backup

# Dry-run
./update-claude.sh --dry-run
```

## Slash-команды

| Команда | Файл | Описание |
|---------|------|----------|
| `/audit` | `commands/audit.md` | Запустить аудит проекта |
| `/doc` | `commands/doc.md` | Задокументировать код |
| `/fix` | `commands/fix.md` | Исправить найденную проблему |
| `/explain` | `commands/explain.md` | Объяснить код/архитектуру |
| `/test` | `commands/test.md` | Написать тесты |
| `/refactor` | `commands/refactor.md` | Рефакторинг кода |
| `/migrate` | `commands/migrate.md` | Помощь с миграциями БД |
| `/find-script` | `commands/find-script.md` | Найти скрипт |
| `/find-function` | `commands/find-function.md` | Найти функцию |

## Компоненты

Переиспользуемые блоки для вставки в свои инструкции:

| Компонент | Описание |
|-----------|----------|
| `severity-levels.md` | Уровни критичности (CRITICAL → LOW) |
| `self-check-section.md` | Секция самопроверки (фильтр реальности) |
| `report-format.md` | Шаблон формата отчёта |
| `quick-check-scripts.md` | Bash-скрипты для быстрых проверок |

## Триггеры в CLAUDE.md

Добавь в свой `CLAUDE.md`:

```markdown
## ДОСТУПНЫЕ ИНСТРУКЦИИ

| Триггер | Действие |
|---------|----------|
| "security audit", "аудит безопасности" | Выполни `.claude/prompts/SECURITY_AUDIT.md` |
| "performance audit", "аудит производительности" | Выполни `.claude/prompts/PERFORMANCE_AUDIT.md` |
| "code review", "ревью кода" | Выполни `.claude/prompts/CODE_REVIEW.md` |
| "deploy checklist", "готов к деплою?" | Выполни `.claude/prompts/DEPLOY_CHECKLIST.md` |
```

## Разработка

```bash
# Установить зависимости
make install

# Запустить линтеры
make lint

# Запустить тесты
make test

# Валидация шаблонов
make validate
```

### Pre-commit hooks

```bash
pip install pre-commit
pre-commit install
```

## Кастомизация

### Добавление project-specific секций

В каждом шаблоне есть секция `## 0.2 PROJECT SPECIFICS`:

```markdown
## 0.2 PROJECT SPECIFICS — [Project Name]

**Что уже реализовано:**
- ✅ [Существующие security controls]

**Публичные endpoints (by design):**
- `/api/health` — health check
- `/webhooks/*` — webhooks с signature verification

**Известные особенности:**
- [Project-specific notes]
```

## Принципы

1. **DRY** — Не дублируй инструкции между проектами
2. **Специфичность** — Framework-specific детали в отдельных файлах
3. **Самопроверка** — Каждый аудит имеет секцию фильтрации false positives
4. **Actionable** — Конкретные команды и примеры кода

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md) for guidelines.

## Security

See [SECURITY.md](SECURITY.md) for reporting vulnerabilities.

## License

MIT — see [LICENSE](LICENSE)
