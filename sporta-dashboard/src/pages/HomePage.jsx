import {
  Users, Building2, Swords, CalendarCheck, DollarSign,
  UserCheck, TrendingUp, Megaphone, ArrowUpRight, Trophy, Store,
} from 'lucide-react';
import { adminApi } from '../api/adminApi';
import { matchesApi } from '../api/matchesApi';
import { useApi } from '../hooks/useApi';
import StatusBadge from '../components/StatusBadge';

const matchStatus = (s) =>
  ({ Open: 'upcoming', Full: 'upcoming', InProgress: 'upcoming', Completed: 'completed', Cancelled: 'inactive' }[s] || 'upcoming');

export default function HomePage() {
  const { data: stats, loading } = useApi(() => adminApi.getStats(), []);
  const { data: matches } = useApi(() => matchesApi.getAll(), []);
  const { data: ads } = useApi(() => adminApi.getAds(), []);

  const cards = [
    { label: 'إجمالي المستخدمين', value: stats?.totalUsers, icon: Users, light: '#EFF6FF', text: '#2563EB' },
    { label: 'اللاعبون', value: stats?.totalPlayers, icon: TrendingUp, light: '#EEF2FF', text: '#4338CA' },
    { label: 'المدربون', value: stats?.totalCoaches, icon: UserCheck, light: '#F0FDFA', text: '#0D9488' },
    { label: 'الملاعب', value: stats?.totalVenueOwners, icon: Store, light: '#FFF7ED', text: '#EA580C' },
    { label: 'الملاعب', value: stats?.totalCourts, icon: Building2, light: '#E0F7FA', text: '#2AB5CE' },
    { label: 'المباريات', value: stats?.totalMatches, icon: Swords, light: '#F5F3FF', text: '#7C3AED' },
    { label: 'الحجوزات', value: stats?.totalBookings, icon: CalendarCheck, light: '#FFF7ED', text: '#EA580C' },
    { label: 'حجوزات معلقة', value: stats?.pendingBookings, icon: CalendarCheck, light: '#FEF2F2', text: '#DC2626' },
    { label: 'البطولات', value: stats?.totalTournaments, icon: Trophy, light: '#FEFCE8', text: '#CA8A04' },
    { label: 'الإيرادات (ر.س)', value: stats ? Number(stats.totalRevenue).toLocaleString() : undefined, icon: DollarSign, light: '#ECFDF5', text: '#059669' },
  ];

  return (
    <div className="space-y-6">
      <div>
        <h2 className="text-xl font-bold text-gray-800 mb-1">مرحباً بك في لوحة تحكم سبورتا 👋</h2>
        <div className="flex items-center gap-2 text-gray-400 text-xs">
          <span className="w-2 h-2 bg-[#2AB5CE] rounded-full animate-pulse" />
          نظرة عامة على المنصة
        </div>
      </div>

      <div className="grid grid-cols-2 sm:grid-cols-3 lg:grid-cols-5 gap-4">
        {cards.map((card) => {
          const Icon = card.icon;
          return (
            <div key={card.label}
              className="bg-white rounded-2xl p-5 shadow-sm hover:shadow-md transition-all"
              style={{ border: '1px solid #E5E7EB' }}>
              <div className="flex items-start justify-between">
                <div>
                  <p className="text-xs text-gray-500 mb-2 font-medium">{card.label}</p>
                  <p className="text-2xl font-bold text-gray-800">
                    {loading || card.value === undefined ? '—' : card.value}
                  </p>
                </div>
                <div className="p-2.5 rounded-xl" style={{ backgroundColor: card.light }}>
                  <Icon className="w-5 h-5" style={{ color: card.text }} />
                </div>
              </div>
            </div>
          );
        })}
      </div>

      <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
        {/* Recent matches */}
        <div className="bg-white rounded-2xl p-5 shadow-sm border border-gray-100">
          <div className="flex items-center justify-between mb-4">
            <h3 className="font-bold text-gray-800">آخر المباريات</h3>
            <a href="/matches" className="text-xs text-[#2AB5CE] hover:underline flex items-center gap-1">
              عرض الكل <ArrowUpRight className="w-3 h-3" />
            </a>
          </div>
          <div className="space-y-3">
            {(matches ?? []).slice(0, 5).map((m) => (
              <div key={m.id} className="flex items-center justify-between py-2 border-b border-gray-50 last:border-0">
                <div>
                  <p className="text-sm font-medium text-gray-800">{m.typeLabel ?? 'مباراة'} · {m.currentPlayers}/{m.maxPlayers}</p>
                  <p className="text-xs text-gray-400">{m.venueName ?? '—'} · {m.city ?? ''}</p>
                </div>
                <StatusBadge status={matchStatus(m.status)} />
              </div>
            ))}
            {(matches ?? []).length === 0 && (
              <p className="text-sm text-gray-400 text-center py-6">لا توجد مباريات</p>
            )}
          </div>
        </div>

        {/* Recent announcements */}
        <div className="bg-white rounded-2xl p-5 shadow-sm border border-gray-100">
          <div className="flex items-center justify-between mb-4">
            <h3 className="font-bold text-gray-800">آخر الإعلانات</h3>
            <a href="/announcements" className="text-xs text-[#2AB5CE] hover:underline flex items-center gap-1">
              عرض الكل <ArrowUpRight className="w-3 h-3" />
            </a>
          </div>
          <div className="space-y-3">
            {(ads ?? []).slice(0, 5).map((a) => (
              <div key={a.id} className="flex items-center justify-between py-2 border-b border-gray-50 last:border-0">
                <div className="flex items-center gap-3 min-w-0">
                  <Megaphone className="w-4 h-4 text-[#2AB5CE] shrink-0" />
                  <div className="min-w-0">
                    <p className="text-sm font-medium text-gray-800 truncate">{a.title}</p>
                    <p className="text-xs text-gray-400 truncate">{a.subtitle}</p>
                  </div>
                </div>
                <StatusBadge status={a.isActive ? 'active' : 'inactive'} />
              </div>
            ))}
            {(ads ?? []).length === 0 && (
              <p className="text-sm text-gray-400 text-center py-6">لا توجد إعلانات</p>
            )}
          </div>
        </div>
      </div>
    </div>
  );
}
