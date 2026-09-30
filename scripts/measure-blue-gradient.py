#!/usr/bin/env python3
"""Measure Blue gradient colors against native whiteness using calibration 01/02."""
import argparse,json,importlib.util
from pathlib import Path
import numpy as np
from PIL import Image
p=argparse.ArgumentParser();p.add_argument('--data',type=Path,required=True);p.add_argument('--usb',type=Path,required=True);args=p.parse_args()
D=args.data;S=Path(__file__).resolve().parent
spec=importlib.util.spec_from_file_location('cal',S/'rekordbox-calibration.py');cal=importlib.util.module_from_spec(spec);spec.loader.exec_module(cal)
buckets=[[[] for _ in range(5)] for _ in range(8)];counts=[0]*8
for q in json.load(open(D/'registration.json'))['jobs']:
 if q['stem'] not in ['01_blue_detail','02_blue_detail']:continue
 a=np.array(Image.open(D/(q['stem']+'_reference.png')))[:,:,:3];mask=np.load(D/(q['stem']+'_mask.npy'));h,w=a.shape[:2]
 sig=(a[:,:,2]>90)&(a[:,:,2]>a[:,:,0]*1.2)&~mask;sig[88:]=False
 _,data=cal.read_anlz((args.usb/'PIONEER/USBANLZ')/cal.ANLZ[int(q['stem'][:2])-1]);top=np.argmax(sig,0);bot=h-1-np.argmax(sig[::-1],0)
 for x in range(w):
  if sig[:,x].sum()<10:continue
  white=int(data[min(len(data)-1,int((q['first_second']+x*(q['last_second']-q['first_second'])/w)*150)),1]);counts[white]+=1
  for k in range(5):
   y=int(round(top[x]+(57-top[x])*min(k,4-k)/2)) if white>0 else int(round(top[x]+(bot[x]-top[x])*k/4))
   if sig[y,x]:buckets[white][k].append(a[y,x])
rows=[dict(whiteness=i,columns=counts[i],gradient=[np.median(v,axis=0).tolist() if v else None for v in row]) for i,row in enumerate(buckets)]
(D/'blue-gradient-by-whiteness.json').write_text(json.dumps(rows,indent=2)+'\n');print(rows)
