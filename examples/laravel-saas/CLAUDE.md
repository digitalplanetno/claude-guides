# MySaaS — Claude Code Instructions

## Project Overview

**Framework:** Laravel 11 + Vue 3 + Inertia.js
**Type:** Multi-tenant SaaS application
**Description:** B2B SaaS platform with subscription billing, team management, and API access.

---

## Key Directories

```
app/
├── Actions/           # Single-purpose action classes
├── Http/
│   ├── Controllers/   # Thin controllers (delegate to Actions)
│   ├── Middleware/    # Auth, tenant, subscription checks
│   └── Requests/      # Form validation
├── Models/            # Eloquent models with scopes
├── Services/          # Business logic (PaymentService, etc.)
├── Jobs/              # Background jobs (email, billing, etc.)
└── Policies/          # Authorization policies

resources/
├── js/
│   ├── Pages/         # Inertia pages
│   ├── Components/    # Vue components
│   └── Composables/   # Vue composables
└── views/             # Blade templates (emails, PDF)

database/
├── migrations/        # Schema migrations
└── seeders/           # Development data
```

---

## Architecture Decisions

### Multi-tenancy
- **Model:** Single database, `tenant_id` column
- **Scoping:** Global scope `TenantScope` on all tenant models
- **Switching:** Middleware sets current tenant from subdomain

### Billing
- **Provider:** Stripe via Laravel Cashier
- **Plans:** Free, Pro ($29/mo), Enterprise (custom)
- **Enforcement:** `SubscriptionMiddleware` checks plan limits

### Background Jobs
- **Queue:** Redis with Horizon
- **Workers:** 3 workers, default/high/low queues
- **Monitoring:** Horizon dashboard at `/horizon`

---

## Development Workflow

### Running Locally
```bash
composer install
npm install
cp .env.example .env
php artisan key:generate
php artisan migrate --seed
npm run dev
php artisan serve
```

### Testing
```bash
php artisan test                    # All tests
php artisan test --filter=Billing   # Specific
php artisan test --coverage         # Coverage report
```

### Building
```bash
npm run build
php artisan config:cache
php artisan route:cache
```

---

## Project-Specific Rules

### Code Style
1. **Controllers** — Max 5 methods, delegate to Actions
2. **Actions** — Single responsibility, `handle()` method
3. **Services** — Stateless, injected via constructor
4. **Models** — No business logic, only relationships and scopes

### Naming
- Actions: `CreateUser`, `UpdateSubscription` (verb + noun)
- Jobs: `SendWelcomeEmail`, `ProcessPayment` (verb + noun)
- Events: `UserCreated`, `SubscriptionCanceled` (noun + past tense)

### Security
- All tenant data queries MUST use `TenantScope`
- API keys stored in `api_keys` table, hashed
- Rate limiting: 60/min for API, 1000/min for webhooks

---

## Available Prompts

Run audits and reviews using the prompts in `.claude/prompts/`:

- **Security Audit:** Focus on tenant isolation, API auth, payment security
- **Performance Audit:** Focus on N+1, queue optimization, caching
- **Code Review:** Focus on SRP, tenant scoping, billing logic
- **Deploy Checklist:** Include Horizon restart, Stripe webhook check

---

## Environment Variables

```ini
# Required
APP_ENV=production
APP_DEBUG=false
APP_URL=https://app.mysaas.com

# Database
DB_CONNECTION=mysql
DB_HOST=127.0.0.1
DB_DATABASE=mysaas

# Redis (sessions, cache, queue)
REDIS_HOST=127.0.0.1
CACHE_DRIVER=redis
SESSION_DRIVER=redis
QUEUE_CONNECTION=redis

# Stripe
STRIPE_KEY=pk_live_...
STRIPE_SECRET=sk_live_...
STRIPE_WEBHOOK_SECRET=whsec_...

# Mail
MAIL_MAILER=ses
```

---

## Contacts

- **Maintainer:** Team Lead
- **Documentation:** https://docs.mysaas.com
- **Slack:** #mysaas-dev
