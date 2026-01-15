# Report Format

Стандартный формат отчётов для аудитов.

---

## Security Audit Report

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
| ⚪ Info | X | - |

**Overall Risk Level**: [Critical/High/Medium/Low]

---

## 🔴 Critical Vulnerabilities

### CRIT-001: [Название]
**Location**: `path/to/file.ext:XX`
**CVSS Score**: X.X (если применимо)
**Description**: [Описание уязвимости]
**Impact**: [Какой ущерб может быть нанесён]
**Proof of Concept**: [Как воспроизвести]
**Remediation**: [Как исправить]
**Status**: ✅ Fixed / ❌ Pending

---

## 🟠 High Severity Issues
[Аналогичный формат]

## 🟡 Medium Severity Issues
[Аналогичный формат]

## 🔵 Low Severity Issues
[Краткий список]

## ⚪ Informational
[Краткий список]

---

## ✅ Security Controls in Place

- [x] [Что уже реализовано]
- [x] [Что уже реализовано]
- [ ] [Что рекомендуется добавить]

---

## 📋 Remediation Checklist

### Immediate (24h)
- [ ] [Критические исправления]

### Short-term (1 week)
- [ ] [Важные исправления]

### Long-term (1 month)
- [ ] [Улучшения]
```text

---

## Code Review Report

```markdown
# Code Review Report — [Project Name]
Дата: [дата]
Scope: [какие файлы/коммиты проверены]

## Summary

| Категория | Проблем | Критичных |
|-----------|---------|-----------|
| Architecture | X | X |
| Code Quality | X | X |
| [Framework] | X | X |
| Security | X | X |
| Performance | X | X |

---

## CRITICAL Issues

| # | Файл | Строка | Проблема | Решение |
|---|------|--------|----------|---------|
| 1 | file.ext | 45 | [Описание] | [Решение] |

## HIGH Priority
[Аналогичный формат]

## MEDIUM Priority
[Аналогичный формат]

---

## Good Practices Found

- [Что сделано хорошо]

---

## Code Suggestions

### 1. [Название изменения]

```language
// Было (path/to/file.ext:XX-YY)
[старый код]

// Стало
[новый код]
```text

---

## Checklist для автора

- [ ] Исправить критические проблемы
- [ ] Обновить документацию
- [ ] Запустить тесты

```text

---

## Deploy Checklist Report

```markdown
# Deploy Checklist Report — [Project Name]
Дата: [дата]
Version: [git commit hash]
Deployed by: [кто]

## Summary

| Step | Status | Duration |
|------|--------|----------|
| Pre-checks | ✅/❌ | X min |
| Backup | ✅/❌ | X min |
| Code deploy | ✅/❌ | X min |
| Migrations | ✅/❌ | X min |
| Build | ✅/❌ | X min |
| Cache | ✅/❌ | X min |
| Verification | ✅/❌ | X min |
| **Total** | **✅/❌** | **X min** |

## Readiness Score

**Score**: XX% — [READY / ACCEPTABLE / NOT READY]

### Blockers
- [Если есть]

### Warnings
- [Если есть]

### Passed
- [Список пройденных проверок]

---

## Changes Deployed

### Features
- [Новые фичи]

### Fixes
- [Исправления]

### Migrations
- [Миграции БД]

---

## Verification Results

| Check | Result |
|-------|--------|
| Homepage loads | ✅/❌ |
| Login works | ✅/❌ |
| Core functionality | ✅/❌ |
| Error rate | X% |

---

## Post-Deploy Tasks

- [ ] Monitor error rate for 24h
- [ ] Check queue processing
- [ ] Notify stakeholders
```text
