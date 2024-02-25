--!strict

local Package = game.ReplicatedStorage.Packages.RichTextHelper

local RichTextHelper = require(Package)
local _TestHelper = require(Package.TestHelper)

local richText = '<font size="40"><font transparency="0.5">Hello<!--Comment!-->World</font></font>'
local parsed = RichTextHelper.parse(richText)
local written = RichTextHelper.write(parsed)

print(parsed)
print(richText)
print(written)
