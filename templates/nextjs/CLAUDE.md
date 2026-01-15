# [Project Name] — Claude Code Instructions

## 🎯 Project Overview

**Stack:** Next.js 15 + TypeScript + Tailwind CSS + Prisma
**Type:** [SaaS/Dashboard/E-commerce/Marketing Site]
**Database:** PostgreSQL 15+ / MySQL 8.x
**Node:** 20+ | **Package Manager:** pnpm

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
| `think` | Простые задачи, однофайловые изменения |
| `think hard` | Средняя сложность, несколько файлов |
| `think harder` | Архитектурные решения, новые фичи |
| `ultrathink` | Безопасность, SSR/ISR стратегии, критические решения |

### Git Workflow

- **Branch naming:** `feature/xxx`, `fix/xxx`, `refactor/xxx`
- **Commits:** Conventional Commits (`feat:`, `fix:`, `refactor:`, `docs:`)
- **НИКОГДА** не пушь напрямую в `main`

---

## 📁 Project Structure

```
app/                          # App Router (Next.js 13+)
├── (auth)/                   # Route group — auth pages
├── (dashboard)/              # Route group — protected
├── api/                      # API Routes
├── layout.tsx                # Root layout
└── page.tsx                  # Home page

components/
├── ui/                       # Primitives (Button, Input, Modal)
├── forms/                    # Form components
└── providers/                # Context providers

lib/
├── actions/                  # Server Actions
├── db/                       # Database (Prisma)
├── utils/                    # Helper functions
├── validations/              # Zod schemas
└── types/                    # TypeScript types

hooks/                        # Custom React hooks
```

---

## ⚡ Essential Commands

```bash
# Development
pnpm dev                      # Next.js dev server

# Database
pnpm prisma generate          # Generate Prisma client
pnpm prisma migrate dev       # Create migration

# Testing
pnpm test                     # Run all tests
pnpm e2e                      # Playwright E2E

# Quality
pnpm lint                     # ESLint
pnpm typecheck                # TypeScript
```

---

## 🔒 Security Rules (НИКОГДА НЕ НАРУШАЙ!)

### 1. Server vs Client
```tsx
// ❌ secrets в client component!
'use client'
const API_KEY = process.env.API_KEY;

// ✅ secrets только на сервере
const API_KEY = process.env.API_KEY;
```

### 2. API Validation
```typescript
// ❌ доверять без валидации
const body = await request.json();
await prisma.user.create({ data: body });

// ✅ Zod validation
const validated = CreateUserSchema.parse(body);
await prisma.user.create({ data: validated });
```

### 3. Auth Check
```typescript
// ✅ ВСЕГДА проверяй auth
const session = await auth();
if (!session) return new Response('Unauthorized', { status: 401 });
```

---

## 🤖 Available Agents

| Command | Purpose |
|---------|---------|
| `/agent:code-reviewer` | Code review |
| `/agent:test-writer` | TDD тесты |
| `/agent:nextjs-expert` | Next.js экспертиза |

---

## 🧠 Available Skills

| Skill | Описание |
|-------|----------|
| Next.js Expert | App Router, Server Components, SSR/ISR, caching |
| Shadcn UI Expert | Компоненты, cn() utility, формы (RHF + Zod), темы |
| Tailwind CSS Expert | Class ordering, responsive, accessibility |

Skills активируются автоматически по контексту.

---

## 📋 Available Audits

| Trigger | Action |
|---------|--------|
| `security audit` | `.claude/prompts/SECURITY_AUDIT.md` |
| `performance audit` | `.claude/prompts/PERFORMANCE_AUDIT.md` |
| `code review` | `.claude/prompts/CODE_REVIEW.md` |
