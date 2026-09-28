note
	description: "Abstraction for ${XT_ENTITY_PARTS_LIST} and ${XT_PARAMETER_ENTITY_PARTS_LIST}"

	author: "Finnian Reilly"
	copyright: "Copyright (c) 2001-2026 Finnian Reilly"
	contact: "finnian at eiffel hyphen loop dot com"

	license: "MIT license (See: en.wikipedia.org/wiki/MIT_License)"

	date: "2026-09-01 13:45:00 GMT (Tuesday 1st September 2026)"
	revision: "1"

deferred class
	XT_ENTITY_PARTS_I

inherit
	XT_STRING_CONSTANTS

	XT_TOKEN_CONSTANTS

feature -- Status query

	is_parameter: BOOLEAN
		deferred
		end

	has_public_id: BOOLEAN
		deferred
		end

	has_system_id: BOOLEAN
		deferred
		end

	is_valid: BOOLEAN
		do
			if (has_public_id and then external_id_list.count = 2)
				or else (has_system_id and then external_id_list.count = 1)
			then
				if count > 1 then
					Result := count = 3 and i_th (2) = NDATA
				else
					Result := True
				end

			elseif count = 2 then
				Result := i_th_token (1) = Tok_name and i_th_token (2) = Tok_literal
			end
		end

feature -- Access

	external_id_type: detachable STRING
		deferred
		end

	name: STRING
		deferred
		end

	public_id: detachable STRING
		deferred
		end

	system_id: detachable STRING
		deferred
		end

	notation_name: detachable STRING
		do
			inspect count when 3 then
				if i_th (2) = NDATA then
					Result := i_th (3)
				end
			else end
		end

	value: detachable STRING
		do
			inspect count when 2 then
				Result := i_th (2)
			else end
		end

feature -- Measurement

	count: INTEGER
			-- Number of items.
		deferred
		end

feature {NONE} -- Implementation

	external_id_list: SPECIAL [STRING]
		deferred
		end

	i_th alias "[]", at alias "@" (i: INTEGER): STRING
		deferred
		end

	i_th_token (i: INTEGER): INTEGER
		deferred
		end

	token_area: SPECIAL [INTEGER]
		deferred
		end

end
