import {
  LayoutDashboard, Store, Users, UserCheck, Swords,
  Megaphone, Package, Receipt, Bell, Settings, Gamepad2, GraduationCap,
  Award, Wallet, MapPin, ScrollText, ShieldCheck, Percent, CreditCard, UserRound,
  MessageSquare, Trophy, Map as MapIcon,
} from 'lucide-react';

// The dashboard's sections in sidebar order. `perm` is the permission that
// unlocks the section — an employee sees a link (and can open the route) only
// when they hold it. Admins hold everything. The API enforces the same keys.
export const navItems = [
  { to: '/', label: 'الرئيسية', icon: LayoutDashboard, exact: true, perm: 'dashboard.view' },
  { to: '/sports', label: 'الألعاب', icon: Gamepad2, perm: 'sports.view' },
  { to: '/assessment', label: 'المستويات والتقييم', icon: GraduationCap, perm: 'assessment.view' },
  { to: '/levels-points', label: 'المستويات والنقاط', icon: Trophy, perm: 'pointsSystem.view' },
  // قسم واحد: النادي هو المدخل، وملاعبه تُعرض داخل صفحة تفاصيله.
  { to: '/venues', label: 'الأندية والملاعب', icon: Store, perm: 'venues.view' },
  { to: '/coaches', label: 'المدربون', icon: UserCheck, perm: 'coaches.view' },
  { to: '/coach-specializations', label: 'تخصصات المدربين', icon: Award, perm: 'coachSpecializations.view' },
  { to: '/players', label: 'اللاعبون', icon: Users, perm: 'users.view' },
  { to: '/users', label: 'المستخدمون', icon: UserRound, perm: 'users.view' },
  { to: '/cities', label: 'الدول والمدن', icon: MapPin, perm: 'locations.view' },
  { to: '/service-zones', label: 'مناطق الخدمة', icon: MapIcon, perm: 'serviceZones.view' },
  { to: '/matches', label: 'المباريات', icon: Swords, perm: 'matches.view' },
  { to: '/announcements', label: 'الإعلانات', icon: Megaphone, perm: 'ads.view' },
  { to: '/packages', label: 'الاشتراكات', icon: Package, perm: 'packages.view' },
  { to: '/finance', label: 'المالية', icon: Wallet, perm: 'finance.view' },
  { to: '/discounts', label: 'الخصومات والعروض', icon: Percent, perm: 'discounts.view' },
  { to: '/venue-subscriptions', label: 'اشتراكات الملاعب', icon: CreditCard, perm: 'venueSubscriptions.view' },
  { to: '/invoices', label: 'الفواتير', icon: Receipt, perm: 'bookings.view' },
  { to: '/support', label: 'الدردشة والدعم', icon: MessageSquare, perm: 'support.view' },
  { to: '/notifications', label: 'الإشعارات', icon: Bell, perm: 'notifications.view' },
  { to: '/policies', label: 'السياسات', icon: ScrollText, perm: 'policies.view' },
  { to: '/staff', label: 'الموظفون والصلاحيات', icon: ShieldCheck, perm: 'staff.view' },
  { to: '/settings', label: 'الإعدادات', icon: Settings, perm: 'settings.view' },
];
