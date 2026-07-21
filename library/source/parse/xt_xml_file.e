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

feature -- Status report

	valid_first_chunk: BOOLEAN

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
			if is_readable and then attached chunk_string as c_str then
				if not gc_enabled then
					Memory.collection_off
				end
				positive_CR_count := 0; skip_CR_checking := False
				new_line_occurrences := 0; new_line_check_count := 0
				from open_read; parse_status := Status_ok until final_chunk or parse_status = Status_error loop
					read_chunk (c_str); n := bytes_read
					if off or else (n = chunk.count and then position = count) then
						final_chunk := True
					-- prune trailing newlines
						if n > 0 then
							from until n < 0 or else chunk [n - 1] /= '%N' loop
								n := n - 1
							end
						end
					end
					if n > 0 then
					-- This aligns with C examples which excludes final newline
					-- but Claude thinks this is a parsing issue, so this is just a workaround.
						parse_status := parser.parse (chunk, 0, n, final_chunk)
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
		-- `True' if `chunk' as no '%R' (CR) characters
		do
			chunk_string.make_shared (chunk.base_address, bytes_read)
			Result := chunk_string.index_of ('%R', 1) = 0
		end

feature {NONE} -- Implementation

	check_first_chunk (byte_count: INTEGER)
		local
			str: C_STRING_8; lt_index, gt_index: INTEGER; u: UTF_CONVERTER
		do
			str := chunk_string
			str.make_shared (chunk.base_address, byte_count)
			lt_index := str.index_of ('<', 1)
			if lt_index > 0 then
				if attached str.substring (1, lt_index - 1).to_string as leading
					and then attached u.utf_8_bom_to_string_8 as bom
				then
				-- check leading bytes before first '<'
					if leading.starts_with (bom) then
						leading.remove_head (bom.count)
					end
					leading.adjust
				-- Must exlude /usr/share/app-install/icons/gnome-oregano.svg (Linux Mint 22.2)
				-- The leading bytes are \x89PNG\r\n, which is the PNG magic header, so it's not XML.
					if leading.count = 0 then
						gt_index := str.index_of ('>', lt_index + 1)
						if gt_index > 0 and then attached str.substring (lt_index, gt_index).to_string as element then
							valid_first_chunk := True
							element.to_upper
							if element.starts_with ("<?XML") and then element.has_substring ("ISO-8859-1") then
								parser.set_scanner (Latin_1)
							end
						end
					end
				end
			end
		end

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

	read_chunk (c_str: like chunk_string)
		require
			is_readable: file_readable
		local
			byte_count, cr_index: INTEGER
		do
			if attached chunk as area then
				byte_count := file_gss (file_pointer, area.base_address, area.count)
				bytes_read := byte_count
				if not valid_first_chunk then
					check_first_chunk (byte_count)
				end
				if not valid_first_chunk then
					parse_status := Status_error
					bytes_read := 0

				elseif skip_CR_checking then
					do_nothing -- Encountered >= 5 newlines and zero CR characters, so stopped checking.
				else
					c_str.make_shared (area.base_address, byte_count)
					cr_index := c_str.index_of ('%R', 1)
					if cr_index = 0 then
						if new_line_check_count < 5 then
							new_line_occurrences := new_line_occurrences + c_str.occurrences ('%N')
							new_line_check_count := new_line_check_count + 1
							if new_line_occurrences >= 5 and then positive_CR_count = 0 then
								skip_CR_checking := True
							end
						end
					else
						positive_CR_count := positive_CR_count + 1
						read_pruned_chunk (area, c_str, cr_index)
					end
				end
			end
		end

	read_pruned_chunk (area: like chunk; c_str: C_STRING_8; cr_index: INTEGER)
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

	positive_CR_count: INTEGER

	new_line_occurrences: INTEGER

	new_line_check_count: INTEGER

	skip_CR_checking: BOOLEAN

feature {NONE} -- Constants

	EOF: INTEGER = -1

	Default_chunk_size: INTEGER = 4096

	Memory: MEMORY
		once
			create Result
		end

end
