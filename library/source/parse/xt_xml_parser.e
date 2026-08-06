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
			on_tag_start as on_base_tag_start,
			on_tag_end as on_base_tag_end,
			on_processing_instruction as on_base_processing_instruction
		redefine
			make
		end

	XT_STRING_8_ROUTINES_I

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

	on_base_commment (area: SPECIAL [CHARACTER]; start_index, end_index: INTEGER; attributes: XT_ATTRIBUTE_BUFFER_INTERVALS)
		do
			on_comment (new_substring (area, start_index, end_index))
		end

	on_base_content (
		area: SPECIAL [CHARACTER]; start_index, end_index: INTEGER; attributes: XT_ATTRIBUTE_BUFFER_INTERVALS
	)
		-- handle content section in `area' from index `start_index' to `end_index'
		local
			count, white_count: INTEGER
		do
			if attached text_buffer as text then
				if is_white_space_skipped then
					append_area (text, area, start_index, end_index)
				else
					count := end_index - start_index + 1
					white_count := leading_white_space (area, start_index, end_index)
					if white_count < count then
						append_area (text, area, start_index + white_count, end_index)
						is_white_space_skipped := True
					end
				end
				content_call_count := content_call_count + 1
			end
		end

	on_base_processing_instruction (buf: SPECIAL [CHARACTER]; start_index, end_index: INTEGER; attributes: XT_ATTRIBUTE_BUFFER_INTERVALS)
		do
			if attributes.is_empty then
				on_processing_instruction (new_substring (buf, start_index, end_index), Empty_string)
			else
				on_processing_instruction (attributes.first_name (buf), attributes.first_value (buf))
			end
		end

	on_base_tag_start (buf: like buffer; context: XT_ELEMENT_CONTEXT; attributes: XT_ATTRIBUTE_BUFFER_INTERVALS; token: INTEGER)
		do
			on_tag_start (context.name, context.depth, attributes.as_table (buf, False))
		end

	on_base_tag_end (name: STRING)
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

	on_tag_start (name: STRING_8; depth: INTEGER; attribute_table: HASH_TABLE [STRING, STRING])
		deferred
		end

	on_tag_end (name: STRING_8)
		deferred
		end

	on_processing_instruction (name, value: STRING)
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

	put_tabs (n: INTEGER)
		local
			i: INTEGER
		do
			from i := 1 until i > n loop
				IO.put_string (Tab_string)
				i := i + 1
			end
		end

feature {NONE} -- Internal attributes

	content_call_count: INTEGER

	is_white_space_skipped: BOOLEAN

	text_buffer: STRING

feature {NONE} -- Constants

	Tab_string: STRING
		once
			create Result.make_filled (' ', 3)
		end


end
