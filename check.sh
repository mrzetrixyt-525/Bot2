#!/usr/bin/env bash
set -Eeuo pipefail
IFS=$'\n\t'
umask 077

# Release/source integrity tests + host readiness report for the seven-file RGNODES bundle.
SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
APP_DIR="${RGNODES_APP_DIR:-$SCRIPT_DIR}"
MODE="${1:-all}"
PASS=0; WARN=0; FAIL=0
pass(){ printf '[PASS] %s\n' "$*"; PASS=$((PASS+1)); }
warn(){ printf '[WARN] %s\n' "$*"; WARN=$((WARN+1)); }
fail(){ printf '[FAIL] %s\n' "$*" >&2; FAIL=$((FAIL+1)); }
info(){ printf '[INFO] %s\n' "$*"; }

case "$MODE" in all|--static|--host) ;; *) printf 'Usage: bash check.sh [--static|--host]\n' >&2; exit 2;; esac
for f in .env bot.py requirements.txt setup.sh check.sh node.sh ecosystem.config.js; do
  if [[ -s "$APP_DIR/$f" ]]; then pass "Required bundle file exists: $f"; else fail "Required bundle file missing/empty: $APP_DIR/$f"; fi
done
for f in setup.sh check.sh node.sh; do
  if bash -n "$APP_DIR/$f"; then pass "Shell syntax: $f"; else fail "Shell syntax: $f"; fi
done
if command -v node >/dev/null 2>&1; then
  if node --check "$APP_DIR/ecosystem.config.js" >/dev/null 2>&1; then pass 'JavaScript syntax: ecosystem.config.js'; else fail 'JavaScript syntax: ecosystem.config.js'; fi
else warn 'Node.js is unavailable; ecosystem.config.js syntax check skipped.'; fi
if [[ -f "$APP_DIR/.env" ]]; then
  mode="$(stat -c '%a' "$APP_DIR/.env" 2>/dev/null || echo unknown)"
  [[ "$mode" == 600 ]] && pass '.env permissions are 0600' || warn ".env mode is $mode; run chmod 600 '$APP_DIR/.env'."
fi

TMP_DIR="$(mktemp -d /tmp/rgnodes-compact-check.XXXXXX)"
cleanup(){ rm -rf -- "$TMP_DIR"; }
trap cleanup EXIT
mkdir -p "$TMP_DIR/tests"
if python3 - "$APP_DIR/bot.py" "$APP_DIR/node.sh" "$TMP_DIR" <<'PYSTATIC'
import ast,base64,hashlib,re,sys,zlib,subprocess
from pathlib import Path
bot_path,node_path,tmp=Path(sys.argv[1]),Path(sys.argv[2]),Path(sys.argv[3])
bot=bot_path.read_text(encoding='utf-8'); node=node_path.read_text(encoding='utf-8')
tree=ast.parse(bot,filename='bot.py')

def payload(source, payload_pattern, hash_pattern, name, flags=0):
    pm=re.search(payload_pattern,source,flags); hm=re.search(hash_pattern,source,flags)
    if not pm or not hm: raise SystemExit(f'[FAIL] {name} embedded payload/hash not found')
    encoded=pm.group(2) if name=='KVM controller' else pm.group(1)
    raw=zlib.decompress(base64.b64decode(encoded,validate=True))
    actual=hashlib.sha256(raw).hexdigest()
    if actual != hm.group(1): raise SystemExit(f'[FAIL] {name} SHA-256 mismatch: {actual}')
    ast.parse(raw.decode('utf-8'),filename=name)
    print(f'[PASS] {name}: embedded bytes/hash/syntax verified ({actual})')
    return raw
controller=payload(bot,r"_EMBEDDED_VPSCTL_ZLIB_B64\s*=\s*(['\"])(.*?)\1",r"_EMBEDDED_VPSCTL_SHA256\s*=\s*['\"]([0-9a-f]{64})['\"]",'KVM controller',re.S)
agent=payload(node,r"^NODE_AGENT_ZLIB_B64='([^']+)'$",r"^NODE_AGENT_SHA256='([0-9a-f]{64})'$",'Remote node agent',re.M)
node_controller=payload(node,r"^VPSCTL_ZLIB_B64='([^']+)'$",r"^VPSCTL_SHA256='([0-9a-f]{64})'$",'Node KVM controller',re.M)
if controller != node_controller: raise SystemExit('[FAIL] bot.py and node.sh carry different KVM controllers')
print('[PASS] Main and remote-node controllers are byte-for-byte identical')
text=controller.decode('utf-8')
if not all(x in text for x in ('KVM/QEMU/libvirt only','def compat(','virsh','is_real_public_ipv4','allocate_public_ipv4')):
    raise SystemExit('[FAIL] KVM/public-IP safety markers missing from embedded controller')
if not all(x in agent.decode('utf-8') for x in ('X-API-Key','hmac.compare_digest','def build_vpsctl_argv','ThreadingHTTPServer')):
    raise SystemExit('[FAIL] Remote agent authentication/allowlist markers missing')
if not all(x in node for x in ('KVM_NETWORK_MODE','PUBLIC_PARENT_INTERFACE','PUBLIC_BRIDGE_NAME','REAL_PUBLIC_IPV4_REQUIRED','PUBLIC_IPV4_POOL_CIDR','PUBLIC_IPV4_GATEWAY','PUBLIC_IPV4_DNS','RGNODES_VPS_ROOT')):
    raise SystemExit('[FAIL] Remote installer does not set/retain complete KVM network configuration')
if 'if key in forced: value=forced[key]' not in node and 'if key in forced: value=forced[key]' not in node.replace('\\n','\n'):
    raise SystemExit('[FAIL] Remote installer no longer enforces credentials or preserves defaults safely')
print('[PASS] KVM, public-IP, API-key authentication, command allowlist and network defaults present')
functions={n.name for n in ast.walk(tree) if isinstance(n,(ast.FunctionDef,ast.AsyncFunctionDef))}
required={'init_db','create_port_forward','remove_port_forward','recreate_port_forwards','ensure_docker_ready','get_sshx_session_info','get_pinggy_session_info','apply_guest_motd','build_rgnodes_motd_profile_script','deploy_command','resize_vps','send_progress','_find_kvm_vpsctl'}
missing=required-functions
if missing: raise SystemExit('[FAIL] Critical bot functions missing: '+', '.join(sorted(missing)))
print('[PASS] Required DB, VPS, port, tunnel, access, deployment and embedded-controller functions present')
# Exercise the pure MOTD builder without importing/running the Discord bot. Include hostile
# shell metacharacters to prove user-configured text is base64-encoded, not executed.
fn=next((n for n in tree.body if isinstance(n,ast.FunctionDef) and n.name=='build_rgnodes_motd_profile_script'),None)
if fn is None: raise SystemExit('[FAIL] Safe MOTD script builder is missing')
mod=ast.Module(body=[fn],type_ignores=[])
ns={'base64':base64}
exec(compile(mod,'bot.py#motd-builder','exec'),ns)
probe="Welcome $(touch /tmp/rgnodes-motd-injection) ' ; `id`"
profile=ns['build_rgnodes_motd_profile_script'](probe)
expected=base64.b64encode(probe.encode()).decode()
if f"CUSTOM_MOTD_B64='{expected}'" not in profile or probe in profile:
    raise SystemExit('[FAIL] MOTD custom text is not safely encoded')
if any(x in profile for x in ('/etc/pam.d/','sed -i','chmod -x /etc/update-motd.d','rm -f /etc/motd','systemctl restart ssh')):
    raise SystemExit('[FAIL] Embedded MOTD installer contains PAM/SSH/distro-MOTD destructive changes')
motd_file=tmp/'motd-profile.sh'; motd_file.write_text(profile,encoding='utf-8')
syntax=subprocess.run(['sh','-n',str(motd_file)],capture_output=True,text=True)
if syntax.returncode: raise SystemExit('[FAIL] Embedded MOTD profile shell syntax: '+syntax.stderr[-500:])
env_config=(bot_path.parent/'.env').read_text(encoding='utf-8')
if 'AUTO_MOTD_INSTALLER=true' not in env_config or 'AUTO_MOTD_INSTALLER' not in bot:
    raise SystemExit('[FAIL] Automatic MOTD installer default/config is missing')
print('[PASS] Safe MOTD installer: POSIX syntax, hostile-text encoding, no PAM/SSH mutation, auto enabled')
# Exercise Pinggy endpoint parsing against ANSI-wrapped and malformed provider output.
regex_nodes=[]
for n in tree.body:
    if isinstance(n,ast.Assign) and any(isinstance(t,ast.Name) and t.id in {'ANSI_RE','PINGGY_ENDPOINT_RE'} for t in n.targets):
        regex_nodes.append(n)
parser=next((n for n in tree.body if isinstance(n,ast.FunctionDef) and n.name=='parse_pinggy_endpoint'),None)
if parser is None or len(regex_nodes)!=2: raise SystemExit('[FAIL] Pinggy endpoint parser or regex definitions missing')
from typing import Optional as _Optional
parser_ns={'re':re,'Optional':_Optional}
exec(compile(ast.Module(body=regex_nodes+[parser],type_ignores=[]),'bot.py#pinggy-parser','exec'),parser_ns)
parse=parser_ns['parse_pinggy_endpoint']
if parse('\x1b[31mForwarding TCP: tcp://abc123.a.pinggy.link:443\x1b[0m') != ('abc123.a.pinggy.link',443,'tcp://abc123.a.pinggy.link:443'):
    raise SystemExit('[FAIL] Pinggy ANSI endpoint parser regression')
if parse('Your TCP URL is tcp://x.pinggy.io:2022') != ('x.pinggy.io',2022,'tcp://x.pinggy.io:2022'):
    raise SystemExit('[FAIL] Pinggy provider-format parser regression')
if parse('https://foo.pinggy.link:65536') != (None,None,None):
    raise SystemExit('[FAIL] Pinggy parser accepted an out-of-range TCP port')
print('[PASS] Pinggy parser: ANSI stripping, TCP URL formats, port-range validation')
# Detect duplicate prefixed command names/aliases before discord.py registers them.
registered={}
for n in ast.walk(tree):
    if not isinstance(n,(ast.FunctionDef,ast.AsyncFunctionDef)): continue
    for dec in n.decorator_list:
        if not isinstance(dec,ast.Call): continue
        fn=dec.func
        if not (isinstance(fn,ast.Attribute) and fn.attr in {'command','hybrid_command'} and isinstance(fn.value,ast.Name) and fn.value.id=='bot'): continue
        kws={k.arg:k.value for k in dec.keywords if k.arg}
        name=kws.get('name')
        name=name.value if isinstance(name,ast.Constant) and isinstance(name.value,str) else n.name
        aliases=[]
        a=kws.get('aliases')
        if isinstance(a,(ast.List,ast.Tuple)):
            aliases=[v.value for v in a.elts if isinstance(v,ast.Constant) and isinstance(v.value,str)]
        for key in [name,*aliases]:
            normalized=key.casefold()
            previous=registered.get(normalized)
            if previous and previous != n.name: raise SystemExit(f'[FAIL] Duplicate command/alias {key!r}: {previous} and {n.name}')
            registered[normalized]=n.name
print(f'[PASS] No duplicate prefix command names/aliases ({len(registered)} registered)')
# Confirm progress edits a normal public message, not the ephemeral interaction original response.
if 'await progress_message.edit(embed=embed, view=None' not in bot or 'await interaction.edit_original_response(embed=embed)' in bot or 'await self.ctx.send(embed=creating_embed' not in bot:
    raise SystemExit('[FAIL] Deployment progress is not configured as a persistent public message')
if 'HOST_MOTD=bash <(' in (bot_path.parent/'.env').read_text(encoding='utf-8'):
    raise SystemExit('[FAIL] Unsafe remote-shell command remains as default guest MOTD')
if any(marker in bot for marker in ('**Generated API Key:**', '**Current API Key:**', 'sudo bash node.sh --api-key={api_key}', 'add_field(success_embed, "New API Key"')):
    raise SystemExit('[FAIL] A remote-node API key appears to be posted into a public channel/command')
if 'send_private_node_setup' not in functions or '--prompt-api-key' not in node:
    raise SystemExit('[FAIL] Private node-key delivery or hidden rotation prompt is missing')
# Execute the exact env-writer embedded in node.sh against a temporary config: secrets must be
# enforced, custom bridge/pool settings preserved, empty uplink auto-filled, duplicates removed.
start=node.index('# Atomically write credentials and fill missing network defaults')
writer=re.search(r'''python3 - "\$ENV_FILE" "\$API_KEY" "\$HOST" "\$PORT" "\$CONTROLLER" "\$UPLINK" <<'PYENV'\n(.*?)\nPYENV''',node[start:],re.S)
if not writer: raise SystemExit('[FAIL] Remote node environment writer could not be extracted for testing')
envtest=tmp/'node-agent.env'
envtest.write_text('# preserve this comment\nRGNODES_NODE_API_KEY=old-key\nKVM_NETWORK_MODE=bridge\nPUBLIC_PARENT_INTERFACE=\nPUBLIC_BRIDGE_NAME=br-public\nPUBLIC_IPV4_POOL_CIDR=198.51.100.0/29\nPUBLIC_IPV4_GATEWAY=198.51.100.1\nKVM_NETWORK_MODE=direct\n',encoding='utf-8')
cp=subprocess.run([sys.executable,'-',str(envtest),'a'*64,'127.0.0.1','18443','/usr/local/sbin/vpsctl','ens3'],input=writer.group(1),text=True,capture_output=True)
if cp.returncode: raise SystemExit('[FAIL] Remote env-writer execution failed: '+cp.stderr[-500:])
envtext=envtest.read_text(encoding='utf-8')
for marker in ('RGNODES_NODE_API_KEY='+'a'*64,'KVM_NETWORK_MODE=bridge','PUBLIC_PARENT_INTERFACE=ens3','PUBLIC_BRIDGE_NAME=br-public','PUBLIC_IPV4_POOL_CIDR=198.51.100.0/29','PUBLIC_IPV4_GATEWAY=198.51.100.1'):
    if marker not in envtext: raise SystemExit('[FAIL] Remote env-writer lost required setting '+marker.split('=',1)[0])
if envtext.count('KVM_NETWORK_MODE=')!=1 or (envtest.stat().st_mode & 0o777)!=0o600:
    raise SystemExit('[FAIL] Remote env-writer failed duplicate cleanup or mode-0600 protection')
print('[PASS] Remote env writer: credentials enforced, custom network preserved, defaults filled, file mode 0600')
print('[PASS] Deployment progress is persistent; node API keys are DM-only and terminal input can be hidden')
(tmp/'vpsctl.py').write_bytes(controller)
(tmp/'node-agent.py').write_bytes(agent)
PYSTATIC
then pass 'Python, embedded payload, command, and progress static checks'; else fail 'Python/embedded payload static checks'; fi

# The controller regression suite is embedded here to keep release ZIP contents to exactly seven files.
cat > "$TMP_DIR/tests/test_vpsctl.py" <<'PYTEST'
"""Host-independent regression tests for the embedded KVM controller/node agent."""
from __future__ import annotations
import os, importlib.util, shutil, sys, tempfile, unittest
from pathlib import Path
from types import SimpleNamespace
from unittest.mock import patch
ROOT_TMP=tempfile.TemporaryDirectory(prefix='rgnodes-vpsctl-tests-')
os.environ['RGNODES_VPS_ROOT']=str(Path(ROOT_TMP.name)/'state')
os.environ['KVM_NETWORK_MODE']='direct'; os.environ['PUBLIC_BRIDGE_NAME']=''; os.environ['PUBLIC_PARENT_INTERFACE']=''
os.environ['PUBLIC_IPV4_POOL_CIDR']=''; os.environ['PUBLIC_IPV4_GATEWAY']=''; os.environ['REAL_PUBLIC_IPV4_REQUIRED']='true'
sys.path.insert(0,str(Path(__file__).resolve().parents[1]))
import vpsctl
spec=importlib.util.spec_from_file_location('rgnodes_node_agent',Path(__file__).resolve().parents[1]/'node-agent.py')
assert spec and spec.loader
node_agent=importlib.util.module_from_spec(spec); spec.loader.exec_module(node_agent)
class VpsCtlTests(unittest.TestCase):
 def setUp(self):
  for path in (vpsctl.IMAGE_DIR,vpsctl.DISK_DIR,vpsctl.SEED_DIR,vpsctl.SECRET_DIR,vpsctl.META_DIR):
   shutil.rmtree(path,ignore_errors=True); path.mkdir(parents=True,exist_ok=True)
 def test_public_ipv4_validator_accepts_global_and_rejects_special_ranges(self):
  self.assertTrue(vpsctl.is_real_public_ipv4('1.1.1.1')); self.assertTrue(vpsctl.is_real_public_ipv4('8.8.8.8'))
  self.assertFalse(node_agent.is_global_unicast('224.0.0.1',4)); self.assertFalse(node_agent.is_global_unicast('ff02::1',6))
  self.assertTrue(node_agent.is_global_unicast('2001:4860:4860::8888',6))
  for a in ('10.1.2.3','192.168.1.2','127.0.0.1','198.51.100.1','203.0.113.1','224.0.0.1','bad-ip',''):
   with self.subTest(address=a): self.assertFalse(vpsctl.is_real_public_ipv4(a))
 def test_public_pool_rejects_private_and_documentation_ranges(self):
  for cidr,gateway in (('192.168.20.0/24','192.168.20.1'),('203.0.113.0/24','203.0.113.1'),('100.64.0.0/24','100.64.0.1')):
   with self.subTest(cidr=cidr),patch.object(vpsctl,'PUBLIC_POOL',cidr),patch.object(vpsctl,'PUBLIC_GATEWAY',gateway),patch.object(vpsctl,'REAL_PUBLIC_REQUIRED',True):
    with self.assertRaisesRegex(RuntimeError,'globally routable'): vpsctl.public_pool_ready()
 def test_public_pool_validation_does_not_materialize_all_hosts(self):
  with patch.object(vpsctl,'PUBLIC_POOL','11.0.0.0/8'),patch.object(vpsctl,'PUBLIC_GATEWAY','11.0.0.1'),patch.object(vpsctl,'REAL_PUBLIC_REQUIRED',True): self.assertTrue(vpsctl.public_pool_ready())
 def test_allocator_skips_gateway_and_previously_reserved_addresses(self):
  with patch.object(vpsctl,'PUBLIC_POOL','8.8.8.0/29'),patch.object(vpsctl,'PUBLIC_GATEWAY','8.8.8.1'):
   (vpsctl.META_DIR/'existing.json').write_text('{"name":"existing","public_ipv4":"8.8.8.2"}',encoding='utf-8')
   self.assertEqual(vpsctl.allocate_public_ipv4('new-vm'),'8.8.8.3')
 def test_seed_iso_is_rebuilt_after_retry(self):
  marker={'value':b'A'}
  def fake_run(argv,**_kwargs):
   if argv[0]=='openssl': return SimpleNamespace(stdout='fake-password-hash\n',returncode=0,stderr='')
   if argv[0]=='cloud-localds': Path(argv[-3]).write_bytes(marker['value']*2048); return SimpleNamespace(stdout='',returncode=0,stderr='')
   raise AssertionError(f'Unexpected command in unit test: {argv[0]}')
  def which(command): return '/usr/bin/cloud-localds' if command=='cloud-localds' else None
  with patch.object(vpsctl,'run',side_effect=fake_run),patch.object(vpsctl.shutil,'which',side_effect=which):
   iso=vpsctl.write_seed('retry-vm','password-one','retry-vm','52:54:00:00:00:01'); self.assertEqual(iso.read_bytes(),b'A'*2048)
   marker['value']=b'B'; second=vpsctl.write_seed('retry-vm','password-two','retry-vm','52:54:00:00:00:02')
   self.assertEqual(second,iso); self.assertEqual(iso.read_bytes(),b'B'*2048); self.assertFalse(list(iso.parent.glob('.seed-*.iso')))
 def test_remote_agent_accepts_only_allowlisted_kvm_controller_command(self):
  controller=Path(ROOT_TMP.name)/'vpsctl'; controller.write_text('#!/usr/bin/env python3\n# KVM/QEMU/libvirt only\ndef compat(command): pass\n# virsh controller marker\n',encoding='utf-8'); controller.chmod(0o755)
  with patch.dict(os.environ,{'RGNODES_VPSCTL_PATH':str(controller)}):
   command=f"{controller} compat 'status test-vm'"; self.assertEqual(node_agent.build_vpsctl_argv(command),[str(controller),'compat','status test-vm'])
   with self.assertRaisesRegex(ValueError,'only approved'): node_agent.build_vpsctl_argv("/bin/sh -c 'id'")
   with self.assertRaisesRegex(ValueError,'only approved'): node_agent.build_vpsctl_argv(f"{controller} compat 'status test-vm' ; id")
   controller.chmod(0o775)
   with self.assertRaisesRegex(ValueError,'group/world writable'): node_agent.build_vpsctl_argv(command)
 def test_create_refuses_orphan_disk_without_deleting_user_data(self):
  orphan=vpsctl.DISK_DIR/'orphan-vm.qcow2'; orphan.write_bytes(b'preserve-user-data')
  with patch.object(vpsctl,'ensure_kvm_ready'),patch.object(vpsctl,'ensure_dirs'),patch.object(vpsctl,'ensure_network'),patch.object(vpsctl,'domain_exists',return_value=False),patch.object(vpsctl,'host_capacity_ok') as capacity,patch.object(vpsctl,'download_image') as download:
   with self.assertRaisesRegex(RuntimeError,'orphaned VPS artifact'): vpsctl.create('orphan-vm','ubuntu:24.04',1,1,max(vpsctl.MIN_DISK,10),password='unit-test-password',start=False)
  self.assertEqual(orphan.read_bytes(),b'preserve-user-data'); capacity.assert_not_called(); download.assert_not_called()
 def test_create_rolls_back_disk_seed_and_secret_when_domain_definition_fails(self):
  base=vpsctl.IMAGE_DIR/'fake-base.img'; base.write_bytes(b'base-image')
  def fake_run(argv,**_kwargs):
   if argv[:2]==['qemu-img','info']: return SimpleNamespace(stdout='',returncode=1,stderr='not a qcow image')
   if argv[:2]==['qemu-img','create']: Path(argv[-2]).write_bytes(b'partial-disk'); return SimpleNamespace(stdout='',returncode=0,stderr='')
   if argv[:2] in (['virsh','destroy'],['virsh','undefine']): return SimpleNamespace(stdout='',returncode=0,stderr='')
   raise AssertionError(f'Unexpected command in unit test: {argv[:2]}')
  def fake_seed(name,*_args):
   seed_dir=vpsctl.SEED_DIR/name; seed_dir.mkdir(parents=True,exist_ok=True); iso=seed_dir/'seed.iso'; iso.write_bytes(b'test-seed'); return iso
  with patch.object(vpsctl,'ensure_kvm_ready'),patch.object(vpsctl,'ensure_dirs'),patch.object(vpsctl,'ensure_network'),patch.object(vpsctl,'domain_exists',return_value=False),patch.object(vpsctl,'host_capacity_ok'),patch.object(vpsctl,'download_image',return_value=base),patch.object(vpsctl,'run',side_effect=fake_run),patch.object(vpsctl,'write_seed',side_effect=fake_seed),patch.object(vpsctl,'define_domain',side_effect=RuntimeError('simulated define failure')):
   with self.assertRaisesRegex(RuntimeError,'simulated define failure'): vpsctl.create('rollback-test','ubuntu:24.04',1,1,max(vpsctl.MIN_DISK,10),password='unit-test-password',start=False)
  self.assertFalse((vpsctl.DISK_DIR/'rollback-test.qcow2').exists()); self.assertFalse(vpsctl.secret_path('rollback-test').exists()); self.assertFalse(vpsctl.meta_path('rollback-test').exists()); self.assertFalse((vpsctl.SEED_DIR/'rollback-test').exists())
if __name__=='__main__': unittest.main(verbosity=2)
PYTEST
if [[ "$MODE" != "--host" ]]; then
  export RGNODES_VPS_ROOT="$TMP_DIR/state"
  if python3 -m unittest discover -s "$TMP_DIR/tests" -v; then pass 'Embedded-controller regression tests'; else fail 'Embedded-controller regression tests'; fi
fi

if [[ "$MODE" != "--static" ]]; then
  for bin in virsh qemu-img sshpass ssh curl; do command -v "$bin" >/dev/null 2>&1 && pass "Host command available: $bin" || warn "Host command missing: $bin"; done
  [[ -e /dev/kvm ]] && pass '/dev/kvm exists' || warn '/dev/kvm missing: real KVM VPS deployment requires provider/nested virtualization.'
  if command -v virsh >/dev/null 2>&1 && virsh -c qemu:///system list --all >/dev/null 2>&1; then pass 'libvirt qemu:///system responds'; else warn 'libvirt qemu:///system is not ready.'; fi
  [[ -s "$APP_DIR/.env" ]] && pass '.env present' || fail '.env missing'
  if python3 - "$APP_DIR/.env" <<'PYENV'
import sys
from pathlib import Path
v={}
for line in Path(sys.argv[1]).read_text(encoding='utf-8',errors='replace').splitlines():
 s=line.strip()
 if s and not s.startswith('#') and '=' in s:
  k,x=s.split('=',1); v[k.strip()]=x.strip().strip('"').strip("'")
t=v.get('DISCORD_TOKEN','')
raise SystemExit(0 if len(t)>=50 and not any(c.isspace() for c in t) else 1)
PYENV
  then pass 'DISCORD_TOKEN appears configured (value not displayed)'; else warn 'DISCORD_TOKEN not configured; bot cannot login until .env is completed.'; fi
  info 'Provider-routed IPv4, guest boot, actual SSH reachability and external tunnels require a real configured node and cannot be proven by offline self-check.'
fi
printf '\nSummary: pass=%s warn=%s fail=%s\n' "$PASS" "$WARN" "$FAIL"
[[ $FAIL -eq 0 ]]
