import { useState } from 'react';
import { useParams, useNavigate } from 'react-router-dom';
import {
  ArrowRight, Building2, MapPin, Phone, Calendar, LayoutGrid,
  FileText, IdCard, Receipt, Image as ImageIcon, CheckCircle2, XCircle, Home, Trash2,
} from 'lucide-react';
import { venuesApi } from '../api/venuesApi';
import { useApi } from '../hooks/useApi';
import StatusBadge from '../components/StatusBadge';
import ConfirmModal from '../components/ConfirmModal';
import VenueCourtsTable from '../components/VenueCourtsTable';
import { resolveImageUrl } from '../components/ImageUploadField';
import { Spinner } from '../components/TableBits';
import { useAuth } from '../context/AuthContext';

function formatDate(iso) {
  const d = new Date(iso);
  if (Number.isNaN(d.getTime())) return '—';
  return d.toLocaleDateString('ar', { year: 'numeric', month: 'long', day: 'numeric' });
}

const genderPolicyLabel = {
  men: 'رجال',
  womenOnly: 'نساء فقط',
  familyOnly: 'عائلات',
};

export default function VenueDetailPage() {
  const { id } = useParams();
  const navigate = useNavigate();
  const { can } = useAuth();
  const canDelete = can('venues.delete');
  const { data: venue, loading, error, refetch } = useApi(() => venuesApi.getById(id), [id]);

  const [confirm, setConfirm] = useState(false); // approve | revoke | delete | false
  const [busy, setBusy] = useState(false);
  const [actionError, setActionError] = useState(null);

  const applyApproval = async (approve) => {
    setBusy(true);
    setActionError(null);
    setConfirm(false);
    try {
      await venuesApi.setApproved(id, approve);
      await refetch();
    } catch (err) {
      setActionError(err?.response?.data?.messageAr || err?.response?.data?.message || 'تعذّر تنفيذ العملية');
    } finally {
      setBusy(false);
    }
  };

  const remove = async () => {
    setBusy(true);
    setActionError(null);
    setConfirm(false);
    try {
      await venuesApi.remove(id);
      navigate('/venues');
    } catch (err) {
      setActionError(err?.response?.data?.messageAr || err?.response?.data?.message || 'تعذّر حذف النادي');
      setBusy(false);
    }
  };

  if (loading) return <Spinner />;
  if (error || !venue) {
    return (
      <div className="text-center py-20 text-gray-400">
        {error || 'النادي غير موجود'}
        <div className="mt-4">
          <button onClick={() => navigate('/venues')} className="text-[#2AB5CE] hover:underline">
            العودة للأندية والملاعب
          </button>
        </div>
      </div>
    );
  }

  const stats = [
    { label: 'المدينة', value: venue.city || '—', icon: MapPin },
    { label: 'الحي', value: venue.district || '—', icon: Home },
    { label: 'الملاعب', value: venue.courtsCount, icon: LayoutGrid },
    { label: 'السياسة', value: genderPolicyLabel[venue.genderPolicy] ?? venue.genderPolicy, icon: Building2 },
  ];

  const documents = [
    { key: 'commercialRegistrationImageUrl', label: 'صورة السجل التجاري', icon: FileText, kind: 'image', value: venue.commercialRegistrationImageUrl },
    { key: 'nationalAddressImageUrl', label: 'صورة العنوان الوطني', icon: MapPin, kind: 'image', value: venue.nationalAddressImageUrl },
    { key: 'ownerIdImageUrl', label: 'صورة هوية صاحب الحساب', icon: IdCard, kind: 'image', value: venue.ownerIdImageUrl },
    { key: 'taxCertificateUrl', label: 'شهادة الضريبة', icon: Receipt, kind: 'image', value: venue.taxCertificateUrl },
  ];

  return (
    <div>
      <button onClick={() => navigate('/venues')}
        className="flex items-center gap-1 text-sm text-gray-500 hover:text-gray-700 mb-4">
        <ArrowRight className="w-4 h-4" /> العودة للأندية والملاعب
      </button>

      <div className="grid grid-cols-1 lg:grid-cols-3 gap-6">
        {/* Profile */}
        <div className="bg-white rounded-2xl shadow-sm border border-gray-100 p-6 flex flex-col items-center">
          <div className="w-24 h-24 rounded-full bg-gradient-to-br from-teal-400 to-cyan-600 flex items-center justify-center text-white text-3xl font-bold mb-3">
            {venue.name?.[0] ?? '؟'}
          </div>
          <h2 className="text-xl font-bold text-gray-800 text-center">{venue.name}</h2>
          <p className="text-sm text-gray-500 mt-1">{venue.address}</p>
          <div className="mt-4 flex items-center gap-2">
            <StatusBadge status={venue.isActive ? 'active' : 'inactive'} />
            <StatusBadge status={venue.isApproved ? 'active' : 'pending'}
              label={venue.isApproved ? 'ظاهر للاعبين' : 'بانتظار الموافقة'} />
          </div>

          {actionError && (
            <p className="mt-3 text-xs text-red-600 text-center">{actionError}</p>
          )}

          <div className="w-full mt-4">
            {venue.isApproved ? (
              <button disabled={busy} onClick={() => setConfirm('revoke')}
                className="w-full flex items-center justify-center gap-1.5 px-4 py-2.5 rounded-xl bg-red-50 text-red-600 hover:bg-red-100 transition text-sm font-medium disabled:opacity-50">
                <XCircle className="w-4 h-4" /> إلغاء الموافقة
              </button>
            ) : (
              <button disabled={busy} onClick={() => setConfirm('approve')}
                className="w-full flex items-center justify-center gap-1.5 px-4 py-2.5 rounded-xl bg-green-50 text-green-700 hover:bg-green-100 transition text-sm font-medium disabled:opacity-50">
                <CheckCircle2 className="w-4 h-4" /> الموافقة على النادي
              </button>
            )}

            {canDelete && (
              <button disabled={busy} onClick={() => setConfirm('delete')}
                className="w-full mt-2 flex items-center justify-center gap-1.5 px-4 py-2.5 rounded-xl bg-red-500 text-white hover:bg-red-600 transition text-sm font-medium disabled:opacity-50">
                <Trash2 className="w-4 h-4" /> حذف النادي
              </button>
            )}
          </div>

          <div className="w-full mt-5 pt-5 border-t border-gray-100 space-y-3 text-sm">
            <p className="text-xs text-gray-400 font-semibold">الحساب</p>
            <p className="text-gray-700 font-medium">{venue.ownerName}</p>
            {venue.ownerPhone && (
              <div className="flex items-center gap-2 text-gray-600">
                <Phone className="w-4 h-4 text-gray-400 shrink-0" />
                <span dir="ltr">{venue.ownerPhone}</span>
              </div>
            )}
            <div className="flex items-center gap-2 text-gray-600">
              <Calendar className="w-4 h-4 text-gray-400 shrink-0" />
              <span>سُجّل في {formatDate(venue.createdAt)}</span>
            </div>
            <div className="flex items-center justify-between pt-2 text-xs text-gray-400">
              <span>رقم النادي</span><span dir="ltr">#{venue.id}</span>
            </div>
          </div>
        </div>

        {/* Details */}
        <div className="lg:col-span-2 space-y-6">
          <div className="grid grid-cols-2 sm:grid-cols-4 gap-3">
            {stats.map((s) => (
              <div key={s.label} className="bg-white rounded-2xl border border-gray-100 p-4 shadow-sm">
                <div className="flex items-center gap-2 text-gray-400 text-xs mb-1">
                  <s.icon className="w-4 h-4" /> {s.label}
                </div>
                <p className="text-lg font-bold text-gray-800">{s.value}</p>
              </div>
            ))}
          </div>

          {venue.description && (
            <div className="bg-white rounded-2xl border border-gray-100 p-5 shadow-sm">
              <div className="flex items-center gap-2 text-gray-700 font-semibold mb-2">
                <Building2 className="w-4 h-4 text-[#2AB5CE]" /> نبذة
              </div>
              <p className="text-sm text-gray-600 leading-relaxed">{venue.description}</p>
            </div>
          )}

          {/* ملاعب النادي — بديل صفحة الملاعب المستقلة بعد دمج القسمين */}
          <VenueCourtsTable courts={venue.courts ?? []} onChanged={refetch} />

          {/* الموقع */}
          <div className="bg-white rounded-2xl border border-gray-100 p-5 shadow-sm">
            <div className="flex items-center gap-2 text-gray-700 font-semibold mb-4">
              <MapPin className="w-4 h-4 text-[#2AB5CE]" /> الموقع
            </div>
            <div className="grid grid-cols-1 sm:grid-cols-2 gap-x-6">
              {[
                { label: 'الدولة', value: venue.country || '—' },
                { label: 'المدينة', value: venue.city || '—' },
                { label: 'الحي', value: venue.district || '—' },
                { label: 'العنوان', value: venue.address || '—' },
                { label: 'خط العرض', value: venue.latitude?.toFixed?.(5) ?? '—' },
                { label: 'خط الطول', value: venue.longitude?.toFixed?.(5) ?? '—' },
              ].map((r) => (
                <div key={r.label} className="flex justify-between gap-3 py-2.5 border-b border-gray-50 last:border-0">
                  <span className="text-sm text-gray-400 shrink-0">{r.label}</span>
                  <span className="text-sm font-semibold text-gray-800 text-left">{r.value}</span>
                </div>
              ))}
            </div>
            {(venue.latitude && venue.longitude) && (
              <a href={`https://maps.google.com/?q=${venue.latitude},${venue.longitude}`}
                target="_blank" rel="noreferrer"
                className="inline-block mt-3 text-xs text-[#2AB5CE] hover:underline">
                فتح الموقع على الخريطة
              </a>
            )}
          </div>

          {/* مستندات المالك (السجل التجاري، العنوان الوطني، الهوية، الضريبة) */}
          <div className="bg-white rounded-2xl border border-gray-100 p-5 shadow-sm">
            <div className="flex items-center gap-2 text-gray-700 font-semibold mb-4">
              <FileText className="w-4 h-4 text-[#2AB5CE]" /> مستندات التسجيل
            </div>
            <div className="grid grid-cols-1 sm:grid-cols-2 gap-4">
              {documents.map((d) => (
                <div key={d.key} className="rounded-xl border border-gray-100 bg-gray-50/50 p-4">
                  <div className="flex items-center gap-2 text-xs text-gray-500 mb-2">
                    <d.icon className="w-3.5 h-3.5" /> {d.label}
                  </div>
                  {!d.value ? (
                    <p className="text-sm text-gray-400">غير مرفوع</p>
                  ) : d.kind === 'text' ? (
                    <p className="text-sm font-semibold text-gray-800 break-words">{d.value}</p>
                  ) : (
                    <a href={resolveImageUrl(d.value)} target="_blank" rel="noreferrer" className="block group">
                      <img
                        src={resolveImageUrl(d.value)}
                        alt={d.label}
                        className="w-full h-32 object-cover rounded-lg border border-gray-200 group-hover:opacity-90 transition"
                      />
                    </a>
                  )}
                </div>
              ))}
            </div>
          </div>

          {/* صور النادي/الملعب */}
          <div className="bg-white rounded-2xl border border-gray-100 p-5 shadow-sm">
            <div className="flex items-center gap-2 text-gray-700 font-semibold mb-4">
              <ImageIcon className="w-4 h-4 text-[#2AB5CE]" /> صور النادي
            </div>
            {venue.imageUrls?.length > 0 ? (
              <div className="grid grid-cols-2 sm:grid-cols-3 gap-3">
                {venue.imageUrls.map((url, i) => (
                  <a key={i} href={resolveImageUrl(url)} target="_blank" rel="noreferrer" className="block group">
                    <img
                      src={resolveImageUrl(url)}
                      alt={`صورة النادي ${i + 1}`}
                      className="w-full h-28 object-cover rounded-lg border border-gray-200 group-hover:opacity-90 transition"
                    />
                  </a>
                ))}
              </div>
            ) : (
              <p className="text-sm text-gray-400">لم تُرفع صور بعد</p>
            )}
          </div>
        </div>
      </div>

      <ConfirmModal
        open={!!confirm}
        danger={confirm !== 'approve'}
        title={confirm === 'approve'
          ? 'الموافقة على النادي'
          : confirm === 'delete' ? 'حذف النادي' : 'إلغاء الموافقة'}
        message={confirm === 'approve'
          ? `سيصبح "${venue.name}" وملاعبه ظاهرين للاعبين ويمكن حجزهم، وسيصل إشعار لصاحب النادي.`
          : confirm === 'delete'
            ? `سيُحذف "${venue.name}" وكل ملاعبه (${venue.courtsCount}) من المنصة: تُلغى الحجوزات القادمة ويُعاد ما دفعه اللاعبون إلى محافظهم، ويصل إشعار للملعب. لا يمكن التراجع عن هذه العملية.`
            : `لن يظهر "${venue.name}" ولا ملاعبه للاعبين بعد الآن حتى تتم الموافقة عليه مجدداً، وسيصل إشعار لصاحب النادي.`}
        onConfirm={confirm === 'delete' ? remove : () => applyApproval(confirm === 'approve')}
        onCancel={() => setConfirm(false)}
      />
    </div>
  );
}
