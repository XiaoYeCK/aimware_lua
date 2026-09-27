RF=gui.Reference

gui.Button(RF("暴力", "常规"), "Botton Name", function()
 end)

gui.Checkbox(RF("暴力", "常规"), "checkbox_name", "Checkbox", true)

gui.ColorPicker(RF("暴力", "常规"), "colorpicker_name", "ColorPicker", 0, 0, 0, 0)

gui.Combobox(RF("暴力", "常规"), "combobox_name", "Combobox", "Op1", "Op2")

gui.Command("alias")

gui.Editbox(RF("暴力", "常规"), "editbox_name", "Editbox")

gui.Groupbox(RF("暴力"), "Groupbox", 450, 400, 100)

gui.Keybox(RF("暴力", "常规"), "keybox_name", "Keybox", 1)

gui.Listbox(RF("暴力", "常规"), "listbox", 200, "Item 1")

gui.Multibox(RF("暴力"), "Multibox")

gui.Slider(RF("暴力", "常规"), "slider_name", "Slider", 5.0, 0.0, 10.0, 0.01)

gui.Text(RF("暴力", "常规"), "Text")

-- cant work
gui.Tab(RF("暴力"), "tab_name", "Tab")