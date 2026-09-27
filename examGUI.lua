RF=gui.Reference

gui.Button(RF("杂项", "功能"), "Botton Name", function()
 end)

gui.Checkbox(RF("杂项", "功能"), "checkbox_name", "Checkbox", true)

gui.ColorPicker(RF("杂项", "功能"), "colorpicker_name", "ColorPicker", 0, 0, 0, 0)

gui.Combobox(RF("杂项", "功能"), "combobox_name", "Combobox", "Op1", "Op2")

gui.Command("alias")

gui.Editbox(RF("杂项", "功能"), "editbox_name", "Editbox")

gui.Keybox(RF("杂项", "功能"), "keybox_name", "Keybox", 1)

gui.Listbox(RF("杂项", "功能"), "listbox", 200, "Item 1")

gui.Multibox(RF("杂项", "功能"), "Multibox")
gui.Checkbox(RF("杂项", "功能", "Multibox"), "checkbox_name", "Checkbox1", true)
gui.Checkbox(RF("杂项", "功能", "Multibox"), "checkbox_name", "Checkbox2", false)

gui.Slider(RF("杂项", "功能"), "slider_name", "Slider", 5.0, 0.0, 10.0, 0.01)

gui.Text(RF("杂项", "功能"), "Text")