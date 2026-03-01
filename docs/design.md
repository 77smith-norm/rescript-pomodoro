# rescript-pomodoro — Design Documentation

## Overview

A Pomodoro focus timer built as a harness engineering exercise. The primary goals are:

1. **Test the rescript-12 skill** under real conditions with JSX preserve mode (`.res.jsx`)
2. **Validate the shadcn MCP integration** with OpenCode
3. **Exercise the `@directive("'use memo'")` opt-in** for the React Compiler
4. **Build something genuinely beautiful** using shadcn/ui's design system

This is a deliberate exercise — the learning compounds into future projects.

---

## Technical Stack

| Layer | Technology |
|-------|------------|
| Language | ReScript 12.2, `.res.jsx` suffix, JSX preserve mode |
| UI Framework | React 19 + `@rescript/react` 0.14.x |
| Bundler | Vite 6 + `@vitejs/plugin-react` |
| Memoization | React Compiler via `babel-plugin-react-compiler` |
| Styling | Tailwind CSS v4 + shadcn/ui design system |
| Tests | rescript-vitest 2.1.1 + vitest 3 |
| Static Analysis | `rescript-tools reanalyze` (DCE), ESLint react-hooks |
| MCP | shadcn MCP server (opencode.json) |

### Key build config differences from yesterday's rescript-test

| Concern | rescript-test | rescript-pomodoro |
|---------|---------------|-------------------|
| Suffix | `.res.mjs` | `.res.jsx` |
| JSX mode | `"version": 4` | `"version": 4, "preserve": true` |
| Vite include | default | `include: /\.res\.jsx$/` |
| React Compiler | no | `babel-plugin-react-compiler` via Babel |
| shadcn | no | yes, via MCP |

---

## Application Structure

### Timer State Machine

```
Idle ──start──→ Working ──tick(0)──→ OnBreak ──tick(0)──→ Working
         ↑         │                                           │
         │      pause                                         │
         │         ↓                                           │
         └──reset── Paused ──resume──→ Working ────────────────┘
```

Timer phases:
- **Idle** — not started; shows the work duration
- **Working** — counting down the work interval
- **OnBreak** — counting down the break interval
- **Paused** — suspended; remembers which phase was active

Timer transitions:
| Action | From | To | Side effect |
|--------|------|-----|------------|
| start | Idle | Working | — |
| pause | Working | Paused | — |
| pause | OnBreak | Paused | — |
| pause | Idle/Paused | unchanged | no-op |
| resume | Paused | previous phase | — |
| reset | any | Idle | restore workSecs |
| tick | Working (timeLeft > 1) | Working | timeLeft - 1 |
| tick | Working (timeLeft = 1) | OnBreak | sessionCount + 1, timeLeft = breakSecs |
| tick | OnBreak (timeLeft > 1) | OnBreak | timeLeft - 1 |
| tick | OnBreak (timeLeft = 1) | Working | timeLeft = workSecs |
| tick | Idle / Paused | unchanged | no-op, completed = false |

### Timer record type

```res
type phase = Idle | Working | OnBreak | Paused

type timer = {
  phase: phase,
  timeLeft: int,    // seconds remaining in current phase
  workSecs: int,    // configured work duration
  breakSecs: int,   // configured break duration
  sessionCount: int // completed pomodoros this session
}
```

### Task record type

```res
type task = {
  id: int,
  title: string,
  done_: bool,  // "done" is a ReScript keyword, use done_ with trailing underscore
}
```

### App state

```res
type state = {
  timer: Timer.timer,
  tasks: array<Timer.task>,
  nextTaskId: int,
  workSecs: int,   // configured via Settings dialog
  breakSecs: int,
}
```

---

## Component Architecture

```
App
├── TimerCard            ← shadcn Card, full-width timer display
│   ├── TimerDisplay     ← large countdown clock + phase label (@directive memo)
│   ├── ProgressBar      ← shadcn Progress, shows % of current phase complete
│   └── TimerControls    ← Start/Pause/Resume/Reset buttons (shadcn Button)
├── SessionBadge         ← shadcn Badge, shows sessionCount (@directive memo)
├── TaskList             ← task input + scrollable list
│   ├── TaskInput        ← shadcn Input + Button "Add"
│   └── TaskItem[]       ← Checkbox + title + delete button (@directive memo)
└── SettingsDialog       ← shadcn Dialog with Sliders for work/break duration
```

### React Compiler annotation strategy

Annotate with `@directive("'use memo'")` where:
- Props are stable (don't change every render)
- The component re-renders due to unrelated parent state changes

| Component | Annotate? | Reason |
|-----------|-----------|--------|
| TimerDisplay | **NO** | Re-renders every tick by design |
| ProgressBar | **NO** | Updates every tick |
| TimerControls | Yes | Only changes phase — stable relative to ticks |
| SessionBadge | Yes | Only changes at session completion |
| TaskItem | Yes | Renders in list; only its own task changes |
| TaskInput | Yes | Stable; no tick dependency |
| SettingsDialog | Yes | Stable; only opens/closes |

---

## shadcn Components Needed

Query the shadcn MCP before implementing each of these:

- `button` — Timer controls (primary/outline variants), task actions
- `card` — Timer container, task list container
- `progress` — Timer progress bar
- `badge` — Session count
- `input` — Task text input
- `dialog` — Settings panel
- `slider` — Work/break duration configuration
- `checkbox` — Task completion toggle
- `separator` — Section dividers

---

## File Structure

```
rescript-pomodoro/
├── __tests__/
│   └── Pomodoro_Test.res       # Failing tests (pre-written by harness engineer)
├── docs/
│   └── design.md               # This file
├── src/
│   ├── Main.res                # Bootstrap (pre-written — do not modify)
│   ├── App.res                 # Root component + state + reducer
│   ├── Timer.res               # Pure timer logic (state machine + formatTime)
│   ├── Tasks.res               # Pure task CRUD
│   ├── Cn.res                  # cn() utility binding
│   ├── components/
│   │   ├── TimerCard.res
│   │   ├── TimerDisplay.res
│   │   ├── TimerControls.res
│   │   ├── SessionBadge.res
│   │   ├── TaskList.res
│   │   ├── TaskItem.res
│   │   ├── TaskInput.res
│   │   └── SettingsDialog.res
│   ├── lib/
│   │   └── utils.js            # cn() helper (pre-written)
│   └── index.css               # Tailwind + shadcn CSS variables (pre-written)
├── .agents/skills/rescript-12/SKILL.md
├── opencode.json               # shadcn MCP config (auto-generated)
├── components.json             # shadcn registry config
├── AGENTS.md
├── rescript.json
├── vite.config.js
└── package.json
```

---

## Quality Gate

```bash
pnpm run check
# = rescript && rescript-tools reanalyze -dce -json && eslint src/ && vitest run
```

All four must pass before a feature is considered complete.

Test count starts at **0** (Timer and Tasks modules don't exist yet).
Target: **27 tests passing** after implementation.

---

## Harness Engineering Context

This project is part of an ongoing experiment in harness engineering — the practice of setting up coding agents for success through:

- **Prime prompt quality** over skill file updates as the primary correctness signal
- **TDD-first workflow**: write failing tests → verify red → spawn agent → verify green
- **Explicit correctness tables** in the prime for state machines and reducers
- **Tests as backward-compat enforcement** for any refactoring
- **Avoidance of None-as-pass anti-pattern** in test assertions

See `~/.openclaw/workspace/harness-engineering.md` for the full methodology.

---

## Deployment

GitHub Pages via Actions workflow.
Live URL (after first deploy): `https://77smith-norm.github.io/rescript-pomodoro/`
