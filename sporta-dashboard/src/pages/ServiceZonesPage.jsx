import { useEffect, useMemo, useRef, useState } from 'react';
import {
  Plus, Map as MapIcon, Edit3, Trash2, ToggleLeft, ToggleRight, Save, X, MessageSquare,
} from 'lucide-react';
import { adminApi } from '../api/adminApi';
import { useApi } from '../hooks/useApi';
import { useAuth } from '../context/AuthContext';
import PageHeader from '../components/PageHeader';
import ConfirmModal from '../components/ConfirmModal';
import StatusBadge from '../components/StatusBadge';
import { Spinner, Empty } from '../components/TableBits';
import ZoneMapEditor from '../components/serviceZones/ZoneMapEditor';

const PALETTE = ['#2AB5CE', '#16a34a', '#f59e0b', '#dc2626', '#7c3aed', '#2563eb', '#db2777', '#4d7c0f'];

const EMPTY_FORM = { nameAr: '', nameEn: '', polygon: [], color: PALETTE[0], isActive: true };

const inputCls =
  'w-full px-4 py-2.5 border border-gray-200 rounded-xl text-sm focus:outline-none focus:ring-2 focus:ring-[#2AB5CE] bg-gray-50 disabled:opacity-60';

const apiError = (e, fallback) => e?.response?.data?.messageAr || e?.response?.data?.message || fallback;

/** رسالة «خارج نطاق الخدمة» — تظهر في التطبيق لمن يقع خارج المناطق المفعّلة. */
function OutsideMessageCard({ canManage }) {
  const { data, loading } = useApi(() => adminApi.getServiceZoneMessage(), []);
  const [form, setForm] = useState({ valueAr: '', valueEn: '' });
  const [saving, setSaving] = useState(false);
  const [status, setStatus] = useState(null); // {ok, text}

  useEffect(() => {
    if (data) setForm({ valueAr: data.valueAr, valueEn: data.valueEn });
  }, [data]);

  const save = async (e) => {
    e.preventDefault();
    setSaving(true);
    setStatus(null);
    try {
      const res = await adminApi.saveServiceZoneMessage(form);
      setForm(res.data.data);
      setStatus({ ok: true, text: 'تم حفظ الرسالة' });
    } catch (err) {
      setStatus({ ok: false, text: apiError(err, 'تعذّر حفظ الرسالة') });
    } finally {
      setSaving(false);
    }
  };

  return (
    <div className="bg-white rounded-2xl shadow-sm border border-gray-100 p-5 mt-6">
      <h3 className="font-bold text-gray-800 flex items-center gap-2">
        <MessageSquare className="w-4 h-4 text-[#2AB5CE]" /> رسالة «خارج نطاق الخدمة»
      </h3>
      <p className="text-xs text-gray-500 mt-1 mb-4">
        تظهر للمستخدم في التطبيق عندما يكون موقعه خارج كل المناطق المفعّلة.
      </p>
      {loading ? (
        <Spinner />
      ) : (
        <form onSubmit={save} className="grid gap-3 md:grid-cols-2">
          <div>
            <label className="block text-sm font-medium text-gray-700 mb-1.5">النص بالعربية</label>
            <input className={inputCls} value={form.valueAr} disabled={!canManage || saving}
              onChange={(e) => setForm((f) => ({ ...f, valueAr: e.target.value }))} />
          </div>
          <div>
            <label className="block text-sm font-medium text-gray-700 mb-1.5">النص بالإنجليزية</label>
            <input className={inputCls} dir="ltr" value={form.valueEn} disabled={!canManage || saving}
              onChange={(e) => setForm((f) => ({ ...f, valueEn: e.target.value }))} />
          </div>
          <div className="md:col-span-2 flex items-center gap-3">
            {canManage && (
              <button type="submit" disabled={saving}
                className="flex items-center gap-2 px-4 py-2.5 bg-[#2AB5CE] hover:bg-[#1E9AB0] disabled:bg-gray-200 text-white rounded-xl text-sm font-medium transition">
                <Save className="w-4 h-4" /> {saving ? 'جارٍ الحفظ...' : 'حفظ الرسالة'}
              </button>
            )}
            {status && (
              <span className={`text-sm ${status.ok ? 'text-green-600' : 'text-red-500'}`}>{status.text}</span>
            )}
          </div>
        </form>
      )}
    </div>
  );
}

export default function ServiceZonesPage() {
  const { can } = useAuth();
  const canManage = can('serviceZones.manage');

  const { data, loading, error, refetch } = useApi(() => adminApi.getServiceZones(), []);
  const zones = useMemo(() => data ?? [], [data]);
  const activeCount = zones.filter((z) => z.isActive).length;

  const [editorOpen, setEditorOpen] = useState(false);
  const [editingId, setEditingId] = useState(null);
  const [form, setForm] = useState(EMPTY_FORM);
  const [formError, setFormError] = useState(null);
  const [saving, setSaving] = useState(false);
  const editorRef = useRef(null);

  const [testPoint, setTestPoint] = useState(null);
  const [testResult, setTestResult] = useState(null);
  const [confirm, setConfirm] = useState(null); // {type: 'delete'|'toggle', item}

  const openEditor = (zone) => {
    setEditingId(zone?.id ?? null);
    setForm(
      zone
        ? {
            nameAr: zone.nameAr || '',
            nameEn: zone.nameEn || '',
            polygon: (zone.polygon || []).map((p) => ({ lat: p.lat, lng: p.lng })),
            color: zone.color || PALETTE[0],
            isActive: !!zone.isActive,
          }
        : { ...EMPTY_FORM, color: PALETTE[zones.length % PALETTE.length] }
    );
    setFormError(null);
    setTestPoint(null);
    setTestResult(null);
    setEditorOpen(true);
    setTimeout(() => editorRef.current?.scrollIntoView({ behavior: 'smooth', block: 'start' }), 50);
  };

  const closeEditor = () => {
    setEditorOpen(false);
    setEditingId(null);
    setForm(EMPTY_FORM);
    setFormError(null);
  };

  const setField = (field, value) => setForm((prev) => ({ ...prev, [field]: value }));

  const handleSave = async (e) => {
    e.preventDefault();
    if (!form.nameAr.trim()) return setFormError('اسم المنطقة مطلوب');
    if (form.polygon.length < 3) return setFormError('ارسم المنطقة على الخريطة (3 نقاط على الأقل)');

    const payload = {
      nameAr: form.nameAr.trim(),
      nameEn: form.nameEn.trim(),
      polygon: form.polygon,
      color: form.color,
      isActive: form.isActive,
    };
    setSaving(true);
    setFormError(null);
    try {
      if (editingId) await adminApi.updateServiceZone(editingId, payload);
      else await adminApi.createServiceZone(payload);
      closeEditor();
      refetch();
    } catch (err) {
      setFormError(apiError(err, 'تعذّر حفظ المنطقة'));
    } finally {
      setSaving(false);
    }
  };

  const handleConfirm = async () => {
    const { type, item } = confirm;
    setConfirm(null);
    try {
      if (type === 'delete') {
        await adminApi.deleteServiceZone(item.id);
        if (editingId === item.id) closeEditor();
      } else {
        await adminApi.updateServiceZone(item.id, {
          nameAr: item.nameAr,
          nameEn: item.nameEn,
          polygon: item.polygon,
          color: item.color,
          isActive: !item.isActive,
        });
      }
      refetch();
    } catch (err) {
      alert(apiError(err, 'تعذّر تنفيذ العملية'));
    }
  };

  // اختبار نقطة عبر الخادم (المناطق المحفوظة والمفعّلة فقط).
  const handleTestPoint = async (p) => {
    setTestPoint(p);
    setTestResult(null);
    try {
      const res = await adminApi.checkServiceZone(p.lat, p.lng);
      setTestResult(res.data.data);
    } catch {
      setTestResult({ error: true });
    }
  };

  const otherZones = useMemo(() => zones.filter((z) => z.id !== editingId), [zones, editingId]);

  return (
    <div>
      <PageHeader
        title="مناطق الخدمة"
        subtitle="حدّد أين يعمل التطبيق جغرافياً — المستخدم خارج المناطق المفعّلة يرى رسالة «خارج نطاق الخدمة»."
        action={
          canManage && (
            <button onClick={() => openEditor(null)}
              className="flex items-center gap-2 px-4 py-2.5 bg-[#2AB5CE] hover:bg-[#1E9AB0] text-white rounded-xl text-sm font-medium shadow transition">
              <Plus className="w-4 h-4" /> إضافة منطقة
            </button>
          )
        }
      />

      <div className={`rounded-xl border px-4 py-3 text-sm mb-5 ${
        activeCount === 0
          ? 'bg-amber-50 border-amber-200 text-amber-800'
          : 'bg-emerald-50 border-emerald-200 text-emerald-800'
      }`}>
        {activeCount === 0
          ? 'لا توجد منطقة مفعّلة — التطبيق يعمل حالياً في كل مكان.'
          : `التطبيق يعمل داخل ${activeCount} منطقة مفعّلة فقط، وخارجها تظهر رسالة «خارج نطاق الخدمة».`}
      </div>

      {editorOpen && (
        <div ref={editorRef} className="bg-white rounded-2xl shadow-sm border border-gray-100 mb-6 overflow-hidden">
          <div className="flex items-center justify-between px-5 py-4 border-b border-gray-100 bg-gray-50">
            <h3 className="font-bold text-gray-800 flex items-center gap-2">
              <MapIcon className="w-4 h-4 text-[#2AB5CE]" />
              {editingId ? `تعديل منطقة: ${form.nameAr}` : 'منطقة خدمة جديدة'}
            </h3>
            <button onClick={closeEditor} className="w-8 h-8 flex items-center justify-center rounded-lg hover:bg-gray-100 text-gray-400">
              <X className="w-5 h-5" />
            </button>
          </div>

          <form onSubmit={handleSave} className="grid gap-5 p-5 xl:grid-cols-[340px_1fr]">
            <div className="space-y-4">
              <div>
                <label className="block text-sm font-medium text-gray-700 mb-1.5">اسم المنطقة (عربي)</label>
                <input className={inputCls} value={form.nameAr} placeholder="مثال: مدينة الرياض"
                  onChange={(e) => setField('nameAr', e.target.value)} />
              </div>
              <div>
                <label className="block text-sm font-medium text-gray-700 mb-1.5">الاسم (إنجليزي)</label>
                <input className={inputCls} dir="ltr" value={form.nameEn} placeholder="Riyadh"
                  onChange={(e) => setField('nameEn', e.target.value)} />
              </div>
              <div>
                <label className="block text-sm font-medium text-gray-700 mb-1.5">لون المنطقة على الخريطة</label>
                <div className="flex flex-wrap gap-2">
                  {PALETTE.map((c) => (
                    <button key={c} type="button" aria-label={c} onClick={() => setField('color', c)}
                      className={`w-7 h-7 rounded-full border-2 transition ${form.color === c ? 'border-gray-800 scale-110' : 'border-white shadow'}`}
                      style={{ background: c }} />
                  ))}
                </div>
              </div>
              <label className="flex items-center gap-2 text-sm text-gray-700 cursor-pointer">
                <input type="checkbox" checked={form.isActive} onChange={(e) => setField('isActive', e.target.checked)}
                  className="w-4 h-4 accent-[#2AB5CE]" />
                مفعّلة
              </label>

              {testResult && (
                <div className={`rounded-xl border px-3 py-2.5 text-sm ${
                  testResult.error
                    ? 'bg-red-50 border-red-200 text-red-700'
                    : testResult.insideServiceArea
                      ? 'bg-emerald-50 border-emerald-200 text-emerald-800'
                      : 'bg-amber-50 border-amber-200 text-amber-800'
                }`}>
                  {testResult.error ? 'تعذّر فحص النقطة' : (
                    <>
                      <strong>{testResult.insideServiceArea ? '✅ داخل نطاق الخدمة' : '⛔ خارج نطاق الخدمة'}</strong>
                      {testResult.zoneNameAr && <div>المنطقة: {testResult.zoneNameAr}</div>}
                      {!testResult.hasZones && <div>لا توجد مناطق مفعّلة، فكل المواقع داخل النطاق.</div>}
                    </>
                  )}
                </div>
              )}

              {formError && <p className="text-sm text-red-500">{formError}</p>}

              <div className="flex gap-3">
                <button type="button" onClick={closeEditor} disabled={saving}
                  className="flex-1 py-2.5 border border-gray-200 rounded-xl text-gray-600 font-medium hover:bg-gray-50 transition text-sm">
                  إلغاء
                </button>
                <button type="submit" disabled={saving || !canManage}
                  className="flex-1 py-2.5 bg-[#2AB5CE] hover:bg-[#1E9AB0] disabled:bg-gray-200 disabled:text-gray-400 text-white font-medium rounded-xl transition text-sm flex items-center justify-center gap-2">
                  <Save className="w-4 h-4" />
                  {saving ? 'جارٍ الحفظ...' : editingId ? 'حفظ التعديلات' : 'إنشاء المنطقة'}
                </button>
              </div>
            </div>

            <ZoneMapEditor
              key={editingId ?? 'new'}
              points={form.polygon}
              onChange={(pts) => setField('polygon', pts)}
              color={form.color}
              otherZones={otherZones}
              testPoint={testPoint}
              onTestPoint={handleTestPoint}
              height={520}
            />
          </form>
        </div>
      )}

      {loading ? (
        <Spinner />
      ) : error ? (
        <div className="text-center py-16 text-red-500 text-sm">{error}</div>
      ) : zones.length === 0 ? (
        <Empty icon={MapIcon} text="لا توجد مناطق خدمة — التطبيق يعمل في كل مكان" />
      ) : (
        <div className="grid gap-4 md:grid-cols-2 xl:grid-cols-3">
          {zones.map((zone) => (
            <div key={zone.id}
              className={`bg-white rounded-2xl shadow-sm border border-gray-100 overflow-hidden ${zone.isActive ? '' : 'opacity-70'}`}>
              <div className="h-1.5" style={{ background: zone.color || PALETTE[0] }} />
              <div className="p-4">
                <div className="flex items-start justify-between gap-2">
                  <div>
                    <p className="font-semibold text-gray-800">{zone.nameAr}</p>
                    {zone.nameEn && zone.nameEn !== zone.nameAr && (
                      <p className="text-xs text-gray-400">{zone.nameEn}</p>
                    )}
                  </div>
                  <StatusBadge status={zone.isActive ? 'active' : 'inactive'} />
                </div>
                <p className="text-xs text-gray-500 mt-2">{zone.polygon?.length ?? 0} نقطة</p>
                <div className="flex flex-wrap gap-2 mt-4">
                  <button onClick={() => openEditor(zone)}
                    className="flex items-center gap-1 px-3 py-1.5 rounded-lg bg-gray-50 text-gray-600 hover:bg-gray-100 transition text-xs font-medium">
                    <Edit3 className="w-3.5 h-3.5" /> {canManage ? 'تعديل' : 'عرض'}
                  </button>
                  {canManage && (
                    <>
                      <button onClick={() => setConfirm({ type: 'toggle', item: zone })}
                        className={`flex items-center gap-1 px-3 py-1.5 rounded-lg text-xs font-medium transition ${zone.isActive ? 'bg-yellow-50 text-yellow-600 hover:bg-yellow-100' : 'bg-green-50 text-green-700 hover:bg-green-100'}`}>
                        {zone.isActive ? <><ToggleRight className="w-3.5 h-3.5" />إيقاف</> : <><ToggleLeft className="w-3.5 h-3.5" />تفعيل</>}
                      </button>
                      <button onClick={() => setConfirm({ type: 'delete', item: zone })}
                        className="flex items-center gap-1 px-3 py-1.5 rounded-lg bg-red-50 text-red-500 hover:bg-red-100 transition text-xs font-medium">
                        <Trash2 className="w-3.5 h-3.5" /> حذف
                      </button>
                    </>
                  )}
                </div>
              </div>
            </div>
          ))}
        </div>
      )}

      <OutsideMessageCard canManage={canManage} />

      <ConfirmModal
        open={!!confirm}
        title={confirm?.type === 'delete' ? 'حذف منطقة الخدمة' : confirm?.item?.isActive ? 'إيقاف المنطقة' : 'تفعيل المنطقة'}
        message={
          confirm?.type === 'delete'
            ? `هل أنت متأكد من حذف "${confirm?.item?.nameAr}"؟ سيتوقف أثرها فوراً على التطبيق.`
            : confirm?.item?.isActive
              ? `سيتم إيقاف "${confirm?.item?.nameAr}" فلا تُحتسب ضمن نطاق الخدمة.`
              : `سيتم تفعيل "${confirm?.item?.nameAr}" فيصبح التطبيق مقيّداً بالمناطق المفعّلة.`
        }
        danger={confirm?.type === 'delete'}
        onConfirm={handleConfirm}
        onCancel={() => setConfirm(null)}
      />
    </div>
  );
}
