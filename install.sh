#!/bin/bash
set -e

echo "🔧 ClaudeNotify Setup"
echo "━━━━━━━━━━━━━━━━━━━━━"

# 1. Проверка Xcode CLI Tools
if ! xcode-select -p &>/dev/null; then
    echo "❌ Xcode Command Line Tools не установлены."
    echo "   Запусти: xcode-select --install"
    echo "   После установки запусти install.sh снова."
    exit 1
fi
echo "✓ Xcode CLI Tools найдены"

# 2. Проверка VSCode
if [ ! -d "/Applications/Visual Studio Code.app" ]; then
    echo "⚠️  VSCode не найден в /Applications/"
    echo "   Установи VSCode и запусти install.sh снова."
    exit 1
fi
echo "✓ VSCode найден"

# 3. Копируем исходник и скилл
mkdir -p ~/.claude/ClaudeNotify-source ~/.claude/skills
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
cp "$SCRIPT_DIR/ClaudeNotify-source/main.swift" ~/.claude/ClaudeNotify-source/
cp "$SCRIPT_DIR/claude-skills/setup-project.md" ~/.claude/skills/
echo "✓ Файлы скопированы в ~/.claude/"

# 4. Собираем ClaudeNotify.app
APP_DIR="$HOME/Applications/ClaudeNotify.app/Contents"
mkdir -p "$APP_DIR/MacOS" "$APP_DIR/Resources"

cat > "$APP_DIR/Info.plist" << 'PLIST'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0"><dict>
  <key>CFBundleIdentifier</key><string>com.claudecode.notify</string>
  <key>CFBundleName</key><string>Claude Code</string>
  <key>CFBundleDisplayName</key><string>Claude Code</string>
  <key>CFBundleExecutable</key><string>ClaudeNotify</string>
  <key>CFBundleVersion</key><string>1.0</string>
  <key>CFBundleIconFile</key><string>AppIcon</string>
  <key>LSUIElement</key><true/>
  <key>NSPrincipalClass</key><string>NSApplication</string>
  <key>LSMinimumSystemVersion</key><string>13.0</string>
</dict></plist>
PLIST

# Иконка из Claude Code расширения
CLAUDE_EXT=$(ls ~/.vscode/extensions/ 2>/dev/null | grep anthropic.claude-code | head -1)
if [ -n "$CLAUDE_EXT" ]; then
    ICON_SRC="$HOME/.vscode/extensions/$CLAUDE_EXT/resources/claude-logo.png"
    if [ -f "$ICON_SRC" ]; then
        mkdir -p /tmp/claude.iconset
        for size in 16 32 64 128 256 512; do
            sips -z $size $size "$ICON_SRC" --out "/tmp/claude.iconset/icon_${size}x${size}.png" 2>/dev/null
            sips -z $((size*2)) $((size*2)) "$ICON_SRC" --out "/tmp/claude.iconset/icon_${size}x${size}@2x.png" 2>/dev/null
        done
        iconutil -c icns /tmp/claude.iconset -o "$APP_DIR/Resources/AppIcon.icns" 2>/dev/null
        echo "✓ Иконка Claude добавлена"
    fi
fi

echo "⏳ Компилируем ClaudeNotify.app..."
swiftc ~/.claude/ClaudeNotify-source/main.swift \
    -o "$APP_DIR/MacOS/ClaudeNotify" \
    -framework Cocoa \
    -framework UserNotifications \
    -target arm64-apple-macos13.0
echo "✓ Скомпилировано"

# 5. Подписываем
codesign --sign - --force "$HOME/Applications/ClaudeNotify.app"
echo "✓ Подписано"

# 6. Добавляем хуки в ~/.claude/settings.json
if [ ! -f ~/.claude/settings.json ]; then
    echo '{"hooks":{}}' > ~/.claude/settings.json
fi

python3 - << 'PYEOF'
import json, os
path = os.path.expanduser("~/.claude/settings.json")
with open(path, 'r') as f:
    data = json.load(f)
if "hooks" not in data:
    data["hooks"] = {}
data["hooks"]["Stop"] = [{"hooks": [{"type": "command", "async": True,
    "command": "open ~/Applications/ClaudeNotify.app --args '✅ Задача выполнена' 'Claude Code' 'Hero'"}]}]
data["hooks"]["PermissionRequest"] = [{"hooks": [{"type": "command", "async": False,
    "command": "open ~/Applications/ClaudeNotify.app --args '⚠️ Нужно разрешение' 'Claude Code' 'Glass'"}]}]
data["hooks"]["Notification"] = [{"matcher": "idle_prompt", "hooks": [{"type": "command", "async": True,
    "command": "open ~/Applications/ClaudeNotify.app --args '💬 Claude ждёт ответа' 'Claude Code' 'Tink'"}]}]
with open(path, 'w') as f:
    json.dump(data, f, indent=2, ensure_ascii=False)
print("✓ Хуки добавлены в ~/.claude/settings.json")
PYEOF

# 7. Тестовое уведомление (запрос разрешений)
echo ""
echo "⏳ Запускаем первое уведомление для запроса разрешений..."
open "$HOME/Applications/ClaudeNotify.app" --args "Нажми Разрешить если появился запрос" "Claude Code" "Glass"
sleep 2

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "✅ ClaudeNotify установлен!"
echo ""
echo "Следующие шаги:"
echo "1. Если появился запрос разрешений — нажми Разрешить"
echo "2. System Settings → Notifications → Claude Code → Alerts"
echo "3. Открой Claude Code и напиши: /setup-project"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
