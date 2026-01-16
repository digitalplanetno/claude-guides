# Security Audit — Next.js Template

## Цель

Комплексный аудит безопасности Next.js приложения. Действуй как Senior Security Engineer.

> **⚠️ Рекомендуемая модель:** Используй **Claude Opus 4.5** (`claude-opus-4-5-20251101`) для проведения аудитов — лучше работает с анализом кода.

---

## 0. QUICK CHECK (5 минут)

| # | Check | Command | Expected |
| --- | ------- | --------- | ---------- |
| 1 | Auth на API | `find app/api -name "route.ts" -exec grep -L "getServerSession\|auth" {} \;` | Пусто (или только public endpoints) |
| 2 | Secrets в коде | `grep -rn "sk-\|password.*=.*['\"]" app/ lib/ --include="*.ts"` | Пусто |
| 3 | SQL injection | `grep -rn "SELECT.*\${" lib/ app/ --include="*.ts"` | Пусто |
| 4 | npm audit | `npm audit --production` | No critical/high |
| 5 | Env exposure | `grep -rn "NEXT_PUBLIC_.*KEY\|NEXT_PUBLIC_.*SECRET" .env*` | Пусто |

Если все 5 = OK → Базовый уровень безопасности OK.

---

## 0.1 AUTO-CHECK SCRIPT

```bash
#!/bin/bash
# security-check.sh

echo "🔐 Security Quick Check — Next.js..."

# 1. Unprotected API routes
UNPROTECTED=$(find app/api -name "route.ts" -exec grep -L "getServerSession\|auth" {} \; 2>/dev/null | grep -v "health\|webhook")
[ -z "$UNPROTECTED" ] && echo "✅ Auth: All API routes protected" || echo "❌ Auth: Unprotected routes found"

# 2. Hardcoded secrets
SECRETS=$(grep -rn "sk-\|api_key.*=.*['\"][a-zA-Z0-9]" app/ lib/ components/ --include="*.ts" --include="*.tsx" 2>/dev/null | grep -v "node_modules")
[ -z "$SECRETS" ] && echo "✅ Secrets: No hardcoded keys" || echo "❌ Secrets: Found hardcoded keys!"

# 3. SQL injection patterns
SQLI=$(grep -rn 'SELECT.*\${\|INSERT.*\${\|UPDATE.*\${' lib/ app/ --include="*.ts" 2>/dev/null)
[ -z "$SQLI" ] && echo "✅ SQL: No injection patterns" || echo "❌ SQL: Potential injection!"

# 4. npm audit
npm audit --production 2>/dev/null | grep -q "critical\|high" && echo "❌ NPM: Critical vulnerabilities" || echo "✅ NPM: No critical issues"

# 5. Env exposure
EXPOSED=$(grep -rn "NEXT_PUBLIC_.*KEY\|NEXT_PUBLIC_.*SECRET\|NEXT_PUBLIC_.*PASSWORD" .env* 2>/dev/null)
[ -z "$EXPOSED" ] && echo "✅ Env: No secrets exposed" || echo "❌ Env: Secrets in NEXT_PUBLIC_!"

# 6. dangerouslySetInnerHTML
DANGEROUS=$(grep -rn "dangerouslySetInnerHTML" app/ components/ --include="*.tsx" 2>/dev/null | wc -l)
[ "$DANGEROUS" -eq 0 ] && echo "✅ XSS: No dangerouslySetInnerHTML" || echo "🟡 XSS: $DANGEROUS uses (verify sanitization)"

echo "Done!"
```

---

## 0.2 PROJECT SPECIFICS — [Project Name]

**Заполни перед аудитом:**

**Что уже реализовано:**

- [ ] Authentication: [NextAuth / custom / none]
- [ ] Authorization: [middleware / API checks]
- [ ] Input validation: [Zod / yup / other]
- [ ] Database: [Prisma / Drizzle / raw SQL / MySQL]

**Публичные endpoints (by design):**

- `/api/health` — health check
- `/api/auth/*` — NextAuth endpoints (если используется)
- `/api/webhooks/*` — webhooks (проверь signature!)

---

## 0.3 SEVERITY LEVELS

| Level | Описание | Действие |
| ------- | ---------- | ---------- |
| 🔴 CRITICAL | Эксплуатируемая уязвимость, RCE, SQLi, auth bypass | **БЛОКЕР** — исправить немедленно |
| 🟠 HIGH | Серьёзная уязвимость, требует auth или сложной эксплуатации | Исправить до деплоя |
| 🟡 MEDIUM | Потенциальная уязвимость, низкий риск | Исправить в ближайшем спринте |
| 🔵 LOW | Best practice, defense in depth | Backlog |
| ⚪ INFO | Информация, не требует действий | — |

---

## 1. API ROUTES SECURITY

### 1.1 Authentication на API Routes

```typescript
// ❌ КРИТИЧНО — API без аутентификации
// app/api/projects/route.ts
export async function GET(request: Request) {
  const projects = await db.query('SELECT * FROM projects');
  return Response.json(projects);  // Кто угодно может получить!
}

// ✅ Хорошо — полная проверка
import { getServerSession } from 'next-auth';
import { authOptions } from '@/lib/auth';

export async function POST(request: Request) {
  const session = await getServerSession(authOptions);

  if (!session?.user?.id) {
    return Response.json({ error: 'Unauthorized' }, { status: 401 });
  }

  const body = await request.json();

  // Проверка ownership
  const project = await getProject(body.projectId);
  if (project.userId !== session.user.id) {
    return Response.json({ error: 'Forbidden' }, { status: 403 });
  }

  // ... остальная логика
}
```

- [ ] Все protected API routes проверяют session
- [ ] Проверяется ownership ресурсов
- [ ] Публичные routes явно задокументированы

### 1.2 Rate Limiting

```typescript
// ❌ Плохо — нет rate limiting на expensive endpoints
export async function POST(request: Request) {
  const { prompt } = await request.json();
  // Сразу вызываем AI — можно задосить!
}

// ✅ Хорошо — rate limiting
import { Ratelimit } from '@upstash/ratelimit';
import { Redis } from '@upstash/redis';

const ratelimit = new Ratelimit({
  redis: Redis.fromEnv(),
  limiter: Ratelimit.slidingWindow(10, '1 m'),
});

export async function POST(request: Request) {
  const session = await getServerSession(authOptions);
  if (!session?.user?.id) {
    return Response.json({ error: 'Unauthorized' }, { status: 401 });
  }

  const { success, reset } = await ratelimit.limit(`api_${session.user.id}`);

  if (!success) {
    return Response.json({ error: 'Rate limit exceeded', reset }, { status: 429 });
  }

  // ... логика
}
```

- [ ] Expensive endpoints имеют rate limiting
- [ ] Rate limit по user ID, не по IP
- [ ] 429 response с информацией о reset

### 1.3 Request Validation

```typescript
// ❌ Плохо — нет валидации
export async function POST(request: Request) {
  const body = await request.json();
  const result = await processData(body.data);  // Что угодно!
}

// ✅ Хорошо — Zod валидация
import { z } from 'zod';

const RequestSchema = z.object({
  prompt: z.string().min(1).max(10000),
  projectId: z.string().uuid(),
  options: z.object({
    model: z.enum(['gpt-4', 'claude-sonnet-4-5-20250929']).optional(),
  }).optional(),
});

export async function POST(request: Request) {
  const body = await request.json();

  const parsed = RequestSchema.safeParse(body);
  if (!parsed.success) {
    return Response.json(
      { error: 'Invalid request', details: parsed.error.flatten() },
      { status: 400 }
    );
  }

  const { prompt, projectId, options } = parsed.data;
  // ... безопасно использовать
}
```

- [ ] Все API routes валидируют input через Zod
- [ ] String fields имеют max length
- [ ] UUID/ID fields валидируются

---

## 2. INJECTION ATTACKS

### 2.1 SQL Injection

```typescript
// ❌ КРИТИЧНО — SQL Injection
const projects = await query(
  `SELECT * FROM projects WHERE user_id = '${userId}'`
);

// ❌ Плохо — конкатенация
const sql = `SELECT * FROM projects WHERE name LIKE '%${search}%'`;

// ✅ Хорошо — параметризованные запросы
const projects = await query(
  'SELECT * FROM projects WHERE user_id = ?',
  [userId]
);

// ✅ Для LIKE
const projects = await query(
  'SELECT * FROM projects WHERE name LIKE ?',
  [`%${search}%`]
);
```

- [ ] Все SQL используют параметризованные запросы
- [ ] Нет конкатенации user input в SQL
- [ ] LIKE запросы используют параметры

### 2.2 NoSQL/Object Injection

```typescript
// ❌ Опасно — spread user input
const updateData = { ...await request.json() };
await db.update(updateData);

// ✅ Хорошо — явный whitelist
const body = await request.json();
const updateData = {
  name: body.name,
  email: body.email,
  // Только разрешённые поля
};
```

- [ ] User input не spread'ится напрямую
- [ ] Whitelist для разрешённых полей

### 2.3 Command Injection

```typescript
// ❌ КРИТИЧНО — Command Injection
import { exec } from 'child_process';

export async function POST(request: Request) {
  const { command } = await request.json();
  exec(command);  // Полный контроль над сервером!
}

// ✅ Хорошо — whitelist команд
const ALLOWED_COMMANDS = {
  'install': ['npm', 'install'],
  'build': ['npm', 'run', 'build'],
} as const;

export async function POST(request: Request) {
  const { commandType } = await request.json();

  const baseCommand = ALLOWED_COMMANDS[commandType];
  if (!baseCommand) {
    return Response.json({ error: 'Command not allowed' }, { status: 400 });
  }

  spawn(baseCommand[0], baseCommand.slice(1));
}
```

- [ ] Нет прямого выполнения user commands
- [ ] Whitelist разрешённых команд

---

## 3. CROSS-SITE SCRIPTING (XSS)

### 3.1 React/Next.js XSS

```tsx
// ❌ КРИТИЧНО — XSS
<div dangerouslySetInnerHTML={{ __html: userContent }} />

// ✅ Безопасно — React автоматически экранирует
<div>{userContent}</div>

// ✅ Если HTML необходим — санитизация
import DOMPurify from 'dompurify';

<div dangerouslySetInnerHTML={{
  __html: DOMPurify.sanitize(htmlContent, {
    ALLOWED_TAGS: ['p', 'br', 'strong', 'em', 'ul', 'li', 'a'],
    ALLOWED_ATTR: ['href', 'target']
  })
}} />
```

- [ ] Нет `dangerouslySetInnerHTML` с user content без DOMPurify
- [ ] Минимальный whitelist тегов в DOMPurify

### 3.2 URL Injection

```tsx
// ❌ Опасно — user-controlled href
<a href={userProvidedUrl}>Link</a>
// javascript:alert('XSS')

// ✅ Хорошо — валидация URL
function SafeLink({ href, children }) {
  const isValid = href.startsWith('https://') || href.startsWith('/');

  if (!isValid) {
    return <span>{children}</span>;
  }

  return (
    <a href={href} rel="noopener noreferrer" target="_blank">
      {children}
    </a>
  );
}
```

- [ ] User-provided URLs валидируются
- [ ] Нет `javascript:` URLs
- [ ] External links имеют `rel="noopener noreferrer"`

---

## 4. AUTHENTICATION (next-auth)

### 4.1 Configuration

```typescript
// ✅ Безопасная конфигурация
import { compare } from 'bcryptjs';

export const authOptions: NextAuthOptions = {
  secret: process.env.NEXTAUTH_SECRET,  // Обязательно!

  providers: [
    CredentialsProvider({
      async authorize(credentials) {
        if (!credentials?.email || !credentials?.password) {
          return null;
        }

        const user = await db.query(
          'SELECT * FROM users WHERE email = ?',
          [credentials.email]
        );

        if (!user) return null;

        const isValid = await compare(credentials.password, user.password);
        if (!isValid) return null;

        return { id: user.id, email: user.email };
      }
    })
  ],

  session: {
    strategy: 'jwt',
    maxAge: 30 * 24 * 60 * 60,
  },
};
```

- [ ] `NEXTAUTH_SECRET` установлен и сильный (min 32 chars)
- [ ] `NEXTAUTH_URL` правильный для production
- [ ] Пароли хэшируются (bcryptjs)
- [ ] Параметризованные SQL запросы

### 4.2 Middleware Protection

```typescript
// middleware.ts
import { withAuth } from 'next-auth/middleware';

export default withAuth({
  pages: { signIn: '/auth/signin' },
});

export const config = {
  matcher: [
    '/dashboard/:path*',
    '/api/projects/:path*',
    '/api/generate-:path*',
  ],
};
```

- [ ] middleware.ts защищает нужные routes
- [ ] Нет доступа к чужим данным

---

## 5. SSRF (Server-Side Request Forgery)

### 5.1 URL Validation

```typescript
// ❌ КРИТИЧНО — SSRF
export async function POST(request: Request) {
  const { url } = await request.json();
  const response = await fetch(url);  // Может запросить internal URLs!
  // http://169.254.169.254/latest/meta-data/
}

// ✅ Хорошо — валидация URL
const BLOCKED_HOSTS = [
  'localhost', '127.0.0.1', '0.0.0.0',
  '169.254.169.254',  // AWS metadata
  '10.', '172.16.', '192.168.',
];

function isUrlAllowed(urlString: string): boolean {
  try {
    const url = new URL(urlString);

    if (!['http:', 'https:'].includes(url.protocol)) {
      return false;
    }

    const host = url.hostname.toLowerCase();
    for (const blocked of BLOCKED_HOSTS) {
      if (host === blocked || host.startsWith(blocked)) {
        return false;
      }
    }

    return true;
  } catch {
    return false;
  }
}

export async function POST(request: Request) {
  const { url } = await request.json();

  if (!isUrlAllowed(url)) {
    return Response.json({ error: 'URL not allowed' }, { status: 400 });
  }

  const response = await fetch(url, {
    signal: AbortSignal.timeout(10000),
  });
}
```

- [ ] URL scraping endpoints валидируют URLs
- [ ] Blocked: localhost, internal IPs, cloud metadata
- [ ] Timeout установлен

---

## 6. API KEYS & SECRETS

### 6.1 Environment Variables

```typescript
// ❌ КРИТИЧНО — hardcoded keys
const anthropic = new Anthropic({
  apiKey: 'sk-ant-api03-xxxxx',
});

// ❌ Плохо — key в client-side коде
// components/Generator.tsx
const apiKey = process.env.NEXT_PUBLIC_ANTHROPIC_KEY;  // Видно в браузере!

// ✅ Хорошо — только на сервере
// app/api/generate/route.ts (server-side)
const anthropic = new Anthropic({
  apiKey: process.env.ANTHROPIC_API_KEY,  // Без NEXT_PUBLIC_
});
```

- [ ] Нет hardcoded API keys
- [ ] AI/DB keys без `NEXT_PUBLIC_` prefix
- [ ] Все secrets в `.env.local`, не в коде
- [ ] `.env.local` в `.gitignore`

### 6.2 Client-Side Exposure

```ini
# ✅ Можно NEXT_PUBLIC_
NEXT_PUBLIC_APP_URL=https://your-app.com
NEXT_PUBLIC_ANALYTICS_ID=GA-xxxxx

# ❌ НЕ должно быть NEXT_PUBLIC_
# NEXT_PUBLIC_API_KEY=sk-...
# NEXT_PUBLIC_DATABASE_URL=...
```

- [ ] Только безопасные переменные имеют `NEXT_PUBLIC_`
- [ ] API keys, database URLs — без `NEXT_PUBLIC_`

---

## 7. FILE HANDLING

### 7.1 File Upload Security

```typescript
// ❌ Плохо — нет валидации
export async function POST(request: Request) {
  const formData = await request.formData();
  const file = formData.get('file') as File;
  // Сохраняем как есть
}

// ✅ Хорошо — валидация
const ALLOWED_TYPES = ['image/jpeg', 'image/png', 'image/webp'];
const MAX_SIZE = 10 * 1024 * 1024; // 10MB

export async function POST(request: Request) {
  const formData = await request.formData();
  const file = formData.get('file') as File;

  if (!file) {
    return Response.json({ error: 'No file' }, { status: 400 });
  }

  if (!ALLOWED_TYPES.includes(file.type)) {
    return Response.json({ error: 'Invalid file type' }, { status: 400 });
  }

  if (file.size > MAX_SIZE) {
    return Response.json({ error: 'File too large' }, { status: 400 });
  }

  // Генерируем безопасное имя
  const safeName = `${nanoid()}.${file.name.split('.').pop()}`;
}
```

- [ ] File type валидируется
- [ ] File size ограничен
- [ ] Filename генерируется

### 7.2 Path Traversal

```typescript
// ❌ КРИТИЧНО — Path Traversal
const filePath = `./uploads/${req.query.filename}`;
// filename: "../../../etc/passwd"

// ✅ Хорошо — санитизация пути
import path from 'path';

const filename = path.basename(req.query.filename);
const filePath = path.join('./uploads', filename);

if (!filePath.startsWith(path.resolve('./uploads'))) {
  throw new Error('Invalid path');
}
```

- [ ] Все file paths санитизируются
- [ ] `path.basename()` для user-provided filenames

---

## 8. SECURITY HEADERS

### 8.1 Next.js Config

```typescript
// next.config.ts
const nextConfig = {
  async headers() {
    return [
      {
        source: '/:path*',
        headers: [
          { key: 'X-DNS-Prefetch-Control', value: 'on' },
          { key: 'Strict-Transport-Security', value: 'max-age=63072000; includeSubDomains; preload' },
          { key: 'X-Content-Type-Options', value: 'nosniff' },
          { key: 'X-Frame-Options', value: 'DENY' },
          { key: 'X-XSS-Protection', value: '1; mode=block' },
          { key: 'Referrer-Policy', value: 'strict-origin-when-cross-origin' },
          { key: 'Permissions-Policy', value: 'camera=(), microphone=(), geolocation=()' },
        ],
      },
    ];
  },
};
```

- [ ] Security headers в next.config.ts
- [ ] HSTS включен для production
- [ ] X-Frame-Options = DENY

### 8.2 CORS

```typescript
// ❌ Плохо
headers.set('Access-Control-Allow-Origin', '*');

// ✅ Хорошо — конкретные origins
const allowedOrigins = [
  'https://your-app.com',
  process.env.NODE_ENV === 'development' ? 'http://localhost:3000' : '',
].filter(Boolean);
```

- [ ] CORS не `*` для sensitive API

---

## 9. DEPENDENCY SECURITY

```bash
npm audit
npm audit --json
```

- [ ] `npm audit` без critical/high
- [ ] Зависимости обновлены

---

## 10. САМОПРОВЕРКА

**Перед добавлением уязвимости в отчёт:**

| Вопрос | Если "нет" → пересмотри severity |
| -------- | ---------------------------------- |
| Это **эксплуатируемо** в реальных условиях? | Теоретическая ≠ реальная угроза |
| Есть **путь атаки** для злоумышленника? | Internal-only ≠ CRITICAL |
| **Какой ущерб** при успешной атаке? | Утечка публичных данных ≠ утечка паролей |
| Требуется ли **auth** для эксплуатации? | Auth-required снижает severity |

**Типичные ложные срабатывания:**

| Кажется уязвимостью | Почему может не быть проблемой |
| --------------------- | -------------------------------- |
| "Нет auth на endpoint" | Может быть intentionally public |
| "CORS: *" | Если endpoint auth-protected — не критично |
| "Старая версия пакета" | Если нет CVE — не security issue |

---

## 11. ФОРМАТ ОТЧЁТА

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

### CRIT-001: [Название]
**Location**: `app/api/xxx/route.ts:XX`
**Description**: ...
**Impact**: ...
**Remediation**: ...

## ✅ Security Controls in Place
- [x] NextAuth authentication
- [x] Zod validation
- [ ] Rate limiting on all endpoints
```

---

## 12. ДЕЙСТВИЯ

1. **Quick Check** — пройди 5 пунктов
2. **Сканируй** — пройди все секции
3. **Классифицируй** — Critical → Low
4. **Самопроверка** — фильтруй false positives
5. **Документируй** — файл, строка, код
6. **Исправляй** — предложи конкретный fix

Начни аудит. Сначала Quick Check, потом Executive Summary.
