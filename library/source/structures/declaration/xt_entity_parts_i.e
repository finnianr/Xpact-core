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

	is_public: BOOLEAN
		deferred
		end

	is_system: BOOLEAN
		do
			Result := count >= 2 and then i_th (2) = SYSTEM
		end

	is_valid: BOOLEAN
		do
			if is_public then
				inspect count when 4 .. 6 then
					if i_th_token (3) = Tok_literal then
						if count > 4 then
							Result := count = 6 and i_th (5) = NDATA
						else
							Result := True
						end
					end
				else
				end
			elseif is_system then
				inspect count when 3 .. 5 then
					if i_th_token (3) = Tok_literal then
						if count > 3 then
							Result := count = 5 and i_th (4) = NDATA
						else
							Result := True
						end
					end
				else
				end

			elseif count = 2 then
				Result := i_th_token (1) = Tok_name and i_th_token (2) = Tok_literal
			end
		end

feature -- Access

	name: STRING
		deferred
		end

	public_id: detachable STRING
		do
			if is_public and then count >= 3 then
				Result := i_th (3)
			end
		end

	system_id: detachable STRING
		local
			offset: INTEGER
		do
			offset := is_public.to_integer
			if count >= 3 + offset then
				Result := i_th (3 + offset)
			end
		end

	notation_name: detachable STRING
		local
			offset: INTEGER
		do
			offset := is_public.to_integer
			if count = 5 + offset and i_th (4 + offset) = NDATA then
				Result := i_th (5 + offset)
			end
		end

	value: detachable STRING
		do
			if count = 2 then
				Result := i_th (2)
			end
		end

feature -- Measurement

	count: INTEGER
			-- Number of items.
		deferred
		end

feature {NONE} -- Implementation

	i_th alias "[]", at alias "@" (i: INTEGER): STRING
		deferred
		end

	i_th_token (i: INTEGER): INTEGER
		deferred
		end

end
