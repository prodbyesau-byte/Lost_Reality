"""Original, repeatable 512px PBR surface authoring. No external images/assets.
Run with Python + numpy/Pillow. PNGs are shipped; this tool is never run by the game.
"""
from pathlib import Path
import numpy as np
from PIL import Image

OUT = Path(__file__).resolve().parent / "textures"
OUT.mkdir(exist_ok=True)
N = 512
y, x = np.mgrid[:N, :N] / N
rng = np.random.default_rng(73021)

def noise(cells):
    source = rng.random((cells, cells)).astype(np.float32)
    # Periodic interpolation, so every authored layer tiles without a border seam.
    xx, yy = x*cells, y*cells
    ix, iy = xx.astype(int), yy.astype(int)
    fx, fy = xx-ix, yy-iy
    fx, fy = fx*fx*(3-2*fx), fy*fy*(3-2*fy)
    return ((source[iy%cells,ix%cells]*(1-fx)+source[iy%cells,(ix+1)%cells]*fx)*(1-fy)
        +(source[(iy+1)%cells,ix%cells]*(1-fx)+source[(iy+1)%cells,(ix+1)%cells]*fx)*fy)

broad, fine, grain = noise(5), noise(32), noise(128)
for family in ["mineral", "wood", "brick", "fabric", "metal", "bark", "roof", "leaf", "skin", "asphalt"]:
    h = .45 + broad*.12 + fine*.08 + grain*.03
    tone = .76+broad*.18+fine*.05
    rough = .76+broad*.2
    ao = np.ones_like(x)
    if family == "wood":
        wave = np.sin(2*np.pi*(x*36 + .24*np.sin(y*2*np.pi) + broad*.8))
        knot = np.sin(2*np.pi*(x*9 + .18*np.sin(y*4*np.pi)))
        h = .5 + wave*.04 + knot*.025 + grain*.02
        tone = .69+wave*.075+knot*.04+broad*.16
        rough = .70+fine*.23
    elif family in ["brick", "roof"]:
        rows = 12 if family == "brick" else 16
        cols = 5 if family == "brick" else 9
        yy = y*rows
        xx = x*cols + (np.floor(yy)%2)*.5
        edge = np.minimum.reduce([xx%1, 1-xx%1, yy%1, 1-yy%1])
        face = np.clip((edge-.018)/.045, 0, 1)
        variation = (np.sin(np.floor(xx)*31+np.floor(yy)*97)*437.7)%1
        h = face*.65+fine*.07+grain*.025
        tone = (.48+variation*.24+fine*.14)*face+.38*(1-face)
        ao = .62+.38*face
        rough = .78+fine*.18
    elif family == "fabric":
        weave = np.sin(x*2*np.pi*128)*np.sin(y*2*np.pi*128)
        h = .5+weave*.055+fine*.015
        tone = .84+weave*.055+broad*.08
        rough = .91+fine*.08
    elif family == "bark":
        groove = np.sin(2*np.pi*(x*17+broad*.5+np.sin(y*2*np.pi)*.23))
        h = .5+groove*.19+fine*.08
        tone = .58+groove*.16+broad*.18
        ao = .75+groove*.12
    elif family == "metal":
        scratches = np.maximum(0,np.sin(x*2*np.pi*117+np.sin(y*2*np.pi)*.7)-.96)
        h = .5+grain*.014-scratches*.4
        tone = .80+broad*.14-scratches*.6
        rough = .55+broad*.28+scratches
    elif family == "leaf":
        veins = np.sin(x*2*np.pi*18+y*2*np.pi*12)**16
        h = .5+fine*.14+veins*.05
        tone = .67+broad*.2+fine*.1-veins*.03
    elif family == "skin":
        h = .5+grain*.003
        tone = .92+broad*.07
        rough = .78+fine*.12
    elif family == "asphalt":
        h = .4+grain*.22+fine*.06
        tone = .64+grain*.24+fine*.06
    dx, dy = (np.roll(h,-1,1)-np.roll(h,1,1))*2.5, (np.roll(h,-1,0)-np.roll(h,1,0))*2.5
    normal = np.stack([-dx,dy,np.ones_like(x)],axis=-1)
    normal /= np.linalg.norm(normal,axis=-1,keepdims=True)
    albedo = np.repeat(tone[...,None],3,axis=-1)
    orm = np.stack([ao,rough,np.zeros_like(x)],axis=-1)
    for suffix, pixels in [("albedo",albedo),("normal",normal*.5+.5),("orm",orm)]:
        Image.fromarray((np.clip(pixels,0,1)*255).astype(np.uint8)).save(OUT/f"{family}_{suffix}.png")
print("Baked 30 seamless PBR maps")
