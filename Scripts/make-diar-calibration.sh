#!/bin/bash
# Build a synthetic multi-speaker calibration clip: three distinct macOS TTS
# voices interleaved in turns with silence between, plus an mp3 round-trip
# version to mimic the real meeting capture path.
set -euo pipefail
cd "${1:-$(pwd)}"
rm -rf seg plan.txt && mkdir -p seg

LINES=("The quarterly numbers came in above expectations, and the board approved the expansion plan."
       "We need to rethink how the warehouse handles returns before the holiday peak hits us hard."
       "I tried the new routing experiment last night and the latency dropped by nearly forty percent.")
VOICES=(Daniel Fred Shelly)

for round in 0 1; do
  for v in 0 1 2; do
    f="seg/v${v}_${round}"
    say -v "${VOICES[$v]}" -r 165 -o "${f}.aiff" "${LINES[$v]}"
    ffmpeg -hide_banner -v error -y -i "${f}.aiff" -ar 16000 -ac 1 -c:a pcm_f32le "${f}.wav"
    printf '%s %s\n' "${f}.wav" "${v}" >> plan.txt
  done
done

python3 - <<'EOF'
import numpy as np, struct, json, subprocess

def readwav(p):
    raw=open(p,'rb').read(); pos=12; ch=sr=0; data=None
    while pos+8<=len(raw):
        cid=raw[pos:pos+4]; sz=struct.unpack("<I",raw[pos+4:pos+8])[0]
        if cid==b"fmt ": _,ch,sr=struct.unpack("<HHI",raw[pos+8:pos+16])
        elif cid==b"data": data=raw[pos+8:pos+8+sz]
        pos+=8+sz+(sz&1)
    x=np.frombuffer(data,dtype="<f4").reshape(-1,ch)
    return (x[:,0] if ch==1 else x.mean(1)), sr

plan=[l.split() for l in open("plan.txt").read().split("\n") if l.strip()]
parts=[]; meta=[]; sil=int(0.45*16000); t=0.0
for path, spk in plan:
    s,_=readwav(path)
    s=s/(np.max(np.abs(s))+1e-9)*0.62
    meta.append(dict(start=round(t,3), end=round(t+len(s)/16000,3), speaker=int(spk)))
    parts.append(s); t+=len(s)/16000.0
    parts.append(np.zeros(sil,dtype=np.float32)); t+=sil/16000.0
audio=np.concatenate(parts)

def write_wav(p, s):
    d=s.astype("<f4").tobytes()
    hdr=b"RIFF"+struct.pack("<I",36+len(d))+b"WAVEfmt "+struct.pack("<IHHIIHH",16,3,1,16000,16000*4,4,32)+b"data"+struct.pack("<I",len(d))
    open(p,"wb").write(hdr+d)

write_wav("synth3.wav", audio)
json.dump(meta, open("synth3.json","w"), indent=1)
subprocess.run("ffmpeg -hide_banner -v error -y -i synth3.wav -codec:a libmp3lame -b:a 256k synth3.mp3", shell=True, check=True)
subprocess.run("ffmpeg -hide_banner -v error -y -i synth3.mp3 -ar 16000 -ac 1 -c:a pcm_f32le synth3_mp3.wav", shell=True, check=True)
print("wrote synth3.wav %.1fs / %d turns / 3 speakers"%(len(audio)/16000, len(meta)))
EOF
