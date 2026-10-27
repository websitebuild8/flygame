shader_type spatial;
render_mode cull_disabled;
uniform vec3 deep_color : source_color = vec3(0.025, 0.30, 0.43);
uniform vec3 shallow_color : source_color = vec3(0.16, 0.70, 0.65);
uniform float rough_sea=0.0;
uniform float wave_time=0.0;
uniform float rain=0.0;
uniform float detail_quality=2.0;
uniform float daylight=1.0;
varying vec3 world;
uniform vec2 harbour_origin=vec2(23.,16.);
uniform vec2 harbour_inward=vec2(1.,0.);
uniform vec3 harbour_size=vec3(33.,0.,14.);
float shelter(vec2 p){vec2 d=p-harbour_origin;float u=dot(d,harbour_inward);float v=dot(d,vec2(-harbour_inward.y,harbour_inward.x));return (u>-harbour_size.x && u<harbour_size.y && abs(v)<harbour_size.z) ? .2 : 1.;}
void vertex(){
 world=(MODEL_MATRIX*vec4(VERTEX,1.0)).xyz;
 VERTEX.y+=(sin(world.x*.12+wave_time*1.1)*.08+sin(world.z*.16+wave_time*.8)*.06)*(1.+rough_sea*3.5)*.22*shelter(world.xz);
}
uniform sampler2D coast_map : repeat_disable, filter_linear;
uniform sampler2D sand_texture : source_color, repeat_enable, filter_linear_mipmap;
uniform sampler2D ripple_normal : hint_normal, repeat_enable, filter_linear_mipmap;
uniform vec4 shoal_fish[8];
float fish_shape(vec2 p){
 p.y+=sin(wave_time*5.+p.x*16.)*.008*smoothstep(.02,.13,-p.x);
 float body=1.-smoothstep(.85,1.05,length(p/vec2(.085,.022)));
 float tail=step(-.13,p.x)*step(p.x,-.075)*(1.-smoothstep((-.075-p.x)*.57,(-.075-p.x)*.57+.003,abs(p.y)));
 float fins=step(-.025,p.x)*step(p.x,.005)*(1.-smoothstep(.025-p.x,.030-p.x,abs(p.y)))*.7;
 return max(body,max(tail,fins));
}
void fragment(){
 vec2 map_uv=(world.xz+vec2(700.))/1400.;
 vec4 coast=texture(coast_map,clamp(map_uv,vec2(.001),vec2(.999)));
 float depth=coast.r;
 float shallow=1.-smoothstep(.04,.82,depth);
 float shelter_amount=shelter(world.xz);
 float local_rough=rough_sea*shelter_amount;
 vec2 ripple_uv=world.xz*.055;
 vec3 n1=texture(ripple_normal,ripple_uv+vec2(wave_time*.014,-wave_time*.009)).rgb;
 vec3 n2=texture(ripple_normal,ripple_uv*.63+vec2(-wave_time*.009,wave_time*.012)).rgb;
 NORMAL_MAP=mix(n1,n2,.5);
 NORMAL_MAP_DEPTH=.14+local_rough*.42;
 float face=clamp(dot(normalize(VIEW),normalize(NORMAL)),0.,1.);
 float bottom=(1.-smoothstep(.1,.62,depth))*face*(1.-local_rough*.65)*daylight;
 vec3 deep=vec3(.003,.018,.065);
 vec3 lagoon=vec3(.018,.22,.27);
 vec3 water_color=mix(deep,lagoon,shallow);
 vec2 refract_uv=world.xz*.12+(n1.xy-.5)*.065;
 vec3 sand=texture(sand_texture,refract_uv).rgb;
 vec3 bed=mix(vec3(.18,.30,.24),sand*vec3(.39,.61,.55),.62);
 water_color=mix(water_color,bed,bottom*.63);
 if(detail_quality>.5 && bottom>.01 && distance(world.xz,CAMERA_POSITION_WORLD.xz)<18.){
  float caustic=pow(max(0.,sin(world.x*4.+wave_time*.8)*sin(world.z*4.7-wave_time*.65)),6.);
  water_color+=vec3(.045,.065,.052)*caustic*bottom;
 }
 // Fish silhouettes sit in the seabed layer, so quays/hulls occlude them normally.
 if(bottom>.03 && distance(world.xz,CAMERA_POSITION_WORLD.xz)<32.){
  float activity=0.;
  for(int i=0;i<8;i++){
   if(shoal_fish[i].w>.5){
    vec2 d=world.xz-shoal_fish[i].xy;
    if(abs(d.x)<.25 && abs(d.y)<.25){
     float c=cos(shoal_fish[i].z);float s=sin(shoal_fish[i].z);
     activity=max(activity,fish_shape(vec2(c*d.x+s*d.y,-s*d.x+c*d.y)));
    }
   }
  }
  water_color=mix(water_color,vec3(.008,.04,.06),activity*bottom*.85);
 }
 float wash=(.5+.5*sin(world.x*.8+world.z*.6-wave_time*1.1));
 float foam=coast.g*wash*(.14+local_rough*.28);
 water_color=mix(water_color,vec3(.61,.85,.80),foam);
 ALBEDO=water_color*mix(.20,1.,daylight);
 ROUGHNESS=.28+local_rough*.18+rain*.06;
 METALLIC=.07;
 SPECULAR=.65;
}
