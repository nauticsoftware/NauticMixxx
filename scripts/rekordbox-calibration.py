#!/usr/bin/env python3
"""Read-only calibration experiment. Train 01-06, freeze, then validate 07-09.

No audio, USB, library, or ANLZ is modified. numpy and Pillow are required.
ANLZ layouts: https://djl-analysis.deepsymmetry.org/rekordbox-export-analysis/anlz.html
"""
import argparse, hashlib, json, struct, wave
from pathlib import Path
import numpy as np

ANLZ=['P051/00019B31','P058/00014EBA','P04C/000144E0','P063/0001E01F','P00A/0000558E','P011/00004601','P03F/0002F3EF','P025/00003579','P036/0000E76C']
FIELDS=['blue_height','blue_whiteness','rgb_r','rgb_g','rgb_b','rgb_height','band_low','band_mid','band_high']

def sections(path):
    data=path.read_bytes()
    if data[:4]!=b'PMAI': raise ValueError(f'Not ANLZ: {path}')
    offset=struct.unpack_from('>I',data,4)[0];result={}
    while offset+12<=len(data):
        tag=data[offset:offset+4].decode('ascii');header,size=struct.unpack_from('>II',data,offset+4)
        if not 12<=header<=size or offset+size>len(data):raise ValueError(f'Invalid {tag}')
        result[tag]=(data[offset+header:offset+size],data[offset:offset+header]);offset+=size
    return result

def read_anlz(folder):
    tags={}
    for ext in ['DAT','EXT','2EX']: tags.update(sections(folder/f'ANLZ0000.{ext}'))
    blue=np.frombuffer(tags['PWV3'][0],np.uint8);rgb=np.frombuffer(tags['PWV5'][0],'>u2');band=np.frombuffer(tags['PWV7'][0],np.uint8).reshape(-1,3)
    if not len(blue)==len(rgb)==len(band):raise ValueError('Detailed lengths differ')
    y=np.column_stack((blue&31,blue>>5,(rgb>>13)&7,(rgb>>10)&7,(rgb>>7)&7,(rgb>>2)&31,band[:,0],band[:,1],band[:,2])).astype(float)
    return tags,y

def read_audio(path):
    with wave.open(str(path)) as w:
        rate=w.getframerate();channels=w.getnchannels();width=w.getsampwidth()
        if width!=2:raise ValueError('Calibration requires PCM16')
        a=np.frombuffer(w.readframes(w.getnframes()),'<i2').reshape(-1,channels).astype(float)/32768
    return a.mean(1),rate

def audio_features(a,rate,n):
    # Phase-sensitive local envelope plus a fixed spectral analysis at 150 Hz.
    hop=rate/150;idx=np.floor(np.arange(n+1)*hop).astype(int)
    padded=np.pad(a,(0,max(0,idx[-1]-len(a)+1)))
    env=np.zeros((n,3))
    for i in range(n):
        v=padded[idx[i]:idx[i+1]]
        if len(v):env[i]=np.max(np.abs(v)),np.sqrt(np.mean(v*v)),np.mean(np.abs(v))
    fft=4096;win=np.hanning(fft);pad=np.pad(a,(fft//2,fft//2+int(hop)*2));freq=np.fft.rfftfreq(fft,1/rate)
    edges=np.geomspace(10,rate/2,97);bands=np.clip(np.searchsorted(edges,freq)-1,0,95)
    spec=np.empty((n,96));norm=2/(fft*np.sum(win*win))
    for first in range(0,n,256):
        centers=np.floor(np.arange(first,min(first+256,n))*hop).astype(int)
        frames=pad[centers[:,None]+np.arange(fft)]*win
        power=np.abs(np.fft.rfft(frames,axis=1))**2*norm
        for j in range(len(centers)):spec[first+j]=np.bincount(bands,weights=power[j],minlength=96)
    env = np.column_stack((env, (env / max(float(np.max(np.abs(a))), 1e-12))**2))
    return env,spec,np.sqrt(edges[:-1]*edges[1:])

def metrics(pred,y):
    err=np.abs(pred-y)
    return {name:dict(mae=float(err[:,i].mean()),rmse=float(np.sqrt(np.mean(err[:,i]**2))),p95=float(np.percentile(err[:,i],95)),exact_fraction=float(np.mean(np.rint(pred[:,i])==y[:,i]))) for i,name in enumerate(FIELDS)}

def predict(env,spec,model):
    # Coefficients and quantization remain frozen during validation.
    en=np.column_stack((env,np.ones(len(env))))
    h=np.clip(en@np.array(model['height_weights']),0,31)
    fraction=spec/np.maximum(spec.sum(1,keepdims=True),1e-12)
    color=np.clip(fraction@np.array(model['color_weights']),0,7)
    linear=np.maximum(spec@np.array(model['band_weights']),0)
    band=255*np.power(linear,np.array(model['band_exponents'])/2)
    silence=spec.sum(1)<1e-10
    band[silence]=0;color[silence]=0;h[env[:,0]==0]=0
    return np.column_stack((h[:,0],color[:,0],color[:,1:4],h[:,1],np.clip(band,0,255)))

def main():
    ap=argparse.ArgumentParser();ap.add_argument('--usb',type=Path,default=Path('/Volumes/NAUTICBOY'));ap.add_argument('--manifest',type=Path);ap.add_argument('--output',type=Path,required=True);ap.add_argument('--model',type=Path);ap.add_argument('--audio',type=Path);args=ap.parse_args();args.output.mkdir(parents=True,exist_ok=True)
    if args.model and args.audio:
        a,rate=read_audio(args.audio);env,spec,_=audio_features(a,rate,int(np.ceil(len(a)/rate*150)));pred=predict(env,spec,json.loads(args.model.read_text()));np.savez_compressed(args.output/'analysis.npz',columns=pred,columns_per_second=150,fields=FIELDS);return
    if args.manifest is None:ap.error('--manifest is required for calibration')
    manifest=json.loads(args.manifest.read_text());files=list(manifest['files']);training=[];mapping=[];hashes=[]
    # Only 01-06 are read before model.json is finalized.
    for i,name in enumerate(files[:6]):
        path=args.usb/'Contents/UnknownArtist/UnknownAlbum'/name;tags,y=read_anlz(args.usb/'PIONEER/USBANLZ'/ANLZ[i]);a,rate=read_audio(path);env,spec,freq=audio_features(a,rate,len(y));training.append((env,spec,y))
        hashes.append(dict(file=name,audio_sha256=hashlib.sha256(path.read_bytes()).hexdigest(),anlz={ext:hashlib.sha256((args.usb/'PIONEER/USBANLZ'/ANLZ[i]/f'ANLZ0000.{ext}').read_bytes()).hexdigest() for ext in ['DAT','EXT','2EX']}))
        for seg in manifest['files'][name]['segments']:
            lo=int((seg['start_s']+.25)*150);hi=int((seg['end_s']-.25)*150)
            if 'freq_formula' in seg:
                for f in np.geomspace(25,18000,64):
                    t=seg['start_s']+np.log(f/20)/np.log(1000)*(seg['end_s']-seg['start_s']);j=int(t*150);v=np.median(y[max(lo,j-5):min(hi,j+6)],axis=0);mapping.append(dict(file=i+1,frequency_hz=float(f),level_dbfs=seg['level_dbfs_peak'],values=v.tolist()))
            else:mapping.append(dict(file=i+1,frequency_hz=seg['freq_hz'],level_dbfs=seg['level_dbfs'],values=np.median(y[lo:hi],axis=0).tolist()))
        print('training features',name,flush=True)
    exponents=[]
    for band,f in enumerate([60,1000,10000]):
        rows=[r for r in mapping if r['file']==6 and r['frequency_hz']==f and -30<=r['level_dbfs']<=-3 and r['values'][6+band]>2]
        x=np.array([r['level_dbfs'] for r in rows]);z=20*np.log10(np.array([r['values'][6+band]/255 for r in rows]));exponents.append(float(np.polyfit(x,z,1)[0]))
    env=np.concatenate([v[0] for v in training]);spec=np.concatenate([v[1] for v in training]);y=np.concatenate([v[2] for v in training]);en=np.column_stack((env,np.ones(len(env))))
    hw=np.linalg.lstsq(en,y[:,[0,5]],rcond=None)[0]
    frac=spec/np.maximum(spec.sum(1,keepdims=True),1e-12);cw=np.linalg.solve(frac.T@frac+np.eye(96)*.1,frac.T@y[:,[1,2,3,4]])
    target=np.power(y[:,6:]/255,2/np.array(exponents));gram=spec.T@spec;rhs=spec.T@target;ridge=np.trace(gram)/96*1e-5
    bw=np.maximum(np.linalg.solve(gram+np.eye(96)*ridge,rhs),0)
    # Projected least squares enforces nonnegative spectral energy responses.
    step=1/np.linalg.norm(gram+np.eye(96)*ridge,2)
    for _ in range(2000):bw=np.maximum(0,bw-step*((gram+np.eye(96)*ridge)@bw-rhs))
    model=dict(schema=1,columns_per_second=150,fft_size=4096,window='Hann centered',frequency_hz=freq.tolist(),height_weights=hw.tolist(),color_weights=cw.tolist(),band_weights=bw.tolist(),band_exponents=exponents,trained_files=files[:6],validation_files=files[6:],policy='No validation-driven tuning; experimental fallback, not Pioneer-equivalent')
    encoded=json.dumps(model,indent=2)+'\n';(args.output/'model.json').write_text(encoded);frozen=hashlib.sha256(encoded.encode()).hexdigest()
    (args.output/'measured-transfer.json').write_text(json.dumps(dict(fields=FIELDS,rows=mapping,input_hashes=hashes,manifest_sha256=hashlib.sha256(args.manifest.read_bytes()).hexdigest()),indent=2)+'\n')
    report=dict(frozen_model_sha256=frozen,units='PWV3/PWV5 height 0..31, whiteness/RGB 0..7, PWV7 bands 0..255',training={},validation={})
    for i,name in enumerate(files):
        if i<6:env,spec,y=training[i]
        else:
            _,y=read_anlz(args.usb/'PIONEER/USBANLZ'/ANLZ[i]);a,rate=read_audio(args.usb/'Contents/UnknownArtist/UnknownAlbum'/name);env,spec,_=audio_features(a,rate,len(y))
        pred=predict(env,spec,model);segments={}
        for seg in manifest['files'][name]['segments']:
            lo=int(seg['start_s']*150);hi=min(len(y),int(seg['end_s']*150));segments[seg['label']]=metrics(pred[lo:hi],y[lo:hi])
        report['training' if i<6 else 'validation'][name]=dict(columns=len(y),all_columns=metrics(pred,y),segments=segments)
        print('evaluated',name,flush=True)
    assert hashlib.sha256((args.output/'model.json').read_bytes()).hexdigest()==frozen
    (args.output/'column-validation.json').write_text(json.dumps(report,indent=2)+'\n')

if __name__=='__main__':main()
