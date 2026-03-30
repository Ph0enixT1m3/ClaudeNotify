# ClaudeNotify — автономная система уведомлений для Claude Code

Нативные macOS уведомления + автономный режим работы для Claude Code (VSCode расширение).

Существующие решения (`terminal-notifier`, `osascript`) сломаны на macOS Sonoma/Sequoia:
колбэк при клике на уведомление никогда не срабатывает. ClaudeNotify решает это
через современный `UNUserNotificationCenter` API и нативный Swift app-bundle.

## Что это даёт

- ✅ Уведомление когда Claude завершил задачу (звук Hero)
- ⚠️ Уведомление когда нужно разрешение вне проекта (звук Glass)
- 💬 Уведомление когда Claude задаёт вопрос (звук Tink)
- По клику на уведомление — автофокус на окно VSCode
- Автономный режим: Claude выполняет задачи внутри проекта без постоянных запросов разрешений

## Системные требования

- macOS 13.0 (Ventura) или новее
- VSCode с расширением Claude Code (`anthropic.claude-code`)
- Xcode Command Line Tools: `xcode-select --install`
- Python 3 (предустановлен на macOS)

## Установка

### Способ 1 — Одна команда в Claude Code (рекомендуется)

Напиши в Claude Code:

```
Прочитай и выполни инструкции из: https://raw.githubusercontent.com/Ph0enixT1m3/ClaudeNotify/main/INSTALL-PROMPT.md
```

Claude сам скачает инструкции и выполнит всю установку автоматически.

После установки:
- Если появился запрос разрешений — нажми **Разрешить**
- **System Settings → Notifications → Claude Code → Alerts**

### Способ 2 — Через install.sh (без Claude Code)

```bash
git clone https://github.com/Ph0enixT1m3/ClaudeNotify
cd ClaudeNotify
bash install.sh
```

Скрипт сделает всё автоматически:
1. Проверит зависимости (Xcode CLI, VSCode)
2. Скомпилирует `ClaudeNotify.app` и положит в `~/Applications/`
3. Добавит иконку Claude из расширения
4. Настроит хуки в `~/.claude/settings.json`
5. Скопирует скилл `/setup-project` в `~/.claude/skills/`
6. Отправит тестовое уведомление

## Как использовать

В начале любого нового проекта напиши в Claude Code:

```
/setup-project
```

Скилл создаст `.claude/settings.json` с автоматическими разрешениями на все операции
внутри проекта — без диалогов подтверждения при каждой команде.

## Уведомления

| Иконка | Звук | Когда появляется |
|--------|------|-----------------|
| ✅ | Hero | Claude завершил задачу или ответил |
| ⚠️ | Glass | Claude запрашивает разрешение |
| 💬 | Tink | Claude задаёт вопрос |

Клик на уведомление → VSCode выходит на передний план.

## Архитектура

```
~/.claude/settings.json  (hooks)
        │
        ├─ Stop hook ──────────────────────────────────────┐
        ├─ PermissionRequest hook ─────────────────────────┤
        └─ Notification (idle_prompt) hook ────────────────┤
                                                           ↓
                              open ~/Applications/ClaudeNotify.app --args "сообщение" "заголовок" "звук"
                                                           ↓
                              ClaudeNotify.app (LSUIElement — нет иконки в Dock)
                                                           ↓
                              UNUserNotificationCenter → системное уведомление macOS
                                                           ↓
                              Клик → NSWorkspace → find VSCode → activate()
```

**Почему Swift app, а не terminal-notifier:**
`terminal-notifier` использует устаревший `NSUserNotification` API. Apple сломала
колбэки при клике в Sonoma (14) и Sequoia (15). `UNUserNotificationCenter` —
современный API, тот же что использует сам macOS.

## Troubleshooting

**Уведомления не появляются**
→ System Settings → Notifications → Claude Code → включи Allow Notifications, выбери Alerts

**"Claude Code" не в списке уведомлений**
→ Запусти вручную: `open ~/Applications/ClaudeNotify.app --args "тест" "Claude Code" "Glass"`
→ macOS добавит приложение в список после первого запуска

**Клик не открывает VSCode**
→ Убедись что VSCode в `/Applications/Visual Studio Code.app`

**Ошибка компиляции Swift**
→ `xcode-select --install` → перезапусти `bash install.sh`

**Intel Mac (x86_64)**
→ В `install.sh` замени `-target arm64-apple-macos13.0` на `-target x86_64-apple-macos13.0`

**Уведомления дублируются**
→ Проверь `~/.claude/settings.json` — убедись что Stop/PermissionRequest/Notification
   хуки существуют только в одном экземпляре

## Файловая структура

```
~/Applications/ClaudeNotify.app/   ← скомпилированное приложение
~/.claude/
├── settings.json                   ← глобальные хуки (Stop, PermissionRequest, Notification)
├── skills/
│   └── setup-project.md            ← скилл /setup-project
└── ClaudeNotify-source/
    └── main.swift                  ← исходник Swift (для пересборки)
```

## Лицензия

MIT
