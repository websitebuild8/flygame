shader_type spatial;
render_mode cull_disabled;
uniform sampler2D base_map : source_color,filter_linear_mipmap;
uniform bool has_map=false;
uniform bool cutout=false;
uniform float cutoff=.5;
uniform vec4 base_color : source_color=vec4(1.0);
uniform vec4 paint_color : source_color=vec4(1.0);
uniform vec4 accent_color : source_color=vec4(1.0);
uniform float source_roughness=.5;
uniform float source_metallic=.2;
uniform bool boat=false;
uniform bool has_normal=false;
uniform sampler2D normal_map : hint_normal,filter_linear_mipmap;
uniform bool special=false;
uniform float band_low=-.6;
uniform float band_high=.3;
varying vec3 local_point;
varying vec3 local_normal;
void vertex(){local_point=VERTEX;local_normal=NORMAL;}
void fragment(){
 vec3 original=base_color.rgb;
 if(has_map){
  vec4 texel=texture(base_map,UV);
  if(cutout && texel.a*base_color.a<cutoff){discard;}
  original*=texel.rgb;
 }
 float light=dot(original,vec3(.2126,.7152,.0722));
 float mask=smoothstep(.035,.14,light);
 if(boat){
  mask*=1.-smoothstep(.45,.75,abs(local_normal.y));
  mask*=smoothstep(band_low,band_low+.08,local_point.y)*(1.-smoothstep(band_high-.08,band_high,local_point.y));
 }
 vec3 color=paint_color.rgb;
 if(special){
  float stripe=boat?smoothstep(band_high-.14,band_high-.11,local_point.y):step(.84,fract(UV.y*5.));
  color=mix(color,accent_color.rgb,stripe);
 }
 ALBEDO=mix(original,color*(.64+light*.36),mask);
 if(has_normal){NORMAL_MAP=texture(normal_map,UV).rgb;}
 ROUGHNESS=source_roughness;METALLIC=source_metallic;
}
