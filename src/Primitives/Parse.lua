--!strict

local RichTextTypes = require(script.Parent["RichTextTypes.d"])

type ParsedRichText = RichTextTypes.ParsedRichText
type RichProperties = RichTextTypes.RichProperties
type RichCharacter = RichTextTypes.RichCharacter
type RichComment = RichTextTypes.RichComment

-- Tag definitions

type TagDefinition = {
	identifier: string,
	transformers: {
		[any]: (string, ParseState) -> any,
	},
}

local NIL_VALUE = newproxy()
local COMMENT_IDENTIFIER = "^!--.*--"

local TAG_DEFINITIONS: { [string]: { TagDefinition } } = {
	["font"] = {
		{
			identifier = "font",
			transformers = {
				["color"] = function(input: string)
					if input:sub(1, 3) == "rgb" then
						local r, g, b = input:match("%s*(%d+)%s*,%s*(%d+)%s*,%s*(%d+)%s*")
						return Color3.fromRGB(tonumber(r), tonumber(g), tonumber(b))
					elseif input:sub(1, 1) == "#" and #input == 7 then
						return Color3.fromHex(input:sub(2))
					end
					return nil
				end,
				["size"] = function(input: string)
					return tonumber(input)
				end,
				["face"] = function(input: string)
					return input
				end,
				["features"] = function(input: string)
					local features = input:split(",")
					table.sort(features)
					return table.concat(features, ",")
				end,
				["family"] = function(input: string)
					return input
				end,
				["weight"] = function(input: string)
					return tonumber(input) or input
				end,
				["transparency"] = function(input: string)
					return tonumber(input)
				end,
			},
		},
	},
	["stroke"] = {
		{
			identifier = "stroke",
			transformers = {
				["color"] = function(input: string)
					if input:sub(1, 3) == "rgb" then
						local r, g, b = input:match("%s*(%d+)%s*,%s*(%d+)%s*,%s*(%d+)%s*")
						return Color3.fromRGB(tonumber(r), tonumber(g), tonumber(b))
					elseif input:sub(1, 1) == "#" and #input == 7 then
						return Color3.fromHex(input:sub(2))
					end
					return nil
				end,
				["joins"] = function(input: string)
					return input
				end,
				["thickness"] = function(input: string)
					return tonumber(input)
				end,
				["transparency"] = function(input: string)
					return tonumber(input)
				end,
			},
		},
	},
	["bold"] = {
		{
			identifier = "b",
			transformers = {},
		},
	},
	["italic"] = {
		{
			identifier = "i",
			transformers = {},
		},
	},
	["underline"] = {
		{
			identifier = "u",
			transformers = {},
		},
	},
	["strikethrough"] = {
		{
			identifier = "s",
			transformers = {},
		},
	},
	["uppercase"] = {
		{
			identifier = "uppercase",
			transformers = {},
		},
		{
			identifier = "uc",
			transformers = {},
		},
	},
	["smallcaps"] = {
		{
			identifier = "smallcaps",
			transformers = {},
		},
		{
			identifier = "sc",
			transformers = {},
		},
	},
}

-- Private

type FlatProperty = {
	path: { string },
	value: any,
}

type RichTag = {
	name: string,
	flatProperties: { FlatProperty },
}

type ParseState = {
	index: number,
	richText: string,
	openRichTags: { RichTag },
	richCharacters: { RichCharacter },
	richComments: { RichComment },
}

local function addCharacters(state: ParseState, from: number, to: number)
	for i = from, to do
		local character = string.sub(state.richText, i, i)

		local properties: any = {}
		local processedTagsOnCharacter: { [string]: boolean } = {}

		for j = #state.openRichTags, 1, -1 do
			local openTag = state.openRichTags[j]

			for _, node in openTag.flatProperties do
				local hashed = table.concat(node.path, "/")

				if not processedTagsOnCharacter[hashed] then
					local transformedValue = node.value
					if node.value == NIL_VALUE then
						transformedValue = nil
					end

					local parent = properties
					for i = 1, #node.path - 1 do
						local step = node.path[i]

						if not parent[step] then
							parent[step] = {}
						end

						parent = parent[step]
					end

					parent[node.path[#node.path]] = transformedValue
					processedTagsOnCharacter[hashed] = true
				end
			end
		end

		table.insert(state.richCharacters, {
			character = character,
			properties = properties :: RichProperties,
		})
	end
end

local function processComment(state: ParseState, tagNoBrackets: string)
	if tagNoBrackets:match(COMMENT_IDENTIFIER) == tagNoBrackets then
		table.insert(state.richComments, {
			index = #state.richCharacters + 1,
			text = tagNoBrackets:sub(4, -3),
		})

		return true
	end

	return false
end

local function processTag(state: ParseState, tag: string)
	local tagNoBrackets = string.gsub(
		string.gsub(string.sub(tag, 2, -2), '%b""', function(matched)
			return string.gsub(matched, "%s+", "")
		end),
		"%b''",
		function(matched)
			return string.gsub(matched, "%s+", "")
		end
	)

	local tagNoBracketsFirstWord = string.match(tagNoBrackets, "^[^%s]+")
	local tagNoBracketsNoWhitespace = string.gsub(tagNoBrackets, "%s", "")

	local isComment = processComment(state, tagNoBrackets)
	if isComment then
		return true
	end

	for definitionType, definitions in TAG_DEFINITIONS do
		for _, definition in definitions do
			if tagNoBracketsFirstWord then
				local isMatchClosed = tagNoBracketsNoWhitespace == ("/" .. definition.identifier)
				local isMatchOpen = #tagNoBracketsFirstWord == #definition.identifier
					and string.sub(tagNoBracketsFirstWord, 1, #definition.identifier) == definition.identifier

				if isMatchOpen then
					local splitTag = {}
					for _, text in string.split(string.gsub(tagNoBrackets, "%s+", " "), " ") do
						table.insert(splitTag, text)
					end

					table.remove(splitTag, 1)

					local flatProperties: { FlatProperty } = {}
					for _, text in splitTag do
						local property, valueWithQuotes = string.match(text, '([^=]+)=(%b"")')
						if not (property and valueWithQuotes) then
							property, valueWithQuotes = string.match(text, "([^=]+)=(%b'')")
						end

						if property and valueWithQuotes then
							local noQuotes = string.sub(valueWithQuotes, 2, -2)
							local transformer = definition.transformers and definition.transformers[property]

							assert(
								transformer,
								("No property transformer exists for %s:%s:%s"):format(
									definitionType,
									definition.identifier,
									property
								)
							)

							local transformedValue = transformer(noQuotes, state)
							if transformedValue == nil then
								transformedValue = NIL_VALUE
							end

							table.insert(flatProperties, {
								path = { definitionType, property },
								value = transformedValue,
							})
						end
					end

					if #flatProperties == 0 then
						table.insert(flatProperties, {
							path = { definitionType },
							value = true,
						})
					else
						table.insert(flatProperties, 1, {
							path = { definitionType },
							value = {},
						})
					end

					table.insert(state.openRichTags, {
						name = definitionType,
						flatProperties = flatProperties,
					})

					return true
				elseif isMatchClosed then
					for i = #state.openRichTags, 1, -1 do
						if state.openRichTags[i].name == definitionType then
							table.remove(state.openRichTags, i)
							break
						end
					end

					return true
				end
			end
		end
	end
	return false
end

-- Public

local function parse(richText: string): ParsedRichText
	richText = string.gsub(richText, "<br%s*/>", "\n")

	local state: ParseState = {
		index = 1,
		richText = richText,
		openRichTags = {},
		richCharacters = {},
		richComments = {},
	}

	while state.index <= #richText do
		local from, to = string.find(richText, "%b<>", state.index)

		if from and to then
			addCharacters(state, state.index, from - 1)

			local tag = string.sub(richText, from, to)
			local success = processTag(state, tag)

			if not success then
				error(`Unable to process the following tag: {tag}`)
			end

			state.index = to + 1
		else
			addCharacters(state, state.index, #richText)
			break
		end
	end

	return {
		characters = state.richCharacters,
		comments = state.richComments,
	}
end

return parse
