--!strict

local RichTextHelper = require(script.Parent)
local TestHelper = require(script.Parent:WaitForChild("TestHelper"))

local VALID_RICH_TEXT: { string } = {
	-- all of these are taken from:
	-- https://create.roblox.com/docs/ui/rich-text
	"Use a <b>bold title</b>",
	"<b><i><u>Formatted Text</u></i></b>",
	'I want the <font color="#FF7800">orange</font> candy.',
	'I want the <font color="rgb(255,125,0)">orange</font> candy.',
	'<font size="40">This is big.</font> <font size="20">This is small.</font>',
	'<font face="Michroma">This is Michroma face.</font>',
	'<font family="rbxasset://fonts/families/Michroma.json">This is Michroma face.</font>',
	'This is normal. <font weight="heavy">This is heavy.</font>',
	'This is normal. <font weight="900">This is heavy.</font>',
	'You won <stroke color="#00A2FF" joins="miter" thickness="2" transparency="0.25">25 gems</stroke>.',
	'Text at <font transparency="0.5">50% transparency</font>.',
	"Text in <b>bold</b>.",
	"Text <i>italicized</i>.",
	"Text <u>underlined</u>.",
	"Text with <s>strikethrough</s> applied.",
	"New line occurs after this sentence.<br />Next sentence...",
	"<uppercase>Uppercase</uppercase> makes words read loudly!",
	"<uc>Uppercase</uc> makes words read loudly!",
	"My name is <smallcaps>Diva Dragonslayer</smallcaps>.",
	"My name is <sc>Diva Dragonslayer</sc>.",
	"After this is a comment...<!--This does not appear in the final text--> and now more text...",
	"10 &lt; 100",
	"100 &gt; 10",
	"Meet &quot;Diva Dragonslayer&quot;",
	"Diva&apos;s pet is a falcon!",
	"Render another escape form <b>&amp;lt;</b> by escaping an ampersand",

	-- the following are custom generated to check specific cases
	'I want <u>the <font color="#FF7800"><font size="50">orange</font></font></u> candy',
	'<i>I want </i><u>the <font color="#FF7800" size="50">orange</font></u> <i>candy</i>',
	"<!--Comment 1-->Hello<!--Comment 2--><!--Comment 3-->World<!--Comment 4-->",
	"<!--Comment 1--><!--Comment 2--><!--Comment 3-->",
	"<!--Only a comment!-->",
	"<!--Only a comment!-->\t   ",
	"\t  <!--Only a comment!--> ",
	"  \t   \n",
	"",
}

local INVALID_RICH_TEXT: { string } = {
	"Text <i>italicized.", -- not closed
	"Text italicized</i>.", -- only closed
	"<uppercase>Uppercase</uc> makes words read loudly!", -- mismatch
	"<b><i><u>Formatted Text</i></u></b>", -- incorrect nest exiting
}

return function()
	describe("VALID", function()
		for _, richText in VALID_RICH_TEXT do
			describe(("TEXT: '%s'"):format(richText), function()
				describe("validate", function()
					it("should pass validation", function()
						expect(RichTextHelper.validate(richText)).to.equal(true)
					end)
				end)

				describe("parse", function()
					it("should successfully parse a non-nil value", function()
						local parsed
						expect(function()
							parsed = RichTextHelper.parse(richText)
						end).never.to.throw()

						expect(parsed).to.be.ok()
					end)
				end)

				describe("read", function()
					it("should convert parsed to a string", function()
						local parsed
						expect(function()
							parsed = RichTextHelper.parse(richText)
						end).never.to.throw()

						expect(parsed).to.be.ok()

						local plain
						expect(function()
							plain = RichTextHelper.read(parsed)
						end).never.to.throw()

						expect(plain).to.be.a("string")
					end)

					it("should match TextLabel.ContentText", function()
						local parsed
						expect(function()
							parsed = RichTextHelper.parse(richText)
						end).never.to.throw()

						expect(parsed).to.be.ok()

						local plain
						expect(function()
							plain = RichTextHelper.read(parsed)
						end).never.to.throw()

						expect(plain).to.be.a("string")

						local plainRaw = TestHelper.readRaw(richText)
						expect(plain).to.equal(plainRaw)
					end)
				end)

				describe("write", function()
					it("should write valid rich text", function()
						local parsed
						expect(function()
							parsed = RichTextHelper.parse(richText)
						end).never.to.throw()

						expect(parsed).to.be.ok()

						local written
						expect(function()
							written = RichTextHelper.write(parsed)
						end).never.to.throw()

						expect(written).to.be.a("string")
						expect(RichTextHelper.validate(written)).to.equal(true)
					end)

					it("should write losslessly", function()
						local parsed
						expect(function()
							parsed = RichTextHelper.parse(richText)
						end).never.to.throw()

						expect(parsed).to.be.ok()

						local written
						expect(function()
							written = RichTextHelper.write(parsed)
						end).never.to.throw()

						expect(written).to.be.a("string")
						expect(RichTextHelper.validate(written)).to.equal(true)

						local parsedWritten
						expect(function()
							parsedWritten = RichTextHelper.parse(written)
						end).never.to.throw()

						local charactersA = parsed.characters
						local charactersB = parsedWritten.characters

						expect(#charactersA).to.equal(#charactersB)

						for i = 1, #charactersA do
							local a = charactersA[i]
							local b = charactersB[i]

							expect(a.character).to.equal(b.character)
							expect(TestHelper.hash(a.properties)).to.equal(TestHelper.hash(b.properties))
						end

						local commentsA = parsed.comments
						local commentsB = parsedWritten.comments

						expect(#commentsA).to.equal(#commentsB)

						for i = 1, #commentsA do
							local a = commentsA[i]
							local b = commentsB[i]

							expect(a.text).to.equal(b.text)
						end
					end)

					it("should reduce or maintain string length (simplify)", function()
						local parsed
						expect(function()
							parsed = RichTextHelper.parse(richText)
						end).never.to.throw()

						expect(parsed).to.be.ok()

						local written
						expect(function()
							written = RichTextHelper.write(parsed)
						end).never.to.throw()

						expect(written).to.be.a("string")
						expect(RichTextHelper.validate(written)).to.equal(true)
						expect(#written <= #richText).to.equal(true)
					end)
				end)

				describe("concat", function()
					it("should be concat two rich text strings together", function()
						local parsed
						expect(function()
							parsed = RichTextHelper.parse(richText)
						end).never.to.throw()

						expect(parsed).to.be.ok()

						local separator = "<b> _MIND THE GAP_ </b>"
						local merged
						expect(function()
							merged = RichTextHelper.concat({ parsed, parsed }, separator)
						end).never.to.throw()

						expect(merged).to.be.ok()

						local plain
						expect(function()
							plain = RichTextHelper.read(merged)
						end).never.to.throw()

						expect(plain).to.be.a("string")
						expect(plain).to.equal(TestHelper.readRaw(richText .. separator .. richText))
					end)
				end)

				describe("slice", function()
					it("should be able to slice a substring", function()
						local parsed
						expect(function()
							parsed = RichTextHelper.parse(richText)
						end).never.to.throw()

						expect(parsed).to.be.ok()

						for i = 1, #parsed.characters do
							local sliced
							expect(function()
								sliced = RichTextHelper.slice(parsed, 1, i)
							end).never.to.throw()

							expect(sliced).to.be.ok()

							local written
							expect(function()
								written = RichTextHelper.write(sliced)
							end).never.to.throw()

							expect(written).to.be.a("string")
							expect(RichTextHelper.validate(written)).to.equal(true)
						end
					end)
				end)

				describe("tag", function()
					it("should be able to add a tag", function()
						local parsed
						expect(function()
							parsed = RichTextHelper.parse(richText)
						end).never.to.throw()

						expect(parsed).to.be.ok()

						local tagged
						expect(function()
							tagged = RichTextHelper.tag(parsed, '<font transparency="0.5"> </font>')
						end).never.to.throw()

						expect(tagged).to.be.ok()

						local written
						expect(function()
							written = RichTextHelper.write(tagged)
						end).never.to.throw()

						expect(written).to.be.a("string")
						expect(RichTextHelper.validate(written)).to.equal(true)
					end)
				end)
			end)
		end
	end)

	describe("INVALID", function()
		for _, richText in INVALID_RICH_TEXT do
			describe(("TEXT: '%s'"):format(richText), function()
				describe("validate", function()
					it("should fail validation", function()
						expect(RichTextHelper.validate(richText)).to.equal(false)
					end)
				end)

				describe("parse", function()
					it("should fail to parse", function()
						expect(function()
							RichTextHelper.parse(richText)
						end).to.throw()
					end)
				end)

				describe("read", function() end)

				describe("write", function() end)
			end)
		end
	end)
end
