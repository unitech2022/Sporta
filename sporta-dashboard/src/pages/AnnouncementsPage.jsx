import { useState } from 'react';
import { Search, Plus, Megaphone, Edit3, Trash2, X, Save } from 'lucide-react';
import { adminApi } from '../api/adminApi';
import { useApi } from '../hooks/useApi';
import PageHeader from '../components/PageHeader';
import StatusBadge from '../components/StatusBadge';
import ConfirmModal from '../components/ConfirmModal';
import { Spinner, Empty } from '../components/TableBits';
import ImageUploadField, { resolveImageUrl } from '../components/ImageUploadField';

const TARGETS = [
  ['', 'بدون'],
  ['courts', 'الملاعب'],
  ['matches', 'المباريات'],
  ['coaches', 'المدربون'],
];
const targetLabel = (t) => TARGETS.find((x) => x[0] === (t ?? ''))?.[1] ?? t;

// أماكن ظهور الإعلان داخل التطبيق (غير "الوجهة عند الضغط" أعلاه).
const PLACEMENTS = [
  ['home', 'الرئيسية'],
  ['courts', 'الملاعب'],
  ['matches', 'المباريات'],
  ['coaches', 'المدربون'],
];
const placementList = (p) =>
  (p ?? '').split(',').map((x) => x.trim()).filter(Boolean);
const placementLabels = (p) => {
  const list = placementList(p);
  const names = (list.length ? list : ['home'])
    .map((x) => PLACEMENTS.find((y) => y[0] === x)?.[1] ?? x);
  return names.join('، ');
};
const inputCls =
  'w-full px-4 py-2.5 border border-gray-200 rounded-xl text-sm focus:outline-none focus:ring-2 focus:ring-[#2AB5CE] bg-gray-50';

export default function AnnouncementsPage() {
  const [search, setSearch] = useState('');
  const [formModal, setFormModal] = useState(null); // 'new' | ad
  const [confirm, setConfirm] = useState(null);

  const { data, loading, error, refetch } = useApi(() => adminApi.getAds(), []);
  const ads = data ?? [];
  const q = search.trim().toLowerCase();
  const filtered = ads.filter((a) =>
    [a.title, a.subtitle, a.titleEn, a.subtitleEn]
      .some((t) => (t ?? '').toLowerCase().includes(q)),
  );

  const remove = async () => {
    await adminApi.deleteAd(confirm.item.id);
    setConfirm(null);
    refetch();
  };

  return (
    <div>
      <PageHeader
        title="الإعلانات"
        subtitle={`${ads.length} إعلان في سلايدر التطبيق`}
        action={
          <button onClick={() => setFormModal('new')}
            className="flex items-center gap-2 px-4 py-2.5 bg-[#2AB5CE] hover:bg-[#1E9AB0] text-white rounded-xl text-sm font-medium shadow transition">
            <Plus className="w-4 h-4" /> إعلان جديد
          </button>
        }
      />

      <div className="relative flex-1 mb-5">
        <Search className="absolute right-3 top-1/2 -translate-y-1/2 w-4 h-4 text-gray-400" />
        <input value={search} onChange={(e) => setSearch(e.target.value)}
          placeholder="بحث بالعنوان أو الوصف..."
          className="w-full pr-9 pl-4 py-2.5 border border-gray-200 rounded-xl text-sm focus:outline-none focus:ring-2 focus:ring-[#2AB5CE] bg-white" />
      </div>

      {loading ? (
        <Spinner />
      ) : error ? (
        <div className="text-center py-16 text-red-500 text-sm">{error}</div>
      ) : filtered.length === 0 ? (
        <Empty icon={Megaphone} text="لا توجد إعلانات" />
      ) : (
        <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 gap-4">
          {filtered.map((a) => (
            <div key={a.id} className="bg-white rounded-2xl shadow-sm border border-gray-100 overflow-hidden">
              <div className="h-32 bg-gray-100 relative">
                {a.imageUrl
                  ? <img src={resolveImageUrl(a.imageUrl)} alt={a.title} className="w-full h-full object-cover" />
                  : <div className="w-full h-full flex items-center justify-center text-gray-300"><Megaphone className="w-8 h-8" /></div>}
                <div className="absolute top-2 left-2">
                  <StatusBadge status={a.isActive ? 'active' : 'inactive'} />
                </div>
              </div>
              <div className="p-4">
                <p className="font-semibold text-gray-800 truncate">{a.title || 'إعلان بلا عنوان'}</p>
                <p className="text-xs text-gray-400 truncate mt-0.5">{a.subtitle || '—'}</p>
                <p className="text-xs text-gray-500 truncate mt-1.5" dir="ltr">{a.titleEn || '—'}</p>
                <div className="flex flex-wrap items-center gap-1.5 mt-3">
                  <span className="text-xs px-2 py-1 rounded-full bg-emerald-50 text-emerald-600">
                    يظهر في: {placementLabels(a.placements)}
                  </span>
                  <span className="text-xs px-2 py-1 rounded-full bg-blue-50 text-blue-600">
                    الضغط: {targetLabel(a.target)}
                  </span>
                </div>
                <div className="flex items-center justify-end mt-3">
                  <div className="flex items-center gap-1.5">
                    <button onClick={() => setFormModal(a)}
                      className="p-1.5 rounded-lg bg-gray-50 text-gray-600 hover:bg-gray-100 transition">
                      <Edit3 className="w-3.5 h-3.5" />
                    </button>
                    <button onClick={() => setConfirm({ item: a })}
                      className="p-1.5 rounded-lg bg-red-50 text-red-500 hover:bg-red-100 transition">
                      <Trash2 className="w-3.5 h-3.5" />
                    </button>
                  </div>
                </div>
              </div>
            </div>
          ))}
        </div>
      )}

      {formModal && (
        <AdFormModal
          initial={formModal === 'new' ? null : formModal}
          onClose={() => setFormModal(null)}
          onSaved={() => { setFormModal(null); refetch(); }}
        />
      )}
      <ConfirmModal
        open={!!confirm}
        title="حذف الإعلان"
        message={`هل أنت متأكد من حذف "${confirm?.item?.title}"؟`}
        onConfirm={remove}
        onCancel={() => setConfirm(null)}
      />
    </div>
  );
}

function AdFormModal({ initial, onClose, onSaved }) {
  const [form, setForm] = useState(
    initial
      ? {
          title: initial.title, subtitle: initial.subtitle ?? '',
          titleEn: initial.titleEn ?? '', subtitleEn: initial.subtitleEn ?? '',
          imageUrl: initial.imageUrl ?? '', target: initial.target ?? '',
          placements: placementList(initial.placements).length
            ? placementList(initial.placements)
            : ['home'],
          isActive: initial.isActive, sortOrder: initial.sortOrder ?? 0,
        }
      : {
          title: '', subtitle: '', titleEn: '', subtitleEn: '',
          imageUrl: '', target: '', placements: ['home'],
          isActive: true, sortOrder: 0,
        },
  );
  const [saving, setSaving] = useState(false);
  const [err, setErr] = useState(null);
  // الصورة وحدها إلزامية — النصوص اختيارية (إعلان صورة فقط مقبول).
  const valid = form.imageUrl.trim() && form.placements.length > 0;

  const togglePlacement = (key) =>
    setForm((f) => ({
      ...f,
      placements: f.placements.includes(key)
        ? f.placements.filter((p) => p !== key)
        : [...f.placements, key],
    }));

  const submit = async (e) => {
    e.preventDefault();
    if (!valid || saving) return;
    setSaving(true);
    setErr(null);
    try {
      const body = {
        ...form,
        sortOrder: Number(form.sortOrder),
        placements: form.placements.join(','),
      };
      if (initial) await adminApi.updateAd(initial.id, body);
      else await adminApi.createAd(body);
      onSaved();
    } catch (e2) {
      setErr(e2?.response?.data?.messageAr || 'تعذّر الحفظ');
      setSaving(false);
    }
  };

  return (
    <div className="fixed inset-0 bg-black/50 z-50 flex items-center justify-center p-4">
      <div className="bg-white rounded-2xl shadow-2xl w-full max-w-lg max-h-[92vh] flex flex-col">
        <div className="flex items-center justify-between px-6 py-4 border-b border-gray-100 shrink-0">
          <h3 className="font-bold text-gray-800 text-lg">{initial ? 'تعديل الإعلان' : 'إعلان جديد'}</h3>
          <button onClick={onClose} className="w-8 h-8 flex items-center justify-center rounded-lg hover:bg-gray-100 text-gray-400">
            <X className="w-5 h-5" />
          </button>
        </div>
        <form onSubmit={submit} className="flex-1 min-h-0 flex flex-col">
          <div className="p-6 space-y-4 overflow-y-auto">
            <Field label="العنوان (اختياري)">
              <input className={inputCls} value={form.title}
                onChange={(e) => setForm((f) => ({ ...f, title: e.target.value }))} placeholder="احجز ملعبك المفضل" />
            </Field>
            <Field label="الوصف (اختياري)">
              <input className={inputCls} value={form.subtitle}
                onChange={(e) => setForm((f) => ({ ...f, subtitle: e.target.value }))} placeholder="أفضل ملاعب البادل بانتظارك" />
            </Field>
            <Field label="العنوان بالإنجليزية (اختياري)">
              <input className={inputCls} value={form.titleEn} dir="ltr"
                onChange={(e) => setForm((f) => ({ ...f, titleEn: e.target.value }))} placeholder="Book your favourite court" />
            </Field>
            <Field label="الوصف بالإنجليزية (اختياري)">
              <input className={inputCls} value={form.subtitleEn} dir="ltr"
                onChange={(e) => setForm((f) => ({ ...f, subtitleEn: e.target.value }))} placeholder="The best padel courts are waiting" />
            </Field>
            <ImageUploadField
              label="صورة الإعلان (إلزامية)"
              value={form.imageUrl}
              onChange={(url) => setForm((f) => ({ ...f, imageUrl: url ?? '' }))}
            />
            {form.imageUrl && (
              <img src={resolveImageUrl(form.imageUrl)} alt=""
                className="w-full h-32 object-cover rounded-xl border border-gray-100" />
            )}
            <Field label="أماكن الظهور في التطبيق">
              <div className="grid grid-cols-2 gap-2">
                {PLACEMENTS.map(([key, label]) => (
                  <label key={key}
                    className="flex items-center gap-2 px-3 py-2 border border-gray-200 rounded-xl bg-gray-50 cursor-pointer text-sm text-gray-700">
                    <input type="checkbox" className="w-4 h-4 accent-[#2AB5CE]"
                      checked={form.placements.includes(key)}
                      onChange={() => togglePlacement(key)} />
                    {label}
                  </label>
                ))}
              </div>
              {form.placements.length === 0 && (
                <p className="text-xs text-red-500 mt-1.5">اختر صفحة واحدة على الأقل.</p>
              )}
            </Field>
            <div className="grid grid-cols-2 gap-4">
              <Field label="الوجهة عند الضغط">
                <select className={inputCls} value={form.target}
                  onChange={(e) => setForm((f) => ({ ...f, target: e.target.value }))}>
                  {TARGETS.map(([v, l]) => <option key={v} value={v}>{l}</option>)}
                </select>
              </Field>
              <Field label="الترتيب">
                <input type="number" className={inputCls} value={form.sortOrder}
                  onChange={(e) => setForm((f) => ({ ...f, sortOrder: e.target.value }))} />
              </Field>
            </div>
            <label className="flex items-center gap-2 cursor-pointer">
              <input type="checkbox" checked={form.isActive}
                onChange={(e) => setForm((f) => ({ ...f, isActive: e.target.checked }))}
                className="w-4 h-4 accent-[#2AB5CE]" />
              <span className="text-sm text-gray-700">مفعّل (يظهر في التطبيق)</span>
            </label>
            {err && <p className="text-sm text-red-500">{err}</p>}
          </div>
          <div className="flex gap-3 px-6 py-4 border-t border-gray-100 shrink-0">
            <button type="button" onClick={onClose}
              className="flex-1 py-2.5 border border-gray-200 rounded-xl text-gray-600 font-medium hover:bg-gray-50 transition text-sm">
              إلغاء
            </button>
            <button type="submit" disabled={!valid || saving}
              className="flex-1 py-2.5 bg-[#2AB5CE] hover:bg-[#1E9AB0] disabled:bg-gray-200 disabled:text-gray-400 text-white font-medium rounded-xl transition text-sm flex items-center justify-center gap-2">
              <Save className="w-4 h-4" /> {saving ? 'جارٍ الحفظ...' : 'حفظ'}
            </button>
          </div>
        </form>
      </div>
    </div>
  );
}

function Field({ label, children }) {
  return (
    <div>
      <label className="block text-sm font-medium text-gray-700 mb-1.5">{label}</label>
      {children}
    </div>
  );
}
