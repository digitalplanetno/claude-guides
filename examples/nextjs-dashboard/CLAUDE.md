# Analytics Dashboard — Claude Code Instructions

## Project Overview

**Framework:** Next.js 14 (App Router) + TypeScript
**Type:** Analytics dashboard with AI insights
**Description:** Real-time analytics dashboard with AI-powered insights and report generation.

---

## Key Directories

```
app/
├── (auth)/            # Auth pages (login, register)
├── (dashboard)/       # Protected dashboard pages
│   ├── analytics/     # Analytics views
│   ├── reports/       # AI-generated reports
│   └── settings/      # User settings
├── api/               # API routes
│   ├── analytics/     # Data endpoints
│   ├── ai/            # AI generation endpoints
│   └── webhooks/      # External webhooks
└── layout.tsx         # Root layout

components/
├── ui/                # shadcn/ui components
├── charts/            # Chart components (Recharts)
├── dashboard/         # Dashboard-specific components
└── ai/                # AI-related components

lib/
├── db/                # Database (Prisma)
├── services/          # Business logic
├── ai/                # AI utilities (Anthropic)
├── schemas/           # Zod schemas
└── utils/             # Helper functions
```

---

## Architecture Decisions

### Server vs Client Components
- **Server Components:** Data fetching, layout, static content
- **Client Components:** Charts, interactive forms, real-time updates
- **Rule:** Start with Server, add 'use client' only when needed

### Data Fetching
- **Server Components:** Direct Prisma queries
- **Client Components:** SWR with API routes
- **Real-time:** WebSocket for live data (separate server)

### AI Integration
- **Provider:** Anthropic Claude API
- **Streaming:** Server-Sent Events for long responses
- **Caching:** Redis cache for repeated queries

---

## Development Workflow

### Running Locally
```bash
npm install
cp .env.example .env.local
npx prisma generate
npx prisma db push
npm run dev
```

### Testing
```bash
npm test                     # Unit tests (Vitest)
npm run test:e2e             # E2E tests (Playwright)
npm run test:coverage        # Coverage report
```

### Building
```bash
npm run build
npm run start
```

---

## Project-Specific Rules

### TypeScript
1. **Strict mode** — No `any`, no `@ts-ignore`
2. **Zod** — All external input validated with Zod
3. **Types** — Shared types in `lib/types/`

### Components
1. **Server first** — Default to Server Components
2. **Props** — Always define interfaces for props
3. **Size** — Max 150 lines per component

### API Routes
1. **Auth** — All routes (except public) check `getServerSession`
2. **Validation** — Input validated with Zod schemas
3. **Errors** — Consistent error response format

### AI
1. **Cost** — Track token usage, implement rate limiting
2. **Streaming** — Use streaming for responses > 100 tokens
3. **Fallback** — Graceful degradation if AI unavailable

---

## Available Prompts

Run audits and reviews using the prompts in `.claude/prompts/`:

- **Security Audit:** Focus on API auth, AI prompt injection, data exposure
- **Performance Audit:** Focus on Server/Client split, bundle size, AI latency
- **Code Review:** Focus on TypeScript, component patterns, AI integration
- **Deploy Checklist:** Vercel deployment, environment variables

---

## Environment Variables

```ini
# App
NEXTAUTH_URL=https://dashboard.example.com
NEXTAUTH_SECRET=your-secret-key-min-32-chars

# Database
DATABASE_URL=postgresql://...

# AI
ANTHROPIC_API_KEY=sk-ant-...

# Analytics (optional)
POSTHOG_KEY=phc_...
```

---

## Contacts

- **Maintainer:** Frontend Team
- **Documentation:** /docs in repo
- **Slack:** #dashboard-dev
