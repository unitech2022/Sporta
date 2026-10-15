// Presentational building blocks shared by the account/coach detail pages.
import { useState } from 'react';
import { ImageOff } from 'lucide-react';
import { resolveImageUrl } from './ImageUploadField';

/**
 * صورة تتحوّل إلى بديل رمادي إذا فشل تحميلها (رابط محفوظ في قاعدة البيانات
 * لكن الملف غير موجود على الخادم — يحدث كثيراً مع البيانات التجريبية).
 */
export function SafeImage({ url, alt, className, fallbackText = 'الصورة غير متوفرة' }) {
  const [failed, setFailed] = useState(false);
  const src = resolveImageUrl(url);

  if (!src || failed) {
    return (
      <div className={`${className} !bg-gray-50 border border-dashed border-gray-200 flex flex-col items-center justify-center gap-1 text-gray-300`}>
        <ImageOff className="w-5 h-5" />
        <span className="text-[10px] text-center px-1">{src ? fallbackText : 'لم تُرفع'}</span>
      </div>
    );
  }
  return (
    <a href={src} target="_blank" rel="noreferrer" title="فتح بالحجم الكامل" className="block">
      <img src={src} alt={alt} onError={() => setFailed(true)}
        className={`${className} hover:opacity-90 transition`} />
    </a>
  );
}

/** A titled white card. Renders nothing when it has no content to show. */
export function Section({ icon: Icon, title, action, children, hidden }) {
  if (hidden) return null;
  return (
    <div className="bg-white rounded-2xl border border-gray-100 p-5 shadow-sm">
      <div className="flex items-center justify-between mb-4">
        <p className="font-semibold text-gray-800 flex items-center gap-2">
          {Icon && <Icon className="w-4 h-4 text-[#2AB5CE]" />} {title}
        </p>
        {action}
      </div>
      {children}
    </div>
  );
}

/**
 * A label/value list. `rows` is an array of { label, value, icon?, dir? };
 * rows whose value is null/undefined/'' are dropped so empty fields don't
 * clutter the card.
 */
export function InfoRows({ rows, emptyText = 'لا توجد بيانات' }) {
  const visible = rows.filter((r) => r && r.value !== null && r.value !== undefined && r.value !== '');
  if (visible.length === 0) return <p className="text-sm text-gray-400">{emptyText}</p>;
  return (
    <div className="divide-y divide-gray-50">
      {visible.map((r) => (
        <div key={r.label} className="flex items-start justify-between gap-4 py-2.5">
          <span className="flex items-center gap-2 text-gray-500 text-sm shrink-0">
            {r.icon && <r.icon className="w-4 h-4 text-gray-400" />} {r.label}
          </span>
          <span className="font-medium text-gray-800 text-sm text-left" dir={r.dir}>
            {r.value}
          </span>
        </div>
      ))}
    </div>
  );
}

/** A single number/figure tile for the stats grid. */
export function StatTile({ icon: Icon, label, value, tone = 'text-gray-800' }) {
  return (
    <div className="bg-white rounded-2xl border border-gray-100 p-4 shadow-sm">
      <div className="flex items-center gap-2 text-gray-400 text-xs mb-1">
        {Icon && <Icon className="w-4 h-4" />} {label}
      </div>
      <p className={`text-lg font-bold ${tone}`}>{value}</p>
    </div>
  );
}

/** Chip list (specializations, available days, permissions…). */
export function Chips({ items, cls = 'bg-teal-50 text-teal-700' }) {
  if (!items?.length) return <p className="text-sm text-gray-400">—</p>;
  return (
    <div className="flex flex-wrap gap-2">
      {items.map((t, i) => (
        <span key={`${t}-${i}`} className={`px-3 py-1 rounded-full text-xs ${cls}`}>{t}</span>
      ))}
    </div>
  );
}

/** An uploaded document/photo, clickable to open full size. */
export function DocImage({ label, url }) {
  return (
    <div>
      <p className="text-xs text-gray-500 mb-2">{label}</p>
      <SafeImage url={url} alt={label}
        className="w-full h-40 object-cover rounded-xl border border-gray-200" />
    </div>
  );
}

/** Round avatar that falls back to the first letter of the name. */
export function Avatar({ url, name, size = 'w-24 h-24 text-3xl', gradient = 'from-indigo-400 to-violet-600' }) {
  const [failed, setFailed] = useState(false);
  const src = resolveImageUrl(url);
  if (src && !failed) {
    return (
      <img src={src} alt={name} onError={() => setFailed(true)}
        className={`${size} rounded-full object-cover border border-gray-100`} />
    );
  }
  return (
    <div className={`${size} rounded-full bg-gradient-to-br ${gradient} flex items-center justify-center text-white font-bold`}>
      {name?.[0] ?? '؟'}
    </div>
  );
}
