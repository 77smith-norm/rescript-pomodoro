open Vitest

// ============================================================
// Timer State Machine Tests
// ============================================================

describe("Timer.makeInitial", () => {
  test("creates idle timer with correct defaults", t => {
    let timer = Timer.makeInitial(~workSecs=1500, ~breakSecs=300)
    t->expect(timer.Timer.phase)->Expect.toBe(Timer.Idle)
    t->expect(timer.Timer.timeLeft)->Expect.toBe(1500)
    t->expect(timer.Timer.sessionCount)->Expect.toBe(0)
  })
})

describe("Timer.start", () => {
  test("transitions Idle to Working", t => {
    let timer = Timer.makeInitial(~workSecs=1500, ~breakSecs=300)
    let t2 = Timer.start(timer)
    t->expect(t2.Timer.phase)->Expect.toBe(Timer.Working)
    t->expect(t2.Timer.timeLeft)->Expect.toBe(1500)
  })
})

describe("Timer.pause", () => {
  test("transitions Working to Paused", t => {
    let timer = {...Timer.makeInitial(~workSecs=1500, ~breakSecs=300), Timer.phase: Timer.Working}
    let t2 = Timer.pause(timer)
    t->expect(t2.Timer.phase)->Expect.toBe(Timer.Paused)
  })

  test("preserves timeLeft when pausing", t => {
    let timer = {...Timer.makeInitial(~workSecs=1500, ~breakSecs=300), Timer.phase: Timer.Working, Timer.timeLeft: 742}
    let t2 = Timer.pause(timer)
    t->expect(t2.Timer.timeLeft)->Expect.toBe(742)
  })

  test("no-op when already Idle", t => {
    let timer = Timer.makeInitial(~workSecs=1500, ~breakSecs=300)
    let t2 = Timer.pause(timer)
    t->expect(t2.Timer.phase)->Expect.toBe(Timer.Idle)
  })
})

describe("Timer.resume", () => {
  test("transitions Paused to Working", t => {
    let timer = {...Timer.makeInitial(~workSecs=1500, ~breakSecs=300), Timer.phase: Timer.Paused, Timer.timeLeft: 600}
    let t2 = Timer.resume(timer)
    t->expect(t2.Timer.phase)->Expect.toBe(Timer.Working)
    t->expect(t2.Timer.timeLeft)->Expect.toBe(600)
  })
})

describe("Timer.reset", () => {
  test("resets to Idle with original workSecs", t => {
    let timer = {...Timer.makeInitial(~workSecs=1500, ~breakSecs=300), Timer.phase: Timer.Working, Timer.timeLeft: 42}
    let t2 = Timer.reset(timer)
    t->expect(t2.Timer.phase)->Expect.toBe(Timer.Idle)
    t->expect(t2.Timer.timeLeft)->Expect.toBe(1500)
  })

  test("preserves sessionCount on reset", t => {
    let timer = {...Timer.makeInitial(~workSecs=1500, ~breakSecs=300), Timer.sessionCount: 3}
    let t2 = Timer.reset(timer)
    t->expect(t2.Timer.sessionCount)->Expect.toBe(3)
  })
})

describe("Timer.tick", () => {
  test("decrements timeLeft by 1 while Working", t => {
    let timer = {...Timer.makeInitial(~workSecs=1500, ~breakSecs=300), Timer.phase: Timer.Working, Timer.timeLeft: 10}
    let (t2, completed) = Timer.tick(timer)
    t->expect(t2.Timer.timeLeft)->Expect.toBe(9)
    t->expect(completed)->Expect.toBe(false)
  })

  test("decrements timeLeft by 1 while OnBreak", t => {
    let timer = {...Timer.makeInitial(~workSecs=1500, ~breakSecs=300), Timer.phase: Timer.OnBreak, Timer.timeLeft: 5}
    let (t2, completed) = Timer.tick(timer)
    t->expect(t2.Timer.timeLeft)->Expect.toBe(4)
    t->expect(completed)->Expect.toBe(false)
  })

  test("signals completion and starts break when Working reaches 0", t => {
    let timer = {...Timer.makeInitial(~workSecs=1500, ~breakSecs=300), Timer.phase: Timer.Working, Timer.timeLeft: 1}
    let (t2, completed) = Timer.tick(timer)
    t->expect(completed)->Expect.toBe(true)
    t->expect(t2.Timer.sessionCount)->Expect.toBe(1)
    t->expect(t2.Timer.phase)->Expect.toBe(Timer.OnBreak)
    t->expect(t2.Timer.timeLeft)->Expect.toBe(300)
  })

  test("signals completion and returns to Working when OnBreak reaches 0", t => {
    let timer = {...Timer.makeInitial(~workSecs=1500, ~breakSecs=300), Timer.phase: Timer.OnBreak, Timer.timeLeft: 1}
    let (t2, completed) = Timer.tick(timer)
    t->expect(completed)->Expect.toBe(true)
    t->expect(t2.Timer.phase)->Expect.toBe(Timer.Working)
    t->expect(t2.Timer.timeLeft)->Expect.toBe(1500)
  })

  test("no-op when Idle", t => {
    let timer = Timer.makeInitial(~workSecs=1500, ~breakSecs=300)
    let (t2, completed) = Timer.tick(timer)
    t->expect(t2.Timer.phase)->Expect.toBe(Timer.Idle)
    t->expect(completed)->Expect.toBe(false)
  })

  test("no-op when Paused", t => {
    let timer = {...Timer.makeInitial(~workSecs=1500, ~breakSecs=300), Timer.phase: Timer.Paused, Timer.timeLeft: 100}
    let (t2, completed) = Timer.tick(timer)
    t->expect(t2.Timer.timeLeft)->Expect.toBe(100)
    t->expect(completed)->Expect.toBe(false)
  })
})

describe("Timer.formatTime", () => {
  test("formats 90 seconds as 1:30", t => {
    t->expect(Timer.formatTime(90))->Expect.toBe("1:30")
  })

  test("formats 0 as 0:00", t => {
    t->expect(Timer.formatTime(0))->Expect.toBe("0:00")
  })

  test("formats 1500 as 25:00", t => {
    t->expect(Timer.formatTime(1500))->Expect.toBe("25:00")
  })

  test("pads single-digit seconds", t => {
    t->expect(Timer.formatTime(61))->Expect.toBe("1:01")
  })
})

// ============================================================
// Tasks Tests
// ============================================================

describe("Tasks.addTask", () => {
  test("adds a new task with given title", t => {
    let tasks = Tasks.addTask([], "Buy groceries", 1)
    t->expect(Array.length(tasks))->Expect.toBe(1)
    switch tasks[0] {
    | None => t->expect("got None")->Expect.toBe("expected task")
    | Some(task) => {
        t->expect(task.Tasks.title)->Expect.toBe("Buy groceries")
        t->expect(task.Tasks.done_)->Expect.toBe(false)
        t->expect(task.Tasks.id)->Expect.toBe(1)
      }
    }
  })

  test("appends to existing tasks", t => {
    let tasks = Tasks.addTask([], "First", 1)->Tasks.addTask("Second", 2)
    t->expect(Array.length(tasks))->Expect.toBe(2)
  })
})

describe("Tasks.toggleTask", () => {
  test("marks an incomplete task as done", t => {
    let tasks = Tasks.addTask([], "Write tests", 1)
    let tasks2 = Tasks.toggleTask(tasks, 1)
    switch tasks2[0] {
    | None => t->expect("got None")->Expect.toBe("expected task")
    | Some(task) => t->expect(task.Tasks.done_)->Expect.toBe(true)
    }
  })

  test("marks a done task as incomplete", t => {
    let tasks = Tasks.addTask([], "Write tests", 1)->Tasks.toggleTask(1)->Tasks.toggleTask(1)
    switch tasks[0] {
    | None => t->expect("got None")->Expect.toBe("expected task")
    | Some(task) => t->expect(task.Tasks.done_)->Expect.toBe(false)
    }
  })

  test("only toggles the targeted task", t => {
    let tasks =
      Tasks.addTask([], "First", 1)
      ->Tasks.addTask("Second", 2)
      ->Tasks.toggleTask(1)
    switch tasks[1] {
    | None => t->expect("got None")->Expect.toBe("expected task")
    | Some(task) => t->expect(task.Tasks.done_)->Expect.toBe(false)
    }
  })
})

describe("Tasks.deleteTask", () => {
  test("removes the task with matching id", t => {
    let tasks =
      Tasks.addTask([], "Keep", 1)
      ->Tasks.addTask("Delete me", 2)
      ->Tasks.deleteTask(2)
    t->expect(Array.length(tasks))->Expect.toBe(1)
    switch tasks[0] {
    | None => t->expect("got None")->Expect.toBe("expected task")
    | Some(task) => t->expect(task.Tasks.title)->Expect.toBe("Keep")
    }
  })

  test("no-op when id not found", t => {
    let tasks = Tasks.addTask([], "Task", 1)->Tasks.deleteTask(99)
    t->expect(Array.length(tasks))->Expect.toBe(1)
  })
})

describe("Tasks.countDone", () => {
  test("counts completed tasks", t => {
    let tasks =
      Tasks.addTask([], "A", 1)
      ->Tasks.addTask("B", 2)
      ->Tasks.addTask("C", 3)
      ->Tasks.toggleTask(1)
      ->Tasks.toggleTask(3)
    t->expect(Tasks.countDone(tasks))->Expect.toBe(2)
  })

  test("returns 0 for empty list", t => {
    t->expect(Tasks.countDone([]))->Expect.toBe(0)
  })
})
