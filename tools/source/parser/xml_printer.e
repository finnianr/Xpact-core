note
	description: "[
		Concrete XML parser that prints element names, attribute
		name/value pairs, and character data to standard output.
	]"
	notes: "[
		**EXAMPLE OUTPUT**
		
			Parsing: data/sample.xml
			bookstore:
			COMMENT: Test data for the billion-user project xpact
			book:
			   ATTRIBUTES: {category : "cooking"}
			title:
			   ATTRIBUTES: {lang : "en"}
			   "Everyday Italian"
			author:
			   "Giada De Laurentiis"
			price:
			   30.00
			book:
			   ATTRIBUTES: {category : "children"}
			title:
			   ATTRIBUTES: {lang : "en"}
			COMMENT: Test leading/trailing space adjust
			   "Harry Potter"
			author:
			   "J K. Rowling"
			price:
			   29.99
			dvd:
			   ATTRIBUTES: {region : "2", format : "PAL"}

	]"

	author: "Finnian Reilly"
	copyright: "Copyright (c) 2001-2026 Finnian Reilly"
	contact: "finnian at eiffel hyphen loop dot com"

	license: "MIT license (See: en.wikipedia.org/wiki/MIT_License)"
	date: "2026-06-20 18:21:11 GMT (Saturday 20th June 2026)"
	revision: "1"

class XML_PRINTER

inherit
	XT_XML_PARSER
		redefine
			on_base_tag_start
		end

create
	make

feature {NONE} -- Event handlers

	on_base_tag_start (buf: like buffer; context: XT_ELEMENT_CONTEXT; attributes: XT_ATTRIBUTE_LIST; token: INTEGER)
		do
			if attributes.index_count > 0 then
				attributes.null_terminate_values (buf) -- purely to test null termination
			end
			on_tag_start (context.name, context.depth, attributes.as_table (buf, False))
			if attributes.index_count > 0 then
				attributes.undo_null_terminated_values (buf) -- purely to test restoring value
			end
		ensure then
			buffer_unchanged:
				attributes.upper_plus_1_characters (buf).is_equal (
					old attributes.upper_plus_1_characters (buf) -- purely to test upper_plus_1_characters
				)
		end

	on_comment (text: STRING_8)
		do
			put_tabs (element_context.depth)
			IO.put_string ("COMMENT: %"")
			IO.put_string (text)
			IO.put_character ('"')
			IO.put_new_line
		end

	on_content (text: STRING)
		local
			is_double: BOOLEAN; left, right: CHARACTER
		do
			is_double := text.is_double
			put_tabs (element_context.depth)
			if in_cdata_section then
				IO.put_string ("CDATA: ")
				if text.count > 1 then
					if text [1] = '"' and text [text.count] = '"' then
						do_nothing

					elseif text [1] = '"' or text [text.count] = '"' then
						left := '['; right := ']'
					end
				end

			elseif not text.is_double then
				left := '"'; right := '"'
			end
			if left /= '%U' then
				IO.put_character (left)
			end
			IO.put_string (text)
			if right /= '%U' then
				IO.put_character (right)
			end
			IO.put_new_line
		end

	on_tag_end (name: STRING_8)
		do
		end

	on_tag_start (name: STRING_8; depth: INTEGER; attribute_table: HASH_TABLE [STRING, STRING])
		do
			put_tabs (depth - 1)
			IO.put_string (name)
			IO.put_character (':')
			IO.put_new_line
			put_attributes ("ATTRIBUTES", depth, attribute_table)
		end

	on_processing_instruction (name, value: STRING)
		local
			s: XT_STRING_8_ROUTINES; template: STRING; index: INTEGER
		do
			put_tabs (element_context.depth)
			if value.is_empty then
				index := Processing_template.index_of ('%S', 1) - 1
				IO.put_string (Processing_template.substring (1, index) + name)
			else
				template := Processing_template.twin
				if value.has ('"') then
					from index := 1 until not template.has ('"') loop
						index := template.index_of ('"', 1)
						if index > 0 then
							template [index] := '%''
							index := index + 1
						end
					end
				end
				IO.put_string (s.substitute (template, << name, value >>))
			end
			IO.put_new_line
		end

	on_xml_declaration (buf: like buffer; attributes: XT_ATTRIBUTE_LIST)
		do
			put_attributes ("XML", 0, attributes.as_table (buffer, False))
		end

feature {NONE} -- Implementation

	put_attributes (name: STRING; depth: INTEGER; attribute_table: HASH_TABLE [STRING, STRING])
		do
			if attribute_table.count > 0 then
				across attribute_table as value loop
					if @ value.is_first then
						put_tabs (depth)
						IO.put_string (name)
						IO.put_string (": {")
					else
						IO.put_string (", ")
					end
					IO.put_string (@ value.key)
					IO.put_string (" : %"")
					IO.put_string (value)
					IO.put_character ('"')
				end
				IO.put_character ('}')
				IO.put_new_line
			end
		end

feature {NONE} -- Constants

	Processing_template: STRING = "PROCESS: %S (%"%S%")"
end
