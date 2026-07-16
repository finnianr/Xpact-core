note
	description: "Parse event types"
	author: ""
	date: "$Date$"
	revision: "$Revision$"

class
	PARSE_EVENT_CONSTANTS

inherit
	XT_TOKEN_CONSTANTS
		rename
			Tok_data_chars as Tok_text,
			Tok_cdata_sect_open as Tok_cdata,
			Tok_end_tag as Tok_tag,
			Tok_attribute_value_s as Tok_attribute
		export
			{NONE} all
		end

feature {NONE} -- Constants

	Parse_event_types: HASH_TABLE [INTEGER, STRING]
		once
			create Result.make_from_iterable_tuples (<<
				[Tok_text, "text"],				-- text content
				[Tok_cdata, "cdata"],			-- CDATA text content
				[Tok_comment, "comment"],		-- comment
				[Tok_tag, "tag"],					-- tag name (open element)
				[Tok_attribute, "attribute"]	-- attribute value
			>>)
		end

end
