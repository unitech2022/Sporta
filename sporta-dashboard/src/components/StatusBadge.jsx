const configs = {
  active:    { label: 'نشط',     cls: 'bg-green-100 text-green-700' },
  inactive:  { label: 'موقوف',   cls: 'bg-gray-100 text-gray-500' },
  published: { label: 'منشور',   cls: 'bg-green-100 text-green-700' },
  draft:     { label: 'مسودة',   cls: 'bg-yellow-100 text-yellow-700' },
  paid:      { label: 'مدفوع',   cls: 'bg-green-100 text-green-700' },
  pending:   { label: 'معلق',    cls: 'bg-yellow-100 text-yellow-700' },
  overdue:   { label: 'متأخر',   cls: 'bg-red-100 text-red-600' },
  completed: { label: 'منتهية',  cls: 'bg-blue-100 text-blue-700' },
  upcoming:  { label: 'قادمة',   cls: 'bg-purple-100 text-purple-700' },
};

export default function StatusBadge({ status, label }) {
  const cfg = configs[status] ?? { label: status, cls: 'bg-gray-100 text-gray-500' };
  return (
    <span className={`inline-block px-2.5 py-0.5 rounded-full text-xs font-medium ${cfg.cls}`}>
      {label ?? cfg.label}
    </span>
  );
}
