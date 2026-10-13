#!/usr/bin/env bash
set -Eeuo pipefail
IFS=$'\n\t'
umask 077

# RGNODES™ compact installer. Uses .env as data (never `source`s it) and preserves runtime state.
# Remote-only mode installs KVM/QEMU on NODE - 1 via node.sh, not on the Discord control host.
SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
SOURCE_DIR="$(cd -- "${RGNODES_SOURCE_DIR:-$SCRIPT_DIR}" && pwd -P)"
APP_DIR="${RGNODES_APP_DIR:-/root/Bot2}"
SERVICE_NAME="${RGNODES_SERVICE_NAME:-bot.service}"
MODE="${1:-install}"
BANNER_SHOWN=0
CODE_FILES=(bot.py setup.sh check.sh node.sh requirements.txt ecosystem.config.js)
BUNDLE_FILES=(.env bot.py requirements.txt setup.sh check.sh node.sh ecosystem.config.js)

# Color is enabled only for interactive terminals; logs stay clean for systemd/CI.
if [[ -t 1 && -z "${NO_COLOR:-}" ]]; then
  RED=$'\033[0;31m'; GRN=$'\033[0;32m'; YEL=$'\033[1;33m'
  BLU=$'\033[0;34m'; MAG=$'\033[0;35m'; CYN=$'\033[0;36m'
  WHT=$'\033[1;37m'; DIM=$'\033[2m'; NC=$'\033[0m'
else
  RED=''; GRN=''; YEL=''; BLU=''; MAG=''; CYN=''; WHT=''; DIM=''; NC=''
fi

log(){ printf '%b[RGNODES™]%b %s\n' "$CYN" "$NC" "$*"; }
step(){ printf '%b[+]%b %s\n' "$GRN" "$NC" "$*"; }
warn(){ printf '%b[!]%b %s\n' "$YEL" "$NC" "$*" >&2; }
die(){ printf '%b[x]%b %s\n' "$RED" "$NC" "$*" >&2; exit 1; }

rainbow_line(){
  local text="$1" i color
  local -a colors=("$RED" "$YEL" "$GRN" "$CYN" "$BLU" "$MAG")
  if [[ -z "$NC" ]]; then printf '%s\n' "$text"; return; fi
  for ((i=0; i<${#text}; i++)); do
    color="${colors[$((i % ${#colors[@]}))]}"
    printf '%b%s%b' "$color" "${text:i:1}" "$NC"
  done
  printf '\n'
}

banner(){
  BANNER_SHOWN=1
  if [[ -t 1 && -n "${TERM:-}" && "$TERM" != dumb ]] && command -v clear >/dev/null 2>&1; then clear || true; fi
  printf '\n%b╔══════════════════════════════════════════════════════════════╗%b\n' "$CYN" "$NC"
  printf '%b║                                                              ║%b\n' "$CYN" "$NC"
  rainbow_line '                    >>> RGNODES™ <<<'
  printf '%b║                 VPS CONTROL PLATFORM                        ║%b\n' "$CYN" "$NC"
  printf '%b║                   Power By RGNODES™                         ║%b\n' "$CYN" "$NC"
  printf '%b║                                                              ║%b\n' "$CYN" "$NC"
  printf '%b╚══════════════════════════════════════════════════════════════╝%b\n' "$CYN" "$NC"
  printf '%b  KVM/QEMU • libvirt • Public IPv4 • SSH • Pinggy/SSHX%b\n' "$BLU" "$NC"
  printf '%b  Docker-in-guest • Auto MOTD • Discord dashboard • systemd%b\n' "$BLU" "$NC"
  printf '%b  Ubuntu/Debian auto-detect • Python venv • protected rollback%b\n\n' "$BLU" "$NC"
}

usage(){
  cat <<'USAGE'
Usage: sudo bash setup.sh [install|--code-only|--repair-controller|--check|--help]
  install      Install host dependencies, deploy/update the bot, and configure systemd.
  --code-only  Skip apt package installation; all host prerequisites must already exist.
  --repair-controller  Re-extract, hash-verify and atomically repair /usr/local/sbin/vpsctl only.
  --check      Run the bundle's static validation and regression tests without host changes.
  --help       Show this help.
USAGE
}

# No mode menu: `sudo bash setup.sh` automatically detects supported Debian/Ubuntu and runs full install.
if [[ $# -gt 1 ]]; then usage >&2; die 'Use at most one mode argument.'; fi
if [[ $# -eq 1 && "$MODE" == "--help" ]]; then banner; usage; exit 0; fi

if [[ "$MODE" == "--check" ]]; then
  [[ -s "$SOURCE_DIR/check.sh" ]] || die 'check.sh is missing.'
  exec bash "$SOURCE_DIR/check.sh" --static
fi
[[ "$MODE" == "install" || "$MODE" == "--code-only" || "$MODE" == "--repair-controller" ]] || { usage >&2; die "Unknown mode: $MODE"; }
if (( BANNER_SHOWN == 0 )); then banner; fi
[[ $EUID -eq 0 ]] || die 'Run as root: sudo bash setup.sh'
if [[ "$MODE" != "--repair-controller" ]]; then
  command -v systemctl >/dev/null 2>&1 || die 'systemd/systemctl is required. Generic CodeSandbox/container shells are not suitable for the KVM host installer.'
fi
if [[ "$MODE" == "install" ]]; then
  command -v apt-get >/dev/null 2>&1 || die 'apt-get is required; use --code-only only when system prerequisites are already installed.'
  [[ -r /etc/os-release ]] || die 'Cannot identify the operating system from /etc/os-release.'
  . /etc/os-release
  case "${ID:-}" in debian|ubuntu) ;; *) die "Supported OS is Debian/Ubuntu; detected ${PRETTY_NAME:-unknown}.";; esac
  log "Detected OS: ${PRETTY_NAME:-${ID:-unknown}}. Target backend: KVM/QEMU/libvirt."
fi
command -v python3 >/dev/null 2>&1 || die 'Python 3 is required.'
python3 - <<'PYVER' || die 'Python 3.10 or newer is required. Use Ubuntu 22.04+ or Debian 12+ (or install a supported Python first).'
import sys
raise SystemExit(0 if sys.version_info >= (3, 10) else 1)
PYVER

# Parse .env as data, never as shell code. Existing APP_DIR config wins over the bundled template.
CONFIG_ENV_FILE="$APP_DIR/.env"
if [[ ! -s "$CONFIG_ENV_FILE" ]]; then CONFIG_ENV_FILE="$SOURCE_DIR/.env"; fi
config_get(){
  local key="$1" file="${2:-$CONFIG_ENV_FILE}"
  [[ -s "$file" ]] || return 0
  python3 - "$file" "$key" <<'PYENVGET'
import sys
from pathlib import Path
path, wanted = sys.argv[1:]
try:
    lines = Path(path).read_text(encoding='utf-8', errors='replace').splitlines()
except OSError:
    raise SystemExit(0)
for line in lines:
    text = line.strip()
    if not text or text.startswith('#'):
        continue
    if text.startswith('export '):
        text = text[7:].lstrip()
    if '=' not in text:
        continue
    key, value = text.split('=', 1)
    if key.strip() != wanted:
        continue
    value = value.strip()
    if len(value) >= 2 and value[0] == value[-1] and value[0] in "\\\"'":
        value = value[1:-1]
    print(value)
    break
PYENVGET
}

ENV_STATE_ROOT="${RGNODES_VPS_ROOT:-$(config_get RGNODES_VPS_ROOT)}"
STATE_ROOT="${ENV_STATE_ROOT:-/var/lib/rgnodes-vps}"
ENV_DATA_DIR="${RGNODES_DATA_DIR:-$(config_get RGNODES_DATA_DIR)}"
DATA_DIR="${ENV_DATA_DIR:-$STATE_ROOT/data}"
BACKUP_ROOT="${RGNODES_BACKUP_ROOT:-/var/backups/rgnodes-vps}"
FAIL2BAN_JAIL_FILE="/etc/fail2ban/jail.d/99-rgnodes-sshd.local"

[[ "$APP_DIR" == /* ]] || die 'RGNODES_APP_DIR must resolve to an absolute path.'
[[ "$STATE_ROOT" == /* && "$DATA_DIR" == /* && "$BACKUP_ROOT" == /* ]] || die 'App, data and backup directories must be absolute paths.'
[[ "$APP_DIR" != *[[:space:]]* && "$STATE_ROOT" != *[[:space:]]* && "$DATA_DIR" != *[[:space:]]* && "$BACKUP_ROOT" != *[[:space:]]* ]] || die 'App/data/backup paths must not contain whitespace (systemd and guest tooling compatibility).'
[[ "$STATE_ROOT" != / && "$DATA_DIR" != / && "$BACKUP_ROOT" != / ]] || die 'Refusing to use the filesystem root as an application data/backup directory.'
[[ "$SERVICE_NAME" =~ ^[A-Za-z0-9_.@-]+\.service$ ]] || die 'RGNODES_SERVICE_NAME must be a simple systemd unit name ending in .service.'
for f in "${BUNDLE_FILES[@]}"; do [[ -s "$SOURCE_DIR/$f" ]] || die "Required bundle file is missing or empty: $f"; done

# Verify the compact bundle before any host mutation. Controller/agent source is embedded in
# bot.py and node.sh; it is not expected as a separate release file.
python3 - "$SOURCE_DIR/bot.py" "$SOURCE_DIR/node.sh" <<'PYVERIFY'
import ast,base64,hashlib,re,sys,zlib
from pathlib import Path
bot_path,node_path=map(Path,sys.argv[1:])
bot=bot_path.read_text(encoding='utf-8'); node=node_path.read_text(encoding='utf-8')
ast.parse(bot,filename='bot.py')
patterns={
 'controller':(r"_EMBEDDED_VPSCTL_ZLIB_B64\s*=\s*(['\"])(.*?)\1",r"_EMBEDDED_VPSCTL_SHA256\s*=\s*['\"]([0-9a-f]{64})['\"]",bot),
 'node agent':(r"^NODE_AGENT_ZLIB_B64='([^']+)'$",r"^NODE_AGENT_SHA256='([0-9a-f]{64})'$",node),
 'node controller':(r"^VPSCTL_ZLIB_B64='([^']+)'$",r"^VPSCTL_SHA256='([0-9a-f]{64})'$",node),
}
payloads={}
for name,(payload_re,hash_re,source) in patterns.items():
    flags=re.M|re.S if name=='controller' else re.M
    m=re.search(payload_re,source,flags); h=re.search(hash_re,source,flags)
    if not m or not h: raise SystemExit(f'{name}: embedded payload/hash missing')
    raw=zlib.decompress(base64.b64decode(m.group(2) if name=='controller' else m.group(1),validate=True))
    if hashlib.sha256(raw).hexdigest()!=h.group(1): raise SystemExit(f'{name}: embedded SHA-256 mismatch')
    ast.parse(raw.decode('utf-8'),filename=name)
    payloads[name]=raw
if payloads['controller'] != zlib.decompress(base64.b64decode(re.search(patterns['node controller'][0],node,re.M).group(1),validate=True)):
    raise SystemExit('bot.py and node.sh carry different KVM controllers')
if not all(s in payloads['controller'].decode() for s in ('KVM/QEMU/libvirt only','def compat(','virsh')):
    raise SystemExit('embedded controller markers mismatch')
if not all(s in payloads['node agent'].decode() for s in ('X-API-Key','def build_vpsctl_argv','ThreadingHTTPServer')):
    raise SystemExit('embedded node agent security/interface markers mismatch')
print('Bundle validation passed: bot.py, embedded KVM controller, node agent and hashes are consistent.')
PYVERIFY

# Dedicated controller repair path. This is useful when an older install or a directory/symlink
# at /usr/local/sbin/vpsctl prevents the bot from finding the trusted KVM controller. It does not
# reinstall packages, replace .env, or touch VM disks/database.
if [[ "$MODE" == "--repair-controller" ]]; then
  REPAIR_TARGET=/usr/local/sbin/vpsctl
  REPAIR_DIR="$(dirname -- "$REPAIR_TARGET")"
  REPAIR_STAMP="$(date +%Y%m%d-%H%M%S)-$$"
  REPAIR_TMP="$REPAIR_DIR/.vpsctl.rgnodes-repair-$REPAIR_STAMP"
  REPAIR_BACKUP=''
  install -d -m 0755 "$REPAIR_DIR"
  cleanup_repair(){ [[ -z "$REPAIR_TMP" || ! -e "$REPAIR_TMP" ]] || rm -f -- "$REPAIR_TMP"; }
  trap cleanup_repair EXIT
  python3 - "$SOURCE_DIR/bot.py" "$REPAIR_TMP" <<'PYREPAIR'
import base64, hashlib, os, re, sys, zlib
from pathlib import Path
bot_path, out_path = map(Path, sys.argv[1:])
s = bot_path.read_text(encoding='utf-8')
p = re.search(r"_EMBEDDED_VPSCTL_ZLIB_B64\s*=\s*(['\"])(.*?)\1", s, re.S)
h = re.search(r"_EMBEDDED_VPSCTL_SHA256\s*=\s*['\"]([0-9a-f]{64})['\"]", s)
if not p or not h:
    raise SystemExit('Embedded controller payload/hash is missing from bot.py; use a matching complete release ZIP.')
try:
    payload = zlib.decompress(base64.b64decode(p.group(2), validate=True))
except Exception as e:
    raise SystemExit(f'Embedded controller payload is corrupt: {type(e).__name__}')
if hashlib.sha256(payload).hexdigest() != h.group(1):
    raise SystemExit('Embedded controller SHA-256 does not match the bot release.')
text = payload.decode('utf-8')
if not all(marker in text for marker in ('KVM/QEMU/libvirt only', 'def compat(', 'virsh')):
    raise SystemExit('Controller payload does not match the required KVM backend.')
compile(text, str(out_path), 'exec')
out_path.write_bytes(payload)
os.chmod(out_path, 0o755)
print('Extracted controller SHA-256:', hashlib.sha256(payload).hexdigest())
PYREPAIR
  chown root:root "$REPAIR_TMP"
  chmod 0755 "$REPAIR_TMP"
  if [[ -e "$REPAIR_TARGET" || -L "$REPAIR_TARGET" ]]; then
    REPAIR_BACKUP="${REPAIR_TARGET}.legacy-${REPAIR_STAMP}"
    if [[ -e "$REPAIR_BACKUP" || -L "$REPAIR_BACKUP" ]]; then die "Refusing to overwrite existing backup path: $REPAIR_BACKUP"; fi
    mv -T -- "$REPAIR_TARGET" "$REPAIR_BACKUP" || die "Could not preserve the existing controller path: $REPAIR_TARGET"
  fi
  if ! mv -T -- "$REPAIR_TMP" "$REPAIR_TARGET"; then
    if [[ -n "$REPAIR_BACKUP" && ( -e "$REPAIR_BACKUP" || -L "$REPAIR_BACKUP" ) ]]; then mv -T -- "$REPAIR_BACKUP" "$REPAIR_TARGET" || true; fi
    die 'Could not atomically install the KVM controller; old path was restored where possible.'
  fi
  REPAIR_TMP=''
  if ! python3 - "$SOURCE_DIR/bot.py" "$REPAIR_TARGET" <<'PYVERIFYCTL'
import hashlib, os, re, sys
from pathlib import Path
bot_path, ctl_path = map(Path, sys.argv[1:])
s = bot_path.read_text(encoding='utf-8')
h = re.search(r"_EMBEDDED_VPSCTL_SHA256\s*=\s*['\"]([0-9a-f]{64})['\"]", s)
data = ctl_path.read_bytes()
text = data.decode('utf-8', errors='replace')
if not h or hashlib.sha256(data).hexdigest() != h.group(1): raise SystemExit('Installed controller SHA-256 mismatch.')
if not all(x in text for x in ('KVM/QEMU/libvirt only', 'def compat(', 'virsh')): raise SystemExit('Installed controller markers mismatch.')
if not os.access(ctl_path, os.X_OK): raise SystemExit('Installed controller is not executable.')
compile(data.decode('utf-8'), str(ctl_path), 'exec')
print('Installed controller verified:', ctl_path, hashlib.sha256(data).hexdigest())
PYVERIFYCTL
  then
    rm -f -- "$REPAIR_TARGET"
    if [[ -n "$REPAIR_BACKUP" && ( -e "$REPAIR_BACKUP" || -L "$REPAIR_BACKUP" ) ]]; then mv -T -- "$REPAIR_BACKUP" "$REPAIR_TARGET" || true; fi
    die 'Post-install controller verification failed; previous path restored where possible.'
  fi
  log "Hash-verified KVM controller repaired at $REPAIR_TARGET."
  [[ -z "$REPAIR_BACKUP" ]] || log "Previous controller preserved at $REPAIR_BACKUP."
  log 'Restart the bot with: systemctl restart bot'
  exit 0
fi

mkdir -p "$APP_DIR"
APP_DIR="$(cd -- "$APP_DIR" && pwd -P)"
ENV_FILE="$APP_DIR/.env"
STAMP="$(date +%Y%m%d-%H%M%S)"
install -d -m 0700 "$BACKUP_ROOT/source-snapshots" "$BACKUP_ROOT/db-snapshots" "$DATA_DIR"
chmod 0700 "$DATA_DIR"
BACKUP_DIR="$BACKUP_ROOT/source-snapshots/$STAMP"
install -d -m 0700 "$BACKUP_DIR"
STAGE_DIR="$(mktemp -d "$APP_DIR/.rgnodes-stage.XXXXXX")"
WAS_ACTIVE=0
WAS_ENABLED=0
ROLLBACK_ARMED=0
if systemctl is-active --quiet "$SERVICE_NAME" 2>/dev/null; then WAS_ACTIVE=1; fi
if systemctl is-enabled --quiet "$SERVICE_NAME" 2>/dev/null; then WAS_ENABLED=1; fi

restore_previous(){
  local f
  log 'Attempting source/unit/controller rollback from the external snapshot.'
  # Remove the new enablement link before restoring/removing its unit file.
  if (( WAS_ENABLED == 0 )); then systemctl disable "$SERVICE_NAME" >/dev/null 2>&1 || true; fi
  for f in "${CODE_FILES[@]}"; do
    if [[ -f "$BACKUP_DIR/$f" ]]; then cp -p -- "$BACKUP_DIR/$f" "$APP_DIR/.$f.rollback.$$" && mv -f -- "$APP_DIR/.$f.rollback.$$" "$APP_DIR/$f"
    elif [[ -f "$BACKUP_DIR/.absent-$f" ]]; then rm -f -- "$APP_DIR/$f"; fi
  done
  if [[ -f "$BACKUP_DIR/bot.service" ]]; then cp -p -- "$BACKUP_DIR/bot.service" "/etc/systemd/system/$SERVICE_NAME"
  elif [[ -f "$BACKUP_DIR/.absent-bot.service" ]]; then rm -f -- "/etc/systemd/system/$SERVICE_NAME"; fi
  if [[ -f "$BACKUP_DIR/vpsctl-bin" ]]; then install -m 0755 "$BACKUP_DIR/vpsctl-bin" /usr/local/sbin/vpsctl
  elif [[ -f "$BACKUP_DIR/.absent-vpsctl-bin" ]]; then rm -f /usr/local/sbin/vpsctl; fi
  if [[ -f "$BACKUP_DIR/fail2ban-sshd.local" ]]; then
    install -d -m 0755 "$(dirname "$FAIL2BAN_JAIL_FILE")"
    cp -p -- "$BACKUP_DIR/fail2ban-sshd.local" "$FAIL2BAN_JAIL_FILE"
  elif [[ -f "$BACKUP_DIR/.absent-fail2ban-sshd.local" ]]; then rm -f -- "$FAIL2BAN_JAIL_FILE"; fi
  if command -v fail2ban-client >/dev/null 2>&1 && systemctl is-active --quiet fail2ban 2>/dev/null; then
    fail2ban-client -t >/dev/null 2>&1 && systemctl restart fail2ban >/dev/null 2>&1 || true
  fi
  systemctl daemon-reload >/dev/null 2>&1 || true
  if (( WAS_ENABLED )); then systemctl enable "$SERVICE_NAME" >/dev/null 2>&1 || true; else systemctl disable "$SERVICE_NAME" >/dev/null 2>&1 || true; fi
  if (( WAS_ACTIVE )); then systemctl restart "$SERVICE_NAME" >/dev/null 2>&1 || true; fi
}
cleanup(){ rm -rf -- "$STAGE_DIR"; }
trap 'rc=$?; if (( rc != 0 && ROLLBACK_ARMED == 1 )); then restore_previous; fi; cleanup; if (( rc != 0 )); then warn "Setup failed (exit $rc). Snapshot: $BACKUP_DIR"; fi; exit "$rc"' EXIT

# Snapshot only code files and system controller/unit; .env and runtime VPS data are never replaced.
step 'Preparing a protected rollback snapshot (code/unit/controller only; VM data is preserved)...'
for f in "${CODE_FILES[@]}"; do
  if [[ -f "$APP_DIR/$f" ]]; then cp -p -- "$APP_DIR/$f" "$BACKUP_DIR/$f"; else : > "$BACKUP_DIR/.absent-$f"; fi
done
if [[ -f "/etc/systemd/system/$SERVICE_NAME" ]]; then cp -p "/etc/systemd/system/$SERVICE_NAME" "$BACKUP_DIR/bot.service"; else : > "$BACKUP_DIR/.absent-bot.service"; fi
if [[ -f /usr/local/sbin/vpsctl ]]; then cp -p /usr/local/sbin/vpsctl "$BACKUP_DIR/vpsctl-bin"; else : > "$BACKUP_DIR/.absent-vpsctl-bin"; fi
if [[ -f "$FAIL2BAN_JAIL_FILE" ]]; then cp -p -- "$FAIL2BAN_JAIL_FILE" "$BACKUP_DIR/fail2ban-sshd.local"; else : > "$BACKUP_DIR/.absent-fail2ban-sshd.local"; fi

# Preserve database using SQLite's online backup API; original DB/WAL/SHM stay in place.
LIVE_DB=''
if [[ -f "$DATA_DIR/vps.db" ]]; then LIVE_DB="$DATA_DIR/vps.db"; elif [[ -f "$APP_DIR/vps.db" ]]; then LIVE_DB="$APP_DIR/vps.db"; fi
if [[ -n "$LIVE_DB" ]]; then
  python3 - "$LIVE_DB" "$BACKUP_ROOT/db-snapshots/$STAMP-vps.db" <<'PYDB'
import os,sqlite3,sys
src,dst=sys.argv[1:]
s=sqlite3.connect(src,timeout=30)
try:
 d=sqlite3.connect(dst)
 try: s.backup(d)
 finally: d.close()
finally: s.close()
os.chmod(dst,0o600)
print('SQLite online backup created; source DB/WAL/SHM were not altered.')
PYDB
fi

if [[ "$SOURCE_DIR" != "$APP_DIR" && ! -f "$ENV_FILE" ]]; then
  cp -- "$SOURCE_DIR/.env" "$ENV_FILE"
fi
[[ -f "$ENV_FILE" ]] || die "No .env exists at $ENV_FILE. Restore the .env file from the seven-file bundle."
chmod 0600 "$ENV_FILE"
MOTD_CONFIG="$(config_get AUTO_MOTD_INSTALLER "$ENV_FILE")"
case "${MOTD_CONFIG,,}" in 0|false|no|off) log 'Guest MOTD installer is disabled by the existing .env setting AUTO_MOTD_INSTALLER.' ;; *) log 'Guest MOTD: auto-install is enabled by .env/default; RGNODES safe profile script is applied during VPS provisioning (no upstream curl|bash execution).' ;; esac
log "Using existing configuration: $ENV_FILE (it will not be replaced)."
log "Persistent VM state: $STATE_ROOT; bot data: $DATA_DIR."

# Small atomic key/value editor. It does not echo secret values into the setup log.
env_get(){ python3 - "$1" "$ENV_FILE" <<'PYGET'
import sys
key,path=sys.argv[1:]
try:
 for line in open(path,encoding='utf-8',errors='replace'):
  s=line.strip()
  if s and not s.startswith('#') and '=' in s:
   k,v=s.split('=',1)
   if k.strip()==key: print(v.strip().strip('"').strip("'")); break
except OSError: pass
PYGET
}
env_set(){ python3 - "$1" "$2" "$ENV_FILE" <<'PYSET'
import os,sys,tempfile
from pathlib import Path
key,value,path=sys.argv[1:]
p=Path(path); lines=p.read_text(encoding='utf-8',errors='replace').splitlines(); out=[]; seen=False
for line in lines:
 s=line.strip()
 if s and not s.startswith('#') and '=' in s and s.split('=',1)[0].strip()==key:
  if not seen: out.append(f'{key}={value}'); seen=True
 else: out.append(line)
if not seen: out.append(f'{key}={value}')
fd,tmp=tempfile.mkstemp(prefix='.env-rgnodes-',dir=str(p.parent))
try:
 with os.fdopen(fd,'w',encoding='utf-8') as f: f.write('\n'.join(out)+'\n'); f.flush(); os.fsync(f.fileno())
 os.chmod(tmp,0o600); os.replace(tmp,p)
finally:
 try: os.unlink(tmp)
 except FileNotFoundError: pass
PYSET
}
# Refresh release metadata only; keep the operator's token, IDs and feature settings intact.
env_set BOT_VERSION '15.3.5 Remote-only KVM Health Fixes'
# Apply requested remote-only routing and repair the old Pinggy server-port default in preserved configs.
env_set REMOTE_NODE_ONLY 'true'
[[ -n "$(env_get DEFAULT_NODE_ID)" ]] || env_set DEFAULT_NODE_ID '0'
env_set PINGGY_SSH_PORT '443'
env_set PINGGY_REMOTE_PORT '890'
[[ -n "$(env_get HOST_VCPU_OVERCOMMIT_RATIO)" ]] || env_set HOST_VCPU_OVERCOMMIT_RATIO '1.5'
[[ -n "$(env_get MAX_DEPLOY_RAM_SHARE)" ]] || env_set MAX_DEPLOY_RAM_SHARE '0.80'
[[ -n "$(env_get HOST_CPU_RESERVE)" ]] || env_set HOST_CPU_RESERVE '1'
[[ -n "$(env_get HOST_RAM_RESERVE_GB)" ]] || env_set HOST_RAM_RESERVE_GB '2'
[[ -n "$(env_get HOST_DISK_RESERVE_GB)" ]] || env_set HOST_DISK_RESERVE_GB '10'
[[ -n "$(env_get HOST_CPU_MAX_DEPLOY_PCT)" ]] || env_set HOST_CPU_MAX_DEPLOY_PCT '85'
[[ -n "$(env_get MIN_HOST_RAM_FREE_PCT_DEPLOY)" ]] || env_set MIN_HOST_RAM_FREE_PCT_DEPLOY '18'

# Interactive first run: token prompt is hidden. Non-interactive setup leaves blank keys unchanged.
if [[ -t 0 && -r /dev/tty ]]; then
  if [[ -z "$(env_get DISCORD_TOKEN)" ]]; then
    printf 'Paste DISCORD_TOKEN (hidden; Enter skips): ' >/dev/tty
    IFS= read -r -s INPUT_TOKEN </dev/tty || INPUT_TOKEN=''; printf '\n' >/dev/tty
    INPUT_TOKEN="${INPUT_TOKEN//[[:space:]]/}"
    [[ -z "$INPUT_TOKEN" ]] || env_set DISCORD_TOKEN "$INPUT_TOKEN"
    unset INPUT_TOKEN
  fi
  if [[ -z "$(env_get MAIN_ADMIN_ID)" ]]; then
    printf 'Enter MAIN_ADMIN_ID (numeric Discord user ID; Enter skips): ' >/dev/tty
    IFS= read -r INPUT_ADMIN </dev/tty || INPUT_ADMIN=''
    INPUT_ADMIN="${INPUT_ADMIN//[[:space:]]/}"
    if [[ "$INPUT_ADMIN" =~ ^[0-9]{15,22}$ ]]; then env_set MAIN_ADMIN_ID "$INPUT_ADMIN"; elif [[ -n "$INPUT_ADMIN" ]]; then warn 'MAIN_ADMIN_ID must be a 15-22 digit Discord ID; left blank.'; fi
    unset INPUT_ADMIN
  fi
fi

# Auto-detect a default-route NIC only; do not alter interfaces, routes, bridges or provider firewall.
if [[ -z "$(env_get PUBLIC_PARENT_INTERFACE)" && -z "$(env_get PUBLIC_BRIDGE_NAME)" && "$(env_get KVM_NETWORK_MODE)" != bridge ]]; then
  UPLINK="$(ip -4 route show default 2>/dev/null | awk '{for(i=1;i<=NF;i++) if($i=="dev"){print $(i+1); exit}}' || true)"
  if [[ -n "$UPLINK" ]]; then env_set PUBLIC_PARENT_INTERFACE "$UPLINK"; log "Detected uplink $UPLINK and saved it as PUBLIC_PARENT_INTERFACE."; else warn 'Public uplink not detected; set PUBLIC_PARENT_INTERFACE or configure a provider-created PUBLIC_BRIDGE_NAME.'; fi
fi
# Save the effective config after hidden token/admin prompts and safe uplink detection, so a
# first-install credential is actually present in the private backup. Never expose it in logs.
install -m 0600 "$ENV_FILE" "$DATA_DIR/env.backup"

# Install named packages only. In remote-only mode, KVM is installed on NODE - 1 by node.sh,
# not on the Discord bot's control VM; this avoids treating the control VM as an accidental node.
if [[ "$MODE" != "--code-only" ]]; then
  export DEBIAN_FRONTEND=noninteractive NEEDRESTART_MODE=a APT_LISTCHANGES_FRONTEND=none
  log "Installing runtime dependencies on ${PRETTY_NAME:-${ID:-Debian/Ubuntu}}; no host-wide upgrade or network rewrite will be performed."
  apt-get update
  apt-get install -y python3 python3-venv python3-pip python3-dev build-essential libffi-dev pkg-config \
    ca-certificates curl wget openssl sqlite3 acl sudo net-tools openssh-server openssh-client sshpass iproute2 \
    iputils-ping procps util-linux nftables dnsutils fail2ban python3-systemd
  if [[ "$(printf '%s' "$(env_get REMOTE_NODE_ONLY)" | tr '[:upper:]' '[:lower:]')" == true ]]; then
    log 'REMOTE_NODE_ONLY=true: skipping local KVM/libvirt packages. Run node.sh on NODE - 1 (Asia/Singapore) to install the virtualization stack.'
  else
    apt-get install -y cpu-checker qemu-kvm qemu-utils qemu-guest-agent \
      libvirt-daemon-system libvirt-clients libvirt-daemon-driver-qemu libvirt-daemon-config-network \
      cloud-image-utils genisoimage
  fi
fi

# Stage code outside the live paths and install Python dependencies into an isolated venv.
step 'Validating the release and preparing the isolated Python environment...'
for f in "${CODE_FILES[@]}"; do cp -- "$SOURCE_DIR/$f" "$STAGE_DIR/$f"; done
python3 - "$STAGE_DIR/bot.py" "$STAGE_DIR/vpsctl-bin" <<'PYCTL'
import base64,hashlib,os,re,sys,tempfile,zlib
from pathlib import Path
bot,out=map(Path,sys.argv[1:])
s=bot.read_text(encoding='utf-8')
p=re.search(r"""_EMBEDDED_VPSCTL_ZLIB_B64\s*=\s*(['"])(.*?)\1""",s,re.S)
h=re.search(r"""_EMBEDDED_VPSCTL_SHA256\s*=\s*['"]([0-9a-f]{64})['"]""",s)
if not p or not h: raise SystemExit('Embedded KVM controller/hash missing')
data=zlib.decompress(base64.b64decode(p.group(2),validate=True))
if hashlib.sha256(data).hexdigest()!=h.group(1): raise SystemExit('Embedded KVM controller checksum mismatch')
text=data.decode('utf-8'); compile(text,'vpsctl','exec')
if not all(x in text for x in ('KVM/QEMU/libvirt only','def compat(','virsh')): raise SystemExit('Unexpected controller payload')
out.write_bytes(data); os.chmod(out,0o755)
print('Embedded controller extracted and verified.')
PYCTL

if [[ ! -x "$APP_DIR/.venv/bin/python" ]]; then python3 -m venv "$APP_DIR/.venv"; fi
"$APP_DIR/.venv/bin/python" -m pip install --disable-pip-version-check --upgrade pip setuptools wheel
"$APP_DIR/.venv/bin/python" -m pip install --disable-pip-version-check -r "$STAGE_DIR/requirements.txt"
"$APP_DIR/.venv/bin/python" -m py_compile "$STAGE_DIR/bot.py"

# All inputs are validated and package installation is complete. From here, rollback is armed.
ROLLBACK_ARMED=1
FAIL2BAN_CONFIG_ENABLED="$(config_get HOST_FAIL2BAN_SSH_ENABLED "$ENV_FILE")"
case "${FAIL2BAN_CONFIG_ENABLED,,}" in ''|1|true|yes|on) FAIL2BAN_CONFIG_ENABLED=true;; *) FAIL2BAN_CONFIG_ENABLED=false;; esac
if [[ "$FAIL2BAN_CONFIG_ENABLED" == true ]]; then
  if command -v fail2ban-client >/dev/null 2>&1; then
    if [[ ! -e "$FAIL2BAN_JAIL_FILE" || "$(grep -Ec '^# Managed by RGNODES(™™|™) setup\.sh; SSH brute-force protection only\.$' "$FAIL2BAN_JAIL_FILE" 2>/dev/null || true)" == 1 ]]; then
      install -d -m 0755 "$(dirname "$FAIL2BAN_JAIL_FILE")"
      JAIL_TMP="$(mktemp "$(dirname "$FAIL2BAN_JAIL_FILE")/.rgnodes-sshd.XXXXXX")"
      cat > "$JAIL_TMP" <<'FAIL2BANJAIL'
# Managed by RGNODES™ setup.sh; SSH brute-force protection only.
[sshd]
enabled = true
backend = systemd
port = ssh
maxretry = 5
findtime = 10m
bantime = 1h
FAIL2BANJAIL
      chown root:root "$JAIL_TMP"; chmod 0644 "$JAIL_TMP"; mv -f -- "$JAIL_TMP" "$FAIL2BAN_JAIL_FILE"
      step 'Configured a bounded Fail2ban SSH jail (5 retries / 10-minute window / 1-hour ban).'
    else
      warn 'A non-RGNODES Fail2ban jail file already exists at the managed path; preserved it rather than overwriting custom policy.'
    fi
    if fail2ban-client -t >/dev/null 2>&1; then
      systemctl enable fail2ban >/dev/null
      systemctl restart fail2ban
      if fail2ban-client status sshd >/dev/null 2>&1; then
        step 'Fail2ban SSH jail is active; existing UFW/provider firewall and SSH authentication settings were not changed.'
      else
        warn 'Fail2ban service is active but the sshd jail is not confirmed. Review /etc/fail2ban and run fail2ban-client status.'
      fi
    else
      die 'Fail2ban configuration test failed; rollback will restore the previous jail configuration.'
    fi
  else
    warn 'Fail2ban is unavailable (most likely --code-only mode without the package). Install fail2ban to enable SSH brute-force protection.'
  fi
else
  log 'HOST_FAIL2BAN_SSH_ENABLED is disabled in .env; no Fail2ban policy was added.'
fi
if (( WAS_ACTIVE )); then log "Stopping $SERVICE_NAME for a source-safe update."; systemctl stop "$SERVICE_NAME"; fi
for f in "${CODE_FILES[@]}"; do
  chmod 0755 "$STAGE_DIR/$f" 2>/dev/null || true
  case "$f" in requirements.txt|ecosystem.config.js) chmod 0644 "$STAGE_DIR/$f";; esac
  chown root:root "$STAGE_DIR/$f"
  mv -f -- "$STAGE_DIR/$f" "$APP_DIR/$f"
done
# Setup is the only place that creates the controller executable; runtime data stays untouched.
install -d -m 0755 /usr/local/sbin
CTL_TMP="/usr/local/sbin/.vpsctl.rgnodes-$STAMP"
install -o root -g root -m 0755 "$STAGE_DIR/vpsctl-bin" "$CTL_TMP"
# A stale path might be a directory or symlink, not just an old regular file. Preserve such
# an object before replacing it; `mv -T` prevents silently moving the controller inside a dir.
if [[ -d /usr/local/sbin/vpsctl && ! -L /usr/local/sbin/vpsctl ]]; then
  mv -T -- /usr/local/sbin/vpsctl "/usr/local/sbin/vpsctl.legacy-dir-$STAMP" || die 'Could not preserve an unexpected directory at /usr/local/sbin/vpsctl.'
  warn "Preserved unexpected controller directory at /usr/local/sbin/vpsctl.legacy-dir-$STAMP."
fi
mv -fT -- "$CTL_TMP" /usr/local/sbin/vpsctl
python3 - "$APP_DIR/bot.py" /usr/local/sbin/vpsctl <<'PYPOSTCTL'
import hashlib, os, re, sys
from pathlib import Path
bot_path, ctl_path = map(Path, sys.argv[1:])
s = bot_path.read_text(encoding='utf-8')
h = re.search(r"_EMBEDDED_VPSCTL_SHA256\s*=\s*['"]([0-9a-f]{64})['"]", s)
data = ctl_path.read_bytes()
text = data.decode('utf-8', errors='replace')
if not h or hashlib.sha256(data).hexdigest() != h.group(1): raise SystemExit('Installed KVM controller hash does not match bot.py.')
if not all(x in text for x in ('KVM/QEMU/libvirt only', 'def compat(', 'virsh')): raise SystemExit('Installed KVM controller markers do not match.')
if not os.access(ctl_path, os.X_OK): raise SystemExit('Installed KVM controller is not executable.')
compile(data.decode('utf-8'), str(ctl_path), 'exec')
print('Installed controller verified:', ctl_path, hashlib.sha256(data).hexdigest())
PYPOSTCTL

install -d -m 0755 "$STATE_ROOT" "$STATE_ROOT/images" "$STATE_ROOT/disks" "$STATE_ROOT/seeds" "$STATE_ROOT/meta" "$STATE_ROOT/secrets" "$APP_DIR/db_backups" "$APP_DIR/vps_backups"
chmod 0700 "$STATE_ROOT/secrets"
if [[ "$(printf '%s' "$(env_get REMOTE_NODE_ONLY)" | tr '[:upper:]' '[:lower:]')" != true ]]; then
  QEMU_USER=''
  for candidate in libvirt-qemu qemu; do if id "$candidate" >/dev/null 2>&1; then QEMU_USER="$candidate"; break; fi; done
  if [[ -n "$QEMU_USER" ]] && command -v setfacl >/dev/null 2>&1; then
    setfacl -m "u:$QEMU_USER:rx" "$STATE_ROOT" 2>/dev/null || true
    for d in images disks seeds; do setfacl -m "u:$QEMU_USER:rwx" "$STATE_ROOT/$d" 2>/dev/null || true; find "$STATE_ROOT/$d" -type d -exec setfacl -m "d:u:$QEMU_USER:rwX" {} + 2>/dev/null || true; done
  else warn 'Automatic QEMU ACL setup unavailable; inspect /var/lib/rgnodes-vps permissions.'; fi
fi

mkdir -p /run/sshd
if command -v sshd >/dev/null 2>&1; then sshd -t || die 'Host sshd configuration test failed; provider SSH configuration was not overwritten.'; fi
if [[ "$(printf '%s' "$(env_get REMOTE_NODE_ONLY)" | tr '[:upper:]' '[:lower:]')" == true ]]; then
  systemctl enable ssh.service >/dev/null 2>&1 || true
  systemctl start ssh.service >/dev/null 2>&1 || true
  log 'Remote-only mode: local libvirt services were intentionally not enabled or started.'
else
  for unit in libvirtd.service virtqemud.service virtlogd.service virtlockd.service ssh.service; do systemctl enable "$unit" >/dev/null 2>&1 || true; systemctl start "$unit" >/dev/null 2>&1 || true; done
fi

UNIT_TMP="$(mktemp /etc/systemd/system/.${SERVICE_NAME}.XXXXXX)"
cat > "$UNIT_TMP" <<EOFUNIT
[Unit]
Description=RGNODES™ VPS Bot - Remote-node KVM/QEMU Controller
Wants=network-online.target
After=network-online.target

[Service]
Type=simple
User=root
Group=root
WorkingDirectory=$APP_DIR
Environment=HOME=/root
Environment=PYTHONUNBUFFERED=1
Environment=RGNODES_VPS_ROOT=$STATE_ROOT
EnvironmentFile=-$ENV_FILE
ExecStartPre=$APP_DIR/.venv/bin/python -m py_compile $APP_DIR/bot.py
ExecStart=$APP_DIR/.venv/bin/python -u $APP_DIR/bot.py
Restart=on-failure
RestartSec=8
StartLimitIntervalSec=300
StartLimitBurst=5
KillMode=control-group
TimeoutStartSec=180
TimeoutStopSec=60
LimitNOFILE=65535
TasksMax=infinity
UMask=0077

[Install]
WantedBy=multi-user.target
EOFUNIT
chown root:root "$UNIT_TMP"; chmod 0644 "$UNIT_TMP"; mv -f "$UNIT_TMP" "/etc/systemd/system/$SERVICE_NAME"
systemctl daemon-reload
systemctl enable "$SERVICE_NAME" >/dev/null

bash "$APP_DIR/check.sh" --static
TOKEN_READY="$(python3 - "$ENV_FILE" <<'PYTOKEN'
import sys
from pathlib import Path
values={}
for line in Path(sys.argv[1]).read_text(encoding='utf-8',errors='replace').splitlines():
 s=line.strip()
 if s and not s.startswith('#') and '=' in s:
  k,v=s.split('=',1); values[k.strip()]=v.strip().strip('"').strip("'")
t=values.get('DISCORD_TOKEN','')
bad={'','paste_your_discord_bot_token_here','your_discord_bot_token','your_bot_token','changeme','change_me'}
print('yes' if t.lower() not in bad and len(t)>=50 and not any(c.isspace() for c in t) else 'no')
PYTOKEN
)"
if [[ "$TOKEN_READY" != yes ]]; then
  systemctl disable --now "$SERVICE_NAME" >/dev/null 2>&1 || true
  warn "DISCORD_TOKEN is missing/placeholder. Bot service was not started; edit .env and run: systemctl enable --now $SERVICE_NAME"
else
  if (( WAS_ACTIVE )); then systemctl restart "$SERVICE_NAME"; else systemctl start "$SERVICE_NAME"; fi
  sleep 3
  if ! systemctl is-active --quiet "$SERVICE_NAME"; then journalctl -u "$SERVICE_NAME" -n 80 --no-pager || true; die "Service $SERVICE_NAME failed to start; rollback will be attempted."; fi
  log "Service $SERVICE_NAME is active."
fi

if [[ "$(printf '%s' "$(env_get REMOTE_NODE_ONLY)" | tr '[:upper:]' '[:lower:]')" != true ]]; then
  if [[ ! -e /dev/kvm ]]; then warn '/dev/kvm is missing: real local KVM VPS deployment requires provider/nested virtualization.'; fi
  if ! virsh -c qemu:///system list --all >/dev/null 2>&1; then warn 'libvirt qemu:///system is not ready; run sudo bash check.sh for diagnostics.'; fi
else
  log 'Control VM is remote-only. Verify the Singapore node using bot.py --self-check after `-node create` is complete.'
fi
ROLLBACK_ARMED=0
printf '\n%b════════════════════ INSTALLATION COMPLETE ════════════════════%b\n' "$GRN" "$NC"
log 'Power By RGNODES™ — setup completed. Existing .env, database, VM disks, metadata and backups were preserved.'
log "Service: systemctl status $SERVICE_NAME"
log "Logs: journalctl -u $SERVICE_NAME -f"
log "Restart: systemctl restart $SERVICE_NAME"
log "Config: $ENV_FILE (permissions 0600)"
log "Diagnostics: sudo bash $APP_DIR/check.sh"
if [[ ! -e /dev/kvm ]]; then warn 'The host bot may run, but actual VPS deployment remains unavailable until /dev/kvm and provider networking are enabled.'; fi
