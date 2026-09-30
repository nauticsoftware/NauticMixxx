#!/usr/bin/env python3
"""Measure the original (unscaled) 2026-09-29 calibration PNGs."""
import argparse,json,hashlib
from pathlib import Path
from collections import Counter
import numpy as np
from PIL import Image

def runs(v):
 out=[]
 for x in v:
  if out and x==out[-1][-1]+1:out[-1].append(int(x))
  else:out.append([int(x)])
 return out

def palette(a,n=16):
 return [{'rgb':'#%02X%02X%02X'%tuple(map(int,c)),'pixels':int(count)} for c,count in Counter(map(tuple,a.reshape(-1,3))).most_common(n)]

def measure(ref):
 a=np.array(Image.open(ref['path']).convert('RGB'));h,w=a.shape[:2]
 gray=(a[:,:,0]==a[:,:,1])&(a[:,:,1]==a[:,:,2])&(a[:,:,0]>35)
 rows=np.where(gray.sum(1)>w*.7)[0];rows=rows[rows<h/3];baseline=int(rows[0])
 red=np.all(a==[255,0,0],axis=2);detail=red.copy();detail[:baseline+20]=False
 px=int(detail.sum(0).argmax());rr=max(runs(np.where(detail[:,px])[0]),key=len)
 triangle=[]
 for y in range(baseline+20,h):
  groups=[g for g in runs(np.where(red[y])[0]) if len(g) in [3,5,7]]
  if len(groups)>2:triangle.append((y,groups))
 # Grid-independent detail center from strongest symmetric waveform envelope.
 start=baseline+35;end=h-4
 if triangle:
  top=triangle[0][0];bars=[g[len(g)//2] for g in triangle[0][1]]
  bottoms=[y for y,_ in triangle if y>top+50];bottom=bottoms[-1] if bottoms else None
 else:top=None;bottom=None;bars=[]
 if bottom is not None:center=(top+bottom)/2
 else:
  if ref['mode']=='3band':mask=np.all(a==[0,81,225],axis=2)
  elif ref['mode']=='blue':mask=(a[:,:,2]>a[:,:,0]+20)&(a[:,:,2]>100)
  else:mask=(a[:,:,0]>60)&(a[:,:,1]<a[:,:,0]*.2)&(a[:,:,2]<a[:,:,0]*.2)
  mask[:start]=False
  # Ignore flat phrase/selection bars and header/overview.
  mask[mask.sum(1)>w*.95]=False
  yy=np.where(mask)[0];center=float(np.median(yy)) if len(yy) else (start+end)/2
 label=np.all(a==[0,125,225],axis=2);label[:baseline+15]=False;ly,lx=np.where(label)
 detail_top=top if top is not None else rr[0]
 report=dict(file=ref['file'],mode=ref['mode'],path=ref['path'],sha256=hashlib.sha256(Path(ref['path']).read_bytes()).hexdigest(),size=[w,h],overview_baseline_rows=rows.tolist(),overview_palette=palette(a[20:baseline]),detail_palette=palette(a[detail_top:]),playhead=dict(x=px,y=[rr[0],rr[-1]],width_px=1),grid_top=top,grid_bottom=bottom,bar_x=bars,pixels_per_beat=float(np.median(np.diff(bars))/4) if len(bars)>1 else None,detail_center_y=center,label_bbox=[int(lx.min()),int(ly.min()),int(lx.max()+1),int(ly.max()+1)] if len(lx) else None)
 return report
if __name__=='__main__':
 p=argparse.ArgumentParser();p.add_argument('references',type=Path);p.add_argument('--output',type=Path,required=True);a=p.parse_args();r=[measure(x) for x in json.loads(a.references.read_text())];a.output.write_text(json.dumps(r,indent=2)+'\n')
 for q in r:print(q['file'],q['mode'],'grid',q['grid_top'],q['grid_bottom'],'center',q['detail_center_y'],'px/beat',q['pixels_per_beat'])
