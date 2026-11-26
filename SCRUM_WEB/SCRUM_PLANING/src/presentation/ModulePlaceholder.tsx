interface ModulePlaceholderProps {
  title: string;
  notFound?: boolean;
}

export function ModulePlaceholder({
  title,
  notFound = false,
}: ModulePlaceholderProps) {
  return (
    <section className="rounded-2xl border border-sky-100 bg-white/90 p-6 shadow-lg shadow-sky-100/50 sm:p-8">
      <p className="text-xs font-medium uppercase tracking-wide text-sky-700">
        {notFound ? "Ruta" : "Módulo"}
      </p>
      <h2 className="mt-2 text-lg font-semibold text-slate-900">{title}</h2>
      <p className="mt-2 max-w-2xl text-sm leading-6 text-slate-600">
        {notFound
          ? "Esta ruta no existe. Usa el menú lateral para ir a un módulo disponible."
          : `El módulo ${title} todavía no está implementado. La navegación ya funciona y esta área queda reservada para desarrollar su contenido.`}
      </p>
    </section>
  );
}
