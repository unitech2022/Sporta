import { BrowserRouter, Routes, Route, Navigate } from 'react-router-dom';
import { AuthProvider, useAuth } from './context/AuthContext';
import LoginPage from './pages/LoginPage';
import HomePage from './pages/HomePage';
import CourtDetailPage from './pages/CourtDetailPage';
import CoachesPage from './pages/CoachesPage';
import CoachDetailPage from './pages/CoachDetailPage';
import VenuesPage from './pages/VenuesPage';
import VenueDetailPage from './pages/VenueDetailPage';
import PlayersPage from './pages/PlayersPage';
import UsersPage from './pages/UsersPage';
import AccountDetailPage from './pages/AccountDetailPage';
import MatchesPage from './pages/MatchesPage';
import MatchDetailPage from './pages/MatchDetailPage';
import AnnouncementsPage from './pages/AnnouncementsPage';
import PackagesPage from './pages/PackagesPage';
import PackageDetailPage from './pages/PackageDetailPage';
import InvoicesPage from './pages/InvoicesPage';
import InvoiceDetailPage from './pages/InvoiceDetailPage';
import FinancePage from './pages/FinancePage';
import NotificationsPage from './pages/NotificationsPage';
import SupportChatPage from './pages/SupportChatPage';
import SettingsPage from './pages/SettingsPage';
import SportsPage from './pages/SportsPage';
import SportDetailPage from './pages/SportDetailPage';
import CoachSpecializationsPage from './pages/CoachSpecializationsPage';
import LevelsPointsPage from './pages/LevelsPointsPage';
import AssessmentPage from './pages/AssessmentPage';
import CitiesPage from './pages/CitiesPage';
import ServiceZonesPage from './pages/ServiceZonesPage';
import PoliciesPage from './pages/PoliciesPage';
import StaffPage from './pages/StaffPage';
import DiscountsPage from './pages/DiscountsPage';
import VenueSubscriptionsPage from './pages/VenueSubscriptionsPage';
import DashboardLayout from './components/DashboardLayout';
import { navItems } from './config/navItems';

const Placeholder = ({ name }) => (
  <div className="flex items-center justify-center h-64 text-gray-400 text-lg">
    {name} — قريباً...
  </div>
);

/// Blocks a section an employee has no permission for, and sends them to the
/// first section they *can* open (the API enforces this too — this is UX).
function Guard({ perm, children }) {
  const { can } = useAuth();
  if (can(perm)) return children;

  const fallback = navItems.find(i => i.to !== '/' && can(i.perm));
  if (fallback) return <Navigate to={fallback.to} replace />;

  return (
    <div className="flex items-center justify-center h-64 text-center px-6">
      <div className="text-gray-400">
        <p className="font-medium text-gray-600 mb-1">لا تملك صلاحية لهذا القسم</p>
        <p className="text-sm">تواصل مع مدير النظام لمنحك الصلاحية المناسبة.</p>
      </div>
    </div>
  );
}

function ProtectedRoute({ children }) {
  const { user, loading } = useAuth();
  if (loading) return (
    <div className="min-h-screen flex items-center justify-center bg-gray-50">
      <div className="flex flex-col items-center gap-3">
        <div className="w-10 h-10 border-4 border-green-200 border-t-green-600 rounded-full animate-spin" />
        <p className="text-sm text-gray-400">جاري التحقق...</p>
      </div>
    </div>
  );
  return user ? children : <Navigate to="/login" replace />;
}

function AppRoutes() {
  return (
    <Routes>
      <Route path="/login" element={<LoginPage />} />
      <Route
        path="/"
        element={
          <ProtectedRoute>
            <DashboardLayout />
          </ProtectedRoute>
        }
      >
        <Route index element={<Guard perm="dashboard.view"><HomePage /></Guard>} />
        <Route path="sports" element={<Guard perm="sports.view"><SportsPage /></Guard>} />
        <Route path="sports/:id" element={<Guard perm="sports.view"><SportDetailPage /></Guard>} />
        <Route path="assessment" element={<Guard perm="assessment.view"><AssessmentPage /></Guard>} />
        <Route path="levels-points" element={<Guard perm="pointsSystem.view"><LevelsPointsPage /></Guard>} />
        <Route path="cities" element={<Guard perm="locations.view"><CitiesPage /></Guard>} />
        <Route path="service-zones" element={<Guard perm="serviceZones.view"><ServiceZonesPage /></Guard>} />
        <Route path="venues" element={<Guard perm="venues.view"><VenuesPage /></Guard>} />
        <Route path="venues/:id" element={<Guard perm="venues.view"><VenueDetailPage /></Guard>} />
        {/* لا توجد قائمة ملاعب مستقلة — يُفتح الملعب من داخل تفاصيل ناديه. */}
        <Route path="courts" element={<Navigate to="/venues" replace />} />
        <Route path="courts/:id" element={<Guard perm="courts.view"><CourtDetailPage /></Guard>} />
        <Route path="coaches" element={<Guard perm="coaches.view"><CoachesPage /></Guard>} />
        <Route path="coaches/:id" element={<Guard perm="coaches.view"><CoachDetailPage /></Guard>} />
        <Route path="coach-specializations" element={<Guard perm="coachSpecializations.view"><CoachSpecializationsPage /></Guard>} />
        <Route path="players" element={<Guard perm="users.view"><PlayersPage /></Guard>} />
        <Route path="players/:id" element={<Guard perm="users.view"><AccountDetailPage backTo="/players" backLabel="العودة للاعبين" /></Guard>} />
        <Route path="users" element={<Guard perm="users.view"><UsersPage /></Guard>} />
        <Route path="users/:id" element={<Guard perm="users.view"><AccountDetailPage /></Guard>} />
        <Route path="matches" element={<Guard perm="matches.view"><MatchesPage /></Guard>} />
        <Route path="matches/:id" element={<Guard perm="matches.view"><MatchDetailPage /></Guard>} />
        <Route path="announcements" element={<Guard perm="ads.view"><AnnouncementsPage /></Guard>} />
        <Route path="packages" element={<Guard perm="packages.view"><PackagesPage /></Guard>} />
        <Route path="packages/:id" element={<Guard perm="packages.view"><PackageDetailPage /></Guard>} />
        <Route path="finance" element={<Guard perm="finance.view"><FinancePage /></Guard>} />
        <Route path="discounts" element={<Guard perm="discounts.view"><DiscountsPage /></Guard>} />
        <Route path="venue-subscriptions" element={<Guard perm="venueSubscriptions.view"><VenueSubscriptionsPage /></Guard>} />
        <Route path="invoices" element={<Guard perm="bookings.view"><InvoicesPage /></Guard>} />
        <Route path="invoices/:id" element={<Guard perm="bookings.view"><InvoiceDetailPage /></Guard>} />
        <Route path="support" element={<Guard perm="support.view"><SupportChatPage /></Guard>} />
        <Route path="notifications" element={<Guard perm="notifications.view"><NotificationsPage /></Guard>} />
        <Route path="policies" element={<Guard perm="policies.view"><PoliciesPage /></Guard>} />
        <Route path="staff" element={<Guard perm="staff.view"><StaffPage /></Guard>} />
        <Route path="settings" element={<Guard perm="settings.view"><SettingsPage /></Guard>} />
      </Route>
      <Route path="*" element={<Navigate to="/" replace />} />
    </Routes>
  );
}

export default function App() {
  return (
    <AuthProvider>
      <BrowserRouter>
        <AppRoutes />
      </BrowserRouter>
    </AuthProvider>
  );
}
