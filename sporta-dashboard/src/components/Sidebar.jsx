import { NavLink, useNavigate } from 'react-router-dom';
import { useAuth } from '../context/AuthContext';
import { LogOut, X } from 'lucide-react';
import { navItems } from '../config/navItems';

export default function Sidebar({ open, onClose }) {
  const { user, access, isAdmin, can, logout } = useAuth();
  const navigate = useNavigate();
  const visibleItems = navItems.filter(item => can(item.perm));

  const handleLogout = () => {
    logout();
    navigate('/login');
  };

  return (
    <>
      {open && (
        <div className="fixed inset-0 bg-black/40 z-20 lg:hidden" onClick={onClose} />
      )}

      <aside
        className={`
          fixed top-0 right-0 h-full w-64 z-30 flex flex-col transition-transform duration-300
          bg-[#0A2540] shadow-2xl
          ${open ? 'translate-x-0' : 'translate-x-full'}
          lg:translate-x-0 lg:static lg:z-auto
        `}
      >
        {/* Logo */}
        <div className="flex items-center justify-between px-5 py-5 border-b border-white/10">
          <div className="flex items-center gap-3">
            <img src="/logo.png" alt="Sporta" className="h-9 w-auto object-contain" />
            <div>
              <p className="font-bold text-white text-base leading-tight">سبورتا</p>
              <p className="text-xs text-white/50">لوحة التحكم</p>
            </div>
          </div>
          <button onClick={onClose} className="lg:hidden text-white/50 hover:text-white">
            <X className="w-5 h-5" />
          </button>
        </div>

        {/* Nav + User + Logout (scroll together, scrollbar hidden) */}
        <nav className="flex-1 overflow-y-auto no-scrollbar py-4 px-3 space-y-0.5">
          {visibleItems.map(({ to, label, icon: Icon, exact }) => (
            <NavLink
              key={to}
              to={to}
              end={exact}
              onClick={onClose}
              className={({ isActive }) =>
                `flex items-center gap-3 px-4 py-2.5 rounded-xl text-sm font-medium transition-all
                ${isActive
                  ? 'bg-[#2AB5CE] text-white shadow-lg shadow-[#2AB5CE]/30'
                  : 'text-white/60 hover:bg-white/10 hover:text-white'
                }`
              }
            >
              <Icon className="w-5 h-5 shrink-0" />
              <span>{label}</span>
            </NavLink>
          ))}

          <div className="border-t border-white/10 mt-3 pt-4">
            <div className="flex items-center gap-3 mb-3 px-1">
              <div className="w-9 h-9 bg-[#2AB5CE]/20 border border-[#2AB5CE]/40 rounded-full flex items-center justify-center text-[#2AB5CE] font-bold text-sm shrink-0">
                {(user?.firstName ?? user?.name)?.[0] ?? 'م'}
              </div>
              <div className="min-w-0">
                <p className="text-sm font-semibold text-white truncate">
                  {user?.firstName && user?.lastName
                    ? `${user.firstName} ${user.lastName}`
                    : (user?.name ?? 'المستخدم')}
                </p>
                <p className="text-xs text-white/40 truncate">{user?.phone ?? ''}</p>
                {!isAdmin && access?.countryNameAr && (
                  <p className="text-[11px] text-[#2AB5CE] truncate">
                    {access.countryNameAr} · {access.cityNameAr ?? 'كل المدن'}
                  </p>
                )}
              </div>
            </div>
            <button
              onClick={handleLogout}
              className="w-full flex items-center gap-2 px-4 py-2.5 rounded-xl text-sm font-medium text-red-400 hover:bg-red-500/10 transition-all"
            >
              <LogOut className="w-4 h-4" />
              <span>تسجيل الخروج</span>
            </button>
          </div>
        </nav>
      </aside>
    </>
  );
}
