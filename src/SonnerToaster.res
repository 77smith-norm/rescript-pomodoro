// Sonner toast bindings for rescript-pomodoro
// shadcn/sonner wraps the sonner library.
// Docs: https://ui.shadcn.com/docs/components/sonner

// Toaster — drop into root layout, renders the toast portal
module Toaster = {
  @module("sonner") @react.component
  external make: (
    ~position: string=?,
    ~richColors: bool=?,
    ~theme: string=?,
    ~closeButton: bool=?,
  ) => React.element = "Toaster"
}

// toast API — imperative calls from anywhere in the app
type toastFn = {
  success: string => unit,
}

@module("sonner")
external toast: toastFn = "toast"
