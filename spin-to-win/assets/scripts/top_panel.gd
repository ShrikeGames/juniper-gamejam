extends Panel
class_name TopPanelCard

@export var top:Top
@export var textbox:RichTextLabel

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	var top_color_hex:String = top.colour.to_html()
	var top_name:String = top.top_name.substr(0, min(10, len(top.top_name)))
	var top_dex_stars:String = calculate_stars_string("Dexterity")
	var top_power_stars:String = calculate_stars_string("Power")
	var top_special_stars:String = calculate_stars_string("Special")
	textbox.text = "[color=%s]%s[/color]\n[color=green]%s DEX[/color]\n[color=red]%s PWR[/color]\n[color=blue]%s SPE[/color]"%[top_color_hex, top_name, top_dex_stars, top_power_stars, top_special_stars]

func calculate_stars_string(stat_name:String):
	var top_stars:String = ""
	for i in range(self.top.current_stats[stat_name]):
		top_stars += "★"
	for i in range(5-self.top.current_stats[stat_name]):
		top_stars += "☆"
	return top_stars
