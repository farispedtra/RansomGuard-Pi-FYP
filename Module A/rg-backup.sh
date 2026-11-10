#!/usr/bin/env bash
# rg-backup - RansomGuard Pi, Modul A (Backup & Recovery)
# Guna: sudo rg-backup <arahan>   (lihat "rg-backup help")
# Keperluan: restic, rsync, python3, docker compose
set -euo pipefail

NC_DIR="${RG_NC_DIR:-/home/hafa/nextcloud}"   # folder docker-compose.yml Nextcloud
BASE="${RG_BASE:-/srv/rg-backup}"             # tempat repo backup (BUKAN dalam folder Nextcloud)
REPO="$BASE/repo"
STATE="$BASE/state"
PASSFILE="${RG_PASSFILE:-/root/.rg-restic-pass}"
PIN_FILE="$STATE/PINNED"
LOG="$STATE/rg-backup.log"
METRICS="$STATE/metrics.csv"
DATA="$NC_DIR/data"
export RESTIC_REPOSITORY="$REPO" RESTIC_PASSWORD_FILE="$PASSFILE"

need_root() { [ "$(id -u)" -eq 0 ] || { echo "Jalankan dengan sudo." >&2; exit 1; }; }
log() { mkdir -p "$STATE"; printf '%s %s\n' "$(date '+%F %T')" "$*" | tee -a "$LOG" >&2; }
dc() { docker compose --project-directory "$NC_DIR" "$@"; }
occ() { dc exec -T -u www-data app php occ "$@"; }
maint_on() { occ maintenance:mode --on >/dev/null; }
maint_off() { occ maintenance:mode --off >/dev/null || true; }

# lock [-w saat]  (lalai: gagal terus kalau sibuk)
lock() {
  mkdir -p "$STATE"; exec 9>"$STATE/.lock"
  if [ $# -eq 0 ]; then set -- -n; fi
  flock "$@" 9 || { echo "rg-backup lain sedang berjalan." >&2; exit 1; }
}

# Ratakan output "restic snapshots --json" (format boleh berbeza antara versi)
read -r -d '' PY_PICK <<'PY' || true
import sys, json, re
from datetime import datetime
before = sys.argv[1] if len(sys.argv) > 1 else ""
data = json.load(sys.stdin)
snaps = []
for item in data:
    if isinstance(item, dict) and "snapshots" in item and "time" not in item:
        snaps.extend(item["snapshots"] or [])
    else:
        snaps.append(item)
def parse(s):
    s = re.sub(r'(\.\d{6})\d*', r'\1', s)
    if s.endswith('Z'):
        s = s[:-1] + '+00:00'
    return datetime.fromisoformat(s)
limit = None
if before:
    if re.fullmatch(r'\d+(\.\d+)?', before):
        limit = datetime.fromtimestamp(float(before)).astimezone()
    else:
        limit = parse(before.replace(' ', 'T'))
        if limit.tzinfo is None:
            limit = limit.astimezone()
best = None
for s in snaps:
    t = parse(s['time'])
    if limit is None or t <= limit:
        if best is None or t > best[0]:
            best = (t, s['short_id'])
print(best[1] if best else "")
PY

cmd_init() {
  need_root
  mkdir -p "$REPO" "$STATE"; chmod 700 "$BASE"
  if [ ! -f "$PASSFILE" ]; then
    head -c 32 /dev/urandom | base64 > "$PASSFILE"; chmod 600 "$PASSFILE"
    log "Kata laluan repo dijana di $PASSFILE (simpan satu salinan di tempat lain!)"
  fi
  if restic cat config >/dev/null 2>&1; then log "Repo sudah wujud."; else restic init; fi
}

cmd_backup() {
  need_root; lock
  local tag="${1:-auto}" t0 t1 sid size
  if [ -f "$PIN_FILE" ]; then
    log "BEKU: snapshot dipin ($(head -1 "$PIN_FILE")), backup dan rotation dilangkau."
    return 0
  fi
  t0=$(date +%s)
  log "Backup bermula (tag=$tag)"
  maint_on
  trap 'maint_off' EXIT

  # 1) DB dan config pada saat yang sama dengan fail (maintenance mode = tiada tulisan klien)
  dc exec -T db sh -c 'mariadb-dump -u root -p"$MARIADB_ROOT_PASSWORD" --single-transaction nextcloud' > "$STATE/db.sql.tmp"
  [ -s "$STATE/db.sql.tmp" ] || { log "RALAT: dump DB kosong"; rm -f "$STATE/db.sql.tmp"; return 1; }
  mv "$STATE/db.sql.tmp" "$STATE/db.sql"
  dc cp app:/var/www/html/config/config.php "$STATE/config.php" 2>/dev/null || log "Amaran: config.php tidak disalin"

  # 2) Manifest SHA-256 bagi fail data (untuk sahkan selepas restore)
  (cd "$DATA" && find . -type f ! -name nextcloud.log ! -path './appdata_*/preview/*' -print0 \
      | sort -z | xargs -0 -r sha256sum) > "$STATE/manifest.sha256"

  # 3) Snapshot berversi
  local paths=("$DATA" "$STATE/db.sql" "$STATE/manifest.sha256")
  if [ -f "$STATE/config.php" ]; then paths+=("$STATE/config.php"); fi
  restic backup --tag "$tag" \
      --exclude "$DATA/nextcloud.log" --exclude "$DATA/appdata_*/preview" \
      "${paths[@]}" >/dev/null
  maint_off; trap - EXIT

  # 4) Rotation (tidak pernah jalan semasa beku/pin; lihat awal cmd_backup)
  restic forget --keep-hourly 24 --keep-daily 7 --keep-weekly 4 --prune >/dev/null

  # 5) Metrik untuk bab penilaian
  t1=$(date +%s)
  sid=$(restic snapshots --json | python3 -c '
import sys, json
d = json.load(sys.stdin); s = []
for i in d:
    if isinstance(i, dict) and "snapshots" in i and "time" not in i: s.extend(i["snapshots"] or [])
    else: s.append(i)
s.sort(key=lambda x: x["time"]); print(s[-1]["short_id"])')
  size=$(du -sb "$REPO" | cut -f1)
  [ -f "$METRICS" ] || echo "waktu,tag,snapshot,tempoh_s,saiz_repo_bait" > "$METRICS"
  echo "$(date -Is),$tag,$sid,$((t1 - t0)),$size" >> "$METRICS"
  log "Backup siap: snapshot $sid, $((t1 - t0))s, repo $size bait"
}

# Dipanggil Modul B bila serangan dikesan:
#   rg-backup pin --before "2026-11-12T19:29:27+08:00"
cmd_pin() {
  need_root
  local before="" reason="modul-B" sid
  while [ $# -gt 0 ]; do
    case "$1" in
      --before) before="$2"; shift 2;;
      --reason) reason="$2"; shift 2;;
      *) echo "Pilihan tidak dikenali: $1" >&2; exit 2;;
    esac
  done
  mkdir -p "$STATE"
  # Bekukan SEGERA supaya backup berjadual dan rotation tidak jalan lagi
  echo "snapshot=PENDING" > "$PIN_FILE"
  lock -w 300   # tunggu backup yang sedang jalan siap
  sid=$(restic snapshots --json | python3 -c "$PY_PICK" "$before")
  if [ -z "$sid" ]; then
    echo "snapshot=NONE" > "$PIN_FILE"
    log "RALAT: tiada snapshot sebelum '${before:-sekarang}'. Backup kekal beku."
    exit 1
  fi
  # Nota: JANGAN guna "restic tag" di sini. Ia cipta snapshot baharu dengan ID baharu,
  # jadi ID dalam PIN_FILE jadi lapuk. Perlindungan datang daripada pembekuan:
  # semasa PIN_FILE wujud, tiada backup dan tiada forget/prune dijalankan.
  { echo "snapshot=$sid"; echo "pinned_at=$(date -Is)"; echo "before=$before"; echo "reason=$reason"; } > "$PIN_FILE"
  log "PIN: snapshot $sid dilindungi (sebelum '${before:-sekarang}', sebab=$reason). Backup dibekukan."
  echo "$sid"
}

cmd_unpin() {
  need_root; lock
  rm -f "$PIN_FILE"
  log "UNPIN: backup berjadual disambung semula."
}

cmd_list() { need_root; restic snapshots; }

cmd_status() {
  need_root
  if [ -f "$PIN_FILE" ]; then echo "== STATUS: BEKU =="; cat "$PIN_FILE"; else echo "== STATUS: aktif =="; fi
  echo; restic snapshots --compact || true
  echo; [ -f "$METRICS" ] && tail -n 5 "$METRICS" || true
}

cmd_verify() {
  need_root; lock
  if [ "${1:-}" = "--full" ]; then restic check --read-data; else restic check --read-data-subset=10%; fi
}

# restore [--snapshot ID|latest|pinned] [--user cikgu1] [--to DIR] [--apply]
#  tanpa --apply : restore ke folder staging + sahkan hash (selamat, tak ubah Nextcloud)
#  dengan --apply: tampal ke Nextcloud (fail pengguna sahaja kalau --user, jika tidak fail + DB)
cmd_restore() {
  need_root; lock
  local snap="" user="" to="" apply=0 stage sd mf n
  while [ $# -gt 0 ]; do
    case "$1" in
      --snapshot) snap="$2"; shift 2;;
      --user) user="$2"; shift 2;;
      --to) to="$2"; shift 2;;
      --apply) apply=1; shift;;
      *) echo "Pilihan tidak dikenali: $1" >&2; exit 2;;
    esac
  done
  if [ -z "$snap" ] || [ "$snap" = "pinned" ]; then
    if [ -f "$PIN_FILE" ] && grep -q '^snapshot=[0-9a-f]' "$PIN_FILE"; then
      snap=$(sed -n 's/^snapshot=//p' "$PIN_FILE")
    else
      snap=latest
    fi
  fi
  stage="${to:-$BASE/restore-$(date +%Y%m%d-%H%M%S)}"
  mkdir -p "$stage"
  log "Restore snapshot=$snap user=${user:-SEMUA} ke $stage"

  if [ -n "$user" ]; then
    restic restore "$snap" --target "$stage" --include "$DATA/$user" --include "$STATE/manifest.sha256" >/dev/null
  else
    restic restore "$snap" --target "$stage" >/dev/null
  fi
  sd="$stage$DATA"; mf="$stage$STATE/manifest.sha256"
  [ -f "$mf" ] || { log "RALAT: manifest tiada dalam snapshot"; return 1; }

  # Sahkan SHA-256 fail yang dipulihkan
  if [ -n "$user" ]; then grep -F "  ./$user/" "$mf" > "$stage/manifest.part" || true
  else cp "$mf" "$stage/manifest.part"; fi
  n=$(wc -l < "$stage/manifest.part")
  if (cd "$sd" && sha256sum -c --quiet "$stage/manifest.part"); then
    log "SAHKAN: $n fail, semua hash SHA-256 sepadan."
  else
    log "RALAT: ada hash tidak sepadan. Restore dihentikan."; return 1
  fi

  if [ "$apply" -eq 0 ]; then
    echo "Staging siap di $stage. Guna --apply untuk tampal ke Nextcloud."
    return 0
  fi

  maint_on; trap 'maint_off' EXIT
  if [ -n "$user" ]; then
    rsync -a --delete "$sd/$user/" "$DATA/$user/"
  else
    rsync -a --delete --exclude nextcloud.log --exclude 'appdata_*/preview' "$sd/" "$DATA/"
    [ -s "$stage$STATE/db.sql" ] || { log "RALAT: db.sql tiada dalam snapshot"; return 1; }
    dc exec -T db sh -c 'mariadb -u root -p"$MARIADB_ROOT_PASSWORD" nextcloud' < "$stage$STATE/db.sql"
  fi
  maint_off; trap - EXIT
  occ maintenance:data-fingerprint >/dev/null || true
  if [ -n "$user" ]; then occ files:scan "$user" >/dev/null; else occ files:scan --all >/dev/null; fi
  log "APPLY siap. Jalankan 'rg-backup unpin' bila ancaman sudah diatasi."
}

cmd_install_timer() {
  need_root
  if [ "$(readlink -f "$0")" != /usr/local/sbin/rg-backup ]; then
    install -m 750 "$(readlink -f "$0")" /usr/local/sbin/rg-backup
  fi
  cat > /etc/systemd/system/rg-backup.service <<EOF
[Unit]
Description=RansomGuard Pi - backup Nextcloud (Modul A)
After=docker.service

[Service]
Type=oneshot
Environment=RG_NC_DIR=$NC_DIR
ExecStart=/usr/local/sbin/rg-backup backup auto
EOF
  cat > /etc/systemd/system/rg-backup.timer <<'EOF'
[Unit]
Description=Jadual backup RansomGuard Pi (setiap jam)

[Timer]
OnCalendar=hourly
Persistent=true
RandomizedDelaySec=60

[Install]
WantedBy=timers.target
EOF
  systemctl daemon-reload
  systemctl enable --now rg-backup.timer
  log "Timer dipasang: backup setiap jam."
}

usage() {
  cat <<'EOF'
rg-backup - RansomGuard Pi, Modul A
  init                         sediakan repo restic (sekali sahaja)
  backup [tag]                 snapshot baharu (fail + DB + manifest SHA-256)
  list                         senarai snapshot
  status                       status beku/aktif + metrik terkini
  verify [--full]              semak integriti repo (lalai: 10% data)
  pin [--before MASA]          lindungi snapshot bersih terakhir + bekukan backup (untuk Modul B)
  unpin                        sambung semula backup berjadual
  restore [--snapshot ID|latest|pinned] [--user NAMA] [--to DIR] [--apply]
  install-timer                pasang systemd timer (setiap jam)
EOF
}

case "${1:-help}" in
  init) cmd_init;;
  backup) shift; cmd_backup "$@";;
  pin) shift; cmd_pin "$@";;
  unpin) cmd_unpin;;
  list) cmd_list;;
  status) cmd_status;;
  verify) shift; cmd_verify "$@";;
  restore) shift; cmd_restore "$@";;
  install-timer) cmd_install_timer;;
  *) usage;;
esac
