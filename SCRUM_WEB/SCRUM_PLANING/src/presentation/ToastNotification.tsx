import { useEffect } from "react";

export interface ToastMessage {
  id: number;
  message: string;
  type: "error" | "success";
}

interface ToastNotificationProps {
  toast: ToastMessage | null;
  onDismiss: () => void;
}

export function ToastNotification({
  toast,
  onDismiss,
}: ToastNotificationProps) {
  useEffect(() => {
    if (!toast) return;
    const timeoutId = window.setTimeout(onDismiss, 5000);
    return () => window.clearTimeout(timeoutId);
  }, [toast, onDismiss]);

  if (!toast) return null;

  const isError = toast.type === "error";
  return (
    <div
      role={isError ? "alert" : "status"}
      aria-live={isError ? "assertive" : "polite"}
      className={`fixed right-4 top-4 z-[60] flex w-[calc(100%-2rem)] max-w-sm items-start gap-3 rounded-xl border bg-white p-4 text-sm shadow-lg sm:right-6 sm:top-6 ${
        isError
          ? "border-red-200 text-red-800 shadow-red-900/10"
          : "border-emerald-200 text-emerald-800 shadow-emerald-900/10"
      }`}
    >
      <p className="flex-1">{toast.message}</p>
      <button
        type="button"
        onClick={onDismiss}
        aria-label="Cerrar notificación"
        className="cursor-pointer rounded px-1 text-slate-400 transition hover:bg-slate-100 hover:text-slate-700 focus:outline-none focus-visible:ring-2 focus-visible:ring-sky-500/40"
      >
        ×
      </button>
    </div>
  );
}
