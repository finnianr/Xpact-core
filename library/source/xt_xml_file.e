note
	description: "Incremental XML file parser"

	author: "Finnian Reilly"
	copyright: "Copyright (c) 2001-2026 Finnian Reilly"
	contact: "finnian at eiffel hyphen loop dot com"

	license: "MIT license (See: en.wikipedia.org/wiki/MIT_License)"
	date: "2026-06-20 18:21:11 GMT (Saturday 20th June 2026)"
	revision: "1"

class
	XT_XML_FILE

inherit
	PLAIN_TEXT_FILE
		rename
			make as make_file
		export
			{NONE} all
			{ANY} off, bytes_read
		end

	XT_PARSE_CONSTANTS
		export
			{NONE} all
		end

	XT_ENCODING_TYPE_CONSTANTS

create
	make

feature -- Initialization	

	make (fn: READABLE_STRING_GENERAL; a_parser: like parser)
		do
			make_with_name (fn)
			parser := a_parser
			set_chunk_size (Default_chunk_size)

			if exists then
				open_read; read_line; close
				last_string.to_upper
				if last_string.has_substring ("ISO-8859-1") then
					parser.set_encoding (Latin_1)
				end
			end
		end

feature -- Access

	chunk: SPECIAL [CHARACTER]
		-- incremental chunk

	status: INTEGER
		-- one of `XT_PARSE_CONSTANTS' parse status constants

	gc_enabled: BOOLEAN

feature -- Access

	set_chunk_size (chunk_size: INTEGER)
		do
			create chunk.make_filled ('%U', chunk_size)
		end

feature -- Status sett

	collection_off
		-- Disables garbage collection temporarily until the parse has finished
		-- (useful for Xpact C bridge)
		do
			gc_enabled := False
		end

	collection_on
		-- Enable garbage collection all the time.
		do
			gc_enabled := True
		end

feature -- Basic operations

	parse
		require
			readable: is_readable
		local
			n: INTEGER
		do
			if is_readable then
				if not gc_enabled then
					Memory.collection_off
				end
				from open_read; status := Status_ok until off or status = Status_error loop
					read_chunk
					n := bytes_read
					if n > 0 then
						status := parser.parse (chunk, 0, n, off)
					end
				end
				if not gc_enabled then
					Memory.collection_on
					Memory.full_collect
				end
			end
			close
		end

feature {NONE} -- Implementation

	read_chunk
		require
			is_readable: file_readable
		local
			n: INTEGER
		do
			n := chunk.count
			bytes_read := file_gss (file_pointer, chunk.base_address, n)
		end

feature {NONE} -- Internal attributes

	parser: XT_XML_PARSER

feature {NONE} -- Constants

	Default_chunk_size: INTEGER = 4096

	Memory: MEMORY
		once
			create Result
		end

end
