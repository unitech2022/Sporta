import { useState, useEffect, useCallback } from 'react';
import { Plus, Edit3, Trash2, Save, X, Settings as SettingsIcon, EyeOff, Percent } from 'lucide-react';
import { settingsApi } from '../api/settingsApi';
import { adminApi } from '../api/adminApi';
import PageHeader from '../components/PageHeader';
import ConfirmModal from '../components/ConfirmModal';

const TYPE_LABELS = { text: 'نص', switch: 'مفتاح تشغيل', number: 'رقم' };

const inputCls =
  'w-full px-4 py-2.5 border border-gray-200 rounded-xl text-sm focus:outline-none focus:ring-2 focus:ring-[#2AB5CE] bg-gray-50';

export default function SettingsPage() {
  const [items, setItems] = useState([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState(null);
  const [modal, setModal] = useState(null); // 'new' | setting
  const [confirm, setConfirm] = useState(null);

  const load = useCallback(async () => {
    setLoading(true);
    setError(null);
    try {
      const res = await settingsApi.getAll();
      setItems(res.data.data);
    } catch (err) {
      setError(err?.response?.data?.messageAr || 'تعذّر تحميل الإعدادات');
    } finally {
      setLoading(false);
    }
  }, []);

  useEffect(() => {
    load();
  }, [load]);

  const save = async (form) => {
    if (modal === 'new') await settingsApi.create(form);
    else await settingsApi.update(modal.id, form);
    setModal(null);
    load();
  };

  const handleConfirm = async () => {
    await settingsApi.delete(confirm.id);
    setConfirm(null);
    load();
  };

  return (
    <div>
      <PageHeader
        title="الإعدادات"
        subtitle="إدارة إعدادات النظام العامة (الصيانة، النسخ، السياسات، الدعم...)"
        action={
          <button
            onClick={() => setModal('new')}
            className="flex items-center gap-2 px-4 py-2.5 bg-[#2AB5CE] hover:bg-[#1E9AB0] text-white rounded-xl text-sm font-medium shadow transition"
          >
            <Plus className="w-4 h-4" /> إعداد جديد
          </button>
        }
      />

      <DefaultCommissionCard />

      {loading ? (
        <div className="flex justify-center py-20">
          <div className="w-10 h-10 border-4 border-green-200 border-t-[#2AB5CE] rounded-full animate-spin" />
        </div>
      ) : error ? (
        <div className="text-center py-16 text-red-500 text-sm">{error}</div>
      ) : items.length === 0 ? (
        <div className="text-center py-20 text-gray-400">
          <SettingsIcon className="w-12 h-12 mx-auto mb-3 opacity-30" />
          <p>لا توجد إعدادات بعد</p>
        </div>
      ) : (
        <SettingsTable
          items={items}
          onEdit={setModal}
          onDelete={(item) => setConfirm(item)}
        />
      )}

      {modal && (
        <SettingFormModal
          initial={modal === 'new' ? null : modal}
          onSave={save}
          onClose={() => setModal(null)}
        />
      )}
      <ConfirmModal
        open={!!confirm}
        title="حذف الإعداد"
        message={`هل أنت متأكد من حذف "${confirm?.nameAr}"؟`}
        onConfirm={handleConfirm}
        onCancel={() => setConfirm(null)}
      />
    </div>
  );
}

function DefaultCommissionCard() {
  const [percent, setPercent] = useState('');
  const [loaded, setLoaded] = useState(false);
  const [saving, setSaving] = useState(false);
  const [savedMsg, setSavedMsg] = useState(false);
  const [err, setErr] = useState(null);

  useEffect(() => {
    adminApi.getDefaultCommission()
      .then((res) => setPercent(String(res.data.data.percent)))
      .catch(() => {})
      .finally(() => setLoaded(true));
  }, []);

  const save = async () => {
    const value = Number(percent);
    if (Number.isNaN(value) || value < 0 || value > 100) {
      setErr('أدخل نسبة صحيحة بين 0 و 100');
      return;
    }
    setSaving(true);
    setErr(null);
    setSavedMsg(false);
    try {
      await adminApi.setDefaultCommission(value);
      setSavedMsg(true);
    } catch (e) {
      setErr(e?.response?.data?.messageAr || 'تعذّر الحفظ');
    } finally {
      setSaving(false);
    }
  };

  return (
    <div className="bg-white rounded-2xl shadow-sm border border-gray-100 p-5 mb-5">
      <div className="flex items-start gap-3 mb-4">
        <div className="w-10 h-10 rounded-xl bg-[#2AB5CE]/10 flex items-center justify-center shrink-0">
          <Percent className="w-5 h-5 text-[#2AB5CE]" />
        </div>
        <div>
          <h3 className="font-bold text-gray-800">نسبة سبورتا الافتراضية</h3>
          <p className="text-xs text-gray-400 mt-0.5">
            تُضاف على سعر الحجز والمباريات، وتُطبَّق تلقائيًا على الملاعب الجديدة عند إنشائها.
            يمكن تعديلها لكل ملعب من صفحة الملعب.
          </p>
        </div>
      </div>
      <div className="flex items-center gap-3">
        <div className="relative w-40">
          <input
            type="number" min={0} max={100} step="0.5"
            value={percent}
            onChange={(e) => { setPercent(e.target.value); setSavedMsg(false); }}
            disabled={!loaded}
            className="w-full pr-9 pl-4 py-2.5 border border-gray-200 rounded-xl text-sm focus:outline-none focus:ring-2 focus:ring-[#2AB5CE] bg-gray-50"
            placeholder="10"
          />
          <span className="absolute right-3 top-1/2 -translate-y-1/2 text-gray-400 text-sm">%</span>
        </div>
        <button
          onClick={save} disabled={saving || !loaded}
          className="flex items-center gap-2 px-4 py-2.5 bg-[#2AB5CE] hover:bg-[#1E9AB0] disabled:bg-gray-200 disabled:text-gray-400 text-white rounded-xl text-sm font-medium transition"
        >
          <Save className="w-4 h-4" /> {saving ? 'جارٍ الحفظ...' : 'حفظ'}
        </button>
        {savedMsg && <span className="text-sm text-green-600">تم الحفظ ✓</span>}
        {err && <span className="text-sm text-red-500">{err}</span>}
      </div>
    </div>
  );
}

function SettingsTable({ items, onEdit, onDelete }) {
  return (
    <div className="bg-white rounded-2xl shadow-sm border border-gray-100 overflow-hidden">
      <div className="overflow-x-auto">
        <table className="w-full text-sm">
          <thead>
            <tr className="border-b border-gray-100 bg-gray-50">
              <th className="text-right px-5 py-3.5 font-semibold text-gray-600">المفتاح</th>
              <th className="text-right px-4 py-3.5 font-semibold text-gray-600">الاسم</th>
              <th className="text-right px-4 py-3.5 font-semibold text-gray-600">النوع</th>
              <th className="text-right px-4 py-3.5 font-semibold text-gray-600">القيمة</th>
              <th className="text-right px-4 py-3.5 font-semibold text-gray-600">الإجراءات</th>
            </tr>
          </thead>
          <tbody className="divide-y divide-gray-50">
            {items.map((s) => (
              <tr key={s.id} className="hover:bg-gray-50/50 transition">
                <td className="px-5 py-4">
                  <code className="text-xs text-gray-500 bg-gray-100 px-2 py-1 rounded-lg">{s.key}</code>
                </td>
                <td className="px-4 py-4">
                  <p className="font-semibold text-gray-800">{s.nameAr}</p>
                  <p className="text-xs text-gray-400">{s.nameEn}</p>
                </td>
                <td className="px-4 py-4">
                  <span className="inline-block px-2.5 py-0.5 rounded-full text-xs font-medium bg-blue-50 text-blue-600">
                    {TYPE_LABELS[s.type] ?? s.type}
                  </span>
                </td>
                <td className="px-4 py-4 max-w-xs">
                  {s.isSensitive ? (
                    <span className="flex items-center gap-1 text-xs text-gray-400">
                      <EyeOff className="w-3.5 h-3.5" /> مخفي
                    </span>
                  ) : (
                    <p className="text-gray-600 truncate" title={s.valueAr}>{s.valueAr || '—'}</p>
                  )}
                </td>
                <td className="px-4 py-4">
                  <RowActions onEdit={() => onEdit(s)} onDelete={() => onDelete(s)} />
                </td>
              </tr>
            ))}
          </tbody>
        </table>
      </div>
    </div>
  );
}

function SettingFormModal({ initial, onSave, onClose }) {
  const [form, setForm] = useState(
    initial
      ? {
          key: initial.key,
          nameAr: initial.nameAr,
          nameEn: initial.nameEn,
          type: initial.type,
          valueAr: initial.valueAr,
          valueEn: initial.valueEn,
          isSensitive: initial.isSensitive,
        }
      : {
          key: '', nameAr: '', nameEn: '', type: 'text',
          valueAr: '', valueEn: '', isSensitive: false,
        },
  );
  const [saving, setSaving] = useState(false);
  const [err, setErr] = useState(null);
  const valid = form.key.trim() && form.nameAr.trim() && form.nameEn.trim();

  const submit = async () => {
    if (!valid || saving) return;
    setSaving(true);
    setErr(null);
    try {
      await onSave(form);
    } catch (e) {
      setErr(e?.response?.data?.messageAr || 'تعذّر الحفظ');
      setSaving(false);
    }
  };

  return (
    <ModalShell title={initial ? 'تعديل الإعداد' : 'إعداد جديد'} onClose={onClose}>
      <div className="p-6 space-y-4 max-h-[70vh] overflow-y-auto">
        <Field label="المفتاح (Key)">
          <input className={inputCls} dir="ltr" value={form.key} disabled={!!initial}
            onChange={(e) => setForm((f) => ({ ...f, key: e.target.value }))}
            placeholder="مثال: support_phone" />
        </Field>
        <div className="grid grid-cols-2 gap-4">
          <Field label="الاسم (عربي)">
            <input className={inputCls} value={form.nameAr}
              onChange={(e) => setForm((f) => ({ ...f, nameAr: e.target.value }))} />
          </Field>
          <Field label="الاسم (إنجليزي)">
            <input className={inputCls} value={form.nameEn}
              onChange={(e) => setForm((f) => ({ ...f, nameEn: e.target.value }))} />
          </Field>
        </div>
        <Field label="النوع">
          <select className={inputCls} value={form.type}
            onChange={(e) => setForm((f) => ({ ...f, type: e.target.value }))}>
            <option value="text">نص</option>
            <option value="number">رقم</option>
            <option value="switch">مفتاح تشغيل (true/false)</option>
          </select>
        </Field>

        {form.type === 'switch' ? (
          <label className="flex items-center gap-2 cursor-pointer">
            <input type="checkbox" checked={form.valueAr === 'true'}
              onChange={(e) => setForm((f) => ({ ...f, valueAr: e.target.checked ? 'true' : 'false', valueEn: e.target.checked ? 'true' : 'false' }))}
              className="w-4 h-4 accent-[#2AB5CE]" />
            <span className="text-sm text-gray-700">مفعّل</span>
          </label>
        ) : (
          <div className="grid grid-cols-1 sm:grid-cols-2 gap-4">
            <Field label="القيمة (عربي)">
              <textarea className={inputCls} rows={form.type === 'number' ? 1 : 3}
                value={form.valueAr}
                onChange={(e) => setForm((f) => ({ ...f, valueAr: e.target.value }))} />
            </Field>
            <Field label="القيمة (إنجليزي)">
              <textarea className={inputCls} rows={form.type === 'number' ? 1 : 3}
                value={form.valueEn}
                onChange={(e) => setForm((f) => ({ ...f, valueEn: e.target.value }))} />
            </Field>
          </div>
        )}

        <label className="flex items-center gap-2 cursor-pointer">
          <input type="checkbox" checked={form.isSensitive}
            onChange={(e) => setForm((f) => ({ ...f, isSensitive: e.target.checked }))}
            className="w-4 h-4 accent-[#2AB5CE]" />
          <span className="text-sm text-gray-700">حساس (لا يظهر للتطبيق العام)</span>
        </label>

        {err && <p className="text-sm text-red-500">{err}</p>}
      </div>
      <ModalFooter saving={saving} valid={valid} onClose={onClose} onSubmit={submit} edit={!!initial} />
    </ModalShell>
  );
}

function RowActions({ onEdit, onDelete }) {
  return (
    <div className="flex items-center gap-2 shrink-0">
      <button onClick={onEdit}
        className="flex items-center gap-1 px-3 py-1.5 rounded-lg bg-gray-50 text-gray-600 hover:bg-gray-100 transition text-xs font-medium">
        <Edit3 className="w-3.5 h-3.5" /> تعديل
      </button>
      <button onClick={onDelete}
        className="flex items-center gap-1 px-3 py-1.5 rounded-lg bg-red-50 text-red-500 hover:bg-red-100 transition text-xs font-medium">
        <Trash2 className="w-3.5 h-3.5" /> حذف
      </button>
    </div>
  );
}

function ModalShell({ title, onClose, children }) {
  return (
    <div className="fixed inset-0 bg-black/50 z-50 flex items-center justify-center p-4">
      <div className="bg-white rounded-2xl shadow-2xl w-full max-w-lg">
        <div className="flex items-center justify-between px-6 py-4 border-b border-gray-100">
          <h3 className="font-bold text-gray-800 text-lg">{title}</h3>
          <button onClick={onClose}
            className="w-8 h-8 flex items-center justify-center rounded-lg hover:bg-gray-100 text-gray-400">
            <X className="w-5 h-5" />
          </button>
        </div>
        {children}
      </div>
    </div>
  );
}

function ModalFooter({ saving, valid, onClose, onSubmit, edit }) {
  return (
    <div className="flex gap-3 px-6 py-4 border-t border-gray-100">
      <button onClick={onClose}
        className="flex-1 py-2.5 border border-gray-200 rounded-xl text-gray-600 font-medium hover:bg-gray-50 transition text-sm">
        إلغاء
      </button>
      <button onClick={onSubmit} disabled={!valid || saving}
        className="flex-1 py-2.5 bg-[#2AB5CE] hover:bg-[#1E9AB0] disabled:bg-gray-200 disabled:text-gray-400 text-white font-medium rounded-xl transition text-sm flex items-center justify-center gap-2">
        <Save className="w-4 h-4" />
        {saving ? 'جارٍ الحفظ...' : edit ? 'حفظ التعديلات' : 'إضافة'}
      </button>
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
