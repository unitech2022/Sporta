import { useState } from 'react';
import { useNavigate } from 'react-router-dom';
import {
  Search, Eye, Trash2, ToggleLeft, ToggleRight,
  Plus, Gamepad2, Users, Edit3, Save, X
} from 'lucide-react';
import { adminApi } from '../api/adminApi';
import { useApi } from '../hooks/useApi';
import PageHeader from '../components/PageHeader';
import StatusBadge from '../components/StatusBadge';
import ConfirmModal from '../components/ConfirmModal';
import ImageUploadField, { resolveImageUrl } from '../components/ImageUploadField';
import { Spinner, Empty } from '../components/TableBits';

function SportFormModal({ open, initial, onClose, onSaved }) {
  const [form, setForm] = useState(
    initial
      ? { name: initial.name, nameEn: initial.nameEn, image: initial.image, description: initial.description ?? '', players: initial.players, duration: initial.duration }
      : { name: '', nameEn: '', image: null, description: '', players: 2, duration: 60 }
  );
  const [saving, setSaving] = useState(false);
  const [err, setErr] = useState(null);

  if (!open) return null;
  const isValid = form.name.trim() && form.nameEn.trim();

  const submit = async () => {
    if (!isValid || saving) return;
    setSaving(true);
    setErr(null);
    try {
      const body = { ...form, players: Number(form.players), duration: Number(form.duration) };
      if (initial) await adminApi.updateSport(initial.id, { ...body, isActive: initial.isActive, sortOrder: initial.sortOrder });
      else await adminApi.createSport(body);
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
          <h3 className="font-bold text-gray-800 text-lg">{initial ? 'تعديل اللعبة' : 'إضافة لعبة جديدة'}</h3>
          <button onClick={onClose} className="w-8 h-8 flex items-center justify-center rounded-lg hover:bg-gray-100 text-gray-400">
            <X className="w-5 h-5" />
          </button>
        </div>
        <div className="p-6 space-y-4">
          <div className="grid grid-cols-2 gap-4">
            <div>
              <label className="block text-sm font-medium text-gray-700 mb-1.5">اسم اللعبة (عربي)</label>
              <input value={form.name} onChange={e => setForm(f => ({ ...f, name: e.target.value }))}
                placeholder="مثال: البادل"
                className="w-full px-4 py-2.5 border border-gray-200 rounded-xl text-sm focus:outline-none focus:ring-2 focus:ring-[#2AB5CE] bg-gray-50" />
            </div>
            <div>
              <label className="block text-sm font-medium text-gray-700 mb-1.5">الاسم (إنجليزي)</label>
              <input value={form.nameEn} onChange={e => setForm(f => ({ ...f, nameEn: e.target.value }))}
                placeholder="Padel"
                className="w-full px-4 py-2.5 border border-gray-200 rounded-xl text-sm focus:outline-none focus:ring-2 focus:ring-[#2AB5CE] bg-gray-50" />
            </div>
          </div>
          <ImageUploadField
            label="صورة اللعبة"
            value={form.image}
            onChange={(url) => setForm(f => ({ ...f, image: url }))}
          />
          <div className="grid grid-cols-2 gap-4">
            <div>
              <label className="block text-sm font-medium text-gray-700 mb-1.5">عدد اللاعبين</label>
              <input type="number" min={1} value={form.players} onChange={e => setForm(f => ({ ...f, players: Number(e.target.value) }))}
                className="w-full px-4 py-2.5 border border-gray-200 rounded-xl text-sm focus:outline-none focus:ring-2 focus:ring-[#2AB5CE] bg-gray-50" />
            </div>
            <div>
              <label className="block text-sm font-medium text-gray-700 mb-1.5">مدة المباراة (دقيقة)</label>
              <input type="number" min={15} step={15} value={form.duration} onChange={e => setForm(f => ({ ...f, duration: Number(e.target.value) }))}
                className="w-full px-4 py-2.5 border border-gray-200 rounded-xl text-sm focus:outline-none focus:ring-2 focus:ring-[#2AB5CE] bg-gray-50" />
            </div>
          </div>
          <div>
            <label className="block text-sm font-medium text-gray-700 mb-1.5">الوصف</label>
            <textarea value={form.description} onChange={e => setForm(f => ({ ...f, description: e.target.value }))}
              rows={3} placeholder="وصف مختصر عن اللعبة..."
              className="w-full px-4 py-2.5 border border-gray-200 rounded-xl text-sm focus:outline-none focus:ring-2 focus:ring-[#2AB5CE] bg-gray-50 resize-none" />
          </div>
          {err && <p className="text-sm text-red-500">{err}</p>}
        </div>
        <div className="flex gap-3 px-6 py-4 border-t border-gray-100">
          <button onClick={onClose} className="flex-1 py-2.5 border border-gray-200 rounded-xl text-gray-600 font-medium hover:bg-gray-50 transition text-sm">إلغاء</button>
          <button onClick={submit} disabled={!isValid || saving}
            className="flex-1 py-2.5 bg-[#2AB5CE] hover:bg-[#1E9AB0] disabled:bg-gray-200 disabled:text-gray-400 text-white font-medium rounded-xl transition text-sm flex items-center justify-center gap-2">
            <Save className="w-4 h-4" />
            {saving ? 'جارٍ الحفظ...' : initial ? 'حفظ التعديلات' : 'إضافة اللعبة'}
          </button>
        </div>
      </div>
    </div>
  );
}

export default function SportsPage() {
  const [search, setSearch] = useState('');
  const [filter, setFilter] = useState('all');
  const [confirm, setConfirm] = useState(null);
  const [formModal, setFormModal] = useState(null); // 'new' | sport
  const navigate = useNavigate();

  const { data, loading, error, refetch } = useApi(() => adminApi.getSports(), []);
  const sports = data ?? [];

  const filtered = sports.filter(s => {
    const matchSearch = s.name.includes(search) || s.nameEn.toLowerCase().includes(search.toLowerCase());
    const matchFilter = filter === 'all' || (filter === 'active') === s.isActive;
    return matchSearch && matchFilter;
  });

  const handleDelete = async () => {
    await adminApi.deleteSport(confirm.item.id);
    setConfirm(null);
    refetch();
  };

  const handleToggle = async (sport) => {
    await adminApi.updateSport(sport.id, {
      name: sport.name, nameEn: sport.nameEn, image: sport.image, description: sport.description,
      players: sport.players, duration: sport.duration, isActive: !sport.isActive, sortOrder: sport.sortOrder,
    });
    setConfirm(null);
    refetch();
  };

  return (
    <div>
      <PageHeader
        title="الألعاب الرياضية"
        subtitle={`${sports.length} لعبة مسجلة في المنصة`}
        action={
          <button onClick={() => setFormModal('new')}
            className="flex items-center gap-2 px-4 py-2.5 bg-[#2AB5CE] hover:bg-[#1E9AB0] text-white rounded-xl text-sm font-medium shadow transition">
            <Plus className="w-4 h-4" /> إضافة لعبة
          </button>
        }
      />

      {/* Stats */}
      <div className="grid grid-cols-2 lg:grid-cols-3 gap-3 mb-6">
        {[
          { label: 'إجمالي الألعاب', value: sports.length, color: 'text-blue-600', bg: 'bg-blue-50', border: 'border-blue-100' },
          { label: 'النشطة', value: sports.filter(s => s.isActive).length, color: 'text-[#2AB5CE]', bg: 'bg-green-50', border: 'border-green-100' },
          { label: 'الموقوفة', value: sports.filter(s => !s.isActive).length, color: 'text-gray-500', bg: 'bg-gray-50', border: 'border-gray-100' },
        ].map(c => (
          <div key={c.label} className={`${c.bg} rounded-2xl border ${c.border} p-4 shadow-sm`}>
            <p className="text-xs text-gray-500 mb-1">{c.label}</p>
            <p className={`text-2xl font-bold ${c.color}`}>{c.value}</p>
          </div>
        ))}
      </div>

      {/* Filters */}
      <div className="flex flex-col sm:flex-row gap-3 mb-5">
        <div className="relative flex-1">
          <Search className="absolute right-3 top-1/2 -translate-y-1/2 w-4 h-4 text-gray-400" />
          <input value={search} onChange={e => setSearch(e.target.value)}
            placeholder="بحث باسم اللعبة..."
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
        <Empty icon={Gamepad2} text="لا توجد ألعاب مطابقة" />
      ) : (
        <div className="bg-white rounded-2xl shadow-sm border border-gray-100 overflow-hidden">
          <div className="overflow-x-auto">
            <table className="w-full text-sm">
              <thead>
                <tr className="border-b border-gray-100 bg-gray-50">
                  <th className="text-right px-5 py-3.5 font-semibold text-gray-600">اللعبة</th>
                  <th className="text-right px-4 py-3.5 font-semibold text-gray-600">عدد اللاعبين</th>
                  <th className="text-right px-4 py-3.5 font-semibold text-gray-600">مدة المباراة</th>
                  <th className="text-right px-4 py-3.5 font-semibold text-gray-600">الحالة</th>
                  <th className="text-right px-4 py-3.5 font-semibold text-gray-600">الإجراءات</th>
                </tr>
              </thead>
              <tbody className="divide-y divide-gray-50">
                {filtered.map(sport => (
                  <tr key={sport.id} className="hover:bg-gray-50/50 transition">
                    <td className="px-5 py-4">
                      <div className="flex items-center gap-3">
                        {sport.image ? (
                          <img src={resolveImageUrl(sport.image)} alt={sport.name}
                            className="w-10 h-10 rounded-xl object-cover shrink-0" />
                        ) : (
                          <div className="w-10 h-10 bg-gradient-to-br from-green-400 to-emerald-600 rounded-xl flex items-center justify-center shrink-0">
                            <Gamepad2 className="w-5 h-5 text-white" />
                          </div>
                        )}
                        <div>
                          <p className="font-semibold text-gray-800">{sport.name}</p>
                          <p className="text-xs text-gray-400">{sport.nameEn}</p>
                        </div>
                      </div>
                    </td>
                    <td className="px-4 py-4">
                      <span className="flex items-center gap-1.5 text-gray-600">
                        <Users className="w-3.5 h-3.5 text-gray-400" />
                        {sport.players} لاعبين
                      </span>
                    </td>
                    <td className="px-4 py-4 text-gray-600">{sport.duration} دقيقة</td>
                    <td className="px-4 py-4"><StatusBadge status={sport.isActive ? 'active' : 'inactive'} /></td>
                    <td className="px-4 py-4">
                      <div className="flex items-center gap-2">
                        <button onClick={() => navigate(`/sports/${sport.id}`)}
                          className="flex items-center gap-1 px-3 py-1.5 rounded-lg bg-blue-50 text-blue-600 hover:bg-blue-100 transition text-xs font-medium">
                          <Eye className="w-3.5 h-3.5" /> عرض
                        </button>
                        <button onClick={() => setFormModal(sport)}
                          className="flex items-center gap-1 px-3 py-1.5 rounded-lg bg-gray-50 text-gray-600 hover:bg-gray-100 transition text-xs font-medium">
                          <Edit3 className="w-3.5 h-3.5" /> تعديل
                        </button>
                        <button onClick={() => setConfirm({ type: 'toggle', item: sport })}
                          className={`flex items-center gap-1 px-3 py-1.5 rounded-lg text-xs font-medium transition ${sport.isActive ? 'bg-yellow-50 text-yellow-600 hover:bg-yellow-100' : 'bg-green-50 text-green-700 hover:bg-green-100'}`}>
                          {sport.isActive ? <><ToggleRight className="w-3.5 h-3.5"/>إيقاف</> : <><ToggleLeft className="w-3.5 h-3.5"/>تفعيل</>}
                        </button>
                        <button onClick={() => setConfirm({ type: 'delete', item: sport })}
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
        title={confirm?.type === 'delete' ? 'حذف اللعبة' : confirm?.item?.isActive ? 'إيقاف اللعبة' : 'تفعيل اللعبة'}
        message={confirm?.type === 'delete' ? `هل أنت متأكد من حذف "${confirm?.item?.name}"؟` : confirm?.item?.isActive ? `سيتم إيقاف "${confirm?.item?.name}" من المنصة.` : `سيتم تفعيل "${confirm?.item?.name}" في المنصة.`}
        danger={confirm?.type === 'delete'}
        onConfirm={() => confirm?.type === 'delete' ? handleDelete() : handleToggle(confirm.item)}
        onCancel={() => setConfirm(null)}
      />

      <SportFormModal
        open={!!formModal}
        initial={formModal !== 'new' ? formModal : null}
        onClose={() => setFormModal(null)}
        onSaved={() => { setFormModal(null); refetch(); }}
      />
    </div>
  );
}
