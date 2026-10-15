import { useState } from 'react';
import { useNavigate } from 'react-router-dom';
import { Search, Users, Eye, ToggleLeft, ToggleRight, BadgeCheck, Trash2 } from 'lucide-react';
import { adminApi } from '../api/adminApi';
import { useApi } from '../hooks/useApi';
import PageHeader from '../components/PageHeader';
import StatusBadge from '../components/StatusBadge';
import ConfirmModal from '../components/ConfirmModal';
import Pagination from '../components/Pagination';
import { Th, Spinner, Empty } from '../components/TableBits';
import { Avatar } from '../components/DetailBits';
import { roleLabels, formatDate } from '../utils/accountLabels';
import { useAuth } from '../context/AuthContext';

const PAGE_SIZE = 15;

/** فلاتر الدور — القيم كما يفهمها GET /api/admin/users?role=. */
const roleFilters = [
  { key: '', label: 'الكل' },
  { key: 'player', label: 'لاعبون' },
  { key: 'coach', label: 'مدربون' },
  { key: 'venue', label: 'ملاعب' },
  { key: 'staff', label: 'موظفون' },
  { key: 'admin', label: 'مشرفون' },
];

/** قسم «المستخدمون»: كل الحسابات على المنصة مهما كان دورها. */
export default function UsersPage() {
  const navigate = useNavigate();
  const { can } = useAuth();
  const canDelete = can('users.delete');

  const [search, setSearch] = useState('');
  const [query, setQuery] = useState('');
  const [role, setRole] = useState('');
  const [page, setPage] = useState(1);
  const [confirm, setConfirm] = useState(null);
  // { user, role } — اعتماد حساب مدرب/ملعب بعد مراجعة بياناته.
  const [approving, setApproving] = useState(null);
  const [deleting, setDeleting] = useState(null); // حذف نهائي
  const [busy, setBusy] = useState(false);
  const [actionError, setActionError] = useState(null);

  const { data, loading, error, refetch } = useApi(
    () => adminApi.getUsers({
      role: role || undefined,
      search: query || undefined,
      page,
      pageSize: PAGE_SIZE,
    }),
    [page, query, role],
  );

  const users = data?.items ?? [];
  const total = data?.total ?? 0;
  const totalPages = Math.max(1, Math.ceil(total / PAGE_SIZE));

  const submitSearch = (e) => {
    e.preventDefault();
    setPage(1);
    setQuery(search.trim());
  };

  const pickRole = (key) => {
    setPage(1);
    setRole(key);
  };

  const toggle = async () => {
    if (!confirm) return;
    setBusy(true);
    try {
      if (confirm.isActive) await adminApi.lockUser(confirm.id);
      else await adminApi.unlockUser(confirm.id);
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
      setActionError(e?.response?.data?.messageAr || 'تعذّر حذف الحساب');
      setDeleting(null);
    } finally {
      setBusy(false);
    }
  };

  const approve = async () => {
    if (!approving) return;
    setBusy(true);
    try {
      await adminApi.approveUserRole(approving.user.id, approving.role, true);
      setApproving(null);
      refetch();
    } finally {
      setBusy(false);
    }
  };

  return (
    <div>
      <PageHeader title="المستخدمون" subtitle={`${total} حساب على المنصة`} />

      {actionError && (
        <div className="mb-4 px-4 py-3 bg-red-50 border border-red-100 text-red-600 rounded-xl text-sm">
          {actionError}
        </div>
      )}

      <form onSubmit={submitSearch} className="flex gap-3 mb-4">
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

      <div className="flex flex-wrap gap-2 mb-5">
        {roleFilters.map((f) => (
          <button key={f.key || 'all'} onClick={() => pickRole(f.key)}
            className={`px-3.5 py-1.5 rounded-full text-xs font-medium transition ${role === f.key ? 'bg-[#2AB5CE] text-white shadow' : 'bg-white border border-gray-200 text-gray-600 hover:bg-gray-50'}`}>
            {f.label}
          </button>
        ))}
      </div>

      {loading ? (
        <Spinner />
      ) : error ? (
        <div className="text-center py-16 text-red-500 text-sm">{error}</div>
      ) : users.length === 0 ? (
        <Empty icon={Users} text="لا يوجد مستخدمون" />
      ) : (
        <div className="bg-white rounded-2xl shadow-sm border border-gray-100 overflow-hidden">
          <div className="overflow-x-auto">
            <table className="w-full text-sm">
              <thead>
                <tr className="border-b border-gray-100 bg-gray-50">
                  <Th>المستخدم</Th><Th>الجوال</Th><Th>الأدوار</Th>
                  <Th>المدينة</Th><Th>الانضمام</Th><Th>الحالة</Th><Th>الإجراءات</Th>
                </tr>
              </thead>
              <tbody className="divide-y divide-gray-50">
                {users.map((u) => (
                  <tr key={u.id} className="hover:bg-gray-50/50 transition">
                    <td className="px-5 py-4">
                      <div className="flex items-center gap-3">
                        <Avatar url={u.avatarUrl} name={u.fullName} size="w-9 h-9 text-sm" />
                        <div>
                          <p className="font-semibold text-gray-800">{u.fullName}</p>
                        </div>
                      </div>
                    </td>
                    <td className="px-4 py-4 text-gray-600" dir="ltr">{u.phone}</td>
                    <td className="px-4 py-4">
                      <div className="flex flex-wrap gap-1">
                        {(u.roles ?? []).map((r) => {
                          const pending = (u.pendingRoles ?? []).includes(r);
                          return (
                            <span key={r}
                              className={`px-2 py-0.5 rounded-full text-xs ${pending ? 'bg-amber-50 text-amber-700 border border-amber-200' : 'bg-gray-100 text-gray-600'}`}>
                              {roleLabels[r] ?? r}{pending ? ' · قيد المراجعة' : ''}
                            </span>
                          );
                        })}
                      </div>
                    </td>
                    <td className="px-4 py-4 text-gray-600">{u.city ?? '—'}</td>
                    <td className="px-4 py-4 text-gray-500 text-xs">{formatDate(u.createdAt)}</td>
                    <td className="px-4 py-4">
                      <StatusBadge status={u.isActive ? 'active' : 'inactive'} />
                    </td>
                    <td className="px-4 py-4">
                      <div className="flex items-center gap-1.5">
                        {(u.pendingRoles ?? []).map((r) => (
                          <button key={r} onClick={() => setApproving({ user: u, role: r })}
                            title={`اعتماد حساب ${roleLabels[r] ?? r} بعد مراجعة بياناته`}
                            className="flex items-center gap-1 px-2.5 py-1.5 rounded-lg text-xs font-medium bg-green-50 text-green-700 hover:bg-green-100 transition">
                            <BadgeCheck className="w-3.5 h-3.5" /> اعتماد {roleLabels[r] ?? r}
                          </button>
                        ))}
                        <button onClick={() => navigate(`/users/${u.id}`)} title="عرض كل بيانات الحساب"
                          className="flex items-center gap-1 px-2.5 py-1.5 rounded-lg text-xs font-medium bg-gray-50 text-gray-600 hover:bg-gray-100 transition">
                          <Eye className="w-3.5 h-3.5" /> تفاصيل
                        </button>
                        <button onClick={() => setConfirm(u)}
                          className={`flex items-center gap-1 px-2.5 py-1.5 rounded-lg text-xs font-medium transition ${u.isActive ? 'bg-yellow-50 text-yellow-600 hover:bg-yellow-100' : 'bg-green-50 text-[#2AB5CE] hover:bg-green-100'}`}>
                          {u.isActive ? <><ToggleRight className="w-3.5 h-3.5" />إيقاف</> : <><ToggleLeft className="w-3.5 h-3.5" />تفعيل</>}
                        </button>
                        {/* حسابات الإدارة تُحذف من شاشة الموظفين — الخادم يرفضها هنا. */}
                        {canDelete && !(u.roles ?? []).some(r => r === 'admin' || r === 'staff') && (
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
        title={confirm?.isActive ? 'إيقاف الحساب' : 'تفعيل الحساب'}
        message={confirm?.isActive
          ? `سيتم إيقاف حساب "${confirm?.fullName}" ومنعه من الدخول.`
          : `سيتم إعادة تفعيل حساب "${confirm?.fullName}".`}
        danger={confirm?.isActive}
        onConfirm={busy ? () => {} : toggle}
        onCancel={() => setConfirm(null)}
      />

      <ConfirmModal
        open={!!approving}
        title="اعتماد الحساب"
        message={`سيتم تفعيل حساب ${roleLabels[approving?.role] ?? ''} لـ "${approving?.user?.fullName}" وإشعاره بالموافقة.`}
        onConfirm={busy ? () => {} : approve}
        onCancel={() => setApproving(null)}
      />

      <ConfirmModal
        open={!!deleting}
        title="حذف الحساب نهائياً"
        message={`سيُحذف حساب "${deleting?.fullName}" نهائياً: تُلغى حجوزاته وجلساته القادمة ويُعاد ما دُفع، وتُمسح بياناته الشخصية وملفاته المرفوعة. لو كان يملك أندية فستُحذف هي وملاعبها. لا يمكن التراجع عن هذه العملية.`}
        onConfirm={busy ? () => {} : remove}
        onCancel={() => setDeleting(null)}
      />
    </div>
  );
}
