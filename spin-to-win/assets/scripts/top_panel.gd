extends Panel
class_name TopPanelCard

@export var top:Top
@export var textbox:RichTextLabel
@export var use_save:bool = false

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	if use_save:
		update(Global.game_state["stats"])
	else:
		update(top.current_stats)
	
func update(stats:Dictionary):
	var top_color_hex:String = top.colour.to_html()
	var top_name:String = top.top_name.substr(0, min(10, len(top.top_name)))
	var top_dex_stars:String = calculate_stars_string("Dexterity", stats)
	var top_power_stars:String = calculate_stars_string("Power", stats)
	var top_special_stars:String = calculate_stars_string("Special", stats)
	var ult_name:String = Global.ult_names[stats["Ult"]]
	var win_count:String =""
	if not top.ai_controlled:
		win_count = "(%d wins)"%[stats["wins"]]
	textbox.text = "[color=%s]%s[/color]%s\n[color=green]%s DEX[/color]\n[color=red]%s PWR[/color]\n[color=blue]%s SPE[/color]\n[color=orange]%s[/color]"%[top_color_hex, top_name, win_count, top_dex_stars, top_power_stars, top_special_stars, ult_name]
	
func calculate_stars_string(stat_name:String, stats:Dictionary):
	var top_stars:String = ""
	if self.top and not self.top.ai_controlled and not self.top.current_stats.get(stat_name):
		self.top.update_based_on_stats(stats)
	
	for i in range(min(5, self.top.current_stats[stat_name])):
		top_stars += "★"
	for i in range(5-min(5, self.top.current_stats[stat_name])):
		top_stars += "☆"
	return top_stars
