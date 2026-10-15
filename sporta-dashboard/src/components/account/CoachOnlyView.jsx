// عرض المدرب لمن يملك صلاحية «المدربون» دون صلاحية «المستخدمون»: كل ما يعيده
// GET /api/coaches/{id} بلا بيانات الحساب (المحفظة/الاشتراك/البنك) التي تحتاج
// users.view. من يملك users.view يرى صفحة تفاصيل الحساب الكاملة بدلاً من هذه.
import { ArrowRight, Star, BadgeCheck, Phone, Calendar, GraduationCap, IdCard } from 'lucide-react';
import StatusBadge from '../StatusBadge';
import { Section, InfoRows, Chips, DocImage, Avatar } from '../DetailBits';
import {
  experienceLabels, residencyLabels, dayLabels, genderLabels, formatDate, money,
} from '../../utils/accountLabels';

export default function CoachOnlyView({ coach, onBack }) {
  const rows = [
    { label: 'اللعبة', value: coach.sportName },
    { label: 'المدينة', value: coach.city },
    { label: 'التخصص', value: coach.specialization },
    { label: 'سعر الساعة', value: money(coach.hourlyRate) },
    { label: 'سعر الباقة (8 حصص)', value: coach.packagePrice ? money(coach.packagePrice) : null },
    { label: 'سنوات الخبرة', value: experienceLabels[coach.experienceLevel] },
    { label: 'الفئة المستهدفة', value: genderLabels[coach.targetGender] },
    { label: 'الجنسية', value: residencyLabels[coach.residency] },
    { label: 'الملعب المعتاد', value: coach.preferredVenueName },
    { label: 'التقييم', value: `${Number(coach.rating).toFixed(1)} من ${coach.reviews} تقييم` },
    { label: 'الطلاب', value: coach.students },
    { label: 'الشهادات', value: coach.certifications },
  ];

  return (
    <div>
      <button onClick={onBack} className="flex items-center gap-1 text-sm text-gray-500 hover:text-gray-700 mb-4">
        <ArrowRight className="w-4 h-4" /> العودة للمدربين
      </button>

      <div className="grid grid-cols-1 lg:grid-cols-3 gap-6 items-start">
        <div className="bg-white rounded-2xl shadow-sm border border-gray-100 p-6 flex flex-col items-center">
          <Avatar url={coach.avatarUrl} name={coach.name} gradient="from-teal-400 to-cyan-600" />
          <div className="flex items-center gap-1.5 mt-3">
            <h2 className="text-xl font-bold text-gray-800">{coach.name}</h2>
            {coach.isVerified && <BadgeCheck className="w-5 h-5 text-[#2AB5CE]" />}
          </div>
          <p className="text-sm text-gray-500 mt-1">{coach.specialization || 'مدرب'}</p>
          <div className="flex items-center gap-1 mt-3">
            {[1, 2, 3, 4, 5].map((s) => (
              <Star key={s} className={`w-5 h-5 ${s <= Math.round(coach.rating) ? 'fill-yellow-400 text-yellow-400' : 'text-gray-200'}`} />
            ))}
            <span className="text-sm text-gray-500 mr-1">({Number(coach.rating).toFixed(1)})</span>
          </div>
          <div className="mt-4"><StatusBadge status={coach.isActive ? 'active' : 'inactive'} /></div>

          <div className="w-full mt-5 pt-5 border-t border-gray-100 space-y-3 text-sm">
            {coach.phone && (
              <div className="flex items-center gap-2 text-gray-600">
                <Phone className="w-4 h-4 text-gray-400 shrink-0" /><span dir="ltr">{coach.phone}</span>
              </div>
            )}
            <div className="flex items-center gap-2 text-gray-600">
              <Calendar className="w-4 h-4 text-gray-400 shrink-0" />
              <span>انضم في {formatDate(coach.joinedAt)}</span>
            </div>
          </div>
        </div>

        <div className="lg:col-span-2 space-y-6">
          <Section icon={GraduationCap} title="ملف المدرب">
            <InfoRows rows={rows} />
            {coach.bio && (
              <p className="text-sm text-gray-600 leading-relaxed mt-4 pt-4 border-t border-gray-50">{coach.bio}</p>
            )}
            {(coach.specializationNames?.length > 0 || coach.specialties?.length > 0) && (
              <div className="mt-4 pt-4 border-t border-gray-50">
                <p className="text-xs text-gray-500 mb-2">التخصصات</p>
                <Chips items={coach.specializationNames?.length ? coach.specializationNames : coach.specialties} />
              </div>
            )}
            {coach.availableDays?.length > 0 && (
              <div className="mt-4 pt-4 border-t border-gray-50">
                <p className="text-xs text-gray-500 mb-2">الأيام المتاحة</p>
                <Chips items={coach.availableDays.map((d) => dayLabels[d] ?? d)} cls="bg-indigo-50 text-indigo-700" />
              </div>
            )}
          </Section>

          <Section icon={IdCard} title="وثائق المدرب">
            <div className="grid grid-cols-1 sm:grid-cols-3 gap-4">
              <DocImage label="الهوية / الإقامة — الوجه الأمامي" url={coach.nationalIdFrontUrl} />
              <DocImage label="الهوية / الإقامة — الوجه الخلفي" url={coach.nationalIdBackUrl} />
              {coach.idDocumentUrl && <DocImage label="وثيقة قديمة" url={coach.idDocumentUrl} />}
            </div>
          </Section>
        </div>
      </div>
    </div>
  );
}
