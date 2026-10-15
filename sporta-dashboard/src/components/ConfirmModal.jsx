import { AlertTriangle } from 'lucide-react';

export default function ConfirmModal({ open, title, message, onConfirm, onCancel, danger = true }) {
  if (!open) return null;
  return (
    <div className="fixed inset-0 bg-black/50 z-50 flex items-center justify-center p-4">
      <div className="bg-white rounded-2xl shadow-2xl w-full max-w-sm p-6 text-center">
        <div className={`inline-flex w-14 h-14 rounded-full items-center justify-center mb-4 ${danger ? 'bg-red-100' : 'bg-yellow-100'}`}>
          <AlertTriangle className={`w-7 h-7 ${danger ? 'text-red-500' : 'text-yellow-500'}`} />
        </div>
        <h3 className="text-lg font-bold text-gray-800 mb-2">{title}</h3>
        <p className="text-gray-500 text-sm mb-6">{message}</p>
        <div className="flex gap-3">
          <button
            onClick={onCancel}
            className="flex-1 py-2.5 border border-gray-200 rounded-xl text-gray-600 font-medium hover:bg-gray-50 transition"
          >
            إلغاء
          </button>
          <button
            onClick={onConfirm}
            className={`flex-1 py-2.5 rounded-xl text-white font-medium transition ${danger ? 'bg-red-500 hover:bg-red-600' : 'bg-yellow-500 hover:bg-yellow-600'}`}
          >
            تأكيد
          </button>
        </div>
      </div>
    </div>
  );
}
