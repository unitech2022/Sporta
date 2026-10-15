// جداول آخر نشاط الحساب: الحجوزات، المباريات، جلسات التدريب، حركات المحفظة،
// والأصدقاء. كل قسم يختفي إذا لم يكن للحساب أي سجل من نوعه.
import { Link } from 'react-router-dom';
import { CalendarCheck, Swords, GraduationCap, Wallet, Users } from 'lucide-react';
import { Section, Avatar } from '../DetailBits';
import StatusBadge from '../StatusBadge';
import {
  bookingStatusLabels, matchStatusLabels, sessionStatusLabels,
  matchTypeNameLabels, walletTypeLabels, badgeFor, formatDateTime, money,
} from '../../utils/accountLabels';

/** جدول بسيط بترويسة عربية وتمرير أفقي على الشاشات الضيقة. */
function Table({ headers, children }) {
  return (
    <div className="overflow-x-auto -mx-5 px-5">
      <table className="w-full text-sm">
        <thead>
          <tr className="border-b border-gray-100">
            {headers.map((h) => (
              <th key={h} className="text-right py-2 font-medium text-gray-500 text-xs whitespace-nowrap px-2">{h}</th>
            ))}
          </tr>
        </thead>
        <tbody className="divide-y divide-gray-50">{children}</tbody>
      </table>
    </div>
  );
}

const Td = ({ children, className = '' }) => (
  <td className={`py-2.5 px-2 text-gray-700 whitespace-nowrap ${className}`}>{children}</td>
);

export function BookingsSection({ bookings }) {
  if (!bookings?.length) return null;
  return (
    <Section icon={CalendarCheck} title={`آخر الحجوزات (${bookings.length})`}>
      <Table headers={['الملعب', 'النادي', 'الموعد', 'المبلغ', 'الدفع', 'الحالة']}>
        {bookings.map((b) => (
          <tr key={b.id}>
            <Td className="font-medium text-gray-800">{b.courtName}</Td>
            <Td>{b.venueName || '—'}</Td>
            <Td className="text-xs text-gray-500">{formatDateTime(b.startTime)}</Td>
            <Td>{money(b.totalPrice)}</Td>
            <Td className="text-xs">{b.paidFullAmount ? 'كامل' : 'حصة'}</Td>
            <Td><StatusBadge status={badgeFor[b.status]} label={bookingStatusLabels[b.status] ?? b.status} /></Td>
          </tr>
        ))}
      </Table>
    </Section>
  );
}

export function MatchesSection({ matches }) {
  if (!matches?.length) return null;
  return (
    <Section icon={Swords} title={`آخر المباريات (${matches.length})`}>
      <Table headers={['النوع', 'الموعد', 'الملعب', 'الحصة', 'النتيجة', 'الدور', 'الحالة']}>
        {matches.map((m) => (
          <tr key={m.id}>
            <Td className="font-medium text-gray-800">
              <Link to={`/matches/${m.id}`} className="hover:text-[#2AB5CE]">
                {matchTypeNameLabels[m.matchType] ?? m.matchType}
              </Link>
            </Td>
            <Td className="text-xs text-gray-500">{formatDateTime(m.scheduledAt)}</Td>
            <Td>{m.courtName || '—'}{m.venueName ? ` · ${m.venueName}` : ''}</Td>
            <Td>{money(m.pricePerPlayer)}</Td>
            <Td dir="ltr">{m.score || '—'}</Td>
            <Td className="text-xs">{m.isCreator ? 'منشئ' : 'مشارك'}</Td>
            <Td><StatusBadge status={badgeFor[m.status]} label={matchStatusLabels[m.status] ?? m.status} /></Td>
          </tr>
        ))}
      </Table>
    </Section>
  );
}

export function SessionsSection({ sessions, title, counterpartLabel }) {
  if (!sessions?.length) return null;
  return (
    <Section icon={GraduationCap} title={`${title} (${sessions.length})`}>
      <Table headers={['الجلسة', counterpartLabel, 'الموعد', 'المدة', 'السعر', 'الدفع', 'الحالة']}>
        {sessions.map((s) => (
          <tr key={s.id}>
            <Td className="font-medium text-gray-800">{s.title || '—'}</Td>
            <Td>{s.counterpartName || '—'}</Td>
            <Td className="text-xs text-gray-500">{formatDateTime(s.scheduledAt)}</Td>
            <Td className="text-xs">{s.durationMinutes} د</Td>
            <Td>{money(s.price)}</Td>
            <Td className="text-xs">{s.isPaid ? 'مدفوعة' : 'غير مدفوعة'}</Td>
            <Td>
              <StatusBadge
                status={s.isCompleted ? 'completed' : badgeFor[s.status]}
                label={s.isCompleted ? 'منتهية' : (sessionStatusLabels[s.status] ?? s.status)} />
            </Td>
          </tr>
        ))}
      </Table>
    </Section>
  );
}

export function WalletSection({ transactions }) {
  if (!transactions?.length) return null;
  return (
    <Section icon={Wallet} title={`آخر حركات المحفظة (${transactions.length})`}>
      <Table headers={['العملية', 'الوصف', 'التاريخ', 'الحالة', 'المبلغ']}>
        {transactions.map((t) => (
          <tr key={t.id}>
            <Td className="font-medium text-gray-800">{walletTypeLabels[t.type] ?? t.type}</Td>
            <Td className="text-xs text-gray-500 whitespace-normal">{t.description || '—'}</Td>
            <Td className="text-xs text-gray-500">{formatDateTime(t.createdAt)}</Td>
            <Td>
              {t.status === 'Failed'
                ? <StatusBadge status="overdue" label="فشلت" />
                : <StatusBadge status="completed" label="تمت" />}
            </Td>
            <Td className={`font-bold ${t.amount > 0 ? 'text-green-600' : 'text-red-500'}`} dir="ltr">
              {t.amount > 0 ? `+${Number(t.amount).toFixed(2)}` : Number(t.amount).toFixed(2)}
            </Td>
          </tr>
        ))}
      </Table>
    </Section>
  );
}

export function FriendsSection({ friends }) {
  if (!friends?.length) return null;
  return (
    <Section icon={Users} title={`الأصدقاء (${friends.length})`}>
      <div className="flex flex-wrap gap-3">
        {friends.map((f) => (
          <Link key={f.id} to={`/users/${f.id}`}
            className="flex items-center gap-2 px-3 py-2 rounded-xl border border-gray-100 hover:bg-gray-50 transition">
            <Avatar url={f.avatarUrl} name={f.fullName} size="w-8 h-8 text-xs" />
            <div>
              <p className="text-sm font-medium text-gray-800">{f.fullName}</p>
              <p className="text-xs text-gray-400">{f.city || '—'}</p>
            </div>
          </Link>
        ))}
      </div>
    </Section>
  );
}
