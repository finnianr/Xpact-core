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
		local
			file: RAW_FILE
		do
			make_with_path (file_path)
			parser := a_parser
			create file.make_open_read (file_path.name)
			if file.count > 4 then
				file.read_natural_16
				is_utf_16 := file.last_natural_16 = 0xFEFF
			end
			file.close
			if is_utf_16 then
				set_chunk_size (Default_chunk_size * 2)
			else
				set_chunk_size (Default_chunk_size)
			end
		end

feature -- Access

	chunk: XT_LATIN_1_CODEC
		-- incremental chunk

	parse_status: INTEGER
		-- one of `XT_PARSE_CONSTANTS' parse Status_* constants

	gc_enabled: BOOLEAN

feature -- Eleement change

	set_chunk_size (chunk_size: INTEGER)
		do
			create chunk.make_filled ('%U', chunk_size)
		end

feature -- Status report

	is_utf_16: BOOLEAN

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
		local
			byte_count: INTEGER; final_chunk: BOOLEAN
		do
			if not gc_enabled then
				Memory.collection_off
			end
			if file_readable then
				from parse_status := Status_ok until final_chunk or parse_status /= Status_OK loop
					read_to_managed_pointer (chunk, 0, chunk.count); byte_count := bytes_read
					if off or else (byte_count = chunk.count and then position = count) then
						final_chunk := True
					end
					if byte_count > 0 then
					-- This aligns with C examples which excludes final newline
					-- but Claude thinks this is a parsing issue, so this is just a workaround.
						parse_status := parser.parse (chunk, 0, byte_count, final_chunk)
					end
				end
			else
				parse_status := parser.parse (chunk, 0, 0, True)
			end
			if not gc_enabled then
				Memory.collection_on
				Memory.full_collect
			end
			close
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
