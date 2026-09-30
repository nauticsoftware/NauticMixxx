#!/usr/bin/env python3
"""Measure signed PCM geometry and within-column gradients on calibration PNG crops.
Only 01-05 references; never validation 07-09. Writes reproducible measurements.
"""
import argparse,json,wave
from pathlib import Path
import numpy as np
from PIL import Image

def pcm(path):
 with wave.open(str(path)) as w:
  assert w.getsampwidth()==2
  return np.frombuffer(w.readframes(w.getnframes()),'<i2').reshape(-1,w.getnchannels()).mean(1)/32768,w.getframerate()

def envelope(audio,rate,first,increment,width):
 bounds=np.clip(np.floor((first+np.arange(width+1)*increment)*rate).astype(int),0,len(audio)-1)
 # Source windows are contiguous and nonempty at the reference zoom.
 return np.minimum.reduceat(audio,bounds)[:width],np.maximum.reduceat(audio,bounds)[:width]

def main(a):
 jobs=json.loads((a.data/'registration.json').read_text())['jobs'];out=[]
 for job in jobs:
  stem=job['stem']
  if not stem.endswith('_detail') or '_3band_' in stem:continue
  idx=int(stem[:2]);mode=stem.split('_')[1];path=next(a.audio.glob(f'{idx:02d}_*.wav'));audio,rate=pcm(path)
  ref=np.array(Image.open(a.data/f'{stem}_reference.png'))[:,:,:3];mask=np.load(a.data/f'{stem}_mask.npy');h,w=ref.shape[:2]
  # Color discrimination excludes grey grid, red phrase rails, and black.
  sig=(ref[:,:,2]>100)&(ref[:,:,2]>ref[:,:,0]*1.2) if mode=='blue' else (ref[:,:,0]>90)&(ref[:,:,0]>ref[:,:,1]*2)&(ref[:,:,2]<30)
  sig &= ~mask;sig[88:]=False
  top=np.argmax(sig,axis=0);bot=h-1-np.argmax(sig[::-1],axis=0)
  valid=sig.sum(0)>2;valid[:80]=False;valid[900:]=False
  if valid.sum()<20:out.append(dict(stem=stem,reason='insufficient colored pixels'));continue
  increment=(job['last_second']-job['first_second'])/w
  # Signed geometry's phase gives a more precise registration than onset alone.
  best=None
  for sign in [1,-1]:
   for dt in np.arange(-.06,.0601,.00025):
    low,high=envelope(audio,rate,job['first_second']+dt,increment,w)
    if sign<0:low,high=-high,-low
    x=np.r_[-high[valid],-low[valid]];y=np.r_[top[valid],bot[valid]]
    mat=np.column_stack([np.ones(len(x)),x]);coeff=np.linalg.lstsq(mat,y,rcond=None)[0]
    err=float(np.mean(np.abs(mat@coeff-y)))
    if coeff[1]>0 and (best is None or err<best['boundary_mae_px']):best=dict(stem=stem,time_offset_s=float(dt),polarity=sign,center_y=float(coeff[0]),pixels_per_unit=float(coeff[1]),boundary_mae_px=err,columns=int(valid.sum()))
  # Measure gradient by position inside each colored column, not from eye.
  bins=[[] for _ in range(17)]
  for x in np.where(valid)[0]:
   for y in range(top[x],bot[x]+1):
    if sig[y,x]:
     t=(y-top[x])/max(1,bot[x]-top[x]);bins[min(16,int(round(t*16)))].append(ref[y,x])
  best['height_99th_percentile_px']=float(np.percentile((bot-top+1)[valid],99));best['pcm_peak']=float(np.max(np.abs(audio)));best['gradient_median_rgb']=[np.median(b,axis=0).tolist() if b else None for b in bins];out.append(best)
 (a.data/'signed-measurements.json').write_text(json.dumps(out,indent=2)+'\n')
 for q in out:print({k:v for k,v in q.items() if k!='gradient_median_rgb'})
if __name__=='__main__':
 p=argparse.ArgumentParser();p.add_argument('--data',type=Path,required=True);p.add_argument('--audio',type=Path,required=True);main(p.parse_args())
