import { useParams, useNavigate } from 'react-router-dom';
import { ArrowRight, MapPin, Clock, Users, DollarSign, BarChart3, Swords } from 'lucide-react';
import { matchesApi } from '../api/matchesApi';
import { useApi } from '../hooks/useApi';
import { Spinner } from '../components/TableBits';
import StatusBadge from '../components/StatusBadge';

const statusMap = {
  Open: ['upcoming', 'مفتوحة'], Full: ['upcoming', 'مكتملة'],
  InProgress: ['upcoming', 'جارية'], Completed: ['completed', 'منتهية'],
  Cancelled: ['inactive', 'ملغاة'],
};

function fmt(iso) {
  const d = new Date(iso);
  return Number.isNaN(d.getTime()) ? '—'
    : d.toLocaleString('ar', { weekday: 'long', day: 'numeric', month: 'long', hour: '2-digit', minute: '2-digit' });
}

export default function MatchDetailPage() {
  const { id } = useParams();
  const navigate = useNavigate();
  const { data: m, loading, error } = useApi(() => matchesApi.getById(id), [id]);

  if (loading) return <Spinner />;
  if (error || !m) {
    return (
      <div className="text-center py-20 text-gray-400">
        {error || 'المباراة غير موجودة'}
        <div className="mt-4">
          <button onClick={() => navigate('/matches')} className="text-[#2AB5CE] hover:underline">العودة للمباريات</button>
        </div>
      </div>
    );
  }

  const [badge, label] = statusMap[m.status] ?? ['upcoming', m.status];
  const rows = [
    { icon: Swords, label: 'النوع', value: m.matchType },
    { icon: Clock, label: 'الموعد', value: fmt(m.scheduledAt) },
    { icon: Clock, label: 'المدة', value: `${m.durationMinutes} دقيقة` },
    { icon: MapPin, label: 'الموقع', value: [m.venueName, m.city, m.neighborhood].filter(Boolean).join('، ') || '—' },
    { icon: BarChart3, label: 'المستوى', value: `${m.minLevel} - ${m.maxLevel}` },
    { icon: Users, label: 'اللاعبون', value: `${m.currentPlayers}/${m.maxPlayers}` },
    { icon: DollarSign, label: 'السعر للاعب', value: `${m.pricePerPlayer} ر.س` },
  ];

  return (
    <div>
      <button onClick={() => navigate('/matches')}
        className="flex items-center gap-1 text-sm text-gray-500 hover:text-gray-700 mb-4">
        <ArrowRight className="w-4 h-4" /> العودة للمباريات
      </button>

      <div className="bg-gradient-to-br from-violet-500 to-purple-700 rounded-2xl p-6 text-white mb-6">
        <div className="flex items-center justify-between">
          <div>
            <p className="text-white/70 text-sm mb-1">مباراة #{m.id}</p>
            <h2 className="text-2xl font-bold">{m.matchType}</h2>
          </div>
          <StatusBadge status={badge} label={label} />
        </div>
      </div>

      <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
        <div className="bg-white rounded-2xl border border-gray-100 p-5 shadow-sm">
          <p className="font-semibold text-gray-800 mb-4">تفاصيل المباراة</p>
          <div className="divide-y divide-gray-50">
            {rows.map((r) => (
              <div key={r.label} className="flex items-center justify-between py-3">
                <span className="flex items-center gap-2 text-gray-500 text-sm">
                  <r.icon className="w-4 h-4 text-gray-400" /> {r.label}
                </span>
                <span className="font-medium text-gray-800 text-sm">{r.value}</span>
              </div>
            ))}
          </div>
          {m.notes && <p className="text-sm text-gray-500 mt-3 border-t border-gray-50 pt-3">{m.notes}</p>}
        </div>

        <div className="bg-white rounded-2xl border border-gray-100 p-5 shadow-sm">
          <p className="font-semibold text-gray-800 mb-4">اللاعبون ({m.players?.length ?? 0})</p>
          <div className="space-y-2">
            {(m.players ?? []).map((p) => (
              <div key={p.userId ?? p.id} className="flex items-center gap-3 py-2 border-b border-gray-50 last:border-0">
                <div className="w-9 h-9 rounded-full bg-violet-100 text-violet-600 flex items-center justify-center font-bold text-sm">
                  {p.name?.[0] ?? '؟'}
                </div>
                <div>
                  <p className="text-sm font-medium text-gray-800">{p.name}</p>
                  {p.level != null && <p className="text-xs text-gray-400">مستوى {p.level}</p>}
                </div>
              </div>
            ))}
            {(m.players ?? []).length === 0 && <p className="text-sm text-gray-400 text-center py-6">لا يوجد لاعبون</p>}
          </div>
        </div>
      </div>
    </div>
  );
}
