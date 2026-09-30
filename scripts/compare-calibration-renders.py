#!/usr/bin/env python3
"""Prepare native render jobs and compare their output to calibration crops.

The C++ fixture uses production ANLZ decoding/renderColumns. UI chrome is
excluded. Cropped regions, masks and registration are recorded explicitly.
"""
import argparse,json,importlib.util
from pathlib import Path
import numpy as np
from PIL import Image

base=Path(__file__).resolve().parent
spec=importlib.util.spec_from_file_location('cal',base/'rekordbox-calibration.py');cal=importlib.util.module_from_spec(spec);spec.loader.exec_module(cal)
spec=importlib.util.spec_from_file_location('measure',base/'measure-waveform-references.py');measure=importlib.util.module_from_spec(spec);spec.loader.exec_module(measure)

def prepare(args):
 refs=json.loads((args.data/'capture-measurements.json').read_text());manifest=json.loads(args.manifest.read_text());names=list(manifest['files']);jobs=[];registrations=[]
 overview_fit={x['file']:x for x in json.loads((args.data/'overview-fit.json').read_text())}
 # Derive pixels/s ONLY from supplied grid + exported beat timestamps.
 scales=[]
 for q in refs:
  tags,_=cal.read_anlz(args.usb/'PIONEER/USBANLZ'/cal.ANLZ[q['file']-1]);payload=tags['PQTZ'][0]
  if q['pixels_per_beat'] and len(payload)>=16:
   times=np.array([int.from_bytes(payload[i+4:i+8],'big')/1000 for i in range(0,len(payload),8)]);scales.append(q['pixels_per_beat']/np.median(np.diff(times)))
 scale=float(np.median(scales))
 for q in refs:
  i=q['file'];mode=['blue','rgb','3band'].index(q['mode']);a=np.array(Image.open(q['path']).convert('RGB'));h,w=a.shape[:2];duration=manifest['files'][names[i-1]]['duration_s']
  # Establish timing from the visible audio onset at t=2 s; use the 3-Band
  # companion to avoid mistaking Blue/RGB half-cycle zero crossings for onset.
  mate=next(r for r in refs if r['file']==i and r['mode']=='3band');b=np.array(Image.open(mate['path']).convert('RGB'));blue=np.all(b==[0,81,225],2);blue[:mate['overview_baseline_rows'][-1]+30]=False;yy,xx=np.where(blue);xstart=int(xx.min());ys=np.where(blue[:,xstart+30:xstart+100])[0];mc=(ys.min()+ys.max())/2
  # Different PNG crops have different left edges. Align via playhead x.
  xstart+=q['playhead']['x']-mate['playhead']['x'];first=2-xstart/scale
  center=mc+(q['grid_top']-mate['grid_top'] if q['grid_top'] and mate['grid_top'] else q['detail_center_y']-mate['detail_center_y'])
  y0=int(round(center-57));crop_h=min(114,h-y0);stem=f'{i:02d}_{q["mode"]}'
  for overview in [False,True]:
   if overview:
    fit=overview_fit[i];x0=fit['origin'];ww=min(fit['width'],w-x0);yy0=20;hh=q['overview_baseline_rows'][0]-2-yy0;start=0;end=duration;actual_h=hh;kind='overview'
   else:x0=0;ww=w;yy0=y0;hh=114;actual_h=crop_h;start=first;end=first+w/scale;kind='detail'
   ref=a[yy0:yy0+actual_h,x0:x0+ww].copy();mask=np.zeros(ref.shape[:2],bool)
   if not overview:
    # Exclude grid lines/playhead and flat phrase bars; waveform pixels remain.
    for x in q['bar_x']+[q['playhead']['x']]:mask[:,max(0,x-x0-1):min(ww,x-x0+2)]=True
    if q['pixels_per_beat'] and q['bar_x']:
     for x in np.arange(q['bar_x'][0]%q['pixels_per_beat'],w,q['pixels_per_beat']):mask[:,max(0,int(x)-1):min(ww,int(x)+2)]=True
    for y in range(len(ref)):
     colors,counts=np.unique(ref[y],axis=0,return_counts=True);c=colors[counts.argmax()]
     if counts.max()>ww*.6 and (tuple(c) in [(203,63,63),(180,0,0),(30,30,30)]):mask[y]=True
   else:
    red=np.all(ref==[255,0,0],2);mask[:,red.sum(0)>hh*.6]=True
   Image.fromarray(ref).save(args.data/f'{stem}_{kind}_reference.png');np.save(args.data/f'{stem}_{kind}_mask.npy',mask)
   job=dict(audio=str(args.usb/'Contents/UnknownArtist/UnknownAlbum'/names[i-1]),anlz=str(args.usb/'PIONEER/USBANLZ'/cal.ANLZ[i-1]),duration=duration,mode=mode,overview=overview,width=ww,height=hh,first_second=start,last_second=end,output=str((args.data/f'{stem}_{kind}_render.png').resolve()))
   jobs.append(job);registrations.append(dict(stem=f'{stem}_{kind}',source=q['path'],crop=[x0,yy0,ww,actual_h],render_height=hh,first_second=start,last_second=end,masked_pixels=int(mask.sum())))
 args.spec.write_text(json.dumps(jobs,indent=2)+'\n');(args.data/'registration.json').write_text(json.dumps(dict(pixels_per_second_from_grid=scale,jobs=registrations),indent=2)+'\n')
 print('Prepared',len(jobs),'native jobs; scale',scale)

def register_previews(args):
 """Register each crop's audio onset at manifest t=2s, independently by mode.
 This removes the different left crop margins; it does not optimize SSIM.
 """
 jobs=json.loads(args.spec.read_text());registration=json.loads((args.data/'registration.json').read_text())
 for job in jobs:
  if not job['overview'] or job['mode']==2:continue
  stem=Path(job['output']).stem.removesuffix('_render');im=np.array(Image.open(args.data/f'{stem}_reference.png'))[:,:,:3];h,w=im.shape[:2]
  rgb=im.astype(float)
  active=(rgb[:,:,2]>25)&(rgb[:,:,2]>rgb[:,:,0]*1.3) if job['mode']==0 else (rgb[:,:,0]>40)&(rgb[:,:,1]<rgb[:,:,0]*.1)&(rgb[:,:,2]<rgb[:,:,0]*.1)
  xs=np.where(active[int(h*.4):].sum(0)>3)[0]
  if not len(xs):raise ValueError('No measured onset: '+stem)
  offset=int(xs[0])-round(w*2/job['duration']);job['preview_offset_x']=offset
  row=next(x for x in registration['jobs'] if x['stem']==stem);row['preview_offset_x']=offset;row['preview_registration']='first colored PCM onset, manifest t=2s; no SSIM optimization'
 args.spec.write_text(json.dumps(jobs,indent=2)+'\n');(args.data/'registration.json').write_text(json.dumps(registration,indent=2)+'\n')
 print('Registered preview margins from measured audio onset')

def compare(args):
 rows=[]
 for job in json.loads((args.data/'registration.json').read_text())['jobs']:
  stem=job['stem'];ref=np.array(Image.open(args.data/f'{stem}_reference.png').convert('RGB'));render=np.array(Image.open(args.data/f'{stem}_render.png').convert('RGB'))[:len(ref)];mask=np.load(args.data/f'{stem}_mask.npy');raw_ref=ref.copy();raw_render=render.copy();ref[mask]=0;render[mask]=0
  Image.fromarray(ref).save(args.data/f'{stem}_reference_masked.png');Image.fromarray(render).save(args.data/f'{stem}_render_masked.png')
  # Same SSIM implementation used by the measurement tool.
  result=measure.compare(args.data/f'{stem}_reference_masked.png',args.data/f'{stem}_render_masked.png',args.data/f'{stem}_comparison.png')
  active=(np.any(raw_ref>0,2)|np.any(raw_render>0,2))&~mask
  result['foreground_mae_0_255']=float(np.abs(raw_ref.astype(float)-raw_render).mean(2)[active].mean())
  result['stem']=stem;rows.append(result)
 (args.data/'visual-validation.json').write_text(json.dumps(rows,indent=2)+'\n');print('Compared',len(rows),'pairs')

if __name__=='__main__':
 p=argparse.ArgumentParser();p.add_argument('action',choices=['prepare','compare','register-previews']);p.add_argument('--data',type=Path,required=True);p.add_argument('--manifest',type=Path);p.add_argument('--usb',type=Path,default=Path('/Volumes/NAUTICBOY'));p.add_argument('--spec',type=Path,default=Path('/tmp/nautic-calibration-render-spec.json'));args=p.parse_args();{'prepare':prepare,'compare':compare,'register-previews':register_previews}[args.action](args)
