@tool
class_name RichTextTorch
extends RichTextEffect

# Usage: [torch speed=8 width=4 len=24]text[/torch]
var bbcode := "torch"

const BASE_GLOW := Color(2.5, 1.8, 0.8) # values above 1.0 = HDR "overbright"

func _process_custom_fx(c: CharFXTransform) -> bool:
	var speed: float = c.env.get("speed", 8.0)   # chars per second
	var width: float = c.env.get("width", 4.0)   # size of the torch light
	var length: float = c.env.get("len", 20.0)   # number of chars in the tagged text

	# Torch position travels along the text, then loops with a gap
	var cycle := length + width * 2.0
	var torch_pos := fmod(c.elapsed_time * speed, cycle) - width

	# 1 at the torch center, 0 outside its width
	var d: float = abs(float(c.relative_index) - torch_pos)
	var k: float = clamp(1.0 - d / width, 0.0, 1.0)
	k *= k # softer falloff

	# Flicker like fire
	var flicker := 0.85 + 0.15 * sin(c.elapsed_time * 30.0 + c.relative_index)

	c.color = c.color.lerp(BASE_GLOW, k * flicker)
	c.offset.y -= k * 5.0 # lit letters lift slightly
	return true
