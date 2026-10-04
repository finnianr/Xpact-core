note
	description: "[
		${XT_C_STRING_CODEC} that uses a client supplied custom character mapping defined by class
		interface ${XT_CUSTOM_ENCODING}.
	]"

	author: "Finnian Reilly"
	copyright: "Copyright (c) 2001-2026 Finnian Reilly"
	contact: "finnian at eiffel hyphen loop dot com"

	license: "MIT license (See: en.wikipedia.org/wiki/MIT_License)"

	date: "2026-10-02 11:13:00 GMT (Saturday 2nd October 2026)"
	revision: "1"

class
	XT_CUSTOM_CODEC

inherit
	EL_MANAGED_C_STRING_8
		rename
			make as make_codec
		export
			{XT_C_STRING_CODEC} area
			{STRING_HANDLER} make_shared
			{NONE} all
		redefine
			make_codec, make_shared
		end

	XT_C_STRING_CODEC
		undefine
			copy, is_equal
		end

	XT_C_ENCODING_STRUCT
		undefine
			copy, is_equal
		end

create
	make, make_codec, make_shared, make_empty, make_from_string

feature {NONE} -- Initialization

	make (chunk: XT_UTF_8_CODEC; a_encoding: XT_CUSTOM_ENCODING_I)
		do
			make_shared (chunk.area, chunk.count)
			encoding := a_encoding
		end

	make_shared (a_ptr: POINTER; n: INTEGER)
		do
			Precursor (a_ptr, n)
			encoding := Default_encoding
		end

	make_codec (n: INTEGER)
		do
			Precursor (n)
			encoding := Default_encoding
		end

feature -- Basic operations

	copy_as_utf_8 (dest: SPECIAL [CHARACTER]; dest_index, n: INTEGER)
		local
			dest_full: BOOLEAN; ptr, encoding_ptr: POINTER; c_i: CHARACTER
			i, i_final, j, remaining_count: INTEGER; code_i: INTEGER
		do
			encoding_ptr := encoding.self_ptr; ptr := area; i_final := count - 1
			remaining_count := n
			from i := 0; j := dest_index until i > i_final or dest_full loop
				c_i := c_read_character_8 (ptr, i)
				inspect c_i when '%R' then
				-- skip '%R'
					i := i + 1
				else
					code_i := c_map_code (encoding_ptr, c_i.code)
					if code_i <= 0x7F then -- 0xxxxxxx
						inspect remaining_count when 0 then
							dest_full := True
						else
							dest [j] := c_i
							j := j + 1
							remaining_count := remaining_count - 1
							i := i + 1
						end

					elseif code_i < 0x7FF then -- 110xxxxx 10xxxxxx
						inspect remaining_count when 0, 1 then
							dest_full := True
						else
							dest [j] := ((code_i |>> 6) | 0xC0).to_character_8
							dest [j + 1] := ((code_i & 0x3F) | 0x80).to_character_8
							j := j + 2
							remaining_count := remaining_count - 2
							i := i + 1
						end
					elseif code_i < 0xFFFF then -- 1110xxxx 10xxxxxx 10xxxxxx
						inspect remaining_count when 0 .. 2 then
							dest_full := True
						else
							dest [j] := ((code_i |>> 12) | 0xE0).to_character_8
							dest [j + 1] := (((code_i |>> 6) & 0x3F) | 0x80).to_character_8
							dest [j + 2] := ((code_i & 0x3F) | 0x80).to_character_8
							j := j + 3
							remaining_count := remaining_count - 3
							i := i + 1
						end
					else
					-- `code_i' <= 1FFFFF - there are no higher code points
					-- 11110xxx 10xxxxxx 10xxxxxx 10xxxxxx
						inspect remaining_count when 0 .. 3 then
							dest_full := True
						else
							dest [j] := ((code_i |>> 18) | 0xF0).to_character_8
							dest [j + 1] := (((code_i |>> 12) & 0x3F) | 0x80).to_character_8
							dest [j + 2] := (((code_i |>> 6) & 0x3F) | 0x80).to_character_8
							dest [j + 3] := ((code_i & 0x3F) | 0x80).to_character_8
							j := j + 4
							remaining_count := remaining_count - 4
							i := i + 1
						end
					end
				end
			end
			utf_8_copied_count := n - remaining_count
			last_index := i
		end

feature {NONE} -- Internal attributes

	encoding: XT_CUSTOM_ENCODING_I

feature {NONE} -- Constants

	Code_unit_bytes: INTEGER = 1

	Default_encoding: XT_CUSTOM_ENCODING
		once
			create Result.make
		end
end
