import { useState, useEffect, useCallback } from 'react';
import { Save, CreditCard, Store, Calendar } from 'lucide-react';
import { adminApi } from '../api/adminApi';
import { useAuth } from '../context/AuthContext';
import PageHeader from '../components/PageHeader';
import { Spinner, Empty } from '../components/TableBits';

const field = 'w-full px-4 py-2.5 border border-gray-200 rounded-xl text-sm focus:outline-none focus:ring-2 focus:ring-[#2AB5CE] bg-gray-50';

const money = (v) => `${Number(v ?? 0).toLocaleString('en-US')} ر.س`;
const date = (iso) => (iso ? iso.slice(0, 10) : '—');

// A worked example so the admin sees what the tiers actually charge.
function PricePreview({ pricing }) {
  const priceFor = (courts, yearly) => {
    const one = yearly ? pricing.yearlyOneCourt : pricing.monthlyOneCourt;
    const two = yearly ? pricing.yearlyTwoCourts : pricing.monthlyTwoCourts;
    const extra = yearly ? pricing.yearlyExtraCourt : pricing.monthlyExtraCourt;
    if (courts <= 1) return one;
    if (courts === 2) return two;
    return Number(two) + (courts - 2) * Number(extra);
  };

  return (
    <div className="bg-white rounded-2xl shadow-sm border border-gray-100 overflow-hidden">
      <div className="px-5 py-4 border-b border-gray-100">
        <h3 className="font-bold text-gray-800 text-sm">أمثلة على السعر النهائي</h3>
        <p className="text-xs text-gray-400 mt-0.5">قبل أي خصم من قسم الخصومات</p>
      </div>
      <div className="overflow-x-auto">
        <table className="w-full text-sm">
          <thead className="bg-gray-50 text-gray-500 text-xs">
            <tr>
              <th className="px-5 py-2.5 text-right font-medium">عدد الملاعب</th>
              <th className="px-5 py-2.5 text-right font-medium">شهري</th>
              <th className="px-5 py-2.5 text-right font-medium">سنوي</th>
            </tr>
          </thead>
          <tbody className="divide-y divide-gray-50">
            {[1, 2, 3, 5].map(n => (
              <tr key={n}>
                <td className="px-5 py-2.5 text-gray-700">{n}</td>
                <td className="px-5 py-2.5 text-gray-700">{money(priceFor(n, false))}</td>
                <td className="px-5 py-2.5 text-gray-700">{money(priceFor(n, true))}</td>
              </tr>
            ))}
          </tbody>
        </table>
      </div>
    </div>
  );
}

export default function VenueSubscriptionsPage() {
  const { can } = useAuth();
  const canManage = can('venueSubscriptions.manage');
  const canEditCommission = can('finance.commission.manage');

  const [pricing, setPricing] = useState(null);
  const [subs, setSubs] = useState([]);
  const [coachCommission, setCoachCommission] = useState('');
  const [loading, setLoading] = useState(true);
  const [saving, setSaving] = useState(false);
  const [savedNote, setSavedNote] = useState(null);
  const [error, setError] = useState(null);

  const load = useCallback(async () => {
    setLoading(true); setError(null);
    try {
      const [pricingRes, subsRes] = await Promise.all([
        adminApi.getVenueSubscriptionPricing(),
        adminApi.getVenueSubscriptions({ pageSize: 50 }),
      ]);
      setPricing(pricingRes.data.data);
      setSubs(subsRes.data.data?.items ?? []);
      // Coach commission sits behind a finance permission — absence is not an error.
      try {
        const cc = await adminApi.getCoachCommission();
        setCoachCommission(String(cc.data.data?.percent ?? ''));
      } catch { /* no finance.view */ }
    } catch (e) {
      setError(e?.response?.data?.messageAr || 'تعذّر تحميل بيانات الاشتراكات');
    } finally { setLoading(false); }
  }, []);

  useEffect(() => { load(); }, [load]);

  const savePricing = async () => {
    setSaving(true); setSavedNote(null);
    try {
      await adminApi.saveVenueSubscriptionPricing({
        monthlyOneCourt: Number(pricing.monthlyOneCourt),
        monthlyTwoCourts: Number(pricing.monthlyTwoCourts),
        monthlyExtraCourt: Number(pricing.monthlyExtraCourt),
        yearlyOneCourt: Number(pricing.yearlyOneCourt),
        yearlyTwoCourts: Number(pricing.yearlyTwoCourts),
        yearlyExtraCourt: Number(pricing.yearlyExtraCourt),
        isActive: pricing.isActive,
      });
      setSavedNote('تم حفظ التسعيرة');
    } catch (e) {
      setSavedNote(e?.response?.data?.messageAr || 'تعذّر الحفظ');
    } finally { setSaving(false); }
  };

  const saveCoachCommission = async () => {
    setSavedNote(null);
    try {
      await adminApi.setCoachCommission(Number(coachCommission));
      setSavedNote('تم حفظ نسبة عمولة المدربين');
    } catch (e) {
      setSavedNote(e?.response?.data?.messageAr || 'تعذّر الحفظ');
    }
  };

  const set = (key, value) => setPricing(p => ({ ...p, [key]: value }));

  if (loading) return <div><PageHeader title="اشتراكات الملاعب" /><Spinner /></div>;
  if (error) return <div><PageHeader title="اشتراكات الملاعب" /><div className="text-center py-16 text-red-500 text-sm">{error}</div></div>;

  return (
    <div>
      <PageHeader title="اشتراكات الملاعب" subtitle={`${subs.length} اشتراك`} />

      <div className="grid grid-cols-1 lg:grid-cols-2 gap-6 mb-6">
        {/* Pricing tiers */}
        <div className="bg-white rounded-2xl shadow-sm border border-gray-100 p-5">
          <h3 className="font-bold text-gray-800 text-sm mb-4 flex items-center gap-2">
            <CreditCard className="w-4 h-4 text-[#2AB5CE]" /> التسعيرة المتدرّجة
          </h3>

          <p className="text-xs text-gray-500 mb-3">الاشتراك الشهري</p>
          <div className="grid grid-cols-3 gap-3 mb-5">
            {[
              ['monthlyOneCourt', 'ملعب واحد'],
              ['monthlyTwoCourts', 'ملعبان'],
              ['monthlyExtraCourt', 'كل ملعب إضافي'],
            ].map(([key, label]) => (
              <div key={key}>
                <label className="block text-xs text-gray-500 mb-1.5">{label}</label>
                <input type="number" step="any" disabled={!canManage} value={pricing[key]}
                  onChange={e => set(key, e.target.value)}
                  className={`${field} ${!canManage ? 'opacity-60' : ''}`} />
              </div>
            ))}
          </div>

          <p className="text-xs text-gray-500 mb-3">الاشتراك السنوي</p>
          <div className="grid grid-cols-3 gap-3">
            {[
              ['yearlyOneCourt', 'ملعب واحد'],
              ['yearlyTwoCourts', 'ملعبان'],
              ['yearlyExtraCourt', 'كل ملعب إضافي'],
            ].map(([key, label]) => (
              <div key={key}>
                <label className="block text-xs text-gray-500 mb-1.5">{label}</label>
                <input type="number" step="any" disabled={!canManage} value={pricing[key]}
                  onChange={e => set(key, e.target.value)}
                  className={`${field} ${!canManage ? 'opacity-60' : ''}`} />
              </div>
            ))}
          </div>

          <label className="flex items-center gap-3 mt-5 cursor-pointer">
            <input type="checkbox" disabled={!canManage} checked={pricing.isActive}
              onChange={e => set('isActive', e.target.checked)}
              className="w-4 h-4 rounded accent-[#2AB5CE]" />
            <span className="text-sm text-gray-700">الاشتراك مفعّل</span>
          </label>

          {canManage && (
            <button onClick={savePricing} disabled={saving}
              className="mt-5 w-full py-2.5 bg-[#2AB5CE] hover:bg-[#1E9AB0] disabled:bg-gray-200 text-white font-medium rounded-xl transition text-sm flex items-center justify-center gap-2">
              <Save className="w-4 h-4" /> {saving ? 'جارٍ الحفظ...' : 'حفظ التسعيرة'}
            </button>
          )}

          {/* Coach commission lives with the other platform fees */}
          {coachCommission !== '' && (
            <div className="mt-6 pt-5 border-t border-gray-100">
              <label className="block text-sm font-medium text-gray-700 mb-1.5">
                نسبة سبورتا على جلسات المدربين (%)
              </label>
              <div className="flex gap-2">
                <input type="number" step="any" min="0" max="100" disabled={!canEditCommission}
                  value={coachCommission} onChange={e => setCoachCommission(e.target.value)}
                  className={`${field} ${!canEditCommission ? 'opacity-60' : ''}`} />
                {canEditCommission && (
                  <button onClick={saveCoachCommission}
                    className="px-4 py-2.5 bg-[#2AB5CE] hover:bg-[#1E9AB0] text-white rounded-xl text-sm font-medium shrink-0">
                    حفظ
                  </button>
                )}
              </div>
              <p className="text-xs text-gray-400 mt-1">تُقتطع من مستحقات المدرب — اللاعب يدفع السعر المعروض.</p>
            </div>
          )}

          {savedNote && <p className="mt-3 text-sm text-[#2AB5CE]">{savedNote}</p>}
        </div>

        <PricePreview pricing={pricing} />
      </div>

      {/* Subscribers */}
      <div className="bg-white rounded-2xl shadow-sm border border-gray-100 overflow-hidden">
        <div className="px-5 py-4 border-b border-gray-100">
          <h3 className="font-bold text-gray-800 text-sm flex items-center gap-2">
            <Store className="w-4 h-4 text-[#2AB5CE]" /> المشتركون
          </h3>
        </div>
        {subs.length === 0 ? <Empty icon={Calendar} text="لا اشتراكات بعد" />
        : (
          <div className="overflow-x-auto">
            <table className="w-full text-sm">
              <thead className="bg-gray-50 text-gray-500 text-xs">
                <tr>
                  <th className="px-5 py-2.5 text-right font-medium">الحساب</th>
                  <th className="px-5 py-2.5 text-right font-medium">النوع</th>
                  <th className="px-5 py-2.5 text-right font-medium">الملاعب</th>
                  <th className="px-5 py-2.5 text-right font-medium">الأساسي</th>
                  <th className="px-5 py-2.5 text-right font-medium">الخصم</th>
                  <th className="px-5 py-2.5 text-right font-medium">المدفوع</th>
                  <th className="px-5 py-2.5 text-right font-medium">ينتهي</th>
                  <th className="px-5 py-2.5 text-right font-medium">الحالة</th>
                </tr>
              </thead>
              <tbody className="divide-y divide-gray-50">
                {subs.map(s => (
                  <tr key={s.id} className="hover:bg-gray-50/50">
                    <td className="px-5 py-3 text-gray-800">{s.ownerName}</td>
                    <td className="px-5 py-3 text-gray-600">{s.isYearly ? 'سنوي' : 'شهري'}</td>
                    <td className="px-5 py-3 text-gray-600">{s.courtCount}</td>
                    <td className="px-5 py-3 text-gray-600">{money(s.basePrice)}</td>
                    <td className="px-5 py-3 text-gray-600">{Number(s.discountPercent)}%</td>
                    <td className="px-5 py-3 font-medium text-gray-800">{money(s.paidAmount)}</td>
                    <td className="px-5 py-3 text-gray-600">{date(s.endsAt)}</td>
                    <td className="px-5 py-3">
                      <span className={`text-[11px] px-2 py-1 rounded-lg ${
                        s.isCurrent ? 'bg-green-50 text-green-700' : 'bg-gray-100 text-gray-500'}`}>
                        {s.isCurrent ? 'ساري' : 'منتهٍ'}
                      </span>
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        )}
      </div>
    </div>
  );
}
