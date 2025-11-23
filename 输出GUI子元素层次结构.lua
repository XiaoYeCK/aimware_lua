local function PrintChildren(obj, prefix)
    print(prefix .. obj:GetName());
    for child in obj:Children() do
        PrintChildren(child, prefix .. "\t");
    end
end

PrintChildren(gui.Reference("MENU"), "");