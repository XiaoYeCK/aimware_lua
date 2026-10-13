RF = gui.Reference

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

function NonASCII(str)
    for i = 1, #str do
        byteVal = string.byte(str, i)
        if byteVal > 127 then
            return true
        end
    end
    return false
end

function CheckTranslated()
    return NonASCII(DumpGUI())
end

if CheckTranslated() then
    translated = true
    print("[CheckTranslated] true")
else
    translated = false
    print("[CheckTranslated] false")
end

function TranslatedOutput(chinese, english)
    local text = translated and chinese or english
    local results = {}

    for value in string.gmatch(text, "([^,]+)") do
        value = string.gsub(value, "^%s+", "")
        value = string.gsub(value, "%s+$", "")

        value = string.gsub(value, "^'", "")
        value = string.gsub(value, "'$", "")

        table.insert(results, value)
    end

    return unpack(results)
end

BaseRF = RF(
    TranslatedOutput("'杂项', '功能'", "'Miscellaneous', 'Features'")
)