# Performance Audit — Next.js Template

## Цель

Комплексный аудит производительности Next.js приложения. Действуй как Senior Performance Engineer.

---

## 0. QUICK CHECK (5 минут)

| # | Check | Command | Expected |
| --- | ------- | --------- | ---------- |
| 1 | Build | `npm run build` | Success, no warnings |
| 2 | Bundle size | Смотри build output | First Load JS < 200KB |
| 3 | SELECT * | `grep -rn "SELECT \*" lib/ app/ --include="*.ts"` | Минимум |
| 4 | N+1 queries | `grep -rn "for.*await.*query" lib/ app/` | Пусто |
| 5 | Dynamic imports | `grep -rn "dynamic(" app/ components/` | Есть для тяжёлых компонентов |

---

## 0.1 AUTO-CHECK SCRIPT

```bash
#!/bin/bash
# performance-check.sh

echo "⚡ Performance Quick Check — Next.js..."

# 1. Build test
npm run build > /tmp/build.log 2>&1
if [ $? -eq 0 ]; then
    echo "✅ Build: Success"
    BUNDLE=$(grep "First Load JS" /tmp/build.log | head -1)
    echo "   $BUNDLE"
else
    echo "❌ Build: Failed"
fi

# 2. SELECT * queries
SELECT_STAR=$(grep -rn "SELECT \*" lib/ app/ --include="*.ts" 2>/dev/null | wc -l)
[ "$SELECT_STAR" -eq 0 ] && echo "✅ SQL: No SELECT *" || echo "🟡 SQL: Found $SELECT_STAR SELECT * queries"

# 3. N+1 patterns
N_PLUS_1=$(grep -rn "for.*await.*query\|\.map.*await.*query" lib/ app/ --include="*.ts" 2>/dev/null | wc -l)
[ "$N_PLUS_1" -eq 0 ] && echo "✅ N+1: No patterns" || echo "❌ N+1: Found $N_PLUS_1 potential N+1"

# 4. Dynamic imports
DYNAMIC=$(grep -rn "dynamic(" app/ components/ --include="*.tsx" 2>/dev/null | wc -l)
[ "$DYNAMIC" -gt 0 ] && echo "✅ Dynamic: $DYNAMIC dynamic imports" || echo "🟡 Dynamic: No dynamic imports"

# 5. Client components count
USE_CLIENT=$(grep -rn "'use client'" app/ components/ --include="*.tsx" 2>/dev/null | wc -l)
echo "ℹ️  Client components: $USE_CLIENT files"

echo "Done!"
```

---

## 0.2 PROJECT SPECIFICS — [Project Name]

**Что уже оптимизировано:**

- [ ] Bundle analyzer — `@next/bundle-analyzer`
- [ ] Database connection pooling
- [ ] Streaming responses
- [ ] Dynamic imports

**Команда для bundle analysis:**

```bash
ANALYZE=true npm run build
```

---

## 0.3 SEVERITY LEVELS

| Level | Описание | Действие |
| ------- | ---------- | ---------- |
| 🔴 CRITICAL | > 50% деградация, N+1 на главных страницах | Исправить немедленно |
| 🟠 HIGH | 20-50% деградация | Исправить до деплоя |
| 🟡 MEDIUM | 5-20% деградация | Следующий спринт |
| 🔵 LOW | < 5% улучшение | Backlog |

---

## 1. NEXT.JS CORE WEB VITALS

### 1.1 Измерение метрик

```typescript
// app/layout.tsx
'use client';

import { useReportWebVitals } from 'next/web-vitals';

export function WebVitalsReporter() {
  useReportWebVitals((metric) => {
    console.log(metric);
  });
  return null;
}

// Целевые значения:
// LCP (Largest Contentful Paint): < 2.5s
// FID (First Input Delay): < 100ms
// CLS (Cumulative Layout Shift): < 0.1
// TTFB (Time to First Byte): < 800ms
// INP (Interaction to Next Paint): < 200ms
```

- [ ] LCP < 2.5s
- [ ] FID < 100ms
- [ ] CLS < 0.1
- [ ] TTFB < 800ms
- [ ] INP < 200ms

### 1.2 Build Analysis

```bash
npm run build
ANALYZE=true npm run build
```

- [ ] Bundle analyzer настроен
- [ ] Main bundle < 200KB (gzipped)
- [ ] Нет дублирования библиотек
- [ ] Tree shaking работает

---

## 2. SERVER COMPONENTS VS CLIENT COMPONENTS

### 2.1 Аудит 'use client'

```bash
grep -rn "'use client'" app/ components/ --include="*.tsx"
```

```tsx
// ❌ Плохо — весь компонент client без необходимости
'use client';

import { useState } from 'react';

export function ProjectList({ projects }) {
  const [expanded, setExpanded] = useState(false);

  return (
    <div>
      {/* Много статического контента */}
      <h1>Projects</h1>
      <p>Long description...</p>

      {/* Только это интерактивно */}
      <button onClick={() => setExpanded(!expanded)}>Toggle</button>

      {/* Список — статичный */}
      {projects.map(p => <ProjectCard key={p.id} project={p} />)}
    </div>
  );
}

// ✅ Хорошо — разделение
// app/projects/page.tsx (Server Component)
export default async function ProjectsPage() {
  const projects = await getProjects();  // Server-side fetch

  return (
    <div>
      <h1>Projects</h1>
      <p>Long description...</p>

      <ExpandableSection>  {/* Только это client */}
        <div>Details</div>
      </ExpandableSection>

      {projects.map(p => <ProjectCard key={p.id} project={p} />)}
    </div>
  );
}

// components/ExpandableSection.tsx
'use client';

export function ExpandableSection({ children }) {
  const [expanded, setExpanded] = useState(false);

  return (
    <>
      <button onClick={() => setExpanded(!expanded)}>Toggle</button>
      {expanded && children}
    </>
  );
}
```

- [ ] Действительно нужен client-side interactivity?
- [ ] Можно ли вынести интерактивную часть в отдельный компонент?
- [ ] Server Component + Client island pattern используется?

### 2.2 Data Fetching Location

```tsx
// ❌ Плохо — fetch на клиенте
'use client';

export function ProjectList() {
  const [projects, setProjects] = useState([]);

  useEffect(() => {
    fetch('/api/projects').then(r => r.json()).then(setProjects);
  }, []);

  return <div>{projects.map(...)}</div>;
}

// ✅ Хорошо — fetch на сервере
// app/projects/page.tsx (Server Component)
export default async function ProjectsPage() {
  const projects = await db.query('SELECT * FROM projects');
  return <ProjectList projects={projects} />;
}
```

- [ ] Data fetching в Server Components где возможно
- [ ] Нет `useEffect` для начального data fetching
- [ ] API routes только для mutations

---

## 3. DATABASE PERFORMANCE

### 3.1 Query Optimization

```typescript
// ❌ Плохо — SELECT *
const projects = await query('SELECT * FROM projects');

// ❌ Плохо — N+1 запросы
const projects = await query('SELECT * FROM projects');
for (const project of projects) {
  const files = await query('SELECT * FROM files WHERE project_id = ?', [project.id]);
  project.files = files;  // N запросов!
}

// ✅ Хорошо — только нужные поля
const projects = await query(
  'SELECT id, name, created_at FROM projects WHERE user_id = ?',
  [userId]
);

// ✅ Хорошо — JOIN вместо N+1
const projectsWithFiles = await query(`
  SELECT
    p.id, p.name,
    f.id as file_id, f.name as file_name
  FROM projects p
  LEFT JOIN files f ON f.project_id = p.id
  WHERE p.user_id = ?
`, [userId]);
```

- [ ] Нет `SELECT *` для больших таблиц
- [ ] Нет N+1 запросов
- [ ] Используются JOINs где нужно

### 3.2 Indexes

```sql
-- ✅ Хорошо — индексы на часто используемые поля
CREATE TABLE projects (
    id INT PRIMARY KEY AUTO_INCREMENT,
    user_id INT NOT NULL,
    name VARCHAR(255) NOT NULL,
    status ENUM('active', 'archived') DEFAULT 'active',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,

    INDEX idx_user_id (user_id),
    INDEX idx_status (status),
    INDEX idx_user_status (user_id, status)
);
```

- [ ] Foreign keys имеют индексы
- [ ] Поля в WHERE имеют индексы
- [ ] Составные индексы для частых комбинаций

### 3.3 Connection Management

```typescript
// ✅ Connection pooling
import mysql from 'mysql2/promise';

const pool = mysql.createPool({
  host: process.env.DB_HOST,
  user: process.env.DB_USER,
  password: process.env.DB_PASSWORD,
  database: process.env.DB_NAME,
  waitForConnections: true,
  connectionLimit: 10,
  enableKeepAlive: true,
});
```

- [ ] Connection pooling используется
- [ ] `connectionLimit` настроен

### 3.4 Query Patterns

```typescript
// ❌ Плохо — waterfall
const user = await query('SELECT * FROM users WHERE id = ?', [userId]);
const projects = await query('SELECT * FROM projects WHERE user_id = ?', [userId]);
const settings = await query('SELECT * FROM settings WHERE user_id = ?', [userId]);

// ✅ Хорошо — Promise.all для независимых запросов
const [user, projects, settings] = await Promise.all([
  query('SELECT id, name FROM users WHERE id = ?', [userId]),
  query('SELECT id, name FROM projects WHERE user_id = ?', [userId]),
  query('SELECT * FROM settings WHERE user_id = ?', [userId]),
]);
```

- [ ] Независимые запросы через Promise.all
- [ ] Нет waterfall запросов

---

## 4. AI API OPTIMIZATION (если используется)

### 4.1 Streaming Responses

```typescript
// ❌ Плохо — ждём полный ответ
export async function POST(request: Request) {
  const { prompt } = await request.json();

  const response = await anthropic.messages.create({
    model: 'claude-sonnet-4-5-20250929',
    messages: [{ role: 'user', content: prompt }],
  });

  return Response.json({ content: response.content });
}

// ✅ Хорошо — streaming
import { streamText } from 'ai';
import { anthropic } from '@ai-sdk/anthropic';

export async function POST(request: Request) {
  const { prompt } = await request.json();

  const result = await streamText({
    model: anthropic('claude-sonnet-4-5-20250929'),
    prompt,
  });

  return result.toDataStreamResponse();
}
```

- [ ] AI responses используют streaming
- [ ] UI показывает progressive output

### 4.2 Model Selection

```typescript
// ✅ Правильная модель для задачи
function selectModel(task: string): string {
  switch (task) {
    case 'simple-edit':
      return 'claude-haiku-4-5-20251001';  // Дешёвый
    case 'code-generation':
      return 'claude-sonnet-4-5-20250929';  // Баланс
    case 'complex-analysis':
      return 'claude-opus-4-5-20251101';  // Умный
    default:
      return 'claude-sonnet-4-5-20250929';
  }
}
```

- [ ] Haiku для простых задач
- [ ] Sonnet для большинства задач
- [ ] Opus только для сложных задач

### 4.3 Caching AI Responses

```typescript
// ✅ Кэширование для идентичных запросов
import { createHash } from 'crypto';

const responseCache = new Map();
const CACHE_TTL = 5 * 60 * 1000; // 5 минут

function getCacheKey(prompt: string, model: string): string {
  return createHash('sha256').update(`${model}:${prompt}`).digest('hex');
}

export async function POST(request: Request) {
  const { prompt, model } = await request.json();

  const cacheKey = getCacheKey(prompt, model);
  const cached = responseCache.get(cacheKey);

  if (cached && Date.now() - cached.timestamp < CACHE_TTL) {
    return Response.json({ content: cached.response, cached: true });
  }

  const response = await generateCode(prompt, model);

  responseCache.set(cacheKey, {
    response,
    timestamp: Date.now(),
  });

  return Response.json({ content: response });
}
```

- [ ] Идентичные запросы кэшируются
- [ ] TTL для кэша

---

## 5. IMAGE & ASSET OPTIMIZATION

### 5.1 Next.js Image Component

```tsx
// ❌ Плохо — обычный img
<img src="/hero.png" alt="Hero" />

// ✅ Хорошо — next/image
import Image from 'next/image';

<Image
  src="/hero.png"
  alt="Hero"
  width={800}
  height={600}
  priority  // Для above-the-fold
/>

<Image
  src="https://example.com/image.jpg"
  alt="External"
  width={400}
  height={300}
  loading="lazy"  // Для below-the-fold
/>
```

- [ ] Все изображения через `next/image`
- [ ] `priority` для above-the-fold images
- [ ] `loading="lazy"` для below-the-fold
- [ ] remotePatterns настроены для внешних images

### 5.2 Font Optimization

```tsx
// ❌ Плохо — внешние шрифты
<link href="https://fonts.googleapis.com/..." rel="stylesheet" />

// ✅ Хорошо — next/font
import { Inter } from 'next/font/google';

const inter = Inter({
  subsets: ['latin'],
  display: 'swap',
  variable: '--font-inter',
});

export default function RootLayout({ children }) {
  return (
    <html lang="en" className={inter.variable}>
      <body>{children}</body>
    </html>
  );
}
```

- [ ] Шрифты через `next/font`
- [ ] `display: 'swap'` для FOUT

---

## 6. BUNDLE OPTIMIZATION

### 6.1 Dynamic Imports

```tsx
// ❌ Плохо — всё в main bundle
import { CodeMirror } from '@uiw/react-codemirror';
import { HeavyChart } from './HeavyChart';

// ✅ Хорошо — dynamic imports
import dynamic from 'next/dynamic';

const CodeMirror = dynamic(
  () => import('@uiw/react-codemirror').then(mod => mod.default),
  {
    loading: () => <div>Loading editor...</div>,
    ssr: false
  }
);

const HeavyChart = dynamic(
  () => import('./HeavyChart'),
  { loading: () => <ChartSkeleton /> }
);
```

- [ ] CodeMirror / Monaco Editor — dynamic import
- [ ] Chart libraries — dynamic import
- [ ] Модальные окна — dynamic import

### 6.2 Tree Shaking

```typescript
// ❌ Плохо — импорт всей библиотеки
import * as _ from 'lodash';
_.map(arr, fn);

// ✅ Хорошо — named imports
import map from 'lodash/map';
// или lodash-es
import { map } from 'lodash-es';

// Для иконок
import { Home, Settings, User } from 'lucide-react';
```

- [ ] Нет `import *` для tree-shakeable libraries
- [ ] `lodash-es` вместо `lodash`
- [ ] Named imports для иконок

### 6.3 Code Splitting

```typescript
// next.config.ts
const nextConfig = {
  experimental: {
    optimizePackageImports: [
      'lucide-react',
      '@radix-ui/react-icons',
      'lodash-es',
      'framer-motion',
    ],
  },
};
```

- [ ] `optimizePackageImports` настроен

---

## 7. CACHING STRATEGY

### 7.1 Next.js Caching

```typescript
// app/api/projects/route.ts

// ❌ Плохо — нет кэширования
export async function GET() {
  const projects = await getProjects();
  return Response.json(projects);
}

// ✅ Хорошо — с кэшированием
export async function GET() {
  const projects = await getProjects();

  return Response.json(projects, {
    headers: {
      'Cache-Control': 'private, max-age=60, stale-while-revalidate=300',
    },
  });
}
```

```typescript
// Server Components с revalidation
async function getProjects() {
  const res = await fetch('https://api.example.com/projects', {
    next: {
      revalidate: 60,  // ISR
      tags: ['projects'],
    },
  });
  return res.json();
}
```

- [ ] API routes имеют Cache-Control headers
- [ ] ISR для полустатичных данных

---

## 8. RUNTIME PERFORMANCE

### 8.1 React Performance

```tsx
// ❌ Плохо — ненужные re-renders
function ProjectList({ projects, filter }) {
  const handleClick = (id) => console.log(id);  // Новая функция каждый render
  const filtered = projects.filter(p => p.status === filter);  // Каждый render!

  return filtered.map(p => (
    <ProjectCard key={p.id} project={p} onClick={handleClick} />
  ));
}

// ✅ Хорошо — мемоизация
import { useCallback, useMemo, memo } from 'react';

function ProjectList({ projects, filter }) {
  const handleClick = useCallback((id) => console.log(id), []);

  const filtered = useMemo(
    () => projects.filter(p => p.status === filter),
    [projects, filter]
  );

  return filtered.map(p => (
    <ProjectCard key={p.id} project={p} onClick={handleClick} />
  ));
}

const ProjectCard = memo(function ProjectCard({ project, onClick }) {
  return <div onClick={() => onClick(project.id)}>{project.name}</div>;
});
```

- [ ] useCallback для event handlers
- [ ] useMemo для expensive computations
- [ ] memo для компонентов с объектами/функциями в props

### 8.2 List Virtualization

```tsx
// ❌ Плохо — рендер всех элементов
function FileList({ files }) {
  return files.map(file => <FileItem key={file.id} file={file} />);
}

// ✅ Хорошо — виртуализация для > 100 items
import { useVirtualizer } from '@tanstack/react-virtual';

function FileList({ files }) {
  const parentRef = useRef(null);

  const virtualizer = useVirtualizer({
    count: files.length,
    getScrollElement: () => parentRef.current,
    estimateSize: () => 50,
  });

  return (
    <div ref={parentRef} style={{ height: '400px', overflow: 'auto' }}>
      <div style={{ height: virtualizer.getTotalSize() }}>
        {virtualizer.getVirtualItems().map((virtualItem) => (
          <div key={virtualItem.key} style={{ position: 'absolute', top: virtualItem.start }}>
            <FileItem file={files[virtualItem.index]} />
          </div>
        ))}
      </div>
    </div>
  );
}
```

- [ ] Виртуализация для списков > 100 items

### 8.3 Debounce & Throttle

```typescript
// ❌ Плохо — запрос на каждый keystroke
function Search() {
  const [query, setQuery] = useState('');

  useEffect(() => {
    fetch(`/api/search?q=${query}`);  // Каждый символ!
  }, [query]);
}

// ✅ Хорошо — debounced
import { useDebounce } from 'usehooks-ts';

function Search() {
  const [query, setQuery] = useState('');
  const debouncedQuery = useDebounce(query, 300);

  useEffect(() => {
    if (debouncedQuery) {
      fetch(`/api/search?q=${debouncedQuery}`);
    }
  }, [debouncedQuery]);
}
```

- [ ] Search inputs debounced
- [ ] AI prompts debounced

---

## 9. САМОПРОВЕРКА

**Перед добавлением проблемы в отчёт:**

| Вопрос | Если "нет" → исключить |
| -------- | ------------------------ |
| Это влияет на **runtime**? | Если только на build time — не критично |
| **Tree-shaking** не решает это? | Современные бандлеры умные |
| У меня есть **измеримые данные**? | "Может быть медленно" ≠ проблема |
| **Исправление** даст ощутимый эффект? | < 5ms не нужны |

**НЕ включай в отчёт:**

| Кажется проблемой | Почему не проблема |
| ------------------- | --------------------- |
| "Большой пакет в node_modules" | Tree-shaking включает только используемое |
| "Много зависимостей" | Важен размер бандла, не node_modules |
| "Старая версия библиотеки" | Если работает — не performance issue |

---

## 10. ФОРМАТ ОТЧЁТА

```markdown
# Performance Audit Report — [Project Name]
Дата: [дата]

## Core Web Vitals

| Metric | Current | Target | Status |
|--------|---------|--------|--------|
| LCP | Xs | < 2.5s | ✅/❌ |
| FID | Xms | < 100ms | ✅/❌ |
| CLS | X | < 0.1 | ✅/❌ |
| TTFB | Xms | < 800ms | ✅/❌ |

## Bundle Size

| Chunk | Size (gzip) | Status |
|-------|-------------|--------|
| Main | XKB | ✅/❌ |
| Vendor | XKB | ✅/❌ |

## 🔴 Critical Issues

| # | Issue | Location | Impact | Solution |
|---|-------|----------|--------|----------|
| 1 | N+1 queries | lib/db.ts | ~500ms | Add JOIN |

## Recommendations

1. Add virtualization to file list
2. Implement response caching
```

---

## 11. ДЕЙСТВИЯ

1. **Измерь** — Web Vitals, bundle size, DB queries
2. **Приоритизируй** — влияние на UX
3. **Особое внимание**:
   - Server vs Client Components
   - Database queries (N+1, indexes)
   - Bundle size (dynamic imports)
4. **Оптимизируй** — начни с critical

Начни аудит. Покажи метрики и summary.
