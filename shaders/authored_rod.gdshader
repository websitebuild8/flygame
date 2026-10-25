shader_type spatial;
render_mode cull_disabled;
uniform sampler2D albedo_map : source_color, filter_linear_mipmap_anisotropic;
uniform float bend=0.0;
uniform bool overhead=false;
uniform vec4 tint : source_color=vec4(1.0);
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
}
void fragment(){
 vec3 paint=texture(albedo_map,UV).rgb;
 float white_paint=step(.62,min(paint.r,min(paint.g,paint.b)));
 paint=mix(paint,paint*vec3(.19,.28,.36),white_paint);
 ALBEDO=paint*tint.rgb;
 ROUGHNESS=.34;
 METALLIC=.28;
}
