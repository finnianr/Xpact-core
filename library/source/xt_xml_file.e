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

			create chunk_string.make_empty

			if exists then
				open_read; read_line; close
				last_string.to_upper
				if last_string.has_substring ("ISO-8859-1") then
					parser.set_scanner (Latin_1)
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
			n: INTEGER; final_chunk: BOOLEAN
		do
			if is_readable and then attached chunk_string as str then
				if not gc_enabled then
					Memory.collection_off
				end
				zero_CR_count := 0
				from open_read; status := Status_ok until off or status = Status_error loop
					read_chunk (str); n := bytes_read
					final_chunk := off
					if n > 0 then
					-- This aligns with C examples which excludes final newline
					-- but Claude thinks this is a parsing issue, so this is just a workaround.
						if final_chunk and then chunk [n - 1] = '%N' then
							n := n - 1
						end
						status := parser.parse (chunk, 0, n, final_chunk)
					end
				end
				if not gc_enabled then
					Memory.collection_on
					Memory.full_collect
				end
			end
			close
		end

	all_cr_characters_removed: BOOLEAN
		-- `True' if chunk as no '%R' (CR) characters
		do
			chunk_string.make_shared (chunk.base_address, bytes_read)
			Result := chunk_string.index_of ('%R', 1) = 0
		end

feature {NONE} -- Implementation

	check_newline_ahead: INTEGER
		do
			if readable then
				read_character
			end
			if end_of_file then
				Result := EOF
			else
				inspect last_character when '%N' then
					Result := {ASCII}.Line_feed
				else
				end
			end
		end

	read_chunk (str: like chunk_string)
		require
			is_readable: file_readable
		local
			byte_count, cr_index: INTEGER
		do
			if attached chunk as area then
				byte_count := file_gss (file_pointer, area.base_address, area.count)
				bytes_read := byte_count

				if zero_CR_count < Maximum_zero_CR_count then
					str.make_shared (area.base_address, byte_count)
					cr_index := str.index_of ('%R', 1)
					if cr_index = 0 then
						zero_CR_count := zero_CR_count + 1
					else
						read_pruned_chunk (area, str, cr_index)
					end
				else
					do_nothing -- Assume no '%R' if `Maximum_zero_CR_count' chunks checked and none found
				end
			end
		end

	read_pruned_chunk (area: like chunk; str: C_STRING_8; cr_index: INTEGER)
		-- replace CR/NL character pairs with NL. Replace isolated CR to NL
		local
			i, i_final, j, byte_count, start_index, pass_count: INTEGER
		do
			byte_count := bytes_read
			start_index := cr_index - 1; i_final := byte_count - 1
			from pass_count := 1 until pass_count > 2 loop
				from i := start_index; j := i until i > i_final loop
					inspect area [i] when '%R' then
						if i < i_final then
							inspect area [i + 1] when '%N' then
								i := i + 1
								when '%R' then
									do_nothing
							else
								if i + 1 /= i_final then
									area [i] := '%N' -- eXpat behavior is to replace lone %R with %N
								end
							end
						else
							inspect check_newline_ahead
								when {ASCII}.Line_feed then
									area [i] := '%N' -- eXpat behavior is to replace lone %R with %N
								when EOF then
									do_nothing
							else
								back -- undo reading newline
							end
						end
					else end
					area [j] := area [i]
					i := i + 1; j := j + 1
				end
				if end_of_file then
					bytes_read := j
					pass_count := 2 -- break

				elseif pass_count = 1 then
				-- fill in vacant space left by CR pruning and continue pruning
					byte_count := file_gss (file_pointer, area.item_address (j), area.count - j)
					start_index := j; i_final := j + byte_count - 1
				else
					bytes_read := j
				end
				pass_count := pass_count + 1
			end
		ensure
			all_cr_characters_removed: all_cr_characters_removed
		end

feature {NONE} -- Internal attributes

	parser: XT_XML_PARSER_BASE

	chunk_string: C_STRING_8

	zero_CR_count: INTEGER

feature {NONE} -- Constants

	EOF: INTEGER = -1

	Default_chunk_size: INTEGER = 4096

	Memory: MEMORY
		once
			create Result
		end

	Maximum_zero_CR_count: INTEGER = 20
		-- maximum number of times to check for CR character if there are none found
		-- Assumes if you haven't found one after 4096 x 10 bytes

end
