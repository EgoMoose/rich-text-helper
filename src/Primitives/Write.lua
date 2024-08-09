--!strict

local Packages = script.Parent.Parent.Parent
local Sift = require(Packages.Sift)

local RichTextTypes = require(script.Parent["RichTextTypes.d"])

type ParsedRichText = RichTextTypes.ParsedRichText
type RichProperties = RichTextTypes.RichProperties
type RichCharacter = RichTextTypes.RichCharacter

local EMPTY_RICH_CHARACTER: RichCharacter = {
	character = "",
	properties = {},
}

local EMPTY_TAG_LENGTH: TagLength = {
	count = 0,
	maxCount = 0,
}

local TAG_IDENTIFIERS: { [string]: string } = {
	["font"] = "font",
	["stroke"] = "stroke",
	["bold"] = "b",
	["italic"] = "i",
	["underline"] = "u",
	["strikethrough"] = "s",
	["uppercase"] = "uc",
	["smallcaps"] = "sc",
}

-- Private

local function followPath(t: any, path: { any }): any
	for _, key in path do
		if not t then
			break
		end
		t = t[key]
	end
	return t
end

local function flatten(unflattened: RichProperties): { [string]: any }
	assert(typeof(unflattened) == "table", "unflattened argument is not a table")

	local flattend = {}

	local queue = { {
		dict = unflattened,
		path = {},
	} }

	while #queue > 0 do
		local pop = table.remove(queue) :: any

		for key, value in pairs(pop.dict) do
			local path = Sift.Array.concat(pop.path, { key })

			if type(value) == "table" then
				table.insert(queue, {
					dict = value,
					path = path,
				})
			else
				local hash = table.concat(path, "/")
				flattend[hash] = value
			end
		end
	end

	return flattend
end

type TagLength = {
	count: number,
	maxCount: number,
}

local function getTagLengths(parsed: ParsedRichText, from: number, to: number): { { [string]: TagLength } }
	local counts: { [string]: number } = {}
	local prevFlat = flatten(parsed.characters[to].properties)

	local byIndexHashToCounts = {}

	for i = to, from, -1 do
		local richCharacter = parsed.characters[i]
		local currentFlat = flatten(richCharacter.properties)

		for hash, prevValue in prevFlat do
			local currentValue = currentFlat[hash]
			if currentValue == prevValue then
				counts[hash] = (counts[hash] or 0) + 1
			else
				counts[hash] = nil
			end
		end

		for hash, _ in currentFlat do
			if not counts[hash] then
				counts[hash] = 1
			end
		end

		byIndexHashToCounts[i - from + 1] = table.clone(counts)
		prevFlat = currentFlat
	end

	local byIndex = {}
	local hashMaxCount = {}
	for i, hashToCounts in byIndexHashToCounts do
		byIndex[i] = {}

		for hash, count in hashToCounts do
			local prevHashToCounts: { [string]: number } = byIndexHashToCounts[i - 1] or {}
			local prevCount = prevHashToCounts[hash] or -1

			local maxCount = count
			if prevCount == count + 1 then
				maxCount = hashMaxCount[hash]
			end

			byIndex[i][hash] = {
				count = count,
				maxCount = maxCount,
			}

			hashMaxCount[hash] = maxCount
		end
	end

	return byIndex
end

local function identifyTagsFromHashCounts(
	richCharacter: RichCharacter,
	reverse: boolean,
	callback: ((string, TagLength) -> ()) -> ()
)
	local identified = {}
	local function mark(hash: string, tagLength: TagLength)
		local path = string.split(hash, "/")
		local step = path[1]

		if not identified[step] then
			identified[step] = {}
		end

		if not identified[step][tagLength.count] then
			identified[step][tagLength.count] = {}
		end

		if not identified[step][tagLength.count][tagLength.maxCount] then
			identified[step][tagLength.count][tagLength.maxCount] = {}
		end

		table.insert(identified[step][tagLength.count][tagLength.maxCount], hash)
	end

	callback(mark)

	local function compare(a: any, b: any): boolean
		if reverse then
			return a < b
		end
		return a > b
	end

	local sorted = {}
	for step, countToMaxCountsToHashes in identified do
		for count, maxCountsToHashes in countToMaxCountsToHashes do
			for maxCount, hashes in maxCountsToHashes do
				table.insert(sorted, {
					step = step,
					count = count,
					maxCount = maxCount,
					hashes = hashes,
				})
			end
		end

		table.sort(sorted, function(a, b)
			if a.maxCount == b.maxCount then
				if a.count == b.count then
					return compare(a.step, b.step)
				end
				return compare(a.count, b.count)
			end
			return compare(a.maxCount, b.maxCount)
		end)
	end

	local merged = {}
	for _, countAndHash in sorted do
		local tag = {
			identifier = TAG_IDENTIFIERS[countAndHash.step],
			properties = {},
		}

		for _, hash in countAndHash.hashes do
			local path = string.split(hash, "/")
			if #path > 1 then
				local value = followPath(richCharacter.properties, path)
				table.remove(path, 1)
				local property = table.concat(path, "/")

				tag.properties[property] = value
			end
		end

		table.insert(merged, tag)
	end

	return merged
end

-- Public

local function write(parsed: ParsedRichText, from: number?, to: number?): string
	local result = ""

	local length = #parsed.characters
	local fromTarget = if not from or from == 0 then 1 else from
	local toTarget = if not to then length elseif to < 0 then length + to + 1 else to

	local richCommentsByIndex = {}
	for _, richComment in parsed.comments do
		if not richCommentsByIndex[richComment.index] then
			richCommentsByIndex[richComment.index] = {}
		end
		table.insert(richCommentsByIndex[richComment.index], richComment.text)
	end

	if length > 0 and fromTarget <= toTarget then
		local prevTagLengths: { [string]: TagLength } = {}
		local tagLengthsByIndex = getTagLengths(parsed, fromTarget, toTarget)

		for i = fromTarget, toTarget do
			local richCharacter = parsed.characters[i]
			local currentTagLengths = tagLengthsByIndex[i - fromTarget + 1]

			local removeTags = identifyTagsFromHashCounts(richCharacter, true, function(mark)
				for hash, prev in prevTagLengths do
					local current = currentTagLengths[hash]
					if not current then
						mark(hash, prev)
					end
				end
			end)

			for _, tag in removeTags do
				result = result .. `</{tag.identifier}>`
			end

			local addTags = identifyTagsFromHashCounts(richCharacter, false, function(mark)
				for hash, current in currentTagLengths do
					local prev = prevTagLengths[hash] or EMPTY_TAG_LENGTH
					if current.count > prev.count then
						mark(hash, current)
					end
				end
			end)

			for _, tag in addTags do
				local tagAddArray = { tag.identifier }
				for key, subValue in tag.properties do
					local typeofSubValue = typeof(subValue)
					local transformedSubValue = tostring(subValue)

					if typeofSubValue == "Color3" then
						transformedSubValue = "#" .. (subValue :: Color3):ToHex():upper()
					end

					table.insert(tagAddArray, `{key}="{transformedSubValue}"`)
				end

				result = result .. `<{table.concat(tagAddArray, " ")}>`
			end

			local richCommentTexts: { string } = richCommentsByIndex[i] or {}
			for _, commentText in richCommentTexts do
				result = result .. ("<!--%s-->"):format(commentText)
			end

			result = result .. richCharacter.character
			prevTagLengths = currentTagLengths
		end

		local removeTags = identifyTagsFromHashCounts(EMPTY_RICH_CHARACTER, true, function(mark)
			for hash, prev in prevTagLengths do
				mark(hash, prev)
			end
		end)

		for _, tag in removeTags do
			result = result .. `</{tag.identifier}>`
		end
	end

	local richCommentTexts: { string } = richCommentsByIndex[length + 1] or {}
	for _, commentText in richCommentTexts do
		result = result .. ("<!--%s-->"):format(commentText)
	end

	return result
end

--

return write
