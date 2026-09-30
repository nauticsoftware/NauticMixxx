#!/usr/bin/env python3
"""Measure preview column height and five gradient knots on calibration 01."""
import argparse,json
from pathlib import Path
import numpy as np
from PIL import Image
p=argparse.ArgumentParser();p.add_argument('--data',type=Path,required=True);a=p.parse_args();result={}
for mode,start,end,label in [('blue',.07,.13,'blue_low'),('blue',.78,.85,'blue_high'),('rgb',.07,.13,'rgb_low')]:
 im=np.array(Image.open(a.data/f'01_{mode}_overview_reference.png'))[:,:,:3];mask=np.load(a.data/f'01_{mode}_overview_mask.npy');h,w=im.shape[:2];colors=[];heights=[]
 for x in range(int(w*start),int(w*end)):
  if mask[:,x].any():continue
  y=h-2
  if not im[y,x].any():continue
  top=y
  while top>0 and im[top-1,x].any():top-=1
  if y-top<5:continue
  heights.append(y-top+1);colors.append([im[round(top+(y-1-top)*k/4),x] for k in range(5)])
 result[label]=dict(columns=len(colors),height_median=float(np.median(heights)),gradient_median_rgb=np.median(colors,axis=0).tolist())
(a.data/'preview-gradient-measurements.json').write_text(json.dumps(result,indent=2)+'\n');print(result)
