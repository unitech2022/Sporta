import { useState } from 'react';
import {
  Search, Trash2, ToggleLeft, ToggleRight,
  Plus, GraduationCap, Edit3, Save, X
} from 'lucide-react';
import { adminApi } from '../api/adminApi';
import { useApi } from '../hooks/useApi';
import PageHeader from '../components/PageHeader';
import StatusBadge from '../components/StatusBadge';
import ConfirmModal from '../components/ConfirmModal';
import { Spinner, Empty } from '../components/TableBits';

function SpecializationFormModal({ open, initial, onClose, onSaved }) {
  const [form, setForm] = useState(
    initial
      ? { nameAr: initial.nameAr, nameEn: initial.nameEn }
      : { nameAr: '', nameEn: '' }
  );
  const [saving, setSaving] = useState(false);
  const [err, setErr] = useState(null);

  if (!open) return null;
  const isValid = form.nameAr.trim() && form.nameEn.trim();

  const submit = async () => {
    if (!isValid || saving) return;
    setSaving(true);
    setErr(null);
    try {
      if (initial) {
        await adminApi.updateCoachSpecialization(initial.id, {
          ...form, isActive: initial.isActive, sortOrder: initial.sortOrder,
        });
      } else {
        await adminApi.createCoachSpecialization(form);
      }
      onSaved();
    } catch (e) {
      setErr(e?.response?.data?.messageAr || 'تعذّر الحفظ');
      setSaving(false);
    }
  };

  return (
    <div className="fixed inset-0 bg-black/50 z-50 flex items-center justify-center p-4">
      <div className="bg-white rounded-2xl shadow-2xl w-full max-w-md">
        <div className="flex items-center justify-between px-6 py-4 border-b border-gray-100">
          <h3 className="font-bold text-gray-800 text-lg">{initial ? 'تعديل التخصص' : 'إضافة تخصص جديد'}</h3>
          <button onClick={onClose} className="w-8 h-8 flex items-center justify-center rounded-lg hover:bg-gray-100 text-gray-400">
            <X className="w-5 h-5" />
          </button>
        </div>
        <div className="p-6 space-y-4">
          <div>
            <label className="block text-sm font-medium text-gray-700 mb-1.5">اسم التخصص (عربي)</label>
            <input value={form.nameAr} onChange={e => setForm(f => ({ ...f, nameAr: e.target.value }))}
              placeholder="مثال: تدريب المبتدئين"
              className="w-full px-4 py-2.5 border border-gray-200 rounded-xl text-sm focus:outline-none focus:ring-2 focus:ring-[#2AB5CE] bg-gray-50" />
          </div>
          <div>
            <label className="block text-sm font-medium text-gray-700 mb-1.5">الاسم (إنجليزي)</label>
            <input value={form.nameEn} onChange={e => setForm(f => ({ ...f, nameEn: e.target.value }))}
              placeholder="Beginner Training"
              className="w-full px-4 py-2.5 border border-gray-200 rounded-xl text-sm focus:outline-none focus:ring-2 focus:ring-[#2AB5CE] bg-gray-50" />
          </div>
          {err && <p className="text-sm text-red-500">{err}</p>}
        </div>
        <div className="flex gap-3 px-6 py-4 border-t border-gray-100">
          <button onClick={onClose} className="flex-1 py-2.5 border border-gray-200 rounded-xl text-gray-600 font-medium hover:bg-gray-50 transition text-sm">إلغاء</button>
          <button onClick={submit} disabled={!isValid || saving}
            className="flex-1 py-2.5 bg-[#2AB5CE] hover:bg-[#1E9AB0] disabled:bg-gray-200 disabled:text-gray-400 text-white font-medium rounded-xl transition text-sm flex items-center justify-center gap-2">
            <Save className="w-4 h-4" />
            {saving ? 'جارٍ الحفظ...' : initial ? 'حفظ التعديلات' : 'إضافة التخصص'}
          </button>
        </div>
      </div>
    </div>
  );
}

export default function CoachSpecializationsPage() {
  const [search, setSearch] = useState('');
  const [filter, setFilter] = useState('all');
  const [confirm, setConfirm] = useState(null);
  const [formModal, setFormModal] = useState(null); // 'new' | specialization

  const { data, loading, error, refetch } = useApi(() => adminApi.getCoachSpecializations(), []);
  const specializations = data ?? [];

  const filtered = specializations.filter(s => {
    const matchSearch = s.nameAr.includes(search) || s.nameEn.toLowerCase().includes(search.toLowerCase());
    const matchFilter = filter === 'all' || (filter === 'active') === s.isActive;
    return matchSearch && matchFilter;
  });

  const handleDelete = async () => {
    await adminApi.deleteCoachSpecialization(confirm.item.id);
    setConfirm(null);
    refetch();
  };

  const handleToggle = async (spec) => {
    await adminApi.updateCoachSpecialization(spec.id, {
      nameAr: spec.nameAr, nameEn: spec.nameEn, isActive: !spec.isActive, sortOrder: spec.sortOrder,
    });
    setConfirm(null);
    refetch();
  };

  return (
    <div>
      <PageHeader
        title="تخصصات المدربين"
        subtitle={`${specializations.length} تخصص متاح عند تسجيل المدربين`}
        action={
          <button onClick={() => setFormModal('new')}
            className="flex items-center gap-2 px-4 py-2.5 bg-[#2AB5CE] hover:bg-[#1E9AB0] text-white rounded-xl text-sm font-medium shadow transition">
            <Plus className="w-4 h-4" /> إضافة تخصص
          </button>
        }
      />

      {/* Filters */}
      <div className="flex flex-col sm:flex-row gap-3 mb-5">
        <div className="relative flex-1">
          <Search className="absolute right-3 top-1/2 -translate-y-1/2 w-4 h-4 text-gray-400" />
          <input value={search} onChange={e => setSearch(e.target.value)}
            placeholder="بحث باسم التخصص..."
            className="w-full pr-9 pl-4 py-2.5 border border-gray-200 rounded-xl text-sm focus:outline-none focus:ring-2 focus:ring-[#2AB5CE] bg-white" />
        </div>
        <div className="flex gap-2">
          {[['all','الكل'],['active','النشطة'],['inactive','الموقوفة']].map(([v,l]) => (
            <button key={v} onClick={() => setFilter(v)}
              className={`px-4 py-2.5 rounded-xl text-sm font-medium transition ${filter===v ? 'bg-[#2AB5CE] text-white shadow' : 'bg-white border border-gray-200 text-gray-600 hover:bg-gray-50'}`}>
              {l}
            </button>
          ))}
        </div>
      </div>

      {loading ? (
        <Spinner />
      ) : error ? (
        <div className="text-center py-16 text-red-500 text-sm">{error}</div>
      ) : filtered.length === 0 ? (
        <Empty icon={GraduationCap} text="لا توجد تخصصات مطابقة" />
      ) : (
        <div className="bg-white rounded-2xl shadow-sm border border-gray-100 overflow-hidden">
          <div className="overflow-x-auto">
            <table className="w-full text-sm">
              <thead>
                <tr className="border-b border-gray-100 bg-gray-50">
                  <th className="text-right px-5 py-3.5 font-semibold text-gray-600">التخصص</th>
                  <th className="text-right px-4 py-3.5 font-semibold text-gray-600">الحالة</th>
                  <th className="text-right px-4 py-3.5 font-semibold text-gray-600">الإجراءات</th>
                </tr>
              </thead>
              <tbody className="divide-y divide-gray-50">
                {filtered.map(spec => (
                  <tr key={spec.id} className="hover:bg-gray-50/50 transition">
                    <td className="px-5 py-4">
                      <div className="flex items-center gap-3">
                        <div className="w-10 h-10 bg-gradient-to-br from-violet-400 to-purple-600 rounded-xl flex items-center justify-center shrink-0">
                          <GraduationCap className="w-5 h-5 text-white" />
                        </div>
                        <div>
                          <p className="font-semibold text-gray-800">{spec.nameAr}</p>
                          <p className="text-xs text-gray-400">{spec.nameEn}</p>
                        </div>
                      </div>
                    </td>
                    <td className="px-4 py-4"><StatusBadge status={spec.isActive ? 'active' : 'inactive'} /></td>
                    <td className="px-4 py-4">
                      <div className="flex items-center gap-2">
                        <button onClick={() => setFormModal(spec)}
                          className="flex items-center gap-1 px-3 py-1.5 rounded-lg bg-gray-50 text-gray-600 hover:bg-gray-100 transition text-xs font-medium">
                          <Edit3 className="w-3.5 h-3.5" /> تعديل
                        </button>
                        <button onClick={() => setConfirm({ type: 'toggle', item: spec })}
                          className={`flex items-center gap-1 px-3 py-1.5 rounded-lg text-xs font-medium transition ${spec.isActive ? 'bg-yellow-50 text-yellow-600 hover:bg-yellow-100' : 'bg-green-50 text-green-700 hover:bg-green-100'}`}>
                          {spec.isActive ? <><ToggleRight className="w-3.5 h-3.5"/>إيقاف</> : <><ToggleLeft className="w-3.5 h-3.5"/>تفعيل</>}
                        </button>
                        <button onClick={() => setConfirm({ type: 'delete', item: spec })}
                          className="flex items-center gap-1 px-3 py-1.5 rounded-lg bg-red-50 text-red-500 hover:bg-red-100 transition text-xs font-medium">
                          <Trash2 className="w-3.5 h-3.5" /> حذف
                        </button>
                      </div>
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        </div>
      )}

      <ConfirmModal
        open={!!confirm}
        title={confirm?.type === 'delete' ? 'حذف التخصص' : confirm?.item?.isActive ? 'إيقاف التخصص' : 'تفعيل التخصص'}
        message={confirm?.type === 'delete' ? `هل أنت متأكد من حذف "${confirm?.item?.nameAr}"؟` : confirm?.item?.isActive ? `سيتم إيقاف "${confirm?.item?.nameAr}" ولن يظهر عند تسجيل المدربين.` : `سيتم تفعيل "${confirm?.item?.nameAr}" ليظهر عند تسجيل المدربين.`}
        danger={confirm?.type === 'delete'}
        onConfirm={() => confirm?.type === 'delete' ? handleDelete() : handleToggle(confirm.item)}
        onCancel={() => setConfirm(null)}
      />

      <SpecializationFormModal
        open={!!formModal}
        initial={formModal !== 'new' ? formModal : null}
        onClose={() => setFormModal(null)}
        onSaved={() => { setFormModal(null); refetch(); }}
      />
    </div>
  );
}
