---
name: rescript-12
description: Write ReScript v12 code. Use when working with ReScript projects, especially v12. Covers critical syntax differences from JavaScript/TypeScript, common pitfalls, and stdlib usage.
---

# ReScript v12 Development Guide

This skill provides guidance for writing ReScript v12 code, particularly for avoiding common syntax traps that trip up agents unfamiliar with the language.

## Critical Syntax Rules

### Refs (Mutable State)

**DO NOT use** `!ref` or `ref := value`. This syntax is deprecated in v12.

**USE** `.contents` to read and write:

```res
// Creating a ref
let count = ref(0)

// Reading
let current = count.contents

// Writing
count.contents = count.contents + 1
```

### Loops

**DO NOT use** traditional JavaScript-style `for` loops:
```res
// WRONG - will cause parser errors
for (let i = 0; i < 10; i++) {
  Console.log(i)
}
```

**USE** `while` loops with manual increment:
```res
// Correct ReScript v12
let i = ref(0)
while i.contents < 10 {
  Console.log(Int.toString(i.contents))
  i.contents = i.contents + 1
}
```

**OR USE** functional alternatives:
```res
// Array.forEach
[1, 2, 3]->Array.forEach(x => {
  Console.log(Int.toString(x))
})

// Array.reduce
let sum = [1, 2, 3]->Array.reduce(0, (acc, x) => acc + x)
```

### Array Creation

**BE CAREFUL** with labeled arguments. The `length:` label can collide with JSX `:` characters in certain contexts.

```res
// Safe ways to create arrays
let arr = Array.make(10, 0)  // Correct: no label
let arr2 = Belt.Array.make(10, 0)  // Also safe

// AVOID labeled arguments that might conflict with JSX in the same file
```

### Array Reading vs Writing — Critical!

**READING** an array returns an option:
```res
let arr = Belt.Array.make(10, Dead)
let val = arr[5]  // val has type: option<cell>
// Must pattern match or use switch:
switch arr[5] {
| Some(cell) => ...
| None => ...
}
```

**WRITING** takes the raw value — do NOT wrap in `Some`:
```res
// WRONG - will cause type errors
arr[5] = Some(Alive)

// CORRECT - write raw value directly
arr[5] = Alive
```

### Flat 1D Arrays for Grids (Recommended)

When implementing 2D grids (like game boards), use a **flat 1D array** instead of nested arrays. This avoids option-wrapping issues from double indexing:

```res
// Instead of array<array<cell>> which causes grid[row][col] to return option<option<cell>>
type cell = Alive | Dead

// Flat 1D approach: index = r * cols + c
let make_grid = (rows: int, cols: int): array<cell> =>
  Belt.Array.make(rows * cols, Dead)

let get_cell = (grid: array<cell>, cols: int, r: int, c: int): cell =>
  switch grid[r * cols + c] {
  | Some(cell) => cell
  | None => Dead
  }

let set_cell = (grid: array<cell>, cols: int, r: int, c: int, val: cell): unit => {
  let _ = Belt.Array.set(grid, r * cols + c, val)
}
```

### Unit Discarding

When mutating inside expressions, you must discard the unit result:

```res
// WRONG
let _ = count.contents = count.contents + 1  // Assignment returns unit in this context

// CORRECT - use a separate statement
count.contents = count.contents + 1

// OR use this pattern for expression context
let _ = {
  count.contents = count.contents + 1
  ()
}
```

### Variants

**DO NOT confuse** variant constructors with types:

```res
// Define type
type state = Alive | Dead

// Use constructors (no prefix)
let s = Alive
switch s {
| Alive => Console.log("alive")
| Dead => Console.log("dead")
}

// AVOID: Dead (capital D) is a constructor, not a type
// If you need a type, use: type state = ...
```

### Continue in Loops

ReScript does NOT have a `continue` keyword. Use boolean flags or restructure:

```res
// Instead of continue, use if statements
let result = ref(list{})
let i = ref(0)
while i.contents < 10 {
  if i.contents !== 5 {
    // Skip 5
    result.contents = list{i.contents, ...result.contents}
  }
  i.contents = i.contents + 1
}
```

## React/JSX Patterns

### JSX String Children

**ALWAYS** wrap string children in `React.string()`:

```res
// WRONG - will not render
<div>{"Hello World"}</div>

// CORRECT
<div>{React.string("Hello World")}</div>
```

### useEffect Return Types

`React.useEffect0`, `React.useEffect1`, `React.useEffect2` expect specific return types:

```res
// useEffect2 expects: (unit => option<unit => unit>)
React.useEffect2(() => {
  if someCondition {
    let id = Js.Global.setInterval(...)
    Some(() => Js.Global.clearInterval(id))  // Return Some(cleanup)
  } else {
    None  // Must return None, not omitted
  }
}, (dep1, dep2))
```

### JSX Children Must Be Arrays

JSX children expect `array<React.element>`, not `list`. Convert if needed:

```res
// Use Array.map, not List.map
<div>
  {Array.map(item => <span>{React.string(item)}</span>, items)}
</div>
```

### Event Handlers

```res
// onChange handler pattern
<select
  onChange={e => {
    let value = ReactEvent.FormTarget.value(e)
    dispatch(MyAction(Int.fromString(value)))
  }}>
  ...
</select>
```

Note: Use `Int.fromString` which returns `option<int>`, not `Int.of_string`.

## Reducer Best Practices

### Actions Should Not Mutate Unrelated State

Be careful that actions don't accidentally change state you didn't intend:

```res
// WRONG - Step should NOT touch running state, or it breaks interval loops
| Step =>
  let new_grid = compute_next_gen(state.grid, ...)
  {...state, grid: new_grid, running: false}  // This breaks the animation!

// CORRECT - Step only advances the grid
| Step =>
  {...state, grid: compute_next_gen(state.grid, ...)}
```

### Use Separate Actions for Different Concerns

Instead of one action doing multiple things, create separate actions:

```res
// Instead of having Step also update running state:
| Step => compute_next_gen(...)
| Toggle => toggle running
| ToggleCell(r, c) => toggle specific cell
```

## v12 Migration Quick Reference

| Old (v11) | New (v12) |
|-----------|-----------|
| `!ref` | `ref.contents` |
| `ref := val` | `ref.contents = val` |
| `@bs.as("x")` | `@as("x")` |
| `@bs.send` | `@send` |
| `@bs.new` | `@new` |
| `lnot(a)` | `~~~a` |
| `land(a, b)` | `a &&& b` |
| `lor(a, b)` | `a \|\| b` |
| `lxor(a, b)` | `a ^^^ b` |
| `lsl(a, b)` | `a << b` |
| `lsr(a, b)` | `a >> b` |
| `asr(a, b)` | `a >>> b` |
| `Error.t` | `JsError.t` |
| `Js.Exn.Error` | `JsExn` |
| `assert 1 == 2` | `assert(1 == 2)` |
| `rescript build` | `rescript` |
| `rescript build -w` | `rescript watch` |
| `Js.Global.setInterval` | `setInterval` (global) |

## Standard Library

ReScript v12 ships with a new stdlib. Common imports:

```res
// Most modules are auto-opened, but if needed:
open Array
open Belt.Array
open List
open String
open Int
open Bool
```

### Common Array Operations

```res
let arr = [1, 2, 3]

// Get element (returns option)
let first = arr[0]  // Some(1)
let tenth = arr[10]  // None

// Set element
arr[0] = 10

// Map
let doubled = arr->Array.map(x => x * 2)

// Filter
let evens = arr->Array.filter(x => x mod 2 == 0)

// Reduce
let sum = arr->Array.reduce(0, (acc, x) => acc + x)

// Push (mutates)
arr->Array.push(4)
```

### Console Output

```res
Console.log("hello")      // prints to console
Console.log2("a", "b")    // prints multiple values
```

## DOM/HTML in ReScript

When working with JSX, remember:

1. **Capitalize components**: `<MyComponent />` not `<myComponent />`
2. **Attributes use ReScript syntax**: `className` not `class`, `onClick` not `onclick`
3. **No `for` attribute**: use `htmlFor`
4. **Inline styles**: pass a JS object, not a string
5. **String children**: wrap in `React.string()`

```res
<div onClick={_ => Console.log("clicked")} className="container">
  <span style={{"color": "red"}}>Hello</span>
</div>
```

## Build Commands

```bash
# Build
rescript

# Watch mode
rescript watch

# Format
rescript format
```

## Common Error Patterns

1. **JSX parser collision**: If you see errors about `:` or `=`, check for JSX conflicts in your code
2. **Unit expected**: You're likely using an expression that returns `unit` where a value is expected — add `let _ =` wrapper or separate statements
3. **Unbound variant**: Make sure you've defined the type first: `type myType = Variant1 | Variant2`
4. **"This has type X but expected Y" on array access**: Check if you're writing `Some(val)` to an array that should hold raw values
5. **"Function takes X arguments but got Y" in useEffect**: Check that both branches return the same type (e.g., both return `None`, not one returning a value and one returning `None`)



## While Loop Patterns (Critical — Learned from RLE Implementation)

When implementing parsers or any while loop in ReScript, every branch MUST have an exit condition. Unlike JavaScript where unhandled cases implicitly continue, ReScript requires explicit handling.

### Every Case Must Increment or Break

```res
// WRONG - will cause infinite loop
while i.contents < len {
  let ch = String.get(s, i.contents)
  switch ch {
    | Some("!") => ()  // No increment! Infinite loop!
    | Some("o") => i.contents = i.contents + 1
    | _ => i.contents = i.contents + 1
  }
}

// CORRECT - every case either increments or sets a definitive position
while i.contents < len {
  let ch = String.get(s, i.contents)
  switch ch {
    | Some("!") => i.contents = len  // Exit loop by setting to len
    | Some("o") => i.contents = i.contents + 1
    | _ => i.contents = i.contents + 1
  }
}
```

### parseDigits Pattern — Must Stop on Non-Digit

When parsing numbers, you MUST have a stop condition when hitting a non-digit:

```res
// WRONG - will hang on non-digit
let parseDigits = (s: string, start: int): option<(int, int)> => {
  let i = ref(start)
  let num = ref(0)
  while i.contents < len {
    let ch = String.get(s, i.contents)
    switch ch {
      | Some(d) if d >= "0" && d <= "9" => {
        // process digit
        i.contents = i.contents + 1
      }
      | _ => ()  // No increment! Infinite loop!
    }
  }
  // ...
}

// CORRECT - use a stop flag
let parseDigits = (s: string, start: int): option<(int, int)> => {
  let i = ref(start)
  let num = ref(0)
  let stop = ref(false)
  while i.contents < len && !stop.contents {
    let ch = String.get(s, i.contents)
    switch ch {
      | Some(d) if d >= "0" && d <= "9" => {
        // process digit
        i.contents = i.contents + 1
      }
      | _ => stop.contents = true  // Exit loop cleanly
    }
  }
  // ...
}
```

### String.indexOf Returns -1 When Not Found

`String.indexOf(s, pattern)` returns `-1` when the pattern is not found. This is different from some languages that return an option.

```res
// WRONG - 'idx' is a catch-all binding, matches -1 too! Subsequent arms unreachable.
let valStr = switch endIdx {
  | idx => String.slice(s, ~start=0, ~end=idx)  // Matches EVERYTHING including -1!
  | _ => s  // This is DEAD CODE - unreachable!
}

// CORRECT - match the sentinel value explicitly
let valStr = switch endIdx {
  | -1 => s  // Not found - use whole string
  | idx => String.slice(s, ~start=0, ~end=idx)  // Found at position idx
}
```

### Multi-Line Parsing — Reset State Between Lines

When parsing text that has multiple lines (like RLE encoding), each line may represent a new row/record:

```res
Array.forEach(lines, line => {
  let trimmedLine = String.trim(line)
  if !parsingBody.contents && String.includes(trimmedLine, "header") {
    parsingBody.contents = true
  }
  if parsingBody.contents && trimmedLine != "" && !String.includes(trimmedLine, "header") {
    // Each line is a new row - MUST reset column position
    currentCol.contents = 0
    
    // Parse the line...
    while i.contents < len {
      // ...parsing logic...
    }
    
    // After each line, move to next row
    currentRow.contents = currentRow.contents + 1
  }
})
```

### After Digit+Char Run, Skip the Char

When parsing patterns like "3o" (3 alive cells), after processing the run, you must skip past the character that defined the run:

```res
// parseDigits returns (number, positionAfterDigits)
// For "3o" starting at position 1: returns (3, 2) - stopped at "o"
switch parseDigits(trimmedLine, i.contents) {
  | Some((num, newPos)) => {
    let nextCh = String.get(trimmedLine, newPos)
    // Process num cells of type nextCh...
    
    // CRITICAL: skip past the char we just processed
    i.contents = newPos + 1  // Not just 'newPos' - that reprocesses the char!
  }
  | None => i.contents = i.contents + 1  // Also handle parse failure
}
```

### Deprecated Js.String.make

In ReScript v12, `Js.String.make` is deprecated. Use direct string handling:

```res
// WRONG
let s = Js.String.make(someChar)  // Deprecated

// CORRECT - if already a string, use it directly
let s = someChar  // Already a string

// Or use appropriate conversion
let s = Int.toString(n)
let s = Float.toString(f)
```

---

## Project Structure

Typical ReScript project:

```
project/
├── src/
│   ├── Main.res      # Entry point
│   ├── Component.res # Components
│   └── Utils.res     # Utilities
├── rescript.json     # Build config (was bsconfig.json)
└── package.json
```

---

## JSX Attribute Gotchas (Learned from Game of Life)

### `type` is a Reserved Keyword — Use `type_`

**WRONG — parse error:**
```res
<input type="range" />
```

**CORRECT:**
```res
<input type_="range" />
```

This applies to any HTML attribute that collides with a ReScript keyword. The trailing underscore is the escape convention.

### Bare Text with Special Characters in JSX

The ReScript JSX parser gets confused by `:` and `=` inside bare text content. **Always wrap text children in `React.string()`**, especially if they contain punctuation.

**WRONG — parse error when text contains `:`:**
```res
<label>Speed:</label>
```

**CORRECT:**
```res
<label>{React.string("Speed:")}</label>
```

### Inline Style — Record, Not JS Object

The `style` prop in JSX expects a `JsxDOMStyle.t` **record** with **string** CSS values, not a JS object with int values.

**WRONG — type error:**
```res
<div style={{"width": gridWidth, "height": gridHeight}} />
// Error: This has type {"height": int, "width": int} but expected JsxDOMStyle.t
```

**CORRECT — unquoted keys, string values with CSS units:**
```res
<div style={{width: Int.toString(gridWidth) ++ "px", height: Int.toString(gridHeight) ++ "px"}} />
```

### `List.range` Does Not Exist — Use `Array.fromInitializer`

There is no `List.range` in ReScript v12 stdlib. To generate an index sequence for mapping, use:

```res
// Generate indices 0..n-1 as an array
Array.fromInitializer(~length=n, i => i)

// Common pattern: render n rows
React.array(Array.fromInitializer(~length=rows, r => renderRow(r)))
```

### Rendering Arrays in JSX — Use `React.array`

`Array.map` and `Array.fromInitializer` return `array<React.element>`. JSX cannot render arrays directly — wrap them in `React.array(...)`.

**WRONG — type error:**
```res
<div>
  {Array.fromInitializer(~length=cols, c => renderCell(r, c))}
</div>
```

**CORRECT:**
```res
<div>
  {React.array(Array.fromInitializer(~length=cols, c => renderCell(r, c)))}
</div>
```

### Function Definition Syntax — `=` Is Required

**WRONG — parse error:**
```res
let renderGrid (): React.element =>
  ...
```

**CORRECT:**
```res
let renderGrid = (): React.element =>
  ...
```

### `ReactEvent.FormTarget` Does Not Exist — Use `ReactEvent.Form.target`

The `ReactEvent.FormTarget` module is not part of `@rescript/react`. To read a form input's value from an onChange event:

**WRONG:**
```res
let value = ReactEvent.FormTarget.value(e)
```

**CORRECT:**
```res
let handleChange = (e: ReactEvent.Form.t) => {
  let value: string = ReactEvent.Form.target(e)["value"]
  ...
}
```

The `target` accessor returns `{..}` (an open object), so you index into it with `["value"]`.

### Integer Modulo — `mod` vs `%`, and Negative Values

In ReScript v12, both `mod` and `%` are the integer modulo operator. They compile identically to `Primitive_int.mod_`, which is JavaScript `%` with a zero-division guard.

**Use `mod` — it is the idiomatic ReScript keyword:**
```res
let remainder = 10 mod 3  // 1
```

`%` also works but is unconventional and agents unfamiliar with ReScript may confuse it with JavaScript's behavior.

**Critical: Both `mod` and `%` can return NEGATIVE values for negative inputs.** This is different from Python's `%`, which always returns non-negative results.

```res
// WRONG for wrap-around — returns -1 when r=0, di=-1
let nr = (r + di.contents) mod rows  // → -1 mod 5 = -1 ← WRONG

// CORRECT — add `rows` first so the dividend is never negative
let nr = (r + di.contents + rows) mod rows  // → (-1 + 5) mod 5 = 4 ✓
```

**Safe grid wrap-around pattern** (when offset is always in {-1, 0, 1}):
```res
let nr = (r + dr + rows) mod rows
let nc = (c + dc + cols) mod cols
```

This works because `dr` and `dc` are at minimum -1, so adding the grid dimension ensures the dividend is always ≥ 0 before the modulo operation.

---

## Dead Code Analysis — reanalyze

ReScript 12.2 ships `rescript-tools reanalyze` as part of the `rescript` package. Always run it after changes.

### Commands

```bash
pnpm run res:analyze        # text output
pnpm run res:analyze:json   # JSON output (agent-parseable)
pnpm run check              # DCE + tests (full quality gate)
```

### What triggers a DCE warning

- A function or value that is defined but never called from ReScript code
- A type, record field, or variant case that is defined but never used
- React `make` functions called only from JS/HTML (not ReScript) — see annotation below

### Annotations

```res
// At top of file — marks ALL items live (use for JS-entry-point files)
@@live

// Single declaration — marks one item live
@live
let myFn = ...
```

**Only use `@@live` / `@live` for items that are genuinely called from outside ReScript** (e.g. entry points, exported APIs). Do not use it to silence warnings on actual dead code — remove that code instead.

### React entry points — mount the app, don't just export it

**The entry point `Main.res` must call `ReactDOM.Client.createRoot` to actually mount the app.
Exporting a component function without mounting it produces a white screen with zero console errors.**

```res
// Main.res — CORRECT: mounts the app to the DOM, with error visibility
@@live

type createRootOptions = {
  onUncaughtError: exn => unit,
  onCaughtError: exn => unit,
}

@module("react-dom/client")
external createRootWithOptions: (Dom.element, createRootOptions) => ReactDOM.Client.Root.t = "createRoot"

switch ReactDOM.querySelector("#root") {
| None => ()
| Some(root) =>
  createRootWithOptions(root, {
    onUncaughtError: e => Console.error2("React uncaught error:", e),
    onCaughtError: e => Console.error2("React caught error:", e),
  })->ReactDOM.Client.Root.render(<App />)
}
```

Without `onUncaughtError`, a render crash (TypeError in useEffect, bad external binding, etc.)
produces a white screen and a `console.warn` with unreadable `%s` placeholders. The actual
error is invisible. With `onUncaughtError`, it logs the exact TypeError and stack trace.

React Strict Mode (`<React.StrictMode>`) is separately useful — it double-invokes effects in
dev to catch non-idempotent side effects. Add it by wrapping: `.render(<React.StrictMode> <App /> </React.StrictMode>)`. It would NOT catch wrong external binding types.

```res
// Main.res — WRONG: just exports a component, nothing ever renders
@@live

@react.component
let make = () => <App />
// ↑ This compiles cleanly, passes all tests, deploys successfully, and produces a white screen.
```

`@@live` is needed on the first form to suppress DCE warnings (the querySelector call isn't
referenced from other ReScript files). The `@react.component` form above is wrong for an entry
point — it's a component definition, not a mount call.

**Bundle size is the canary.** A correct React + ReScript build should produce a bundle > 100 kB.
A 9 kB bundle means the app code was never included — likely because the entry point never
imported any app modules.

### Browser property externals — @val vs @get/@set

**`@val @scope(...) external fn: unit => T = "prop"` compiles to calling the property as a function.**
This crashes at runtime: `TypeError: window.location.hash is not a function`.

```res
// WRONG — compiles to: window.location.hash()
@val @scope(("window", "location")) external getHash: unit => string = "hash"

// CORRECT — read a browser property:
type location
@val @scope("window") external location: location = "location"
@get external getHash: location => string = "hash"
@set external setHash: (location, string) => unit = "hash"
// Usage: getHash(location) / setHash(location, "#value")

// CORRECT (alternative) — if you only need to read and the value never changes:
@val @scope(("window", "location")) external hash: string = "hash"
// Usage: let h = hash  (direct property access, no function call)
```

The rule: only add `unit =>` to an external if the JS side is actually a function call.
Reading a property (`window.location.hash`, `window.innerWidth`, etc.) does not use `unit =>`.

### `__tests__/` and dev sources

Test files compiled with `"type": "dev"` in `rescript.json` are treated as live by reanalyze. Symbols only referenced in tests do not produce false DCE warnings. No annotation needed.

### Deprecated APIs (as of 12.2.0)

When OpenCode writes localStorage or nullable code, it may use deprecated APIs. Migrate:

| Old | New |
|-----|-----|
| `Js.Nullable.t<'a>` | `Nullable.t<'a>` |
| `Js.Nullable.toOption(x)` | `Nullable.toOption(x)` |
| `JSON.parseExn(s)` | `JSON.parseOrThrow(s)` |

Run `pnpm exec rescript-tools migrate-all .` to auto-migrate, or fix manually.

---

## React Compiler + ESLint Integration

### What works in ReScript 12 + React Compiler

| Concern | Status |
|---------|--------|
| ReScript 12 emits `let` (required by React Compiler) | ✅ Fixed in v12 |
| JSX preserve mode ships | ✅ `"jsx": {"version": 4, "preserve": true}` |
| Vite + `babel-plugin-react-compiler` processes `.res.jsx` | ✅ Works |
| Fully automatic memoization without annotation | ⚠️ Incomplete |
| Per-component opt-in via `@directive("'use memo'")` | ✅ Works |
| ESLint `react-hooks/rules-of-hooks` on compiled `.res.mjs` | ✅ Works |
| `@rescript/react` 0.14.x + React 19 | ✅ Supported |

### Why auto-detection doesn't fully work

The React Compiler detects components by looking for **PascalCase function names** that return
JSX. ReScript compiled output exports `make` — lowercase — which the Compiler doesn't recognize
as a component. The detection heuristic fails on `make()` even with JSX preserve mode.

The fix: `@directive("'use memo'")` directly annotates the function body, bypassing detection:

```res
@react.component
let make = @directive("'use memo'") (~count) => {
  let (double, _) = React.useState(_ => 2 * count)
  <div>{React.string(`${Int.toString(double)}`)}</div>
}
```

### JSX preserve mode setup (for React Compiler projects)

Change `rescript.json` and `vite.config.js` for preserve mode:

```json
// rescript.json — use .res.jsx suffix so Babel picks up JSX output
{
  "suffix": ".res.jsx",
  "jsx": { "version": 4, "preserve": true }
}
```

```js
// vite.config.js
import react from "@vitejs/plugin-react";
export default defineConfig({
  plugins: [
    react({
      include: /\.res\.jsx$/,
      babel: { plugins: [["babel-plugin-react-compiler", {}]] },
    }),
  ],
});
```

**Important:** With preserve mode + Tailwind v4, `@tailwindcss/vite` must scan `.res.jsx` files
for class names. Verify Tailwind finds your classes in the new output format. If classes go
missing, the `<link rel="stylesheet" href="/src/index.css">` entry point and the Vite build
graph scan should pick them up automatically — but confirm after switching suffixes.

### ESLint on compiled output

`eslint-plugin-react-hooks` works on compiled ReScript output. With preserve mode, point at `.res.jsx` files.
Use only `rules-of-hooks` — the other rules have false positives on compiled code:

```js
// eslint.config.mjs
import reactHooks from "eslint-plugin-react-hooks";
export default [{
  files: ["src/**/*.res.jsx"],
  plugins: { "react-hooks": reactHooks },
  rules: {
    "react-hooks/rules-of-hooks": "error",
    "react-hooks/exhaustive-deps": "off",  // false positives on stable dispatch refs
    "react-hooks/immutability": "off",     // false positives on event-handler side effects
  },
}];
```

**`exhaustive-deps` off:** `dispatch` from `useReducer` and `setState` setters are stable refs —
the linter doesn't know this in compiled output, producing spurious warnings.

**`immutability` off:** The v7 rule flags `window.location.hash = value` in click handlers as
"modifying a variable defined outside a component." This is valid React code — event handlers
are explicitly allowed side effects.

### Quality gate command (with rescript-tools reanalyze)

The standalone `reanalyze` npm package ships x86_64 only — segfaults on M1 under Rosetta.
Use `rescript-tools reanalyze` which ships natively with `rescript@12`:

```json
"check": "rescript && rescript-tools reanalyze -dce -json && eslint src/ && vitest run"
```

### Upstream resolution paths (open)

The auto-detection gap will close via one of:
1. React Compiler adds a heuristic for `make` when the surrounding module is PascalCase
2. ReScript preserve mode emits a named re-export (`export { make as App }`) so detection works automatically

Watch `rescript-lang/rescript-compiler` JSX preserve mode issues and `reactwg/react-compiler` discussions.

---

## Never Create Handwritten `.js` Files Alongside `.res` Files

When you are uncertain about a ReScript external binding, do NOT create a handwritten `.js` file as a fallback or workaround. This is always wrong.

### Why this happens (and why it's wrong)

Agents sometimes create a plain `.js` file next to a `.res` binding file when they are unsure the binding will work at runtime. For example:

**WRONG — do not create this:**
```js
// src/SonnerToaster.js  ← DO NOT CREATE
/* eslint-disable */
export const Toaster = window.Sonner?.Toaster ?? function Toaster() { return null; };
export const toast = window.Sonner?.toast ?? { success: () => {}, error: () => {} };
```

This file:
- Is not compiled by ReScript — it lives outside the type system
- Shadows or conflicts with `SonnerToaster.res.jsx` (the compiled output)
- Produces ESLint warnings for its own `/* eslint-disable */` comment
- Breaks the integrity of the codebase — you now have two competing implementations
- Will cause confusing runtime behavior that is very hard to debug

### The correct approach: write proper externals

If you are uncertain how to bind a JavaScript module, write the correct ReScript external declaration. If the module exports named values:

```res
// CORRECT — bind Toaster as a named React component export
module Toaster = {
  @module("sonner") @react.component
  external make: (
    ~position: string=?,
    ~richColors: bool=?,
    ~theme: string=?,
  ) => React.element = "Toaster"
}

// CORRECT — bind the toast object with a typed record
type toastFn = {
  success: string => unit,
  error: string => unit,
}

@module("sonner")
external toast: toastFn = "toast"
```

### The rule

**If you find yourself creating a `.js` file in `src/`, stop.** Write a `.res` file with correct `@module` external bindings instead. The only `.js` files that should exist in a ReScript project's source directory are explicit utility files that are part of the design (e.g. `src/lib/utils.js` for the `cn()` helper), not workarounds for binding uncertainty.
