shader_type spatial;
render_mode cull_back;
uniform int species = 0;
varying vec3 body_position;
float hash(vec2 p){return fract(sin(dot(p,vec2(127.1,311.7)))*43758.5453);}
float speckles(vec2 p){
 vec2 cell=floor(p);
 vec2 q=fract(p)-vec2(.22+hash(cell)*.55,.22+hash(cell+7.)*.55);
 float radius=mix(.07,.19,hash(cell+19.));
 return (1.-smoothstep(radius*.6,radius,length(q)))*step(.23,hash(cell+31.));
}
void vertex(){body_position=VERTEX;}
void fragment(){
 float top=smoothstep(-.18,.26,body_position.y);
 float side_mask=1.-smoothstep(.15,.3,abs(body_position.y));
 vec3 belly=vec3(.69,.74,.70);
 vec3 back=vec3(.045,.16,.20);
 if(species==2){back=vec3(.15,.23,.22);}
 if(species==3){belly=vec3(.78,.77,.22);back=vec3(.03,.44,.25);}
 if(species==5 || species==10){belly=vec3(.78,.47,.37);back=vec3(.36,.15,.12);}
 if(species==7){back=vec3(.035,.29,.36);}
 if(species==9){belly=vec3(.60,.66,.51);back=vec3(.16,.28,.18);}
 if(species==11 || species==12){belly=vec3(.60,.49,.30);back=vec3(.24,.24,.13);}
 if(species==13){back=vec3(.16,.25,.20);}
 vec3 skin=mix(belly,back,top);
 vec2 flank=vec2(body_position.z*26.,body_position.y*45.);
 float spots=speckles(flank);
 if(species==11){skin=mix(skin,vec3(.12,.35,.51),spots*.85);}
 if(species==12){
 float blotches=speckles(flank*.15);
 skin=mix(skin,vec3(.14,.12,.065),max(spots*.7,blotches*.55));
}
 if(species==2 || species==7 || species==3){skin=mix(skin,species==7 ? vec3(.025,.18,.4) : back*.45,spots*.65);}
 if(species==1){
  float stripes=pow(.5+.5*cos(body_position.y*79.),10.);
  skin=mix(skin,vec3(.11,.21,.23),stripes*(1.-top)*smoothstep(-.6,-.3,body_position.z)*.72);
 }
 if(species==4 || species==13 || species==14){
  float bars=pow(.5+.5*sin(body_position.z*32.+sin(body_position.y*15.)*.5),8.);
  skin*=1.-bars*top*.35;
 }
 if(species==0 || species==6){
 float band=exp(-pow((body_position.y-.015)*35.,2.));
 if(species==6) band+=exp(-pow((body_position.y-.09)*45.,2.));
 skin=mix(skin,vec3(.71,.62,.25),band*.65);
}
 float lateral=exp(-pow(body_position.y*140.,2.));
 skin*=1.-lateral*.1;
 float head=1.-smoothstep(-.85,-.48,body_position.z);
 float plate=1.-smoothstep(-.58,-.43,body_position.z+.10*pow(body_position.y/.3,2.));
 skin=mix(skin,mix(belly*.94,back,top),plate*.25);
 skin=mix(skin,mix(belly,back,top),head*.5);
 vec2 scales_uv=vec2(UV.y*115.,UV.x*55.);
 scales_uv.x+=step(.5,fract(scales_uv.y*.5))*.5;
 float scales=pow(max(0.,1.-length(fract(scales_uv)-.5)*2.),5.);
 float grain=hash(floor(UV*vec2(600.,350.)))-.5;
 skin+=scales*.018+grain*.012;
 ALBEDO=skin;
 METALLIC=.23;
 ROUGHNESS=.30+grain*.035-scales*.035;
 SPECULAR=.58;
}
