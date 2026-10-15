import { useState, useEffect } from 'react';
import { useParams, useNavigate } from 'react-router-dom';
import { ArrowRight, MapPin, DollarSign, Clock, Calendar, CalendarDays, Building2, RefreshCw, Percent, Check, Trash2 } from 'lucide-react';
import { courtsApi } from '../api/courtsApi';
import StatusBadge from '../components/StatusBadge';
import ConfirmModal from '../components/ConfirmModal';
import { LoadingTable, ErrorState } from '../components/ApiState';
import { useAuth } from '../context/AuthContext';

const today = new Date().toISOString().split('T')[0];

const DAY_NAMES = ['الأحد', 'الاثنين', 'الثلاثاء', 'الأربعاء', 'الخميس', 'الجمعة', 'السبت'];

const hhmm = (h) => `${String(h).padStart(2, '0')}:00`;

function adjustmentLabel(percent) {
  const value = Number(percent ?? 0);
  if (value === 0) return 'بدون تغيير';
  return `${value > 0 ? '+' : '−'}${Math.abs(value).toFixed(0)}%`;
}

export default function CourtDetailPage() {
  const { id } = useParams();
  const navigate = useNavigate();
  const { can } = useAuth();
  const canDelete = can('courts.delete');

  const [deleting, setDeleting] = useState(false);
  const [deleteBusy, setDeleteBusy] = useState(false);
  const [deleteError, setDeleteError] = useState(null);

  const [court, setCourt]               = useState(null);
  const [courtLoading, setCourtLoading] = useState(true);
  const [courtError, setCourtError]     = useState(null);

  const [date, setDate]                   = useState(today);
  const [slots, setSlots]                 = useState([]);
  const [dayClosed, setDayClosed]         = useState(false);
  const [slotsLoading, setSlotsLoading]   = useState(false);
  const [slotsError, setSlotsError]       = useState(null);

  const [commission, setCommission]             = useState('');
  const [commissionSaving, setCommissionSaving] = useState(false);
  const [commissionError, setCommissionError]   = useState(null);
  const [commissionSaved, setCommissionSaved]   = useState(false);

  const saveCommission = () => {
    const percent = Number(commission);
    if (Number.isNaN(percent) || percent < 0 || percent > 100) {
      setCommissionError('أدخل نسبة بين 0 و 100');
      return;
    }
    setCommissionSaving(true);
    setCommissionError(null);
    setCommissionSaved(false);
    courtsApi.updateCommission(id, percent)
      .then(() => courtsApi.getById(id))
      .then(res => {
        setCourt(res.data.data);
        setCommissionSaved(true);
      })
      .catch(err => setCommissionError(err?.response?.data?.messageAr || 'تعذّر حفظ النسبة'))
      .finally(() => setCommissionSaving(false));
  };

  // Fetch court details
  useEffect(() => {
    setCourtLoading(true);
    courtsApi.getById(id)
      .then(res => {
        setCourt(res.data.data);
        setCommission(String(res.data.data?.sportaCommissionPercent ?? 0));
      })
      .catch(err => setCourtError(err?.response?.data?.messageAr || 'تعذّر تحميل بيانات الملعب'))
      .finally(() => setCourtLoading(false));
  }, [id]);

  // Fetch availability when date changes
  useEffect(() => {
    if (!date) return;
    setSlotsLoading(true);
    setSlotsError(null);
    courtsApi.getAvailability(id, date)
      .then(res => {
        setSlots(res.data.data?.slots ?? []);
        setDayClosed(res.data.data?.isClosed === true);
      })
      .catch(err => setSlotsError(err?.response?.data?.messageAr || 'تعذّر تحميل المواعيد'))
      .finally(() => setSlotsLoading(false));
  }, [id, date]);

  if (courtLoading) return (
    <div className="space-y-4">
      <div className="h-8 bg-gray-100 rounded-xl w-32 animate-pulse" />
      <LoadingTable rows={4} cols={3} />
    </div>
  );

  if (courtError) return <ErrorState message={courtError} onRetry={() => window.location.reload()} />;

  if (!court) return null;

  const genderLabel = { all: 'مختلط', men: 'رجال', women: 'نساء', family: 'عائلي' }[court.gender] ?? court.gender;

  const removeCourt = async () => {
    setDeleteBusy(true);
    setDeleteError(null);
    setDeleting(false);
    try {
      await courtsApi.remove(id);
      navigate(court.venueId ? `/venues/${court.venueId}` : '/venues');
    } catch (e) {
      setDeleteError(e?.response?.data?.messageAr || 'تعذّر حذف الملعب');
      setDeleteBusy(false);
    }
  };

  return (
    <div>
      {/* الملاعب تُفتح من داخل ناديها بعد دمج القسمين، فالرجوع يعود للنادي نفسه. */}
      <div className="flex items-center justify-between mb-5">
        <button onClick={() => navigate(court.venueId ? `/venues/${court.venueId}` : '/venues')}
          className="flex items-center gap-2 text-sm text-gray-500 hover:text-gray-700">
          <ArrowRight className="w-4 h-4" /> العودة إلى {court.venueName || 'النادي'}
        </button>
        {canDelete && (
          <button disabled={deleteBusy} onClick={() => setDeleting(true)}
            className="flex items-center gap-1.5 px-4 py-2 rounded-xl bg-red-50 text-red-600 hover:bg-red-100 transition text-sm font-medium disabled:opacity-50">
            <Trash2 className="w-4 h-4" /> حذف الملعب
          </button>
        )}
      </div>

      {deleteError && (
        <div className="mb-4 px-4 py-3 bg-red-50 border border-red-100 text-red-600 rounded-xl text-sm">
          {deleteError}
        </div>
      )}

      <div className="grid grid-cols-1 lg:grid-cols-3 gap-5">
        {/* Main */}
        <div className="lg:col-span-2 space-y-4">
          {/* Hero */}
          <div className="bg-white rounded-2xl shadow-sm border border-gray-100 overflow-hidden">
            {court.imageUrl ? (
              <img src={court.imageUrl} alt={court.name} className="w-full h-52 object-cover" />
            ) : (
              <div className="h-52 bg-gradient-to-br from-green-400 to-emerald-600 flex items-center justify-center">
                <Building2 className="w-20 h-20 text-white/40" />
              </div>
            )}
            <div className="p-6">
              <div className="flex items-start justify-between mb-2">
                <h2 className="text-2xl font-bold text-gray-800">{court.name}</h2>
                <StatusBadge status={court.isAvailable ? 'active' : 'inactive'} />
              </div>
              <p className="text-sm text-gray-500 mb-1 font-medium">{court.venueName}</p>
              <div className="flex items-center gap-1 text-gray-400 text-sm mb-6">
                <MapPin className="w-4 h-4" /> {court.city}{court.neighborhood ? ` · ${court.neighborhood}` : ''} · {court.country}
              </div>

              <div className="grid grid-cols-1 sm:grid-cols-2 gap-0">
                {[
                  { label: 'نوع الملعب', value: court.type === 'indoor' ? 'داخلي' : 'خارجي', icon: <Building2 className="w-4 h-4 text-gray-400" /> },
                  { label: 'الفئة المستهدفة', value: genderLabel, icon: <Building2 className="w-4 h-4 text-gray-400" /> },
                  { label: 'السعر الأساسي', value: `${court.basePrice} ر.س/جلسة`, icon: <DollarSign className="w-4 h-4 text-gray-400" /> },
                  { label: 'نسبة سبورتا', value: `${court.sportaCommissionPercent ?? 0}%`, icon: <Percent className="w-4 h-4 text-cyan-500" /> },
                  { label: 'الإجمالي (شامل النسبة)', value: `${court.totalPrice ?? court.basePrice} ر.س/جلسة`, icon: <DollarSign className="w-4 h-4 text-green-500" /> },
                  // سعر الذروة قاعدة قديمة لا تُطبَّق متى عرّف المالك قواعد تسعير خاصة.
                  ...(court.priceRules?.length
                    ? []
                    : [{ label: 'سعر الذروة (بعد 4 عصراً)', value: `${court.peakHourPrice} ر.س/جلسة`, icon: <DollarSign className="w-4 h-4 text-orange-400" /> }]),
                  { label: 'مدد الجلسات المتاحة', value: court.availableDurations?.map(d => `${d} د`).join(' · ') || '-', icon: <Clock className="w-4 h-4 text-gray-400" /> },
                  { label: 'الحالة', value: <StatusBadge status={court.isAvailable ? 'active' : 'inactive'} /> },
                ].map(row => (
                  <div key={row.label} className="flex items-center justify-between py-3 border-b border-gray-50">
                    <span className="text-sm text-gray-500 flex items-center gap-2">{row.icon}{row.label}</span>
                    <span className="text-sm font-semibold text-gray-800">{row.value}</span>
                  </div>
                ))}
              </div>
            </div>
          </div>

          {/* دوام الأسبوع — يحدده الملعب من تطبيقه */}
          <div className="bg-white rounded-2xl shadow-sm border border-gray-100 p-6">
            <h3 className="font-bold text-gray-800 flex items-center gap-2 mb-4">
              <CalendarDays className="w-5 h-5 text-[#2AB5CE]" /> دوام الأسبوع
            </h3>
            <div className="grid grid-cols-1 sm:grid-cols-2 gap-x-6">
              {(court.openingHours ?? []).map((h) => (
                <div key={h.day} className="flex justify-between items-center py-2.5 border-b border-gray-50">
                  <span className="text-sm text-gray-500">{DAY_NAMES[h.day] ?? h.day}</span>
                  {h.isClosed ? (
                    <span className="px-2 py-0.5 bg-red-50 text-red-600 rounded-lg text-xs font-semibold">مغلق</span>
                  ) : (
                    <span className="text-sm font-semibold text-gray-800" dir="ltr">
                      {hhmm(h.openHour)} – {hhmm(h.closeHour)}
                    </span>
                  )}
                </div>
              ))}
            </div>
          </div>

          {/* قواعد التسعير حسب اليوم والوقت */}
          <div className="bg-white rounded-2xl shadow-sm border border-gray-100 p-6">
            <h3 className="font-bold text-gray-800 flex items-center gap-2 mb-1">
              <Percent className="w-5 h-5 text-[#2AB5CE]" /> أسعار حسب اليوم والوقت
            </h3>
            <p className="text-xs text-gray-400 mb-4">
              فترات يحدّد فيها الملعب سعر ساعة ثابتاً (سعر المالك قبل نسبة سبورتا) أو نسبة زيادة/خصم على السعر الأساسي. فترة اليوم المحدد تسبق «كل الأيام»، والحجز الممتد بين فترتين يُحسب كل جزء بسعر فترته.
            </p>
            {!court.priceRules?.length ? (
              <p className="text-sm text-gray-400">لا توجد قواعد — السعر موحّد طوال الأسبوع.</p>
            ) : (
              <div className="space-y-2">
                {court.priceRules.map((r, i) => (
                  <div key={i} className="flex items-center justify-between gap-3 px-4 py-3 rounded-xl bg-gray-50 border border-gray-100">
                    <span className="text-sm font-medium text-gray-700">
                      {r.day === null || r.day === undefined ? 'كل الأيام' : DAY_NAMES[r.day]}
                    </span>
                    <span className="text-sm text-gray-500" dir="ltr">
                      {hhmm(r.startHour)} – {hhmm(r.endHour)}
                    </span>
                    {r.hourlyPrice != null ? (
                      <span className="px-2.5 py-1 rounded-lg text-xs font-bold bg-blue-50 text-blue-700">
                        {Number(r.hourlyPrice).toLocaleString('ar-SA')} ر.س/ساعة
                      </span>
                    ) : (
                      <span className={`px-2.5 py-1 rounded-lg text-xs font-bold ${
                        Number(r.adjustmentPercent) >= 0
                          ? 'bg-orange-50 text-orange-700'
                          : 'bg-green-50 text-green-700'
                      }`}>
                        {adjustmentLabel(r.adjustmentPercent)}
                      </span>
                    )}
                  </div>
                ))}
              </div>
            )}
          </div>

          {/* Availability */}
          <div className="bg-white rounded-2xl shadow-sm border border-gray-100 p-6">
            <div className="flex items-center justify-between mb-5">
              <h3 className="font-bold text-gray-800 flex items-center gap-2">
                <Calendar className="w-5 h-5 text-[#2AB5CE]" /> جدول المواعيد
              </h3>
              <div className="flex items-center gap-2">
                <input type="date" value={date} min={today}
                  onChange={e => setDate(e.target.value)}
                  className="px-3 py-2 border border-gray-200 rounded-xl text-sm focus:outline-none focus:ring-2 focus:ring-[#2AB5CE] bg-gray-50" />
                {slotsLoading && <RefreshCw className="w-4 h-4 text-gray-400 animate-spin" />}
              </div>
            </div>

            {slotsError ? (
              <p className="text-center text-sm text-red-500 py-4">{slotsError}</p>
            ) : slotsLoading ? (
              <div className="grid grid-cols-3 sm:grid-cols-4 gap-2">
                {Array.from({ length: 8 }).map((_, i) => (
                  <div key={i} className="h-14 bg-gray-100 rounded-xl animate-pulse" />
                ))}
              </div>
            ) : slots.length === 0 ? (
              <div className="text-center py-8 text-gray-400">
                <Clock className="w-10 h-10 mx-auto mb-2 opacity-30" />
                <p className="text-sm">
                  {dayClosed
                    ? 'الملعب مغلق في هذا اليوم حسب دوام الأسبوع'
                    : 'لا توجد مواعيد متاحة لهذا التاريخ'}
                </p>
              </div>
            ) : (
              <div className="grid grid-cols-3 sm:grid-cols-4 gap-2">
                {slots.map((slot, i) => (
                  <div key={i}
                    className={`rounded-xl p-3 text-center border transition ${
                      slot.isBooked
                        ? 'bg-red-50 border-red-100 opacity-60'
                        : slot.isPeak
                          ? 'bg-orange-50 border-orange-200'
                          : 'bg-green-50 border-green-200'
                    }`}>
                    <p className={`text-sm font-bold ${slot.isBooked ? 'text-red-400' : slot.isPeak ? 'text-orange-700' : 'text-green-700'}`}>
                      {slot.time}
                    </p>
                    <p className={`text-xs mt-0.5 ${slot.isBooked ? 'text-red-400' : 'text-gray-500'}`}>
                      {slot.isBooked ? 'محجوز' : `${slot.price} ر.س`}
                    </p>
                    {slot.isPeak && !slot.isBooked && (
                      <span className="text-[9px] text-orange-500 font-medium">ذروة</span>
                    )}
                  </div>
                ))}
              </div>
            )}

            {/* Legend */}
            {slots.length > 0 && (
              <div className="flex items-center gap-4 mt-4 pt-3 border-t border-gray-100">
                {[
                  { color: 'bg-green-200', label: 'متاح' },
                  { color: 'bg-orange-200', label: 'ذروة' },
                  { color: 'bg-red-200',   label: 'محجوز' },
                ].map(l => (
                  <span key={l.label} className="flex items-center gap-1.5 text-xs text-gray-500">
                    <span className={`w-3 h-3 rounded-full ${l.color}`} /> {l.label}
                  </span>
                ))}
              </div>
            )}
          </div>
        </div>

        {/* Side info */}
        <div className="space-y-4">
          {/* نسبة سبورتا */}
          <div className="bg-white rounded-2xl shadow-sm border border-gray-100 p-5">
            <h3 className="font-bold text-gray-800 mb-1 flex items-center gap-2">
              <Percent className="w-4 h-4 text-[#2AB5CE]" /> نسبة سبورتا
            </h3>
            <p className="text-xs text-gray-400 mb-4">
              تُضاف هذه النسبة على السعر الأساسي الذي يحدده الملعب، ويدفع اللاعب الإجمالي.
            </p>
            <div className="flex items-center gap-2">
              <div className="relative flex-1">
                <input type="number" min="0" max="100" step="0.5" value={commission}
                  onChange={e => { setCommission(e.target.value); setCommissionSaved(false); }}
                  className="w-full pl-8 pr-3 py-2 border border-gray-200 rounded-xl text-sm focus:outline-none focus:ring-2 focus:ring-[#2AB5CE]" />
                <span className="absolute left-3 top-1/2 -translate-y-1/2 text-gray-400 text-sm">%</span>
              </div>
              <button onClick={saveCommission} disabled={commissionSaving}
                className="px-4 py-2 bg-[#2AB5CE] text-white rounded-xl text-sm font-semibold hover:opacity-90 disabled:opacity-50 flex items-center gap-1.5">
                {commissionSaving ? <RefreshCw className="w-4 h-4 animate-spin" /> : commissionSaved ? <Check className="w-4 h-4" /> : null}
                حفظ
              </button>
            </div>
            {commissionError && <p className="text-xs text-red-500 mt-2">{commissionError}</p>}
            {commissionSaved && !commissionError && (
              <p className="text-xs text-green-600 mt-2">تم حفظ النسبة وتحديث الأسعار</p>
            )}
            <div className="mt-4 pt-3 border-t border-gray-50 space-y-2 text-sm">
              <div className="flex justify-between"><span className="text-gray-400">السعر الأساسي</span><span className="font-semibold text-gray-700">{court.basePrice} ر.س</span></div>
              <div className="flex justify-between"><span className="text-gray-400">نسبة سبورتا</span><span className="font-semibold text-cyan-600">{court.sportaCommissionPercent ?? 0}%</span></div>
              <div className="flex justify-between"><span className="text-gray-400">الإجمالي</span><span className="font-bold text-gray-800">{court.totalPrice ?? court.basePrice} ر.س</span></div>
            </div>
          </div>

          <div className="bg-white rounded-2xl shadow-sm border border-gray-100 p-5">
            <h3 className="font-bold text-gray-800 mb-4">معلومات إضافية</h3>
            <div className="space-y-3">
              {[
                { label: 'معرّف الملعب', value: `#${court.id}` },
                { label: 'معرّف المكان', value: `#${court.venueId}` },
                { label: 'مدد الجلسات', value: court.availableDurations?.join(', ') + ' دقيقة' },
                { label: 'التوافر الحالي', value: court.isAvailable ? '✅ متاح' : '❌ غير متاح' },
              ].map(r => (
                <div key={r.label} className="flex justify-between items-center py-2 border-b border-gray-50 last:border-0">
                  <span className="text-sm text-gray-500">{r.label}</span>
                  <span className="text-sm font-semibold text-gray-800">{r.value}</span>
                </div>
              ))}
            </div>
          </div>

          {court.availableTimes?.length > 0 && (
            <div className="bg-white rounded-2xl shadow-sm border border-gray-100 p-5">
              <h3 className="font-bold text-gray-800 mb-3">أوقات الفتح اليومية</h3>
              <div className="flex flex-wrap gap-2">
                {court.availableTimes.map(t => (
                  <span key={t} className="px-2.5 py-1 bg-green-50 text-green-700 rounded-lg text-xs font-medium border border-green-100">
                    {t}
                  </span>
                ))}
              </div>
            </div>
          )}

          {(court.latitude && court.longitude) && (
            <div className="bg-white rounded-2xl shadow-sm border border-gray-100 p-5">
              <h3 className="font-bold text-gray-800 mb-3">الموقع الجغرافي</h3>
              <div className="space-y-2 text-sm text-gray-600">
                <div className="flex justify-between"><span className="text-gray-400">خط العرض</span><span className="font-mono">{court.latitude?.toFixed(5)}</span></div>
                <div className="flex justify-between"><span className="text-gray-400">خط الطول</span><span className="font-mono">{court.longitude?.toFixed(5)}</span></div>
                {court.distanceKm != null && (
                  <div className="flex justify-between"><span className="text-gray-400">المسافة</span><span>{court.distanceKm.toFixed(1)} كم</span></div>
                )}
              </div>
            </div>
          )}
        </div>
      </div>
      <ConfirmModal
        open={deleting}
        title="حذف الملعب"
        message={`سيُحذف ملعب "${court.name}" من المنصة: تُلغى الحجوزات القادمة عليه ويُعاد ما دفعه اللاعبون إلى محافظهم، ويصل إشعار للملعب. لا يمكن التراجع عن هذه العملية.`}
        onConfirm={removeCourt}
        onCancel={() => setDeleting(false)}
      />

    </div>
  );
}
