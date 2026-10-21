shader_type spatial;
render_mode unshaded, cull_disabled, depth_draw_never, fog_disabled;
uniform sampler2D cloud_noise : repeat_enable, filter_linear_mipmap;
uniform float cover=0.0;
uniform float daylight=1.0;
uniform float sunset=0.0;
void fragment(){
 vec2 drift=vec2(TIME*.0004,TIME*.0002);
 float noise=texture(cloud_noise,UV*2.5+drift).r;
 float cloud=smoothstep(.45-cover*.3,.65-cover*.22,noise);
 vec3 tint=mix(vec3(.12,.17,.27),vec3(.94,.95,.92),daylight);
 tint=mix(tint,vec3(.95,.65,.49),sunset*.45);
 ALBEDO=tint*mix(1.,.52,cover)*(.8+noise*.2);
 ALPHA=cloud*.85;
}
