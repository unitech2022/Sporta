// Shared labels / helpers for the finance section.

// Wallet transaction types (camelCase enum names from the API).
export const TX_TYPES = {
  deposit:        { label: 'شحن المحفظة',     dir: 'in'  },
  refund:         { label: 'استرداد',          dir: 'in'  },
  reward:         { label: 'مكافأة',           dir: 'in'  },
  coachEarning:   { label: 'أرباح مدرب',       dir: 'in'  },
  venueEarning:   { label: 'أرباح ملعب',       dir: 'in'  },
  creatorEarning: { label: 'استرداد منشئ',     dir: 'in'  },
  matchPayment:   { label: 'دفع مباراة',       dir: 'out' },
  bookingPayment: { label: 'دفع حجز ملعب',     dir: 'out' },
  coachPayment:   { label: 'دفع جلسة مدرب',    dir: 'out' },
  subscription:   { label: 'اشتراك',           dir: 'out' },
  withdrawal:     { label: 'سحب رصيد',         dir: 'out' },
};

export const TX_TYPE_OPTIONS = [
  { value: '', label: 'كل الأنواع' },
  { value: 'Deposit',        label: 'شحن المحفظة' },
  { value: 'Withdrawal',     label: 'سحب رصيد' },
  { value: 'BookingPayment', label: 'دفع حجز ملعب' },
  { value: 'MatchPayment',   label: 'دفع مباراة' },
  { value: 'CoachPayment',   label: 'دفع جلسة مدرب' },
  { value: 'Subscription',   label: 'اشتراك' },
  { value: 'Refund',         label: 'استرداد' },
  { value: 'CoachEarning',   label: 'أرباح مدرب' },
  { value: 'VenueEarning',   label: 'أرباح ملعب' },
  { value: 'CreatorEarning', label: 'استرداد منشئ' },
  { value: 'Reward',         label: 'مكافأة' },
];

export const txLabel = (type) => TX_TYPES[type]?.label ?? type;

// Payment status. A failed row records a rejected attempt (insufficient
// balance) — no money moved, and it is excluded from the finance totals.
export const TX_STATUS = {
  completed: { label: 'تمت',   cls: 'bg-green-100 text-green-700' },
  failed:    { label: 'فشلت',  cls: 'bg-red-100 text-red-600' },
};

export const TX_STATUS_OPTIONS = [
  { value: '',          label: 'كل الحالات' },
  { value: 'Completed', label: 'تمت' },
  { value: 'Failed',    label: 'فشلت' },
];

export const WITHDRAWAL_STATUS = {
  pending:  { label: 'قيد المراجعة', badge: 'pending' },
  approved: { label: 'موافق عليه',   badge: 'active' },
  rejected: { label: 'مرفوض',        badge: 'inactive' },
};

// Money formatting — always Gregorian/latin digits, 2 decimals when needed.
export const money = (v) => {
  const n = Number(v ?? 0);
  const abs = Math.abs(n);
  const str = abs % 1 === 0 ? abs.toLocaleString('en-US') : abs.toLocaleString('en-US', { minimumFractionDigits: 2, maximumFractionDigits: 2 });
  return `${n < 0 ? '−' : ''}${str} ر.س`;
};

export const fmtDateTime = (iso) =>
  iso ? new Date(iso).toLocaleString('ar-SA-u-ca-gregory', {
    year: 'numeric', month: 'short', day: 'numeric', hour: '2-digit', minute: '2-digit',
  }) : '-';

export const fmtDate = (iso) =>
  iso ? new Date(iso).toLocaleDateString('ar-SA-u-ca-gregory', {
    year: 'numeric', month: 'short', day: 'numeric',
  }) : '-';
