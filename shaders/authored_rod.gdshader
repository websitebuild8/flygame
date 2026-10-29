shader_type spatial;
render_mode cull_disabled;
uniform sampler2D albedo_map : source_color, filter_linear_mipmap_anisotropic;
uniform float bend=0.0;
uniform bool overhead=false;
uniform vec4 tint : source_color=vec4(1.0);
uniform bool preserve_source_color=false;
uniform bool has_normal=false;
uniform sampler2D normal_map : hint_normal, filter_linear_mipmap;
uniform bool custom_paint=false;
uniform bool custom_special=false;
uniform vec4 custom_color : source_color=vec4(1.);
uniform vec4 custom_accent : source_color=vec4(1.);
varying float rod_distance;
void vertex(){
 vec3 base=vec3(0.,-.04,.38);
 vec3 axis=normalize(vec3(0.,.47,-.882666));
 vec3 radial=vec3(0.,-axis.z,axis.y);
 if(overhead){
  vec3 relative=VERTEX-base;
  VERTEX=base+axis*dot(relative,axis)-radial*dot(relative,radial)-vec3(relative.x,0.,0.);
  NORMAL=axis*dot(NORMAL,axis)-radial*dot(NORMAL,radial)-vec3(NORMAL.x,0.,0.);
 }
 float along=clamp(dot(VERTEX-base,axis),0.,2.7);
 rod_distance=along;
 float flex=max(along-.675,0.);
 float curvature=bend*.95/2.025;
 float angle=curvature*flex;
 vec3 center=base+axis*along;
 if(curvature>.00001){
  center=base+axis*(min(along,.675)+sin(angle)/curvature)-radial*((1.-cos(angle))/curvature);
 }
 vec3 offset=VERTEX-(base+axis*along);
 mat3 turn=mat3(vec3(1.,0.,0.),vec3(0.,cos(angle),-sin(angle)),vec3(0.,sin(angle),cos(angle)));
 VERTEX=center+turn*offset;
 NORMAL=turn*NORMAL;
 TANGENT=turn*TANGENT;
 BINORMAL=turn*BINORMAL;
}
void fragment(){
 vec3 paint=texture(albedo_map,UV).rgb;
 float white_paint=step(.62,min(paint.r,min(paint.g,paint.b)));
 if(!preserve_source_color){paint=mix(paint,paint*vec3(.19,.28,.36),white_paint);}
 vec3 base_paint=paint*tint.rgb;
 if(custom_paint){
  vec3 finish=custom_color.rgb;
  if(custom_special){finish=mix(finish,custom_accent.rgb,step(.84,fract(rod_distance*5.)));}
  base_paint=mix(base_paint,finish*(.65+dot(paint,vec3(.2126,.7152,.0722))*.35),smoothstep(.72,.9,rod_distance)*(1.-white_paint*.75));
 }
 ALBEDO=base_paint;
 if(has_normal){NORMAL_MAP=texture(normal_map,UV).rgb;NORMAL_MAP_DEPTH=.45;}
 ROUGHNESS=.34;
 METALLIC=.28;
}
