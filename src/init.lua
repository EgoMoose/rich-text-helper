--!strict

local Primitives = require(script:WaitForChild("Primitives"))
local Extended = require(script:WaitForChild("Extended"))

export type ParsedRichText = Primitives.ParsedRichText

return {
	validate = Primitives.validate,

	parse = Primitives.parseSafe,
	write = Primitives.write,
	read = Primitives.read,

	concat = Extended.concat,
	slice = Extended.slice,
	tag = Extended.addTag,
}
