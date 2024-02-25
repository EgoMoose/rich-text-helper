--!strict

local module = {}

-- Private

local function flatten(unflattened: any): { [string]: any }
	assert(typeof(unflattened) == "table", "unflattened argument is not a table")

	local flattend = {}

	local queue = { {
		dict = unflattened,
		path = {},
	} }

	while #queue > 0 do
		local pop = table.remove(queue) :: any

		for key, value in pairs(pop.dict) do
			local path = table.clone(pop.path)
			table.insert(path, key)

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

-- Public

function module.readRaw(richText: string)
	local label = Instance.new("TextLabel")
	label.RichText = true
	label.Text = richText

	local result = label.ContentText
	label:Destroy()
	return result
end

function module.hash(t: any)
	local flat = flatten(t)
	local arr = {}

	for key, value in flat do
		table.insert(arr, {
			key = key,
			value = value,
		})
	end

	table.sort(arr, function(a, b)
		return a.key < b.key
	end)

	local lines = {}
	for _, entry in arr do
		table.insert(lines, ("%s: [%s]"):format(entry.key, tostring(entry.value)))
	end

	return table.concat(lines, "\n")
end

--

return module
