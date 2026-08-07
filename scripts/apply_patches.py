import re, struct, sys, zipfile

URL_RE = re.compile(r'(?:https?://|stirlingpdf://)[^\s"\'<>`]+|(?:raw\.)?github\.com/[^\s"\'<>`]+|stirling-software\.com')
KEEP = ('X-Stirling-Tool-Report', 'hasStirling')
SENT = '\x00URL\x00'

def decode_mutf8(b):
    out=[]; i=0; n=len(b)
    while i<n:
        c=b[i]
        if c & 0x80 == 0:
            out.append(chr(c)); i+=1
        elif c & 0xE0 == 0xC0:
            out.append(chr(((c&0x1F)<<6)|(b[i+1]&0x3F))); i+=2
        elif c & 0xF0 == 0xE0:
            x=((c&0x0F)<<12)|((b[i+1]&0x3F)<<6)|(b[i+2]&0x3F); i+=3
            if 0xD800 <= x <= 0xDBFF:
                c2=b[i]; y=((c2&0x0F)<<12)|((b[i+1]&0x3F)<<6)|(b[i+2]&0x3F); i+=3
                x=0x10000+((x-0xD800)<<10)+(y-0xDC00)
            out.append(chr(x))
        elif c & 0xF8 == 0xF0:
            x=((c&0x07)<<18)|((b[i+1]&0x3F)<<12)|((b[i+2]&0x3F)<<6)|(b[i+3]&0x3F); i+=4
            out.append(chr(x))
        else:
            out.append('?'); i+=1
    return ''.join(out)

def encode_mutf8(s):
    out=bytearray()
    for ch in s:
        cp=ord(ch)
        if cp==0:
            out += b'\xc0\x80'
        elif cp < 0x80:
            out.append(cp)
        elif cp < 0x800:
            out += bytes([0xC0|(cp>>6), 0x80|(cp&0x3F)])
        elif cp < 0x10000:
            out += bytes([0xE0|(cp>>12), 0x80|((cp>>6)&0x3F), 0x80|(cp&0x3F)])
        else:
            cp -= 0x10000
            hi=0xD800+((cp>>10)&0x3FF); lo=0xDC00+(cp&0x3FF)
            for x in (hi,lo):
                out += bytes([0xE0|(x>>12), 0x80|((x>>6)&0x3F), 0x80|(x&0x3F)])
    return bytes(out)

def transform(s):
    s = s.replace('https://raw.githubusercontent.com/Stirling-Tools/Stirling-PDF/refs/heads/main/LICENSE', 'https://raw.githubusercontent.com/ActiveInAI/PanPDF/main/LICENSE')
    s = s.replace('https://raw.githubusercontent.com/Stirling-Tools/Stirling-PDF', 'https://raw.githubusercontent.com/ActiveInAI/PanPDF')
    s = s.replace('https://github.com/Stirling-Tools/Stirling-PDF', 'https://github.com/ActiveInAI/PanPDF')
    s = s.replace('https://github.com/Frooodle/Stirling-PDF', 'https://github.com/ActiveInAI')
    subs=[]
    def rep(m):
        subs.append(m.group(0)); return SENT
    s2=URL_RE.sub(rep, s)
    for k in KEEP:
        s2=s2.replace(k, SENT+k+SENT)
    s2=s2.replace('Stirling PDF', 'Pan PDF')
    s2=s2.replace('Stirling-PDF', 'Pan-PDF')
    s2=s2.replace('Stirling Software', 'Pan Software')
    s2=s2.replace('Stirling AI Comment', 'Pan AI Comment')
    s2=s2.replace('Stirling AI', 'Pan AI')
    s2=s2.replace('StirlingPDFLabel', 'PanPDFLabel')
    s2=re.sub(r'Stirling(?![A-Za-z-])', 'Pan', s2)
    for k in KEEP:
        s2=s2.replace(SENT+k+SENT, k)
    for i,u in enumerate(subs):
        s2=s2.replace(SENT, u, 1)
    return s2

def parse_cp(data, off):
    count=struct.unpack('>H', data[off:off+2])[0]; off+=2
    entries=[]; i=1
    while i<count:
        tag=data[off]; off+=1
        if tag==1:
            ln=struct.unpack('>H', data[off:off+2])[0]; off+=2
            raw=data[off:off+ln]; off+=ln
            entries.append((tag, raw))
        elif tag in (7,8,16,19,20):
            entries.append((tag, data[off:off+2])); off+=2
        elif tag in (9,10,11,12,17,18):
            entries.append((tag, data[off:off+4])); off+=4
        elif tag==15:
            entries.append((tag, data[off:off+3])); off+=3
        elif tag in (3,4):
            entries.append((tag, data[off:off+4])); off+=4
        elif tag in (5,6):
            entries.append((tag, data[off:off+8])); off+=8
            entries.append(None)
            i+=1
        else:
            raise ValueError(f'bad tag {tag} at idx {i}')
        i+=1
    return count, entries, off

def patch_class(data):
    magic=data[:4]; ver=data[4:8]; off=8
    count, entries, tail_off = parse_cp(data, off)
    tail=data[tail_off:]
    changed=False
    new_entries=[]
    for idx,item in enumerate(entries):
        if item is None:
            new_entries.append(None); continue
        tag,raw=item
        if idx==0:
            new_entries.append((tag,raw)); continue
        if tag is None:
            new_entries.append(None); continue
        if tag==1:
            s=decode_mutf8(raw)
            if 'Stirling' in s:
                t=transform(s)
                if t!=s:
                    raw=encode_mutf8(t); changed=True
        new_entries.append((tag,raw))
    if not changed:
        return data
    out=bytearray(magic); out+=ver
    out+=struct.pack('>H', count)
    for item in new_entries:
        if item is None:
            continue
        tag,raw=item
        out.append(tag)
        if tag==1:
            out+=struct.pack('>H', len(raw))
        out+=raw
    out+=tail
    return bytes(out)

def rewrite_jar(src, dst):
    zin=zipfile.ZipFile(src)
    with zipfile.ZipFile(dst,'w',zipfile.ZIP_DEFLATED) as zout:
        for item in zin.infolist():
            data=zin.read(item.filename)
            if item.filename.endswith('.class'):
                try:
                    nd=patch_class(data)
                except Exception as e:
                    print('FAIL', item.filename, e); raise
                if nd is not data:
                    print('  patched', item.filename)
                    data=nd
            zout.writestr(item, data)
    print('wrote', dst)

if __name__=='__main__':
    rewrite_jar(sys.argv[1], sys.argv[2])
