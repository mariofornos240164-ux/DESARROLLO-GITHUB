interface BrandLogoProps {
  /** Muestra el slogan debajo del nombre. */
  showSlogan?: boolean;
  className?: string;
}

export const BRAND_NAME = "Scrum Planning";
export const BRAND_SLOGAN = "Orden en cada sprint, confianza en cada entrega.";

/** Isotipo geométrico: tres bloques escalonados (backlog → sprint → entrega). */
function BrandMark({ className = "" }: { className?: string }) {
  return (
    <svg
      viewBox="0 0 48 48"
      role="img"
      aria-hidden="true"
      className={className}
      xmlns="http://www.w3.org/2000/svg"
    >
      <defs>
        <linearGradient id="brand-mark-bg" x1="0" y1="0" x2="1" y2="1">
          <stop offset="0%" stopColor="#0ea5e9" />
          <stop offset="100%" stopColor="#2563eb" />
        </linearGradient>
      </defs>
      <rect width="48" height="48" rx="12" fill="url(#brand-mark-bg)" />
      <rect x="11" y="28" width="7" height="9" rx="2" fill="#ffffff" opacity="0.55" />
      <rect x="20.5" y="21" width="7" height="16" rx="2" fill="#ffffff" opacity="0.8" />
      <rect x="30" y="13" width="7" height="24" rx="2" fill="#ffffff" />
    </svg>
  );
}

export function BrandLogo({ showSlogan = true, className = "" }: BrandLogoProps) {
  return (
    <div className={`flex flex-col items-center text-center ${className}`}>
      <div className="flex items-center gap-3">
        <BrandMark className="h-11 w-11 shadow-md shadow-sky-500/20 sm:h-12 sm:w-12" />
        <span className="text-2xl font-semibold tracking-tight text-slate-900 sm:text-[26px]">
          {BRAND_NAME}
        </span>
      </div>
      {showSlogan && (
        <p className="mt-3 max-w-xs text-sm text-slate-500">{BRAND_SLOGAN}</p>
      )}
    </div>
  );
}
