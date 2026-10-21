shader_type spatial;
render_mode cull_back;
uniform int species = 0;
varying vec3 body_position;
void vertex(){ body_position = VERTEX; }
void fragment(){
 float top = smoothstep(-0.08,0.32,body_position.y);
 vec3 silver = vec3(0.64,0.73,0.73);
 vec3 back = species==2 ? vec3(0.12,0.23,0.26) : vec3(0.025,0.10,0.19);
 vec3 skin = mix(silver,back,top);
 float flank = exp(-pow((body_position.y-0.025)*29.0,2.0));
 if(species==0){ skin=mix(skin,vec3(0.62,0.57,0.23),flank*0.65); }
 if(species==1){
  float stripe = smoothstep(0.72,0.93,cos((body_position.y+0.05)*100.0));
  float belly = (1.0-smoothstep(-0.02,0.05,body_position.y))*smoothstep(-0.85,-0.45,body_position.z);
  skin=mix(skin,vec3(0.10,0.19,0.24),stripe*belly*0.85);
 }
 if(species==3){ skin=mix(vec3(0.78,0.78,0.2),vec3(0.06,0.50,0.35),top); }
 if(species==4){ skin=mix(silver,vec3(0.06,0.23,0.37),top); skin*=1.-smoothstep(.75,.95,sin(body_position.z*38.))*top*.45; }
 if(species==5){ skin=mix(vec3(.68,.35,.27),vec3(.36,.16,.17),top); }
 if(species==6){ skin=mix(silver,vec3(.12,.32,.39),top); skin=mix(skin,vec3(.8,.68,.27),exp(-pow(body_position.y*22.,2.))*.8); }
 if(species==7){ skin=mix(silver,vec3(.07,.29,.40),top); skin*=.92+.08*sin(UV.x*90.)*sin(UV.y*120.); }
 if(species==9){skin=mix(vec3(.56,.67,.52),vec3(.16,.33,.25),top);}
 if(species==10){skin=mix(vec3(.79,.43,.36),vec3(.42,.16,.18),top);}
 if(species==11 || species==12){
  skin=mix(vec3(.55,.43,.26),vec3(.25,.25,.17),top);
  vec2 cell=fract(UV*vec2(34.,48.))-.5;
  float spots=1.-smoothstep(.10,.23,length(cell));
  skin=mix(skin,species==11 ? vec3(.16,.43,.64) : vec3(.13,.14,.10),spots*.8);
 }
 if(species==13){skin=mix(silver,vec3(.17,.26,.22),top);skin*=1.-smoothstep(.8,.98,sin(body_position.z*29.))*top*.45;}
 if(species==14){skin=mix(silver,vec3(.05,.20,.28),top);skin*=1.-smoothstep(.65,.95,sin(body_position.z*33.+sin(body_position.y*40.)))*top*.4;}
 float scales = sin(UV.x*260.0+sin(UV.y*180.0))*sin(UV.y*180.0);
 skin += scales*0.016;
 ALBEDO=skin;
 METALLIC=0.58;
 ROUGHNESS=0.27+scales*0.025;
 SPECULAR=0.65;
}
