# Quick Check Scripts

Bash-скрипты для быстрых автоматических проверок.

---

## Universal Checks

```bash
#!/bin/bash
# quick-check.sh — универсальные проверки

echo "🔐 Quick Security Check..."

# 1. Hardcoded secrets
SECRETS=$(grep -rn "sk-\|api_key.*=.*['\"][a-zA-Z0-9]" . --include="*.php" --include="*.ts" --include="*.js" 2>/dev/null | grep -v "node_modules\|vendor\|.env")
[ -z "$SECRETS" ] && echo "✅ Secrets: No hardcoded keys" || echo "❌ Secrets: Found hardcoded keys!"

# 2. Debug code
DEBUG=$(grep -rn "console.log\|var_dump\|print_r\|dd(" . --include="*.php" --include="*.ts" --include="*.js" --include="*.vue" 2>/dev/null | grep -v "node_modules\|vendor" | wc -l)
[ "$DEBUG" -lt 5 ] && echo "✅ Debug: $DEBUG debug statements" || echo "🟡 Debug: $DEBUG debug statements found"

# 3. TODO/FIXME
TODOS=$(grep -rn "TODO\|FIXME\|XXX\|HACK" . --include="*.php" --include="*.ts" --include="*.js" 2>/dev/null | grep -v "node_modules\|vendor" | wc -l)
echo "ℹ️  TODO/FIXME: $TODOS comments"

# 4. Large files (>500 lines)
LARGE=$(find . -name "*.php" -o -name "*.ts" -o -name "*.js" | grep -v "node_modules\|vendor" | xargs wc -l 2>/dev/null | awk '$1 > 500 {print $2}' | wc -l)
[ "$LARGE" -eq 0 ] && echo "✅ Files: No large files" || echo "🟡 Files: $LARGE files >500 lines"

echo "Done!"
```

---

## Laravel-Specific

```bash
#!/bin/bash
# laravel-check.sh

echo "🔐 Laravel Security Check..."

# 1. Debug mode
DEBUG=$(grep "APP_DEBUG=true" .env 2>/dev/null)
[ -z "$DEBUG" ] && echo "✅ Debug: APP_DEBUG=false" || echo "❌ Debug: APP_DEBUG=true!"

# 2. Mass assignment vulnerability
GUARDED=$(grep -rn 'guarded\s*=\s*\[\]' app/Models/ 2>/dev/null)
[ -z "$GUARDED" ] && echo "✅ Models: No \$guarded = []" || echo "❌ Models: Found \$guarded = []"

# 3. Raw SQL patterns
RAW_SQL=$(grep -rn 'DB::raw\|whereRaw\|selectRaw\|orderByRaw' app/ --include="*.php" 2>/dev/null | wc -l)
[ "$RAW_SQL" -eq 0 ] && echo "✅ SQL: No raw queries" || echo "🟡 SQL: $RAW_SQL raw queries (verify bindings)"

# 4. dd()/dump()
DD_CALLS=$(grep -rn "dd(\|dump(" app/ --include="*.php" 2>/dev/null | wc -l)
[ "$DD_CALLS" -eq 0 ] && echo "✅ Debug: No dd()/dump()" || echo "❌ Debug: $DD_CALLS dd()/dump() calls"

# 5. env() outside config
ENV_CALLS=$(grep -rn "env(" app/ routes/ --include="*.php" 2>/dev/null | wc -l)
[ "$ENV_CALLS" -eq 0 ] && echo "✅ Config: No env() outside config/" || echo "❌ Config: $ENV_CALLS env() calls outside config/"

# 6. composer audit
composer audit 2>/dev/null | grep -q "No security" && echo "✅ Composer: No vulnerabilities" || echo "🟡 Composer: Run 'composer audit'"

# 7. npm audit
npm audit --production 2>/dev/null | grep -q "found 0" && echo "✅ NPM: No vulnerabilities" || echo "🟡 NPM: Run 'npm audit'"

echo "Done!"
```

---

## Next.js-Specific

```bash
#!/bin/bash
# nextjs-check.sh

echo "🔐 Next.js Security Check..."

# 1. Unprotected API routes (basic check)
UNPROTECTED=$(find app/api -name "route.ts" -exec grep -L "getServerSession\|requireAuth\|auth" {} \; 2>/dev/null | grep -v "health\|webhook")
[ -z "$UNPROTECTED" ] && echo "✅ Auth: All API routes protected" || echo "🟡 Auth: Check routes: $UNPROTECTED"

# 2. Hardcoded API keys
SECRETS=$(grep -rn "sk-ant\|sk-proj\|sk-" app/ lib/ components/ --include="*.ts" --include="*.tsx" 2>/dev/null | grep -v "node_modules")
[ -z "$SECRETS" ] && echo "✅ Secrets: No hardcoded keys" || echo "❌ Secrets: Found hardcoded keys!"

# 3. SQL injection patterns
SQLI=$(grep -rn 'SELECT.*\${\|INSERT.*\${\|UPDATE.*\${' lib/ app/ --include="*.ts" 2>/dev/null)
[ -z "$SQLI" ] && echo "✅ SQL: No injection patterns" || echo "❌ SQL: Potential injection!"

# 4. Env exposure
EXPOSED=$(grep -rn "NEXT_PUBLIC_.*KEY\|NEXT_PUBLIC_.*SECRET\|NEXT_PUBLIC_.*PASSWORD" .env* 2>/dev/null)
[ -z "$EXPOSED" ] && echo "✅ Env: No secrets in NEXT_PUBLIC_" || echo "❌ Env: Secrets exposed!"

# 5. dangerouslySetInnerHTML
DANGEROUS=$(grep -rn "dangerouslySetInnerHTML" app/ components/ --include="*.tsx" 2>/dev/null | wc -l)
[ "$DANGEROUS" -eq 0 ] && echo "✅ XSS: No dangerouslySetInnerHTML" || echo "🟡 XSS: $DANGEROUS dangerouslySetInnerHTML (verify sanitization)"

# 6. npm audit
npm audit --production 2>/dev/null | grep -q "critical\|high" && echo "❌ NPM: Critical vulnerabilities" || echo "✅ NPM: No critical issues"

echo "Done!"
```

---

## Code Quality Check

```bash
#!/bin/bash
# code-quality.sh

echo "📝 Code Quality Check..."

# 1. God classes (>300 lines)
GOD_CLASSES=$(find . -name "*.php" -o -name "*.ts" | grep -v "node_modules\|vendor" | xargs wc -l 2>/dev/null | awk '$1 > 300 {print $2}')
if [ -z "$GOD_CLASSES" ]; then
    echo "✅ No god classes (>300 lines)"
else
    echo "🟡 God classes found:"
    echo "$GOD_CLASSES"
fi

# 2. Deeply nested code (>4 levels)
# Approximate check by counting indentation
NESTED=$(grep -rn "^\s\{16,\}" . --include="*.php" --include="*.ts" 2>/dev/null | grep -v "node_modules\|vendor" | wc -l)
[ "$NESTED" -lt 10 ] && echo "✅ Nesting: OK" || echo "🟡 Nesting: $NESTED deeply nested lines"

# 3. Long lines (>120 chars)
LONG_LINES=$(find . -name "*.php" -o -name "*.ts" | grep -v "node_modules\|vendor" | xargs awk 'length > 120' 2>/dev/null | wc -l)
[ "$LONG_LINES" -lt 20 ] && echo "✅ Line length: OK" || echo "🟡 Line length: $LONG_LINES long lines"

echo "Done!"
```

---

## Deploy Readiness Check

```bash
#!/bin/bash
# deploy-ready.sh

echo "🚀 Deploy Readiness Check..."

SCORE=0
TOTAL=10

# Checks...
# (Add framework-specific checks here)

# Calculate percentage
PERCENT=$((SCORE * 100 / TOTAL))

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Readiness Score: $SCORE/$TOTAL ($PERCENT%)"

if [ $PERCENT -ge 95 ]; then
    echo "Status: ✅ READY - Deploy now"
elif [ $PERCENT -ge 70 ]; then
    echo "Status: 🟡 ACCEPTABLE - Deploy possible"
else
    echo "Status: ❌ NOT READY - Fix blockers"
fi
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
```
