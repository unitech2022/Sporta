import { useState, useEffect, useCallback, useMemo } from 'react';
import {
  Search, Plus, ShieldCheck, Edit3, Save, X, ToggleLeft, ToggleRight,
  Globe, MapPin, Mail, Phone as PhoneIcon, Trash2, UserPlus, UserCheck, Check,
} from 'lucide-react';
import { adminApi } from '../api/adminApi';
import { useAuth } from '../context/AuthContext';
import PageHeader from '../components/PageHeader';
import StatusBadge from '../components/StatusBadge';
import ConfirmModal from '../components/ConfirmModal';
import { Spinner, Empty } from '../components/TableBits';

const field = 'w-full px-4 py-2.5 border border-gray-200 rounded-xl text-sm focus:outline-none focus:ring-2 focus:ring-[#2AB5CE] bg-gray-50';

// Sentinel for the "every city in the country" option — <select> values are strings.
const ALL_CITIES = '';

// Every field starts defined so the inputs are controlled from the first render.
const EMPTY_FORM = {
  // userId مضبوط حين يُرقّى مستخدم قائم — يُرسل للخادم فيربط الموظف بحسابه
  // بدل إنشاء حساب جديد برقم جديد.
  userId: null,
  firstName: '', lastName: '', phone: '', email: '', jobTitle: '', password: '',
  countryId: '', cityId: ALL_CITIES, isActive: true,
};

// ── منتقي مستخدم قائم ───────────────────────────────────────────────────────

/// بحث في مستخدمي التطبيق واختيار واحد لترقيته موظفاً — يملأ الاسم والجوال.
function ExistingUserPicker({ onPick, picked, onClear }) {
  const [term, setTerm] = useState('');
  const [results, setResults] = useState([]);
  const [loading, setLoading] = useState(false);

  // بحث مؤجّل: كل ضغطة مفتاح لا تستحق نداءً للخادم.
  useEffect(() => {
    const q = term.trim();
    if (q.length < 2) { setResults([]); return; }
    let cancelled = false;
    setLoading(true);
    const id = setTimeout(() => {
      adminApi.getUsers({ search: q, page: 1, pageSize: 10 })
        .then(res => {
          if (cancelled) return;
          const items = res.data.data?.items ?? [];
          // الموظفون والأدمن ليسوا مرشّحين للترقية.
          setResults(items.filter(u => !(u.roles ?? []).some(r => r === 'staff' || r === 'admin')));
        })
        .catch(() => { if (!cancelled) setResults([]); })
        .finally(() => { if (!cancelled) setLoading(false); });
    }, 350);
    return () => { cancelled = true; clearTimeout(id); };
  }, [term]);

  if (picked) {
    return (
      <div className="flex items-center justify-between gap-3 bg-emerald-50 border border-emerald-200 rounded-xl px-4 py-3">
        <span className="flex items-center gap-2 text-sm text-emerald-800 min-w-0">
          <UserCheck className="w-4 h-4 shrink-0" />
          <span className="font-semibold truncate">{picked.fullName}</span>
          <span className="text-emerald-600 shrink-0" dir="ltr">{picked.phone}</span>
        </span>
        <button onClick={onClear} className="text-xs text-emerald-700 hover:underline shrink-0">
          تغيير
        </button>
      </div>
    );
  }

  return (
    <div>
      <div className="relative">
        <Search className="absolute right-3 top-1/2 -translate-y-1/2 w-4 h-4 text-gray-400" />
        <input value={term} onChange={e => setTerm(e.target.value)}
          placeholder="ابحث بالاسم أو رقم الجوال..."
          className={`${field} pr-9`} />
      </div>

      {term.trim().length >= 2 && (
        <div className="mt-2 border border-gray-100 rounded-xl divide-y divide-gray-50 max-h-56 overflow-y-auto">
          {loading ? (
            <p className="px-4 py-3 text-sm text-gray-400">جاري البحث...</p>
          ) : results.length === 0 ? (
            <p className="px-4 py-3 text-sm text-gray-400">لا يوجد مستخدم مطابق</p>
          ) : results.map(u => (
            <button key={u.id} onClick={() => onPick(u)}
              className="w-full flex items-center justify-between gap-3 px-4 py-3 text-right hover:bg-gray-50 transition">
              <span className="min-w-0">
                <span className="block text-sm font-medium text-gray-800 truncate">{u.fullName}</span>
                <span className="block text-xs text-gray-400" dir="ltr">{u.phone}</span>
              </span>
              <Check className="w-4 h-4 text-[#2AB5CE] shrink-0" />
            </button>
          ))}
        </div>
      )}
    </div>
  );
}

// ── Employee form modal ─────────────────────────────────────────────────────

function StaffFormModal({ open, initial, countries, catalog, onClose, onSaved }) {
  const [form, setForm] = useState(EMPTY_FORM);
  const [cities, setCities] = useState([]);
  const [granted, setGranted] = useState(new Set());
  const [saving, setSaving] = useState(false);
  const [err, setErr] = useState(null);

  /// 'new' حساب جديد | 'existing' ترقية مستخدم من التطبيق.
  const [source, setSource] = useState('new');
  const [picked, setPicked] = useState(null);

  const isEdit = !!initial;
  const isExisting = !isEdit && source === 'existing';

  useEffect(() => {
    if (!open) return;
    setForm(initial
      ? {
        ...EMPTY_FORM,
        firstName: initial.firstName, lastName: initial.lastName,
        phone: initial.phoneNumber, email: initial.email,
        jobTitle: initial.jobTitle ?? '', password: '',
        countryId: String(initial.countryId),
        cityId: initial.cityId == null ? ALL_CITIES : String(initial.cityId),
        isActive: initial.isActive,
      }
      : { ...EMPTY_FORM, countryId: String(countries[0]?.id ?? '') });
    setGranted(new Set(initial?.permissions ?? []));
    setSource('new');
    setPicked(null);
    setErr(null);
  }, [open, initial, countries]);

  /// اختيار مستخدم قائم يملأ الاسم والجوال ويثبّت معرّفه على النموذج.
  const pickUser = (u) => {
    const [first, ...rest] = (u.fullName ?? '').trim().split(/\s+/);
    setPicked(u);
    setForm(f => ({
      ...f,
      userId: u.id,
      firstName: u.firstName || first || '',
      lastName: u.lastName || rest.join(' '),
      phone: u.phone ?? '',
      email: u.email ?? '',
    }));
  };

  const clearPickedUser = () => {
    setPicked(null);
    setForm(f => ({ ...f, userId: null, firstName: '', lastName: '', phone: '', email: '' }));
  };

  // Cities follow the selected country; "كل المدن" stays valid either way.
  useEffect(() => {
    if (!open || !form.countryId) { setCities([]); return; }
    let cancelled = false;
    adminApi.getCities({ countryId: Number(form.countryId) })
      .then(res => { if (!cancelled) setCities(res.data.data ?? []); })
      .catch(() => { if (!cancelled) setCities([]); });
    return () => { cancelled = true; };
  }, [open, form.countryId]);

  if (!open) return null;

  const toggleOne = (key) => setGranted(prev => {
    const next = new Set(prev);
    if (next.has(key)) next.delete(key);
    else next.add(key);
    return next;
  });

  const toggleGroup = (group) => setGranted(prev => {
    const next = new Set(prev);
    const keys = group.permissions.map(p => p.key);
    const allOn = keys.every(k => next.has(k));
    keys.forEach(k => (allOn ? next.delete(k) : next.add(k)));
    return next;
  });

  const isValid =
    form.firstName?.trim() && form.lastName?.trim() && form.email?.trim() &&
    form.countryId &&
    (isEdit
      ? true
      // الترقية تشترط اختيار مستخدم فعلاً، لا مجرد كتابة اسم.
      : (form.phone?.trim() && form.password?.length >= 6 &&
         (!isExisting || !!form.userId)));

  const submit = async () => {
    if (!isValid || saving) return;
    setSaving(true); setErr(null);
    try {
      const scope = {
        countryId: Number(form.countryId),
        cityId: form.cityId === ALL_CITIES ? null : Number(form.cityId),
        permissions: [...granted],
      };
      if (isEdit) {
        await adminApi.updateStaff(initial.userId, {
          firstName: form.firstName.trim(), lastName: form.lastName.trim(),
          email: form.email.trim(), jobTitle: form.jobTitle?.trim() || null,
          password: form.password ? form.password : null,
          isActive: form.isActive, ...scope,
        });
      } else {
        await adminApi.createStaff({
          userId: form.userId,
          firstName: form.firstName.trim(), lastName: form.lastName.trim(),
          phone: form.phone.trim(), email: form.email.trim(),
          password: form.password, jobTitle: form.jobTitle?.trim() || null,
          ...scope,
        });
      }
      onSaved();
    } catch (e) {
      setErr(e?.response?.data?.messageAr || 'تعذّر الحفظ');
      setSaving(false);
    }
  };

  return (
    <div className="fixed inset-0 bg-black/50 z-50 flex items-center justify-center p-4">
      <div className="bg-white rounded-2xl shadow-2xl w-full max-w-3xl max-h-[92vh] flex flex-col">
        <div className="flex items-center justify-between px-6 py-4 border-b border-gray-100">
          <h3 className="font-bold text-gray-800 text-lg">{isEdit ? 'تعديل موظف' : 'إضافة موظف'}</h3>
          <button onClick={onClose} className="w-8 h-8 flex items-center justify-center rounded-lg hover:bg-gray-100 text-gray-400"><X className="w-5 h-5" /></button>
        </div>

        <div className="p-6 space-y-5 overflow-y-auto">
          {/* مصدر الحساب: جديد أم مستخدم قائم يُرقّى — لا يظهر في التعديل */}
          {!isEdit && (
            <div className="space-y-3">
              <div className="grid grid-cols-2 gap-3">
                {[
                  { key: 'new', label: 'حساب جديد', icon: UserPlus },
                  { key: 'existing', label: 'مستخدم موجود', icon: UserCheck },
                ].map(({ key, label, icon: Icon }) => (
                  <button key={key}
                    onClick={() => {
                      setSource(key);
                      clearPickedUser();
                    }}
                    className={`flex items-center justify-center gap-2 py-2.5 rounded-xl border text-sm font-medium transition ${
                      source === key
                        ? 'bg-[#2AB5CE] border-[#2AB5CE] text-white'
                        : 'bg-white border-gray-200 text-gray-600 hover:bg-gray-50'
                    }`}>
                    <Icon className="w-4 h-4" /> {label}
                  </button>
                ))}
              </div>

              {isExisting && (
                <ExistingUserPicker
                  picked={picked}
                  onPick={pickUser}
                  onClear={clearPickedUser}
                />
              )}
            </div>
          )}

          {/* Identity */}
          <div className="grid grid-cols-2 gap-4">
            <div>
              <label className="block text-sm font-medium text-gray-700 mb-1.5">الاسم الأول</label>
              <input value={form.firstName} onChange={e => setForm(f => ({ ...f, firstName: e.target.value }))} className={field} />
            </div>
            <div>
              <label className="block text-sm font-medium text-gray-700 mb-1.5">الاسم الأخير</label>
              <input value={form.lastName} onChange={e => setForm(f => ({ ...f, lastName: e.target.value }))} className={field} />
            </div>
          </div>

          <div className="grid grid-cols-2 gap-4">
            <div>
              <label className="block text-sm font-medium text-gray-700 mb-1.5">رقم الجوال</label>
              <input value={form.phone} disabled={isEdit || isExisting} dir="ltr" placeholder="05xxxxxxxx"
                onChange={e => setForm(f => ({ ...f, phone: e.target.value }))}
                className={`${field} ${isEdit || isExisting ? 'opacity-60 cursor-not-allowed' : ''}`} />
              {isEdit && <p className="text-xs text-gray-400 mt-1">رقم الجوال لا يُعدَّل بعد الإنشاء</p>}
              {isExisting && <p className="text-xs text-gray-400 mt-1">رقم جوال المستخدم المختار</p>}
            </div>
            <div>
              <label className="block text-sm font-medium text-gray-700 mb-1.5">البريد الإلكتروني</label>
              <input value={form.email} dir="ltr" onChange={e => setForm(f => ({ ...f, email: e.target.value }))} className={field} />
            </div>
          </div>

          <div className="grid grid-cols-2 gap-4">
            <div>
              <label className="block text-sm font-medium text-gray-700 mb-1.5">المسمى الوظيفي</label>
              <input value={form.jobTitle} placeholder="مشرف مدينة" onChange={e => setForm(f => ({ ...f, jobTitle: e.target.value }))} className={field} />
            </div>
            <div>
              <label className="block text-sm font-medium text-gray-700 mb-1.5">
                {isEdit ? 'كلمة مرور جديدة (اختياري)' : 'كلمة المرور'}
              </label>
              <input type="password" value={form.password} dir="ltr"
                placeholder={isEdit
                  ? 'اتركها فارغة لعدم التغيير'
                  : (isExisting ? 'كلمة مرور دخول اللوحة — 6 أحرف على الأقل' : '6 أحرف على الأقل')}
                onChange={e => setForm(f => ({ ...f, password: e.target.value }))} className={field} />
            </div>
          </div>

          {/* Geographic scope */}
          <div className="bg-[#2AB5CE]/5 border border-[#2AB5CE]/20 rounded-2xl p-4 space-y-4">
            <p className="font-semibold text-gray-800 text-sm flex items-center gap-2">
              <Globe className="w-4 h-4 text-[#2AB5CE]" /> نطاق العمل
            </p>
            <div className="grid grid-cols-2 gap-4">
              <div>
                <label className="block text-sm font-medium text-gray-700 mb-1.5">الدولة</label>
                <select value={form.countryId}
                  onChange={e => setForm(f => ({ ...f, countryId: e.target.value, cityId: ALL_CITIES }))}
                  className={field}>
                  {countries.map(c => <option key={c.id} value={String(c.id)}>{c.nameAr}</option>)}
                </select>
              </div>
              <div>
                <label className="block text-sm font-medium text-gray-700 mb-1.5">المدينة</label>
                <select value={form.cityId} onChange={e => setForm(f => ({ ...f, cityId: e.target.value }))} className={field}>
                  <option value={ALL_CITIES}>كل المدن</option>
                  {cities.map(c => <option key={c.id} value={String(c.id)}>{c.nameAr}</option>)}
                </select>
              </div>
            </div>
            <p className="text-xs text-gray-500">
              الموظف يرى ويدير فقط بيانات نطاقه: الأندية والملاعب والحجوزات والمستخدمين والمعاملات المالية داخل المدينة المحددة — أو كل مدن الدولة عند اختيار «كل المدن».
            </p>
          </div>

          {/* Permissions */}
          <div>
            <div className="flex items-center justify-between mb-2">
              <p className="font-semibold text-gray-800 text-sm flex items-center gap-2">
                <ShieldCheck className="w-4 h-4 text-[#2AB5CE]" /> الصلاحيات
              </p>
              <span className="text-xs text-gray-400">{granted.size} صلاحية مختارة</span>
            </div>
            <div className="border border-gray-100 rounded-2xl divide-y divide-gray-50 max-h-72 overflow-y-auto">
              {catalog.map(group => {
                const keys = group.permissions.map(p => p.key);
                const allOn = keys.every(k => granted.has(k));
                return (
                  <div key={group.key} className="p-4">
                    <div className="flex items-center justify-between mb-2">
                      <p className="font-medium text-gray-800 text-sm">{group.label}</p>
                      <button type="button" onClick={() => toggleGroup(group)}
                        className="text-xs text-[#2AB5CE] hover:underline">
                        {allOn ? 'إلغاء الكل' : 'تحديد الكل'}
                      </button>
                    </div>
                    <div className="grid grid-cols-1 sm:grid-cols-2 gap-2">
                      {group.permissions.map(p => (
                        <label key={p.key} className="flex items-center gap-2 text-sm text-gray-600 cursor-pointer">
                          <input type="checkbox" checked={granted.has(p.key)} onChange={() => toggleOne(p.key)}
                            className="w-4 h-4 rounded accent-[#2AB5CE]" />
                          <span>{p.label}</span>
                        </label>
                      ))}
                    </div>
                  </div>
                );
              })}
            </div>
          </div>

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

// ── Page ────────────────────────────────────────────────────────────────────

export default function StaffPage() {
  const { can, user } = useAuth();
  const canManage = can('staff.manage');
  const canDelete = can('staff.delete');

  const [rows, setRows] = useState([]);
  const [countries, setCountries] = useState([]);
  const [catalog, setCatalog] = useState([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState(null);
  const [search, setSearch] = useState('');
  const [form, setForm] = useState(null); // 'new' | staff
  const [confirm, setConfirm] = useState(null);       // إيقاف/تفعيل
  const [deleting, setDeleting] = useState(null);     // حذف نهائي
  const [error2, setError2] = useState(null);

  const load = useCallback(async () => {
    setLoading(true); setError(null);
    try {
      const [staffRes, countryRes, catalogRes] = await Promise.all([
        adminApi.getStaff({ search: search || undefined, pageSize: 100 }),
        adminApi.getCountries(),
        adminApi.getPermissionCatalog(),
      ]);
      setRows(staffRes.data.data?.items ?? []);
      setCountries((countryRes.data.data ?? []).filter(c => c.isActive));
      setCatalog(catalogRes.data.data ?? []);
    } catch (e) {
      setError(e?.response?.data?.messageAr || 'تعذّر تحميل الموظفين');
    } finally { setLoading(false); }
  }, [search]);

  useEffect(() => { load(); }, [load]);

  const labelByKey = useMemo(() => {
    const map = {};
    catalog.forEach(g => g.permissions.forEach(p => { map[p.key] = p.label; }));
    return map;
  }, [catalog]);

  const toggleActive = async () => {
    await adminApi.setStaffActive(confirm.userId, !confirm.isActive);
    setConfirm(null);
    load();
  };

  const removeStaff = async () => {
    setError2(null);
    try {
      await adminApi.deleteStaff(deleting.userId);
      setDeleting(null);
      load();
    } catch (e) {
      // الخادم يرفض الحذف حين يكون للحساب نشاط مرتبط ويشرح السبب.
      setError2(e?.response?.data?.messageAr || 'تعذّر حذف الموظف');
      setDeleting(null);
    }
  };

  return (
    <div>
      <PageHeader title="الموظفون والصلاحيات" subtitle={`${rows.length} موظف`}
        action={canManage && countries.length > 0 && (
          <button onClick={() => setForm('new')}
            className="flex items-center gap-2 px-4 py-2.5 bg-[#2AB5CE] hover:bg-[#1E9AB0] text-white rounded-xl text-sm font-medium shadow transition">
            <Plus className="w-4 h-4" /> إضافة موظف
          </button>
        )}
      />

      <div className="relative mb-4 max-w-md">
        <Search className="absolute right-3 top-1/2 -translate-y-1/2 w-4 h-4 text-gray-400" />
        <input value={search} onChange={e => setSearch(e.target.value)} placeholder="بحث بالاسم أو الجوال أو البريد..."
          className="w-full pr-9 pl-4 py-2.5 border border-gray-200 rounded-xl text-sm focus:outline-none focus:ring-2 focus:ring-[#2AB5CE] bg-white" />
      </div>

      {loading ? <Spinner />
      : error ? <div className="text-center py-16 text-red-500 text-sm">{error}</div>
      : rows.length === 0 ? <Empty icon={ShieldCheck} text="لا يوجد موظفون بعد" />
      : (
        <div className="grid grid-cols-1 xl:grid-cols-2 gap-4">
          {rows.map(s => (
            <div key={s.userId} className="bg-white rounded-2xl shadow-sm border border-gray-100 p-5">
              <div className="flex items-start justify-between gap-3">
                <div className="flex items-center gap-3 min-w-0">
                  <div className="w-11 h-11 rounded-xl bg-[#2AB5CE]/10 flex items-center justify-center text-[#2AB5CE] font-bold shrink-0">
                    {s.firstName?.[0] ?? 'م'}
                  </div>
                  <div className="min-w-0">
                    <p className="font-semibold text-gray-800 truncate">{s.firstName} {s.lastName}</p>
                    <p className="text-xs text-gray-400 truncate">{s.jobTitle || 'موظف'}</p>
                  </div>
                </div>
                <div className="flex items-center gap-1.5 shrink-0">
                  <StatusBadge status={s.isActive ? 'active' : 'inactive'} />
                  {canManage && (
                    <>
                      <button onClick={() => setForm(s)} className="p-1.5 rounded-lg bg-gray-50 text-gray-500 hover:bg-gray-100" title="تعديل">
                        <Edit3 className="w-4 h-4" />
                      </button>
                      {s.userId !== user?.id && (
                        <button onClick={() => setConfirm(s)}
                          className={`p-1.5 rounded-lg ${s.isActive ? 'bg-yellow-50 text-yellow-600' : 'bg-green-50 text-green-700'}`}
                          title={s.isActive ? 'إيقاف' : 'تفعيل'}>
                          {s.isActive ? <ToggleRight className="w-4 h-4" /> : <ToggleLeft className="w-4 h-4" />}
                        </button>
                      )}
                    </>
                  )}
                  {/* الحذف بصلاحية مستقلة — لا يُمنح مع التعديل تلقائياً */}
                  {canDelete && s.userId !== user?.id && (
                    <button onClick={() => setDeleting(s)}
                      className="p-1.5 rounded-lg bg-red-50 text-red-500 hover:bg-red-100"
                      title="حذف نهائي">
                      <Trash2 className="w-4 h-4" />
                    </button>
                  )}
                </div>
              </div>

              <div className="mt-4 grid grid-cols-2 gap-2 text-xs text-gray-500">
                <span className="flex items-center gap-1.5 truncate" dir="ltr">
                  <PhoneIcon className="w-3.5 h-3.5 shrink-0" /> {s.phoneNumber}
                </span>
                <span className="flex items-center gap-1.5 truncate" dir="ltr">
                  <Mail className="w-3.5 h-3.5 shrink-0" /> {s.email}
                </span>
              </div>

              <div className="mt-3 flex items-center gap-2 text-xs">
                <span className="inline-flex items-center gap-1 px-2.5 py-1 rounded-lg bg-gray-50 text-gray-600">
                  <Globe className="w-3.5 h-3.5" /> {s.countryNameAr}
                </span>
                <span className="inline-flex items-center gap-1 px-2.5 py-1 rounded-lg bg-gray-50 text-gray-600">
                  <MapPin className="w-3.5 h-3.5" /> {s.cityNameAr ?? 'كل المدن'}
                </span>
              </div>

              <div className="mt-3 pt-3 border-t border-gray-50">
                <p className="text-xs text-gray-400 mb-1.5">{s.permissions.length} صلاحية</p>
                <div className="flex flex-wrap gap-1.5">
                  {s.permissions.slice(0, 6).map(p => (
                    <span key={p} className="px-2 py-0.5 rounded-md bg-[#2AB5CE]/10 text-[#2AB5CE] text-[11px]">
                      {labelByKey[p] ?? p}
                    </span>
                  ))}
                  {s.permissions.length > 6 && (
                    <span className="px-2 py-0.5 rounded-md bg-gray-100 text-gray-500 text-[11px]">
                      +{s.permissions.length - 6}
                    </span>
                  )}
                </div>
              </div>
            </div>
          ))}
        </div>
      )}

      {error2 && (
        <div className="fixed bottom-6 right-6 z-50 max-w-md bg-white border border-red-200 rounded-2xl shadow-lg p-4">
          <p className="text-sm text-red-600">{error2}</p>
          <button onClick={() => setError2(null)}
            className="mt-2 text-xs text-gray-500 hover:text-gray-700">إغلاق</button>
        </div>
      )}

      <ConfirmModal open={!!deleting} title="حذف الموظف نهائياً"
        message={`سيُحذف حساب "${deleting?.firstName} ${deleting?.lastName}" وصلاحياته ونطاقه نهائياً — لا يمكن التراجع. للإيقاف المؤقت استخدم زر الإيقاف بدلاً منه.`}
        onConfirm={removeStaff} onCancel={() => setDeleting(null)} />

      <ConfirmModal open={!!confirm}
        title={confirm?.isActive ? 'إيقاف الموظف' : 'تفعيل الموظف'}
        message={confirm?.isActive
          ? `سيتم إيقاف حساب "${confirm?.firstName} ${confirm?.lastName}" ولن يستطيع الدخول للوحة. متأكد؟`
          : `سيتم تفعيل حساب "${confirm?.firstName} ${confirm?.lastName}". متأكد؟`}
        onConfirm={toggleActive} onCancel={() => setConfirm(null)} />

      <StaffFormModal open={!!form} initial={form !== 'new' ? form : null}
        countries={countries} catalog={catalog}
        onClose={() => setForm(null)} onSaved={() => { setForm(null); load(); }} />
    </div>
  );
}
