# Ещё пять для macOS

Нативное SwiftUI-приложение для коротких сеансов чтения. Kindle сохраняет обычный интерфейс и подключается только для просмотра экрана.

Собрать готовое приложение без полного Xcode:

```bash
sh native-macos/build-app.sh
open "native-macos/build/Ещё пять.app"
```

Готовый пакет появляется в `native-macos/build/Ещё пять.app`. Скрипт использует совместимый macOS SDK из Command Line Tools и ставит локальную подпись, поэтому сборка не требует учётной записи разработчика.

Состояние сохраняется локально в `Application Support/DalsheLive/reading-state.json`.

## AI-помощник: CLIProxyAPI + KOAssistant

Приложение умеет запускать локальный [CLIProxyAPI](https://github.com/router-for-me/CLIProxyAPI) и показывать состояние связи с [KOAssistant](https://github.com/zeeyado/koassistant.koplugin) на Kindle. Это не заменяет обычную читалку: KOAssistant появляется только внутри KOReader, а «Ещё пять» остаётся приложением macOS.

Схема связи:

```text
KOAssistant на Kindle → Wi-Fi → CLIProxyAPI на Mac → выбранный AI-провайдер
```

- CLIProxyAPI устанавливается в `~/.cli-proxy-api/bin/cli-proxy-api` и использует `~/.cli-proxy-api/config.yaml`.
- Сервер привязывается к конкретному локальному IP Mac, требует отдельный API-ключ и не разрешает удалённое управление.
- При сборке найденный файл `native-macos/.runtime/cli-proxy-api` также включается в пакет приложения. Каталог исключён из Git, поэтому сторонний бинарный файл не хранится в репозитории.
- KOAssistant использует полный OpenAI-совместимый адрес `http://<IP-Mac>:8317/v1/chat/completions`.
- Учётные данные AI-провайдера остаются в локальном каталоге CLIProxyAPI и никогда не попадают в репозиторий.
- Передача текста книги в AI выключена в KOAssistant по умолчанию и включается пользователем отдельно в `Settings → Privacy & Data → Text Extraction`.

В интерфейсе «Ещё пять» кнопка статуса AI позволяет запустить шлюз и проверить, появились ли доступные модели. Если показано «Нужен вход в AI», нужно один раз завершить OAuth-вход CLIProxyAPI на Mac.

## Просмотр экрана Kindle

Кнопка «Начать 5 страниц» сразу открывает нативный просмотр framebuffer Kindle Scribe. Реализация основана на идее `kindle-scribe-screen-sharing`, но не требует Node.js или FFmpeg и не отключает проверку SSH-ключей.

Перед первым подключением пользователь вручную включает SSH в KOReader, добавляет свой публичный ключ и один раз подтверждает ключ устройства обычной командой SSH в Терминале. Приложение само ничего не устанавливает и не меняет на Kindle.
