shader_type canvas_item;
uniform sampler2D backdrop : hint_screen_texture, repeat_disable, filter_linear_mipmap;
void fragment(){
 vec4 surface=COLOR;
 vec3 scene=textureLod(backdrop,SCREEN_UV,2.8).rgb;
 vec3 frosted=mix(scene,vec3(.055,.10,.13),.70);
 float sheen=pow(1.-UV.y,4.)*.075;
 COLOR=vec4(mix(frosted,surface.rgb,.25)+sheen,min(surface.a,.89));
}
