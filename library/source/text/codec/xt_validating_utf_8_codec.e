note
	description: "[
		${XT_UTF_8_CODEC} is for text where there is only an assumption that it is UTF-8 and no
		indication like a BOM or XML encoding declaration.
	]"
	author: ""
	date: "$Date$"
	revision: "$Revision$"

class
	XT_VALIDATING_UTF_8_CODEC

inherit
	XT_UTF_8_CODEC
		redefine
			copy_as_utf_8, not_well_formed, reset
		end

	XT_UTF_8_VALIDATION
		undefine
			copy, is_equal
		end

create
	make_shared, make_empty, make_from_string

feature -- Status query

	not_well_formed: BOOLEAN

	partial_sequence: BOOLEAN

feature -- Element change

	reset
		do
			not_well_formed := False
			partial_sequence := False
		end

feature -- Basic operations

	copy_as_utf_8 (dest: SPECIAL [CHARACTER]; dest_index, n: INTEGER)
		local
			ptr: POINTER; i, j, i_final, bt_code, byte_count: INTEGER; c: CHARACTER
			bt_table: like Byte_type_table; done: BOOLEAN; sequence: SPECIAL [CHARACTER]
		do
			bt_table := Byte_type_table; ptr := area; sequence := Sequence_buffer
			i_final := count.min (n) - 1
			i := 0; j := dest_index; not_well_formed := False

			if partial_sequence and then sequence.count > 0 then
				bt_code := bt_table [sequence [0].code]
				byte_count := bt_code - 3
				check
					enough_room: byte_count <= sequence.capacity
				end
				from until sequence.count = byte_count loop
					sequence.extend (read_character (i))
					i := i + 1
					i_final := i_final - 1
				end
				dest.copy_data (sequence, 0, j, byte_count)
				j := j + byte_count
				partial_sequence := False

			elseif pending_CR then
			-- The last chunked ended with a CR
				inspect read_character_8 (ptr, i) when '%N' then
					do_nothing
				else
				-- replace isolated '%R' with '%N'
					dest [j] := '%N'
					i_final := i_final - 1 -- reduce the number of remaining characters
					j := j + 1
				end
				pending_CR := False
			end
			from until i > i_final or done loop
				c := read_character_8 (ptr, i); bt_code := bt_table [c.code]
				inspect bt_code
					when BT_CR then
						i := i + 1 -- skip '%R'
						if i > i_final then
						-- find out in next chunk if characters is Newline
							pending_CR := True
						else
							inspect read_character_8 (ptr, i) when '%N' then
								do_nothing
							else
							-- replace isolated '%R' with '%N'
								dest [j] := '%N'
								j := j + 1
							end
						end
					when BT_non_xml, BT_malform, BT_continuation_byte then
						not_well_formed := True; done := True

					when BT_lead_2_byte, BT_lead_3_byte, BT_lead_4_byte then
						byte_count := bt_code - 3
						fill (sequence, i, byte_count.min (i_final - i + 1))
						if sequence.count < byte_count then
							partial_sequence := True; done := True

						elseif is_invalid_character (sequence, 0, byte_count) then
							not_well_formed := True; done := True
						else
							i := i + byte_count
							dest.copy_data (sequence, 0, j, byte_count)
							j := j + byte_count
						end

				else
					dest [j] := c
					j := j + 1
					i := i + 1
				end
			end
			if not not_well_formed then
				last_index := i
				utf_8_copied_count := j - dest_index
			end
		end

feature {NONE} -- Implementation

	fill (sequence: SPECIAL [CHARACTER]; offset, n: INTEGER)
		local
			i: INTEGER
		do
			sequence.wipe_out
			from i := 0 until i = n loop
				sequence.extend (read_character (i + offset))
				i := i + 1
			end
		end

feature {NONE} -- Constants

	Sequence_buffer: SPECIAL [CHARACTER]
		once ("OBJECT")
			create Result.make_empty (4)
		end
end
