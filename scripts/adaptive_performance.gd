extends RefCounted
## Samples actual rendered frame times; quality changes never alter fish-fight state.
var enabled=true
var scale=1.0
var ceiling=1.0
var target=60.0
var seconds=0.0
var frames=0
var slow_windows=0
var fast_windows=0
var warmup=4.0
var fps=0.0
func configure(quality: int):
 ceiling=[.60,.80,1.0][quality];scale=ceiling;target=30 if quality==0 else 60
 seconds=0;frames=0;slow_windows=0;fast_windows=0;warmup=4
func sample(delta: float,active: bool) -> bool:
 if not active or not enabled or delta<=0:return false
 if warmup>0:warmup-=delta;return false
 seconds+=delta;frames+=1
 if seconds<3:return false
 fps=frames/seconds;seconds=0;frames=0
 slow_windows=slow_windows+1 if fps<target*.80 else 0
 fast_windows=fast_windows+1 if fps>target*.95 else 0
 var before=scale
 if slow_windows>=2:scale=maxf(.45,scale-.05);slow_windows=0;fast_windows=0
 elif fast_windows>=4:scale=minf(ceiling,scale+.025);fast_windows=0
 return not is_equal_approx(before,scale)
