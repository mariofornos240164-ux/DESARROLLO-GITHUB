import { useState } from "react";

export interface ColumnOption {
  label: string;
  checked: boolean;
  onToggle: () => void;
}

interface ColumnOptionsMenuProps {
  options: ColumnOption[];
}

export function ColumnOptionsMenu({ options }: ColumnOptionsMenuProps) {
  const [isOpen, setIsOpen] = useState(false);
  const checkedCount = options.filter((option) => option.checked).length;

  return (
    <div className="relative">
      <button
        type="button"
        onClick={() => setIsOpen((open) => !open)}
        aria-expanded={isOpen}
        aria-haspopup="true"
        className="cursor-pointer rounded-lg px-3 py-2 font-medium text-slate-600 transition hover:bg-sky-50 hover:text-sky-800"
      >
        Opciones de columna
      </button>
      {isOpen && (
        <div
          role="group"
          aria-label="Columnas visibles"
          className="absolute right-0 z-20 mt-2 grid min-w-48 gap-2 rounded-xl border border-slate-200 bg-white p-3 text-xs shadow-xl"
        >
          {options.map((option) => (
            <label
              key={option.label}
              className="flex cursor-pointer items-center gap-2 rounded px-2 py-1.5 text-slate-700 hover:bg-sky-50"
            >
              <input
                type="checkbox"
                checked={option.checked}
                disabled={option.checked && checkedCount === 1}
                onChange={option.onToggle}
                className="h-4 w-4 accent-sky-600"
              />
              {option.label}
            </label>
          ))}
        </div>
      )}
    </div>
  );
}
