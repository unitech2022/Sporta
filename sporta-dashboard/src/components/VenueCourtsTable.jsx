import { useState } from 'react';
import { useNavigate } from 'react-router-dom';
import { LayoutGrid, Eye, Ban, Play, Trash2 } from 'lucide-react';
import { courtsApi } from '../api/courtsApi';
import StatusBadge from '../components/StatusBadge';
import ConfirmModal from '../components/ConfirmModal';
import { Th } from '../components/TableBits';
import { useAuth } from '../context/AuthContext';

/**
 * ملاعب النادي داخل صفحة تفاصيله — القسم أصبح واحداً، فلا توجد قائمة ملاعب
 * مستقلة؛ الإيقاف/التفعيل يتم من هنا مباشرة.
 *
 * @param {{ courts: any[], onChanged: () => Promise<any> }} props
 */
export default function VenueCourtsTable({ courts = [], onChanged }) {
  const navigate = useNavigate();
  const { can } = useAuth();
  const canDelete = can('courts.delete');

  const [confirm, setConfirm] = useState(null);   // { court, suspend }
  const [deleting, setDeleting] = useState(null); // court pending delete
  const [busyId, setBusyId] = useState(null);
  const [actionError, setActionError] = useState(null);

  const applySuspend = async () => {
    if (!confirm) return;
    const { court, suspend } = confirm;
    setBusyId(court.id);
    setActionError(null);
    setConfirm(null);
    try {
      await courtsApi.setSuspended(court.id, suspend);
      await onChanged?.();
    } catch (err) {
      setActionError(err?.response?.data?.messageAr || err?.response?.data?.message || 'تعذّر تنفيذ العملية');
    } finally {
      setBusyId(null);
    }
  };

  const remove = async () => {
    if (!deleting) return;
    const court = deleting;
    setBusyId(court.id);
    setActionError(null);
    setDeleting(null);
    try {
      await courtsApi.remove(court.id);
      await onChanged?.();
    } catch (err) {
      setActionError(err?.response?.data?.messageAr || err?.response?.data?.message || 'تعذّر حذف الملعب');
    } finally {
      setBusyId(null);
    }
  };

  return (
    <div className="bg-white rounded-2xl border border-gray-100 p-5 shadow-sm">
      <div className="flex items-center gap-2 text-gray-700 font-semibold mb-4">
        <LayoutGrid className="w-4 h-4 text-[#2AB5CE]" /> ملاعب النادي
        <span className="text-xs font-normal text-gray-400">({courts.length})</span>
      </div>

      {actionError && (
        <div className="mb-3 px-4 py-3 bg-red-50 border border-red-100 text-red-600 rounded-xl text-sm">{actionError}</div>
      )}

      {courts.length === 0 ? (
        <p className="text-sm text-gray-400 py-4 text-center">لم يُضف أي ملعب لهذا النادي بعد</p>
      ) : (
        <div className="overflow-x-auto -mx-5 px-5">
          <table className="w-full text-sm">
            <thead>
              <tr className="border-b border-gray-100 bg-gray-50">
                <Th>الملعب</Th><Th>النوع</Th><Th>العدد</Th>
                <Th>السعر</Th><Th>نسبة سبورتا</Th><Th>الحالة</Th><Th>الإجراءات</Th>
              </tr>
            </thead>
            <tbody className="divide-y divide-gray-50">
              {courts.map((c) => (
                <tr key={c.id} className={`transition ${c.isSuspended ? 'bg-red-50/40' : 'hover:bg-gray-50/50'}`}>
                  <td className="px-5 py-3 font-semibold text-gray-800">{c.name}</td>
                  <td className="px-4 py-3 text-gray-600">{c.type === 'outdoor' ? 'خارجي' : 'داخلي'}</td>
                  <td className="px-4 py-3 text-gray-600">{c.courtCount}</td>
                  <td className="px-4 py-3 text-gray-600">{Number(c.basePrice ?? 0).toFixed(0)} ر.س</td>
                  <td className="px-4 py-3">
                    <span className="px-2 py-0.5 bg-cyan-50 text-cyan-700 rounded-lg text-xs font-semibold">
                      {Number(c.sportaCommissionPercent ?? 0).toFixed(0)}%
                    </span>
                  </td>
                  <td className="px-4 py-3">
                    {c.isSuspended ? (
                      <span className="px-2.5 py-1 bg-red-100 text-red-700 rounded-lg text-xs font-semibold">موقوف</span>
                    ) : (
                      <StatusBadge status={c.isAvailable ? 'active' : 'inactive'}
                        label={c.isAvailable ? 'متاح' : 'غير متاح'} />
                    )}
                  </td>
                  <td className="px-4 py-3">
                    <div className="flex items-center gap-1.5">
                      <button onClick={() => navigate(`/courts/${c.id}`)}
                        className="flex items-center gap-1 px-2.5 py-1.5 rounded-lg bg-blue-50 text-blue-600 hover:bg-blue-100 transition text-xs font-medium">
                        <Eye className="w-3.5 h-3.5" /> عرض
                      </button>
                      {c.isSuspended ? (
                        <button disabled={busyId === c.id} onClick={() => setConfirm({ court: c, suspend: false })}
                          className="flex items-center gap-1 px-2.5 py-1.5 rounded-lg bg-green-50 text-green-700 hover:bg-green-100 transition text-xs font-medium disabled:opacity-50">
                          <Play className="w-3.5 h-3.5" /> تفعيل
                        </button>
                      ) : (
                        <button disabled={busyId === c.id} onClick={() => setConfirm({ court: c, suspend: true })}
                          className="flex items-center gap-1 px-2.5 py-1.5 rounded-lg bg-red-50 text-red-600 hover:bg-red-100 transition text-xs font-medium disabled:opacity-50">
                          <Ban className="w-3.5 h-3.5" /> إيقاف
                        </button>
                      )}
                      {canDelete && (
                        <button disabled={busyId === c.id} onClick={() => setDeleting(c)}
                          title="حذف الملعب"
                          className="flex items-center gap-1 px-2.5 py-1.5 rounded-lg bg-red-100 text-red-700 hover:bg-red-200 transition text-xs font-medium disabled:opacity-50">
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
      )}

      <ConfirmModal
        open={!!confirm}
        danger={confirm?.suspend}
        title={confirm?.suspend ? 'إيقاف الملعب' : 'تفعيل الملعب'}
        message={confirm?.suspend
          ? `سيتم إيقاف ملعب "${confirm?.court.name}" وإخفاؤه عن اللاعبين، وسيصل إشعار للملعب. هل تريد المتابعة؟`
          : `سيتم إعادة تفعيل ملعب "${confirm?.court.name}" وإظهاره للاعبين مجدداً، وسيصل إشعار للملعب.`}
        onConfirm={applySuspend}
        onCancel={() => setConfirm(null)}
      />

      <ConfirmModal
        open={!!deleting}
        title="حذف الملعب"
        message={`سيُحذف ملعب "${deleting?.name}" من المنصة: تُلغى الحجوزات القادمة عليه ويُعاد ما دفعه اللاعبون إلى محافظهم، ويصل إشعار للملعب. لا يمكن التراجع عن هذه العملية.`}
        onConfirm={remove}
        onCancel={() => setDeleting(null)}
      />
    </div>
  );
}
