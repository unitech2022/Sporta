import { Menu, Bell, Search } from 'lucide-react';
import { useLocation, Link } from 'react-router-dom';

const pageNames = {
  '/': 'الرئيسية',
  '/sports': 'الألعاب الرياضية',
  '/venues': 'الأندية والملاعب',
  '/courts': 'الأندية والملاعب',
  '/coaches': 'المدربون',
  '/players': 'اللاعبون',
  '/matches': 'المباريات',
  '/announcements': 'الإعلانات',
  '/packages': 'الاشتراكات',
  '/invoices': 'الفواتير',
  '/notifications': 'الإشعارات',
  '/settings': 'الإعدادات',
};

export default function Header({ onMenuClick, unreadCount = 0 }) {
  const { pathname } = useLocation();
  const basePath = '/' + pathname.split('/')[1];
  const title = pageNames[basePath] ?? 'لوحة التحكم';

  return (
    <header className="h-16 bg-white border-b border-gray-100 flex items-center justify-between px-5 shrink-0 sticky top-0 z-10 shadow-sm">
      <div className="flex items-center gap-4">
        <button
          onClick={onMenuClick}
          className="lg:hidden w-9 h-9 flex items-center justify-center rounded-lg hover:bg-gray-100 text-gray-500"
        >
          <Menu className="w-5 h-5" />
        </button>
        <h1 className="text-lg font-bold text-gray-800">{title}</h1>
      </div>

      <div className="flex items-center gap-3">
        {/* Search */}
        <div className="hidden md:flex items-center gap-2 bg-gray-50 border border-gray-200 rounded-xl px-3 py-2 w-52">
          <Search className="w-4 h-4 text-gray-400 shrink-0" />
          <input
            type="text"
            placeholder="بحث..."
            className="bg-transparent text-sm text-right outline-none w-full text-gray-600 placeholder:text-gray-400"
          />
        </div>

        {/* Notifications */}
        <Link
          to="/notifications"
          className="relative w-9 h-9 flex items-center justify-center rounded-xl hover:bg-gray-100 text-gray-500 transition"
        >
          <Bell className="w-5 h-5" />
          {unreadCount > 0 && (
            <span className="absolute top-1 right-1 w-4 h-4 bg-red-500 text-white text-[10px] rounded-full flex items-center justify-center font-bold">
              {unreadCount}
            </span>
          )}
        </Link>
      </div>
    </header>
  );
}
