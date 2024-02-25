--!strict

local RichTextTypes = require(script:WaitForChild("RichTextTypes.d"))

export type ParsedRichText = RichTextTypes.ParsedRichText

local parse = require(script:WaitForChild("Parse"))
local write = require(script:WaitForChild("Write"))
local read = require(script:WaitForChild("Read"))

-- Private

local function readRaw(richText: string)
	local label = Instance.new("TextLabel")
	label.RichText = true
	label.Text = richText

	local result = label.ContentText
	label:Destroy()
	return result
end

-- Public

local function validate(richText: string, parsed: ParsedRichText): boolean
	local isMatch = false

	local plainRaw = readRaw(richText)
	local success = pcall(function()
		local plain = read(parsed)

		if plain == plainRaw then
			isMatch = true
		end
	end)

	return success and isMatch
end

local function quickValidate(richText: string): boolean
	local parsed
	local success = pcall(function()
		parsed = parse(richText)
	end)

	return success and validate(richText, parsed)
end

local function parseSafe(richText: string): ParsedRichText
	local parsed
	local success = pcall(function()
		parsed = parse(richText)
	end)

	local isValid = success and validate(richText, parsed)
	assert(isValid, "Parse Error: Invalid rich text provided.")

	return parsed
end

--

return {
	validate = quickValidate,

	parse = parse,
	parseSafe = parseSafe,

	write = write,
	read = read,
}
