# Code Review — Next.js Template

## Цель

Комплексный code review Next.js приложения. Действуй как Senior Tech Lead.

---

## 0. QUICK CHECK (5 минут)

| # | Check | Command | Expected |
| --- | ------- | --------- | ---------- |
| 1 | TypeScript | `npm run build` | No type errors |
| 2 | Lint | `npm run lint` | No errors |
| 3 | Tests | `npm test` | Pass |
| 4 | console.log | `grep -rn "console.log" app/ components/ --include="*.tsx"` | Minimal |

---

## 0.1 AUTO-CHECK SCRIPT

```bash
#!/bin/bash
# code-check.sh

echo "📝 Code Quality Check — Next.js..."

# 1. Build (includes TypeScript check)
npm run build > /dev/null 2>&1 && echo "✅ Build" || echo "❌ Build failed"

# 2. Lint
npm run lint > /dev/null 2>&1 && echo "✅ Lint" || echo "🟡 Lint has warnings"

# 3. console.log
CONSOLE=$(grep -rn "console.log" app/ components/ lib/ --include="*.ts" --include="*.tsx" 2>/dev/null | wc -l)
[ "$CONSOLE" -lt 10 ] && echo "✅ console.log: $CONSOLE" || echo "🟡 console.log: $CONSOLE (много)"

# 4. 'use client' count
USE_CLIENT=$(grep -rn "'use client'" app/ components/ --include="*.tsx" 2>/dev/null | wc -l)
echo "ℹ️  Client components: $USE_CLIENT files"

# 5. Large files (>300 lines)
LARGE_FILES=$(find app components lib -name "*.ts" -o -name "*.tsx" | xargs wc -l 2>/dev/null | awk '$1 > 300 {print $2}' | wc -l)
[ "$LARGE_FILES" -eq 0 ] && echo "✅ No large files" || echo "🟡 Large files: $LARGE_FILES files >300 lines"

# 6. TODO/FIXME
TODOS=$(grep -rn "TODO\|FIXME" app/ components/ lib/ --include="*.ts" --include="*.tsx" 2>/dev/null | wc -l)
echo "ℹ️  TODO/FIXME: $TODOS comments"

echo "Done!"
```text

---

## 0.2 PROJECT SPECIFICS — [Project Name]

**Принятые решения (не нужно исправлять):**

- [Осознанные architectural decisions]

**Ключевые файлы для review:**

- `app/` — страницы и API routes
- `components/` — UI компоненты
- `lib/` — утилиты и хелперы

**Паттерны проекта:**

- Server Components по умолчанию
- 'use client' только для интерактивности
- Zod для валидации
- API routes для mutations

---

## 0.3 SEVERITY LEVELS

| Level | Описание | Действие |
| ------- | ---------- | ---------- |
| CRITICAL | Баг, security issue, data loss | **БЛОКЕР** — исправить сейчас |
| HIGH | Серьёзная проблема в логике | Исправить до merge |
| MEDIUM | Code smell, maintainability | Исправить в этом PR |
| LOW | Style, nice-to-have | Можно отложить |

---

## 1. SCOPE REVIEW

### 1.1 Определи scope проверки

```bash
git diff --name-only HEAD~5
git status --short
```text

- [ ] Какие файлы изменены
- [ ] Какие новые файлы созданы
- [ ] Связь изменений между собой

### 1.2 Категоризация

- [ ] Pages (app/**/page.tsx)
- [ ] API Routes (app/api/**/route.ts)
- [ ] Components (components/*)
- [ ] Lib/Utils (lib/*)
- [ ] Config (next.config.ts, etc.)

---

## 2. ARCHITECTURE & STRUCTURE

### 2.1 Server Components vs Client Components

```tsx
// ❌ Плохо — весь компонент client без необходимости
'use client';

import { useState } from 'react';

export function ProjectPage({ projects }) {
  const [filter, setFilter] = useState('all');

  return (
    <div>
      <h1>Projects</h1>  {/* Статичный контент */}
      <FilterButton onFilter={setFilter} />
      {projects.map(p => <ProjectCard key={p.id} project={p} />)}  {/* Статичный */}
    </div>
  );
}

// ✅ Хорошо — минимальный client boundary
// app/projects/page.tsx (Server Component)
export default async function ProjectsPage() {
  const projects = await getProjects();

  return (
    <div>
      <h1>Projects</h1>
      <ProjectFilters />  {/* Client Component */}
      <ProjectList projects={projects} />  {/* Server Component */}
    </div>
  );
}

// components/ProjectFilters.tsx
'use client';
export function ProjectFilters() {
  const [filter, setFilter] = useState('all');
  return <FilterButton onFilter={setFilter} />;
}
```text

- [ ] Client boundary максимально низко в дереве
- [ ] 'use client' только где реально нужна интерактивность
- [ ] Data fetching в Server Components

### 2.2 API Route Structure

```typescript
// ❌ Плохо — много логики в route handler
// app/api/projects/route.ts
export async function POST(request: Request) {
  // 100 строк бизнес-логики...
}

// ✅ Хорошо — логика в отдельных файлах
// app/api/projects/route.ts
import { createProject } from '@/lib/services/projects';
import { CreateProjectSchema } from '@/lib/schemas/projects';

export async function POST(request: Request) {
  const body = await request.json();

  const parsed = CreateProjectSchema.safeParse(body);
  if (!parsed.success) {
    return Response.json({ error: parsed.error.flatten() }, { status: 400 });
  }

  const project = await createProject(parsed.data);
  return Response.json(project);
}
```text

- [ ] Route handlers тонкие
- [ ] Бизнес-логика в lib/services/
- [ ] Схемы в lib/schemas/

### 2.3 File Structure

```text
app/
├── (auth)/
│   ├── login/
│   │   └── page.tsx
│   └── layout.tsx
├── dashboard/
│   └── page.tsx
├── api/
│   └── projects/
│       └── route.ts
├── layout.tsx
└── page.tsx

components/
├── ui/           # Переиспользуемые UI компоненты
├── features/     # Feature-specific компоненты
└── layouts/      # Layout компоненты

lib/
├── services/     # Бизнес-логика
├── schemas/      # Zod schemas
├── db/           # Database utilities
└── utils/        # Helpers
```text

- [ ] Файлы в правильных директориях
- [ ] Нет God-компонентов (> 300 строк)
- [ ] UI и бизнес-логика разделены

---

## 3. CODE QUALITY

### 3.1 TypeScript

```typescript
// ❌ Плохо — any, отсутствие типов
function process(data: any) {
  return data.something;
}

// ❌ Плохо — implicit any в параметрах
const handleClick = (e) => console.log(e);

// ✅ Хорошо — полная типизация
interface ProcessInput {
  id: string;
  data: Record<string, unknown>;
}

function process(input: ProcessInput): ProcessResult {
  return { id: input.id, processed: true };
}

const handleClick = (e: React.MouseEvent<HTMLButtonElement>) => {
  console.log(e.currentTarget.id);
};
```text

- [ ] Нет `any` без явной необходимости
- [ ] Все функции типизированы
- [ ] Interfaces/types определены

### 3.2 Naming Conventions

```typescript
// ❌ Плохо
const d = await fetchData();
const res = processStuff(d);

// ✅ Хорошо
const projects = await fetchProjects();
const processedProjects = processProjects(projects);
```text

- [ ] **Переменные** — существительные, camelCase: `projectList`, `userData`
- [ ] **Функции** — глаголы, camelCase: `getProjects()`, `processData()`
- [ ] **Компоненты** — PascalCase: `ProjectCard`, `UserProfile`
- [ ] **Boolean** — is/has/can/should: `isLoading`, `hasError`

### 3.3 Component Structure

```tsx
// ❌ Плохо — всё вперемешку
'use client';

import { useState, useEffect } from 'react';

export function ProjectCard({ project }) {
  const [loading, setLoading] = useState(false);

  // 200 строк логики и рендеринга
}

// ✅ Хорошо — разделение на части
// hooks/useProjectActions.ts
export function useProjectActions(projectId: string) {
  const [loading, setLoading] = useState(false);

  const deleteProject = async () => {
    setLoading(true);
    // ...
  };

  return { loading, deleteProject };
}

// components/ProjectCard.tsx
'use client';

import { useProjectActions } from '@/hooks/useProjectActions';

interface ProjectCardProps {
  project: Project;
}

export function ProjectCard({ project }: ProjectCardProps) {
  const { loading, deleteProject } = useProjectActions(project.id);

  return (
    <div>
      <h3>{project.name}</h3>
      <button onClick={deleteProject} disabled={loading}>
        Delete
      </button>
    </div>
  );
}
```text

- [ ] Логика вынесена в custom hooks
- [ ] Props типизированы через interface
- [ ] Компоненты < 150 строк

### 3.4 DRY (Don't Repeat Yourself)

```typescript
// ❌ Плохо — дублирование
// components/ProjectCard.tsx
const formatDate = (date: Date) => date.toLocaleDateString('ru-RU');

// components/UserCard.tsx
const formatDate = (date: Date) => date.toLocaleDateString('ru-RU');

// ✅ Хорошо — общие утилиты
// lib/utils/date.ts
export function formatDate(date: Date, locale = 'ru-RU'): string {
  return date.toLocaleDateString(locale);
}

// Использование
import { formatDate } from '@/lib/utils/date';
```text

- [ ] Нет дублирующегося кода
- [ ] Общие утилиты в lib/utils/

---

## 4. REACT/NEXT.JS BEST PRACTICES

### 4.1 Data Fetching

```tsx
// ❌ Плохо — useEffect для начальных данных
'use client';

export function ProjectList() {
  const [projects, setProjects] = useState([]);

  useEffect(() => {
    fetch('/api/projects').then(r => r.json()).then(setProjects);
  }, []);

  return <div>{projects.map(...)}</div>;
}

// ✅ Хорошо — Server Component
// app/projects/page.tsx
export default async function ProjectsPage() {
  const projects = await getProjects();  // Прямой запрос к БД
  return <ProjectList projects={projects} />;
}
```text

- [ ] Data fetching в Server Components
- [ ] Нет useEffect для начальной загрузки
- [ ] API routes для mutations

### 4.2 Error Handling

```tsx
// ❌ Плохо — нет обработки ошибок
export async function POST(request: Request) {
  const data = await request.json();
  const result = await createProject(data);
  return Response.json(result);
}

// ✅ Хорошо — полная обработка
export async function POST(request: Request) {
  try {
    const body = await request.json();

    const parsed = CreateProjectSchema.safeParse(body);
    if (!parsed.success) {
      return Response.json(
        { error: 'Validation failed', details: parsed.error.flatten() },
        { status: 400 }
      );
    }

    const result = await createProject(parsed.data);
    return Response.json(result, { status: 201 });

  } catch (error) {
    console.error('Create project error:', error);

    if (error instanceof UniqueConstraintError) {
      return Response.json(
        { error: 'Project already exists' },
        { status: 409 }
      );
    }

    return Response.json(
      { error: 'Internal server error' },
      { status: 500 }
    );
  }
}
```text

- [ ] Try-catch в API routes
- [ ] Специфичные error responses
- [ ] Логирование ошибок

### 4.3 Loading & Error States

```tsx
// app/projects/loading.tsx
export default function Loading() {
  return <ProjectsSkeleton />;
}

// app/projects/error.tsx
'use client';

export default function Error({
  error,
  reset,
}: {
  error: Error;
  reset: () => void;
}) {
  return (
    <div>
      <h2>Something went wrong!</h2>
      <button onClick={reset}>Try again</button>
    </div>
  );
}
```text

- [ ] loading.tsx для Suspense
- [ ] error.tsx для error boundaries
- [ ] Skeleton компоненты для loading states

---

## 5. SECURITY & PERFORMANCE QUICK CHECK

### 5.1 Security

- [ ] API routes проверяют auth
- [ ] Input валидируется через Zod
- [ ] Нет SQL injection (параметризованные запросы)
- [ ] Нет secrets в client-side коде
- [ ] Нет dangerouslySetInnerHTML с user content

### 5.2 Performance

- [ ] Server Components используются где возможно
- [ ] Тяжёлые компоненты — dynamic import
- [ ] Images через next/image
- [ ] Нет N+1 queries

---

## 6. САМОПРОВЕРКА

**Перед добавлением проблемы в отчёт:**

| Вопрос | Если "нет" → не включай |
| -------- | ------------------------- |
| Это влияет на **работоспособность** или **maintainability**? | Косметика не критична |
| **Исправление принесёт пользу**? | Рефакторинг ради рефакторинга — пустая трата |
| Это **нарушение** принятых паттернов? | Проверь существующий код |

**НЕ включай в отчёт:**

| Кажется проблемой | Почему может не быть |
| ------------------- | --------------------- |
| "Нет комментариев" | TypeScript + хорошие имена = self-documenting |
| "Можно было бы лучше" | Без конкретики не actionable |
| "'use client' много" | Если интерактивность нужна — OK |

---

## 7. ФОРМАТ ОТЧЁТА

```markdown
# Code Review Report — [Project Name]
Дата: [дата]
Scope: [какие файлы/коммиты проверены]

## Summary

| Категория | Проблем | Критичных |
|-----------|---------|-----------|
| Architecture | X | X |
| Code Quality | X | X |
| TypeScript | X | X |
| Security | X | X |
| Performance | X | X |

## CRITICAL Issues

| # | Файл | Строка | Проблема | Решение |
|---|------|--------|----------|---------|
| 1 | route.ts | 45 | Нет auth check | Добавить getServerSession |

## Code Suggestions

### 1. Добавить auth проверку

```typescript
// Было (app/api/projects/route.ts:10-15)
export async function POST(request: Request) {
  const data = await request.json();
  // ...
}

// Стало
import { getServerSession } from 'next-auth';

export async function POST(request: Request) {
  const session = await getServerSession(authOptions);
  if (!session) {
    return Response.json({ error: 'Unauthorized' }, { status: 401 });
  }
  const data = await request.json();
  // ...
}
```text

## Good Practices Found

- [Что хорошо]

```text

---

## 8. ДЕЙСТВИЯ

1. **Запусти Quick Check** — 5 минут
2. **Определи scope** — какие файлы проверять
3. **Пройди по категориям** — Architecture, Code Quality, Security
4. **Самопроверка** — отфильтруй ложные срабатывания
5. **Приоритизируй** — Critical → Low
6. **Покажи fixes** — конкретный код до/после

Начни code review. Покажи scope и summary первым.
