shader_type spatial;
render_mode cull_disabled;
uniform sampler2D skin_texture : source_color, filter_linear_mipmap, repeat_enable;
uniform float phase=0.0;
uniform float amplitude=0.04;
void vertex() {
 // Head (-Z) stays steady; flex increases smoothly toward the tail (+Z).
 float t=clamp((VERTEX.z+.6)/1.8,0.0,1.0);
 float wave=phase-VERTEX.z*3.4;
 float offset=amplitude*t*t*sin(wave);
 float slope=amplitude*(2.0*t/1.8*sin(wave)-3.4*t*t*cos(wave));
 VERTEX.x+=offset;
 NORMAL=normalize(vec3(NORMAL.x,NORMAL.y,NORMAL.z-NORMAL.x*slope));
}
void fragment() {
 ALBEDO=texture(skin_texture,UV).rgb;
 ROUGHNESS=.38;
 METALLIC=.08;
 SPECULAR=.55;
}
