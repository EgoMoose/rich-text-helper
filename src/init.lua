--!strict

local Primitives = require(script.Primitives)
local Extended = require(script.Extended)

export type ParsedRichText = Primitives.ParsedRichText

return {
	validate = Primitives.validate,

	parse = Primitives.parseSafe,
	write = Primitives.write,
	read = Primitives.read,

	concat = Extended.concat,
	slice = Extended.slice,
	tag = Extended.addRichTag,
}
