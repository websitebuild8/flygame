extends SceneTree
var taps=0
func _initialize():call_deferred("checks")
func mouse(point: Vector2,pressed: bool):
 var event=InputEventMouseButton.new();event.position=point;event.global_position=point;event.button_index=MOUSE_BUTTON_LEFT;event.pressed=pressed;root.push_input(event,true)
func motion(point: Vector2):
 var event=InputEventMouseMotion.new();event.position=point;event.global_position=point;event.button_mask=MOUSE_BUTTON_MASK_LEFT;root.push_input(event,true)
func checks():
 var scroll=preload("res://scripts/club_scroll.gd").new();root.add_child(scroll);scroll.position=Vector2(20,20);scroll.size=Vector2(600,320)
 var content=VBoxContainer.new();content.size_flags_horizontal=Control.SIZE_EXPAND_FILL;scroll.add_child(content)
 for i in range(12):
  var button=Button.new();button.text="Card %d"%i;button.custom_minimum_size.y=90;button.pressed.connect(func():taps+=1);content.add_child(button)
 await process_frame;await process_frame
 assert(scroll.limit()>600,"Cards actually overflow")
 # Real viewport dispatch: begin over a button, drag vertically, then release.
 motion(Vector2(120,180));mouse(Vector2(120,180),true);await process_frame
 motion(Vector2(120,100));await process_frame;motion(Vector2(120,50));await process_frame;mouse(Vector2(120,50),false);await process_frame
 assert(scroll.scroll_vertical>100 and taps==0,"Dragging over a card scrolls without activating its button")
 var before=scroll.get_v_scroll_bar().value;scroll._process(.08);assert(scroll.get_v_scroll_bar().value>before,"Release continues with momentum")
 for i in range(150):scroll._process(.016)
 assert(scroll.get_v_scroll_bar().value<=scroll.limit() and absf(scroll.velocity)<8,"Inertia decelerates and stays inside content bounds")
 scroll.reset_to(0);await process_frame;await create_timer(.25).timeout
 motion(Vector2(120,60));mouse(Vector2(120,60),true);mouse(Vector2(120,60),false);await process_frame
 assert(taps==1,"A deliberate tap still activates its card button")
 scroll.wheel(160);assert(scroll.scroll_vertical==0,"Wheel scroll starts smoothly instead of jumping")
 for i in range(40):scroll._process(.016)
 assert(absf(scroll.scroll_vertical-160)<2,"Wheel animation reaches its accumulated target")
 scroll.reset_to(0);await process_frame
 scroll.begin(2,Vector2(100,200));scroll.move(Vector2(100,190));scroll.move(Vector2(100,100));scroll.end();assert(scroll.scroll_vertical>70 and not scroll.accepts_tap(),"Touch swipes suppress card taps")
 scroll.velocity=1200;scroll.visible=false;scroll._process(.05);assert(scroll.pointer==-99 and scroll.velocity==0,"Hiding cancels pointers and momentum")
 scroll.queue_free();await process_frame
 var game=load("res://scenes/main.tscn").instantiate();game.save_path="user://club-scroll.json";root.add_child(game);game.set_physics_process(false);game.set_process(false);game.interface.start_trip()
 var book=game.interface.logbook;book.open("Spots");await process_frame;await process_frame;book.scroll.set_value(240);var saved=book.scroll.scroll_vertical;assert(saved>0)
 book.show_tab("Daily");await process_frame;await process_frame;book.show_tab("Spots");await process_frame;await process_frame
 assert(absf(book.scroll.scroll_vertical-saved)<2,"Switching tabs restores the prior list position")
 book.event_details("lagoon");await process_frame;await process_frame;assert(book.scroll.scroll_vertical==0,"Challenge detail opens at the top")
 book.show_tab("Spots");await process_frame;await process_frame;assert(absf(book.scroll.scroll_vertical-saved)<2,"Back from details returns to the prior list position")
 game.queue_free();await create_timer(.2).timeout
 print("PASS: card/button drag cancellation, mouse and touch swipes, decaying inertia, smooth wheel targets, limits/hide cancellation and remembered Club list positions")
 quit()
