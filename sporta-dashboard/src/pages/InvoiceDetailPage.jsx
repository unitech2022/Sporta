import { useParams, useNavigate } from 'react-router-dom';
import { ArrowRight, User, Building2, Calendar, Hash, Download } from 'lucide-react';
import { adminApi } from '../api/adminApi';
import { useApi } from '../hooks/useApi';
import StatusBadge from '../components/StatusBadge';
import { Spinner } from '../components/TableBits';
import { downloadInvoicePdf } from '../utils/invoicePdf';

const STATUS_INFO = {
  Pending:   { label: 'بانتظار الموافقة', color: 'bg-yellow-50 border-yellow-200 text-yellow-700', emoji: '⏳' },
  Confirmed: { label: 'حجز مؤكّد',        color: 'bg-green-50 border-green-200 text-green-700',  emoji: '✅' },
  Cancelled: { label: 'ملغي',              color: 'bg-red-50 border-red-200 text-red-600',        emoji: '⚠️' },
  Completed: { label: 'مكتمل',             color: 'bg-blue-50 border-blue-200 text-blue-700',      emoji: '✅' },
};
const STATUS_BADGE_MAP = { Pending: 'pending', Confirmed: 'active', Cancelled: 'inactive', Completed: 'completed' };

const fmt = (iso) => iso ? new Date(iso).toLocaleDateString('ar-SA', { year: 'numeric', month: 'short', day: 'numeric' }) : '-';
const fmtTime = (iso) => iso ? new Date(iso).toLocaleTimeString('ar-SA', { hour: '2-digit', minute: '2-digit' }) : '';

export default function InvoiceDetailPage() {
  const { id } = useParams();
  const navigate = useNavigate();

  const { data: booking, loading, error } = useApi(() => adminApi.getBooking(id), [id]);

  if (loading) return <Spinner />;
  if (error || !booking) return (
    <div className="text-center py-20 text-gray-400">
      <p>الفاتورة غير موجودة</p>
      <button onClick={() => navigate('/invoices')} className="mt-3 text-[#2AB5CE] hover:underline text-sm">العودة للفواتير</button>
    </div>
  );

  const info = STATUS_INFO[booking.status] ?? STATUS_INFO.Pending;

  return (
    <div>
      <div className="flex items-center justify-between mb-5">
        <button onClick={() => navigate('/invoices')} className="flex items-center gap-2 text-sm text-gray-500 hover:text-gray-700">
          <ArrowRight className="w-4 h-4" /> العودة للفواتير
        </button>
        <button onClick={() => downloadInvoicePdf(booking)}
          className="flex items-center gap-2 px-4 py-2.5 bg-[#2AB5CE] hover:bg-[#1E9AB0] text-white rounded-xl text-sm font-semibold shadow-sm transition">
          <Download className="w-4 h-4" /> تحميل PDF
        </button>
      </div>

      <div className="grid grid-cols-1 lg:grid-cols-3 gap-5">
        <div className="lg:col-span-2 space-y-4">
          <div className={`border rounded-2xl px-5 py-4 flex items-center gap-3 ${info.color}`}>
            <div className="text-lg">{info.emoji}</div>
            <div>
              <p className="font-semibold">{info.label}</p>
              <p className="text-sm opacity-75">حجز رقم #{booking.id.toString().padStart(4, '0')}</p>
            </div>
            <div className="mr-auto">
              <StatusBadge status={STATUS_BADGE_MAP[booking.status] ?? 'pending'} />
            </div>
          </div>

          <div className="bg-white rounded-2xl shadow-sm border border-gray-100 overflow-hidden">
            <div className="bg-gray-800 text-white px-6 py-5 flex items-center justify-between">
              <div>
                <p className="text-gray-400 text-xs mb-1">رقم الحجز</p>
                <p className="font-mono font-bold text-lg">#{booking.id.toString().padStart(4, '0')}</p>
              </div>
              <div className="text-left">
                <p className="text-gray-400 text-xs mb-1">المبلغ الإجمالي</p>
                <p className="font-black text-2xl">{booking.totalPrice.toLocaleString()} <span className="text-sm font-normal text-gray-400">ر.س</span></p>
              </div>
            </div>

            <div className="p-6">
              <div className="grid grid-cols-1 sm:grid-cols-2 gap-4">
                {[
                  { label: 'اللاعب', value: booking.userName || '-', icon: <User className="w-4 h-4 text-gray-400" /> },
                  { label: 'الملعب', value: `${booking.courtName} — ${booking.venueName}`, icon: <Building2 className="w-4 h-4 text-gray-400" /> },
                  { label: 'التاريخ', value: fmt(booking.startTime), icon: <Calendar className="w-4 h-4 text-gray-400" /> },
                  { label: 'الوقت', value: `${fmtTime(booking.startTime)} – ${fmtTime(booking.endTime)}`, icon: <Calendar className="w-4 h-4 text-gray-400" /> },
                  { label: 'المدة', value: `${booking.durationMinutes} دقيقة` },
                  { label: 'الدفع', value: booking.paidFullAmount ? 'مدفوع بالكامل' : 'غير مكتمل الدفع' },
                  { label: 'المدينة', value: booking.city || '-' },
                  { label: 'رقم الحجز', value: `#${booking.id.toString().padStart(4, '0')}`, icon: <Hash className="w-4 h-4 text-gray-400" /> },
                  { label: 'الحالة', value: <StatusBadge status={STATUS_BADGE_MAP[booking.status] ?? 'pending'} /> },
                ].map(row => (
                  <div key={row.label} className="flex items-center justify-between py-3 border-b border-gray-50">
                    <span className="text-sm text-gray-500 flex items-center gap-2">{row.icon}{row.label}</span>
                    <span className="text-sm font-semibold text-gray-800">{row.value}</span>
                  </div>
                ))}
              </div>
            </div>
          </div>
        </div>

        <div className="space-y-4">
          <div className="bg-white rounded-2xl shadow-sm border border-gray-100 p-5">
            <h3 className="font-bold text-gray-800 mb-4">ملخص المبلغ</h3>
            <div className="space-y-3">
              <div className="flex justify-between py-2">
                <span className="text-sm font-bold text-gray-700">الإجمالي المدفوع</span>
                <span className="text-base font-black text-green-700">{booking.totalPrice.toLocaleString()} ر.س</span>
              </div>
            </div>
          </div>

          <div className="bg-white rounded-2xl shadow-sm border border-gray-100 p-5">
            <h3 className="font-bold text-gray-800 mb-3">معلومات الحجز</h3>
            <div className="bg-gray-50 rounded-xl p-4 space-y-2">
              <div className="flex justify-between text-sm">
                <span className="text-gray-500">التاريخ</span>
                <span className="font-medium text-gray-800">{fmt(booking.startTime)}</span>
              </div>
              <div className="flex justify-between text-sm">
                <span className="text-gray-500">الحالة</span>
                <span className="font-medium text-gray-800">{info.label}</span>
              </div>
            </div>
          </div>
        </div>
      </div>
    </div>
  );
}
