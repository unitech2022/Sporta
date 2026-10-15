#!/usr/bin/env bash
#
# نشر سبورتا على السيرفر — الواجهة الخلفية + لوحة التحكم.
#
# أمر واحد يفعل كل شيء: بناء + ترقية قاعدة البيانات إن لزم + رفع + إعادة تشغيل.
#
#   ./deploy.sh               نشر كامل (يطبّق أي مايجريشن جديد تلقائياً)
#   ./deploy.sh api           الواجهة الخلفية فقط
#   ./deploy.sh dashboard     لوحة التحكم فقط (بلا توقف، بلا قاعدة بيانات)
#   ./deploy.sh --no-migrate  تخطّي قاعدة البيانات
#   ./deploy.sh --no-backup   تخطّي النسخة الاحتياطية (غير موصى به)
#   ./deploy.sh --dry-run     يعرض ما سيتغيّر دون لمس السيرفر
#
set -euo pipefail

# ── الإعدادات ───────────────────────────────────────────────────────────────
# عنوان السيرفر — يمكن تجاوزه: SERVER_IP=1.2.3.4 ./deploy.sh
SERVER_IP="${SERVER_IP:-167.172.201.182}"
SSH_USER="${SSH_USER:-root}"
SSH_PORT="${SSH_PORT:-22}"

API_DIR="/www/wwwroot/apis.sportaapp.net"
DASH_DIR="/www/wwwroot/admin.sportaapp.net"
SERVICE="sporta.service"

API_URL="https://apis.sportaapp.net"
DASH_URL="https://admin.sportaapp.net"

# سكربت الترقية. الافتراضي: يُولَّد من EF عند كل نشر فيلتقط أي مايجريشن جديد
# تلقائياً. مرّر ملفاً جاهزاً لتجاوز التوليد: MIGRATION_SQL=path/to.sql ./deploy.sh
MIGRATION_SQL="${MIGRATION_SQL:-}"
DB_NAME="${DB_NAME:-SportaDb}"
BACKUP_DIR="${BACKUP_DIR:-/root/sporta-backups}"

# ── ألوان ومساعدات ──────────────────────────────────────────────────────────
readonly RED=$'\033[0;31m' GREEN=$'\033[0;32m' YELLOW=$'\033[1;33m' BLUE=$'\033[0;34m' OFF=$'\033[0m'
step() { printf '\n%s▸ %s%s\n' "$BLUE" "$1" "$OFF"; }
ok()   { printf '%s✓ %s%s\n' "$GREEN" "$1" "$OFF"; }
warn() { printf '%s! %s%s\n' "$YELLOW" "$1" "$OFF"; }
die()  { printf '%s✗ %s%s\n' "$RED" "$1" "$OFF" >&2; exit 1; }

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$ROOT"

# ── قراءة الوسائط ───────────────────────────────────────────────────────────
TARGET="all"; DRY_RUN=""; RUN_MIGRATION=1; SKIP_BACKUP=0
for arg in "$@"; do
  case "$arg" in
    api|dashboard|all) TARGET="$arg" ;;
    --migrate)         RUN_MIGRATION=1 ;;   # افتراضي أصلاً — مقبول للتوافق
    --no-migrate)      RUN_MIGRATION=0 ;;
    --no-backup)       SKIP_BACKUP=1 ;;
    --dry-run)         DRY_RUN="--dry-run" ;;
    -h|--help)         sed -n '3,12p' "$0"; exit 0 ;;
    *)                 die "وسيط غير معروف: $arg" ;;
  esac
done

# ── فحوص قبل البدء ──────────────────────────────────────────────────────────
step "فحص المتطلبات"

[[ -n "$SERVER_IP" ]] || die "SERVER_IP غير محدد. عدّله في أعلى الملف أو مرّره: SERVER_IP=1.2.3.4 ./deploy.sh"

for bin in ssh rsync; do
  command -v "$bin" >/dev/null || die "$bin غير مثبّت"
done
[[ "$TARGET" == "dashboard" ]] || command -v dotnet >/dev/null || die "dotnet غير مثبّت"
[[ "$TARGET" == "api" ]]       || command -v npm    >/dev/null || die "npm غير مثبّت"

STAGE="$(mktemp -d)"

# قناة SSH واحدة مشتركة لكل الأوامر (ssh/rsync/scp). بدونها تُطلب كلمة المرور
# ست مرات في النشر الواحد عند استخدام المصادقة بكلمة مرور.
#
# مقبس القناة يجب أن يبقى قصيراً: حد مقبس Unix ‎~104‎ حرفاً، ومجلد ‎mktemp‎ المؤقت
# على macOS وحده يتجاوز ‎70‎ حرفاً. لذا نضعه في ‎/tmp‎ ونسمّيه بـ ‎%C‎ (بصمة ثابتة
# الطول للاتصال) بدل المستخدم والمضيف والمنفذ.
CONTROL_PATH="/tmp/.sporta-ssh-%C"
SSH_OPTS=(-p "$SSH_PORT"
          -o ControlMaster=auto
          -o ControlPath="$CONTROL_PATH"
          -o ControlPersist=600
          -o ConnectTimeout=15)
SSH=(ssh "${SSH_OPTS[@]}" "${SSH_USER}@${SERVER_IP}")

# تُغلق القناة المشتركة ويُنظَّف المجلد المؤقت مهما كانت نتيجة السكربت.
cleanup() {
  ssh "${SSH_OPTS[@]}" -O exit "${SSH_USER}@${SERVER_IP}" 2>/dev/null || true
  rm -rf "$STAGE"
}
trap cleanup EXIT

# stdout فقط يُكتَم — رسائل SSH وطلب كلمة المرور تبقى ظاهرة للمستخدم.
printf '  (قد تُطلب كلمة مرور %s@%s مرة واحدة)\n' "$SSH_USER" "$SERVER_IP"
"${SSH[@]}" "echo ok" >/dev/null \
  || die "تعذّر الاتصال بـ ${SSH_USER}@${SERVER_IP}:${SSH_PORT} — تحقق من الـ IP وبيانات الدخول"
RSYNC_SSH="ssh -p $SSH_PORT -o ControlMaster=auto -o ControlPath=$CONTROL_PATH -o ControlPersist=600"
ok "الاتصال بالسيرفر يعمل"

# في التجربة نُظهر تفاصيل كل ملف: الغاية منها رؤية ما سيُنقل وما **سيُحذف**
# قبل أول نشر، لا مجرد التأكد أن الاتصال يعمل.
RSYNC_FLAGS=(-az --delete)
if [[ -n "$DRY_RUN" ]]; then
  warn "وضع التجربة: لن يُكتب شيء على السيرفر"
  RSYNC_FLAGS+=(--dry-run --itemize-changes --stats)
fi

# ── بناء الواجهة الخلفية ────────────────────────────────────────────────────
if [[ "$TARGET" == "all" || "$TARGET" == "api" ]]; then
  step "بناء الواجهة الخلفية (Release)"
  dotnet publish SportaApis/SportaApis.csproj -c Release -o "$STAGE/api" --nologo -v q
  ok "تم البناء"
fi

# نشر لوحة التحكم وحدها لا يمسّ قاعدة البيانات إطلاقاً.
[[ "$TARGET" == "dashboard" ]] && RUN_MIGRATION=0

# ── توليد سكربت الترقية ─────────────────────────────────────────────────────
# يُولَّد قبل إيقاف الخدمة: لو فشل التوليد نتوقف والخدمة ما زالت تعمل.
if [[ "$RUN_MIGRATION" == "1" && -z "$MIGRATION_SQL" ]]; then
  step "توليد سكربت الترقية من EF"
  command -v dotnet >/dev/null || die "dotnet مطلوب لتوليد سكربت الترقية"

  # ‎--idempotent‎ يلفّ كل مايجريشن بفحص على ‎__EFMigrationsHistory‎، فيطبّق
  # الناقص فقط ويتجاهل المطبَّق — يصحّ على أي قاعدة مهما كانت متأخرة.
  dotnet ef migrations script --idempotent \
    --project SportaApis/SportaApis.csproj \
    -o "$STAGE/migration.sql" --no-build 2>/dev/null \
    || dotnet ef migrations script --idempotent \
         --project SportaApis/SportaApis.csproj -o "$STAGE/migration.sql" \
    || die "فشل توليد سكربت الترقية. الأسباب المحتملة:
  • dotnet-ef غير مثبّت:  dotnet tool install -g dotnet-ef
  • خطأ بناء في المشروع — راجع الرسالة أعلاه
التوليد لا يحتاج قاعدة بيانات شغّالة (انظر Data/DesignTimeDbContextFactory.cs)،
فإن ذكرت الرسالة تعذّر الاتصال بـ MySQL فالمشكلة في المصنع لا في قاعدتك."

  MIGRATION_SQL="$STAGE/migration.sql"

  # آخر مايجريشن محلي — يقارنه السيرفر بسجله ليعرف هل هناك جديد فعلاً.
  LATEST_MIGRATION="$(ls -1 SportaApis/Migrations/*.cs \
    | grep -v Designer | grep -v Snapshot \
    | sed 's|.*/||; s|\.cs$||' | sort | tail -1)"
  [[ -n "$LATEST_MIGRATION" ]] || die "تعذّر تحديد آخر مايجريشن"

  ok "تم التوليد ($(wc -l < "$MIGRATION_SQL" | tr -d ' ') سطر) — آخر مايجريشن: $LATEST_MIGRATION"
fi

# ── بناء لوحة التحكم ────────────────────────────────────────────────────────
if [[ "$TARGET" == "all" || "$TARGET" == "dashboard" ]]; then
  step "بناء لوحة التحكم"

  # مهم: ‎.env.local‎ يُقرأ في بناء الإنتاج أيضاً، وفيه عنوان السيرفر المحلي
  # أثناء التطوير. نمرّر العنوان صراحةً كمتغيّر بيئة لأن له الأولوية على ملفات
  # ‎.env‎ — وإلا شُحنت لوحة التحكم وهي تنادي localhost.
  if [[ -f sporta-dashboard/.env.local ]]; then
    warn "‎.env.local‎ موجود — سيُتجاوَز بـ VITE_API_BASE_URL=${API_URL}"
  fi

  ( cd sporta-dashboard \
    && npm ci --silent \
    && VITE_API_BASE_URL="$API_URL" npm run build --silent )

  grep -rq "localhost:7000" sporta-dashboard/dist/assets/*.js 2>/dev/null \
    && die "البناء يحتوي على localhost:7000 — تحقق من ‎.env.local‎ قبل النشر"

  cp -R sporta-dashboard/dist "$STAGE/dashboard"
  ok "تم البناء وعنوان الـ API صحيح"
fi

# ── إيقاف الخدمة قبل استبدال الملفات ────────────────────────────────────────
if [[ "$TARGET" == "all" || "$TARGET" == "api" ]] && [[ -z "$DRY_RUN" ]]; then
  step "إيقاف $SERVICE"
  "${SSH[@]}" "systemctl stop $SERVICE" || warn "تعذّر الإيقاف (قد تكون متوقفة أصلاً)"
fi

# ── ترقية قاعدة البيانات ────────────────────────────────────────────────────
# تأتي **بعد** إيقاف الخدمة: الترقية تغيّر معنى نسبة العمولة (كانت تُضاف فوق
# السعر وصارت تُقتطع منه)، فلو بقي الكود القديم شغّالاً على المخطط الجديد لحسب
# أسعاراً خاطئة في النافذة بين الترقية والرفع.
if [[ "$RUN_MIGRATION" == "1" ]]; then
  step "ترقية قاعدة البيانات"
  [[ -f "$MIGRATION_SQL" ]] || die "ملف الترقية غير موجود: $MIGRATION_SQL"

  if [[ -n "$DRY_RUN" ]]; then
    warn "تجربة: كان سيُؤخذ نسخة احتياطية في $BACKUP_DIR ثم تُطبَّق الترقية على $DB_NAME"
  else
    STAMP="$(date +%Y-%m-%d_%H%M%S)"
    REMOTE_SQL="/tmp/sporta_migration_${STAMP}.sql"
    REMOTE_RUNNER="/tmp/sporta_migrate_${STAMP}.sh"

    # يُبنى محلياً ويُنفَّذ على السيرفر: يطلب كلمة مرور MySQL مرة واحدة، يأخذ
    # نسخة احتياطية، يتحقق من سلامتها، ثم يطبّق الترقية. كلمة المرور تُكتب في
    # ملف إعدادات مؤقت بصلاحية 600 بدل سطر الأوامر — فلا تظهر في ps ولا history.
    cat > "$STAGE/migrate.sh" <<REMOTE_SCRIPT
set -euo pipefail
DB="$DB_NAME"
SQL="$REMOTE_SQL"
BACKUP_DIR="$BACKUP_DIR"
STAMP="$STAMP"
API_DIR="$API_DIR"
LATEST_MIGRATION="$LATEST_MIGRATION"
$( [[ "$SKIP_BACKUP" == "1" ]] && echo 'SKIP_BACKUP=1' || echo 'SKIP_BACKUP=0' )
REMOTE_SCRIPT
    cat >> "$STAGE/migrate.sh" <<'REMOTE_SCRIPT'

CNF="$(mktemp)"; chmod 600 "$CNF"
cleanup_remote() { rm -f "$CNF" "$SQL"; }
trap cleanup_remote EXIT

# بيانات الاتصال تُقرأ من إعدادات السيرفر نفسه — هي المصدر الموثوق، وتوفّر
# سؤال المستخدم عن كلمة المرور في كل نشر. تُكتب في ملف 600 لا في سطر الأوامر.
# بيانات الاتصال تُقرأ من إعدادات السيرفر نفسه — هي المصدر الموثوق، وتوفّر
# سؤال المستخدم عن كلمة المرور في كل نشر. التحليل يتم في بايثون لأن قيم سلسلة
# الاتصال قد تحوي ; أو = داخل اقتباس، وتقسيمها في الصدفة يبترها.
for f in "$API_DIR/appsettings.Production.json" "$API_DIR/appsettings.json"; do
  [ -f "$f" ] || continue
  eval "$(python3 - "$f" <<'PY' 2>/dev/null || true
import json, shlex, sys

def parse(cs):
    """يقسّم سلسلة اتصال ADO.NET محترماً الاقتباس حول القيم."""
    parts, buf, quote = [], [], None
    for ch in cs:
        if quote:
            if ch == quote: quote = None
            else: buf.append(ch)
        elif ch in ("'", '"'):
            quote = ch
        elif ch == ';':
            parts.append(''.join(buf)); buf = []
        else:
            buf.append(ch)
    parts.append(''.join(buf))

    out = {}
    for part in parts:
        if '=' not in part: continue
        k, v = part.split('=', 1)
        out[k.strip().lower()] = v.strip()
    return out

try:
    conf = json.load(open(sys.argv[1]))
    strings = conf.get("ConnectionStrings", {})
    cs = strings.get("DefaultConnection") or next(iter(strings.values()), "")
    kv = parse(cs)
    user = kv.get("user") or kv.get("uid") or kv.get("user id") or kv.get("username")
    pwd  = kv.get("password") or kv.get("pwd")
    db   = kv.get("database") or kv.get("initial catalog")
    if user and pwd:
        print("DBUSER=" + shlex.quote(user))
        print("DBPASS=" + shlex.quote(pwd))
        if db: print("DB=" + shlex.quote(db))
except Exception:
    pass
PY
)"
  [ -n "${DBUSER:-}" ] && break
done

if [ -n "${DBUSER:-}" ] && [ -n "${DBPASS:-}" ]; then
  echo "» قرأت بيانات الاتصال من إعدادات السيرفر (قاعدة: $DB)"
else
  echo "» تعذّرت قراءة بيانات الاتصال من appsettings"
  read -rp "مستخدم MySQL [root]: " DBUSER < /dev/tty; DBUSER="${DBUSER:-root}"
  read -rsp "كلمة مرور MySQL: " DBPASS < /dev/tty; echo
fi

printf '[client]\nuser=%s\npassword=%s\n' "$DBUSER" "$DBPASS" > "$CNF"
unset DBPASS

mysql --defaults-extra-file="$CNF" -e "SELECT 1" "$DB" >/dev/null \
  || { echo "تعذّر الاتصال بقاعدة $DB" >&2; exit 1; }

# هل آخر مايجريشن محلي مطبَّق سلفاً؟ إن نعم فلا جديد — نتخطى النسخة والترقية
# معاً بدل أخذ نسخة احتياطية بلا داعٍ في كل نشر.
APPLIED="$(mysql --defaults-extra-file="$CNF" -N -B "$DB" \
  -e "SELECT COUNT(*) FROM \`__EFMigrationsHistory\` WHERE MigrationId='$LATEST_MIGRATION'" 2>/dev/null || echo 0)"

if [ "$APPLIED" = "1" ]; then
  echo "» قاعدة البيانات محدَّثة — لا مايجريشن جديد"
  exit 0
fi

echo "» يوجد مايجريشن غير مطبَّق: $LATEST_MIGRATION"

if [ "$SKIP_BACKUP" = "0" ]; then
  mkdir -p "$BACKUP_DIR"
  DUMP="$BACKUP_DIR/${DB}_${STAMP}.sql"
  echo "» أخذ نسخة احتياطية إلى $DUMP"
  mysqldump --defaults-extra-file="$CNF" --single-transaction --routines "$DB" > "$DUMP"

  # نسخة فارغة أو مبتورة أخطر من عدمها — نتوقف قبل لمس المخطط.
  if [ ! -s "$DUMP" ] || ! tail -5 "$DUMP" | grep -q "Dump completed"; then
    echo "النسخة الاحتياطية ناقصة أو فارغة — أُلغيت الترقية ولم يتغيّر شيء" >&2
    exit 1
  fi
  gzip -f "$DUMP"
  echo "» النسخة جاهزة: ${DUMP}.gz ($(du -h "${DUMP}.gz" | cut -f1))"

  # إبقاء آخر عشر نسخ فقط حتى لا يمتلئ القرص مع تكرار النشر.
  ls -1t "$BACKUP_DIR"/${DB}_*.sql.gz 2>/dev/null | tail -n +11 | xargs -r rm -f
fi

echo "» تطبيق الترقية"
mysql --defaults-extra-file="$CNF" "$DB" < "$SQL"
echo "» تمت الترقية"
REMOTE_SCRIPT

    scp "${SSH_OPTS[@]/#-p/-P}" -q "$MIGRATION_SQL" "${SSH_USER}@${SERVER_IP}:${REMOTE_SQL}"
    scp "${SSH_OPTS[@]/#-p/-P}" -q "$STAGE/migrate.sh" "${SSH_USER}@${SERVER_IP}:${REMOTE_RUNNER}"

    # ‎-t‎ ضروري: طلب كلمة المرور يقرأ من الطرفية، وبلا tty يفشل.
    "${SSH[@]}" -t "bash '$REMOTE_RUNNER'; rc=\$?; rm -f '$REMOTE_RUNNER'; exit \$rc" \
      || die "فشلت الترقية — الخدمة ما زالت متوقفة ولم يُرفع شيء. راجع الخطأ أعلاه ثم أعد المحاولة."
    ok "طُبِّقت الترقية"
  fi
fi

# ── رفع الواجهة الخلفية ─────────────────────────────────────────────────────
if [[ "$TARGET" == "all" || "$TARGET" == "api" ]]; then
  step "رفع الواجهة الخلفية إلى $API_DIR"

  # ‎--delete‎ ينظّف ملفات البناء القديمة، والاستثناءات تحمي ما يخصّ السيرفر:
  # إعداداته الحيّة (سلسلة الاتصال ومفاتيح الدفع) وملفات المستخدمين المرفوعة.
  rsync "${RSYNC_FLAGS[@]}" \
    -e "${RSYNC_SSH}" \
    --exclude 'appsettings.json' \
    --exclude 'appsettings.*.json' \
    --exclude 'wwwroot/uploads/' \
    --exclude 'logs/' \
    "$STAGE/api/" "${SSH_USER}@${SERVER_IP}:${API_DIR}/"
  ok "تم الرفع (إعدادات السيرفر وملفات الرفع لم تُمسّ)"
fi

# ── رفع لوحة التحكم ─────────────────────────────────────────────────────────
if [[ "$TARGET" == "all" || "$TARGET" == "dashboard" ]]; then
  step "رفع لوحة التحكم إلى $DASH_DIR"
  rsync "${RSYNC_FLAGS[@]}" \
    -e "${RSYNC_SSH}" \
    "$STAGE/dashboard/" "${SSH_USER}@${SERVER_IP}:${DASH_DIR}/"
  ok "تم الرفع"
fi

# ── تشغيل الخدمة والتحقق ────────────────────────────────────────────────────
if [[ -n "$DRY_RUN" ]]; then
  printf '\n%s✓ انتهت التجربة — لم يتغيّر شيء على السيرفر%s\n' "$GREEN" "$OFF"
  exit 0
fi

if [[ "$TARGET" == "all" || "$TARGET" == "api" ]]; then
  step "تشغيل $SERVICE"
  "${SSH[@]}" "systemctl start $SERVICE && sleep 3 && systemctl is-active --quiet $SERVICE" \
    || { "${SSH[@]}" "journalctl -u $SERVICE -n 40 --no-pager"; die "الخدمة لم تعمل — السجل أعلاه"; }
  ok "الخدمة تعمل"

  step "فحص الصحة"
  CODE="$(curl -s -o /dev/null -w '%{http_code}' --max-time 20 "${API_URL}/api/settings/public" || echo 000)"
  [[ "$CODE" == "200" ]] && ok "الـ API يستجيب (200)" || warn "الـ API ردّ بـ $CODE — راجع journalctl -u $SERVICE"
fi

if [[ "$TARGET" == "all" || "$TARGET" == "dashboard" ]]; then
  CODE="$(curl -s -o /dev/null -w '%{http_code}' --max-time 20 "$DASH_URL" || echo 000)"
  [[ "$CODE" == "200" ]] && ok "لوحة التحكم تستجيب (200)" || warn "اللوحة ردّت بـ $CODE"
fi

printf '\n%s✓ اكتمل النشر%s\n' "$GREEN" "$OFF"
