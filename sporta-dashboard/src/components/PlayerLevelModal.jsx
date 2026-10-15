import { useEffect, useState } from 'react';
import { X, Save } from 'lucide-react';
import { playerLevelLabels } from '../utils/accountLabels';

const LEVELS = Object.keys(playerLevelLabels).map(Number);

/**
 * تعديل مستوى لاعب يدوياً. المستوى يحدّد المباريات التي يُقبل فيها، فالتعديل
 * هنا تجاوزٌ لما قرّره التقييم الذاتي أو المدرب — لذلك يُعرض المستوى الحالي
 * ويُطلب اختيار غيره صراحةً، ويصل اللاعبَ إشعارٌ بالتغيير.
 */
export default function PlayerLevelModal({ open, player, saving, error, onSave, onClose }) {
  const [level, setLevel] = useState(player?.level ?? 1);

  useEffect(() => {
    if (open) setLevel(player?.level ?? 1);
  }, [open, player]);

  if (!open) return null;

  const unchanged = level === player?.level;

  return (
    <div className="fixed inset-0 bg-black/50 z-50 flex items-center justify-center p-4">
      <div className="bg-white rounded-2xl shadow-2xl w-full max-w-md flex flex-col">
        <div className="flex items-center justify-between px-6 py-4 border-b border-gray-100">
          <h3 className="font-bold text-gray-800 text-lg">تعديل المستوى</h3>
          <button onClick={onClose} className="w-8 h-8 flex items-center justify-center rounded-lg hover:bg-gray-100 text-gray-400">
            <X className="w-5 h-5" />
          </button>
        </div>

        <div className="p-6 space-y-4">
          <p className="text-sm text-gray-500">
            اللاعب <span className="font-semibold text-gray-800">{player?.fullName}</span>
            {player?.level
              ? <> — مستواه الحالي <span className="font-semibold text-gray-800">{player.level} ({playerLevelLabels[player.level]})</span></>
              : ' — غير مُقيّم بعد'}
          </p>

          <div>
            <label className="block text-sm font-medium text-gray-700 mb-1.5">المستوى الجديد</label>
            <div className="grid grid-cols-2 gap-2">
              {LEVELS.map((n) => (
                <button
                  key={n}
                  type="button"
                  onClick={() => setLevel(n)}
                  className={`px-3 py-2.5 rounded-xl text-sm font-medium border transition text-right ${
                    level === n
                      ? 'bg-[#2AB5CE] border-[#2AB5CE] text-white'
                      : 'bg-gray-50 border-gray-200 text-gray-700 hover:bg-gray-100'
                  }`}
                >
                  {n} — {playerLevelLabels[n]}
                </button>
              ))}
            </div>
          </div>

          <p className="text-xs text-gray-400">
            يصل اللاعب إشعارٌ بمستواه الجديد، ويؤثّر المستوى على المباريات التي يحقّ له الانضمام إليها.
          </p>

          {error && (
            <div className="px-4 py-3 bg-red-50 border border-red-100 text-red-600 rounded-xl text-sm">{error}</div>
          )}
        </div>

        <div className="flex gap-3 px-6 py-4 border-t border-gray-100">
          <button onClick={onClose}
            className="flex-1 py-2.5 border border-gray-200 rounded-xl text-gray-600 font-medium hover:bg-gray-50 transition text-sm">
            إلغاء
          </button>
          <button
            onClick={() => !unchanged && !saving && onSave(level)}
            disabled={unchanged || saving}
            className="flex-1 py-2.5 bg-[#2AB5CE] hover:bg-[#1E9AB0] disabled:bg-gray-200 disabled:text-gray-400 text-white font-medium rounded-xl transition text-sm flex items-center justify-center gap-2"
          >
            <Save className="w-4 h-4" />
            {saving ? 'جارٍ الحفظ...' : 'حفظ المستوى'}
          </button>
        </div>
      </div>
    </div>
  );
}
