# Дальше Live для macOS

Нативный SwiftUI-симулятор общего состояния macOS и Kindle. Настоящий Kindle не подключается и не изменяется.

Собрать готовое приложение без полного Xcode:

```bash
sh native-macos/build-app.sh
open "native-macos/build/Дальше.app"
```

Готовый пакет появляется в `native-macos/build/Дальше.app`. Скрипт использует совместимый macOS SDK из Command Line Tools и ставит локальную подпись, поэтому сборка не требует учётной записи разработчика.

Состояние сохраняется локально в `Application Support/DalsheLive/reading-state.json`.
