--!strict

local Package = script.Parent.Parent
local Primitives = require(Package:WaitForChild("Primitives"))

local Packages = Package.Parent
local Sift = require(Packages:WaitForChild("Sift"))

type ParsedRichText = Primitives.ParsedRichText

-- Public

local function slice(parsed: ParsedRichText, from: number?, to: number?): ParsedRichText
	local length = #parsed.characters
	local fromTarget = if not from or from == 0 then 1 else from
	local toTarget = if not to then length elseif to < 0 then length + to + 1 else to

	local characters = {}
	for i = fromTarget, toTarget do
		local richCharacter = parsed.characters[i]
		table.insert(characters, Sift.Dictionary.copyDeep(richCharacter))
	end

	local comments = {}
	for _, richComment in parsed.comments do
		if richComment.index >= fromTarget and richComment.index <= toTarget then
			table.insert(comments, {
				index = richComment.index - fromTarget + 1,
				text = richComment.text,
			})
		end
	end

	return {
		characters = characters,
		comments = comments,
	}
end

--

return slice
