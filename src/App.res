@@live

type state = {
  timer: Timer.timer,
  tasks: array<Tasks.task>,
  nextTaskId: int,
  newTaskTitle: string,
  settingsOpen: bool,
}

type action =
  | TimerStart
  | TimerPause
  | TimerResume
  | TimerReset
  | TimerTick
  | TaskAdd
  | TaskToggle(int)
  | TaskDelete(int)
  | SetNewTaskTitle(string)
  | OpenSettings
  | CloseSettings
  | UpdateWorkSecs(int)
  | UpdateBreakSecs(int)

let reducer = (state, action) => {
  switch action {
  | TimerStart => {
      ...state,
      timer: Timer.start(state.timer),
    }
  | TimerPause => {
      ...state,
      timer: Timer.pause(state.timer),
    }
  | TimerResume => {
      ...state,
      timer: Timer.resume(state.timer),
    }
  | TimerReset => {
      ...state,
      timer: Timer.reset(state.timer),
    }
  | TimerTick => {
      let (t2, completed) = Timer.tick(state.timer)
      if (completed) {
        switch t2.phase {
        | OnBreak => {
            SonnerToaster.toast.success("Session complete! Take a break.")
          }
        | Working => {
            SonnerToaster.toast.success("Break over. Focus time!")
          }
        | _ => ()
        }
      }
      {...state, timer: t2}
    }
  | TaskAdd => {
      if state.newTaskTitle == "" {
        state
      } else {
        {
          ...state,
          tasks: Tasks.addTask(state.tasks, state.newTaskTitle, state.nextTaskId),
          nextTaskId: state.nextTaskId + 1,
          newTaskTitle: "",
        }
      }
    }
  | TaskToggle(id) => {
      ...state,
      tasks: Tasks.toggleTask(state.tasks, id),
    }
  | TaskDelete(id) => {
      ...state,
      tasks: Tasks.deleteTask(state.tasks, id),
    }
  | SetNewTaskTitle(title) => {
      ...state,
      newTaskTitle: title,
    }
  | OpenSettings => {
      ...state,
      settingsOpen: true,
    }
  | CloseSettings => {
      ...state,
      settingsOpen: false,
    }
  | UpdateWorkSecs(secs) => {
      let newTimer = {...state.timer, workSecs: secs}
      let finalTimer = switch newTimer.phase {
        | Idle => {...newTimer, timeLeft: secs}
        | _ => newTimer
      }
      {...state, timer: finalTimer}
    }
  | UpdateBreakSecs(secs) => {
      ...state,
      timer: {...state.timer, breakSecs: secs},
    }
  }
}

@react.component
let make = () => {
  let initialTimer = Timer.makeInitial(~workSecs=1500, ~breakSecs=300)
  let (state, dispatch) = React.useReducer(reducer, {
    timer: initialTimer,
    tasks: [],
    nextTaskId: 1,
    newTaskTitle: "",
    settingsOpen: false,
  })

  React.useEffect1(() => {
    switch state.timer.phase {
    | Working =>
      let id = setInterval(() => {
        dispatch(TimerTick)
      }, 1000)
      Some(() => clearInterval(id))
    | _ => None
    }
  }, [state.timer.phase])

  let phaseLabel = switch state.timer.phase {
  | Idle => "Ready"
  | Working => "Focus"
  | OnBreak => "Break"
  | Paused => "Paused"
  }

  let total = switch state.timer.phase {
  | Working | OnBreak => state.timer.timeLeft
  | _ => state.timer.workSecs
  }

  let progress = if total > 0 {
    let totalTime = switch state.timer.phase {
      | Working => state.timer.workSecs
      | OnBreak => state.timer.breakSecs
      | _ => state.timer.workSecs
    }
    ((totalTime - state.timer.timeLeft) * 100) / totalTime
  } else {
    0
  }

  let sessionText = switch state.timer.sessionCount {
  | 0 => "0 sessions"
  | 1 => "1 session"
  | n => Int.toString(n) ++ " sessions"
  }

  <div className="min-h-screen bg-background text-foreground flex flex-col items-center px-4 py-6 sm:p-8 pb-[env(safe-area-inset-bottom)] pt-[env(safe-area-inset-top)]">
    <SonnerToaster.Toaster position="bottom-center" richColors={true} />
    <button
      className="absolute top-4 right-6 inline-flex items-center justify-center size-9 rounded-md hover:bg-accent hover:text-accent-foreground transition-colors"
      onClick={_ => dispatch(OpenSettings)}>
      <svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
        <path d="M12.22 2h-.44a2 2 0 0 0-2 2v.18a2 2 0 0 1-1 1.73l-.43.25a2 2 0 0 1-2 0l-.15-.08a2 2 0 0 0-2.73.73l-.22.38a2 2 0 0 0 .73 2.73l.15.1a2 2 0 0 1 1 1.72v.51a2 2 0 0 1-1 1.74l-.15.09a2 2 0 0 0-.73 2.73l.22.38a2 2 0 0 0 2.73.73l.15-.08a2 2 0 0 1 2 0l.43.25a2 2 0 0 1 1 1.73V20a2 2 0 0 0 2 2h.44a2 2 0 0 0 2-2v-.18a2 2 0 0 1 1-1.73l.43-.25a2 2 0 0 1 2 0l.15.08a2 2 0 0 0 2.73-.73l.22-.39a2 2 0 0 0-.73-2.73l-.15-.08a2 2 0 0 1-1-1.74v-.5a2 2 0 0 1 1-1.74l.15-.09a2 2 0 0 0 .73-2.73l-.22-.38a2 2 0 0 0-2.73-.73l-.15.08a2 2 0 0 1-2 0l-.43-.25a2 2 0 0 1-1-1.73V4a2 2 0 0 0-2-2z"></path>
        <circle cx="12" cy="12" r="3"></circle>
      </svg>
    </button>

    <div className={"w-full max-w-md bg-card text-card-foreground rounded-xl border shadow-sm px-6 py-6 mb-6 " ++ (switch state.timer.phase {
  | Working => "ring-1 ring-emerald-900/50"
  | OnBreak => "ring-1 ring-sky-900/50"
  | _ => ""
})}>
      <div className="text-center mb-4">
        <span className="text-muted-foreground text-sm uppercase tracking-wider">
          {React.string(phaseLabel)}
        </span>
      </div>

      <div className="text-center mb-6">
        <span className="text-6xl sm:text-7xl font-mono font-bold tracking-tight">
          {React.string(Timer.formatTime(state.timer.timeLeft))}
        </span>
      </div>

      <div className="bg-primary/20 relative h-2 w-full overflow-hidden rounded-full">
        <div
          className="bg-primary h-full w-full flex-1 transition-all"
          style={{transform: "translateX(-" ++ Int.toString(100 - progress) ++ "%)"}}
        />
      </div>

      <div className="flex justify-center gap-3 mt-4">
        {switch state.timer.phase {
        | Idle =>
          <button
            className="inline-flex items-center justify-center gap-2 whitespace-nowrap rounded-md text-sm font-medium transition-all disabled:pointer-events-none disabled:opacity-50 bg-primary text-primary-foreground hover:bg-primary/90 h-9 px-4 py-2"
            onClick={_ => dispatch(TimerStart)}>
            {React.string("Start")}
          </button>
        | Working =>
          <button
            className="inline-flex items-center justify-center gap-2 whitespace-nowrap rounded-md text-sm font-medium transition-all disabled:pointer-events-none disabled:opacity-50 border bg-background shadow-xs hover:bg-accent hover:text-accent-foreground h-9 px-4 py-2"
            onClick={_ => dispatch(TimerPause)}>
            {React.string("Pause")}
          </button>
        | OnBreak =>
          <button
            className="inline-flex items-center justify-center gap-2 whitespace-nowrap rounded-md text-sm font-medium transition-all disabled:pointer-events-none disabled:opacity-50 border bg-background shadow-xs hover:bg-accent hover:text-accent-foreground h-9 px-4 py-2"
            onClick={_ => dispatch(TimerPause)}>
            {React.string("Pause Break")}
          </button>
        | Paused =>
          <button
            className="inline-flex items-center justify-center gap-2 whitespace-nowrap rounded-md text-sm font-medium transition-all disabled:pointer-events-none disabled:opacity-50 bg-primary text-primary-foreground hover:bg-primary/90 h-9 px-4 py-2"
            onClick={_ => dispatch(TimerResume)}>
            {React.string("Resume")}
          </button>
        }}
        <button
          className="inline-flex items-center justify-center gap-2 whitespace-nowrap rounded-md text-sm font-medium transition-all disabled:pointer-events-none disabled:opacity-50 hover:bg-accent hover:text-accent-foreground h-9 px-4 py-2"
          onClick={_ => dispatch(TimerReset)}>
          {React.string("Reset")}
        </button>
      </div>
    </div>

    <div className="mb-8">
      <span className="inline-flex items-center justify-center rounded-full border border-transparent px-3 py-1 text-xs font-medium bg-secondary text-secondary-foreground">
        {React.string(sessionText)}
      </span>
    </div>

    <div className="w-full max-w-md">
      <div className="flex gap-2 mb-4">
        <input
          type_="text"
          inputMode="text"
          className="dark:bg-input/30 border-input h-9 w-full min-w-0 rounded-md border bg-transparent px-3 py-1 text-base shadow-xs transition-[color,box-shadow] outline-none placeholder:text-muted-foreground focus-visible:border-ring focus-visible:ring-ring/50 focus-visible:ring-[3px]"
          placeholder="Add a task..."
          value={state.newTaskTitle}
          onChange={e => {
            let value = ReactEvent.Form.target(e)["value"]
            dispatch(SetNewTaskTitle(value))
          }}
          onKeyDown={e => {
            if ReactEvent.Keyboard.key(e) == "Enter" {
              dispatch(TaskAdd)
            }
          }}
        />
        <button
          className="inline-flex items-center justify-center gap-2 whitespace-nowrap rounded-md text-sm font-medium transition-all disabled:pointer-events-none disabled:opacity-50 bg-primary text-primary-foreground hover:bg-primary/90 h-9 px-4 py-2"
          onClick={_ => dispatch(TaskAdd)}>
          {React.string("Add")}
        </button>
      </div>

      <div className="max-h-64 sm:max-h-80 overflow-y-auto space-y-2 pr-1">
        {React.array(
          Belt.Array.map(state.tasks, task => {
            <div
              key={Int.toString(task.id)}
              className="flex items-center gap-3 p-3 bg-card border rounded-lg group">
              <input
                type_="checkbox"
                checked={task.done_}
                onChange={_ => dispatch(TaskToggle(task.id))}
                className="size-4 shrink-0 rounded border-input accent-primary cursor-pointer"
              />
              <span
                className={task.done_ ? "flex-1 line-through text-muted-foreground" : "flex-1 text-card-foreground"}>
                {React.string(task.title)}
              </span>
              <button
                className="sm:opacity-0 sm:group-hover:opacity-100 opacity-100 p-2 min-w-[44px] min-h-[44px] flex items-center justify-center hover:bg-destructive/10 hover:text-destructive rounded transition-opacity transition-colors text-muted-foreground"
                onClick={_ => dispatch(TaskDelete(task.id))}>
                <svg xmlns="http://www.w3.org/2000/svg" width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
                  <path d="M3 6h18"></path>
                  <path d="M19 6v14c0 1-1 2-2 2H7c-1 0-2-1-2-2V6"></path>
                  <path d="M8 6V4c0-1 1-2 2-2h4c1 0 2 1 2 2v2"></path>
                </svg>
              </button>
            </div>
          }),
        )}
      </div>
    </div>

    {if state.settingsOpen {
      <div className="fixed inset-0 bg-black/50 flex items-center justify-center z-50" onClick={_ => dispatch(CloseSettings)}>
        <div className="bg-background border rounded-lg p-6 w-full max-w-sm mx-4 shadow-lg" onClick={e => ReactEvent.Mouse.stopPropagation(e)}>
          <div className="flex justify-between items-center mb-6">
            <h2 className="text-lg font-semibold leading-none tracking-tight text-foreground">
              {React.string("Settings")}
            </h2>
            <button
              className="inline-flex items-center justify-center size-9 rounded-md hover:bg-accent hover:text-accent-foreground transition-colors"
              onClick={_ => dispatch(CloseSettings)}>
              <svg xmlns="http://www.w3.org/2000/svg" width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
                <path d="M18 6 6 18"></path>
                <path d="m6 6 12 12"></path>
              </svg>
            </button>
          </div>

          <div className="mb-6">
            <label className="block text-sm text-muted-foreground mb-3">
              {React.string("Work Duration: " ++ Int.toString(state.timer.workSecs / 60) ++ " min")}
            </label>
            <input
              type_="range"
              min="5"
              max="60"
              step={5.0}
              value={Int.toString(state.timer.workSecs / 60)}
              onChange={e => {
                let value = Int.fromString(ReactEvent.Form.target(e)["value"])
                switch value {
                | Some(v) => dispatch(UpdateWorkSecs(v * 60))
                | None => ()
                }
              }}
              className="w-full h-2 bg-primary/20 rounded-full appearance-none cursor-pointer accent-primary"
            />
          </div>

          <div className="mb-6">
            <label className="block text-sm text-muted-foreground mb-3">
              {React.string("Break Duration: " ++ Int.toString(state.timer.breakSecs / 60) ++ " min")}
            </label>
            <input
              type_="range"
              min="1"
              max="15"
              step={1.0}
              value={Int.toString(state.timer.breakSecs / 60)}
              onChange={e => {
                let value = Int.fromString(ReactEvent.Form.target(e)["value"])
                switch value {
                | Some(v) => dispatch(UpdateBreakSecs(v * 60))
                | None => ()
                }
              }}
              className="w-full h-2 bg-primary/20 rounded-full appearance-none cursor-pointer accent-primary"
            />
          </div>
        </div>
      </div>
    } else {
      React.null
    }}
  </div>
}