import { useState } from 'react';
import { useParams, useNavigate } from 'react-router-dom';
import { ArrowRight, Check, Users, Trash2, ToggleLeft, ToggleRight, Edit3, Package } from 'lucide-react';
import { adminApi } from '../api/adminApi';
import { useApi } from '../hooks/useApi';
import StatusBadge from '../components/StatusBadge';
import ConfirmModal from '../components/ConfirmModal';
import PackageFormModal from '../components/PackageFormModal';
import { Spinner } from '../components/TableBits';

const tierColors = ['from-amber-600 to-yellow-500','from-slate-400 to-gray-500','from-yellow-400 to-amber-500','from-indigo-500 to-purple-600'];

export default function PackageDetailPage() {
  const { id } = useParams();
  const navigate = useNavigate();
  const [confirm, setConfirm] = useState(null);
  const [editOpen, setEditOpen] = useState(false);
  const [err, setErr] = useState(null);

  const { data, loading, error, refetch } = useApi(() => adminApi.getPackages(), []);
  const pkg = (data ?? []).find(p => p.id === Number(id));

  if (loading) return <Spinner />;
  if (error) return <div className="text-center py-16 text-red-500 text-sm">{error}</div>;

  if (!pkg) return (
    <div className="text-center py-20 text-gray-400">
      <p>الاشتراك غير موجود</p>
      <button onClick={() => navigate('/packages')} className="mt-3 text-[#2AB5CE] hover:underline text-sm">العودة للاشتراكات</button>
    </div>
  );

  const handleDelete = async () => {
    try {
      await adminApi.deletePackage(pkg.id);
      setConfirm(null);
      navigate('/packages');
    } catch (e) {
      setErr(e?.response?.data?.messageAr || 'تعذّر الحذف');
      setConfirm(null);
    }
  };

  const handleToggle = async () => {
    await adminApi.updatePackage(pkg.id, {
      name: pkg.name, price: pkg.price, period: pkg.period ?? 'monthly',
      features: pkg.features, isActive: !pkg.isActive, sortOrder: pkg.sortOrder,
      pointsMultiplier: pkg.pointsMultiplier ?? 1, bookingDiscountPercent: pkg.bookingDiscountPercent ?? 0, welcomePoints: pkg.welcomePoints ?? 0,
      commissionDiscountPercent: pkg.commissionDiscountPercent ?? 0,
      commissionPercent: pkg.commissionPercent ?? 0,
    });
    setConfirm(null);
    refetch();
  };

  const handleSave = async (form) => {
    await adminApi.updatePackage(pkg.id, {
      name: form.name, price: Number(form.price), period: form.period,
      features: form.features, isActive: pkg.isActive, sortOrder: pkg.sortOrder,
      pointsMultiplier: Number(form.pointsMultiplier) || 1, bookingDiscountPercent: Number(form.bookingDiscountPercent) || 0, welcomePoints: Number(form.welcomePoints) || 0,
      commissionDiscountPercent: Number(form.commissionDiscountPercent) || 0,
      commissionPercent: Number(form.commissionPercent) || 0,
    });
    setEditOpen(false);
    refetch();
  };

  return (
    <div>
      <button onClick={() => navigate('/packages')} className="flex items-center gap-2 text-sm text-gray-500 hover:text-gray-700 mb-5">
        <ArrowRight className="w-4 h-4" /> العودة للاشتراكات
      </button>
      {err && <p className="text-sm text-red-500 mb-4">{err}</p>}

      <div className="grid grid-cols-1 lg:grid-cols-3 gap-5">
        <div className="lg:col-span-2 bg-white rounded-2xl shadow-sm border border-gray-100 overflow-hidden">
          <div className={`bg-gradient-to-br ${tierColors[pkg.id % tierColors.length]} p-6 text-white`}>
            <div className="flex items-start justify-between mb-4">
              <Package className="w-10 h-10 text-white/60" />
              <StatusBadge status={pkg.isActive ? 'active' : 'inactive'} />
            </div>
            <h2 className="text-2xl font-black mb-1">{pkg.name}</h2>
            <div className="flex items-baseline gap-2 mt-3">
              <span className="text-4xl font-black">{pkg.price}</span>
              <span className="text-white/70">ر.س / {pkg.duration} يوم</span>
            </div>
          </div>
          <div className="p-6">
            <h3 className="font-bold text-gray-800 mb-4">المميزات المتضمنة</h3>
            {pkg.features.length === 0 ? (
              <p className="text-sm text-gray-400">لا توجد مميزات مضافة لهذا الاشتراك</p>
            ) : (
              <div className="grid grid-cols-1 sm:grid-cols-2 gap-3">
                {pkg.features.map((f, i) => (
                  <div key={i} className="flex items-center gap-3 bg-green-50 rounded-xl px-4 py-3">
                    <div className="w-6 h-6 bg-[#2AB5CE] rounded-full flex items-center justify-center shrink-0">
                      <Check className="w-3.5 h-3.5 text-white" />
                    </div>
                    <span className="text-sm text-gray-700">{f}</span>
                  </div>
                ))}
              </div>
            )}
            <div className="flex items-center gap-2 mt-5 pt-4 border-t border-gray-100 text-sm text-gray-500">
              <Users className="w-4 h-4" />
              <span>{pkg.subscribers} مشترك حالياً</span>
            </div>
          </div>
        </div>

        <div className="space-y-4">
          <div className="bg-white rounded-2xl shadow-sm border border-gray-100 p-5">
            <h3 className="font-bold text-gray-800 mb-4">الإجراءات</h3>
            <div className="space-y-3">
              <button onClick={() => setEditOpen(true)}
                className="w-full flex items-center justify-center gap-2 py-3 rounded-xl font-medium text-sm bg-gray-50 text-gray-700 hover:bg-gray-100 border border-gray-200 transition">
                <Edit3 className="w-4 h-4" /> تعديل الاشتراك
              </button>
              <button onClick={() => setConfirm('toggle')}
                className={`w-full flex items-center justify-center gap-2 py-3 rounded-xl font-medium text-sm border transition ${
                  pkg.isActive
                    ? 'bg-yellow-50 text-yellow-700 border-yellow-200 hover:bg-yellow-100'
                    : 'bg-green-50 text-green-700 border-green-200 hover:bg-green-100'
                }`}>
                {pkg.isActive ? <><ToggleRight className="w-4 h-4"/>إيقاف الاشتراك</> : <><ToggleLeft className="w-4 h-4"/>تفعيل الاشتراك</>}
              </button>
              <button onClick={() => setConfirm('delete')}
                className="w-full flex items-center justify-center gap-2 py-3 rounded-xl font-medium text-sm bg-red-50 text-red-600 border border-red-200 hover:bg-red-100 transition">
                <Trash2 className="w-4 h-4" /> حذف الاشتراك
              </button>
            </div>
          </div>

          <div className="bg-white rounded-2xl shadow-sm border border-gray-100 p-5">
            <h3 className="font-bold text-gray-800 mb-4">إحصائيات</h3>
            <div className="space-y-3">
              {[
                { label: 'المشتركون', value: pkg.subscribers, color: 'text-blue-600' },
                { label: 'الإيراد الحالي', value: `${(pkg.subscribers * pkg.price).toLocaleString()} ر.س`, color: 'text-[#2AB5CE]' },
                { label: 'النوع', value: pkg.period === 'commission' ? 'بالنسبة (بلا مدة)' : pkg.period === 'yearly' ? `سنوي (${pkg.duration} يوم)` : `شهري (${pkg.duration} يوم)`, color: 'text-gray-700' },
                { label: 'مضاعف النقاط', value: `×${pkg.pointsMultiplier ?? 1}`, color: 'text-amber-600' },
                { label: 'خصم الحجوزات', value: `${pkg.bookingDiscountPercent ?? 0}%`, color: 'text-amber-600' },
                { label: 'نقاط ترحيبية', value: pkg.welcomePoints ?? 0, color: 'text-amber-600' },
                { label: pkg.period === 'commission' ? 'نسبة سبورتا من كل عملية' : 'خصم عمولة سبورتا',
                  value: `${pkg.period === 'commission' ? (pkg.commissionPercent ?? 0) : (pkg.commissionDiscountPercent ?? 0)}%`,
                  color: 'text-amber-600' },
              ].map(s => (
                <div key={s.label} className="flex justify-between py-2 border-b border-gray-50 last:border-0">
                  <span className="text-sm text-gray-500">{s.label}</span>
                  <span className={`text-sm font-bold ${s.color}`}>{s.value}</span>
                </div>
              ))}
            </div>
          </div>
        </div>
      </div>

      <ConfirmModal open={confirm === 'delete'} title="حذف الاشتراك" message={`هل أنت متأكد من حذف "${pkg.name}"؟`} danger onConfirm={handleDelete} onCancel={() => setConfirm(null)} />
      <ConfirmModal open={confirm === 'toggle'} title={pkg.isActive ? 'إيقاف الاشتراك' : 'تفعيل الاشتراك'} message={pkg.isActive ? `سيتم إيقاف "${pkg.name}".` : `سيتم تفعيل "${pkg.name}".`} danger={false} onConfirm={handleToggle} onCancel={() => setConfirm(null)} />
      <PackageFormModal open={editOpen} initial={pkg} onSave={handleSave} onClose={() => setEditOpen(false)} />
    </div>
  );
}
