import { useState, useEffect, useCallback } from 'react';
import { useNavigate } from 'react-router-dom';
import { Search, Eye, RefreshCw, FileText, Calendar, Download } from 'lucide-react';
import { adminApi } from '../api/adminApi';
import { downloadInvoicePdf } from '../utils/invoicePdf';
import PageHeader from '../components/PageHeader';
import StatusBadge from '../components/StatusBadge';
import Pagination from '../components/Pagination';
import { LoadingTable, ErrorState } from '../components/ApiState';

const PAGE_SIZE = 10;

const STATUS_OPTIONS = [
  { value: '', label: 'الكل' },
  { value: 'Pending',   label: 'قيد الانتظار' },
  { value: 'Confirmed', label: 'مؤكد' },
  { value: 'Cancelled', label: 'ملغي' },
  { value: 'Completed', label: 'مكتمل' },
];

const STATUS_BADGE_MAP = {
  Pending:   'pending',
  Confirmed: 'active',
  Cancelled: 'inactive',
  Completed: 'completed',
};

export default function InvoicesPage() {
  const navigate = useNavigate();

  const [bookings, setBookings] = useState([]);
  const [total, setTotal]       = useState(0);
  const [loading, setLoading]   = useState(true);
  const [error, setError]       = useState(null);

  const [search, setSearch] = useState('');
  const [status, setStatus] = useState('');
  const [page, setPage]     = useState(1);

  const fetchBookings = useCallback(async () => {
    setLoading(true);
    setError(null);
    try {
      const params = { page, pageSize: PAGE_SIZE };
      if (status) params.status = status;
      const res = await adminApi.getBookings(params);
      const result = res.data.data ?? res.data;
      setBookings(result.items ?? []);
      setTotal(result.total ?? 0);
    } catch (err) {
      setError(err?.response?.data?.messageAr || err?.response?.data?.message || 'تعذّر تحميل الحجوزات');
    } finally {
      setLoading(false);
    }
  }, [page, status]);

  useEffect(() => { fetchBookings(); }, [fetchBookings]);

  const handleStatusChange = (v) => { setStatus(v); setPage(1); };

  const filtered = bookings.filter(b =>
    !search ||
    b.courtName?.includes(search) ||
    b.venueName?.includes(search) ||
    b.userName?.includes(search) ||
    String(b.id).includes(search)
  );

  const totalPages = Math.ceil(total / PAGE_SIZE);

  const fmt = (iso) => iso ? new Date(iso).toLocaleDateString('ar-SA', { year: 'numeric', month: 'short', day: 'numeric' }) : '-';
  const fmtTime = (iso) => iso ? new Date(iso).toLocaleTimeString('ar-SA', { hour: '2-digit', minute: '2-digit' }) : '';

  return (
    <div>
      <PageHeader
        title="الحجوزات والفواتير"
        subtitle={loading ? 'جاري التحميل...' : `${total} حجز`}
        action={
          <button onClick={fetchBookings} disabled={loading}
            className="flex items-center gap-2 px-4 py-2.5 bg-white border border-gray-200 text-gray-600 hover:bg-gray-50 rounded-xl text-sm font-medium transition disabled:opacity-50">
            <RefreshCw className={`w-4 h-4 ${loading ? 'animate-spin' : ''}`} /> تحديث
          </button>
        }
      />

      {/* Filters */}
      <div className="flex flex-col sm:flex-row gap-3 mb-5 flex-wrap">
        <div className="relative flex-1 min-w-52">
          <Search className="absolute right-3 top-1/2 -translate-y-1/2 w-4 h-4 text-gray-400" />
          <input value={search} onChange={e => setSearch(e.target.value)}
            placeholder="بحث برقم الحجز أو اسم اللاعب أو الملعب..."
            className="w-full pr-9 pl-4 py-2.5 border border-gray-200 rounded-xl text-sm focus:outline-none focus:ring-2 focus:ring-[#2AB5CE] bg-white" />
        </div>

        <div className="flex gap-2 flex-wrap">
          {STATUS_OPTIONS.map(({ value, label }) => (
            <button key={value} onClick={() => handleStatusChange(value)}
              className={`px-4 py-2.5 rounded-xl text-sm font-medium transition ${status === value ? 'bg-[#2AB5CE] text-white shadow' : 'bg-white border border-gray-200 text-gray-600 hover:bg-gray-50'}`}>
              {label}
            </button>
          ))}
        </div>
      </div>

      {loading ? (
        <LoadingTable rows={6} cols={8} />
      ) : error ? (
        <ErrorState message={error} onRetry={fetchBookings} />
      ) : filtered.length === 0 ? (
        <div className="text-center py-20 text-gray-400">
          <FileText className="w-12 h-12 mx-auto mb-3 opacity-30" />
          <p>لا توجد حجوزات مطابقة</p>
        </div>
      ) : (
        <div className="bg-white rounded-2xl shadow-sm border border-gray-100 overflow-hidden">
          <div className="overflow-x-auto">
            <table className="w-full text-sm">
              <thead>
                <tr className="border-b border-gray-100 bg-gray-50">
                  <th className="text-right px-5 py-3.5 font-semibold text-gray-600">رقم الحجز</th>
                  <th className="text-right px-4 py-3.5 font-semibold text-gray-600">اللاعب</th>
                  <th className="text-right px-4 py-3.5 font-semibold text-gray-600">الملعب</th>
                  <th className="text-right px-4 py-3.5 font-semibold text-gray-600">التاريخ</th>
                  <th className="text-right px-4 py-3.5 font-semibold text-gray-600">الوقت</th>
                  <th className="text-right px-4 py-3.5 font-semibold text-gray-600">المدة</th>
                  <th className="text-right px-4 py-3.5 font-semibold text-gray-600">المبلغ</th>
                  <th className="text-right px-4 py-3.5 font-semibold text-gray-600">الحالة</th>
                  <th className="text-right px-4 py-3.5 font-semibold text-gray-600">إجراء</th>
                </tr>
              </thead>
              <tbody className="divide-y divide-gray-50">
                {filtered.map(booking => (
                  <tr key={booking.id} className="hover:bg-gray-50/50 transition">
                    <td className="px-5 py-4">
                      <span className="font-mono text-gray-500 text-xs">#{booking.id}</span>
                    </td>
                    <td className="px-4 py-4 text-gray-700">{booking.userName ?? '-'}</td>
                    <td className="px-4 py-4">
                      <div>
                        <p className="font-semibold text-gray-800">{booking.courtName ?? '-'}</p>
                        <p className="text-xs text-gray-400">{booking.venueName ?? ''}</p>
                      </div>
                    </td>
                    <td className="px-4 py-4">
                      <span className="flex items-center gap-1 text-gray-600 text-xs">
                        <Calendar className="w-3 h-3 shrink-0" />
                        {fmt(booking.startTime ?? booking.bookingDate)}
                      </span>
                    </td>
                    <td className="px-4 py-4 text-gray-600 text-xs">
                      {fmtTime(booking.startTime)}{booking.endTime ? ` – ${fmtTime(booking.endTime)}` : ''}
                    </td>
                    <td className="px-4 py-4 text-gray-600 text-xs">
                      {booking.durationMinutes ? `${booking.durationMinutes} د` : '-'}
                    </td>
                    <td className="px-4 py-4 font-semibold text-green-700">
                      {(booking.totalPrice ?? booking.price) != null
                        ? `${booking.totalPrice ?? booking.price} ر.س`
                        : '-'}
                    </td>
                    <td className="px-4 py-4">
                      <StatusBadge
                        status={STATUS_BADGE_MAP[booking.status] ?? 'pending'}
                        label={STATUS_OPTIONS.find(s => s.value === booking.status)?.label ?? booking.status}
                      />
                    </td>
                    <td className="px-4 py-4">
                      <div className="flex items-center gap-1.5">
                        <button onClick={() => navigate(`/invoices/${booking.id}`)}
                          className="flex items-center gap-1 px-3 py-1.5 rounded-lg bg-blue-50 text-blue-600 hover:bg-blue-100 transition text-xs font-medium">
                          <Eye className="w-3.5 h-3.5" /> عرض
                        </button>
                        <button onClick={() => downloadInvoicePdf(booking)} title="تحميل PDF"
                          className="flex items-center gap-1 px-3 py-1.5 rounded-lg bg-[#E8F8FB] text-[#1E9AB0] hover:bg-[#C5EDF5] transition text-xs font-medium">
                          <Download className="w-3.5 h-3.5" /> PDF
                        </button>
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
    </div>
  );
}
