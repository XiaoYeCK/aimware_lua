GUIRef = gui.Reference

function ExPrint(...)
    gui.SetValue("misc.master", true)
    gui.SetValue("misc.log.console", true)
    print(... .. "\n")
end

function DumpGUI()
    output = ""

    function traverse(obj, prefix)
        output = output .. prefix .. obj:GetName() .. "\n"
        for child in obj:Children() do
            traverse(child, prefix .. "\t")
        end
    end

    traverse(GUIRef(), "")

    return output
end

function CheckASCII(str)
    for i = 1, #str do
        byteVal = string.byte(str, i)
        if byteVal > 127 then
            return true
        end
    end
    return false
end

function CheckTranslated()
    return CheckASCII(DumpGUI())
end

if CheckTranslated() then
    translated = true
    print("[CheckTranslated] true")
else
    translated = false
    print("[CheckTranslated] false")
end

-- Select Localized Args
function SLA(chinese, english)
    local results = translated and chinese or english
    return (table.unpack or unpack)(results)
end

BaseRef = GUIRef(
    SLA(
        {"杂项", "功能"},
        {"Miscellaneous", "Features"}
    )
)

print(SLA({"中文"}, {"English"}))