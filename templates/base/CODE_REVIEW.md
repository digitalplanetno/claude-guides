# Code Review — Base Template

## Цель
Комплексный code review веб-приложения. Действуй как Senior Tech Lead.

---

## 0. QUICK CHECK (5 минут)

| # | Check | Expected |
|---|-------|----------|
| 1 | Syntax errors | None |
| 2 | Linter passes | No errors |
| 3 | Build succeeds | Success |
| 4 | Tests pass | All green |
| 5 | No debug code | No dd/dump/console.log |

---

## 0.1 PROJECT SPECIFICS — [Project Name]

**Принятые решения (не нужно исправлять):**
- [Осознанные architectural decisions]

**Ключевые файлы для review:**
- [Где бизнес-логика]
- [Где controllers/routes]
- [Где компоненты UI]

**Паттерны проекта:**
- [Какие паттерны используются]

---

## 0.2 SEVERITY LEVELS

| Level | Описание | Действие |
|-------|----------|----------|
| CRITICAL | Баг, security issue, data loss | **БЛОКЕР** — исправить сейчас |
| HIGH | Серьёзная проблема в логике | Исправить до merge |
| MEDIUM | Code smell, maintainability | Исправить в этом PR |
| LOW | Style, nice-to-have | Можно отложить |

---

## 1. SCOPE REVIEW

### 1.1 Определи scope
- [ ] Какие файлы изменены
- [ ] Какие файлы созданы
- [ ] Связь изменений между собой

### 1.2 Категоризация
- [ ] Business logic changes
- [ ] UI changes
- [ ] Database changes
- [ ] Config changes

---

## 2. ARCHITECTURE & STRUCTURE

### 2.1 Single Responsibility
```
❌ Плохо: Controller 300+ строк со всей логикой
✅ Хорошо: Controller координирует, Service содержит логику
```

- [ ] Файлы < 300 строк
- [ ] Методы < 20 строк
- [ ] Один класс/компонент — одна ответственность

### 2.2 Dependency Injection
- [ ] Зависимости инжектятся, не создаются внутри
- [ ] Нет статических вызовов сервисов

### 2.3 Правильное расположение
- [ ] Файлы в правильных директориях
- [ ] Нет God-классов
- [ ] Логика в правильном слое

---

## 3. CODE QUALITY

### 3.1 Naming
- [ ] Переменные — существительные, camelCase
- [ ] Методы — глаголы, camelCase
- [ ] Boolean — is/has/can/should prefix

### 3.2 Complexity
- [ ] Вложенность < 3 уровней
- [ ] Early returns используются
- [ ] Сложная логика разбита на методы

### 3.3 DRY
- [ ] Нет copy-paste кода
- [ ] Общая логика вынесена

### 3.4 Type Safety
- [ ] Типы указаны
- [ ] Nullable явно обозначен

---

## 4. ERROR HANDLING

### 4.1 Exceptions
- [ ] Специфичные exception типы
- [ ] Логирование с контекстом
- [ ] Нет пустых catch блоков

### 4.2 User-Facing
- [ ] Понятные сообщения пользователю
- [ ] Технические детали только в логах

---

## 5. DOCUMENTATION

### 5.1 Code Comments
- [ ] Public методы документированы
- [ ] Комментарии объясняют "почему", не "что"
- [ ] Нет закомментированного кода

### 5.2 Project Docs
- [ ] README обновлён если нужно
- [ ] INDEX обновлён если нужно

---

## 6. SECURITY & PERFORMANCE

### 6.1 Security Quick Check
- [ ] Нет SQL injection
- [ ] Нет XSS
- [ ] Авторизация проверяется
- [ ] Нет debug code в production

### 6.2 Performance Quick Check
- [ ] Нет N+1 queries
- [ ] Пагинация для списков
- [ ] Тяжёлые операции async

---

## 7. САМОПРОВЕРКА

**НЕ включай в отчёт:**

| Кажется проблемой | Почему может не быть |
|-------------------|---------------------|
| "Нет комментариев" | Код self-documenting |
| "Длинный файл" | Если логически связан — OK |
| "Старый стиль кода" | Если работает — не проблема |
| "Можно было бы лучше" | Без конкретики не actionable |

**Чеклист:**
```
□ Это РЕАЛЬНАЯ проблема, а не вкусовщина
□ Есть КОНКРЕТНОЕ предложение по исправлению
□ Исправление НЕ СЛОМАЕТ функционал
□ Это НЕ intentional design decision
```

---

## 8. ФОРМАТ ОТЧЁТА

```markdown
# Code Review Report — [Project]
Дата: [дата]
Scope: [файлы/коммиты]

## Summary

| Категория | Проблем | Критичных |
|-----------|---------|-----------|
| Architecture | X | X |
| Code Quality | X | X |
| Security | X | X |
| Performance | X | X |

## CRITICAL Issues

| # | Файл | Строка | Проблема | Решение |
|---|------|--------|----------|---------|
| 1 | file.ext | 45 | [Описание] | [Решение] |

## Code Suggestions

### 1. [Название]
```language
// Было
[код]

// Стало
[код]
```

## Good Practices Found
- [Что хорошо]
```

---

## 9. ДЕЙСТВИЯ

1. **Quick Check** — базовые проверки
2. **Определи scope** — что проверять
3. **Пройди категории** — Architecture → Performance
4. **Самопроверка** — фильтруй ложные срабатывания
5. **Покажи fixes** — конкретный код до/после

Начни review. Покажи scope и summary первым.
