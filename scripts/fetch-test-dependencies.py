from pathlib import Path
import gzip,hashlib,json,re,subprocess,sys,urllib.request

era,version,destination=sys.argv[1:4]
host_apk=sys.argv[4] if len(sys.argv)>4 else None
dest=Path(destination);dest.mkdir(parents=True,exist_ok=True)
wanted=re.compile(r'^(ip-tiny|gpiod-tools|libgpiod[0-9]*)$')
for feed in ('base','packages'):
    base=f'https://downloads.openwrt.org/releases/{version}/packages/x86_64/{feed}/'
    local=dest/feed;local.mkdir(exist_ok=True)
    filename='packages.adb' if era=='apk' else 'Packages.gz'
    urllib.request.urlretrieve(base+filename,local/filename)
    if era=='apk':
        data=json.loads(subprocess.check_output([host_apk,'adbdump','--format','json',str(local/filename)]))
        entries=data['packages']
    else:
        entries=[]
        for block in gzip.decompress((local/filename).read_bytes()).decode().split('\n\n'):
            fields=dict(line.split(': ',1) for line in block.splitlines() if ': ' in line and not line.startswith(' '))
            if 'Package' in fields:entries.append({'name':fields['Package'],'filename':fields.get('Filename'),'sha256':fields.get('SHA256sum')})
    for item in entries:
        if not wanted.fullmatch(item['name']):continue
        filename=f"{item['name']}-{item['version']}.apk" if era=='apk' else item['filename']
        target=local/Path(filename).name
        urllib.request.urlretrieve(base+filename.removeprefix('./'),target)
        if item.get('sha256'):assert hashlib.sha256(target.read_bytes()).hexdigest()==item['sha256']
        print('Test dependency:',target.name)
