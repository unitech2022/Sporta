// Role-specific blocks of the account detail page: player profile, coach
// profile, staff scope, and owned venues. Each renders null when the account
// doesn't hold that role.
import { Link } from 'react-router-dom';
import {
  Trophy, GraduationCap, ShieldCheck, Store, BadgeCheck, IdCard,
} from 'lucide-react';
import { Section, InfoRows, Chips, DocImage, SafeImage } from '../DetailBits';
import {
  playerLevelLabels, handLabels, positionLabels, matchTypeLabels,
  playTimeLabels, experienceLabels, residencyLabels, dayLabels,
  genderLabels, money,
} from '../../utils/accountLabels';

export function PlayerSection({ player }) {
  if (!player) return null;
  const rows = [
    { label: 'المستوى', value: `${playerLevelLabels[player.level] ?? player.level} (${player.level})` },
    { label: 'مستوى التقييم', value: player.assessmentLevelName },
    { label: 'تصنيف ELO', value: Math.round(player.eloRating) },
    { label: 'نقاط الالتزام', value: Number(player.reliabilityScore).toFixed(1) },
    { label: 'المباريات', value: `${player.totalMatches} (فوز ${player.totalWins})` },
    { label: 'نسبة الفوز', value: `${Number(player.winRate).toFixed(0)}%` },
    {
      label: 'تقييم الزملاء',
      value: player.peerRatingCount
        ? `${Number(player.peerRatingAverage).toFixed(1)} من ${player.peerRatingCount} تقييم`
        : 'لا يوجد',
    },
    { label: 'اليد المفضّلة', value: handLabels[player.preferredHand] },
    { label: 'مركز اللعب', value: positionLabels[player.courtPosition] },
    { label: 'نوع المباراة المفضّل', value: matchTypeLabels[player.preferredMatchType] },
    { label: 'وقت اللعب المفضّل', value: playTimeLabels[player.preferredPlayTime] },
    { label: 'بدأ اللعب سنة', value: player.playStartYear },
  ];
  return (
    <Section icon={Trophy} title="ملف اللاعب">
      <InfoRows rows={rows} />
    </Section>
  );
}

export function CoachSection({ coach }) {
  if (!coach) return null;
  const rows = [
    { label: 'اللعبة', value: coach.sportName },
    { label: 'التخصص', value: coach.specialization },
    { label: 'سعر الساعة', value: money(coach.hourlyRate) },
    { label: 'سعر الباقة (8 حصص)', value: coach.packagePrice ? money(coach.packagePrice) : null },
    { label: 'سنوات الخبرة', value: experienceLabels[coach.experienceLevel] },
    { label: 'الفئة المستهدفة', value: genderLabels[coach.targetGender] },
    { label: 'الجنسية', value: residencyLabels[coach.residency] },
    { label: 'الملعب المعتاد', value: coach.preferredVenueName },
    { label: 'التقييم', value: `${Number(coach.rating).toFixed(1)} من ${coach.totalRatings} تقييم` },
    { label: 'عدد الجلسات', value: coach.totalSessions },
    { label: 'الشهادات', value: coach.certifications },
  ];

  return (
    <>
      <Section
        icon={GraduationCap}
        title="ملف المدرب"
        action={
          <span className={`flex items-center gap-1 text-xs font-medium px-2.5 py-1 rounded-full ${coach.isVerified ? 'bg-[#2AB5CE]/10 text-[#2AB5CE]' : 'bg-gray-100 text-gray-500'}`}>
            <BadgeCheck className="w-3.5 h-3.5" /> {coach.isVerified ? 'معتمد' : 'غير معتمد'}
          </span>
        }
      >
        <InfoRows rows={rows} />
        {coach.bio && (
          <p className="text-sm text-gray-600 leading-relaxed mt-4 pt-4 border-t border-gray-50">{coach.bio}</p>
        )}
        {coach.specializationNames?.length > 0 && (
          <div className="mt-4 pt-4 border-t border-gray-50">
            <p className="text-xs text-gray-500 mb-2">التخصصات</p>
            <Chips items={coach.specializationNames} />
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
    </>
  );
}

export function StaffSection({ staff }) {
  if (!staff) return null;
  return (
    <Section icon={ShieldCheck} title="بيانات الموظف">
      <InfoRows rows={[
        { label: 'المسمى الوظيفي', value: staff.jobTitle },
        { label: 'الدولة', value: staff.countryName },
        { label: 'المدينة', value: staff.cityName ?? 'كل مدن الدولة' },
      ]} />
      <div className="mt-4 pt-4 border-t border-gray-50">
        <p className="text-xs text-gray-500 mb-2">الصلاحيات ({staff.permissions?.length ?? 0})</p>
        <Chips items={staff.permissions} cls="bg-gray-100 text-gray-600" />
      </div>
    </Section>
  );
}

export function VenuesSection({ venues }) {
  if (!venues?.length) return null;
  return (
    <Section icon={Store} title={`الأندية المملوكة (${venues.length})`}>
      <div className="space-y-5">
        {venues.map((v) => (
          <div key={v.id} className="border border-gray-100 rounded-2xl p-4">
            <div className="flex items-start gap-3">
              <SafeImage url={v.imageUrl} alt={v.name}
                className="w-20 h-20 rounded-xl object-cover border border-gray-100 shrink-0" />
              <div className="flex-1">
                <Link to={`/venues/${v.id}`} className="font-medium text-gray-800 text-sm hover:text-[#2AB5CE]">
                  {v.name}
                </Link>
                <p className="text-xs text-gray-400 mt-0.5">{v.city || '—'} · {v.courts} ملعب</p>
                <div className="flex flex-wrap gap-1.5 mt-2">
                  <span className={`text-xs px-2.5 py-0.5 rounded-full ${v.isActive ? 'bg-green-100 text-green-700' : 'bg-gray-100 text-gray-500'}`}>
                    {v.isActive ? 'نشط' : 'موقوف'}
                  </span>
                  <span className={`text-xs px-2.5 py-0.5 rounded-full ${v.isApproved ? 'bg-[#2AB5CE]/10 text-[#2AB5CE]' : 'bg-yellow-100 text-yellow-700'}`}>
                    {v.isApproved ? 'معتمد' : 'بانتظار الاعتماد'}
                  </span>
                </div>
              </div>
            </div>

            {v.images?.length > 0 && (
              <div className="flex flex-wrap gap-2 mt-3">
                {v.images.map((img, i) => (
                  <SafeImage key={i} url={img} alt={`${v.name} ${i + 1}`}
                    className="w-16 h-16 rounded-lg object-cover border border-gray-100" />
                ))}
              </div>
            )}

            {(v.commercialRegistrationImageUrl || v.nationalAddressImageUrl || v.ownerIdImageUrl) && (
              <div className="grid grid-cols-1 sm:grid-cols-3 gap-3 mt-4 pt-4 border-t border-gray-50">
                <DocImage label="السجل التجاري" url={v.commercialRegistrationImageUrl} />
                <DocImage label="العنوان الوطني" url={v.nationalAddressImageUrl} />
                <DocImage label="هوية صاحب الحساب" url={v.ownerIdImageUrl} />
              </div>
            )}
          </div>
        ))}
      </div>
    </Section>
  );
}
