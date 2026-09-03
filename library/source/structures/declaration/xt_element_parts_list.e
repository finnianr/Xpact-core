note
	description: "${XT_DECLARATION_PARTS_LIST} for `<!ELEMENT ..>' declarations"

	author: "Finnian Reilly"
	copyright: "Copyright (c) 2001-2026 Finnian Reilly"
	contact: "finnian at eiffel hyphen loop dot com"

	license: "MIT license (See: en.wikipedia.org/wiki/MIT_License)"

	date: "2026-09-02 10:16:00 GMT (Wednesday 2nd September 2026)"
	revision: "1"

class
	XT_ELEMENT_PARTS_LIST

inherit
	XT_DECLARATION_PARTS_LIST
		redefine
			make, on_operator, wipe_out, is_valid
		end

	XT_ELEMENT_PARTICLE_CONSTANTS
		undefine
			copy, is_equal
		end

create
	make

feature {NONE} -- Initialization

	make (a_name_cache: like name_cache)
		do
			Precursor (a_name_cache)
			create particle_pool.make (10)
			create stack.make (10)
		end

feature -- Status query

	is_valid: BOOLEAN
		do
			Result := count >= 1 and then stack.is_empty
		end

feature -- Access

	particle: detachable XT_ELEMENT_PARTICLE

feature {NONE} -- Implementation

	borrowed: XT_ELEMENT_PARTICLE
		-- element particle borrowed from pool or created for later recyling
		do
			if attached particle_pool as pool and then pool.count > 0 then
				Result := pool.item
				pool.remove
			else
				create Result.make
			end
		end

	on_operator (token: INTEGER)
		-- change parsing state for '(', ')' or '|' operators
		local
			l_particle: XT_ELEMENT_PARTICLE
		do
			inspect token
				when Tok_open_parenthesis then
					state := State_building
					l_particle := borrowed
					l_particle.set_type_and_quantity (CT_sequence, QT_none)
					particle := l_particle

					stack.put (l_particle)

				when Tok_close_parenthesis, Tok_close_paren_plus, Tok_close_paren_question, Tok_close_paren_asterisk then
					inspect stack.count
						when 0 then
							do_nothing
						when 1 then
							l_particle := stack.item
							l_particle.set_quantity (quantity (token))
							if attached borrowed as name_particle then
								name_particle.set_type_and_quantity (CT_name, QT_none)
								name_particle.set_name (last_name)
								l_particle.add (name_particle)
							end
							stack.remove
					else
						stack.remove
					end
					state := State_extending

				when Tok_name_question, Tok_name_asterisk, Tok_name_plus then
					inspect stack.count
						when 0 then
							do_nothing
						when 1 then
							l_particle := stack.item
							if attached borrowed as name_particle then
								name_particle.set_type_and_quantity (CT_name, quantity (token))
								name_particle.set_name (last_name)
								l_particle.add (name_particle)
							end
					else
					end

			else
			end
		end

	wipe_out
		-- Remove all items.
		do
			Precursor
			if stack.count = 1 then
				stack.item.recycle (particle_pool)
			end
			stack.wipe_out
		end

	 quantity (token: INTEGER): INTEGER
	 	do
			inspect token
				when Tok_close_parenthesis then
					Result := QT_none

				when Tok_close_paren_plus, Tok_name_plus then
					Result := QT_plus

				when Tok_close_paren_question, Tok_name_question then
					Result := QT_option

				when Tok_close_paren_asterisk, Tok_name_asterisk then
					Result := QT_repetition

			else end

	 	end

feature {NONE} -- Internal attributes

	particle_pool: ARRAYED_STACK [XT_ELEMENT_PARTICLE]

	stack: ARRAYED_STACK [XT_ELEMENT_PARTICLE]
		-- expression building stack
end
