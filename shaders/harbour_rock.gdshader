shader_type spatial;
uniform sampler2D stone_color : source_color, filter_linear_mipmap, repeat_enable;
uniform sampler2D stone_normal : hint_normal, filter_linear_mipmap, repeat_enable;
varying float height_world;
void vertex(){height_world=(MODEL_MATRIX*vec4(VERTEX,1.)).y;}
void fragment(){
 vec3 stone=texture(stone_color,UV).rgb;
 float grey=dot(stone,vec3(.299,.587,.114));
 stone=mix(stone,vec3(grey),.60)*COLOR.rgb;
 float wet=1.-smoothstep(-.62,-.36,height_world);
 ALBEDO=mix(stone,stone*.40,wet);
 NORMAL_MAP=texture(stone_normal,UV).rgb;
 NORMAL_MAP_DEPTH=.60;
 ROUGHNESS=mix(.88,.48,wet);
}
