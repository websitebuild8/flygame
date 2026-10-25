extends RefCounted
## Fictional MVR market balance; one immutable individual is rolled per cast.
static func roll(definition: Dictionary,rng: RandomNumberGenerator) -> Dictionary:
	var weight=snappedf(lerpf(float(definition.min),float(definition.max),pow(rng.randf(),1.65)),.1)
	var fraction=inverse_lerp(float(definition.min),float(definition.max),weight)
	var rate=float(definition.value)/lerpf(float(definition.min),float(definition.max),.4)
	var quality=rng.randf_range(.92,1.12)
	return {"species":str(definition.name),"weight":weight,"value":maxi(1,roundi(weight*rate*quality)),"rate":rate*quality,"size":lerpf(.72,1.25,fraction),"strength":float(definition.fight)*lerpf(.85,1.2,fraction),"grade":"TROPHY" if fraction>.85 else ("LARGE" if fraction>.6 else "FRESH CATCH")}
