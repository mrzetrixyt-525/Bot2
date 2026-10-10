#!/usr/bin/env bash
set -Eeuo pipefail
IFS=$'\n\t'
umask 077

if [[ "${1:-}" == '-h' || "${1:-}" == '--help' ]]; then
  printf 'Usage: sudo bash node.sh [--api-key KEY] [--prompt-api-key] [--port 18443] [--host 127.0.0.1]\n'
  exit 0
fi

# RGNODES™ compact remote-node installer. The node agent and KVM controller are
# embedded and SHA-256 verified; no sidecar source files are needed in the bundle.
NODE_AGENT_ZLIB_B64='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'
NODE_AGENT_SHA256='e020d85c4613b20db9d459124c25cad01cdb65c152e6510bad441264b0514896'
VPSCTL_ZLIB_B64='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'
VPSCTL_SHA256='6aca00fb5aa9503d2f129a9046319065ef0ca39b5404b859cdc6ff50fae334d2'

say() { printf '[RGNODES-NODE] %s\n' "$*"; }
die() { printf '[RGNODES-NODE] ERROR: %s\n' "$*" >&2; exit 1; }
[[ $EUID -eq 0 ]] || die 'Run as root: sudo bash node.sh --api-key=KEY --port=PORT'
command -v python3 >/dev/null 2>&1 || die 'Python 3 is required.'
python3 - <<'PYVER' || die 'Python 3.10 or newer is required.'
import sys
raise SystemExit(0 if sys.version_info >= (3,10) else 1)
PYVER

API_KEY=''
PORT='18443'
HOST=''
KEY_SUPPLIED=0
KEY_GENERATED=0
FORCE_PROMPT_KEY=0
while (($#)); do
  case "$1" in
    --api-key|--api_key) (($# >= 2)) || die "$1 requires a value"; API_KEY="$2"; KEY_SUPPLIED=1; shift 2;;
    --api-key=*) API_KEY="${1#*=}"; KEY_SUPPLIED=1; shift;;
    --api_key=*) API_KEY="${1#*=}"; KEY_SUPPLIED=1; shift;;
    --prompt-api-key) FORCE_PROMPT_KEY=1; shift;;
    --port) (($# >= 2)) || die '--port requires a value'; PORT="$2"; shift 2;;
    --port=*) PORT="${1#*=}"; shift;;
    --host) (($# >= 2)) || die '--host requires a value'; HOST="$2"; shift 2;;
    --host=*) HOST="${1#*=}"; shift;;
    -h|--help) printf 'Usage: sudo bash node.sh [--api-key KEY] [--prompt-api-key] [--port 18443] [--host 127.0.0.1]\n'; exit 0;;
    *) die "Unknown option: $1";;
  esac
done
[[ "$PORT" =~ ^[0-9]+$ ]] && ((PORT >= 1 && PORT <= 65535)) || die 'Port must be an integer from 1 to 65535.'

export DEBIAN_FRONTEND=noninteractive NEEDRESTART_MODE=a APT_LISTCHANGES_FRONTEND=none
command -v apt-get >/dev/null 2>&1 || die 'Debian/Ubuntu apt-get is required.'
say 'Installing KVM/QEMU/libvirt and node-agent runtime packages.'
apt-get update
apt-get install -y python3 ca-certificates curl iproute2 iputils-ping openssl \
  qemu-system-x86 qemu-utils libvirt-daemon-system libvirt-clients \
  cloud-image-utils openssh-server openssh-client sshpass acl ufw
for unit in libvirtd.service virtqemud.service virtlogd.service virtlockd.service; do
  systemctl enable --now "$unit" >/dev/null 2>&1 || true
done
command -v virsh >/dev/null 2>&1 || die 'virsh is unavailable after package installation.'
command -v qemu-img >/dev/null 2>&1 || die 'qemu-img is unavailable after package installation.'
[[ -e /dev/kvm ]] || die '/dev/kvm is missing. Enable hardware/nested virtualization at your VPS provider before using this node.'
virsh -c qemu:///system list --all >/dev/null 2>&1 || die 'libvirt qemu:///system did not become ready; inspect libvirtd/virtqemud.'

APP=/opt/rgnodes-node-agent
ENV_DIR=/etc/rgnodes
ENV_FILE="$ENV_DIR/node-agent.env"
CONTROLLER=/usr/local/sbin/vpsctl
UNIT=/etc/systemd/system/rgnodes-node-agent.service
install -d -m 0755 "$APP" "$ENV_DIR" /var/lib/rgnodes-vps/images /var/lib/rgnodes-vps/disks /var/lib/rgnodes-vps/seeds /var/lib/rgnodes-vps/meta /var/lib/rgnodes-vps/secrets
chmod 0700 /var/lib/rgnodes-vps /var/lib/rgnodes-vps/secrets

if (( FORCE_PROMPT_KEY )) && [[ ! -t 0 ]]; then
  die '--prompt-api-key requires an interactive terminal so the new secret can be entered without being echoed.'
fi
if (( FORCE_PROMPT_KEY )); then
  API_KEY=''
elif [[ -z "$API_KEY" ]]; then
  API_KEY="$(python3 - "$ENV_FILE" <<'PYKEY'
import sys
from pathlib import Path
p=Path(sys.argv[1])
if p.exists():
    for line in p.read_text(encoding='utf-8',errors='replace').splitlines():
        s=line.strip()
        if s and not s.startswith('#') and '=' in s:
            k,v=s.split('=',1)
            if k.strip()=='RGNODES_NODE_API_KEY':
                v=v.strip().strip('"').strip("'")
                if len(v)>=32: print(v); raise SystemExit(0)
print('')
PYKEY
)"
fi
if [[ -z "$API_KEY" && -t 0 ]]; then
  read -r -s -p 'Enter the node API key from the bot DM (input hidden): ' API_KEY
  printf '\n'
  [[ -z "$API_KEY" ]] || KEY_SUPPLIED=1
fi
if [[ -z "$API_KEY" ]]; then
  API_KEY="$(python3 -c 'import secrets; print(secrets.token_hex(32))')"
  KEY_GENERATED=1
fi
[[ ${#API_KEY} -ge 32 && "$API_KEY" != *[$'\r\n '$'\t']* ]] || die 'API key must be at least 32 non-whitespace characters.'

if [[ -z "$HOST" ]]; then
  HOST="$(python3 - "$ENV_FILE" <<'PYHOST'
import sys
from pathlib import Path
p=Path(sys.argv[1])
if p.exists():
    for line in p.read_text(encoding='utf-8',errors='replace').splitlines():
        s=line.strip()
        if s and not s.startswith('#') and '=' in s:
            k,v=s.split('=',1)
            if k.strip()=='RGNODES_AGENT_HOST': print(v.strip().strip('"').strip("'")); raise SystemExit(0)
print('127.0.0.1')
PYHOST
)"
fi
[[ "$HOST" =~ ^[A-Za-z0-9.:_-]+$ ]] || die 'Invalid bind host. Use 127.0.0.1, ::1, or an intentional interface address.'

# Decompress to private temporary files, check exact digests, then atomically install.
python3 - "$NODE_AGENT_ZLIB_B64" "$NODE_AGENT_SHA256" "$VPSCTL_ZLIB_B64" "$VPSCTL_SHA256" "$APP/node-agent.py" "$CONTROLLER" <<'PYEMBED'
import base64,hashlib,os,sys,tempfile,zlib
agent_b64,agent_hash,ctl_b64,ctl_hash,agent_out,ctl_out=sys.argv[1:]
for encoded,expected,target in ((agent_b64,agent_hash,agent_out),(ctl_b64,ctl_hash,ctl_out)):
    data=zlib.decompress(base64.b64decode(encoded,validate=True))
    if hashlib.sha256(data).hexdigest()!=expected:
        raise SystemExit(f'Embedded payload integrity check failed for {target}')
    if target.endswith('node-agent.py'):
        compile(data.decode('utf-8'),'node-agent.py','exec')
    else:
        text=data.decode('utf-8')
        compile(text,'vpsctl','exec')
        if not all(x in text for x in ('KVM/QEMU/libvirt only','def compat(','virsh')):
            raise SystemExit('Embedded controller is not the expected KVM controller')
    directory=os.path.dirname(target)
    fd,tmp=tempfile.mkstemp(prefix='.rgnodes-embed-',dir=directory)
    try:
        with os.fdopen(fd,'wb') as f: f.write(data); f.flush(); os.fsync(f.fileno())
        os.chmod(tmp,0o755); os.replace(tmp,target)
    finally:
        try: os.unlink(tmp)
        except FileNotFoundError: pass
print('Embedded node-agent and KVM controller hashes/syntax verified.')
PYEMBED

# Detect the provider uplink where possible; public IPv4 routing still depends on provider setup.
UPLINK="$(ip -4 route show default 2>/dev/null | awk '/^default/ {for(i=1;i<=NF;i++) if($i=="dev") {print $(i+1); exit}}' || true)"

# Atomically write credentials and fill missing network defaults without replacing custom settings.
python3 - "$ENV_FILE" "$API_KEY" "$HOST" "$PORT" "$CONTROLLER" "$UPLINK" <<'PYENV'
import os,sys,tempfile
from pathlib import Path
path=Path(sys.argv[1]); api_key,host,port,controller,uplink=sys.argv[2:]
forced={
    'RGNODES_NODE_API_KEY':api_key,
    'RGNODES_AGENT_HOST':host,
    'RGNODES_AGENT_PORT':port,
    'RGNODES_VPSCTL_PATH':controller,
}
defaults={
    'RGNODES_VPS_ROOT':'/var/lib/rgnodes-vps',
    'KVM_NETWORK_MODE':'direct',
    'PUBLIC_PARENT_INTERFACE':uplink.strip(),
    'PUBLIC_BRIDGE_NAME':'',
    'REAL_PUBLIC_IPV4_REQUIRED':'true',
    'PUBLIC_IPV4_POOL_CIDR':'',
    'PUBLIC_IPV4_GATEWAY':'',
    'PUBLIC_IPV4_DNS':'1.1.1.1,8.8.8.8',
}
existing=path.read_text(encoding='utf-8',errors='replace').splitlines() if path.exists() else []
out=[]; seen=set()
def unquote(value):
    value=value.strip()
    if len(value)>=2 and value[0]==value[-1] and value[0] in '"\'': value=value[1:-1]
    return value
for line in existing:
    item=line.strip()
    if item and not item.startswith('#') and '=' in item:
        key,value=item.split('=',1); key=key.strip()
        if key in forced or key in defaults:
            if key in seen: continue
            seen.add(key)
            if key in forced: value=forced[key]
            elif not unquote(value): value=defaults[key]
            else: value=unquote(value)
            out.append(f'{key}={value}')
            continue
    out.append(line)
for mapping in (forced,defaults):
    for key,value in mapping.items():
        if key not in seen: out.append(f'{key}={value}'); seen.add(key)
fd,tmp=tempfile.mkstemp(prefix='.node-agent-env-',dir=str(path.parent))
try:
    with os.fdopen(fd,'w',encoding='utf-8') as f: f.write('\n'.join(out)+'\n'); f.flush(); os.fsync(f.fileno())
    os.chmod(tmp,0o600); os.replace(tmp,path)
finally:
    try: os.unlink(tmp)
    except FileNotFoundError: pass
PYENV

cat > "$UNIT" <<EOF
[Unit]
Description=RGNODES Remote KVM VPS Node Agent
After=network-online.target
Wants=network-online.target

[Service]
Type=simple
User=root
Group=root
WorkingDirectory=$APP
EnvironmentFile=$ENV_FILE
Environment=PYTHONUNBUFFERED=1
ExecStart=/usr/bin/python3 $APP/node-agent.py
Restart=on-failure
RestartSec=3
StartLimitIntervalSec=300
StartLimitBurst=5
LimitNOFILE=65535
UMask=0077

[Install]
WantedBy=multi-user.target
EOF
chmod 0644 "$UNIT"
python3 -m py_compile "$APP/node-agent.py" "$CONTROLLER"
systemctl daemon-reload
systemctl enable --now rgnodes-node-agent.service
systemctl is-active --quiet rgnodes-node-agent.service || { journalctl -u rgnodes-node-agent.service -n 60 --no-pager || true; die 'node-agent service did not start'; }

# Do not auto-open firewall ports or bind publicly; plain HTTP is not safe on an exposed interface.
if [[ "$HOST" != '127.0.0.1' && "$HOST" != '::1' ]]; then
  say 'WARNING: the agent is bound to a non-loopback address. Restrict firewall access to a trusted VPN/TLS proxy; never expose plain HTTP to the Internet.'
fi
if (( KEY_GENERATED == 1 )); then
  printf '\nGenerated node API key (save it securely and enter the same key in the bot node settings):\n%s\n' "$API_KEY"
else
  say 'Node API key configured; secret is stored in /etc/rgnodes/node-agent.env with mode 0600.'
fi
say 'Remote KVM node agent is active. This host must have provider-routed public IPv4 if guests need direct public IPv4 addresses.'
