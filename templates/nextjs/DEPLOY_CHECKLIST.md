# Deploy Checklist — Next.js Template

## Цель

Комплексная проверка перед деплоем Next.js приложения. Действуй как Senior DevOps Engineer.

---

## 0. QUICK CHECK (5 минут)

| # | Check | Command | Expected |
|---|-------|---------|----------|
| 1 | Build | `npm run build` | Success |
| 2 | Lint | `npm run lint` | No errors |
| 3 | Tests | `npm test` | Pass |
| 4 | TypeScript | Проверяется при build | No errors |
| 5 | console.log | `grep -rn "console.log" app/` | Minimal |
| 6 | Env vars | Все нужные переменные | Set |

**Если все 6 = OK → Можно деплоить!**

---

## 0.1 AUTO-CHECK SCRIPT

```bash
#!/bin/bash
# deploy-check.sh

set -e

echo "Pre-deploy Check for Next.js..."

# 1. Build
npm run build > /dev/null 2>&1 && echo "✅ Build" || { echo "❌ Build failed"; exit 1; }

# 2. Lint
npm run lint > /dev/null 2>&1 && echo "✅ Lint" || echo "🟡 Lint has warnings"

# 3. Tests (if exists)
if npm run test --if-present > /dev/null 2>&1; then
    echo "✅ Tests"
else
    echo "🟡 Tests failed or not configured"
fi

# 4. console.log check
CONSOLE=$(grep -rn "console.log" app/ components/ lib/ --include="*.ts" --include="*.tsx" 2>/dev/null | wc -l)
[ "$CONSOLE" -lt 10 ] && echo "✅ console.log: $CONSOLE" || echo "🟡 console.log: $CONSOLE (много)"

# 5. Check for required env vars
if [ -f ".env.example" ]; then
    MISSING=$(grep -v "^#" .env.example | cut -d= -f1 | while read var; do
        [ -z "${!var}" ] && echo "$var"
    done)
    [ -z "$MISSING" ] && echo "✅ Env vars set" || echo "🟡 Missing env vars: $MISSING"
fi

echo ""
echo "Ready to deploy!"
```text

---

## 0.2 PROJECT SPECIFICS — [Project Name]

**Deployment target:**

- **Platform**: [Vercel / Server / Docker]
- **URL**: [https://...]
- **Region**: [eu-central-1 / etc]

**Database:**

- **Type**: [MySQL / PostgreSQL / SQLite]
- **Host**: [host]
- **Connection**: см. `DATABASE_URL` в env

**Важные переменные:**

- `DATABASE_URL` — подключение к БД
- `NEXTAUTH_SECRET` — секрет для auth
- `NEXTAUTH_URL` — URL приложения

---

## 0.3 DEPLOY TYPES

| Тип | Когда | Чеклист |
|-----|-------|---------|
| Hotfix | Критичный баг | Quick Check только |
| Minor | Мелкие изменения | Quick Check + секция 1 |
| Feature | Новая функциональность | Секции 0-6 |
| Major | Архитектурные изменения | Весь чеклист |

---

## 1. PRE-DEPLOYMENT CODE CLEANUP

### 1.1 Debug Code Removal

```bash
grep -rn "console.log" app/ components/ lib/ --include="*.ts" --include="*.tsx"
grep -rn "console.error" app/ components/ lib/ --include="*.ts" --include="*.tsx"
grep -rn "debugger" app/ components/ lib/ --include="*.ts" --include="*.tsx"
```text

- [ ] Нет лишних `console.log()`
- [ ] Нет `debugger` statements
- [ ] Нет тестовых данных в коде

### 1.2 TODO/FIXME

```bash
grep -rn "TODO\|FIXME" app/ components/ lib/ --include="*.ts" --include="*.tsx"
```text

- [ ] Критичные TODO решены
- [ ] Нет blocking FIXME

### 1.3 Commented Code

- [ ] Нет закомментированного кода
- [ ] Нет старых версий функций

---

## 2. CODE QUALITY CHECKS

### 2.1 Build & TypeScript

```bash
npm run build
```text

- [ ] Build проходит без ошибок
- [ ] Нет TypeScript errors
- [ ] Bundle size в норме (< 200KB First Load)

### 2.2 Linting

```bash
npm run lint
```text

- [ ] Нет ESLint errors
- [ ] Warnings проверены

### 2.3 Tests

```bash
npm test
```text

- [ ] Все тесты проходят
- [ ] Критичный функционал покрыт

---

## 3. DATABASE PREPARATION

### 3.1 Migrations

```bash
# Prisma
npx prisma migrate status
npx prisma migrate deploy

# Drizzle
npx drizzle-kit push

# Raw SQL
# Check pending migrations
```text

- [ ] Все миграции применены
- [ ] Нет pending migrations
- [ ] Schema в синхронизации

### 3.2 Backup

```bash
# MySQL
mysqldump -u USER -p DATABASE > backup_$(date +%Y%m%d).sql

# PostgreSQL
pg_dump DATABASE > backup_$(date +%Y%m%d).sql
```text

- [ ] Backup создан перед миграциями
- [ ] Backup проверен на восстановимость

---

## 4. ENVIRONMENT CONFIGURATION

### 4.1 Production Environment Variables

```ini
# Обязательные
NODE_ENV=production
NEXTAUTH_URL=https://your-domain.com
NEXTAUTH_SECRET=your-super-secret-key-min-32-chars

# Database
DATABASE_URL=mysql://user:password@host:3306/db

# API Keys (на сервере, не в NEXT_PUBLIC_)
ANTHROPIC_API_KEY=sk-...
```text

- [ ] `NODE_ENV=production`
- [ ] `NEXTAUTH_URL` — правильный production URL
- [ ] `NEXTAUTH_SECRET` — сильный ключ (min 32 chars)
- [ ] Database URL правильный

### 4.2 Secrets Check

```bash
# Проверить что нет secrets в коде
grep -rn "sk-\|password=\|secret=" app/ lib/ components/ --include="*.ts" --include="*.tsx"

# Проверить что secrets не в NEXT_PUBLIC_
grep -rn "NEXT_PUBLIC_.*KEY\|NEXT_PUBLIC_.*SECRET" .env*
```text

- [ ] Нет hardcoded secrets
- [ ] API keys не в `NEXT_PUBLIC_`
- [ ] `.env.local` в `.gitignore`

### 4.3 Environment Variables Comparison

```bash
# Сравнить .env.example с production
diff .env.example .env.production
```text

- [ ] Все переменные из `.env.example` установлены
- [ ] Нет development значений в production

---

## 5. BUILD PROCESS

### 5.1 Clean Build

```bash
rm -rf .next node_modules
npm ci
npm run build
```text

- [ ] `npm ci` успешен
- [ ] `npm run build` успешен
- [ ] Нет warnings при build

### 5.2 Bundle Analysis

```bash
# Если настроен bundle analyzer
ANALYZE=true npm run build

# Проверить размер
ls -la .next/static/chunks/
```text

- [ ] Main bundle < 200KB (gzipped)
- [ ] Нет дублирования библиотек
- [ ] Тяжёлые пакеты split'ятся

---

## 6. SECURITY PRE-CHECK

### 6.1 Dependencies Audit

```bash
npm audit
npm audit --production
```text

- [ ] Нет critical уязвимостей
- [ ] High уязвимости проверены

### 6.2 Security Headers

```typescript
// next.config.ts
const nextConfig = {
  async headers() {
    return [
      {
        source: '/:path*',
        headers: [
          { key: 'X-Content-Type-Options', value: 'nosniff' },
          { key: 'X-Frame-Options', value: 'DENY' },
          { key: 'X-XSS-Protection', value: '1; mode=block' },
          { key: 'Referrer-Policy', value: 'strict-origin-when-cross-origin' },
        ],
      },
    ];
  },
};
```text

- [ ] Security headers настроены
- [ ] HTTPS обязателен

### 6.3 API Security

- [ ] Все protected API routes проверяют auth
- [ ] Rate limiting на expensive endpoints
- [ ] Input validation через Zod

---

## 7. DEPLOYMENT

### 7.1 Vercel Deployment

```bash
# Через CLI
vercel --prod

# Или через Git push
git push origin main
```text

- [ ] Vercel project настроен
- [ ] Environment variables в Vercel dashboard
- [ ] Production branch = main

### 7.2 Server Deployment

```bash
#!/bin/bash
# deploy.sh

set -e

APP_DIR="/opt/app"
DATE=$(date +%Y%m%d_%H%M%S)

cd $APP_DIR

# 1. Pull code
git pull origin main

# 2. Install dependencies
npm ci

# 3. Build
npm run build

# 4. Database migrations
npx prisma migrate deploy

# 5. Restart application
pm2 restart app || pm2 start npm --name "app" -- start

echo "Deployment completed!"

# 6. Health check
sleep 5
curl -s https://your-domain.com/api/health | grep -q "ok" && echo "✅ Health check passed" || echo "❌ Health check failed"
```text

---

## 8. POST-DEPLOYMENT VERIFICATION

### 8.1 Smoke Tests

```bash
# Базовые проверки
curl -I https://your-domain.com
curl -I https://your-domain.com/api/health
```text

Проверь вручную:

- [ ] Homepage загружается
- [ ] Логин работает
- [ ] Основной функционал работает
- [ ] API endpoints отвечают

### 8.2 Error Monitoring

- [ ] Vercel logs чистые
- [ ] Нет 500 errors
- [ ] Error rate не вырос

### 8.3 Performance Check

```bash
# Lighthouse
npx lighthouse https://your-domain.com --view

# TTFB check
curl -w "TTFB: %{time_starttransfer}s\n" -o /dev/null -s https://your-domain.com
```text

- [ ] LCP < 2.5s
- [ ] TTFB < 800ms
- [ ] Нет заметного замедления

---

## 9. ROLLBACK PLAN

### 9.1 Vercel Rollback

```bash
# Через UI: Deployments → Select previous → Promote to Production

# Через CLI
vercel rollback
```text

### 9.2 Server Rollback

```bash
#!/bin/bash
# rollback.sh

cd /opt/app

# Откат к предыдущему коммиту
git reset --hard HEAD~1

# Rebuild
npm ci
npm run build

# Restart
pm2 restart app
```text

### 9.3 Database Rollback

```bash
# Prisma
npx prisma migrate reset  # ОСТОРОЖНО! Удаляет данные

# Восстановление из backup
mysql -u USER -p DATABASE < backup_YYYYMMDD.sql
```text

### 9.4 Rollback Triggers

Откатывай если:

- Error rate > 5%
- Critical функционал не работает
- Performance деградировал > 50%

---

## 10. САМОПРОВЕРКА

**НЕ блокируй деплой из-за:**

| Кажется блокером | Почему не блокер |
|------------------|------------------|
| "ESLint warnings" | Если build проходит — OK |
| "Deprecated package" | Если работает — обнови позже |
| "console.log в коде" | Не критично |
| "Нет тестов" | Если функционал работает — OK |
| "Большой bundle" | Если < 500KB — приемлемо |

**Градация готовности:**

```text
READY (95-100%) — Деплой сейчас
   - Build проходит
   - Критичный функционал работает
   - Нет security blockers

ACCEPTABLE (70-94%) — Деплой возможен
   - Есть warnings но не errors
   - Minor issues можно пофиксить после

NOT READY (<70%) — Блокируй
   - Build падает
   - Security vulnerabilities
   - Критичный функционал сломан
```text

---

## 11. ФОРМАТ ОТЧЁТА

```markdown
# Deploy Checklist Report — [Project Name]
Date: [дата]
Version: [git commit hash]

## Summary

| Step | Status |
|------|--------|
| Build | ✅/❌ |
| Tests | ✅/❌ |
| Env vars | ✅/❌ |
| Security | ✅/❌ |
| Deploy | ✅/❌ |
| Verify | ✅/❌ |

**Readiness**: XX% — [READY/ACCEPTABLE/NOT READY]

## Blockers
- [Если есть]

## Warnings
- [Если есть]

## Post-Deploy
- [ ] Monitor for 24h
- [ ] Check error rate
- [ ] Verify performance
```text

---

## 12. ДЕЙСТВИЯ

1. **Проверь** — пройди чеклист
2. **Backup** — создай backup БД
3. **Deploy** — выполни deployment
4. **Verify** — проверь что работает
5. **Monitor** — следи за метриками

Ответь: "OK: Готов к деплою (XX%)" или "FAIL: Проблемы: [список]"
