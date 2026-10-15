import { X, ArrowDownLeft, ArrowUpRight, Copy } from 'lucide-react';
import { txLabel, money, fmtDateTime } from './financeMeta';

function Row({ label, value, mono }) {
  return (
    <div className="flex items-start justify-between gap-4 py-2.5 border-b border-gray-50 last:border-0">
      <span className="text-sm text-gray-500 shrink-0">{label}</span>
      <span className={`text-sm text-gray-800 font-medium text-left ${mono ? 'font-mono text-xs' : ''}`}>
        {value ?? '-'}
      </span>
    </div>
  );
}

export default function TransactionDetailModal({ tx, onClose }) {
  if (!tx) return null;

  const isIn = tx.direction === 'in';
  const copy = (text) => { if (text) navigator.clipboard?.writeText(String(text)); };

  return (
    <div className="fixed inset-0 bg-black/50 z-50 flex items-center justify-center p-4" onClick={onClose}>
      <div className="bg-white rounded-2xl shadow-2xl w-full max-w-md" onClick={(e) => e.stopPropagation()}>
        {/* Header */}
        <div className="flex items-center justify-between px-6 py-4 border-b border-gray-100">
          <h3 className="text-lg font-bold text-gray-800">تفاصيل المعاملة</h3>
          <button onClick={onClose} className="text-gray-400 hover:text-gray-600">
            <X className="w-5 h-5" />
          </button>
        </div>

        {/* Amount hero */}
        <div className="px-6 py-5 text-center border-b border-gray-100">
          <div className={`inline-flex w-12 h-12 rounded-full items-center justify-center mb-2 ${isIn ? 'bg-green-100' : 'bg-red-100'}`}>
            {isIn ? <ArrowDownLeft className="w-6 h-6 text-green-600" /> : <ArrowUpRight className="w-6 h-6 text-red-500" />}
          </div>
          <p className={`text-2xl font-bold ${isIn ? 'text-green-600' : 'text-red-500'}`}>{money(tx.amount)}</p>
          <p className="text-sm text-gray-500 mt-1">{txLabel(tx.type)}</p>
        </div>

        {/* Details */}
        <div className="px-6 py-3">
          <Row label="المرجع الداخلي" value={tx.internalReference} mono />
          <div className="flex items-start justify-between gap-4 py-2.5 border-b border-gray-50">
            <span className="text-sm text-gray-500 shrink-0">معرّف بوابة الدفع</span>
            <span className="text-sm text-gray-800 font-medium text-left flex items-center gap-2">
              {tx.paymentReference ? (
                <>
                  <span className="font-mono text-xs">{tx.paymentReference}</span>
                  <button onClick={() => copy(tx.paymentReference)} className="text-gray-400 hover:text-[#2AB5CE]">
                    <Copy className="w-3.5 h-3.5" />
                  </button>
                </>
              ) : (
                <span className="text-gray-400 text-xs">— لم تُربط بوابة دفع بعد</span>
              )}
            </span>
          </div>
          <Row label="المستخدم" value={tx.userName} />
          <Row label="الجوال" value={tx.userPhone} mono />
          <Row label="الاتجاه" value={isIn ? 'وارد (إضافة للمحفظة)' : 'صادر (خصم من المحفظة)'} />
          <Row label="مرجع العملية" value={tx.referenceId != null ? `#${tx.referenceId}` : null} mono />
          <Row label="الوصف" value={tx.description} />
          <Row label="التاريخ" value={fmtDateTime(tx.createdAt)} />
        </div>

        <div className="px-6 py-4 border-t border-gray-100">
          <button onClick={onClose} className="w-full py-2.5 rounded-xl bg-gray-100 text-gray-700 font-medium hover:bg-gray-200 transition">
            إغلاق
          </button>
        </div>
      </div>
    </div>
  );
}
