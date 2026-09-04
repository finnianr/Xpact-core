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
			make, on_name, on_operator, wipe_out, is_valid, is_OR_token_appended, valid_complex_type
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

feature {NONE} -- Contract support

	is_OR_token_appended (token: INTEGER): BOOLEAN
		do
			Result := True
		end

	valid_complex_type (token: INTEGER): BOOLEAN
		do
			Result := True
		end

feature -- Event handlers

	on_close
		do
			inspect count when 2 then
				if i_th (2) = EMPTY and then attached borrowed as l_particle then
					l_particle.set_type_and_quantifier (CT_empty, QT_none)
					particle := l_particle
				end
			else end
		end

	on_name (a_name: STRING; token: INTEGER)
		do
			if stack.count > 0 and then attached borrowed as name_particle then
				if a_name = Hash_PCDATA then
					stack.item.set_type (CT_mixed)
				else
					name_particle.set_name (a_name) -- sets default quantifier
					name_particle.set_quantifier (quantifier (token))
					stack.item.add (name_particle)
				end
			end
		ensure then
			valid_name_quantifier: (stack.count > 0 and then a_name /= Hash_PCDATA)
												implies stack.item.particle_list.last.quantifier = quantifier (token)
		end

	on_operator (token: INTEGER)
		-- change parsing state for '(', ')' or '|' operators
		local
			l_particle: XT_ELEMENT_PARTICLE
		do
			inspect token
				when Tok_open_parenthesis then
					if stack.count = 0 then
						state := State_building
					end
					l_particle := borrowed
					l_particle.set_type_and_quantifier (CT_sequence, QT_none)
					stack.put (l_particle)

				when Tok_comma then
					inspect stack.count when 0 then
						do_nothing
					else
						stack.item.set_type (CT_sequence)
					end

				when Tok_or then
					l_particle := stack.item
					inspect stack.count when 0 then
						do_nothing
					else
						if l_particle.type /= CT_mixed then
							l_particle.set_type (CT_choice)
						end
					end

				when Tok_close_parenthesis, Tok_close_paren_plus, Tok_close_paren_question, Tok_close_paren_asterisk then
					inspect stack.count when 0 then
							do_nothing
					else
						l_particle := stack.item
						l_particle.set_quantifier (quantifier (token))
						inspect stack.count
							when 0 then
								do_nothing

							when 1 then
								particle := l_particle
								stack.remove
								state := State_extending
						else
							stack.remove
							stack.item.add (l_particle)
						end
					end

				when Tok_name_question, Tok_name_asterisk, Tok_name_plus then
					inspect stack.count
						when 0 then
							do_nothing
						when 1 then
							l_particle := stack.item
							if attached borrowed as name_particle then
								name_particle.set_name (last_name) -- sets default quantifier
								name_particle.set_type_and_quantifier (CT_name, quantifier (token))
								l_particle.add (name_particle)
							end
					else
					end

			else
			end
		end

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

	wipe_out
		-- Remove all items.
		do
			Precursor
			if attached particle as l_particle then
				l_particle.recycle (particle_pool)
				particle := Void
			end
			stack.wipe_out
		end

	 quantifier (token: INTEGER): INTEGER
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
