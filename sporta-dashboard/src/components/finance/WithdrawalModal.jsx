import { useState } from 'react';
import { X, Landmark, Check, Ban } from 'lucide-react';
import { money, fmtDateTime, WITHDRAWAL_STATUS } from './financeMeta';
import StatusBadge from '../StatusBadge';

function Row({ label, value, mono }) {
  return (
    <div className="flex items-start justify-between gap-4 py-2.5 border-b border-gray-50 last:border-0">
      <span className="text-sm text-gray-500 shrink-0">{label}</span>
      <span className={`text-sm text-gray-800 font-medium text-left ${mono ? 'font-mono text-xs' : ''}`}>{value ?? '-'}</span>
    </div>
  );
}

export default function WithdrawalModal({ request, onClose, onProcess, processing }) {
  const [notes, setNotes] = useState('');
  if (!request) return null;

  const st = WITHDRAWAL_STATUS[request.status] ?? { label: request.status, badge: 'pending' };
  const isPending = request.status === 'pending';

  return (
    <div className="fixed inset-0 bg-black/50 z-50 flex items-center justify-center p-4" onClick={onClose}>
      <div className="bg-white rounded-2xl shadow-2xl w-full max-w-md max-h-[90vh] overflow-y-auto" onClick={(e) => e.stopPropagation()}>
        <div className="flex items-center justify-between px-6 py-4 border-b border-gray-100">
          <h3 className="text-lg font-bold text-gray-800">طلب سحب رصيد</h3>
          <button onClick={onClose} className="text-gray-400 hover:text-gray-600"><X className="w-5 h-5" /></button>
        </div>

        <div className="px-6 py-5 text-center border-b border-gray-100">
          <div className="inline-flex w-12 h-12 rounded-full items-center justify-center mb-2 bg-orange-100">
            <Landmark className="w-6 h-6 text-orange-500" />
          </div>
          <p className="text-2xl font-bold text-gray-800">{money(request.amount)}</p>
          <div className="mt-2"><StatusBadge status={st.badge} label={st.label} /></div>
        </div>

        <div className="px-6 py-3">
          <Row label="رقم الطلب" value={`#${request.id}`} mono />
          <Row label="المستخدم" value={request.userName} />
          <Row label="الجوال" value={request.userPhone} mono />
          <Row label="اسم صاحب الحساب" value={request.accountHolderName} />
          <Row label="البنك" value={request.bankName} />
          <Row label="الآيبان (IBAN)" value={request.iban} mono />
          <Row label="تاريخ الطلب" value={fmtDateTime(request.createdAt)} />
          {request.processedAt && <Row label="تاريخ المعالجة" value={fmtDateTime(request.processedAt)} />}
          {request.adminNotes && <Row label="ملاحظات الإدارة" value={request.adminNotes} />}
        </div>

        {isPending ? (
          <div className="px-6 py-4 border-t border-gray-100 space-y-3">
            <textarea
              value={notes}
              onChange={(e) => setNotes(e.target.value)}
              placeholder="ملاحظات (اختياري) — تظهر للمستخدم"
              rows={2}
              className="w-full px-3 py-2 border border-gray-200 rounded-xl text-sm focus:outline-none focus:ring-2 focus:ring-[#2AB5CE] resize-none"
            />
            <div className="flex gap-3">
              <button
                disabled={processing}
                onClick={() => onProcess(request.id, { approved: false, adminNotes: notes || null })}
                className="flex-1 flex items-center justify-center gap-2 py-2.5 rounded-xl border border-red-200 text-red-600 font-medium hover:bg-red-50 transition disabled:opacity-50"
              >
                <Ban className="w-4 h-4" /> رفض واسترداد
              </button>
              <button
                disabled={processing}
                onClick={() => onProcess(request.id, { approved: true, adminNotes: notes || null })}
                className="flex-1 flex items-center justify-center gap-2 py-2.5 rounded-xl bg-green-600 text-white font-medium hover:bg-green-700 transition disabled:opacity-50"
              >
                <Check className="w-4 h-4" /> موافقة
              </button>
            </div>
            <p className="text-xs text-gray-400 text-center">
              الرفض يعيد المبلغ إلى محفظة المستخدم تلقائياً. الموافقة تعني تحويل المبلغ للبنك يدوياً.
            </p>
          </div>
        ) : (
          <div className="px-6 py-4 border-t border-gray-100">
            <button onClick={onClose} className="w-full py-2.5 rounded-xl bg-gray-100 text-gray-700 font-medium hover:bg-gray-200 transition">إغلاق</button>
          </div>
        )}
      </div>
    </div>
  );
}
