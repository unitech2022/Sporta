import { useState } from 'react';
import { useNavigate } from 'react-router-dom';
import { Search, Building2, Eye, LayoutGrid, Clock, Trash2 } from 'lucide-react';
import { venuesApi } from '../api/venuesApi';
import { useApi } from '../hooks/useApi';
import PageHeader from '../components/PageHeader';
import StatusBadge from '../components/StatusBadge';
import Pagination from '../components/Pagination';
import ConfirmModal from '../components/ConfirmModal';
import { Th, Spinner, Empty } from '../components/TableBits';
import { useAuth } from '../context/AuthContext';

const PAGE_SIZE = 15;

export default function VenuesPage() {
  const navigate = useNavigate();
  const { can } = useAuth();
  const canDelete = can('venues.delete');

  const [search, setSearch] = useState('');
  const [query, setQuery] = useState('');
  const [page, setPage] = useState(1);
  const [deleting, setDeleting] = useState(null);
  const [busy, setBusy] = useState(false);
  const [actionError, setActionError] = useState(null);

  const { data, loading, error, refetch } = useApi(
    () => venuesApi.getAll({ search: query || undefined, page, pageSize: PAGE_SIZE }),
    [page, query],
  );

  const venues = data?.items ?? [];
  const total = data?.total ?? 0;
  const totalPages = Math.max(1, Math.ceil(total / PAGE_SIZE));

  const submitSearch = (e) => {
    e.preventDefault();
    setPage(1);
    setQuery(search.trim());
  };

  const remove = async () => {
    if (!deleting) return;
    setBusy(true);
    setActionError(null);
    try {
      await venuesApi.remove(deleting.id);
      setDeleting(null);
      await refetch();
    } catch (e) {
      setActionError(e?.response?.data?.messageAr || 'تعذّر حذف النادي');
      setDeleting(null);
    } finally {
      setBusy(false);
    }
  };

  return (
    <div>
      <PageHeader title="الأندية والملاعب" subtitle={`${total} نادٍ مسجل على المنصة`} />

      {actionError && (
        <div className="mb-4 px-4 py-3 bg-red-50 border border-red-100 text-red-600 rounded-xl text-sm">
          {actionError}
        </div>
      )}

      <form onSubmit={submitSearch} className="flex gap-3 mb-5">
        <div className="relative flex-1">
          <Search className="absolute right-3 top-1/2 -translate-y-1/2 w-4 h-4 text-gray-400" />
          <input value={search} onChange={(e) => setSearch(e.target.value)}
            placeholder="بحث باسم الملعب أو الجوال..."
            className="w-full pr-9 pl-4 py-2.5 border border-gray-200 rounded-xl text-sm focus:outline-none focus:ring-2 focus:ring-[#2AB5CE] bg-white" />
        </div>
        <button type="submit"
          className="px-5 py-2.5 bg-[#2AB5CE] hover:bg-[#1E9AB0] text-white rounded-xl text-sm font-medium shadow transition">
          بحث
        </button>
      </form>

      {loading ? (
        <Spinner />
      ) : error ? (
        <div className="text-center py-16 text-red-500 text-sm">{error}</div>
      ) : venues.length === 0 ? (
        <Empty icon={Building2} text="لا توجد أندية بعد" />
      ) : (
        <div className="bg-white rounded-2xl shadow-sm border border-gray-100 overflow-hidden">
          <div className="overflow-x-auto">
            <table className="w-full text-sm">
              <thead>
                <tr className="border-b border-gray-100 bg-gray-50">
                  <Th>اسم النادي</Th><Th>المدينة</Th><Th>الحي</Th>
                  <Th>عدد الملاعب</Th><Th>الحالة</Th><Th>الإجراءات</Th>
                </tr>
              </thead>
              <tbody className="divide-y divide-gray-50">
                {venues.map((v) => (
                  <tr key={v.id}
                    onClick={() => navigate(`/venues/${v.id}`)}
                    className={`transition cursor-pointer ${v.isApproved ? 'hover:bg-gray-50/50' : 'bg-amber-50/40 hover:bg-amber-50/70'}`}>
                    <td className="px-5 py-4">
                      <div className="flex items-center gap-3">
                        <div className="w-9 h-9 rounded-xl bg-gradient-to-br from-teal-400 to-cyan-600 flex items-center justify-center text-white font-bold shrink-0">
                          {v.name?.[0] ?? '؟'}
                        </div>
                        <div>
                          <p className="font-semibold text-gray-800">{v.name}</p>
                          <p className="text-xs text-gray-400">{v.ownerName}</p>
                        </div>
                      </div>
                    </td>
                    <td className="px-4 py-4 text-gray-600">{v.city || '—'}</td>
                    <td className="px-4 py-4 text-gray-600">{v.district || '—'}</td>
                    <td className="px-4 py-4">
                      <span className="inline-flex items-center gap-1.5 px-2.5 py-1 rounded-lg bg-gray-50 text-gray-700 text-xs font-semibold">
                        <LayoutGrid className="w-3.5 h-3.5 text-gray-400" /> {v.courtsCount}
                      </span>
                    </td>
                    <td className="px-4 py-4">
                      {/* النادي "نشط" فقط حين يكون معتمداً وحساب مالكه فعّالاً — وإلا فهو مخفي عن اللاعبين. */}
                      {!v.isApproved ? (
                        <span className="inline-flex items-center gap-1.5 px-2.5 py-1 rounded-full bg-amber-50 text-amber-700 text-xs font-medium">
                          <Clock className="w-3.5 h-3.5" /> بانتظار الموافقة
                        </span>
                      ) : (
                        <StatusBadge status={v.isActive ? 'active' : 'inactive'}
                          label={v.isActive ? 'نشط' : 'غير نشط'} />
                      )}
                    </td>
                    <td className="px-4 py-4">
                      <div className="flex items-center gap-1.5">
                        <button onClick={(e) => { e.stopPropagation(); navigate(`/venues/${v.id}`); }}
                          title="كل بيانات النادي والملاعب والمستندات والصور"
                          className="flex items-center gap-1 px-3 py-1.5 rounded-lg text-xs font-medium bg-cyan-50 text-[#1E9AB0] hover:bg-cyan-100 transition">
                          <Eye className="w-3.5 h-3.5" /> التفاصيل
                        </button>
                        {canDelete && (
                          <button onClick={(e) => { e.stopPropagation(); setDeleting(v); }}
                            title="حذف النادي وكل ملاعبه"
                            className="flex items-center gap-1 px-3 py-1.5 rounded-lg text-xs font-medium bg-red-50 text-red-600 hover:bg-red-100 transition">
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
          <div className="px-5 pb-4">
            <Pagination page={page} totalPages={totalPages} onPageChange={setPage} totalItems={total} pageSize={PAGE_SIZE} />
          </div>
        </div>
      )}

      <ConfirmModal
        open={!!deleting}
        title="حذف النادي"
        message={`سيُحذف "${deleting?.name}" وكل ملاعبه (${deleting?.courtsCount ?? 0}) من المنصة: تُلغى الحجوزات القادمة ويُعاد ما دفعه اللاعبون إلى محافظهم، ويصل إشعار للملعب. لا يمكن التراجع عن هذه العملية.`}
        onConfirm={busy ? () => {} : remove}
        onCancel={() => setDeleting(null)}
      />
    </div>
  );
}
