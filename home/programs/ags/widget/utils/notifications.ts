import { App, Gtk } from "astal/gtk3";
import { bind, Variable, GLib } from "astal";

// Utility function to setup auto-dismiss behavior for AGS windows
export function setupAutoDismiss(
  window: Gtk.Window,
  windowName: string,
  delay: number = 200,
) {
  let dismissTimeout: GLib.Source | null = null;

  const scheduleAutoDismiss = () => {
    // Clear any existing timeout
    if (dismissTimeout) {
      dismissTimeout.destroy();
      dismissTimeout = null;
    }

    // Schedule dismissal
    dismissTimeout = setTimeout(() => {
      if (window.visible && !window.hasToplevelFocus) {
        App.toggle_window(windowName);
      }
      dismissTimeout = null;
    }, delay);
  };

  const cancelAutoDismiss = () => {
    if (dismissTimeout) {
      dismissTimeout.destroy();
      dismissTimeout = null;
    }
  };

  // Monitor focus changes
  window.connect("notify::has-toplevel-focus", () => {
    if (!window.hasToplevelFocus && window.visible) {
      scheduleAutoDismiss();
    } else {
      cancelAutoDismiss();
    }
  });

  // Also monitor visibility changes to clean up timeouts
  window.connect("notify::visible", () => {
    if (!window.visible) {
      cancelAutoDismiss();
    }
  });

  // Handle mouse leave events
  window.connect("leave-notify-event", () => {
    if (window.visible && !window.hasToplevelFocus) {
      scheduleAutoDismiss();
    }
  });

  // Cancel dismissal on mouse enter
  window.connect("enter-notify-event", () => {
    cancelAutoDismiss();
  });
}

// Enhanced setup for windows that should stay open while interacting with child elements
export function setupSmartAutoDismiss(
  window: Gtk.Window,
  windowName: string,
  delay: number = 500,
) {
  let dismissTimeout: GLib.Source | null = null;
  let isInteracting = false;

  const scheduleAutoDismiss = () => {
    if (dismissTimeout) {
      dismissTimeout.destroy();
      dismissTimeout = null;
    }

    dismissTimeout = setTimeout(() => {
      if (window.visible && !window.hasToplevelFocus && !isInteracting) {
        App.toggle_window(windowName);
      }
      dismissTimeout = null;
    }, delay);
  };

  const cancelAutoDismiss = () => {
    if (dismissTimeout) {
      dismissTimeout.destroy();
      dismissTimeout = null;
    }
  };

  // Track various interaction states
  window.connect("notify::has-toplevel-focus", () => {
    if (!window.hasToplevelFocus && window.visible) {
      scheduleAutoDismiss();
    } else {
      cancelAutoDismiss();
    }
  });

  window.connect("button-press-event", () => {
    isInteracting = true;
    cancelAutoDismiss();
  });

  window.connect("button-release-event", () => {
    isInteracting = false;
    if (!window.hasToplevelFocus) {
      scheduleAutoDismiss();
    }
  });

  window.connect("motion-notify-event", () => {
    cancelAutoDismiss();
  });

  window.connect("leave-notify-event", () => {
    isInteracting = false;
    if (window.visible && !window.hasToplevelFocus) {
      scheduleAutoDismiss();
    }
  });

  window.connect("enter-notify-event", () => {
    cancelAutoDismiss();
  });

  window.connect("notify::visible", () => {
    if (!window.visible) {
      cancelAutoDismiss();
      isInteracting = false;
    }
  });
}
