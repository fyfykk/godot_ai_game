extends Node

var UIFontScript := preload("res://scripts/ui/UIFont.gd")

func _enter_tree():
	var tree := get_tree()
	if tree:
		tree.node_added.connect(_on_node_added)
		UIFontScript.apply_tree(tree.get_root())

func _on_node_added(node: Node):
	if node is Control:
		UIFontScript.apply_control(node as Control)
