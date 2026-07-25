note
	description: "Parse event types"

	author: "Finnian Reilly"
	copyright: "Copyright (c) 2001-2026 Finnian Reilly"
	contact: "finnian at eiffel hyphen loop dot com"

	license: "MIT license (See: en.wikipedia.org/wiki/MIT_License)"
	date: "2026-07-16 17:10:00 GMT (Thursday 15th July 2026)"
	revision: "1"

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

feature {NONE} -- Implementation

	data_type_name (data_type: INTEGER): STRING
		local
			done: BOOLEAN
		do
			create Result.make_empty
			across Parse_data_types as type until done loop
				if type ~ data_type then
					Result := @ type.key
					done := True
				end
			end
		end

feature {NONE} -- Constants

	Parse_data_types: HASH_TABLE [INTEGER, STRING]
		once
			create Result.make_from_iterable_tuples (<<
				[Tok_text,			"text"],			-- text content
				[Tok_cdata, 		"cdata"],		-- CDATA text content
				[Tok_comment,		"comment"],		-- comment
				[Tok_tag,			"tag"],			-- tag name (open element)
				[Tok_attribute,	"attribute"]	-- attribute value
			>>)
		end

end
