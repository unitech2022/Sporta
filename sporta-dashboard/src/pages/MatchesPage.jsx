import { useState } from 'react';
import { Search, Swords, MapPin, Users, Trash2 } from 'lucide-react';
import { matchesApi } from '../api/matchesApi';
import { useApi } from '../hooks/useApi';
import { useAuth } from '../context/AuthContext';
import ConfirmModal from '../components/ConfirmModal';
import PageHeader from '../components/PageHeader';
import StatusBadge from '../components/StatusBadge';
import { Th, Spinner, Empty } from '../components/TableBits';

const statusMap = {
  Open: ['upcoming', 'مفتوحة'],
  Full: ['upcoming', 'مكتملة'],
  InProgress: ['upcoming', 'جارية'],
  Completed: ['completed', 'منتهية'],
  Cancelled: ['inactive', 'ملغاة'],
};

function fmt(iso) {
  const d = new Date(iso);
  if (Number.isNaN(d.getTime())) return '—';
  return d.toLocaleString('ar', { day: 'numeric', month: 'short', hour: '2-digit', minute: '2-digit' });
}

export default function MatchesPage() {
  const [search, setSearch] = useState('');
  const { can } = useAuth();
  const { data, loading, error, refetch } = useApi(() => matchesApi.getAll(), []);
  const matches = data ?? [];

  const canDelete = can('matches.delete');
  const [deleting, setDeleting] = useState(null);
  const [busy, setBusy] = useState(false);
  const [actionError, setActionError] = useState(null);

  const remove = async () => {
    if (!deleting || busy) return;
    setBusy(true);
    setActionError(null);
    try {
      await matchesApi.remove(deleting.id);
      setDeleting(null);
      refetch();
    } catch (err) {
      setActionError(
        err?.response?.data?.messageAr ||
        err?.response?.data?.message ||
        'تعذّر حذف المباراة',
      );
    } finally {
      setBusy(false);
    }
  };

  const filtered = matches.filter(
    (m) => (m.venueName ?? '').includes(search) || (m.city ?? '').includes(search) || (m.matchType ?? '').includes(search),
  );

  return (
    <div>
      <PageHeader title="المباريات" subtitle={`${matches.length} مباراة على المنصة`} />

      <div className="relative flex-1 mb-5">
        <Search className="absolute right-3 top-1/2 -translate-y-1/2 w-4 h-4 text-gray-400" />
        <input value={search} onChange={(e) => setSearch(e.target.value)}
          placeholder="بحث بالنادي أو المدينة أو النوع..."
          className="w-full pr-9 pl-4 py-2.5 border border-gray-200 rounded-xl text-sm focus:outline-none focus:ring-2 focus:ring-[#2AB5CE] bg-white" />
      </div>

      {actionError && (
        <div className="mb-4 rounded-xl border border-red-200 bg-red-50 px-4 py-3 text-sm text-red-600">
          {actionError}
        </div>
      )}

      {loading ? (
        <Spinner />
      ) : error ? (
        <div className="text-center py-16 text-red-500 text-sm">{error}</div>
      ) : filtered.length === 0 ? (
        <Empty icon={Swords} text="لا توجد مباريات" />
      ) : (
        <div className="bg-white rounded-2xl shadow-sm border border-gray-100 overflow-hidden">
          <div className="overflow-x-auto">
            <table className="w-full text-sm">
              <thead>
                <tr className="border-b border-gray-100 bg-gray-50">
                  <Th>النوع</Th><Th>الموعد</Th><Th>الموقع</Th>
                  <Th>اللاعبون</Th><Th>السعر</Th><Th>الحالة</Th>
                  {canDelete && <Th>إجراءات</Th>}
                </tr>
              </thead>
              <tbody className="divide-y divide-gray-50">
                {filtered.map((m) => {
                  const [badge, label] = statusMap[m.status] ?? ['upcoming', m.status];
                  return (
                    <tr key={m.id} className="hover:bg-gray-50/50 transition">
                      <td className="px-5 py-4">
                        <div className="flex items-center gap-3">
                          <div className="w-9 h-9 bg-violet-100 rounded-xl flex items-center justify-center text-violet-600 shrink-0">
                            <Swords className="w-4 h-4" />
                          </div>
                          <p className="font-semibold text-gray-800">{m.matchType}</p>
                        </div>
                      </td>
                      <td className="px-4 py-4 text-gray-600">{fmt(m.scheduledAt)}</td>
                      <td className="px-4 py-4 text-gray-600">
                        <span className="flex items-center gap-1">
                          <MapPin className="w-3.5 h-3.5 text-gray-400" />
                          {[m.venueName, m.city].filter(Boolean).join('، ') || '—'}
                        </span>
                      </td>
                      <td className="px-4 py-4 text-gray-600">
                        <span className="flex items-center gap-1">
                          <Users className="w-3.5 h-3.5 text-gray-400" />
                          {m.currentPlayers}/{m.maxPlayers}
                        </span>
                      </td>
                      <td className="px-4 py-4 text-gray-600">{Number(m.pricePerPlayer).toFixed(0)} ر.س</td>
                      <td className="px-4 py-4"><StatusBadge status={badge} label={label} /></td>
                      {canDelete && (
                        <td className="px-4 py-4">
                          <button
                            onClick={() => { setActionError(null); setDeleting(m); }}
                            className="flex items-center gap-1 px-2.5 py-1.5 rounded-lg bg-red-100 text-red-700 hover:bg-red-200 transition text-xs font-medium">
                            <Trash2 className="w-3.5 h-3.5" /> حذف
                          </button>
                        </td>
                      )}
                    </tr>
                  );
                })}
              </tbody>
            </table>
          </div>
        </div>
      )}

      <ConfirmModal
        open={!!deleting}
        title="حذف المباراة"
        message="ستُحذف المباراة نهائياً من المنصة: يُعاد ما هو محجوز من حصص إلى محافظ اللاعبين ويصلهم إشعار بالإلغاء. لا يمكن التراجع عن هذه العملية."
        onConfirm={remove}
        onCancel={() => setDeleting(null)}
      />
    </div>
  );
}
