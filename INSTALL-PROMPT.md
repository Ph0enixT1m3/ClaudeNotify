# INSTALL-PROMPT.md

## Как использовать этот файл

Скопируй промпт ниже и вставь его в Claude Code на новом Mac.
Claude прочитает инструкции и выполнит всю установку самостоятельно.

---

## Промпт для вставки в Claude Code

```
Прочитай файл INSTALL-PROMPT.md из архива ClaudeNotify-Setup (он у меня на рабочем столе или в папке загрузок) и выполни установку по инструкции ниже.

Установи систему ClaudeNotify — нативные macOS уведомления для Claude Code.

Выполни следующие шаги автоматически:

### 1. Сохрани исходник Swift

Создай файл ~/.claude/ClaudeNotify-source/main.swift со следующим содержимым:

import Cocoa
import UserNotifications

class AppDelegate: NSObject, NSApplicationDelegate, UNUserNotificationCenterDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        let args = CommandLine.arguments
        let message = args.count > 1 ? args[1] : ""
        let title   = args.count > 2 ? args[2] : "Claude Code"
        let sound   = args.count > 3 ? args[3] : "default"
        if message.isEmpty { NSApp.terminate(nil); return }
        let center = UNUserNotificationCenter.current()
        center.delegate = self
        center.requestAuthorization(options: [.alert, .sound]) { granted, _ in
            guard granted else { DispatchQueue.main.async { NSApp.terminate(nil) }; return }
            self.send(title: title, message: message, sound: sound)
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 120) { NSApp.terminate(nil) }
    }
    func send(title: String, message: String, sound: String) {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body  = message
        content.sound = sound == "none" ? nil : UNNotificationSound(named: UNNotificationSoundName(sound))
        let req = UNNotificationRequest(identifier: UUID().uuidString, content: content,
            trigger: UNTimeIntervalNotificationTrigger(timeInterval: 0.1, repeats: false))
        UNUserNotificationCenter.current().add(req, withCompletionHandler: nil)
    }
    func userNotificationCenter(_ c: UNUserNotificationCenter, didReceive r: UNNotificationResponse,
                                withCompletionHandler done: @escaping () -> Void) {
        if let app = NSWorkspace.shared.runningApplications.first(where: {
            $0.bundleIdentifier == "com.microsoft.VSCode"
        }) { app.activate(options: []) }
        else { NSWorkspace.shared.open(URL(fileURLWithPath: "/Applications/Visual Studio Code.app")) }
        done(); NSApp.terminate(nil)
    }
    func userNotificationCenter(_ c: UNUserNotificationCenter, willPresent n: UNNotification,
                                withCompletionHandler done: @escaping (UNNotificationPresentationOptions) -> Void) {
        done([.banner, .sound])
    }
}
let app = NSApplication.shared
app.setActivationPolicy(.accessory)
let delegate = AppDelegate()
app.delegate = delegate
app.run()

### 2. Скопируй скилл

Скопируй файл claude-skills/setup-project.md из архива в ~/.claude/skills/setup-project.md

### 3. Собери ClaudeNotify.app

Выполни bash-командами:

APP_DIR="$HOME/Applications/ClaudeNotify.app/Contents"
mkdir -p "$APP_DIR/MacOS" "$APP_DIR/Resources"

Создай Info.plist:
CFBundleIdentifier = com.claudecode.notify
CFBundleName = Claude Code
CFBundleDisplayName = Claude Code
CFBundleExecutable = ClaudeNotify
LSUIElement = true
NSPrincipalClass = NSApplication
LSMinimumSystemVersion = 13.0
CFBundleIconFile = AppIcon

Добавь иконку из расширения Claude Code:
CLAUDE_EXT=$(ls ~/.vscode/extensions/ | grep anthropic.claude-code | head -1)
ICON_SRC="$HOME/.vscode/extensions/$CLAUDE_EXT/resources/claude-logo.png"
Сгенерируй иконки через sips и iconutil.

Скомпилируй:
swiftc ~/.claude/ClaudeNotify-source/main.swift \
  -o "$APP_DIR/MacOS/ClaudeNotify" \
  -framework Cocoa -framework UserNotifications \
  -target arm64-apple-macos13.0

Подпиши:
codesign --sign - --force "$HOME/Applications/ClaudeNotify.app"

### 4. Настрой хуки

Добавь в ~/.claude/settings.json (не удаляя существующее):
- Stop → open ~/Applications/ClaudeNotify.app --args '✅ Задача выполнена' 'Claude Code' 'Hero'
- PermissionRequest → open ~/Applications/ClaudeNotify.app --args '⚠️ Нужно разрешение' 'Claude Code' 'Glass'
- Notification (idle_prompt) → open ~/Applications/ClaudeNotify.app --args '💬 Claude ждёт ответа' 'Claude Code' 'Tink'

### 5. Отправь тестовое уведомление

open ~/Applications/ClaudeNotify.app --args "✅ ClaudeNotify установлен!" "Claude Code" "Hero"

### 6. Сообщи мне

После установки скажи:
- Что установлено успешно
- Если появился запрос разрешений — что нужно нажать Разрешить
- Что нужно зайти в System Settings → Notifications → Claude Code → Alerts
- Что в новом проекте достаточно написать /setup-project

Правило поведения с этого момента:
- Перед каждым вопросом ко мне отправляй уведомление 💬
- Операции внутри текущего проекта — выполняй без запроса разрешений
- Операции вне проекта — запрашивай разрешение + отправляй уведомление ⚠️
```

---

## Что произойдёт после вставки промпта

Claude автоматически:
1. Создаст Swift исходник в `~/.claude/ClaudeNotify-source/`
2. Соберёт `ClaudeNotify.app` в `~/Applications/`
3. Настроит хуки в `~/.claude/settings.json`
4. Установит скилл `/setup-project`
5. Отправит тестовое уведомление

Тебе останется только:
- Нажать **Разрешить** если появится запрос
- **System Settings → Notifications → Claude Code → Alerts**
- В новом проекте написать `/setup-project`
