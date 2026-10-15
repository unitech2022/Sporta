import { useParams, useNavigate } from 'react-router-dom';
import { coachesApi } from '../api/coachesApi';
import { useApi } from '../hooks/useApi';
import { useAuth } from '../context/AuthContext';
import { Spinner } from '../components/TableBits';
import CoachOnlyView from '../components/account/CoachOnlyView';
import AccountDetailPage from './AccountDetailPage';

/**
 * تفاصيل المدرب. مسار المدرب يحمل معرّف *ملف المدرب*، فنجلبه أولاً للحصول على
 * معرّف الحساب، ثم نعرض صفحة تفاصيل الحساب الكاملة — وهي التي تضم قسم المدرب
 * (السعر، الخبرة، التخصصات، الأيام، الوثائق) إلى جانب المحفظة والاشتراك والنشاط.
 * من لا يملك صلاحية «المستخدمون» يرى بيانات المدرب فقط (فمصدرها /api/coaches).
 */
export default function CoachDetailPage() {
  const { id } = useParams();
  const navigate = useNavigate();
  const { can } = useAuth();
  const { data: coach, loading, error } = useApi(() => coachesApi.getById(id), [id]);

  if (loading) return <Spinner />;
  if (error || !coach) {
    return (
      <div className="text-center py-20 text-gray-400">
        {error || 'المدرب غير موجود'}
        <div className="mt-4">
          <button onClick={() => navigate('/coaches')} className="text-[#2AB5CE] hover:underline">
            العودة للمدربين
          </button>
        </div>
      </div>
    );
  }

  if (!can('users.view')) {
    return <CoachOnlyView coach={coach} onBack={() => navigate('/coaches')} />;
  }

  return (
    <AccountDetailPage userId={coach.userId} backTo="/coaches" backLabel="العودة للمدربين"
      deletePermission="coaches.delete" deleteRequest={coachesApi.remove} />
  );
}
