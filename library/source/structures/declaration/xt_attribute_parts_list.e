note
	description: "${XT_DECLARATION_PARTS_LIST} for `<!ATTLIST ..>' declarations"

	author: "Finnian Reilly"
	copyright: "Copyright (c) 2001-2026 Finnian Reilly"
	contact: "finnian at eiffel hyphen loop dot com"

	license: "MIT license (See: en.wikipedia.org/wiki/MIT_License)"

	date: "2026-08-26 09:34:00 GMT (Wednesday 26th August 2026)"
	revision: "1"

class
	XT_ATTRIBUTE_PARTS_LIST

inherit
	XT_DECLARATION_PARTS_LIST

create
	make

feature -- Access

	default_value: detachable STRING
		local
			last_index: INTEGER
		do
			if attached token_area as tokens and then tokens.count >= 4 then
				last_index := tokens.count - 1
				if tokens [last_index] = Tok_literal then
					inspect tokens [last_index - 1]
						when Tok_name, Tok_or then
						-- Eg. <!ATTLIST glob weight CDATA "50">
							Result := area_v2 [last_index]
						when Tok_pound_name then
							if area_v2 [last_index - 1] = Hash_fixed then
							-- Eg. <!ATTLIST mime-info xmlns CDATA
							-- 	#FIXED "http://www.freedesktop.org/standards/shared-mime-info">
								Result := area_v2 [last_index]
							end
					else
					end
				end
			end
		end

feature -- Status query

	defines_attribute_default: BOOLEAN
		-- `True' if parts list defines a default value for an attribute
		local
			i, i_final: INTEGER
		do
			if count >= 3 and then token_area [count - 1] = Tok_literal and then area_v2 [count - 2] = CDATA then
				Result := True
				from i := 0; i_final := count - 3 until i = i_final or not Result loop
					Result := token_area [i] = Tok_name
					i := i + 1
				end
			end
		end

	is_valid: BOOLEAN
		do
			Result := count >= 4
		end

	is_required: BOOLEAN
		require
			valid_list: is_valid
		do
			if attached area_v2 [3] as name then
				Result := name = Hash_fixed or else name = Hash_required
			end
		end

feature -- Basic operations

	extend_table (default_value_table: HASH_TABLE [ARRAYED_LIST [STRING], STRING])
		local
			default_values_list: ARRAYED_LIST [STRING]
		do
			if attached default_value_table [first] as list then
				default_values_list := list
			else
				create default_values_list.make (5)
				default_value_table.extend (default_values_list, first)
			end
			default_values_list.extend (i_th (2))
			default_values_list.extend (last)
		end

feature {NONE} -- Implementation

	new_filled_list (n: INTEGER): like Current
		do
			create Result.make (create {like name_cache}.make)
		end

end
