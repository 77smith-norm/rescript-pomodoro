# AGENTS.md — rescript-pomodoro

## What This Is

A Pomodoro focus timer built with ReScript 12 + React 19 + shadcn/ui as a harness engineering exercise. This is the second project in the series (after `rescript-test`), now with JSX preserve mode, the React Compiler, and the shadcn MCP.

## Build & Test

```bash
pnpm run res:build      # ReScript compile only
pnpm run res:watch      # ReScript watch mode
pnpm test               # rescript + vitest run
pnpm run lint           # ESLint on compiled output
pnpm run check          # Full quality gate: rescript + DCE + lint + tests
pnpm run dev            # rescript watch + vite dev server
pnpm run build          # Production build
```

**Full quality gate (required before any commit):**
```bash
pnpm run check
```

## Key Files

- `src/Main.res` — Bootstrap. Pre-written by harness engineer. **DO NOT MODIFY.**
- `src/Timer.res` — Pure timer state machine. Agent writes this.
- `src/Tasks.res` — Pure task CRUD. Agent writes this.
- `src/App.res` — Root component + global state + reducer. Agent writes this.
- `src/components/` — UI components. Agent writes these using shadcn MCP.
- `__tests__/Pomodoro_Test.res` — Pre-written failing tests. Agent makes them pass.
- `docs/design.md` — Full design documentation including state machine spec.

## shadcn MCP

This project is configured with the shadcn MCP server (see `opencode.json`).

**Before implementing any shadcn component:**
1. Use the shadcn MCP to fetch the component's schema and usage documentation
2. Do not guess prop names or import paths — always query the MCP first
3. Confirm you fetched from MCP before writing each component

shadcn components live in `src/components/ui/` and are plain JavaScript/TypeScript files.
ReScript components import them via external bindings or wrap them in ReScript components.

**Preferred approach:** Implement components natively in ReScript using shadcn's class names and CSS variables. This avoids binding complexity and keeps everything in ReScript. Use the MCP to understand what classes and variants shadcn uses.

## React Compiler

This project uses `babel-plugin-react-compiler` via Vite.

**Components to annotate with `@directive("'use memo'")`:**
- `TimerControls` — stable relative to ticks
- `SessionBadge` — only changes at session completion
- `TaskItem` — renders in a list with stable per-item props
- `TaskInput` — no tick dependency
- `SettingsDialog` — only opens/closes

**Components NOT to annotate:**
- `TimerDisplay` — updates every second by design
- `ProgressBar` — updates every tick

Annotation syntax:
```res
@react.component
let make = @directive("'use memo'") (~title, ~done_) => {
  <div>...</div>
}
```

## File Suffix: `.res.jsx` (NOT `.res.mjs`)

This project uses JSX preserve mode. Output files have the `.res.jsx` extension.

Vite's `plugin-react` is configured with `include: /\.res\.jsx$/` to process these files.
Tailwind v4 scans all files for class names automatically.

**Note for DCE analysis:** `rescript-tools reanalyze -dce -json` should report `[]` for no dead code. If it reports entries, remove the dead code (or add `@live` only for genuine JS-entry-point exports).

## ReScript-Specific Conventions

See `.agents/skills/rescript-12/SKILL.md` for the full syntax guide.

Critical reminders:
- JSX string children: `{React.string("text")}` — never bare strings
- `type_` not `type` for HTML type attribute
- `React.array(...)` to render arrays in JSX
- `done_` not `done` — `done` is a ReScript keyword
- Timer state machine: see `docs/design.md` for the full transition table

## Known Issues

1. **White screen trap:** `Main.res` must call `createRoot` and mount the app. It's pre-written — do NOT rewrite it. Exporting a component without mounting produces a white screen with zero errors.
2. **Tailwind class detection:** With `.res.jsx` output, verify Tailwind picks up classes after switching from `.res.mjs`. Check bundle CSS includes expected classes.
3. **ESLint on `.res.jsx`:** The eslint config points to `src/**/*.res.jsx`. After compiling, compiled files appear in-source — ESLint should find them.

## Done When (per feature)

1. `pnpm run check` exits with code 0
2. DCE output is `[]` (no dead code introduced)
3. All tests pass (count shown in vitest output)
4. The timer works end-to-end in `pnpm run dev`
5. Committed and pushed to `origin/main`

## History

| Session | Feature | Status |
|---------|---------|--------|
| 1 | Timer.res + Tasks.res + App.res + full UI | pending |

## Off-Limits

- `src/Main.res` — harness engineer's bootstrap, do not touch
- `src/lib/utils.js` — cn() helper, do not touch
- `src/index.css` — shadcn CSS variables, do not touch
- `opencode.json` — MCP config, do not touch
