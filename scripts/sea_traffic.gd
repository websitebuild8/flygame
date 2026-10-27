extends Node3D
const World=preload("res://scripts/world_data.gd")
const Collision=preload("res://scripts/marine_collision.gd")
var game: Node3D
var actors: Array[Dictionary]=[]
var planner=preload("res://scripts/sea_navigation.gd").new()
var random=RandomNumberGenerator.new()
var owners: Dictionary={}
var elapsed=0.0
func configure(owner_game: Node3D) -> void:
 game=owner_game;random.randomize();planner.configure(true)
 var ports=World.Harbours.all_ports()
 for i in range(6):
  var port=ports[0 if i<2 else i-1];var start=port.dock+port.along*(4 if i%2 else -3)
  if i==0:start=World.Harbours.local_point(port,-port.depth-25,0)
  var node=preload("res://scripts/traffic_boat.gd").new();node.design=i;add_child(node)
  var actor={"id":i,"node":node,"position":start,"heading":0.0,"speed":0.0,"cruise":random.randf_range(4,8),"radius":1.3 if i in [1,4] else (.95 if i%3!=2 else 1.25),"path":PackedVector2Array(),"waypoint":1,"target":"","wait":float(i%3)*3,"stuck":0.0}
  actors.append(actor)
  var target=ports[0] if i==0 else ports[(i+1)%ports.size()]
  route_to(actor,target)
  node.position=Vector3(start.x,game.surface.height(start)-game.surface.BASE,start.y)
func route_to(actor: Dictionary,port: Dictionary) -> bool:
 var target=port.dock+port.along*(-5 if actor.id%2==0 else 5)
 if not planner.set_destination(actor.position,target,port.name):
  actor.wait=10;return false
 actor.path=planner.route.duplicate();actor.waypoint=1;actor.target=port.name
 if actor.path.size()>1:
  var d=actor.path[1]-actor.position;actor.heading=atan2(-d.x,-d.y)
 return true
func update(delta: float,active: bool) -> void:
 visible=active
 if not active:return
 elapsed+=delta
 var player=Vector2(game.boat.position.x,game.boat.position.z)
 # One NPC at a time reserves a harbour mouth. Departing boats get priority.
 for port in World.Harbours.all_ports():
  var owner=int(owners.get(port.name,-1));var keep=false
  if owner>=0 and owner<actors.size():keep=actors[owner].wait<=0 and actors[owner].position.distance_to(port.entrance)<7
  if not keep:
   owner=-1
   for actor in actors:
    if actor.wait<=0 and Geometry2D.is_point_in_polygon(actor.position,port.polygon):owner=actor.id;break
   if owner<0:
    for actor in actors:
     if actor.wait<=0 and actor.target==port.name and actor.position.distance_to(port.entrance)<18:owner=actor.id;break
  owners[port.name]=owner
 for actor in actors:
  if actor.wait>0:
   actor.wait=maxf(0,actor.wait-delta);actor.speed=move_toward(actor.speed,0,delta*4)
   if actor.wait==0 and actor.waypoint>=actor.path.size():
    var ports=World.Harbours.all_ports();var choice=ports[random.randi_range(0,ports.size()-1)]
    if choice.name==actor.target:choice=ports[(ports.find(choice)+1)%ports.size()]
    route_to(actor,choice)
   continue
  if actor.path.is_empty():route_to(actor,World.Harbours.get_port("HA. Kelaa"));continue
  if actor.waypoint>=actor.path.size():actor.wait=random.randf_range(10,22);continue
  var at: Vector2=actor.position;var target: Vector2=actor.path[actor.waypoint]
  if at.distance_to(target)<(1.0 if actor.waypoint==actor.path.size()-1 else 1.9):actor.waypoint+=1;continue
  var direction=(target-at).normalized();var right=Vector2(-direction.y,direction.x)
  var aim=target+right*(.65 if not World.Harbours.containing(at).is_empty() else 1.3)
  if not World.water(aim,true,actor.radius):aim=target
  var desired=atan2(-(aim-at).x,-(aim-at).y);actor.heading=lerp_angle(actor.heading,desired,1-exp(-delta*3))
  var forward=Vector2(-sin(actor.heading),-cos(actor.heading))
  var in_port=World.Harbours.containing(at);var speed=2.0 if not in_port.is_empty() else float(actor.cruise)
  if absf(wrapf(desired-actor.heading,-PI,PI))>.55:speed*=.35
  var destination=World.Harbours.get_port(actor.target)
  if at.distance_to(destination.entrance)<14 and in_port.is_empty() and int(owners.get(actor.target,-1))!=actor.id:speed=0
  if Collision.sweeps_circle(at,at+forward*maxf(3,actor.speed*1.2),player,actor.radius+World.BOAT_CLEARANCE+1):speed=0
  for other in actors:
   if other.id==actor.id:continue
   if at.distance_to(other.position)<actor.radius+other.radius+.3:speed=0
   elif other.id<actor.id and Collision.sweeps_circle(at,at+forward*4,other.position,actor.radius+other.radius+.35):speed=0
  actor.speed=move_toward(actor.speed,speed,delta*(3.5 if speed<actor.speed else 1.2))
  var next=at+forward*actor.speed*delta
  var blocked=not Collision.clear_water(at,next,true,actor.radius)
  for other in actors:
   if other.id!=actor.id and Collision.sweeps_circle(at,next,other.position,actor.radius+other.radius):blocked=true
  if Collision.sweeps_circle(at,next,player,actor.radius+World.BOAT_CLEARANCE):blocked=true
  if not blocked:actor.position=next;actor.stuck=0
  else:
   actor.speed=0;actor.heading=desired;actor.stuck+=delta
   if actor.stuck>6:
    planner.set_destination(at,target,"Clear obstruction");actor.stuck=0
 for actor in actors:pose(actor)
func pose(actor: Dictionary):
 actor.node.position=Vector3(actor.position.x,game.surface.height(actor.position)-game.surface.BASE,actor.position.y)
 actor.node.rotation.y=actor.heading
 if not actor.node.imported_id.is_empty():preload("res://scripts/outboard_waterline.gd").update(actor.node.hull,game.surface)
 actor.node.set_speed(actor.speed)
func motion_blocked(from: Vector2,to: Vector2,radius: float) -> bool:
 for actor in actors:
  if Collision.sweeps_circle(from,to,actor.position,radius+actor.radius):return true
 return false
