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
	RAW_FILE
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

	make (file_path: PATH; a_parser: like parser)
		do
			make_with_path (file_path)
			parser := a_parser
			set_chunk_size (Default_chunk_size)
		end

feature -- Access

	chunk: SPECIAL [CHARACTER]
		-- incremental chunk

	parse_status: INTEGER
		-- one of `XT_PARSE_CONSTANTS' parse Status_* constants

	gc_enabled: BOOLEAN

feature -- Eleement change

	set_chunk_size (chunk_size: INTEGER)
		do
			create chunk.make_filled ('%U', chunk_size)
		end

feature -- Status setting

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
			byte_count: INTEGER; final_chunk: BOOLEAN
		do
			if is_readable then
				if not gc_enabled then
					Memory.collection_off
				end
				from open_read; parse_status := Status_ok until final_chunk or parse_status /= Status_OK loop
					read_chunk; byte_count := bytes_read
					if off or else (byte_count = chunk.count and then position = count) then
						final_chunk := True
					end
					if byte_count > 0 then
					-- This aligns with C examples which excludes final newline
					-- but Claude thinks this is a parsing issue, so this is just a workaround.
						parse_status := parser.parse (chunk, 0, byte_count, final_chunk)
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
		do
			if attached chunk as area then
				bytes_read := file_gss (file_pointer, area.base_address, area.count)
			end
		end

feature {NONE} -- Internal attributes

	parser: XT_XML_PARSER_BASE

feature {NONE} -- Constants

	Default_chunk_size: INTEGER = 4096

	Memory: MEMORY
		once
			create Result
		end

end
