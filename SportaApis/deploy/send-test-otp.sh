#!/usr/bin/env bash
#
# إرسال رمز تحقق تجريبي عبر Authentica مباشرةً — لتشخيص قناة الإرسال دون المرور
# بالـ API. يتجاوز حدودنا (المهلة والسقف) لأنه ينادي المزوّد رأساً، فهو أداة
# تشخيص لا مسار تشغيل.
#
#   ./send-test-otp.sh 0578071495              إرسال SMS (الافتراضي)
#   ./send-test-otp.sh 0578071495 whatsapp     تجربة قناة واتساب
#   ./send-test-otp.sh 0578071495 sms 123456   التحقق من رمز وصل
#
# المفتاح لا يُكتب في هذا الملف ولا يُطبع: يُقرأ من متغيّر البيئة
# AUTHENTICA_API_KEY إن وُجد، وإلا من إعدادات السيرفر عبر SSH.
#
set -euo pipefail

PHONE_RAW="${1:-}"
METHOD="${2:-sms}"
OTP="${3:-}"

SERVER="${SERVER:-sporta}"
API_DIR="${API_DIR:-/www/wwwroot/apis.sportaapp.net}"

readonly RED=$'\033[0;31m' GREEN=$'\033[0;32m' YELLOW=$'\033[1;33m' BLUE=$'\033[0;34m' OFF=$'\033[0m'
die() { printf '%s✗ %s%s\n' "$RED" "$1" "$OFF" >&2; exit 1; }
ok()  { printf '%s✓ %s%s\n' "$GREEN" "$1" "$OFF"; }

[[ -n "$PHONE_RAW" ]] || die "الاستعمال: $0 <رقم> [sms|whatsapp] [رمز للتحقق]"
[[ "$METHOD" == "sms" || "$METHOD" == "whatsapp" ]] || die "القناة يجب أن تكون sms أو whatsapp"

# ── تطبيع الرقم إلى E.164 ───────────────────────────────────────────────────
# نفس قاعدة Helpers/PhoneNumber.cs: يقبل 05… و5… و966… و+966… و00966…
digits="${PHONE_RAW//[^0-9]/}"
digits="${digits#00966}"
[[ "$digits" == 966* && ${#digits} -gt 10 ]] && digits="${digits#966}"
[[ ${#digits} -eq 9 && "$digits" == 5* ]] && digits="0$digits"
[[ ${#digits} -eq 10 && "$digits" == 05* ]] || die "رقم جوال سعودي غير صالح: $PHONE_RAW"
E164="+966${digits:1}"

# ── المفتاح ─────────────────────────────────────────────────────────────────
KEY="${AUTHENTICA_API_KEY:-}"
if [[ -z "$KEY" ]]; then
  printf '%s▸ قراءة المفتاح من إعدادات السيرفر (%s)%s\n' "$BLUE" "$SERVER" "$OFF"
  KEY="$(ssh -o BatchMode=yes "$SERVER" "
    python3 - '$API_DIR/appsettings.Production.json' '$API_DIR/appsettings.json' <<'PY'
import json, sys
for path in sys.argv[1:]:
    try:
        key = json.load(open(path)).get('Otp', {}).get('Authentica', {}).get('ApiKey', '')
        if key:
            print(key); break
    except Exception:
        pass
PY" 2>/dev/null)" || die "تعذّر الاتصال بالسيرفر"

  [[ -n "$KEY" ]] || die "لم يُعثر على مفتاح Authentica في إعدادات السيرفر.
مرّره يدوياً: AUTHENTICA_API_KEY='...' $0 $PHONE_RAW"
  ok "المفتاح جاهز (${#KEY} حرف — لا يُطبع)"
fi

# ── النداء ──────────────────────────────────────────────────────────────────
if [[ -n "$OTP" ]]; then
  printf '%s▸ التحقق من الرمز لـ %s%s\n' "$BLUE" "$E164" "$OFF"
  PATH_SEG="verify-otp"
  BODY="$(printf '{"phone":"%s","otp":"%s"}' "$E164" "$OTP")"
else
  printf '%s▸ إرسال رمز عبر %s إلى %s%s\n' "$BLUE" "$METHOD" "$E164" "$OFF"
  PATH_SEG="send-otp"
  BODY="$(printf '{"method":"%s","phone":"%s","template_id":1}' "$METHOD" "$E164")"
fi

RESPONSE="$(curl -s -m 30 -w '\n%{http_code}' \
  -X POST "https://api.authentica.sa/api/v2/$PATH_SEG" \
  -H "X-Authorization: $KEY" \
  -H 'Accept: application/json' \
  -H 'Content-Type: application/json' \
  -d "$BODY")" || die "فشل الاتصال بـ Authentica"

STATUS="$(tail -n1 <<<"$RESPONSE")"
PAYLOAD="$(sed '$d' <<<"$RESPONSE")"

printf '\nHTTP %s\n%s\n\n' "$STATUS" "$PAYLOAD"

case "$STATUS" in
  200|201) ok "نجح — تحقّق من جهازك" ;;
  401) die "المفتاح مرفوض — راجع Otp:Authentica:ApiKey" ;;
  422) printf '%s! القناة %s غير مفعّلة على حسابك لدى Authentica.%s\n' \
         "$YELLOW" "$METHOD" "$OFF"
       printf '  راسل دعمهم لتفعيلها: https://wa.me/966536553944\n'; exit 1 ;;
  429) die "تجاوزت حدّ الإرسال لدى المزوّد — انتظر قليلاً" ;;
  *)   die "ردّ غير متوقع ($STATUS)" ;;
esac
