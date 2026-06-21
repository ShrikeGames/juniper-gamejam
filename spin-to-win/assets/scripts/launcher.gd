extends Node3D
class_name Launcher

@onready var crank:Node3D = $Crank
@onready var crank_base:MeshInstance3D = $Crank/CrankBase
@onready var crank_rod:MeshInstance3D = $Crank/CrankRod
@onready var crank_top_holder:MeshInstance3D = $Crank/CrankTopHolder
@onready var crank_top_spot:Node3D = $Crank/CrankTopSpot
