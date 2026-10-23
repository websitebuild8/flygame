shader_type spatial;
render_mode cull_disabled;
uniform sampler2D skin_texture : source_color, filter_linear_mipmap, repeat_enable;
uniform bool use_vertex_color=false;
uniform int sail_part=-1;
varying vec3 fish_position;
uniform float phase=0.0;
uniform float amplitude=0.04;
void vertex() {
 fish_position=VERTEX;
 // Head (-Z) stays steady; flex increases smoothly toward the tail (+Z).
 float t=clamp((VERTEX.z+.6)/1.8,0.0,1.0);
 float wave=phase-VERTEX.z*3.4;
 float offset=amplitude*t*t*sin(wave);
 float slope=amplitude*(2.0*t/1.8*sin(wave)-3.4*t*t*cos(wave));
 VERTEX.x+=offset;
 NORMAL=normalize(vec3(NORMAL.x,NORMAL.y,NORMAL.z-NORMAL.x*slope));
}
void fragment() {
 ALBEDO=use_vertex_color ? COLOR.rgb : texture(skin_texture,UV).rgb;
 if (sail_part>=0) {
  float back=smoothstep(-.12,.16,fish_position.y);
  vec3 silver=vec3(.58,.72,.76);
  vec3 blue=vec3(.018,.075,.17);
  ALBEDO=mix(silver,blue,back);
  float bars=pow(.5+.5*sin(fish_position.z*76.0),12.0);
  ALBEDO=mix(ALBEDO,vec3(.07,.45,.67),bars*.45*smoothstep(-.3,-.05,fish_position.y)*(1.0-smoothstep(.1,.35,fish_position.y)));
  if (sail_part==1) {
   vec2 cell=fract(vec2(fish_position.z*31.0,fish_position.y*34.0));
   float spots=1.0-smoothstep(.14,.29,length(cell-.5));
   ALBEDO=mix(vec3(.025,.07,.19),vec3(.07,.32,.53),spots);
  }
  if (sail_part>1 && sail_part<6) ALBEDO=vec3(.08,.16,.23);
  if (sail_part==6) ALBEDO=vec3(.015,.028,.035);
  if (sail_part==7) ALBEDO=vec3(.23,.38,.42);
 }
 ROUGHNESS=sail_part==6 ? .16 : .38;
 METALLIC=.08;
 SPECULAR=.55;
}
