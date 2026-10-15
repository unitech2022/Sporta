import { useState } from 'react';
import { useParams, useNavigate } from 'react-router-dom';
import {
  ArrowRight, Phone, MapPin, Calendar, Activity, Globe, Languages,
  ToggleLeft, ToggleRight, Wallet, Star, Landmark, IdCard, CalendarCheck,
  Swords, GraduationCap, Users, Bell, Crown, Navigation, BadgeCheck, Trash2,
} from 'lucide-react';
import { adminApi } from '../api/adminApi';
import { useApi } from '../hooks/useApi';
import { useAuth } from '../context/AuthContext';
import { Spinner } from '../components/TableBits';
import StatusBadge from '../components/StatusBadge';
import ConfirmModal from '../components/ConfirmModal';
import PointsCard from '../components/PointsCard';
import { Section, InfoRows, StatTile, DocImage, Avatar } from '../components/DetailBits';
import {
  PlayerSection, CoachSection, StaffSection, VenuesSection,
} from '../components/account/RoleSections';
import {
  BookingsSection, MatchesSection, SessionsSection, WalletSection, FriendsSection,
} from '../components/account/ActivityLists';
import {
  roleLabels, genderLabels, languageLabels, planLabels,
  formatDate, formatDateTime, money,
} from '../utils/accountLabels';

/**
 * صفحة «تفاصيل الحساب» — كل بيانات المستخدم في مكان واحد: الملف الشخصي،
 * المحفظة والنقاط، الاشتراك، الحساب البنكي، الوثائق، النشاط، بالإضافة إلى
 * أقسام دوره (لاعب / مدرب / موظف / ملعب).
 *
 * تُستخدم من «اللاعبون» و«المستخدمون» عبر معرّف المسار، ومن صفحة المدرب عبر
 * الخاصية [userId] (لأن مسار المدرب يحمل معرّف ملف المدرب لا معرّف الحساب).
 *
 * [deletePermission] و[deleteRequest] تحدّدان مسار الحذف: صفحة المدرب تمرّر
 * صلاحية قسم المدربين ومساره حتى يعمل الزر لموظف يملك صلاحية المدربين وحدها،
 * والباقي يستخدم صلاحية قسم اللاعبين/المستخدمين ومساره.
 */
export default function AccountDetailPage({
  userId, backTo = '/users', backLabel = 'العودة للمستخدمين',
  deletePermission = 'users.delete', deleteRequest = adminApi.deleteUser,
}) {
  const { id: routeId } = useParams();
  const id = userId ?? routeId;
  const navigate = useNavigate();
  const { can } = useAuth();
  const canDelete = can(deletePermission);
  const { data: u, loading, error, refetch } = useApi(() => adminApi.getUser(id), [id]);
  const [confirm, setConfirm] = useState(false);
  // الدور المطلوب اعتماده ('coach' | 'venue') — null حين لا يوجد طلب مفتوح.
  const [approvingRole, setApprovingRole] = useState(null);
  const [deleting, setDeleting] = useState(false);
  const [busy, setBusy] = useState(false);
  const [actionError, setActionError] = useState(null);

  if (loading) return <Spinner />;
  if (error || !u) {
    return (
      <div className="text-center py-20 text-gray-400">
        {error || 'المستخدم غير موجود'}
        <div className="mt-4">
          <button onClick={() => navigate(backTo)} className="text-[#2AB5CE] hover:underline">{backLabel}</button>
        </div>
      </div>
    );
  }

  const toggle = async () => {
    setBusy(true);
    try {
      if (u.isActive) await adminApi.lockUser(u.id);
      else await adminApi.unlockUser(u.id);
      setConfirm(false);
      refetch();
    } finally { setBusy(false); }
  };

  const remove = async () => {
    setBusy(true);
    setActionError(null);
    setDeleting(false);
    try {
      await deleteRequest(u.id);
      navigate(backTo);
    } catch (e) {
      setActionError(e?.response?.data?.messageAr || 'تعذّر حذف الحساب');
      setBusy(false);
    }
  };

  const approveRole = async () => {
    setBusy(true);
    try {
      await adminApi.approveUserRole(u.id, approvingRole, true);
      setApprovingRole(null);
      refetch();
    } finally { setBusy(false); }
  };

  const pendingRoles = u.pendingRoles ?? [];
  const act = u.activity ?? {};
  const sub = u.subscription;

  return (
    <div>
      <button onClick={() => navigate(backTo)}
        className="flex items-center gap-1 text-sm text-gray-500 hover:text-gray-700 mb-4">
        <ArrowRight className="w-4 h-4" /> {backLabel}
      </button>

      <div className="grid grid-cols-1 lg:grid-cols-3 gap-6 items-start">
        {/* ── البطاقة الجانبية ─────────────────────────────────────────── */}
        <div className="space-y-6">
          <div className="bg-white rounded-2xl shadow-sm border border-gray-100 p-6 flex flex-col items-center">
            <Avatar url={u.avatarUrl} name={u.fullName} />
            <h2 className="text-xl font-bold text-gray-800 mt-3">{u.fullName}</h2>
            <p className="text-xs text-gray-400 mt-0.5">حساب رقم #{u.id}</p>
            <div className="mt-2"><StatusBadge status={u.isActive ? 'active' : 'inactive'} /></div>
            <div className="flex flex-wrap gap-1.5 justify-center mt-3">
              {(u.roles ?? []).map((r) => {
                const pending = pendingRoles.includes(r);
                return (
                  <span key={r}
                    className={`px-2.5 py-0.5 rounded-full text-xs ${pending ? 'bg-amber-50 text-amber-700 border border-amber-200' : 'bg-gray-100 text-gray-600'}`}>
                    {roleLabels[r] ?? r}{pending ? ' · قيد المراجعة' : ''}
                  </span>
                );
              })}
            </div>

            {/* اعتماد حساب المدرب/الملعب بعد مراجعة وثائقه أدناه. */}
            {pendingRoles.map((r) => (
              <button key={r} onClick={() => setApprovingRole(r)}
                className="mt-4 w-full flex items-center justify-center gap-1.5 px-4 py-2.5 rounded-xl text-sm font-medium bg-green-50 text-green-700 hover:bg-green-100 transition">
                <BadgeCheck className="w-4 h-4" /> اعتماد حساب {roleLabels[r] ?? r}
              </button>
            ))}
            <button onClick={() => setConfirm(true)}
              className={`mt-5 w-full flex items-center justify-center gap-1.5 px-4 py-2.5 rounded-xl text-sm font-medium transition ${u.isActive ? 'bg-yellow-50 text-yellow-600 hover:bg-yellow-100' : 'bg-green-50 text-[#2AB5CE] hover:bg-green-100'}`}>
              {u.isActive ? <><ToggleRight className="w-4 h-4" /> إيقاف الحساب</> : <><ToggleLeft className="w-4 h-4" /> تفعيل الحساب</>}
            </button>

            {/* حسابات الإدارة تُحذف من شاشة الموظفين — الخادم يرفضها هنا. */}
            {canDelete && !(u.roles ?? []).some(r => r === 'admin' || r === 'staff') && (
              <button disabled={busy} onClick={() => setDeleting(true)}
                className="mt-2 w-full flex items-center justify-center gap-1.5 px-4 py-2.5 rounded-xl text-sm font-medium bg-red-500 text-white hover:bg-red-600 transition disabled:opacity-50">
                <Trash2 className="w-4 h-4" /> حذف الحساب نهائياً
              </button>
            )}

            {actionError && (
              <p className="mt-3 text-xs text-red-600 text-center">{actionError}</p>
            )}
          </div>

          <div className="grid grid-cols-2 gap-3">
            <StatTile icon={Wallet} label="رصيد المحفظة" value={money(u.walletBalance)} tone="text-[#2AB5CE]" />
            <StatTile icon={Star} label="نقاط الولاء" value={u.pointsBalance ?? 0} tone="text-amber-600" />
          </div>
        </div>

        {/* ── الأقسام ──────────────────────────────────────────────────── */}
        <div className="lg:col-span-2 space-y-6">
          <Section icon={IdCard} title="البيانات الشخصية">
            <InfoRows rows={[
              { icon: Phone, label: 'الجوال', value: u.phone, dir: 'ltr' },
              { label: 'الجنس', value: genderLabels[u.gender] },
              { icon: Globe, label: 'الدولة', value: u.country },
              { icon: MapPin, label: 'المدينة', value: u.city },
              { label: 'الحي', value: u.district },
              { icon: Activity, label: 'الرياضة المفضّلة', value: u.favoriteSport },
              { icon: Languages, label: 'لغة التطبيق', value: languageLabels[u.preferredLanguage] },
              { icon: Calendar, label: 'تاريخ الانضمام', value: formatDate(u.createdAt) },
              { label: 'آخر تحديث للبيانات', value: u.updatedAt ? formatDateTime(u.updatedAt) : null },
              {
                icon: Navigation,
                label: 'الموقع المحفوظ',
                value: u.latitude && u.longitude
                  ? <a href={`https://maps.google.com/?q=${u.latitude},${u.longitude}`} target="_blank" rel="noreferrer"
                      className="text-[#2AB5CE] hover:underline" dir="ltr">
                      {u.latitude.toFixed(4)}, {u.longitude.toFixed(4)}
                    </a>
                  : null,
              },
            ]} />
          </Section>

          <Section icon={Activity} title="نشاط الحساب">
            <div className="grid grid-cols-2 sm:grid-cols-3 gap-3">
              <StatTile icon={CalendarCheck} label="الحجوزات" value={act.totalBookings ?? 0} />
              <StatTile icon={CalendarCheck} label="حجوزات ملغاة" value={act.cancelledBookings ?? 0} />
              <StatTile icon={Wallet} label="إجمالي الإنفاق" value={money(act.totalSpent)} />
              <StatTile icon={Swords} label="المباريات" value={act.totalMatches ?? 0} />
              <StatTile icon={GraduationCap} label="جلسات كمتدرّب" value={act.coachSessionsAsPlayer ?? 0} />
              {u.coach && (
                <StatTile icon={GraduationCap} label="جلسات كمدرّب" value={act.coachSessionsAsCoach ?? 0} />
              )}
              <StatTile icon={Users} label="الأصدقاء" value={act.friends ?? 0} />
              <StatTile icon={Bell} label="الإشعارات" value={act.notifications ?? 0} />
              <StatTile icon={Calendar} label="آخر حجز" value={formatDate(act.lastActivityAt)} />
            </div>
          </Section>

          {sub && (
            <Section icon={Crown} title="الاشتراك">
              <InfoRows rows={[
                { label: 'الاشتراك', value: sub.packageName || planLabels[sub.plan] || sub.plan },
                { label: 'الحالة', value: <StatusBadge status={sub.isActive ? 'active' : 'inactive'} /> },
                { label: 'تاريخ البداية', value: sub.startDate ? formatDate(sub.startDate) : null },
                { label: 'تاريخ الانتهاء', value: sub.endDate ? formatDate(sub.endDate) : null },
              ]} />
            </Section>
          )}

          <PlayerSection player={u.player} />
          <CoachSection coach={u.coach} />
          <StaffSection staff={u.staff} />
          <VenuesSection venues={u.venues} />

          {/* يظهران دائماً — «لم يُدخل» أوضح للأدمن من اختفاء القسم. */}
          <Section icon={Landmark} title="الحساب البنكي">
            <InfoRows
              emptyText="لم يُدخل حساب بنكي لهذا المستخدم"
              rows={[
                { label: 'الآيبان', value: u.iban, dir: 'ltr' },
                { label: 'البنك', value: u.bankName },
                { label: 'اسم صاحب الحساب', value: u.accountHolderName },
              ]} />
          </Section>

          <Section icon={IdCard} title="الوثائق المرفوعة">
            <div className="grid grid-cols-1 sm:grid-cols-3 gap-4">
              <DocImage label="صورة الهوية" url={u.idImageUrl} />
              <DocImage label="السجل التجاري" url={u.commercialRegistrationImageUrl} />
              <DocImage label="شهادة الضريبة" url={u.taxCertificateImageUrl} />
            </div>
          </Section>

          <BookingsSection bookings={u.recentBookings} />
          <MatchesSection matches={u.recentMatches} />
          <SessionsSection sessions={u.sessionsAsCoach}
            title="جلسات درّبها" counterpartLabel="اللاعب" />
          <SessionsSection sessions={u.sessionsAsPlayer}
            title="جلسات حجزها كمتدرّب" counterpartLabel="المدرب" />
          <WalletSection transactions={u.recentWalletTransactions} />
          <PointsCard userId={u.id} />
          <FriendsSection friends={u.friends} />
        </div>
      </div>

      <ConfirmModal
        open={confirm}
        title={u.isActive ? 'إيقاف الحساب' : 'تفعيل الحساب'}
        message={u.isActive ? `سيتم إيقاف "${u.fullName}" ومنعه من الدخول.` : `سيتم تفعيل "${u.fullName}".`}
        danger={u.isActive}
        onConfirm={busy ? () => {} : toggle}
        onCancel={() => setConfirm(false)}
      />

      <ConfirmModal
        open={!!approvingRole}
        title="اعتماد الحساب"
        message={`سيتم تفعيل حساب ${roleLabels[approvingRole] ?? ''} لـ "${u.fullName}" وإشعاره بالموافقة.`}
        onConfirm={busy ? () => {} : approveRole}
        onCancel={() => setApprovingRole(null)}
      />

      <ConfirmModal
        open={deleting}
        title="حذف الحساب نهائياً"
        message={`سيُحذف حساب "${u.fullName}" نهائياً: تُلغى حجوزاته وجلساته القادمة ويُعاد ما دُفع، وتُمسح بياناته الشخصية وملفاته المرفوعة. لو كان يملك أندية فستُحذف هي وملاعبها. لا يمكن التراجع عن هذه العملية.`}
        onConfirm={busy ? () => {} : remove}
        onCancel={() => setDeleting(false)}
      />
    </div>
  );
}
