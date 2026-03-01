@@live

type createRootOptions = {
  onUncaughtError: exn => unit,
  onCaughtError: exn => unit,
}

@module("react-dom/client")
external createRootWithOptions: (Dom.element, createRootOptions) => ReactDOM.Client.Root.t =
  "createRoot"

switch ReactDOM.querySelector("#root") {
| None => ()
| Some(root) =>
  createRootWithOptions(root, {
    onUncaughtError: e => Console.error2("React uncaught error:", e),
    onCaughtError: e => Console.error2("React caught error:", e),
  })->ReactDOM.Client.Root.render(
    <React.StrictMode>
      <App />
    </React.StrictMode>,
  )
}
