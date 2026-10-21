shader_type spatial;
render_mode cull_disabled, depth_prepass_alpha;
uniform vec4 fin_color : source_color = vec4(.5,.6,.5,1.);
void fragment(){
 float rays=.5+.5*sin(atan(UV.y,UV.x)*65.);
 float grain=sin(UV.x*220.+UV.y*150.)*.025;
 ALBEDO=fin_color.rgb*(.88+rays*.09+grain);
 ALPHA=.76+rays*.1;
 ROUGHNESS=.37;
 SPECULAR=.55;
}
