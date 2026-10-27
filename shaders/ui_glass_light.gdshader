shader_type canvas_item;
// Low preset: translucent glass without a full-screen copy or blur mipmaps.
void fragment(){
 vec4 surface=COLOR;
 float sheen=pow(1.-UV.y,4.)*.075;
 COLOR=vec4(mix(vec3(.055,.10,.13),surface.rgb,.35)+sheen,min(surface.a,.82));
}
