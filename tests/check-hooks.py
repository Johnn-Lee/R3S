from pathlib import Path
import os,re,subprocess,tempfile

root=Path(__file__).resolve().parent.parent
with tempfile.TemporaryDirectory() as d:
    temp=Path(d)
    fixtures=temp/'hw';fixtures.mkdir()
    (fixtures/'compatible').write_bytes(b'friendlyarm,nanopi-r3s\0rockchip,rk3566\0')
    (fixtures/'thermal_zone0').mkdir()
    (fixtures/'thermal_zone0/type').write_text('cpu-thermal\n')
    (fixtures/'thermal_zone0/temp').write_text('45000\n')
    (fixtures/'gpio').write_text(' gpio-6 (regulator-vcc5v0_usb) out hi\n')
    (fixtures/'driver').mkdir()
    for f in ['bind','unbind']:(fixtures/'driver'/f).touch()
    mocks=temp/'bin';mocks.mkdir()
    for cmd in ['id','uhttpd','uci','ubus','jsonfilter','ip','gpioset','wget','netstat','pidof']:
        script='#!/bin/sh\n'
        if cmd=='id':script+='echo 0\n'
        elif cmd=='jsonfilter':script+='echo 192.168.2.1\n'
        else:script+='exit 0\n'
        p=mocks/cmd;p.write_text(script);p.chmod(0o755)
    env=dict(os.environ,PATH=str(mocks)+':'+os.environ['PATH'])
    for name in ['r3s-monitor','usb-fan-control']:
        hooks=(root/name/'package-hooks.mk').read_text()
        bodies=dict(re.findall(r'define Package/[^/]+/(\w+)\n(.*?)endef',hooks,re.S))
        for event,body in bodies.items():
            p=temp/(name+'-'+event);p.write_text(body.replace('$$','$'))
            subprocess.run(['sh','-n',str(p)],check=True)
            subprocess.run(['sh',str(p)],env=dict(env,IPKG_INSTROOT=str(temp/'offline')),check=True)
        pre=bodies['preinst'].replace('$$','$')
        pre=pre.replace('/proc/device-tree/compatible',str(fixtures/'compatible'))
        pre=pre.replace('/sys/class/thermal/thermal_zone',str(fixtures/'thermal_zone'))
        pre=pre.replace('/sys/kernel/debug/gpio',str(fixtures/'gpio'))
        pre=pre.replace('/dev/gpiochip0','/dev/null')
        pre=pre.replace('/sys/bus/platform/drivers/reg-fixed-voltage',str(fixtures/'driver'))
        p=temp/'preflight';p.write_text(pre)
        subprocess.run(['sh',str(p)],env=env,check=True)
        (fixtures/'compatible').write_bytes(b'other-device\0')
        bad=subprocess.run(['sh',str(p)],env=env,capture_output=True)
        assert bad.returncode!=0 and 'NanoPi R3S' in bad.stderr.decode()
        (fixtures/'compatible').write_bytes(b'friendlyarm,nanopi-r3s\0')
        if name=='usb-fan-control':
            (fixtures/'gpio').write_text('gpio-6 (unrelated-device) out hi\n')
            bad=subprocess.run(['sh',str(p)],env=env,capture_output=True)
            assert bad.returncode!=0 and 'GPIO0_A6' in bad.stderr.decode()
    print('Package hooks passed: offline skips, R3S preflight, wrong-model and GPIO rejection.')
