/* eslint-disable */
export default {
  Toaster: window.Sonner?.Toaster ?? function Toaster() { return null; },
  success_: function(message) { 
    if (window.Sonner?.toast?.success) {
      window.Sonner.toast.success(message);
    }
  }
};