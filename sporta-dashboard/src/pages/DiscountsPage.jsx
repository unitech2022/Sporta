import { useState, useEffect, useCallback } from 'react';
import {
  Plus, Percent, Edit3, Trash2, Save, X, Users, UserPlus, Search, Infinity as InfinityIcon,
} from 'lucide-react';
import { adminApi } from '../api/adminApi';
import { useAuth } from '../context/AuthContext';
import PageHeader from '../components/PageHeader';
import ConfirmModal from '../components/ConfirmModal';
import { Spinner, Empty } from '../components/TableBits';

const field = 'w-full px-4 py-2.5 border border-gray-200 rounded-xl text-sm focus:outline-none focus:ring-2 focus:ring-[#2AB5CE] bg-gray-50';

// Must match DiscountTarget on the API.
const TARGETS = [
  { key: 'venueCommission', label: 'عمولة الملاعب', hint: 'نسبة سبورتا من كل حجز ملعب' },
  { key: 'coachCommission', label: 'عمولة المدربين', hint: 'نسبة سبورتا من كل جلسة تدريب' },
  { key: 'venueSubscription', label: 'اشتراك الملاعب', hint: 'الاشتراك الشهري/السنوي للملعب' },
  { key: 'playerSubscription', label: 'خدمات اللاعبين المدفوعة', hint: 'اشتراك سبورتا بلس' },
  { key: 'playerBooking', label: 'خصم اللاعب على الحجوزات', hint: 'يخفّض ما يدفعه اللاعب ويُموَّل من عمولة سبورتا فقط — لا يمس مستحقات الملعب، فسقفه الفعلي قيمة العمولة' },
];

const targetLabel = (key) => TARGETS.find(t => t.key === key)?.label ?? key;

const EMPTY = {
  nameAr: '', descriptionAr: '', target: 'venueCommission', percent: 50,
  isGeneral: true, startsAt: '', endsAt: '', maxBeneficiaries: '', maxUses: '',
  grantsLifetime: false, isActive: true,
};

// <input type="datetime-local"> needs "YYYY-MM-DDTHH:mm"; the API returns ISO.
const toLocalInput = (iso) => (iso ? iso.slice(0, 16) : '');

// ── Discount form ───────────────────────────────────────────────────────────

function DiscountFormModal({ open, initial, onClose, onSaved }) {
  const [form, setForm] = useState(EMPTY);
  const [saving, setSaving] = useState(false);
  const [err, setErr] = useState(null);

  useEffect(() => {
    if (!open) return;
    setForm(initial
      ? {
        ...EMPTY,
        nameAr: initial.nameAr, descriptionAr: initial.descriptionAr ?? '',
        target: initial.target, percent: initial.percent,
        isGeneral: initial.isGeneral,
        startsAt: toLocalInput(initial.startsAt), endsAt: toLocalInput(initial.endsAt),
        maxBeneficiaries: initial.maxBeneficiaries ?? '',
        maxUses: initial.maxUses ?? '',
        grantsLifetime: initial.grantsLifetime, isActive: initial.isActive,
      }
      : EMPTY);
    setErr(null);
  }, [open, initial]);

  if (!open) return null;
  const isValid = form.nameAr?.trim() && Number(form.percent) > 0 && Number(form.percent) <= 100;

  const submit = async () => {
    if (!isValid || saving) return;
    setSaving(true); setErr(null);
    try {
      const body = {
        nameAr: form.nameAr.trim(),
        descriptionAr: form.descriptionAr?.trim() || null,
        target: form.target,
        percent: Number(form.percent),
        isGeneral: form.isGeneral,
        startsAt: form.startsAt ? new Date(form.startsAt).toISOString() : null,
        endsAt: form.endsAt ? new Date(form.endsAt).toISOString() : null,
        maxBeneficiaries: form.isGeneral && form.maxBeneficiaries !== ''
          ? Number(form.maxBeneficiaries) : null,
        maxUses: form.maxUses !== '' ? Number(form.maxUses) : null,
        grantsLifetime: form.grantsLifetime,
        isActive: form.isActive,
      };
      if (initial) await adminApi.updateDiscount(initial.id, body);
      else await adminApi.createDiscount(body);
      onSaved();
    } catch (e) {
      setErr(e?.response?.data?.messageAr || 'تعذّر الحفظ'); setSaving(false);
    }
  };

  return (
    <div className="fixed inset-0 bg-black/50 z-50 flex items-center justify-center p-4">
      <div className="bg-white rounded-2xl shadow-2xl w-full max-w-2xl max-h-[92vh] flex flex-col">
        <div className="flex items-center justify-between px-6 py-4 border-b border-gray-100">
          <h3 className="font-bold text-gray-800 text-lg">{initial ? 'تعديل خصم' : 'إضافة خصم'}</h3>
          <button onClick={onClose} className="w-8 h-8 flex items-center justify-center rounded-lg hover:bg-gray-100 text-gray-400"><X className="w-5 h-5" /></button>
        </div>

        <div className="p-6 space-y-5 overflow-y-auto">
          <div>
            <label className="block text-sm font-medium text-gray-700 mb-1.5">اسم الخصم</label>
            <input value={form.nameAr} placeholder="عروض الصيف — خصم ٥٠٪"
              onChange={e => setForm(f => ({ ...f, nameAr: e.target.value }))} className={field} />
          </div>

          <div>
            <label className="block text-sm font-medium text-gray-700 mb-1.5">الوصف (اختياري)</label>
            <input value={form.descriptionAr} placeholder="أول ١٠ ملاعب تحصل على التخفيض مدى الحياة"
              onChange={e => setForm(f => ({ ...f, descriptionAr: e.target.value }))} className={field} />
          </div>

          <div className="grid grid-cols-2 gap-4">
            <div>
              <label className="block text-sm font-medium text-gray-700 mb-1.5">الرسم المستهدف</label>
              <select value={form.target} onChange={e => setForm(f => ({ ...f, target: e.target.value }))} className={field}>
                {TARGETS.map(t => <option key={t.key} value={t.key}>{t.label}</option>)}
              </select>
              <p className="text-xs text-gray-400 mt-1">
                {TARGETS.find(t => t.key === form.target)?.hint}
              </p>
            </div>
            <div>
              <label className="block text-sm font-medium text-gray-700 mb-1.5">نسبة الخصم من الرسم (%)</label>
              <input type="number" min="1" max="100" value={form.percent}
                onChange={e => setForm(f => ({ ...f, percent: e.target.value }))} className={field} />
              <p className="text-xs text-gray-400 mt-1">٥٠٪ على عمولة ٥٪ تجعلها ٢٫٥٪</p>
            </div>
          </div>

          {/* General vs targeted */}
          <div className="bg-[#2AB5CE]/5 border border-[#2AB5CE]/20 rounded-2xl p-4 space-y-3">
            <p className="font-semibold text-gray-800 text-sm">نطاق الخصم</p>
            <div className="grid grid-cols-2 gap-3">
              <button type="button" onClick={() => setForm(f => ({ ...f, isGeneral: true }))}
                className={`px-4 py-3 rounded-xl border text-sm text-right transition ${
                  form.isGeneral ? 'border-[#2AB5CE] bg-white shadow-sm' : 'border-gray-200 bg-white/50'}`}>
                <span className="font-medium text-gray-800">عام</span>
                <span className="block text-xs text-gray-400 mt-0.5">يسري على كل من يخضع للرسم</span>
              </button>
              <button type="button" onClick={() => setForm(f => ({ ...f, isGeneral: false }))}
                className={`px-4 py-3 rounded-xl border text-sm text-right transition ${
                  !form.isGeneral ? 'border-[#2AB5CE] bg-white shadow-sm' : 'border-gray-200 bg-white/50'}`}>
                <span className="font-medium text-gray-800">مخصص</span>
                <span className="block text-xs text-gray-400 mt-0.5">لمستفيدين تحددهم بنفسك</span>
              </button>
            </div>

            {form.isGeneral && (
              <div>
                <label className="block text-sm font-medium text-gray-700 mb-1.5">
                  سقف المستفيدين (اتركه فارغاً لبلا سقف)
                </label>
                <input type="number" min="1" value={form.maxBeneficiaries} placeholder="١٠"
                  onChange={e => setForm(f => ({ ...f, maxBeneficiaries: e.target.value }))} className={field} />
                <p className="text-xs text-gray-400 mt-1">
                  «أول ١٠ ملاعب» — يُضَم المستفيد تلقائياً عند أول رسم يخضع له حتى يمتلئ السقف.
                </p>
              </div>
            )}
          </div>

          <div className="grid grid-cols-2 gap-4">
            <div>
              <label className="block text-sm font-medium text-gray-700 mb-1.5">يبدأ (اختياري)</label>
              <input type="datetime-local" value={form.startsAt}
                onChange={e => setForm(f => ({ ...f, startsAt: e.target.value }))} className={field} />
            </div>
            <div>
              <label className="block text-sm font-medium text-gray-700 mb-1.5">ينتهي (اختياري)</label>
              <input type="datetime-local" value={form.endsAt}
                onChange={e => setForm(f => ({ ...f, endsAt: e.target.value }))} className={field} />
            </div>
          </div>

          <div>
            <label className="block text-sm font-medium text-gray-700 mb-1.5">
              سقف عدد الحجوزات (اتركه فارغاً لبلا سقف)
            </label>
            <input type="number" min="1" value={form.maxUses} placeholder="٢٠"
              onChange={e => setForm(f => ({ ...f, maxUses: e.target.value }))} className={field} />
            <p className="text-xs text-gray-400 mt-1">
              يسري الخصم على هذا العدد من الحجوزات/الجلسات المحصَّلة فعلاً ثم يتوقف تلقائياً — مثال: خصم لملعب على أول ٢٠ حجزاً.
            </p>
          </div>

          <label className="flex items-start gap-3 cursor-pointer">
            <input type="checkbox" checked={form.grantsLifetime} className="w-4 h-4 mt-0.5 rounded accent-[#2AB5CE]"
              onChange={e => setForm(f => ({ ...f, grantsLifetime: e.target.checked }))} />
            <span className="text-sm text-gray-700">
              يبقى مع المستفيد مدى الحياة
              <span className="block text-xs text-gray-400">من لحق بالعرض يحتفظ بالخصم حتى بعد انتهائه</span>
            </span>
          </label>

          <label className="flex items-center gap-3 cursor-pointer">
            <input type="checkbox" checked={form.isActive} className="w-4 h-4 rounded accent-[#2AB5CE]"
              onChange={e => setForm(f => ({ ...f, isActive: e.target.checked }))} />
            <span className="text-sm text-gray-700">مفعّل</span>
          </label>

          {err && <p className="text-sm text-red-500">{err}</p>}
        </div>

        <div className="flex gap-3 px-6 py-4 border-t border-gray-100">
          <button onClick={onClose} className="flex-1 py-2.5 border border-gray-200 rounded-xl text-gray-600 font-medium hover:bg-gray-50 transition text-sm">إلغاء</button>
          <button onClick={submit} disabled={!isValid || saving}
            className="flex-1 py-2.5 bg-[#2AB5CE] hover:bg-[#1E9AB0] disabled:bg-gray-200 disabled:text-gray-400 text-white font-medium rounded-xl transition text-sm flex items-center justify-center gap-2">
            <Save className="w-4 h-4" /> {saving ? 'جارٍ الحفظ...' : 'حفظ'}
          </button>
        </div>
      </div>
    </div>
  );
}

// ── Beneficiaries panel ─────────────────────────────────────────────────────

function BeneficiariesModal({ discount, canManage, onClose }) {
  const [rows, setRows] = useState([]);
  const [loading, setLoading] = useState(true);
  const [query, setQuery] = useState('');
  const [options, setOptions] = useState([]);
  const [searching, setSearching] = useState(false);
  const [err, setErr] = useState(null);

  const load = useCallback(async () => {
    setLoading(true);
    try {
      const res = await adminApi.getDiscountBeneficiaries(discount.id);
      setRows(res.data.data ?? []);
    } finally { setLoading(false); }
  }, [discount.id]);

  useEffect(() => { load(); }, [load]);

  // Search candidates by name/phone, filtered to the roles this fee applies to.
  useEffect(() => {
    if (!canManage) return;
    let cancelled = false;
    setSearching(true);
    const timer = setTimeout(async () => {
      try {
        const res = await adminApi.searchDiscountUsers({
          search: query || undefined, target: discount.target,
        });
        if (!cancelled) setOptions(res.data.data ?? []);
      } catch {
        if (!cancelled) setOptions([]);
      } finally {
        if (!cancelled) setSearching(false);
      }
    }, 300); // debounce so typing doesn't hammer the API
    return () => { cancelled = true; clearTimeout(timer); };
  }, [query, discount.target, canManage]);

  const add = async (userId) => {
    setErr(null);
    try {
      await adminApi.addDiscountBeneficiary(discount.id, userId);
      setQuery('');
      load();
    } catch (e) {
      setErr(e?.response?.data?.messageAr || 'تعذّرت الإضافة');
    }
  };

  const remove = async (uid) => {
    await adminApi.removeDiscountBeneficiary(discount.id, uid);
    load();
  };

  return (
    <div className="fixed inset-0 bg-black/50 z-50 flex items-center justify-center p-4">
      <div className="bg-white rounded-2xl shadow-2xl w-full max-w-lg max-h-[85vh] flex flex-col">
        <div className="flex items-center justify-between px-6 py-4 border-b border-gray-100">
          <div>
            <h3 className="font-bold text-gray-800">مستفيدو «{discount.nameAr}»</h3>
            <p className="text-xs text-gray-400 mt-0.5">
              {rows.length} مستفيد{discount.maxBeneficiaries ? ` من ${discount.maxBeneficiaries}` : ''}
            </p>
          </div>
          <button onClick={onClose} className="w-8 h-8 flex items-center justify-center rounded-lg hover:bg-gray-100 text-gray-400"><X className="w-5 h-5" /></button>
        </div>

        {canManage && (
          <div className="px-6 py-3 border-b border-gray-50">
            <div className="relative">
              <Search className="absolute right-3 top-1/2 -translate-y-1/2 w-4 h-4 text-gray-400" />
              <input value={query} placeholder="ابحث بالاسم أو الجوال لإضافة مستفيد..."
                onChange={e => setQuery(e.target.value)}
                className={`${field} pr-9`} />
            </div>

            {/* Candidates already on the list are shown as added, not offered again. */}
            <div className="mt-2 max-h-44 overflow-y-auto rounded-xl border border-gray-100 divide-y divide-gray-50">
              {searching && options.length === 0 && (
                <p className="px-4 py-3 text-xs text-gray-400">جارٍ البحث...</p>
              )}
              {!searching && options.length === 0 && (
                <p className="px-4 py-3 text-xs text-gray-400">لا نتائج مطابقة</p>
              )}
              {options.map(o => {
                const already = rows.some(r => r.userId === o.id);
                return (
                  <div key={o.id} className="flex items-center justify-between px-4 py-2.5">
                    <div className="min-w-0">
                      <p className="text-sm text-gray-800 truncate">
                        {o.name}
                        <span className="text-[11px] text-gray-400 mr-2">{o.roleLabel}</span>
                      </p>
                      <p className="text-xs text-gray-400" dir="ltr">{o.phoneNumber}</p>
                    </div>
                    <button onClick={() => add(o.id)} disabled={already}
                      className={`px-3 py-1.5 rounded-lg text-xs font-medium flex items-center gap-1 shrink-0 ${
                        already
                          ? 'bg-gray-100 text-gray-400 cursor-default'
                          : 'bg-[#2AB5CE] hover:bg-[#1E9AB0] text-white'}`}>
                      <UserPlus className="w-3.5 h-3.5" /> {already ? 'مُضاف' : 'إضافة'}
                    </button>
                  </div>
                );
              })}
            </div>
          </div>
        )}
        {err && <p className="px-6 pt-2 text-sm text-red-500">{err}</p>}

        {loading ? <Spinner />
        : rows.length === 0 ? <Empty icon={Users} text="لا مستفيدين بعد" />
        : (
          <div className="divide-y divide-gray-50 overflow-y-auto">
            {rows.map(b => (
              <div key={b.userId} className="flex items-center justify-between px-6 py-3">
                <div>
                  <p className="text-sm font-medium text-gray-800">{b.name}</p>
                  <p className="text-xs text-gray-400" dir="ltr">{b.phoneNumber}</p>
                </div>
                <div className="flex items-center gap-2">
                  <span className={`text-[11px] px-2 py-0.5 rounded-md ${
                    b.autoEnrolled ? 'bg-blue-50 text-blue-600' : 'bg-gray-100 text-gray-500'}`}>
                    {b.autoEnrolled ? 'انضمام تلقائي' : 'إضافة يدوية'}
                  </span>
                  {canManage && (
                    <button onClick={() => remove(b.userId)} className="p-1.5 rounded-lg bg-red-50 text-red-500 hover:bg-red-100" title="إزالة">
                      <Trash2 className="w-4 h-4" />
                    </button>
                  )}
                </div>
              </div>
            ))}
          </div>
        )}
      </div>
    </div>
  );
}

// ── Page ────────────────────────────────────────────────────────────────────

export default function DiscountsPage() {
  const { can } = useAuth();
  const canManage = can('discounts.manage');

  const [rows, setRows] = useState([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState(null);
  const [form, setForm] = useState(null);          // 'new' | discount
  const [beneficiaries, setBeneficiaries] = useState(null);
  const [confirm, setConfirm] = useState(null);

  const load = useCallback(async () => {
    setLoading(true); setError(null);
    try {
      const res = await adminApi.getDiscounts();
      setRows(res.data.data ?? []);
    } catch (e) {
      setError(e?.response?.data?.messageAr || 'تعذّر تحميل الخصومات');
    } finally { setLoading(false); }
  }, []);

  useEffect(() => { load(); }, [load]);

  const remove = async () => {
    await adminApi.deleteDiscount(confirm.id);
    setConfirm(null);
    load();
  };

  return (
    <div>
      <PageHeader title="الخصومات والعروض" subtitle={`${rows.length} خصم`}
        action={canManage && (
          <button onClick={() => setForm('new')}
            className="flex items-center gap-2 px-4 py-2.5 bg-[#2AB5CE] hover:bg-[#1E9AB0] text-white rounded-xl text-sm font-medium shadow transition">
            <Plus className="w-4 h-4" /> إضافة خصم
          </button>
        )}
      />

      {loading ? <Spinner />
      : error ? <div className="text-center py-16 text-red-500 text-sm">{error}</div>
      : rows.length === 0 ? <Empty icon={Percent} text="لا توجد خصومات بعد" />
      : (
        <div className="grid grid-cols-1 xl:grid-cols-2 gap-4">
          {rows.map(d => (
            <div key={d.id} className="bg-white rounded-2xl shadow-sm border border-gray-100 p-5">
              <div className="flex items-start justify-between gap-3">
                <div className="flex items-start gap-3 min-w-0">
                  <div className="w-11 h-11 rounded-xl bg-[#2AB5CE]/10 flex items-center justify-center text-[#2AB5CE] font-bold shrink-0">
                    {Number(d.percent)}%
                  </div>
                  <div className="min-w-0">
                    <p className="font-semibold text-gray-800 truncate">{d.nameAr}</p>
                    <p className="text-xs text-gray-400 truncate">{d.descriptionAr || targetLabel(d.target)}</p>
                  </div>
                </div>
                <div className="flex items-center gap-1.5 shrink-0">
                  <span className={`text-[11px] px-2 py-1 rounded-lg ${
                    d.isRunning ? 'bg-green-50 text-green-700' : 'bg-gray-100 text-gray-500'}`}>
                    {d.isRunning ? 'ساري' : 'متوقف'}
                  </span>
                  {canManage && (
                    <>
                      <button onClick={() => setForm(d)} className="p-1.5 rounded-lg bg-gray-50 text-gray-500 hover:bg-gray-100" title="تعديل"><Edit3 className="w-4 h-4" /></button>
                      <button onClick={() => setConfirm(d)} className="p-1.5 rounded-lg bg-red-50 text-red-500 hover:bg-red-100" title="حذف"><Trash2 className="w-4 h-4" /></button>
                    </>
                  )}
                </div>
              </div>

              <div className="mt-4 flex flex-wrap items-center gap-2 text-xs">
                <span className="px-2.5 py-1 rounded-lg bg-gray-50 text-gray-600">{targetLabel(d.target)}</span>
                <span className="px-2.5 py-1 rounded-lg bg-gray-50 text-gray-600">
                  {d.isGeneral ? 'عام' : 'مخصص'}
                </span>
                {d.grantsLifetime && (
                  <span className="px-2.5 py-1 rounded-lg bg-purple-50 text-purple-600 flex items-center gap-1">
                    <InfinityIcon className="w-3.5 h-3.5" /> مدى الحياة
                  </span>
                )}
                {d.maxBeneficiaries != null && (
                  <span className="px-2.5 py-1 rounded-lg bg-amber-50 text-amber-700">
                    متبقٍ {d.remainingSlots} من {d.maxBeneficiaries}
                  </span>
                )}
                {d.maxUses != null && (
                  <span className={`px-2.5 py-1 rounded-lg ${
                    d.remainingUses > 0
                      ? 'bg-sky-50 text-sky-700'
                      : 'bg-red-50 text-red-600'}`}>
                    {d.remainingUses > 0
                      ? `متبقٍ ${d.remainingUses} من ${d.maxUses} حجزاً`
                      : 'استُنفدت الحجوزات'}
                  </span>
                )}
              </div>

              <button onClick={() => setBeneficiaries(d)}
                className="mt-3 w-full flex items-center justify-center gap-2 py-2 rounded-xl border border-gray-100 text-sm text-gray-600 hover:bg-gray-50 transition">
                <Users className="w-4 h-4" /> المستفيدون ({d.beneficiariesCount})
              </button>
            </div>
          ))}
        </div>
      )}

      <ConfirmModal open={!!confirm} title="حذف الخصم"
        message={`سيتم حذف "${confirm?.nameAr}" ويفقد كل مستفيديه هذا الخصم — بما فيهم من مُنح مدى الحياة. متأكد؟`}
        onConfirm={remove} onCancel={() => setConfirm(null)} />

      <DiscountFormModal open={!!form} initial={form !== 'new' ? form : null}
        onClose={() => setForm(null)} onSaved={() => { setForm(null); load(); }} />

      {beneficiaries && (
        <BeneficiariesModal discount={beneficiaries} canManage={canManage}
          onClose={() => { setBeneficiaries(null); load(); }} />
      )}
    </div>
  );
}
