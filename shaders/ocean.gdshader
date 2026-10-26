shader_type spatial;
render_mode cull_disabled;
uniform vec3 deep_color : source_color = vec3(0.025, 0.30, 0.43);
uniform vec3 shallow_color : source_color = vec3(0.16, 0.70, 0.65);
uniform float rough_sea=0.0;
uniform float rain=0.0;
uniform float detail_quality=2.0;
uniform float daylight=1.0;
varying vec3 world;
void vertex(){
 world=(MODEL_MATRIX*vec4(VERTEX,1.0)).xyz;
 VERTEX.y+=(sin(world.x*.12+TIME*1.1)*.08+sin(world.z*.16+TIME*.8)*.06)*(1.+rough_sea*3.5);
}
void fragment(){
 float waves=sin(world.x*.9+sin(world.z*.4+TIME))*.5+sin(world.z*1.4-TIME*.6)*.5;
 float shore=exp(-distance(world.xz,vec2(-25.,30.))*.035);
 shore=max(shore,exp(-distance(world.xz,vec2(85.,-80.))*.035));
 shore=max(shore,exp(-distance(world.xz,vec2(-22.,-125.))*.035));
 shore=max(shore,exp(-distance(world.xz,vec2(-130.,110.))*.045));
 shore=max(shore,exp(-distance(world.xz,vec2(115.,65.))*.045));
 ALBEDO=mix(deep_color,shallow_color,clamp(shore+waves*.025,0.,1.))*mix(.5,1.,daylight);
 float crest=smoothstep(.83,.99,sin(world.x*.12+world.z*.16+TIME*1.3))*rough_sea;
 float rain_rings=0.;
 if(detail_quality>0.5 && rain>0.01){rain_rings=pow(max(0.,sin(length(fract(world.xz*.8)-.5)*55.-TIME*14.)),18.)*rain*.09;}
 ALBEDO=mix(ALBEDO,vec3(.65,.82,.82),crest*.18+rain_rings);
 ROUGHNESS=.26+rough_sea*.16+rain*.08;
 METALLIC=.16;
 NORMAL=normalize(vec3(waves*(.045+rough_sea*.11),(.05+rough_sea*.08)*sin(world.z*.8+TIME),1.));
}
