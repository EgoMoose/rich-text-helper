--!strict

local Package = script.Parent.Parent
local Primitives = require(Package:WaitForChild("Primitives"))

local Packages = Package.Parent
local Sift = require(Packages:WaitForChild("Sift"))

type ParsedRichText = Primitives.ParsedRichText

-- Public

local function addTag(parsed: ParsedRichText, tag: string): ParsedRichText
	local parsedClone = Sift.Dictionary.copyDeep(parsed)

	local parsedTag = Primitives.parseSafe(tag)
	local richCharacterTag = parsedTag.characters[1]

	for _, richCharacter in parsedClone.characters do
		richCharacter.properties = Sift.Dictionary.mergeDeep(richCharacter.properties, richCharacterTag.properties)
	end

	return Primitives.parseSafe(Primitives.write(parsedClone))
end

--

return addTag
