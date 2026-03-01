// Pure task CRUD - no React

type task = {
  id: int,
  title: string,
  done_: bool,
}

let addTask = (tasks: array<task>, title: string, id: int): array<task> => {
  let newTask = {id: id, title: title, done_: false}
  Array.concat(tasks, [newTask])
}

let toggleTask = (tasks: array<task>, id: int): array<task> => {
  Belt.Array.map(tasks, task => {
    if task.id == id {
      {...task, done_: !task.done_}
    } else {
      task
    }
  })
}

let deleteTask = (tasks: array<task>, id: int): array<task> => {
  Belt.Array.keep(tasks, task => task.id !== id)
}

let countDone = (tasks: array<task>): int => {
  Belt.Array.reduce(tasks, 0, (acc, task) => {
    if task.done_ {
      acc + 1
    } else {
      acc
    }
  })
}
