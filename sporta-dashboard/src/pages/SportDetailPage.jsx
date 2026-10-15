import { useState, useEffect, useCallback } from 'react';
import { useParams, useNavigate } from 'react-router-dom';
import {
  ArrowRight, Users, Clock, Hash,
  Trash2, ToggleLeft, ToggleRight, Edit3, Gamepad2,
  Save, X, Plus, ListChecks, BarChart3,
} from 'lucide-react';
import { adminApi } from '../api/adminApi';
import { assessmentApi } from '../api/assessmentApi';
import { useApi } from '../hooks/useApi';
import StatusBadge from '../components/StatusBadge';
import ConfirmModal from '../components/ConfirmModal';
import ImageUploadField, { resolveImageUrl } from '../components/ImageUploadField';
import { Spinner } from '../components/TableBits';

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
      const body = {
        ...form, players: Number(form.players), duration: Number(form.duration),
        isActive: initial.isActive, sortOrder: initial.sortOrder,
      };
      await adminApi.updateSport(initial.id, body);
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
          <h3 className="font-bold text-gray-800 text-lg">تعديل اللعبة</h3>
          <button onClick={onClose} className="w-8 h-8 flex items-center justify-center rounded-lg hover:bg-gray-100 text-gray-400">
            <X className="w-5 h-5" />
          </button>
        </div>
        <div className="p-6 space-y-4">
          <div className="grid grid-cols-2 gap-4">
            <div>
              <label className="block text-sm font-medium text-gray-700 mb-1.5">اسم اللعبة (عربي)</label>
              <input value={form.name} onChange={e => setForm(f => ({ ...f, name: e.target.value }))}
                className="w-full px-4 py-2.5 border border-gray-200 rounded-xl text-sm focus:outline-none focus:ring-2 focus:ring-[#2AB5CE] bg-gray-50" />
            </div>
            <div>
              <label className="block text-sm font-medium text-gray-700 mb-1.5">الاسم (إنجليزي)</label>
              <input value={form.nameEn} onChange={e => setForm(f => ({ ...f, nameEn: e.target.value }))}
                className="w-full px-4 py-2.5 border border-gray-200 rounded-xl text-sm focus:outline-none focus:ring-2 focus:ring-[#2AB5CE] bg-gray-50" />
            </div>
          </div>
          <ImageUploadField
            label="صورة اللعبة"
            value={form.image}
            onChange={(url) => setForm(f => ({ ...f, image: url }))}
          />
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
          <div>
            <label className="block text-sm font-medium text-gray-700 mb-1.5">الوصف</label>
            <textarea value={form.description} onChange={e => setForm(f => ({ ...f, description: e.target.value }))}
              rows={3} className="w-full px-4 py-2.5 border border-gray-200 rounded-xl text-sm focus:outline-none focus:ring-2 focus:ring-[#2AB5CE] bg-gray-50 resize-none" />
          </div>
          {err && <p className="text-sm text-red-500">{err}</p>}
        </div>
        <div className="flex gap-3 px-6 py-4 border-t border-gray-100">
          <button onClick={onClose} className="flex-1 py-2.5 border border-gray-200 rounded-xl text-gray-600 font-medium hover:bg-gray-50 transition text-sm">إلغاء</button>
          <button onClick={submit} disabled={!isValid || saving}
            className="flex-1 py-2.5 bg-[#2AB5CE] hover:bg-[#1E9AB0] disabled:bg-gray-200 disabled:text-gray-400 text-white font-medium rounded-xl transition text-sm flex items-center justify-center gap-2">
            <Save className="w-4 h-4" /> {saving ? 'جارٍ الحفظ...' : 'حفظ التعديلات'}
          </button>
        </div>
      </div>
    </div>
  );
}

export default function SportDetailPage() {
  const { id } = useParams();
  const navigate = useNavigate();
  const [confirm, setConfirm] = useState(null);
  const [editOpen, setEditOpen] = useState(false);

  const { data, loading, error, refetch } = useApi(() => adminApi.getSports(), []);
  const sport = (data ?? []).find(s => s.id === Number(id));

  if (loading) return <Spinner />;
  if (error) return <div className="text-center py-16 text-red-500 text-sm">{error}</div>;

  if (!sport) return (
    <div className="text-center py-20 text-gray-400">
      <p>اللعبة غير موجودة</p>
      <button onClick={() => navigate('/sports')} className="mt-3 text-[#2AB5CE] hover:underline text-sm">العودة للألعاب</button>
    </div>
  );

  const handleDelete = async () => {
    await adminApi.deleteSport(sport.id);
    setConfirm(null);
    navigate('/sports');
  };

  const handleToggle = async () => {
    await adminApi.updateSport(sport.id, {
      name: sport.name, nameEn: sport.nameEn, image: sport.image, description: sport.description,
      players: sport.players, duration: sport.duration, isActive: !sport.isActive, sortOrder: sport.sortOrder,
    });
    setConfirm(null);
    refetch();
  };

  const statCards = [
    { label: 'اللاعبون/مباراة', value: sport.players, icon: <Users className="w-5 h-5 text-[#2AB5CE]" />, bg: 'bg-green-50' },
    { label: 'مدة المباراة', value: `${sport.duration} د`, icon: <Clock className="w-5 h-5 text-orange-600" />, bg: 'bg-orange-50' },
    { label: 'الترتيب', value: sport.sortOrder, icon: <Hash className="w-5 h-5 text-purple-600" />, bg: 'bg-purple-50' },
  ];

  return (
    <div>
      <button onClick={() => navigate('/sports')} className="flex items-center gap-2 text-sm text-gray-500 hover:text-gray-700 mb-5">
        <ArrowRight className="w-4 h-4" /> العودة للألعاب
      </button>

      <div className="grid grid-cols-1 lg:grid-cols-3 gap-5">
        {/* Main */}
        <div className="lg:col-span-2 space-y-4">
          {/* Hero Card */}
          <div className="bg-white rounded-2xl shadow-sm border border-gray-100 overflow-hidden">
            <div className="bg-gradient-to-l from-green-600 to-emerald-700 px-6 py-8 flex items-center gap-5">
              <div className="w-20 h-20 bg-white/20 rounded-2xl flex items-center justify-center overflow-hidden shrink-0">
                {sport.image ? (
                  <img src={resolveImageUrl(sport.image)} alt={sport.name} className="w-full h-full object-cover" />
                ) : (
                  <Gamepad2 className="w-8 h-8 text-white" />
                )}
              </div>
              <div className="text-white">
                <div className="flex items-center gap-3 mb-1">
                  <h2 className="text-2xl font-black">{sport.name}</h2>
                  <StatusBadge status={sport.isActive ? 'active' : 'inactive'} />
                </div>
                <p className="text-green-200 text-sm">{sport.nameEn}</p>
                {sport.description && (
                  <p className="text-green-100 text-sm mt-2 leading-relaxed">{sport.description}</p>
                )}
              </div>
            </div>

            {/* Stats row */}
            <div className="grid grid-cols-3 divide-x divide-x-reverse divide-gray-100 border-b border-gray-100">
              {statCards.map(c => (
                <div key={c.label} className="p-4 text-center">
                  <div className={`w-9 h-9 ${c.bg} rounded-xl flex items-center justify-center mx-auto mb-2`}>
                    {c.icon}
                  </div>
                  <p className="text-xl font-bold text-gray-800">{c.value}</p>
                  <p className="text-xs text-gray-400 mt-0.5">{c.label}</p>
                </div>
              ))}
            </div>

            {/* Info */}
            <div className="p-6">
              <div className="grid grid-cols-1 sm:grid-cols-2 gap-0">
                {[
                  { label: 'اسم اللعبة', value: sport.name },
                  { label: 'الاسم الإنجليزي', value: sport.nameEn },
                  { label: 'عدد اللاعبين في المباراة', value: `${sport.players} لاعبين` },
                  { label: 'مدة المباراة', value: `${sport.duration} دقيقة` },
                  { label: 'تاريخ الإضافة', value: sport.createdAt },
                  { label: 'الحالة', value: <StatusBadge status={sport.isActive ? 'active' : 'inactive'} /> },
                ].map(row => (
                  <div key={row.label} className="flex items-center justify-between py-3 border-b border-gray-50">
                    <span className="text-sm text-gray-500">{row.label}</span>
                    <span className="text-sm font-semibold text-gray-800">{row.value}</span>
                  </div>
                ))}
              </div>
            </div>
          </div>

          {/* إعدادات اللعبة: عنوان + عناصر تحته */}
          <SportSettingsSection sportId={sport.id} />

          {/* مستويات اللعبة */}
          <SportLevelsSection sportKey={sport.key} sportName={sport.name} />
        </div>

        {/* Side */}
        <div className="space-y-4">
          <div className="bg-white rounded-2xl shadow-sm border border-gray-100 p-5">
            <h3 className="font-bold text-gray-800 mb-4">الإجراءات</h3>
            <div className="space-y-3">
              <button onClick={() => setEditOpen(true)}
                className="w-full flex items-center justify-center gap-2 py-3 rounded-xl font-medium text-sm bg-gray-50 text-gray-700 hover:bg-gray-100 border border-gray-200 transition">
                <Edit3 className="w-4 h-4" /> تعديل اللعبة
              </button>
              <button onClick={() => setConfirm('toggle')}
                className={`w-full flex items-center justify-center gap-2 py-3 rounded-xl font-medium text-sm border transition ${sport.isActive ? 'bg-yellow-50 text-yellow-700 border-yellow-200 hover:bg-yellow-100' : 'bg-green-50 text-green-700 border-green-200 hover:bg-green-100'}`}>
                {sport.isActive ? <><ToggleRight className="w-4 h-4"/>إيقاف اللعبة</> : <><ToggleLeft className="w-4 h-4"/>تفعيل اللعبة</>}
              </button>
              <button onClick={() => setConfirm('delete')}
                className="w-full flex items-center justify-center gap-2 py-3 rounded-xl font-medium text-sm bg-red-50 text-red-600 border border-red-200 hover:bg-red-100 transition">
                <Trash2 className="w-4 h-4" /> حذف اللعبة
              </button>
            </div>
          </div>
        </div>
      </div>

      <ConfirmModal open={confirm === 'delete'} title="حذف اللعبة" message={`هل أنت متأكد من حذف "${sport.name}"؟ لا يمكن التراجع.`} danger onConfirm={handleDelete} onCancel={() => setConfirm(null)} />
      <ConfirmModal open={confirm === 'toggle'} title={sport.isActive ? 'إيقاف اللعبة' : 'تفعيل اللعبة'} message={sport.isActive ? `سيتم إيقاف "${sport.name}" من المنصة.` : `سيتم تفعيل "${sport.name}".`} danger={false} onConfirm={handleToggle} onCancel={() => setConfirm(null)} />
      <SportFormModal open={editOpen} initial={sport} onClose={() => setEditOpen(false)} onSaved={() => { setEditOpen(false); refetch(); }} />
    </div>
  );
}

// ── إعدادات اللعبة (عنوان + عناصر) ────────────────────────────────────────────

const inputCls =
  'w-full px-4 py-2.5 border border-gray-200 rounded-xl text-sm focus:outline-none focus:ring-2 focus:ring-[#2AB5CE] bg-gray-50';

function SportSettingsSection({ sportId }) {
  const [settings, setSettings] = useState([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState(null);
  const [modal, setModal] = useState(null); // 'new' | setting
  const [toDelete, setToDelete] = useState(null);

  const load = useCallback(async () => {
    setLoading(true);
    setError(null);
    try {
      const res = await adminApi.getSportSettings(sportId);
      setSettings(res.data.data);
    } catch (e) {
      setError(e?.response?.data?.messageAr || 'تعذّر تحميل الإعدادات');
    } finally {
      setLoading(false);
    }
  }, [sportId]);

  useEffect(() => { load(); }, [load]);

  const save = async (form) => {
    if (modal === 'new') await adminApi.createSportSetting(sportId, form);
    else await adminApi.updateSportSetting(modal.id, form);
    setModal(null);
    load();
  };

  const remove = async () => {
    await adminApi.deleteSportSetting(toDelete.id);
    setToDelete(null);
    load();
  };

  return (
    <div className="bg-white rounded-2xl shadow-sm border border-gray-100 p-5">
      <div className="flex items-center justify-between mb-4">
        <h3 className="font-bold text-gray-800 flex items-center gap-2">
          <ListChecks className="w-4 h-4 text-[#2AB5CE]" /> إعدادات اللعبة
        </h3>
        <button onClick={() => setModal('new')}
          className="flex items-center gap-1.5 px-3 py-2 bg-[#2AB5CE] hover:bg-[#1E9AB0] text-white rounded-xl text-xs font-medium transition">
          <Plus className="w-4 h-4" /> إعداد جديد
        </button>
      </div>

      {loading ? (
        <div className="py-8 flex justify-center">
          <div className="w-8 h-8 border-4 border-green-200 border-t-[#2AB5CE] rounded-full animate-spin" />
        </div>
      ) : error ? (
        <p className="text-center py-8 text-sm text-red-500">{error}</p>
      ) : settings.length === 0 ? (
        <p className="text-center py-8 text-sm text-gray-400">
          لا توجد إعدادات لهذه اللعبة بعد — أضف عنوانًا وعناصره
        </p>
      ) : (
        <div className="space-y-3">
          {settings.map((s) => (
            <div key={s.id} className="rounded-xl border border-gray-100 bg-gray-50/50 p-4">
              <div className="flex items-start justify-between gap-3">
                <p className="font-semibold text-gray-800 text-sm">{s.title}</p>
                <div className="flex items-center gap-2 shrink-0">
                  <button onClick={() => setModal(s)}
                    className="flex items-center gap-1 px-2.5 py-1.5 rounded-lg bg-white border border-gray-200 text-gray-600 hover:bg-gray-100 transition text-xs">
                    <Edit3 className="w-3.5 h-3.5" /> تعديل
                  </button>
                  <button onClick={() => setToDelete(s)}
                    className="flex items-center gap-1 px-2.5 py-1.5 rounded-lg bg-red-50 text-red-500 hover:bg-red-100 transition text-xs">
                    <Trash2 className="w-3.5 h-3.5" /> حذف
                  </button>
                </div>
              </div>
              {s.items.length > 0 && (
                <ul className="mt-2 space-y-1">
                  {s.items.map((item, i) => (
                    <li key={i} className="flex items-center gap-2 text-sm text-gray-600">
                      <span className="w-1.5 h-1.5 rounded-full bg-[#2AB5CE] shrink-0" />
                      {item}
                    </li>
                  ))}
                </ul>
              )}
            </div>
          ))}
        </div>
      )}

      {modal && (
        <SettingFormModal
          initial={modal === 'new' ? null : modal}
          onSave={save}
          onClose={() => setModal(null)}
        />
      )}
      <ConfirmModal
        open={!!toDelete}
        title="حذف الإعداد"
        message={`هل أنت متأكد من حذف "${toDelete?.title}"؟`}
        danger
        onConfirm={remove}
        onCancel={() => setToDelete(null)}
      />
    </div>
  );
}

function SettingFormModal({ initial, onSave, onClose }) {
  const [form, setForm] = useState(
    initial
      ? { title: initial.title, itemsText: initial.items.join('\n'), sortOrder: initial.sortOrder }
      : { title: '', itemsText: '', sortOrder: 0 },
  );
  const [saving, setSaving] = useState(false);
  const [err, setErr] = useState(null);
  const valid = form.title.trim();

  const submit = async () => {
    if (!valid || saving) return;
    setSaving(true);
    setErr(null);
    try {
      await onSave({
        title: form.title.trim(),
        items: form.itemsText.split('\n').map((i) => i.trim()).filter(Boolean),
        sortOrder: Number(form.sortOrder) || 0,
      });
    } catch (e) {
      setErr(e?.response?.data?.messageAr || 'تعذّر الحفظ');
      setSaving(false);
    }
  };

  return (
    <div className="fixed inset-0 bg-black/50 z-50 flex items-center justify-center p-4">
      <div className="bg-white rounded-2xl shadow-2xl w-full max-w-md">
        <div className="flex items-center justify-between px-6 py-4 border-b border-gray-100">
          <h3 className="font-bold text-gray-800 text-lg">{initial ? 'تعديل الإعداد' : 'إعداد جديد'}</h3>
          <button onClick={onClose} className="w-8 h-8 flex items-center justify-center rounded-lg hover:bg-gray-100 text-gray-400">
            <X className="w-5 h-5" />
          </button>
        </div>
        <div className="p-6 space-y-4">
          <div>
            <label className="block text-sm font-medium text-gray-700 mb-1.5">العنوان</label>
            <input className={inputCls} value={form.title}
              onChange={(e) => setForm((f) => ({ ...f, title: e.target.value }))}
              placeholder="مثال: قوانين اللعبة" />
          </div>
          <div>
            <label className="block text-sm font-medium text-gray-700 mb-1.5">
              العناصر <span className="text-gray-400 font-normal">(عنصر في كل سطر)</span>
            </label>
            <textarea rows={5} className={`${inputCls} resize-none`} value={form.itemsText}
              onChange={(e) => setForm((f) => ({ ...f, itemsText: e.target.value }))}
              placeholder={'العنصر الأول\nالعنصر الثاني\nالعنصر الثالث'} />
          </div>
          <div>
            <label className="block text-sm font-medium text-gray-700 mb-1.5">الترتيب</label>
            <input type="number" className={inputCls} value={form.sortOrder}
              onChange={(e) => setForm((f) => ({ ...f, sortOrder: e.target.value }))} />
          </div>
          {err && <p className="text-sm text-red-500">{err}</p>}
        </div>
        <div className="flex gap-3 px-6 py-4 border-t border-gray-100">
          <button onClick={onClose}
            className="flex-1 py-2.5 border border-gray-200 rounded-xl text-gray-600 font-medium hover:bg-gray-50 transition text-sm">
            إلغاء
          </button>
          <button onClick={submit} disabled={!valid || saving}
            className="flex-1 py-2.5 bg-[#2AB5CE] hover:bg-[#1E9AB0] disabled:bg-gray-200 disabled:text-gray-400 text-white font-medium rounded-xl transition text-sm flex items-center justify-center gap-2">
            <Save className="w-4 h-4" /> {saving ? 'جارٍ الحفظ...' : initial ? 'حفظ التعديلات' : 'إضافة'}
          </button>
        </div>
      </div>
    </div>
  );
}

// ── مستويات اللعبة ────────────────────────────────────────────────────────────

function SportLevelsSection({ sportKey, sportName }) {
  const [levels, setLevels] = useState([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState(null);
  const [modal, setModal] = useState(null); // 'new' | level
  const [toDelete, setToDelete] = useState(null);

  const load = useCallback(async () => {
    setLoading(true);
    setError(null);
    try {
      const res = await assessmentApi.getLevels(sportKey);
      setLevels(res.data.data);
    } catch (e) {
      setError(e?.response?.data?.messageAr || 'تعذّر تحميل المستويات');
    } finally {
      setLoading(false);
    }
  }, [sportKey]);

  useEffect(() => { load(); }, [load]);

  const save = async (form) => {
    const body = { ...form, sport: sportKey };
    if (modal === 'new') await assessmentApi.createLevel(body);
    else await assessmentApi.updateLevel(modal.id, body);
    setModal(null);
    load();
  };

  const remove = async () => {
    await assessmentApi.deleteLevel(toDelete.id);
    setToDelete(null);
    load();
  };

  return (
    <div className="bg-white rounded-2xl shadow-sm border border-gray-100 p-5">
      <div className="flex items-center justify-between mb-4">
        <h3 className="font-bold text-gray-800 flex items-center gap-2">
          <BarChart3 className="w-4 h-4 text-[#2AB5CE]" /> مستويات {sportName}
        </h3>
        <button onClick={() => setModal('new')}
          className="flex items-center gap-1.5 px-3 py-2 bg-[#2AB5CE] hover:bg-[#1E9AB0] text-white rounded-xl text-xs font-medium transition">
          <Plus className="w-4 h-4" /> مستوى جديد
        </button>
      </div>

      {loading ? (
        <div className="py-8 flex justify-center">
          <div className="w-8 h-8 border-4 border-green-200 border-t-[#2AB5CE] rounded-full animate-spin" />
        </div>
      ) : error ? (
        <p className="text-center py-8 text-sm text-red-500">{error}</p>
      ) : levels.length === 0 ? (
        <p className="text-center py-8 text-sm text-gray-400">لا توجد مستويات لهذه اللعبة بعد</p>
      ) : (
        <div className="overflow-x-auto">
          <table className="w-full text-sm">
            <thead>
              <tr className="border-b border-gray-100 bg-gray-50">
                <th className="text-right px-4 py-3 font-semibold text-gray-600">الترتيب</th>
                <th className="text-right px-4 py-3 font-semibold text-gray-600">الاسم</th>
                <th className="text-right px-4 py-3 font-semibold text-gray-600">عتبة الدرجة</th>
                <th className="text-right px-4 py-3 font-semibold text-gray-600">الحالة</th>
                <th className="text-right px-4 py-3 font-semibold text-gray-600">الإجراءات</th>
              </tr>
            </thead>
            <tbody className="divide-y divide-gray-50">
              {levels.map((l) => (
                <tr key={l.id} className="hover:bg-gray-50/50 transition">
                  <td className="px-4 py-3">
                    <span className="inline-flex w-7 h-7 items-center justify-center rounded-lg bg-[#2AB5CE]/10 text-[#2AB5CE] font-bold text-xs">
                      {l.sortOrder}
                    </span>
                  </td>
                  <td className="px-4 py-3">
                    <p className="font-semibold text-gray-800">{l.nameAr}</p>
                    <p className="text-xs text-gray-400">{l.nameEn}</p>
                  </td>
                  <td className="px-4 py-3 text-gray-600">{l.minScore}</td>
                  <td className="px-4 py-3">
                    <span className={`inline-block px-2.5 py-0.5 rounded-full text-xs font-medium ${l.isActive ? 'bg-green-100 text-green-700' : 'bg-gray-100 text-gray-500'}`}>
                      {l.isActive ? 'مفعّل' : 'معطّل'}
                    </span>
                  </td>
                  <td className="px-4 py-3">
                    <div className="flex items-center gap-2">
                      <button onClick={() => setModal(l)}
                        className="flex items-center gap-1 px-2.5 py-1.5 rounded-lg bg-gray-50 text-gray-600 hover:bg-gray-100 transition text-xs">
                        <Edit3 className="w-3.5 h-3.5" /> تعديل
                      </button>
                      <button onClick={() => setToDelete(l)}
                        className="flex items-center gap-1 px-2.5 py-1.5 rounded-lg bg-red-50 text-red-500 hover:bg-red-100 transition text-xs">
                        <Trash2 className="w-3.5 h-3.5" /> حذف
                      </button>
                    </div>
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
      )}

      {modal && (
        <SportLevelFormModal
          initial={modal === 'new' ? null : modal}
          onSave={save}
          onClose={() => setModal(null)}
        />
      )}
      <ConfirmModal
        open={!!toDelete}
        title="حذف المستوى"
        message={`هل أنت متأكد من حذف "${toDelete?.nameAr}"؟`}
        danger
        onConfirm={remove}
        onCancel={() => setToDelete(null)}
      />
    </div>
  );
}

function SportLevelFormModal({ initial, onSave, onClose }) {
  const [form, setForm] = useState(
    initial
      ? {
          nameAr: initial.nameAr, nameEn: initial.nameEn,
          descriptionAr: initial.descriptionAr ?? '', descriptionEn: initial.descriptionEn ?? '',
          minScore: initial.minScore, sortOrder: initial.sortOrder, isActive: initial.isActive,
        }
      : {
          nameAr: '', nameEn: '', descriptionAr: '', descriptionEn: '',
          minScore: 0, sortOrder: 1, isActive: true,
        },
  );
  const [saving, setSaving] = useState(false);
  const [err, setErr] = useState(null);
  const valid = form.nameAr.trim() && form.nameEn.trim();

  const submit = async () => {
    if (!valid || saving) return;
    setSaving(true);
    setErr(null);
    try {
      await onSave({
        ...form,
        minScore: Number(form.minScore),
        sortOrder: Number(form.sortOrder),
      });
    } catch (e) {
      setErr(e?.response?.data?.messageAr || 'تعذّر الحفظ');
      setSaving(false);
    }
  };

  return (
    <div className="fixed inset-0 bg-black/50 z-50 flex items-center justify-center p-4">
      <div className="bg-white rounded-2xl shadow-2xl w-full max-w-md">
        <div className="flex items-center justify-between px-6 py-4 border-b border-gray-100">
          <h3 className="font-bold text-gray-800 text-lg">{initial ? 'تعديل المستوى' : 'مستوى جديد'}</h3>
          <button onClick={onClose} className="w-8 h-8 flex items-center justify-center rounded-lg hover:bg-gray-100 text-gray-400">
            <X className="w-5 h-5" />
          </button>
        </div>
        <div className="p-6 space-y-4">
          <div className="grid grid-cols-2 gap-4">
            <div>
              <label className="block text-sm font-medium text-gray-700 mb-1.5">الاسم (عربي)</label>
              <input className={inputCls} value={form.nameAr}
                onChange={(e) => setForm((f) => ({ ...f, nameAr: e.target.value }))} placeholder="متقدم" />
            </div>
            <div>
              <label className="block text-sm font-medium text-gray-700 mb-1.5">الاسم (إنجليزي)</label>
              <input className={inputCls} value={form.nameEn}
                onChange={(e) => setForm((f) => ({ ...f, nameEn: e.target.value }))} placeholder="Advanced" />
            </div>
          </div>
          <div className="grid grid-cols-2 gap-4">
            <div>
              <label className="block text-sm font-medium text-gray-700 mb-1.5">عتبة الدرجة</label>
              <input type="number" className={inputCls} value={form.minScore}
                onChange={(e) => setForm((f) => ({ ...f, minScore: e.target.value }))} />
            </div>
            <div>
              <label className="block text-sm font-medium text-gray-700 mb-1.5">الترتيب</label>
              <input type="number" className={inputCls} value={form.sortOrder}
                onChange={(e) => setForm((f) => ({ ...f, sortOrder: e.target.value }))} />
            </div>
          </div>
          <label className="flex items-center gap-2 cursor-pointer">
            <input type="checkbox" checked={form.isActive}
              onChange={(e) => setForm((f) => ({ ...f, isActive: e.target.checked }))}
              className="w-4 h-4 accent-[#2AB5CE]" />
            <span className="text-sm text-gray-700">مفعّل</span>
          </label>
          {err && <p className="text-sm text-red-500">{err}</p>}
        </div>
        <div className="flex gap-3 px-6 py-4 border-t border-gray-100">
          <button onClick={onClose}
            className="flex-1 py-2.5 border border-gray-200 rounded-xl text-gray-600 font-medium hover:bg-gray-50 transition text-sm">
            إلغاء
          </button>
          <button onClick={submit} disabled={!valid || saving}
            className="flex-1 py-2.5 bg-[#2AB5CE] hover:bg-[#1E9AB0] disabled:bg-gray-200 disabled:text-gray-400 text-white font-medium rounded-xl transition text-sm flex items-center justify-center gap-2">
            <Save className="w-4 h-4" /> {saving ? 'جارٍ الحفظ...' : initial ? 'حفظ التعديلات' : 'إضافة'}
          </button>
        </div>
      </div>
    </div>
  );
}
