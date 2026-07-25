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

create
	make

feature {NONE} -- Event handlers

	on_comment (text: STRING_8)
		do
			put_tabs (element_depth)
			IO.put_string ("COMMENT: ")
			IO.put_string (text)
			IO.put_new_line
		end

	on_content (text: STRING)
		local
			is_double: BOOLEAN
		do
			is_double := text.is_double
			put_tabs (element_depth)
			if in_cdata_section then
				IO.put_string ("CDATA: ")
			end
			if not is_double then
				IO.put_character ('"')
			end
			IO.put_string (text)
			if not is_double then
				IO.put_character ('"')
			end
			IO.put_new_line
		end

	on_tag_end (name: STRING_8)
		do
		end

	on_tag_start (context: XT_ELEMENT_CONTEXT; attributes: XT_ATTRIBUTE_BUFFER_INTERVALS)
		do
			put_tabs (element_depth - 1)
			IO.put_string (context.name)
			IO.put_character (':')
			IO.put_new_line
			if attributes.index_count > 0 then
				attributes.null_terminate_values (buffer) -- purely to test null termination

				across attributes.as_table (buffer, False) as value loop
					if @ value.is_first then
						put_tabs (element_depth)
						IO.put_string ("ATTRIBUTES: {")
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
				attributes.undo_null_terminated_values (buffer) -- purely to test restoring value
			end
		ensure then
			buffer_unchanged:
				attributes.upper_plus_1_characters (buffer).is_equal (
					old attributes.upper_plus_1_characters (buffer) -- purely to test upper_plus_1_characters
				)
		end

feature {NONE} -- Implementation

	put_tabs (n: INTEGER)
		local
			i: INTEGER
		do
			from i := 1 until i > n loop
				IO.put_string (Tab_string)
				i := i + 1
			end
		end

feature {NONE} -- Constants

	Tab_string: STRING
		once
			create Result.make_filled (' ', 3)
		end

end
