import { useState } from 'react';
import { useNavigate } from 'react-router-dom';
import { Plus, Eye, Trash2, Edit3, ToggleLeft, ToggleRight, Package, Users, Search } from 'lucide-react';
import { adminApi } from '../api/adminApi';
import { useApi } from '../hooks/useApi';
import PageHeader from '../components/PageHeader';
import StatusBadge from '../components/StatusBadge';
import ConfirmModal from '../components/ConfirmModal';
import PackageFormModal from '../components/PackageFormModal';
import { Spinner, Empty } from '../components/TableBits';

const tierGradients = [
  'from-amber-500 to-yellow-400',
  'from-slate-400 to-gray-500',
  'from-yellow-400 to-amber-500',
  'from-indigo-500 to-purple-600',
];

export default function PackagesPage() {
  const [search, setSearch] = useState('');
  const [filter, setFilter] = useState('all');
  const [confirm, setConfirm] = useState(null);
  const [formModal, setFormModal] = useState(null); // 'new' | package
  const [err, setErr] = useState(null);
  const navigate = useNavigate();

  const { data, loading, error, refetch } = useApi(() => adminApi.getPackages(), []);
  const packages = data ?? [];

  const filtered = packages.filter(p => {
    const matchSearch = p.name.includes(search);
    const matchFilter = filter === 'all' || (filter === 'active') === p.isActive;
    return matchSearch && matchFilter;
  });

  const handleDelete = async () => {
    try {
      await adminApi.deletePackage(confirm.item.id);
      setConfirm(null);
      refetch();
    } catch (e) {
      setErr(e?.response?.data?.messageAr || 'تعذّر الحذف');
      setConfirm(null);
    }
  };

  const handleToggle = async (pkg) => {
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
    const body = {
      name: form.name, price: Number(form.price), period: form.period,
      features: form.features,
      isActive: formModal === 'new' ? true : formModal.isActive,
      sortOrder: formModal === 'new' ? 0 : formModal.sortOrder,
      pointsMultiplier: Number(form.pointsMultiplier) || 1, bookingDiscountPercent: Number(form.bookingDiscountPercent) || 0, welcomePoints: Number(form.welcomePoints) || 0,
      commissionDiscountPercent: Number(form.commissionDiscountPercent) || 0,
      commissionPercent: Number(form.commissionPercent) || 0,
    };
    if (formModal === 'new') await adminApi.createPackage(body);
    else await adminApi.updatePackage(formModal.id, body);
    setFormModal(null);
    refetch();
  };

  return (
    <div>
      <PageHeader
        title="الاشتراكات"
        subtitle={`${packages.length} أنواع اشتراك في المنصة`}
        action={
          <button onClick={() => setFormModal('new')}
            className="flex items-center gap-2 px-4 py-2.5 bg-[#2AB5CE] hover:bg-[#1E9AB0] text-white rounded-xl text-sm font-medium shadow transition">
            <Plus className="w-4 h-4" /> اشتراك جديد
          </button>
        }
      />

      {err && <p className="text-sm text-red-500 mb-4">{err}</p>}

      {/* Filters */}
      <div className="flex flex-col sm:flex-row gap-3 mb-5">
        <div className="relative flex-1">
          <Search className="absolute right-3 top-1/2 -translate-y-1/2 w-4 h-4 text-gray-400" />
          <input value={search} onChange={e => setSearch(e.target.value)}
            placeholder="بحث باسم الاشتراك..."
            className="w-full pr-9 pl-4 py-2.5 border border-gray-200 rounded-xl text-sm focus:outline-none focus:ring-2 focus:ring-[#2AB5CE] bg-white" />
        </div>
        <div className="flex gap-2">
          {[['all','الكل'],['active','النشطة'],['inactive','الموقوفة']].map(([v,l]) => (
            <button key={v} onClick={() => setFilter(v)}
              className={`px-4 py-2.5 rounded-xl text-sm font-medium transition ${filter===v ? 'bg-[#2AB5CE] text-white shadow' : 'bg-white border border-gray-200 text-gray-600 hover:bg-gray-50'}`}>
              {l}
            </button>
          ))}
        </div>
      </div>

      {loading ? (
        <Spinner />
      ) : error ? (
        <div className="text-center py-16 text-red-500 text-sm">{error}</div>
      ) : filtered.length === 0 ? (
        <Empty icon={Package} text="لا توجد اشتراكات مطابقة" />
      ) : (
        <div className="bg-white rounded-2xl shadow-sm border border-gray-100 overflow-hidden">
          <div className="overflow-x-auto">
            <table className="w-full text-sm">
              <thead>
                <tr className="border-b border-gray-100 bg-gray-50">
                  <th className="text-right px-5 py-3.5 font-semibold text-gray-600">الاشتراك</th>
                  <th className="text-right px-4 py-3.5 font-semibold text-gray-600">السعر</th>
                  <th className="text-right px-4 py-3.5 font-semibold text-gray-600">النوع</th>
                  <th className="text-right px-4 py-3.5 font-semibold text-gray-600">المشتركون</th>
                  <th className="text-right px-4 py-3.5 font-semibold text-gray-600">الإيراد الحالي</th>
                  <th className="text-right px-4 py-3.5 font-semibold text-gray-600">المميزات</th>
                  <th className="text-right px-4 py-3.5 font-semibold text-gray-600">الحالة</th>
                  <th className="text-right px-4 py-3.5 font-semibold text-gray-600">الإجراءات</th>
                </tr>
              </thead>
              <tbody className="divide-y divide-gray-50">
                {filtered.map((pkg, i) => (
                  <tr key={pkg.id} className="hover:bg-gray-50/50 transition">
                    <td className="px-5 py-4">
                      <div className="flex items-center gap-3">
                        <div className={`w-9 h-9 rounded-xl bg-gradient-to-br ${tierGradients[i % tierGradients.length]} flex items-center justify-center shrink-0`}>
                          <Package className="w-4 h-4 text-white" />
                        </div>
                        <span className="font-semibold text-gray-800">{pkg.name}</span>
                      </div>
                    </td>
                    <td className="px-4 py-4">
                      {pkg.period === 'commission' ? (
                        <>
                          <span className="font-bold text-amber-600">{pkg.commissionPercent ?? 0}%</span>
                          <span className="text-gray-400 text-xs mr-1">من كل عملية</span>
                        </>
                      ) : (
                        <>
                          <span className="font-bold text-green-700">{pkg.price}</span>
                          <span className="text-gray-400 text-xs mr-1">ر.س</span>
                        </>
                      )}
                    </td>
                    <td className="px-4 py-4 text-gray-600">
                      {pkg.period === 'yearly' ? 'سنوي' : pkg.period === 'commission' ? 'بالنسبة' : 'شهري'}
                      <span className="text-gray-400 text-xs mr-1">
                        {pkg.period === 'commission' ? '(بلا مدة)' : `(${pkg.duration} يوم)`}
                      </span>
                    </td>
                    <td className="px-4 py-4">
                      <span className="flex items-center gap-1 text-gray-600">
                        <Users className="w-3.5 h-3.5 text-gray-400" /> {pkg.subscribers}
                      </span>
                    </td>
                    <td className="px-4 py-4 font-semibold text-indigo-600">
                      {(pkg.subscribers * pkg.price).toLocaleString()} ر.س
                    </td>
                    <td className="px-4 py-4 text-gray-500 text-xs">{pkg.features.length} مميزات</td>
                    <td className="px-4 py-4"><StatusBadge status={pkg.isActive ? 'active' : 'inactive'} /></td>
                    <td className="px-4 py-4">
                      <div className="flex items-center gap-2">
                        <button onClick={() => navigate(`/packages/${pkg.id}`)}
                          className="flex items-center gap-1 px-3 py-1.5 rounded-lg bg-blue-50 text-blue-600 hover:bg-blue-100 transition text-xs font-medium">
                          <Eye className="w-3.5 h-3.5" /> عرض
                        </button>
                        <button onClick={() => setFormModal(pkg)}
                          className="flex items-center gap-1 px-3 py-1.5 rounded-lg bg-gray-50 text-gray-600 hover:bg-gray-100 transition text-xs font-medium">
                          <Edit3 className="w-3.5 h-3.5" /> تعديل
                        </button>
                        <button onClick={() => setConfirm({ type: 'toggle', item: pkg })}
                          className={`flex items-center gap-1 px-3 py-1.5 rounded-lg text-xs font-medium transition ${pkg.isActive ? 'bg-yellow-50 text-yellow-600 hover:bg-yellow-100' : 'bg-green-50 text-green-700 hover:bg-green-100'}`}>
                          {pkg.isActive ? <><ToggleRight className="w-3.5 h-3.5"/>إيقاف</> : <><ToggleLeft className="w-3.5 h-3.5"/>تفعيل</>}
                        </button>
                        <button onClick={() => setConfirm({ type: 'delete', item: pkg })}
                          className="flex items-center gap-1 px-3 py-1.5 rounded-lg bg-red-50 text-red-500 hover:bg-red-100 transition text-xs font-medium">
                          <Trash2 className="w-3.5 h-3.5" /> حذف
                        </button>
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
        title={confirm?.type === 'delete' ? 'حذف الاشتراك' : confirm?.item?.isActive ? 'إيقاف الاشتراك' : 'تفعيل الاشتراك'}
        message={confirm?.type === 'delete' ? `هل أنت متأكد من حذف "${confirm?.item?.name}"؟` : confirm?.item?.isActive ? `سيتم إيقاف "${confirm?.item?.name}".` : `سيتم تفعيل "${confirm?.item?.name}".`}
        danger={confirm?.type === 'delete'}
        onConfirm={() => confirm?.type === 'delete' ? handleDelete() : handleToggle(confirm.item)}
        onCancel={() => setConfirm(null)}
      />
      <PackageFormModal open={!!formModal} initial={formModal !== 'new' ? formModal : null} onSave={handleSave} onClose={() => setFormModal(null)} />
    </div>
  );
}
