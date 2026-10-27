"""Bake a fictional shallow-water map from the game's OSM-derived coastlines.
Run export_ocean_coasts.gd first. Requires numpy and Pillow; no runtime dependency.
"""
import json, pathlib, numpy as np
from PIL import Image, ImageDraw
ROOT=pathlib.Path(__file__).resolve().parents[1]
SIZE=512; HALF=700.0
islands=json.loads((ROOT/'assets/maps/ocean/coasts.json').read_text())
axis=(np.arange(SIZE)+.5)/SIZE*(2*HALF)-HALF
x,z=np.meshgrid(axis,axis);distance=np.full((SIZE,SIZE),10000.0)
land=Image.new('L',(SIZE,SIZE));ports=Image.new('L',(SIZE,SIZE));land_draw=ImageDraw.Draw(land);port_draw=ImageDraw.Draw(ports)
def pixel(p):return ((p[0]+HALF)/(2*HALF)*SIZE,(p[1]+HALF)/(2*HALF)*SIZE)
for island in islands:
 coast=island['coast'];land_draw.polygon([pixel(p) for p in coast],fill=255)
 port_draw.polygon([pixel(p) for p in island['harbour']],fill=255)
 for a,b in zip(coast,coast[1:]+coast[:1]):
  dx=b[0]-a[0];dz=b[1]-a[1];den=dx*dx+dz*dz
  if den<1e-10:continue
  t=np.clip(((x-a[0])*dx+(z-a[1])*dz)/den,0,1)
  distance=np.minimum(distance,np.hypot(x-a[0]-t*dx,z-a[1]-t*dz))
water=np.array(land)<128;harbour=(np.array(ports)>128)&water
# Depth is an artistic coastal ramp, not measured bathymetry or navigation data.
depth=np.clip(distance/24.0,0,1)
noise=np.sin(x*.41+np.sin(z*.18))*np.sin(z*.29)*.035
r=np.clip(depth+noise*depth*(1-depth),0,1);r[~water]=0;r[harbour]=.32
foam=np.clip(1-distance/3.5,0,1);foam[harbour]=0;foam[~water]=0
rgba=np.stack([r,foam,water.astype(float),harbour.astype(float)],axis=-1)
Image.fromarray((rgba*255).astype('uint8')).save(ROOT/'assets/maps/ocean/coastal_depth.png',optimize=True)
# Original tileable normal texture, with long crossed ripple frequencies.
u,v=np.meshgrid(np.arange(256)/256*2*np.pi,np.arange(256)/256*2*np.pi)
rng=np.random.default_rng(7402)
nx=np.zeros_like(u);ny=np.zeros_like(u)
for k in range(12):
 fx,fz=rng.integers(-7,8,size=2);phase=rng.random()*2*np.pi
 strength=.065/(1+.08*(fx*fx+fz*fz))
 nx+=strength*fx*np.cos(u*fx+v*fz+phase)
 ny+=strength*fz*np.cos(u*fx+v*fz+phase)
nz=np.ones_like(nx);length=np.sqrt(nx*nx+ny*ny+nz*nz)
normal=np.stack([nx/length*.5+.5,ny/length*.5+.5,nz/length*.5+.5],axis=-1)
Image.fromarray((normal*255).astype('uint8')).save(ROOT/'assets/textures/ocean/ripple_normal.png',optimize=True)
print('Baked 512px coastline depth map and 256px ripple normal')
