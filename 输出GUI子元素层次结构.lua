function DumpGUI()
    output = ""

    function traverse(obj, prefix)
        output = output .. prefix .. obj:GetName() .. "\n"
        for child in obj:Children() do
            traverse(child, prefix .. "\t")
        end
    end

    traverse(RF(), "")

    return output
end

file.Write("EN_Lang.txt", DumpGUI())
