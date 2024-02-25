# rich-text-helper

A Luau package for interpreting and modifying rich text in Roblox

Get it here:

* [Wally](https://wally.run/package/egomoose/rich-text-helper)
* [Releases](https://github.com/EgoMoose/rich-text-helper/releases)

## API

This module exports one type called `ParsedRichText`. To see this typing please reference the following [file.](src/Primitives/RichTextTypes.d.lua)

```Lua
--[=[
Given an rich text input string this function will return whether or not the string can be parsed by Roblox's rich text system.

@param richText string -- The input rich text string
@return boolean
--]=]
function module.validate(richText: string): boolean

--[=[
Given an rich text input string this function will validate and return a parsed rich text format that's to be used with most other functions in this module.

@param richText string -- The input rich text string
@return ParsedRichText
--]=]
function module.parse(richText: string): ParsedRichText

--[=[
Returns the string form of parsed rich text. This function will attempt to use the minimum number of rich text tags possible so it is not guaranteed to be equal to origin string used to generate the ParsedRichText

Note: `from` and `to` can be negative. `from` defaults to 1 and `to` defaults to -1.

@param parsed ParsedRichText -- The input parsed rich text
@param from number? -- The starting index of the rich text
@param to number? -- The ending index of the rich text
@return ParsedRichText
--]=]
function module.write(parsed: ParsedRichText, from: number?, to: number?): string

--[=[
Returns a rich text tag sanitized version of parsed rich text. This would be equivalent to using the `ContentText` property of a TextLabel Instance.

Example:
"<b>Hello<b> <i>world!</i>" -> "Hello world!"

@param parsed ParsedRichText -- The input parsed rich text
@return string
--]=]
function module.read(parsed: ParsedRichText): string

--[=[
Takes a variadic number of ParsedRichText arguments and concatenates them together.

@param parsedArray { ParsedRichText } -- All the inputs that will be concatenated together
@param richSeparator string -- The separating rich text string 
@return string
--]=]
function module.concat(parsedArray: { ParsedRichText }, richSeparator: string): ParsedRichText

--[=[
Returns a slice of the input ParsedRichText with the provided character range.

Note: `from` and `to` can be negative. `from` defaults to 1 and `to` defaults to -1.

@param parsed ParsedRichText -- The input parsed rich text
@param from number? -- The starting index of the rich text
@param to number? -- The ending index of the rich text
@return string
--]=]
function module.slice(parsed: ParsedRichText, from: number?, to: number?): ParsedRichText

--[=[
Adds tags to all characters in the rich text.

Example:
module.tag(parsed, "<b><i> </i></b>")

@param parsed ParsedRichText -- The input parsed rich text
@param tag string -- The starting index of the rich text
@return string
--]=]
function module.tag(parsed: ParsedRichText, tag: string): string
```