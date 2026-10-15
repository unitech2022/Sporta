import { AlertCircle, RefreshCw } from 'lucide-react';

export function LoadingTable({ rows = 5, cols = 6 }) {
  return (
    <div className="bg-white rounded-2xl shadow-sm border border-gray-100 overflow-hidden">
      <div className="overflow-x-auto">
        <table className="w-full text-sm">
          <tbody>
            {Array.from({ length: rows }).map((_, i) => (
              <tr key={i} className="border-b border-gray-50">
                {Array.from({ length: cols }).map((_, j) => (
                  <td key={j} className="px-5 py-4">
                    <div className="h-4 bg-gray-100 rounded animate-pulse" style={{ width: `${60 + (j * 10) % 30}%` }} />
                  </td>
                ))}
              </tr>
            ))}
          </tbody>
        </table>
      </div>
    </div>
  );
}

export function ErrorState({ message, onRetry }) {
  return (
    <div className="bg-white rounded-2xl border border-red-100 p-10 text-center">
      <div className="w-14 h-14 bg-red-50 rounded-full flex items-center justify-center mx-auto mb-3">
        <AlertCircle className="w-7 h-7 text-red-400" />
      </div>
      <p className="text-gray-700 font-medium mb-1">تعذّر تحميل البيانات</p>
      <p className="text-sm text-gray-400 mb-4">{message}</p>
      {onRetry && (
        <button onClick={onRetry}
          className="inline-flex items-center gap-2 px-4 py-2 bg-red-50 text-red-600 border border-red-200 rounded-xl text-sm font-medium hover:bg-red-100 transition">
          <RefreshCw className="w-4 h-4" /> إعادة المحاولة
        </button>
      )}
    </div>
  );
}
