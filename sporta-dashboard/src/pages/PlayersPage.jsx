import { useState } from 'react';
import { useNavigate } from 'react-router-dom';
import { Search, ToggleLeft, ToggleRight, Users, Eye, Trash2, SlidersHorizontal } from 'lucide-react';
import { adminApi } from '../api/adminApi';
import { useApi } from '../hooks/useApi';
import PageHeader from '../components/PageHeader';
import StatusBadge from '../components/StatusBadge';
import ConfirmModal from '../components/ConfirmModal';
import Pagination from '../components/Pagination';
import PlayerLevelModal from '../components/PlayerLevelModal';
import { useAuth } from '../context/AuthContext';

const PAGE_SIZE = 15;
const avatarColors = ['bg-indigo-500', 'bg-pink-500', 'bg-teal-500', 'bg-amber-500', 'bg-violet-500'];

export default function PlayersPage() {
  const navigate = useNavigate();
  const { can } = useAuth();
  const canDelete = can('users.delete');
  const canEditLevel = can('users.level.edit');

  const [search, setSearch] = useState('');
  const [query, setQuery] = useState('');
  const [page, setPage] = useState(1);
  const [confirm, setConfirm] = useState(null);   // إيقاف/تفعيل
  const [deleting, setDeleting] = useState(null); // حذف نهائي
  const [busy, setBusy] = useState(false);
  const [actionError, setActionError] = useState(null);
  const [levelFor, setLevelFor] = useState(null);   // تعديل المستوى
  const [levelError, setLevelError] = useState(null);

  const { data, loading, error, refetch } = useApi(
    () => adminApi.getUsers({ role: 'player', search: query || undefined, page, pageSize: PAGE_SIZE }),
    [page, query],
  );

  const users = data?.items ?? [];
  const total = data?.total ?? 0;
  const totalPages = Math.max(1, Math.ceil(total / PAGE_SIZE));

  const submitSearch = (e) => {
    e.preventDefault();
    setPage(1);
    setQuery(search.trim());
  };

  const toggle = async () => {
    if (!confirm) return;
    setBusy(true);
    try {
      const u = confirm.item;
      if (u.isActive) await adminApi.lockUser(u.id);
      else await adminApi.unlockUser(u.id);
      setConfirm(null);
      refetch();
    } finally {
      setBusy(false);
    }
  };

  const remove = async () => {
    if (!deleting) return;
    setBusy(true);
    setActionError(null);
    try {
      await adminApi.deleteUser(deleting.id);
      setDeleting(null);
      refetch();
    } catch (e) {
      setActionError(e?.response?.data?.messageAr || 'تعذّر حذف اللاعب');
      setDeleting(null);
    } finally {
      setBusy(false);
    }
  };

  const saveLevel = async (level) => {
    if (!levelFor) return;
    setBusy(true);
    setLevelError(null);
    try {
      await adminApi.setPlayerLevel(levelFor.id, level);
      setLevelFor(null);
      refetch();
    } catch (e) {
      // رسالة الخادم أولاً؛ وحين لا يردّ أصلاً يُقال ذلك بدل اتهام العملية
      // بالفشل — الفرق بين «رُفض المستوى» و«لم يصل الطلب» هو ما يوجّه المحاولة
      // التالية.
      setLevelError(
        e?.response?.data?.messageAr ||
        e?.response?.data?.message ||
        'تعذّر الاتصال بالخادم — لم يُحفظ المستوى'
      );
    } finally {
      setBusy(false);
    }
  };

  return (
    <div>
      <PageHeader title="اللاعبون" subtitle={`${total} لاعب مسجل في المنصة`} />

      {actionError && (
        <div className="mb-4 px-4 py-3 bg-red-50 border border-red-100 text-red-600 rounded-xl text-sm">
          {actionError}
        </div>
      )}

      <form onSubmit={submitSearch} className="flex gap-3 mb-5">
        <div className="relative flex-1">
          <Search className="absolute right-3 top-1/2 -translate-y-1/2 w-4 h-4 text-gray-400" />
          <input value={search} onChange={(e) => setSearch(e.target.value)}
            placeholder="بحث بالاسم أو الجوال..."
            className="w-full pr-9 pl-4 py-2.5 border border-gray-200 rounded-xl text-sm focus:outline-none focus:ring-2 focus:ring-[#2AB5CE] bg-white" />
        </div>
        <button type="submit"
          className="px-5 py-2.5 bg-[#2AB5CE] hover:bg-[#1E9AB0] text-white rounded-xl text-sm font-medium shadow transition">
          بحث
        </button>
      </form>

      {loading ? (
        <div className="flex justify-center py-20">
          <div className="w-10 h-10 border-4 border-green-200 border-t-[#2AB5CE] rounded-full animate-spin" />
        </div>
      ) : error ? (
        <div className="text-center py-16 text-red-500 text-sm">{error}</div>
      ) : users.length === 0 ? (
        <div className="text-center py-20 text-gray-400">
          <Users className="w-12 h-12 mx-auto mb-3 opacity-30" />
          <p>لا يوجد لاعبون</p>
        </div>
      ) : (
        <div className="bg-white rounded-2xl shadow-sm border border-gray-100 overflow-hidden">
          <div className="overflow-x-auto">
            <table className="w-full text-sm">
              <thead>
                <tr className="border-b border-gray-100 bg-gray-50">
                  <th className="text-right px-5 py-3.5 font-semibold text-gray-600">اللاعب</th>
                  <th className="text-right px-4 py-3.5 font-semibold text-gray-600">الجوال</th>
                  <th className="text-right px-4 py-3.5 font-semibold text-gray-600">المدينة</th>
                  <th className="text-right px-4 py-3.5 font-semibold text-gray-600">المستوى</th>
                  <th className="text-right px-4 py-3.5 font-semibold text-gray-600">الحالة</th>
                  <th className="text-right px-4 py-3.5 font-semibold text-gray-600">الإجراءات</th>
                </tr>
              </thead>
              <tbody className="divide-y divide-gray-50">
                {users.map((u, i) => (
                  <tr key={u.id} className="hover:bg-gray-50/50 transition">
                    <td className="px-5 py-4">
                      <div className="flex items-center gap-3">
                        <div className={`w-9 h-9 ${avatarColors[i % avatarColors.length]} rounded-full flex items-center justify-center text-white font-bold text-sm shrink-0`}>
                          {u.fullName?.[0] ?? '؟'}
                        </div>
                        <div>
                          <p className="font-semibold text-gray-800">{u.fullName}</p>
                        </div>
                      </div>
                    </td>
                    <td className="px-4 py-4 text-gray-600">{u.phone}</td>
                    <td className="px-4 py-4 text-gray-600">{u.city ?? '—'}</td>
                    <td className="px-4 py-4">
                      <div className="flex items-center gap-1.5">
                        {u.level
                          ? <span className="px-2.5 py-1 rounded-full text-xs font-medium bg-indigo-100 text-indigo-700">مستوى {u.level}</span>
                          : <span className="text-gray-400 text-xs">غير مُقيّم</span>}
                        {canEditLevel && (
                          <button onClick={() => { setLevelError(null); setLevelFor(u); }} title="تعديل المستوى"
                            className="w-7 h-7 flex items-center justify-center rounded-lg text-gray-400 hover:bg-gray-100 hover:text-gray-600 transition">
                            <SlidersHorizontal className="w-3.5 h-3.5" />
                          </button>
                        )}
                      </div>
                    </td>
                    <td className="px-4 py-4">
                      <StatusBadge status={u.isActive ? 'active' : 'inactive'} />
                    </td>
                    <td className="px-4 py-4">
                      <div className="flex items-center gap-1.5">
                        <button onClick={() => navigate(`/players/${u.id}`)} title="عرض كل بيانات الحساب"
                          className="flex items-center gap-1 px-2.5 py-1.5 rounded-lg text-xs font-medium bg-gray-50 text-gray-600 hover:bg-gray-100 transition">
                          <Eye className="w-3.5 h-3.5" /> تفاصيل
                        </button>
                        <button onClick={() => setConfirm({ item: u })}
                          className={`flex items-center gap-1 px-2.5 py-1.5 rounded-lg text-xs font-medium transition ${u.isActive ? 'bg-yellow-50 text-yellow-600 hover:bg-yellow-100' : 'bg-green-50 text-[#2AB5CE] hover:bg-green-100'}`}>
                          {u.isActive ? <><ToggleRight className="w-3.5 h-3.5" />إيقاف</> : <><ToggleLeft className="w-3.5 h-3.5" />تفعيل</>}
                        </button>
                        {canDelete && (
                          <button onClick={() => setDeleting(u)} title="حذف الحساب نهائياً"
                            className="flex items-center gap-1 px-2.5 py-1.5 rounded-lg text-xs font-medium bg-red-50 text-red-600 hover:bg-red-100 transition">
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
          <div className="px-5 py-4 border-t border-gray-100">
            <Pagination page={page} totalPages={totalPages} onPageChange={setPage} totalItems={total} pageSize={PAGE_SIZE} />
          </div>
        </div>
      )}

      <ConfirmModal
        open={!!confirm}
        title={confirm?.item?.isActive ? 'إيقاف اللاعب' : 'تفعيل اللاعب'}
        message={confirm?.item?.isActive
          ? `سيتم إيقاف حساب "${confirm?.item?.fullName}" ومنعه من الدخول.`
          : `سيتم إعادة تفعيل حساب "${confirm?.item?.fullName}".`}
        danger={confirm?.item?.isActive}
        onConfirm={busy ? () => {} : toggle}
        onCancel={() => setConfirm(null)}
      />

      <PlayerLevelModal
        open={!!levelFor}
        player={levelFor}
        saving={busy}
        error={levelError}
        onSave={saveLevel}
        onClose={() => setLevelFor(null)}
      />

      <ConfirmModal
        open={!!deleting}
        title="حذف اللاعب نهائياً"
        message={`سيُحذف حساب "${deleting?.fullName}" نهائياً: تُلغى حجوزاته وجلساته القادمة ويُعاد ما دفعه إلى محفظته، وتُمسح بياناته الشخصية وصوره. لا يمكن التراجع عن هذه العملية.`}
        onConfirm={busy ? () => {} : remove}
        onCancel={() => setDeleting(null)}
      />
    </div>
  );
}
