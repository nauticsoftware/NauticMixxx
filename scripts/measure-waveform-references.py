#!/usr/bin/env python3
"""Measure reference PNGs, or compare equally sized reference/render PNGs.

Requires Pillow and numpy. Measurements refer to source pixels, not UI points.
No audio timing, absent markers, or unobserved palette endpoints are inferred.
"""
import argparse
from collections import Counter
import hashlib
import json
from pathlib import Path

import numpy as np
from PIL import Image


def palette(pixels, n=12):
    return [{"rgb": "#%02X%02X%02X" % rgb, "pixels": count}
            for rgb, count in Counter(map(tuple, pixels.reshape(-1, 3))).most_common(n)]


def runs(values):
    result = []
    for value in values:
        if result and value == result[-1][-1] + 1:
            result[-1].append(int(value))
        else:
            result.append([int(value)])
    return result


def measure(path):
    a = np.asarray(Image.open(path).convert("RGB"))
    h, w = a.shape[:2]
    gray = (a[:, :, 0] == a[:, :, 1]) & (a[:, :, 1] == a[:, :, 2]) & (a[:, :, 0] > 35)
    baseline_rows = np.where(gray.sum(axis=1) > w * .75)[0]
    baseline_rows = baseline_rows[baseline_rows < h // 3]
    if len(baseline_rows) == 0:
        raise ValueError(f"No measurable overview baseline in {path}")
    baseline = int(baseline_rows[0])
    red = np.all(a == [255, 0, 0], axis=2)
    detail_red = red.copy()
    detail_red[:baseline + 20] = False
    px = int(detail_red.sum(axis=0).argmax())
    py = np.where(detail_red[:, px])[0]
    # The playhead is the longest red run; crop boundaries are never extrapolated.
    play_run = max(runs(py), key=len)
    triangle_rows = []
    for y in range(baseline + 20, h):
        groups = [g for g in runs(np.where(red[y])[0]) if len(g) in (3, 5, 7)]
        if len(groups) >= 2:
            triangle_rows.append((y, groups))
    top = triangle_rows[0][0] if triangle_rows else play_run[0]
    bottom = triangle_rows[-1][0] if triangle_rows else play_run[-1]
    bar_x = [g[len(g)//2] for g in triangle_rows[0][1]] if triangle_rows else []
    spacings = np.diff(bar_x)
    detail = a[top:bottom+1]
    colored = (detail.max(axis=2).astype(int)-detail.min(axis=2).astype(int) > 10)
    colored &= ~np.all(detail == [255, 0, 0], axis=2)
    ys = np.where(colored)[0]
    wave_height = int(ys.max()-ys.min()+1) if len(ys) else None
    label = np.all(a == [0, 125, 225], axis=2)
    label[:baseline+10] = False
    ly, lx = np.where(label)
    return {
        "file": path.name, "sha256": hashlib.sha256(path.read_bytes()).hexdigest(),
        "size": [w,h], "palette": palette(a),
        "overview_baseline_rows": baseline_rows.tolist(),
        "overview_palette": palette(a[:baseline]),
        "detail_palette": palette(detail),
        "detail_grid_bounds_y": [top,bottom],
        "observed_waveform_height_px": wave_height,
        "playhead": {"x": px, "y": [play_run[0],play_run[-1]], "width_px": 1, "rgb": "#FF0000"},
        "bar_triangle_centers_x": bar_x,
        "bar_spacings_px": spacings.tolist(),
        "pixels_per_beat": float(np.median(spacings)/4) if len(spacings) else None,
        "overview_to_detail_grid_height": float(baseline/(bottom-top+1)),
        "label_exact_color_bbox": [int(lx.min()),int(ly.min()),int(lx.max()+1),int(ly.max()+1)] if len(lx) else None,
        "label_rgb": "#007DE1" if len(lx) else None,
        "unmeasured": ["absolute time without track/grid", "amplitude transfer function without ANLZ", "A/B markers absent from these crops", "Blue whitening endpoints obscured by gradient and antialiasing"],
    }


def compare(reference, render, output):
    a = np.asarray(Image.open(reference).convert("RGB"), dtype=np.float64)
    b = np.asarray(Image.open(render).convert("RGB"), dtype=np.float64)
    if a.shape != b.shape:
        raise ValueError("Comparison requires identical dimensions; align/crop explicitly first")
    # SSIM with a 7x7 uniform window, population covariance, RGB channel mean.
    def avg(x):
        return np.lib.stride_tricks.sliding_window_view(x, (7,7), axis=(0,1)).mean(axis=(-1,-2))
    ma, mb = avg(a), avg(b)
    va, vb, cov = avg(a*a)-ma*ma, avg(b*b)-mb*mb, avg(a*b)-ma*mb
    score = ((2*ma*mb+6.5025)*(2*cov+58.5225)/((ma*ma+mb*mb+6.5025)*(va+vb+58.5225))).mean()
    hist_diff = []
    for c in range(3):
        ha = np.bincount(a[:,:,c].astype(int).ravel(), minlength=256)/a[:,:,c].size
        hb = np.bincount(b[:,:,c].astype(int).ravel(), minlength=256)/b[:,:,c].size
        hist_diff.append(float(np.abs(ha-hb).sum()/2))
    canvas = np.concatenate([a,b,np.abs(a-b)],axis=1).astype(np.uint8)
    Image.fromarray(canvas).save(output)
    return {"ssim_uniform_7x7_rgb": float(score), "histogram_total_variation_rgb":hist_diff,
            "mean_absolute_error_rgb":float(np.abs(a-b).mean()), "comparison":str(output)}


def main():
    parser=argparse.ArgumentParser(description=__doc__)
    parser.add_argument("images",nargs="*",type=Path)
    parser.add_argument("--output",required=True,type=Path)
    parser.add_argument("--compare",nargs=2,type=Path,metavar=("REFERENCE","RENDER"))
    args=parser.parse_args()
    args.output.parent.mkdir(parents=True,exist_ok=True)
    result=compare(*args.compare,args.output.with_suffix('.png')) if args.compare else [measure(p) for p in args.images]
    args.output.write_text(json.dumps(result,indent=2)+"\n")


if __name__=="__main__":
    main()
