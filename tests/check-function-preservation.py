from pathlib import Path
from html.parser import HTMLParser
import hashlib,json,re,subprocess

root=Path(__file__).resolve().parent.parent
baseline=json.loads((root/'tests/function-baseline.json').read_text(encoding='utf-8'))
palette={'#2fa98c':'#34c759','#e0a04c':'#ff9500','#e0708a':'#ff3b30','#5b8fd6':'#007aff','#4a9fd8':'#007aff','#8f7ec9':'#5856d6'}
def normalized_script(text):
    for a,b in palette.items(): text=text.replace(a,b)
    return re.sub(r'^\s*//.*$','',text,flags=re.M).replace('\r\n','\n').strip()
for name,digest in baseline['runtime_files'].items():
    assert hashlib.sha256((root/name).read_bytes()).hexdigest()==digest, f'Runtime changed: {name}'
for name,digest in baseline['scripts'].items():
    html=(root/name).read_text(encoding='utf-8')
    js='\n'.join(re.findall(r'<script>(.*?)</script>',html,re.S))
    assert hashlib.sha256(normalized_script(js).encode()).hexdigest()==digest, f'Browser behavior changed: {name}'
    class Controls(HTMLParser):
        def __init__(self): super().__init__();self.ids=[];self.inputs=[];self.buttons=[]
        def handle_starttag(self,tag,attrs):
            d=dict(attrs)
            if 'id' in d:self.ids.append(d['id'])
            if tag=='input':self.inputs.append({k:v for k,v in d.items() if k!='aria-label'})
            if tag=='button':self.buttons.append(d)
    new=Controls();new.feed(html);old=baseline['controls'][name]
    assert old['ids']==sorted(new.ids),f'Control IDs changed: {name}'
    assert old['inputs']==new.inputs and old['buttons']==new.buttons,f'Inputs/actions changed: {name}'
    assert 'class="blob' not in html and 'Water Garden' not in html
    assert 'prefers-color-scheme' not in html and 'color-scheme: light;' in html
print('Preservation passed: 7 runtime/config files byte-identical; browser logic, IDs, inputs and actions unchanged except equivalent palette literals.')
