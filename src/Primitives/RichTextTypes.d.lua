export type RichProperties = {
	font: {
		color: Color3?,
		size: number?,
		face: string?,
		family: string?,
		weight: (string | number)?,
		transparency: number?,
	}?,
	stroke: {
		color: Color3?,
		joins: string?,
		thickness: number?,
		transparency: number?,
	}?,
	bold: boolean?,
	italic: boolean?,
	underline: boolean?,
	strikethrough: boolean?,
	uppercase: boolean?,
	smallcaps: boolean?,
}

export type RichCharacter = {
	character: string,
	properties: RichProperties,
}

export type RichComment = {
	index: number,
	text: string,
}

export type ParsedRichText = {
	characters: { RichCharacter },
	comments: { RichComment },
}

return {}
