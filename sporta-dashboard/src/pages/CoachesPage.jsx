import { useState } from 'react';
import { useNavigate } from 'react-router-dom';
import { Search, UserCheck, Star, BadgeCheck, Eye, Bell, Ban, CheckCircle, X, Save, Trash2 } from 'lucide-react';
import { coachesApi } from '../api/coachesApi';
import { adminApi } from '../api/adminApi';
import { useApi } from '../hooks/useApi';
import PageHeader from '../components/PageHeader';
import StatusBadge from '../components/StatusBadge';
import ConfirmModal from '../components/ConfirmModal';
import { Th, Spinner, Empty } from '../components/TableBits';
import { useAuth } from '../context/AuthContext';

const avatarColors = ['bg-teal-500', 'bg-indigo-500', 'bg-pink-500', 'bg-amber-500', 'bg-violet-500'];
const inputCls =
  'w-full px-4 py-2.5 border border-gray-200 rounded-xl text-sm focus:outline-none focus:ring-2 focus:ring-[#2AB5CE] bg-gray-50';

export default function CoachesPage() {
  const navigate = useNavigate();
  const { can } = useAuth();
  const canDelete = can('coaches.delete');

  const [search, setSearch] = useState('');
  // includeInactive: admin sees suspended coaches too, so they can be reactivated.
  const { data, loading, error, refetch } = useApi(() => coachesApi.getAll(undefined, true), []);
  // GET /api/coaches is paginated ({ items, page, pageSize, total }).
  const coaches = data?.items ?? [];

  const [confirm, setConfirm] = useState(null); // coach pending suspend/activate
  const [deleting, setDeleting] = useState(null); // coach pending permanent delete
  const [busy, setBusy] = useState(false);
  const [actionError, setActionError] = useState(null);
  const [notify, setNotify] = useState(null); // coach we're composing a notification to

  const filtered = coaches.filter(
    (c) => c.name?.includes(search) || (c.city ?? '').includes(search),
  );

  const toggleAccount = async () => {
    if (!confirm) return;
    setBusy(true);
    try {
      if (confirm.isActive) await adminApi.lockUser(confirm.userId);
      else await adminApi.unlockUser(confirm.userId);
      setConfirm(null);
      refetch();
    } finally {
      setBusy(false);
    }
  };

  const removeCoach = async () => {
    if (!deleting) return;
    setBusy(true);
    setActionError(null);
    try {
      // المعرّف هنا هو userId — الحذف يطال الحساب كاملاً لا ملف المدرب وحده.
      await coachesApi.remove(deleting.userId);
      setDeleting(null);
      refetch();
    } catch (e) {
      setActionError(e?.response?.data?.messageAr || 'تعذّر حذف المدرب');
      setDeleting(null);
    } finally {
      setBusy(false);
    }
  };

  return (
    <div>
      <PageHeader title="المدربون" subtitle={`${coaches.length} مدرب على المنصة`} />

      {actionError && (
        <div className="mb-4 px-4 py-3 bg-red-50 border border-red-100 text-red-600 rounded-xl text-sm">
          {actionError}
        </div>
      )}

      <div className="relative flex-1 mb-5">
        <Search className="absolute right-3 top-1/2 -translate-y-1/2 w-4 h-4 text-gray-400" />
        <input value={search} onChange={(e) => setSearch(e.target.value)}
          placeholder="بحث باسم المدرب أو المدينة..."
          className="w-full pr-9 pl-4 py-2.5 border border-gray-200 rounded-xl text-sm focus:outline-none focus:ring-2 focus:ring-[#2AB5CE] bg-white" />
      </div>

      {loading ? (
        <Spinner />
      ) : error ? (
        <div className="text-center py-16 text-red-500 text-sm">{error}</div>
      ) : filtered.length === 0 ? (
        <Empty icon={UserCheck} text="لا يوجد مدربون" />
      ) : (
        <div className="bg-white rounded-2xl shadow-sm border border-gray-100 overflow-hidden">
          <div className="overflow-x-auto">
            <table className="w-full text-sm">
              <thead>
                <tr className="border-b border-gray-100 bg-gray-50">
                  <Th>المدرب</Th><Th>المدينة</Th><Th>التخصص</Th>
                  <Th>سعر الساعة</Th><Th>التقييم</Th><Th>الطلاب</Th>
                  <Th>الحالة</Th><Th>الإجراءات</Th>
                </tr>
              </thead>
              <tbody className="divide-y divide-gray-50">
                {filtered.map((c, i) => (
                  <tr key={c.id} className="hover:bg-gray-50/50 transition">
                    <td className="px-5 py-4">
                      <div className="flex items-center gap-3">
                        <div className={`w-9 h-9 ${avatarColors[i % avatarColors.length]} rounded-full flex items-center justify-center text-white font-bold text-sm shrink-0`}>
                          {c.name?.[0] ?? '؟'}
                        </div>
                        <div className="flex items-center gap-1.5">
                          <p className="font-semibold text-gray-800">{c.name}</p>
                          {c.isVerified && <BadgeCheck className="w-4 h-4 text-[#2AB5CE]" />}
                        </div>
                      </div>
                    </td>
                    <td className="px-4 py-4 text-gray-600">{c.city ?? '—'}</td>
                    <td className="px-4 py-4 text-gray-600 max-w-xs truncate">{c.specialization ?? '—'}</td>
                    <td className="px-4 py-4 text-gray-600">{Number(c.hourlyRate).toFixed(0)} ر.س</td>
                    <td className="px-4 py-4">
                      <span className="flex items-center gap-1 text-gray-700">
                        <Star className="w-3.5 h-3.5 text-yellow-500" />
                        {Number(c.rating).toFixed(1)} <span className="text-gray-400 text-xs">({c.reviews})</span>
                      </span>
                    </td>
                    <td className="px-4 py-4 text-gray-600">{c.students}</td>
                    <td className="px-4 py-4">
                      <StatusBadge status={c.isActive ? 'active' : 'inactive'} />
                    </td>
                    <td className="px-4 py-4">
                      <div className="flex items-center gap-1.5">
                        <button onClick={() => navigate(`/coaches/${c.id}`)} title="عرض كل بيانات الحساب"
                          className="flex items-center gap-1 px-2.5 py-1.5 rounded-lg text-xs font-medium bg-gray-50 text-gray-600 hover:bg-gray-100 transition">
                          <Eye className="w-3.5 h-3.5" /> تفاصيل
                        </button>
                        <button onClick={() => setNotify(c)} title="إرسال إشعار"
                          className="flex items-center gap-1 px-2.5 py-1.5 rounded-lg text-xs font-medium bg-[#2AB5CE]/10 text-[#2AB5CE] hover:bg-[#2AB5CE]/20 transition">
                          <Bell className="w-3.5 h-3.5" /> إشعار
                        </button>
                        <button onClick={() => setConfirm(c)}
                          title={c.isActive ? 'إيقاف الحساب' : 'تفعيل الحساب'}
                          className={`flex items-center gap-1 px-2.5 py-1.5 rounded-lg text-xs font-medium transition ${c.isActive ? 'bg-red-50 text-red-500 hover:bg-red-100' : 'bg-green-50 text-[#2AB5CE] hover:bg-green-100'}`}>
                          {c.isActive
                            ? <><Ban className="w-3.5 h-3.5" /> إيقاف</>
                            : <><CheckCircle className="w-3.5 h-3.5" /> تفعيل</>}
                        </button>
                        {canDelete && (
                          <button onClick={() => setDeleting(c)} title="حذف الحساب نهائياً"
                            className="flex items-center gap-1 px-2.5 py-1.5 rounded-lg text-xs font-medium bg-red-100 text-red-700 hover:bg-red-200 transition">
                            <Trash2 className="w-3.5 h-3.5" /> حذف
                          </button>
                        )}
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
        title={confirm?.isActive ? 'إيقاف حساب المدرب' : 'تفعيل حساب المدرب'}
        message={confirm?.isActive
          ? `سيتم إيقاف حساب "${confirm?.name}" ومنعه من الدخول للمنصة.`
          : `سيتم إعادة تفعيل حساب "${confirm?.name}".`}
        danger={confirm?.isActive}
        onConfirm={busy ? () => {} : toggleAccount}
        onCancel={() => setConfirm(null)}
      />

      <ConfirmModal
        open={!!deleting}
        title="حذف حساب المدرب نهائياً"
        message={`سيُحذف حساب "${deleting?.name}" نهائياً: تُلغى جلساته القادمة ويُشعَر لاعبوها ويُعاد ما دفعوه، وتُمسح عروضه وبياناته الشخصية ومستنداته. لا يمكن التراجع عن هذه العملية.`}
        onConfirm={busy ? () => {} : removeCoach}
        onCancel={() => setDeleting(null)}
      />

      {notify && (
        <NotifyModal coach={notify} onClose={() => setNotify(null)} />
      )}
    </div>
  );
}

function NotifyModal({ coach, onClose }) {
  const [form, setForm] = useState({ title: '', body: '' });
  const [saving, setSaving] = useState(false);
  const [err, setErr] = useState(null);
  const [done, setDone] = useState(false);

  const valid = form.title.trim() && form.body.trim();

  const submit = async (e) => {
    e.preventDefault();
    if (!valid || saving) return;
    setSaving(true); setErr(null);
    try {
      await adminApi.sendToUser({ userId: coach.userId, title: form.title, body: form.body });
      setDone(true);
      setTimeout(onClose, 900);
    } catch (e2) {
      setErr(e2?.response?.data?.messageAr || 'تعذّر الإرسال');
      setSaving(false);
    }
  };

  return (
    <div className="fixed inset-0 bg-black/50 z-50 flex items-center justify-center p-4">
      <div className="bg-white rounded-2xl shadow-2xl w-full max-w-md">
        <div className="flex items-center justify-between px-6 py-4 border-b border-gray-100">
          <div className="flex items-center gap-2">
            <Bell className="w-5 h-5 text-[#2AB5CE]" />
            <h3 className="font-bold text-gray-800 text-lg">إرسال إشعار إلى {coach.name}</h3>
          </div>
          <button onClick={onClose} className="w-8 h-8 flex items-center justify-center rounded-lg hover:bg-gray-100 text-gray-400">
            <X className="w-5 h-5" />
          </button>
        </div>
        {done ? (
          <div className="p-10 text-center">
            <CheckCircle className="w-12 h-12 text-[#2AB5CE] mx-auto mb-3" />
            <p className="text-gray-700 font-medium">تم إرسال الإشعار</p>
          </div>
        ) : (
          <form onSubmit={submit} className="p-6 space-y-4">
            <div>
              <label className="block text-sm font-medium text-gray-700 mb-1.5">العنوان</label>
              <input className={inputCls} value={form.title}
                onChange={(e) => setForm((f) => ({ ...f, title: e.target.value }))} />
            </div>
            <div>
              <label className="block text-sm font-medium text-gray-700 mb-1.5">النص</label>
              <textarea rows={3} className={`${inputCls} resize-none`} value={form.body}
                onChange={(e) => setForm((f) => ({ ...f, body: e.target.value }))} />
            </div>
            {err && <p className="text-sm text-red-500">{err}</p>}
            <div className="flex gap-3 pt-2">
              <button type="button" onClick={onClose}
                className="flex-1 py-2.5 border border-gray-200 rounded-xl text-gray-600 font-medium hover:bg-gray-50 transition text-sm">إلغاء</button>
              <button type="submit" disabled={!valid || saving}
                className="flex-1 py-2.5 bg-[#2AB5CE] hover:bg-[#1E9AB0] disabled:bg-gray-200 disabled:text-gray-400 text-white font-medium rounded-xl transition text-sm flex items-center justify-center gap-2">
                <Save className="w-4 h-4" /> {saving ? 'جارٍ الإرسال...' : 'إرسال'}
              </button>
            </div>
          </form>
        )}
      </div>
    </div>
  );
}
