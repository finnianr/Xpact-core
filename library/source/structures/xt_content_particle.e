note
	description: "[
		Eiffel representation of the eXpat ${XML_Content} struct (declared as `struct XML_cp'
		in expat.h), describing one particle of an element's content model as reported to
		${XML_ElementDeclHandler}.

		Corresponds to the C fields as follows:
			enum XML_Content_Type type   -> `type'              (CT_* constants)
			enum XML_Content_Quant quantity_type -> `quantity_type'              (QT_* constants)
			XML_Char *name               -> `name'               (set only when `type' is `CT_name')
			unsigned int numparticleren     -> `numparticleren'         (derived from `sub_particle_list.count')
			XML_Content *particleren        -> `sub_particle_list'    (sub-particles, dynamically grown)
	]"

	author: "Finnian Reilly"
	copyright: "Copyright (c) 2001-2026 Finnian Reilly"
	contact: "finnian at eiffel hyphen loop dot com"

	license: "MIT license (See: en.wikipedia.org/wiki/MIT_License)"
	date: "2026-09-02 06:05:00 GMT (Wednesday 2nd September 2026)"
	revision: "1"

class
	XT_CONTENT_PARTICLE

inherit
	XT_CONTENT_CONSTANTS

create
	make, make_named

feature {NONE} -- Initialization

	make_named (a_type, a_quantity_type: INTEGER; a_name: STRING)
		do
			make (a_type, a_quantity_type)
			name := a_name
		ensure
			name_set: name = a_name
		end

	make (a_type, a_quantity_type: INTEGER)
			-- Create a content particle of `a_type', quantity_typeified by `a_quantity_type', named `a_name'
			-- (only meaningful when `a_type' is `CT_name').
		do
			type := a_type; quantity_type := a_quantity_type
			sub_particle_list := Default_sub_particle_list
		ensure
			type_set: type = a_type
			quantity_type_set: quantity_type = a_quantity_type
			no_particleren: sub_particle_list.is_empty
		end

feature -- Access

	type: INTEGER
			-- Kind of content particle: one of the CT_* constants.

	quantity_type: INTEGER
			-- Number of times `Current' may occur: one of the QT_* constants.

	name: detachable STRING
			-- Element name, present only when `type' is `CT_name'.

	sub_particle_list: like Default_sub_particle_list
		-- Sub-particles, populated when `type' is `CT_mixed', `CT_choice' or `CT_sequence'.
		-- Shares `Default_sub_particle_list' until the first call to `add_particle'.

feature -- Measurement

	numparticleren: INTEGER
			-- Count of `sub_particle_list' (mirrors the `numparticleren' field of the C struct).
		do
			Result := sub_particle_list.count
		end

feature -- Element change

	set_type (a_type: INTEGER)
		do
			type := a_type
		ensure
			type_set: type = a_type
		end

	set_quantity_type (a_quantity_type: INTEGER)
		do
			quantity_type := a_quantity_type
		ensure
			quantity_type_set: quantity_type = a_quantity_type
		end

	set_name (a_name: STRING)
		do
			name := a_name
		ensure
			name_set: name = a_name
		end

	add_named_particle (a_type, a_quantity_type: INTEGER; a_name: STRING)
		do
			add_particle (a_type, a_quantity_type)
			sub_particle_list.last.set_name (a_name)
		end

	add_particle (a_type, a_quantity_type: INTEGER; a_name: detachable STRING)
			-- Create a new content particle of `a_type', `a_quantity_type' and `a_name'
			-- and append it to `sub_particle_list'.
		local
			particle: like Current
		do
			if sub_particle_list = Default_sub_particle_list then
				create sub_particle_list.make (1)
			end
			create particle.make (a_type, a_quantity_type, a_name)
			sub_particle_list.extend (particle)
		ensure
			particle_added: sub_particle_list.count = old sub_particle_list.count + 1
		end

feature {NONE} -- Constants

	Default_sub_particle_list: ARRAYED_LIST [XT_CONTENT_PARTICLE]
			-- Shared empty list used as the initial value of `sub_particle_list' for particles
			-- with no particleren, to avoid a per-particle allocation until `add_particle' is called.
		once
			create Result.make (0)
		end

end
