note
	description: "A native Eiffel XML parser based on a port of C eXpat"

	author: "Finnian Reilly"
	copyright: "Copyright (c) 2001-2026 Finnian Reilly"
	contact: "finnian at eiffel hyphen loop dot com"

	license: "MIT license (See: en.wikipedia.org/wiki/MIT_License)"
	date: "2026-07-08 20:30:52 GMT (Wednesday 8th July 2026)"
	revision: "1"

deferred class
	XT_XML_PARSER

inherit
	XT_XML_PARSER_BASE
		rename
			on_content as on_base_content,
			on_comment as on_base_commment,
			on_tag_end as on_base_tag_end
		redefine
			make
		end

	XT_STRING_ROUTINES_I

feature {NONE} -- Initialisation

	make
		do
			Precursor
			create text_buffer.make (0)
		end

feature {NONE} -- Event handlers

	on_cdata_section_close
		do
			do_with_content (text_buffer)
		end

	on_base_commment (area: SPECIAL [CHARACTER]; lower, upper: INTEGER)
		do
			on_comment (new_substring (area, lower, upper))
		end

	on_base_content (area: SPECIAL [CHARACTER]; lower, upper: INTEGER)
		-- handle content section in `area' from index `lower' to `upper'
		local
			count, white_count: INTEGER
		do
			if attached text_buffer as text then
				if is_white_space_skipped then
					append_area (text, area, lower, upper)
				else
					count := upper - lower + 1
					white_count := leading_white_space (area, lower, upper)
					if white_count < count then
						append_area (text, area, lower + white_count, upper)
						is_white_space_skipped := True
					end
				end
				content_call_count := content_call_count + 1
			end
		end

	on_base_tag_end (name: STRING_8)
		do
			do_with_content (text_buffer)
			on_tag_end (name)
		end

	on_comment (text: STRING)
		deferred
		end

	on_content (text: STRING)
		deferred
		end

	on_tag_end (name: STRING_8)
		deferred
		end

feature {NONE} -- Implementation

	do_with_content (text: STRING_8)
		do
			inspect content_call_count when 0 then
				do_nothing
			else
				text.right_adjust
				if text.count > 0 then
					on_content (text)
					text.wipe_out
				end
				content_call_count := 0
				is_white_space_skipped := False
			end
		end

feature {NONE} -- Internal attributes

	content_call_count: INTEGER

	is_white_space_skipped: BOOLEAN

	text_buffer: STRING

end
