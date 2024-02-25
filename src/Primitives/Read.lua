--!strict

local RichTextTypes = require(script.Parent:WaitForChild("RichTextTypes.d"))

type ParsedRichText = RichTextTypes.ParsedRichText

local ESCAPE_FORMS: { [string]: string } = {
	["&lt;"] = "<",
	["&gt;"] = ">",
	["&quot;"] = '"',
	["&apos;"] = "'",
	["&amp;"] = "&",
}

-- Public

local function read(parsed: ParsedRichText): string
	local result = ""
	for _, richCharacter in parsed.characters do
		result = result .. richCharacter.character
	end

	for escape, replacement in ESCAPE_FORMS do
		result = result:gsub(escape, replacement)
	end

	return result
end

--

return read
