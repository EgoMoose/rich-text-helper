--!strict

local Package = script.Parent.Parent
local Primitives = require(Package.Primitives)

type ParsedRichText = Primitives.ParsedRichText

-- Public

local function concat(parsedArray: { ParsedRichText }, richSeparator: string): ParsedRichText
	assert(Primitives.validate(richSeparator), "Concat Error: Invalid rich text separator provided.")

	local written = {}
	for i, parsed in parsedArray do
		written[i] = Primitives.write(parsed)
	end

	return Primitives.parse(table.concat(written, richSeparator))
end

--

return concat
