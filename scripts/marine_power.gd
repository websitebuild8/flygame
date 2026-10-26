extends RefCounted
static func color_for(value: float) -> Color:
	var power=absf(clampf(value,-1,1))
	if power<=.13:return Color("65e6a1")
	if power<.5:return Color("f2da62").lerp(Color("ffac42"),(power-.13)/.37)
	return Color("ffac42").lerp(Color("ff4d49"),(power-.5)/.5)
