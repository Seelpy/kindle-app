# Prototype Instructions

Run the local server yourself and open the preview in the browser available to this environment. Do not give the user server-start instructions when you can run it.

Before making substantial visual changes, use the Product Design plugin's `get-context` skill when the visual source is unclear or no longer matches the current goal. When the user gives durable prototype-specific design feedback, preferences, or decisions, record them in `AGENTS.md`.

When implementing from a selected generated mock, treat that image as the source of truth for layout, component anatomy, density, spacing, color, typography, visible content, and hierarchy.

Build app UI in `src/`. Keep `.openai/hosting.json`, `worker/index.js`, `scripts/prepare-sites-build.mjs`, and `tests/sites-worker.test.mjs` intact so the same local prototype can be handed to Sites. Before a Sites handoff, run `npm run build` and `npm run test:sites`; the build must leave `dist/client/index.html`, `dist/server/index.js`, and `dist/.openai/hosting.json`.

## Product decisions

- The product is named «Ещё пять».
- «Ещё пять» существует только как нативное приложение macOS. Kindle сохраняет обычный интерфейс читалки и подключается к Mac только для просмотра экрана; отдельного приложения или плагина на Kindle быть не должно.
- One active book only. Avoid streaks, badges, productivity dashboards, pressure, or guilt.
- The selected visual direction is the third ideation concept: «Когда продолжим?», a tiny five-page commitment, a note to the future self, and a neutral «Отпустить книгу» action.
- The macOS interface must stay high-contrast and readable in both system appearances; the app intentionally renders its calm light paper theme instead of inheriting dark-mode text colors.
