# Claude Guides

Переиспользуемые инструкции, аудиты и шаблоны для Claude Code.

## Быстрый старт

```bash
# Инициализировать .claude/ в новом проекте
curl -sSL https://raw.githubusercontent.com/user/claude-guides/main/scripts/init-claude.sh | bash -s -- laravel
# или
curl -sSL https://raw.githubusercontent.com/user/claude-guides/main/scripts/init-claude.sh | bash -s -- nextjs
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

## Использование

### 1. Ручная установка

Скопируй нужные файлы в `.claude/` директорию проекта:

```bash
# Для Laravel проекта
cp -r templates/laravel/* your-project/.claude/prompts/
cp components/* your-project/.claude/prompts/

# Для Next.js проекта
cp -r templates/nextjs/* your-project/.claude/prompts/
cp components/* your-project/.claude/prompts/
```

### 2. Автоматическая инициализация

```bash
cd your-project
../claude-guides/scripts/init-claude.sh laravel
```

### 3. Настройка CLAUDE.md

После копирования шаблонов, отредактируй `CLAUDE.md.template`:
- Укажи название проекта
- Укажи URL и сервер
- Добавь project-specific правила

## Компоненты

Переиспользуемые блоки для вставки в свои инструкции:

| Компонент | Описание |
|-----------|----------|
| `severity-levels.md` | Уровни критичности (CRITICAL → LOW) |
| `self-check-section.md` | Секция самопроверки (фильтр реальности) |
| `report-format.md` | Шаблон формата отчёта |
| `quick-check-scripts.md` | Bash-скрипты для быстрых проверок |

## Slash-команды

Команды для Claude Code:

| Команда | Файл | Описание |
|---------|------|----------|
| `/doc` | `commands/doc.md` | Задокументировать код |
| `/find-script` | `commands/find-script.md` | Найти скрипт |
| `/find-function` | `commands/find-function.md` | Найти функцию |
| `/audit` | `commands/audit.md` | Запустить аудит проекта |

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

### Изменение severity levels

Если нужны другие уровни критичности, отредактируй `components/severity-levels.md`.

## Принципы

1. **DRY** — Не дублируй инструкции между проектами
2. **Специфичность** — Framework-specific детали в отдельных файлах
3. **Самопроверка** — Каждый аудит имеет секцию фильтрации false positives
4. **Actionable** — Конкретные команды и примеры кода

## Contributing

1. Fork репозитория
2. Создай feature branch
3. Добавь/улучши шаблоны
4. Протестируй на реальном проекте
5. Создай PR

## License

MIT
