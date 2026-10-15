import { useState } from 'react';
import { Star, Plus, Minus } from 'lucide-react';
import { adminApi } from '../api/adminApi';
import { useApi } from '../hooks/useApi';
import { Spinner } from './TableBits';
import { pointsTypeLabels, formatDate } from '../utils/accountLabels';

/** رصيد نقاط الولاء + السجل + منح/خصم يدوي. */
export default function PointsCard({ userId }) {
  const { data, loading, error, refetch } = useApi(
    () => adminApi.getUserPoints(userId, 1, 10), [userId]);
  const [amount, setAmount] = useState('');
  const [reason, setReason] = useState('');
  const [saving, setSaving] = useState(false);
  const [err, setErr] = useState(null);

  const adjust = async (sign) => {
    const value = Math.abs(Number(amount));
    if (!value) return;
    setSaving(true);
    setErr(null);
    try {
      await adminApi.adjustUserPoints(userId, sign * value, reason || null);
      setAmount('');
      setReason('');
      refetch();
    } catch (e) {
      setErr(e?.response?.data?.messageAr || 'تعذّر تعديل النقاط');
    } finally { setSaving(false); }
  };

  return (
    <div className="bg-white rounded-2xl border border-gray-100 p-5 shadow-sm">
      <div className="flex items-center justify-between mb-4">
        <p className="font-semibold text-gray-800 flex items-center gap-2">
          <Star className="w-4 h-4 text-amber-500" /> نقاط الولاء
        </p>
        {data && (
          <span className="text-lg font-black text-amber-600">
            {data.balance} نقطة
            <span className="text-xs text-gray-400 font-normal mr-2">≈ {data.balanceValueSar} ر.س</span>
          </span>
        )}
      </div>

      {loading ? <Spinner /> : error ? (
        <p className="text-sm text-red-500">{error}</p>
      ) : (
        <>
          <div className="flex flex-wrap items-end gap-2 mb-4">
            <div>
              <label className="block text-xs text-gray-500 mb-1">عدد النقاط</label>
              <input type="number" min="1" value={amount}
                onChange={e => setAmount(e.target.value)}
                className="w-28 px-3 py-2 border border-gray-200 rounded-xl text-sm focus:outline-none focus:ring-2 focus:ring-[#2AB5CE] bg-gray-50" />
            </div>
            <div className="flex-1 min-w-[160px]">
              <label className="block text-xs text-gray-500 mb-1">السبب (اختياري)</label>
              <input value={reason} onChange={e => setReason(e.target.value)}
                placeholder="مثال: تعويض عن مشكلة تقنية"
                className="w-full px-3 py-2 border border-gray-200 rounded-xl text-sm focus:outline-none focus:ring-2 focus:ring-[#2AB5CE] bg-gray-50" />
            </div>
            <button onClick={() => adjust(1)} disabled={saving || !Number(amount)}
              className="flex items-center gap-1 px-4 py-2 rounded-xl text-sm font-medium bg-green-50 text-green-700 hover:bg-green-100 disabled:opacity-40 transition">
              <Plus className="w-4 h-4" /> منح
            </button>
            <button onClick={() => adjust(-1)} disabled={saving || !Number(amount)}
              className="flex items-center gap-1 px-4 py-2 rounded-xl text-sm font-medium bg-red-50 text-red-600 hover:bg-red-100 disabled:opacity-40 transition">
              <Minus className="w-4 h-4" /> خصم
            </button>
          </div>
          {err && <p className="text-sm text-red-500 mb-3">{err}</p>}

          {(data?.transactions?.items ?? []).length === 0 ? (
            <p className="text-sm text-gray-400">لا توجد حركات نقاط بعد.</p>
          ) : (
            <div className="divide-y divide-gray-50">
              {data.transactions.items.map(t => (
                <div key={t.id} className="flex items-center justify-between py-2.5">
                  <div>
                    <p className="text-sm text-gray-700">{t.description || pointsTypeLabels[t.type] || t.type}</p>
                    <p className="text-xs text-gray-400">
                      {pointsTypeLabels[t.type] || t.type} · {formatDate(t.createdAt)}
                    </p>
                  </div>
                  <span className={`text-sm font-bold ${t.amount > 0 ? 'text-green-600' : 'text-red-500'}`}>
                    {t.amount > 0 ? `+${t.amount}` : t.amount}
                  </span>
                </div>
              ))}
            </div>
          )}
        </>
      )}
    </div>
  );
}
