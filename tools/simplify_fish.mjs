// Build-time helper for prepare_trevally.py. meshoptimizer 1.3.0 (MIT).
import fs from 'node:fs';
import {pathToFileURL} from 'node:url';
const {MeshoptSimplifier:simplifier}=await import(pathToFileURL(process.argv[3]).href);
await simplifier.ready;
const folder=process.argv[2],g=JSON.parse(fs.readFileSync(folder+'/input.json')),bin=fs.readFileSync(folder+'/input.bin');
function read(i){const a=g.accessors[i],v=g.bufferViews[a.bufferView],n={VEC3:3,VEC2:2,SCALAR:1}[a.type],off=v.byteOffset+(a.byteOffset||0),Type=a.componentType===5126?Float32Array:Uint32Array;return new Type(bin.buffer.slice(bin.byteOffset+off,bin.byteOffset+off+a.count*n*4));}
const groups=new Map();
for(const p of g.meshes[0].primitives){
 if(!groups.has(p.material))groups.set(p.material,{pos:[],norm:[],uv:[],idx:[],weld:new Map()});
 const group=groups.get(p.material),pos=read(p.attributes.POSITION),norm=read(p.attributes.NORMAL),uv=read(p.attributes.TEXCOORD_0),idx=read(p.indices),remap=[];
 for(let i=0;i<pos.length/3;i++){
  const tuple=[...pos.slice(i*3,i*3+3),...norm.slice(i*3,i*3+3),...uv.slice(i*2,i*2+2)],key=tuple.join(',');
  if(!group.weld.has(key)){group.weld.set(key,group.pos.length/3);group.pos.push(...tuple.slice(0,3));group.norm.push(...tuple.slice(3,6));group.uv.push(...tuple.slice(6));}
  remap.push(group.weld.get(key));
 }
 for(const i of idx)group.idx.push(remap[i]);
}
const chunks=[],views=[],accessors=[];let size=0;
function buffer(payload){const pad=(4-size%4)%4;if(pad){chunks.push(Buffer.alloc(pad));size+=pad;}const i=views.length;views.push({buffer:0,byteOffset:size,byteLength:payload.length});chunks.push(payload);size+=payload.length;return i;}
function array(data,type,componentType){const a={bufferView:buffer(Buffer.from(data.buffer,data.byteOffset,data.byteLength)),componentType,count:data.length/({VEC3:3,VEC2:2,SCALAR:1}[type]),type};if(type==='VEC3'){a.min=[Infinity,Infinity,Infinity];a.max=[-Infinity,-Infinity,-Infinity];for(let i=0;i<data.length;i++){a.min[i%3]=Math.min(a.min[i%3],data[i]);a.max[i%3]=Math.max(a.max[i%3],data[i]);}}accessors.push(a);return accessors.length-1;}
const primitives=[];let total=0;
for(const [material,group]of groups){
 const pos=new Float32Array(group.pos),attributes=new Float32Array(pos.length/3*5);
 for(let i=0;i<pos.length/3;i++)attributes.set([...group.norm.slice(i*3,i*3+3),...group.uv.slice(i*2,i*2+2)],i*5);
 const target=Math.round(9800*group.idx.length/((483200-12)*3))*3;
 const [idx,error]=simplifier.simplifyWithAttributes(new Uint32Array(group.idx),pos,3,attributes,5,[.15,.15,.15,1,1],null,target,.025,['RegularizeLight']);
 const map=new Map(),p=[],n=[],u=[],indices=[];
 for(const i of idx){if(!map.has(i)){map.set(i,map.size);p.push(...group.pos.slice(i*3,i*3+3));n.push(...group.norm.slice(i*3,i*3+3));u.push(...group.uv.slice(i*2,i*2+2));}indices.push(map.get(i));}
 primitives.push({attributes:{POSITION:array(new Float32Array(p),'VEC3',5126),NORMAL:array(new Float32Array(n),'VEC3',5126),TEXCOORD_0:array(new Float32Array(u),'VEC2',5126)},indices:array(new Uint32Array(indices),'SCALAR',5125),material,mode:4});
 total+=idx.length/3;console.log(`Material ${material}: ${group.idx.length/3} -> ${idx.length/3} triangles, error ${error.toFixed(4)}`);
}
for(const image of g.images){const v=g.bufferViews[image.bufferView];image.bufferView=buffer(bin.subarray(v.byteOffset,v.byteOffset+v.byteLength));}
g.meshes=[{name:'GiantTrevallyMobile',primitives}];g.bufferViews=views;g.accessors=accessors;g.buffers=[{byteLength:size}];
let json=Buffer.from(JSON.stringify(g)),binary=Buffer.concat(chunks);json=Buffer.concat([json,Buffer.alloc((4-json.length%4)%4,32)]);binary=Buffer.concat([binary,Buffer.alloc((4-binary.length%4)%4)]);
const header=Buffer.alloc(20);header.writeUInt32LE(0x46546c67,0);header.writeUInt32LE(2,4);header.writeUInt32LE(28+json.length+binary.length,8);header.writeUInt32LE(json.length,12);header.writeUInt32LE(0x4e4f534a,16);const bh=Buffer.alloc(8);bh.writeUInt32LE(binary.length);bh.writeUInt32LE(0x004e4942,4);
fs.writeFileSync('assets/models/fish/trevally.glb',Buffer.concat([header,json,bh,binary]));console.log(`Total ${total} triangles, ${(binary.length/1048576).toFixed(2)} MiB`);
