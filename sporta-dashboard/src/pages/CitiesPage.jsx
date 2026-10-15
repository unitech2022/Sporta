import { useState, useEffect, useCallback } from 'react';
import {
  Search, Plus, MapPin, Building2, Edit3, Trash2, Save, X,
  ToggleLeft, ToggleRight, ChevronLeft, Globe,
} from 'lucide-react';
import { adminApi } from '../api/adminApi';
import { useAuth } from '../context/AuthContext';
import PageHeader from '../components/PageHeader';
import StatusBadge from '../components/StatusBadge';
import ConfirmModal from '../components/ConfirmModal';
import { Spinner, Empty } from '../components/TableBits';

const field = 'w-full px-4 py-2.5 border border-gray-200 rounded-xl text-sm focus:outline-none focus:ring-2 focus:ring-[#2AB5CE] bg-gray-50';

// ── Country form modal ──────────────────────────────────────────────────────

function CountryFormModal({ open, initial, onClose, onSaved }) {
  const [form, setForm] = useState({});
  const [saving, setSaving] = useState(false);
  const [err, setErr] = useState(null);

  useEffect(() => {
    if (!open) return;
    setForm(initial
      ? { nameAr: initial.nameAr, nameEn: initial.nameEn, code: initial.code, phoneCode: initial.phoneCode ?? '', currencyCode: initial.currencyCode ?? '', sortOrder: initial.sortOrder ?? 0 }
      : { nameAr: '', nameEn: '', code: '', phoneCode: '', currencyCode: '', sortOrder: 0 });
    setErr(null);
  }, [open, initial]);

  if (!open) return null;
  const isValid = form.nameAr?.trim() && form.nameEn?.trim() && form.code?.trim().length === 2;

  const submit = async () => {
    if (!isValid || saving) return;
    setSaving(true); setErr(null);
    try {
      const body = {
        nameAr: form.nameAr.trim(), nameEn: form.nameEn.trim(),
        code: form.code.trim().toUpperCase(),
        phoneCode: form.phoneCode?.trim() || null,
        currencyCode: form.currencyCode?.trim() || null,
        sortOrder: Number(form.sortOrder) || 0,
        isActive: initial ? initial.isActive : true,
      };
      if (initial) await adminApi.updateCountry(initial.id, body);
      else await adminApi.createCountry(body);
      onSaved();
    } catch (e) {
      setErr(e?.response?.data?.messageAr || 'تعذّر الحفظ'); setSaving(false);
    }
  };

  return (
    <div className="fixed inset-0 bg-black/50 z-50 flex items-center justify-center p-4">
      <div className="bg-white rounded-2xl shadow-2xl w-full max-w-md">
        <div className="flex items-center justify-between px-6 py-4 border-b border-gray-100">
          <h3 className="font-bold text-gray-800 text-lg">{initial ? 'تعديل الدولة' : 'إضافة دولة'}</h3>
          <button onClick={onClose} className="w-8 h-8 flex items-center justify-center rounded-lg hover:bg-gray-100 text-gray-400"><X className="w-5 h-5" /></button>
        </div>
        <div className="p-6 space-y-4">
          <div className="grid grid-cols-2 gap-4">
            <div>
              <label className="block text-sm font-medium text-gray-700 mb-1.5">الاسم (عربي)</label>
              <input value={form.nameAr} onChange={e => setForm(f => ({ ...f, nameAr: e.target.value }))} placeholder="السعودية" className={field} />
            </div>
            <div>
              <label className="block text-sm font-medium text-gray-700 mb-1.5">الاسم (إنجليزي)</label>
              <input value={form.nameEn} onChange={e => setForm(f => ({ ...f, nameEn: e.target.value }))} placeholder="Saudi Arabia" className={field} />
            </div>
          </div>
          <div className="grid grid-cols-3 gap-4">
            <div>
              <label className="block text-sm font-medium text-gray-700 mb-1.5">الرمز</label>
              <input value={form.code} maxLength={2} dir="ltr" onChange={e => setForm(f => ({ ...f, code: e.target.value.toUpperCase() }))} placeholder="SA" className={field} />
            </div>
            <div>
              <label className="block text-sm font-medium text-gray-700 mb-1.5">مفتاح الاتصال</label>
              <input value={form.phoneCode} dir="ltr" onChange={e => setForm(f => ({ ...f, phoneCode: e.target.value }))} placeholder="966" className={field} />
            </div>
            <div>
              <label className="block text-sm font-medium text-gray-700 mb-1.5">العملة</label>
              <input value={form.currencyCode} maxLength={3} dir="ltr" onChange={e => setForm(f => ({ ...f, currencyCode: e.target.value.toUpperCase() }))} placeholder="SAR" className={field} />
            </div>
          </div>
          <div>
            <label className="block text-sm font-medium text-gray-700 mb-1.5">ترتيب العرض</label>
            <input type="number" value={form.sortOrder} onChange={e => setForm(f => ({ ...f, sortOrder: e.target.value }))} className={field} />
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

// ── City form modal ─────────────────────────────────────────────────────────

function CityFormModal({ open, initial, countryId, onClose, onSaved }) {
  const [form, setForm] = useState({});
  const [saving, setSaving] = useState(false);
  const [err, setErr] = useState(null);

  useEffect(() => {
    if (!open) return;
    setForm(initial
      ? { nameAr: initial.nameAr, nameEn: initial.nameEn, region: initial.region ?? '', latitude: initial.latitude ?? '', longitude: initial.longitude ?? '', sortOrder: initial.sortOrder ?? 0 }
      : { nameAr: '', nameEn: '', region: '', latitude: '', longitude: '', sortOrder: 0 });
    setErr(null);
  }, [open, initial]);

  if (!open) return null;
  const isValid = form.nameAr?.trim() && form.nameEn?.trim();

  const submit = async () => {
    if (!isValid || saving) return;
    setSaving(true); setErr(null);
    try {
      const body = {
        countryId: initial ? initial.countryId : countryId,
        nameAr: form.nameAr.trim(), nameEn: form.nameEn.trim(),
        region: form.region?.trim() || null,
        latitude: form.latitude === '' ? null : Number(form.latitude),
        longitude: form.longitude === '' ? null : Number(form.longitude),
        sortOrder: Number(form.sortOrder) || 0,
        isActive: initial ? initial.isActive : true,
      };
      if (initial) await adminApi.updateCity(initial.id, body);
      else await adminApi.createCity(body);
      onSaved();
    } catch (e) {
      setErr(e?.response?.data?.messageAr || 'تعذّر الحفظ'); setSaving(false);
    }
  };

  return (
    <div className="fixed inset-0 bg-black/50 z-50 flex items-center justify-center p-4">
      <div className="bg-white rounded-2xl shadow-2xl w-full max-w-md">
        <div className="flex items-center justify-between px-6 py-4 border-b border-gray-100">
          <h3 className="font-bold text-gray-800 text-lg">{initial ? 'تعديل المدينة' : 'إضافة مدينة'}</h3>
          <button onClick={onClose} className="w-8 h-8 flex items-center justify-center rounded-lg hover:bg-gray-100 text-gray-400"><X className="w-5 h-5" /></button>
        </div>
        <div className="p-6 space-y-4">
          <div className="grid grid-cols-2 gap-4">
            <div>
              <label className="block text-sm font-medium text-gray-700 mb-1.5">الاسم (عربي)</label>
              <input value={form.nameAr} onChange={e => setForm(f => ({ ...f, nameAr: e.target.value }))} placeholder="الرياض" className={field} />
            </div>
            <div>
              <label className="block text-sm font-medium text-gray-700 mb-1.5">الاسم (إنجليزي)</label>
              <input value={form.nameEn} onChange={e => setForm(f => ({ ...f, nameEn: e.target.value }))} placeholder="Riyadh" className={field} />
            </div>
          </div>
          <div>
            <label className="block text-sm font-medium text-gray-700 mb-1.5">المنطقة</label>
            <input value={form.region} onChange={e => setForm(f => ({ ...f, region: e.target.value }))} placeholder="منطقة الرياض" className={field} />
          </div>
          <div className="grid grid-cols-2 gap-4">
            <div>
              <label className="block text-sm font-medium text-gray-700 mb-1.5">خط العرض (Lat)</label>
              <input type="number" step="any" value={form.latitude} onChange={e => setForm(f => ({ ...f, latitude: e.target.value }))} placeholder="24.7136" className={field} />
            </div>
            <div>
              <label className="block text-sm font-medium text-gray-700 mb-1.5">خط الطول (Lng)</label>
              <input type="number" step="any" value={form.longitude} onChange={e => setForm(f => ({ ...f, longitude: e.target.value }))} placeholder="46.6753" className={field} />
            </div>
          </div>
          <div>
            <label className="block text-sm font-medium text-gray-700 mb-1.5">ترتيب العرض</label>
            <input type="number" value={form.sortOrder} onChange={e => setForm(f => ({ ...f, sortOrder: e.target.value }))} className={field} />
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

// ── District form modal ─────────────────────────────────────────────────────

function DistrictFormModal({ open, cityId, initial, onClose, onSaved }) {
  const [form, setForm] = useState({});
  const [saving, setSaving] = useState(false);
  const [err, setErr] = useState(null);

  useEffect(() => {
    if (!open) return;
    setForm(initial
      ? { nameAr: initial.nameAr, nameEn: initial.nameEn, sortOrder: initial.sortOrder ?? 0 }
      : { nameAr: '', nameEn: '', sortOrder: 0 });
    setErr(null);
  }, [open, initial]);

  if (!open) return null;
  const isValid = form.nameAr?.trim() && form.nameEn?.trim();

  const submit = async () => {
    if (!isValid || saving) return;
    setSaving(true); setErr(null);
    try {
      const body = {
        cityId, nameAr: form.nameAr.trim(), nameEn: form.nameEn.trim(),
        sortOrder: Number(form.sortOrder) || 0, isActive: initial ? initial.isActive : true,
      };
      if (initial) await adminApi.updateDistrict(initial.id, body);
      else await adminApi.createDistrict(body);
      onSaved();
    } catch (e) {
      setErr(e?.response?.data?.messageAr || 'تعذّر الحفظ'); setSaving(false);
    }
  };

  return (
    <div className="fixed inset-0 bg-black/50 z-50 flex items-center justify-center p-4">
      <div className="bg-white rounded-2xl shadow-2xl w-full max-w-sm">
        <div className="flex items-center justify-between px-6 py-4 border-b border-gray-100">
          <h3 className="font-bold text-gray-800 text-lg">{initial ? 'تعديل الحي' : 'إضافة حي'}</h3>
          <button onClick={onClose} className="w-8 h-8 flex items-center justify-center rounded-lg hover:bg-gray-100 text-gray-400"><X className="w-5 h-5" /></button>
        </div>
        <div className="p-6 space-y-4">
          <div>
            <label className="block text-sm font-medium text-gray-700 mb-1.5">الاسم (عربي)</label>
            <input value={form.nameAr} onChange={e => setForm(f => ({ ...f, nameAr: e.target.value }))} placeholder="النخيل" className={field} />
          </div>
          <div>
            <label className="block text-sm font-medium text-gray-700 mb-1.5">الاسم (إنجليزي)</label>
            <input value={form.nameEn} onChange={e => setForm(f => ({ ...f, nameEn: e.target.value }))} placeholder="Al Nakheel" className={field} />
          </div>
          <div>
            <label className="block text-sm font-medium text-gray-700 mb-1.5">ترتيب العرض</label>
            <input type="number" value={form.sortOrder} onChange={e => setForm(f => ({ ...f, sortOrder: e.target.value }))} className={field} />
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

// ── Districts panel ─────────────────────────────────────────────────────────

function DistrictsPanel({ city }) {
  const { can } = useAuth();
  const canManage = can('locations.manage');
  const [rows, setRows] = useState([]);
  const [loading, setLoading] = useState(true);
  const [confirm, setConfirm] = useState(null);
  const [form, setForm] = useState(null); // 'new' | district

  const load = useCallback(async () => {
    setLoading(true);
    try {
      const res = await adminApi.getDistricts(city.id);
      setRows(res.data.data ?? res.data ?? []);
    } finally { setLoading(false); }
  }, [city.id]);

  useEffect(() => { load(); }, [load]);

  const toggle = async (d) => {
    await adminApi.updateDistrict(d.id, { cityId: city.id, nameAr: d.nameAr, nameEn: d.nameEn, sortOrder: d.sortOrder, isActive: !d.isActive });
    load();
  };
  const remove = async () => { await adminApi.deleteDistrict(confirm.id); setConfirm(null); load(); };

  return (
    <div className="bg-white rounded-2xl shadow-sm border border-gray-100 overflow-hidden">
      <div className="flex items-center justify-between px-5 py-4 border-b border-gray-100">
        <div>
          <h3 className="font-bold text-gray-800 flex items-center gap-2"><Building2 className="w-4 h-4 text-[#2AB5CE]" /> أحياء {city.nameAr}</h3>
          <p className="text-xs text-gray-400 mt-0.5">{rows.length} حي</p>
        </div>
        {canManage && (
          <button onClick={() => setForm('new')}
            className="flex items-center gap-1.5 px-3 py-2 bg-[#2AB5CE] hover:bg-[#1E9AB0] text-white rounded-xl text-xs font-medium shadow transition">
            <Plus className="w-4 h-4" /> إضافة حي
          </button>
        )}
      </div>

      {loading ? <Spinner />
      : rows.length === 0 ? <Empty icon={Building2} text="لا توجد أحياء لهذه المدينة بعد" />
      : (
        <div className="divide-y divide-gray-50 max-h-[60vh] overflow-y-auto">
          {rows.map(d => (
            <div key={d.id} className="flex items-center justify-between px-5 py-3 hover:bg-gray-50/50 transition">
              <div>
                <p className="font-medium text-gray-800">{d.nameAr}</p>
                <p className="text-xs text-gray-400">{d.nameEn}</p>
              </div>
              <div className="flex items-center gap-2">
                <StatusBadge status={d.isActive ? 'active' : 'inactive'} />
                {canManage && (<>
                <button onClick={() => setForm(d)} className="p-1.5 rounded-lg bg-gray-50 text-gray-500 hover:bg-gray-100" title="تعديل"><Edit3 className="w-4 h-4" /></button>
                <button onClick={() => toggle(d)} className={`p-1.5 rounded-lg ${d.isActive ? 'bg-yellow-50 text-yellow-600' : 'bg-green-50 text-green-700'}`} title={d.isActive ? 'إيقاف' : 'تفعيل'}>
                  {d.isActive ? <ToggleRight className="w-4 h-4" /> : <ToggleLeft className="w-4 h-4" />}
                </button>
                <button onClick={() => setConfirm(d)} className="p-1.5 rounded-lg bg-red-50 text-red-500 hover:bg-red-100" title="حذف"><Trash2 className="w-4 h-4" /></button>
                </>)}
              </div>
            </div>
          ))}
        </div>
      )}

      <ConfirmModal open={!!confirm} title="حذف الحي" message={`هل أنت متأكد من حذف حي "${confirm?.nameAr}"؟`}
        onConfirm={remove} onCancel={() => setConfirm(null)} />
      <DistrictFormModal open={!!form} cityId={city.id} initial={form !== 'new' ? form : null}
        onClose={() => setForm(null)} onSaved={() => { setForm(null); load(); }} />
    </div>
  );
}

// ── Page ────────────────────────────────────────────────────────────────────

export default function CitiesPage() {
  const { can } = useAuth();
  const canManage = can('locations.manage');

  const [countries, setCountries] = useState([]);
  const [activeCountry, setActiveCountry] = useState(null);
  const [countryForm, setCountryForm] = useState(null); // 'new' | country
  const [countryConfirm, setCountryConfirm] = useState(null);

  const [cities, setCities] = useState([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState(null);
  const [search, setSearch] = useState('');
  const [selected, setSelected] = useState(null);
  const [confirm, setConfirm] = useState(null);
  const [form, setForm] = useState(null); // 'new' | city

  const loadCountries = useCallback(async () => {
    try {
      const res = await adminApi.getCountries();
      const list = res.data.data ?? [];
      setCountries(list);
      setActiveCountry(cur => list.find(c => c.id === cur?.id) ?? list[0] ?? null);
    } catch (e) {
      setError(e?.response?.data?.messageAr || 'تعذّر تحميل الدول');
    }
  }, []);

  const load = useCallback(async () => {
    if (!activeCountry) { setCities([]); setLoading(false); return; }
    setLoading(true); setError(null);
    try {
      const res = await adminApi.getCities({ countryId: activeCountry.id });
      const list = res.data.data ?? res.data ?? [];
      setCities(list);
      setSelected((cur) => cur ? list.find(c => c.id === cur.id) ?? null : null);
    } catch (e) {
      setError(e?.response?.data?.messageAr || 'تعذّر تحميل المدن');
    } finally { setLoading(false); }
  }, [activeCountry]);

  useEffect(() => { loadCountries(); }, [loadCountries]);
  useEffect(() => { load(); }, [load]);

  const filtered = cities.filter(c =>
    !search || c.nameAr.includes(search) || c.nameEn.toLowerCase().includes(search.toLowerCase()) || (c.region ?? '').includes(search));

  const toggle = async (c) => {
    await adminApi.updateCity(c.id, { countryId: c.countryId, nameAr: c.nameAr, nameEn: c.nameEn, region: c.region, latitude: c.latitude, longitude: c.longitude, sortOrder: c.sortOrder, isActive: !c.isActive });
    load();
  };
  const remove = async () => { await adminApi.deleteCity(confirm.id); if (selected?.id === confirm.id) setSelected(null); setConfirm(null); load(); };

  const toggleCountry = async (c) => {
    await adminApi.updateCountry(c.id, { nameAr: c.nameAr, nameEn: c.nameEn, code: c.code, phoneCode: c.phoneCode, currencyCode: c.currencyCode, sortOrder: c.sortOrder, isActive: !c.isActive });
    loadCountries();
  };
  const removeCountry = async () => {
    try {
      await adminApi.deleteCountry(countryConfirm.id);
      setCountryConfirm(null);
      loadCountries();
    } catch (e) {
      setError(e?.response?.data?.messageAr || 'تعذّر حذف الدولة');
      setCountryConfirm(null);
    }
  };

  return (
    <div>
      <PageHeader title="الدول والمدن والأحياء"
        subtitle={`${countries.length} دولة · ${cities.length} مدينة`}
        action={canManage && activeCountry && (
          <button onClick={() => setForm('new')}
            className="flex items-center gap-2 px-4 py-2.5 bg-[#2AB5CE] hover:bg-[#1E9AB0] text-white rounded-xl text-sm font-medium shadow transition">
            <Plus className="w-4 h-4" /> إضافة مدينة
          </button>
        )}
      />

      {/* Countries — the city list and every employee scope hang off the active one */}
      <div className="bg-white rounded-2xl shadow-sm border border-gray-100 p-4 mb-6">
        <div className="flex items-center justify-between mb-3">
          <h3 className="font-bold text-gray-800 flex items-center gap-2 text-sm">
            <Globe className="w-4 h-4 text-[#2AB5CE]" /> الدول
          </h3>
          {canManage && (
            <button onClick={() => setCountryForm('new')}
              className="flex items-center gap-1.5 px-3 py-2 bg-[#2AB5CE] hover:bg-[#1E9AB0] text-white rounded-xl text-xs font-medium shadow transition">
              <Plus className="w-4 h-4" /> إضافة دولة
            </button>
          )}
        </div>
        {countries.length === 0
          ? <p className="text-sm text-gray-400 py-4 text-center">لا توجد دول بعد</p>
          : (
            <div className="flex flex-wrap gap-2">
              {countries.map(c => (
                <div key={c.id}
                  className={`flex items-center gap-2 pl-2 pr-3 py-2 rounded-xl border transition ${
                    activeCountry?.id === c.id
                      ? 'border-[#2AB5CE] bg-[#2AB5CE]/10'
                      : 'border-gray-100 bg-gray-50 hover:bg-gray-100'}`}>
                  <button onClick={() => { setActiveCountry(c); setSelected(null); }} className="text-sm">
                    <span className={`font-medium ${activeCountry?.id === c.id ? 'text-[#2AB5CE]' : 'text-gray-700'}`}>
                      {c.nameAr}
                    </span>
                    <span className="text-xs text-gray-400"> · {c.citiesCount} مدينة</span>
                    {!c.isActive && <span className="text-xs text-yellow-600"> · موقوفة</span>}
                  </button>
                  {canManage && (
                    <span className="flex items-center gap-1">
                      <button onClick={() => setCountryForm(c)} className="p-1 rounded-lg text-gray-400 hover:bg-white" title="تعديل"><Edit3 className="w-3.5 h-3.5" /></button>
                      <button onClick={() => toggleCountry(c)} className={`p-1 rounded-lg ${c.isActive ? 'text-yellow-600' : 'text-green-700'} hover:bg-white`} title={c.isActive ? 'إيقاف' : 'تفعيل'}>
                        {c.isActive ? <ToggleRight className="w-3.5 h-3.5" /> : <ToggleLeft className="w-3.5 h-3.5" />}
                      </button>
                      <button onClick={() => setCountryConfirm(c)} className="p-1 rounded-lg text-red-500 hover:bg-white" title="حذف"><Trash2 className="w-3.5 h-3.5" /></button>
                    </span>
                  )}
                </div>
              ))}
            </div>
          )}
      </div>

      <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
        {/* Cities list */}
        <div>
          <div className="relative mb-4">
            <Search className="absolute right-3 top-1/2 -translate-y-1/2 w-4 h-4 text-gray-400" />
            <input value={search} onChange={e => setSearch(e.target.value)} placeholder="بحث باسم المدينة أو المنطقة..."
              className="w-full pr-9 pl-4 py-2.5 border border-gray-200 rounded-xl text-sm focus:outline-none focus:ring-2 focus:ring-[#2AB5CE] bg-white" />
          </div>

          {loading ? <Spinner />
          : error ? <div className="text-center py-16 text-red-500 text-sm">{error}</div>
          : filtered.length === 0 ? <Empty icon={MapPin} text="لا توجد مدن مطابقة" />
          : (
            <div className="bg-white rounded-2xl shadow-sm border border-gray-100 divide-y divide-gray-50 max-h-[70vh] overflow-y-auto">
              {filtered.map(c => (
                <div key={c.id} onClick={() => setSelected(c)}
                  className={`flex items-center justify-between px-5 py-3.5 cursor-pointer transition ${selected?.id === c.id ? 'bg-[#2AB5CE]/10' : 'hover:bg-gray-50/50'}`}>
                  <div className="flex items-center gap-3 min-w-0">
                    <div className="w-9 h-9 rounded-xl bg-[#2AB5CE]/10 flex items-center justify-center shrink-0">
                      <MapPin className="w-4 h-4 text-[#2AB5CE]" />
                    </div>
                    <div className="min-w-0">
                      <p className="font-semibold text-gray-800 truncate">{c.nameAr}</p>
                      <p className="text-xs text-gray-400 truncate">{c.region ?? c.nameEn} · {c.districtsCount} حي</p>
                    </div>
                  </div>
                  <div className="flex items-center gap-1.5 shrink-0">
                    <StatusBadge status={c.isActive ? 'active' : 'inactive'} />
                    {canManage && (<>
                    <button onClick={(e) => { e.stopPropagation(); setForm(c); }} className="p-1.5 rounded-lg bg-gray-50 text-gray-500 hover:bg-gray-100" title="تعديل"><Edit3 className="w-4 h-4" /></button>
                    <button onClick={(e) => { e.stopPropagation(); toggle(c); }} className={`p-1.5 rounded-lg ${c.isActive ? 'bg-yellow-50 text-yellow-600' : 'bg-green-50 text-green-700'}`} title={c.isActive ? 'إيقاف' : 'تفعيل'}>
                      {c.isActive ? <ToggleRight className="w-4 h-4" /> : <ToggleLeft className="w-4 h-4" />}
                    </button>
                    <button onClick={(e) => { e.stopPropagation(); setConfirm(c); }} className="p-1.5 rounded-lg bg-red-50 text-red-500 hover:bg-red-100" title="حذف"><Trash2 className="w-4 h-4" /></button>
                    </>)}
                    <ChevronLeft className="w-4 h-4 text-gray-300" />
                  </div>
                </div>
              ))}
            </div>
          )}
        </div>

        {/* Districts of selected city */}
        <div>
          {selected
            ? <DistrictsPanel key={selected.id} city={selected} />
            : (
              <div className="bg-white rounded-2xl shadow-sm border border-gray-100 h-full flex items-center justify-center min-h-64 text-center p-8">
                <div className="text-gray-400">
                  <Building2 className="w-12 h-12 mx-auto mb-3 opacity-30" />
                  <p className="text-sm">اختر مدينة لعرض وإدارة أحيائها</p>
                </div>
              </div>
            )}
        </div>
      </div>

      <ConfirmModal open={!!confirm} title="حذف المدينة"
        message={`سيتم حذف "${confirm?.nameAr}" وكل أحيائها. المستخدمون المرتبطون بها ستُفرَّغ مدينتهم/حيّهم. متأكد؟`}
        onConfirm={remove} onCancel={() => setConfirm(null)} />
      <CityFormModal open={!!form} initial={form !== 'new' ? form : null}
        countryId={activeCountry?.id}
        onClose={() => setForm(null)} onSaved={() => { setForm(null); load(); loadCountries(); }} />

      <ConfirmModal open={!!countryConfirm} title="حذف الدولة"
        message={`سيتم حذف "${countryConfirm?.nameAr}". لا يمكن حذف دولة تحتوي على مدن أو مُسنَدة لموظفين. متأكد؟`}
        onConfirm={removeCountry} onCancel={() => setCountryConfirm(null)} />
      <CountryFormModal open={!!countryForm} initial={countryForm !== 'new' ? countryForm : null}
        onClose={() => setCountryForm(null)} onSaved={() => { setCountryForm(null); loadCountries(); }} />
    </div>
  );
}
