// Pure timer state machine - no React

type phase = Idle | Working | OnBreak | Paused

type timer = {
  phase: phase,
  timeLeft: int,
  workSecs: int,
  breakSecs: int,
  sessionCount: int,
}

let makeInitial = (~workSecs, ~breakSecs): timer => {
  phase: Idle,
  timeLeft: workSecs,
  workSecs: workSecs,
  breakSecs: breakSecs,
  sessionCount: 0,
}

let start = (timer: timer): timer => {
  switch timer.phase {
  | Idle => {...timer, phase: Working}
  | _ => timer  // no-op for other phases
  }
}

let pause = (timer: timer): timer => {
  switch timer.phase {
  | Working => {...timer, phase: Paused}
  | OnBreak => {...timer, phase: Paused}
  | _ => timer  // no-op for Idle or Paused
  }
}

let resume = (timer: timer): timer => {
  switch timer.phase {
  | Paused => {...timer, phase: Working}
  | _ => timer  // no-op for other phases
  }
}

let reset = (timer: timer): timer => {
  {...timer, phase: Idle, timeLeft: timer.workSecs}
}

let tick = (timer: timer): (timer, bool) => {
  switch timer.phase {
  | Working =>
    if timer.timeLeft > 1 {
      ({...timer, timeLeft: timer.timeLeft - 1}, false)
    } else {
      // Work session complete - start break
      ({
        ...timer,
        phase: OnBreak,
        timeLeft: timer.breakSecs,
        sessionCount: timer.sessionCount + 1,
      }, true)
    }
  | OnBreak =>
    if timer.timeLeft > 1 {
      ({...timer, timeLeft: timer.timeLeft - 1}, false)
    } else {
      // Break complete - start working
      ({
        ...timer,
        phase: Working,
        timeLeft: timer.workSecs,
      }, true)
    }
  | Idle | Paused =>
    (timer, false)  // no-op, completed = false
  }
}

let formatTime = (seconds: int): string => {
  let mins = seconds / 60
  let secs = seconds - (mins * 60)
  let minsStr = Int.toString(mins)
  let secsStr = if secs < 10 {
    "0" ++ Int.toString(secs)
  } else {
    Int.toString(secs)
  }
  minsStr ++ ":" ++ secsStr
}
