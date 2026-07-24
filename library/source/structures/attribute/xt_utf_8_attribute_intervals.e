note
	description: "[
		List of indices demarking name-value attribute pair substrings in ${XT_XML_PARSER}.buffer
	]"

	author: "Finnian Reilly"
	copyright: "Copyright (c) 2001-2026 Finnian Reilly"
	contact: "finnian at eiffel hyphen loop dot com"

	license: "MIT license (See: en.wikipedia.org/wiki/MIT_License)"
	date: "2026-07-24 18:01:01 GMT (Friday 24th July 2026)"
	revision: "1"


class
	XT_UTF_8_ATTRIBUTE_INTERVALS

inherit
	XT_ATTRIBUTE_BUFFER_INTERVALS

create
	make

feature -- Status report

	valid_utf_8 (buf: SPECIAL [CHARACTER]; start_index, end_index: INTEGER): BOOLEAN
			-- True if character in `buf' from `start_index .. end_index' are already
			-- valid as UTF-8
		do
			Result := True
		end

feature {NONE} -- Factory

	new_filled_list (n: INTEGER): like Current
		do
			create Result.make (n)
		end

feature {NONE} -- Implementation

	to_utf_8 (src, dst: SPECIAL [CHARACTER]; a_src_from, end_index: INTEGER)
			-- UTF-8: copy complete characters, stopping before an incomplete
			-- trailing multi-byte sequence.  Sets consumed_from and written_to.
		local
			l_count: INTEGER
		do
			l_count := (end_index - a_src_from + 1).min (dst.capacity)
			dst.copy_data (src, a_src_from, 0, l_count)
			written_to := dst.count
		end

	to_utf_16 (src: SPECIAL [CHARACTER]; dst: SPECIAL [NATURAL_16]; a_src_from, end_index: INTEGER)
			-- Decode UTF-8 to UTF-16.  Sets consumed_from and written_to.
		local
			src_ptr, cp, b0, b1, b2, b3: INTEGER
		do
			src_ptr := a_src_from
			from until src_ptr >= end_index or dst.count = dst.capacity loop
				b0 := src [src_ptr].code
				if b0 < 0x80 then
					dst.extend (b0.to_natural_16)
					src_ptr := src_ptr + 1
				elseif b0 < 0xE0 then
					if src_ptr + 1 >= end_index then
						src_ptr := end_index
					else
						b1 := src [src_ptr + 1].code
						cp := ((b0 & 0x1F) |<< 6) | (b1 & 0x3F)
						dst.extend (cp.to_natural_16)
						src_ptr := src_ptr + 2
					end
				elseif b0 < 0xF0 then
					if src_ptr + 2 >= end_index then
						src_ptr := end_index
					else
						b1 := src [src_ptr + 1].code
						b2 := src [src_ptr + 2].code
						cp := ((b0 & 0x0F) |<< 12) | ((b1 & 0x3F) |<< 6) | (b2 & 0x3F)
						dst.extend (cp.to_natural_16)
						src_ptr := src_ptr + 3
					end
				else
					if src_ptr + 3 >= end_index or dst.count = dst.capacity then
						src_ptr := end_index
					else
						b1 := src [src_ptr + 1].code
						b2 := src [src_ptr + 2].code
						b3 := src [src_ptr + 3].code
						cp := ((b0 & 0x07) |<< 18) | ((b1 & 0x3F) |<< 12)
							| ((b2 & 0x3F) |<< 6) | (b3 & 0x3F)
						cp := cp - 0x10000
						dst.extend ((0xD800 | (cp |>> 10)).to_natural_16)
						dst.extend ((0xDC00 | (cp & 0x3FF)).to_natural_16)
						src_ptr := src_ptr + 4
					end
				end
			end
			written_to := dst.count
		end

end
