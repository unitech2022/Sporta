// Generates a print-ready, branded A4 invoice for a booking and opens the
// browser print dialog (users pick "Save as PDF"). No extra dependencies.

const BRAND = {
  cyan: '#2AB5CE',
  cyanDark: '#1E9AB0',
  navy: '#0A2540',
  gold: '#F0C040',
  ink: '#1F2A37',
  muted: '#6B7280',
  line: '#E5E7EB',
  soft: '#F3F6F9',
};

const STATUS = {
  Pending:   { label: 'بانتظار الموافقة', bg: '#FEF9C3', fg: '#854D0E' },
  Confirmed: { label: 'حجز مؤكّد',        bg: '#DCFCE7', fg: '#166534' },
  Cancelled: { label: 'ملغي',             bg: '#FEE2E2', fg: '#991B1B' },
  Completed: { label: 'مكتمل',            bg: '#DBEAFE', fg: '#1E40AF' },
};

const esc = (v) =>
  String(v ?? '').replace(/[&<>"]/g, (c) => ({ '&': '&amp;', '<': '&lt;', '>': '&gt;', '"': '&quot;' }[c]));

const fmtDate = (iso) =>
  iso ? new Date(iso).toLocaleDateString('ar-SA', { year: 'numeric', month: 'long', day: 'numeric' }) : '—';
const fmtTime = (iso) =>
  iso ? new Date(iso).toLocaleTimeString('ar-SA', { hour: '2-digit', minute: '2-digit' }) : '';
const money = (n) => (n ?? 0).toLocaleString('ar-SA');

export function buildHtml(booking) {
  const st = STATUS[booking.status] ?? STATUS.Pending;
  const no = booking.id?.toString().padStart(5, '0');
  const origin = window.location.origin;
  const timeRange = `${fmtTime(booking.startTime)}${booking.endTime ? ' – ' + fmtTime(booking.endTime) : ''}`;
  const total = booking.totalPrice ?? booking.price ?? 0;
  const issued = new Date().toLocaleDateString('ar-SA', { year: 'numeric', month: 'long', day: 'numeric' });

  const detailRow = (label, value) => `
    <tr>
      <td class="k">${esc(label)}</td>
      <td class="v">${value}</td>
    </tr>`;

  return `<!doctype html>
<html lang="ar" dir="rtl">
<head>
<meta charset="utf-8" />
<title>فاتورة #${esc(no)} — Sporta</title>
<style>
  @page { size: A4; margin: 0; }
  * { box-sizing: border-box; margin: 0; padding: 0; }
  html, body { background: #EEF1F4; }
  body {
    font-family: 'Segoe UI', 'Tahoma', system-ui, sans-serif;
    color: ${BRAND.ink};
    direction: rtl;
    -webkit-print-color-adjust: exact;
    print-color-adjust: exact;
  }
  .sheet {
    width: 210mm; min-height: 297mm; margin: 0 auto; background: #fff;
    position: relative; display: flex; flex-direction: column;
  }
  /* ── Header ── */
  .head {
    background: linear-gradient(135deg, ${BRAND.navy} 0%, ${BRAND.cyanDark} 100%);
    color: #fff; padding: 34px 40px 30px; position: relative; overflow: hidden;
  }
  .head::after {
    content: ''; position: absolute; left: -60px; top: -60px;
    width: 220px; height: 220px; border-radius: 50%;
    background: rgba(255,255,255,.06);
  }
  .head-top { display: flex; justify-content: space-between; align-items: flex-start; position: relative; z-index: 1; }
  .brand { display: flex; align-items: center; gap: 14px; }
  .brand img { height: 52px; width: auto; }
  .brand .logo-fallback {
    height: 52px; width: 52px; border-radius: 14px; background: #fff;
    color: ${BRAND.cyanDark}; font-weight: 800; font-size: 26px;
    display: flex; align-items: center; justify-content: center;
  }
  .brand h1 { font-size: 26px; letter-spacing: .5px; font-weight: 800; }
  .brand p { font-size: 12px; opacity: .8; margin-top: 2px; }
  .inv-label { text-align: left; }
  .inv-label .tag { font-size: 13px; opacity: .8; letter-spacing: 3px; text-transform: uppercase; }
  .inv-label .no { font-size: 30px; font-weight: 800; font-family: 'Courier New', monospace; margin-top: 4px; }
  .head-meta { display: flex; gap: 40px; margin-top: 26px; position: relative; z-index: 1; }
  .head-meta div .lbl { font-size: 11px; opacity: .7; margin-bottom: 3px; }
  .head-meta div .val { font-size: 14px; font-weight: 600; }
  .status-pill {
    display: inline-block; margin-top: 4px; padding: 5px 16px; border-radius: 999px;
    font-size: 13px; font-weight: 700; background: ${st.bg}; color: ${st.fg};
  }
  /* ── Body ── */
  .body { padding: 34px 40px; flex: 1; }
  .section-title {
    font-size: 12px; font-weight: 700; color: ${BRAND.cyanDark};
    letter-spacing: 1px; margin-bottom: 12px; display: flex; align-items: center; gap: 8px;
  }
  .section-title::before { content: ''; width: 5px; height: 16px; border-radius: 3px; background: ${BRAND.cyan}; }
  .cards { display: flex; gap: 18px; margin-bottom: 30px; }
  .card {
    flex: 1; border: 1px solid ${BRAND.line}; border-radius: 16px; padding: 18px 20px; background: ${BRAND.soft};
  }
  .card .who { font-size: 17px; font-weight: 800; color: ${BRAND.navy}; margin-bottom: 6px; }
  .card .sub { font-size: 13px; color: ${BRAND.muted}; line-height: 1.7; }
  table.detail { width: 100%; border-collapse: collapse; }
  table.detail td { padding: 13px 4px; border-bottom: 1px solid ${BRAND.line}; font-size: 14px; }
  table.detail td.k { color: ${BRAND.muted}; width: 38%; }
  table.detail td.v { font-weight: 600; color: ${BRAND.ink}; }
  /* ── Totals ── */
  .totals { margin-top: 28px; display: flex; justify-content: flex-start; }
  .totals-box { width: 300px; }
  .totals-box .row { display: flex; justify-content: space-between; padding: 10px 4px; font-size: 14px; color: ${BRAND.muted}; }
  .totals-box .grand {
    margin-top: 8px; background: linear-gradient(135deg, ${BRAND.cyan}, ${BRAND.cyanDark});
    color: #fff; border-radius: 14px; padding: 16px 20px;
    display: flex; justify-content: space-between; align-items: center;
  }
  .totals-box .grand .lbl { font-size: 14px; opacity: .9; }
  .totals-box .grand .amt { font-size: 24px; font-weight: 800; }
  .totals-box .grand .amt small { font-size: 13px; font-weight: 500; opacity: .85; }
  /* ── Footer ── */
  .foot {
    margin-top: auto; padding: 22px 40px; border-top: 2px dashed ${BRAND.line};
    display: flex; justify-content: space-between; align-items: center;
    font-size: 12px; color: ${BRAND.muted};
  }
  .foot .thanks { font-size: 14px; font-weight: 700; color: ${BRAND.navy}; }
  .stamp {
    position: absolute; left: 44px; bottom: 90px; transform: rotate(-14deg);
    border: 3px solid ${BRAND.cyan}; color: ${BRAND.cyan}; opacity: .18;
    padding: 8px 22px; border-radius: 12px; font-size: 30px; font-weight: 800; letter-spacing: 2px;
  }
  @media print {
    html, body { background: #fff; }
    .sheet { margin: 0; box-shadow: none; }
    .no-print { display: none !important; }
  }
  .bar { position: fixed; top: 0; left: 0; right: 0; background: ${BRAND.navy}; color: #fff;
    padding: 12px 20px; display: flex; gap: 12px; justify-content: center; z-index: 99; }
  .bar button { border: 0; border-radius: 8px; padding: 9px 22px; font-size: 14px; font-weight: 700; cursor: pointer; font-family: inherit; }
  .bar .print { background: ${BRAND.cyan}; color: #fff; }
  .bar .close { background: rgba(255,255,255,.15); color: #fff; }
  .spacer { height: 52px; }
</style>
</head>
<body>
  <div class="bar no-print">
    <button class="print" onclick="window.print()">🖨️ حفظ / طباعة PDF</button>
    <button class="close" onclick="window.close()">إغلاق</button>
  </div>
  <div class="spacer no-print"></div>

  <div class="sheet">
    <div class="head">
      <div class="head-top">
        <div class="brand">
          <img src="${origin}/logo.png" alt="Sporta" onerror="this.outerHTML='<div class=\\'logo-fallback\\'>S</div>'" />
          <div>
            <h1>SPORTA</h1>
            <p>منصة حجز الملاعب الرياضية</p>
          </div>
        </div>
        <div class="inv-label">
          <div class="tag">Invoice</div>
          <div class="no">#${esc(no)}</div>
        </div>
      </div>
      <div class="head-meta">
        <div>
          <div class="lbl">تاريخ الإصدار</div>
          <div class="val">${esc(issued)}</div>
        </div>
        <div>
          <div class="lbl">تاريخ الحجز</div>
          <div class="val">${esc(fmtDate(booking.startTime ?? booking.bookingDate))}</div>
        </div>
        <div>
          <div class="lbl">الحالة</div>
          <div class="status-pill">${esc(st.label)}</div>
        </div>
      </div>
    </div>

    <div class="body">
      <div class="cards">
        <div class="card">
          <div class="section-title">فاتورة إلى</div>
          <div class="who">${esc(booking.userName || 'اللاعب')}</div>
          <div class="sub">${booking.userPhone ? esc(booking.userPhone) + '<br/>' : ''}${esc(booking.city || '')}</div>
        </div>
        <div class="card">
          <div class="section-title">مقدّم الخدمة</div>
          <div class="who">${esc(booking.venueName || '—')}</div>
          <div class="sub">${esc(booking.courtName || '')}<br/>${esc(booking.city || '')}</div>
        </div>
      </div>

      <div class="section-title">تفاصيل الحجز</div>
      <table class="detail">
        ${detailRow('الملعب', esc(booking.courtName || '—'))}
        ${detailRow('المنشأة', esc(booking.venueName || '—'))}
        ${detailRow('التاريخ', esc(fmtDate(booking.startTime ?? booking.bookingDate)))}
        ${detailRow('الوقت', esc(timeRange) || '—')}
        ${detailRow('المدة', booking.durationMinutes ? esc(booking.durationMinutes) + ' دقيقة' : '—')}
        ${detailRow('حالة الدفع', booking.paidFullAmount ? 'مدفوع بالكامل' : 'غير مكتمل الدفع')}
      </table>

      <div class="totals">
        <div class="totals-box">
          <div class="row"><span>الإجمالي الفرعي</span><span>${money(total)} ر.س</span></div>
          <div class="row"><span>الضريبة</span><span>0 ر.س</span></div>
          <div class="grand">
            <span class="lbl">المبلغ الإجمالي</span>
            <span class="amt">${money(total)} <small>ر.س</small></span>
          </div>
        </div>
      </div>
      ${booking.status === 'Completed' || booking.paidFullAmount ? `<div class="stamp">مدفوع</div>` : ''}
    </div>

    <div class="foot">
      <div>
        <div class="thanks">شكراً لاستخدامك Sporta ⚽</div>
        <div>هذه فاتورة إلكترونية ولا تتطلب توقيعاً.</div>
      </div>
      <div style="text-align:left">
        <div>sportaapp.net</div>
        <div>فاتورة #${esc(no)}</div>
      </div>
    </div>
  </div>

  <script>
    window.addEventListener('load', function () {
      setTimeout(function () { window.print(); }, 350);
    });
  </script>
</body>
</html>`;
}

export function downloadInvoicePdf(booking) {
  if (!booking) return;
  const win = window.open('', '_blank', 'width=880,height=1000');
  if (!win) {
    alert('يرجى السماح بالنوافذ المنبثقة لتحميل الفاتورة');
    return;
  }
  win.document.open();
  win.document.write(buildHtml(booking));
  win.document.close();
}
