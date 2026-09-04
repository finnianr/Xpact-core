note
	description: "[
		Eiffel wrapper, with managed memory, for the C struct `XT_particle' (typedef'd as
		`XT_element_particle') defined in `xt_structs.h'. Field-for-field, this struct is
		laid out the same as eXpat's own ${XML_Content} struct (`struct XML_cp' in
		expat.h): a NATURAL `type', a NATURAL `quantifier', a `name' string pointer, a
		NATURAL `list_count' and a `particle_list' pointer to a contiguous run of
		`list_count' further `XT_element_particle' cells.
	]"

	author: "Finnian Reilly"
	copyright: "Copyright (c) 2001-2026 Finnian Reilly"
	contact: "finnian at eiffel hyphen loop dot com"

	license: "MIT license (See: en.wikipedia.org/wiki/MIT_License)"
	date: "2026-09-03 06:47:36 GMT (Thursday 3rd September 2026)"
	revision: "1"

class
	XT_ELEMENT_PARTICLE

inherit
	EL_ALLOCATED_C_OBJECT
		rename
			count as byte_count,
			c_size_of as struct_size
		end

	XT_ELEMENT_PARTICLE_C_API
		rename
			c_size_of as struct_size
		export
			{ANY} struct_size
		undefine
			copy, is_equal
		end

	XT_ELEMENT_PARTICLE_CONSTANTS
		undefine
			copy, is_equal
		end

	EL_STRING_H_C_API
		undefine
			copy, is_equal
		end

	DEBUG_OUTPUT
		undefine
			copy, is_equal
		end

create
	make, make_shareable

feature {NONE} -- Initialization

	make
			-- Allocate the C struct and set its `type' and `quantifier' fields.
			-- `list_count' starts at 0 and `particle_list' starts empty.
		do
			make_default
			set_defaults
			particle_list := Default_particle_list
			c_struct_particle_list := Default_c_struct_particle_list
			c_set_particle_list (self_ptr, c_struct_particle_list.item)
		end

	make_shareable
		do
			share_from_pointer (default_pointer, 0)
			particle_list := Default_particle_list
			c_struct_particle_list := Default_c_struct_particle_list
		end

feature -- Access

	debug_output: STRING
		local
			s: XT_STRING_8_ROUTINES
		do
			Result := s.substitute (Output_template, <<
				attached_name, Content_names [type], Quantifier_names [quantifier + 1], list_count.out
			>>)
		end

	type: INTEGER
			-- Kind of content particle: one of the CT_* constants.
		do
			Result := c_type (self_ptr)
		end

	quantifier: INTEGER
			-- Number of times `Current' may occur: one of the QT_* constants.
		do
			Result := c_quantifier (self_ptr)
		end

	name: detachable STRING

	name_ptr: POINTER
			-- Raw `name' field: a null-terminated C string, or `default_pointer'
			-- when `type' is not `CT_name'.
		do
			Result := c_name (self_ptr)
		end

	particle_list: ARRAYED_LIST [XT_ELEMENT_PARTICLE]

feature -- Basic operations

	append_to_crc_32 (checksum: EL_CRC_32_DIGEST)
		local
			i: INTEGER; ptr: POINTER
		do
			checksum.add_integer_32 (type)
			checksum.add_integer_32 (quantifier)
			ptr := name_ptr
			if attached name as l_name then
				checksum.add_string (l_name)
			end
			checksum.add_integer_32 (list_count)
			if attached particle_list.area as l_area then
				from i := 0 until i = l_area.count loop
					l_area [i].append_to_crc_32 (checksum) -- recurse
					i := i + 1
				end
			end
		end

feature -- Element change

	add (child: XT_ELEMENT_PARTICLE)
		local
			old_count: INTEGER
		do
			if particle_list = Default_particle_list then
				create particle_list.make (5)
				create c_struct_particle_list.make (particle_list.capacity * struct_size)
			end
			old_count := particle_list.count
			particle_list.extend (child)
			if particle_list.capacity > c_struct_particle_list.count // struct_size then
				c_struct_particle_list.resize (particle_list.capacity * struct_size)
				c_set_particle_list (self_ptr, c_struct_particle_list.item)
			end
			(c_struct_particle_list.item + old_count * struct_size).memory_copy (child.self_ptr, struct_size)
			c_set_particle_list_count (self_ptr, (old_count + 1).to_natural_32)
		ensure
			c_list_count_agrees: list_count = particle_list.count
			c_struct_particle_list_set: child.same_as (last_shared)
		end

	set_defaults
		do
			c_set_type (self_ptr, CT_any)
			c_set_quantifier (self_ptr, QT_none)
			c_set_particle_list_count (self_ptr, 0)
			c_set_name (self_ptr, default_pointer)
		end

	set_type_and_quantifier (a_type, a_quantity: INTEGER)
		do
			c_set_type (self_ptr, a_type)
			c_set_quantifier (self_ptr, a_quantity)
		ensure
			type_set: type = a_type
			quantity_set: quantifier = a_quantity
		end

	set_type (a_type: INTEGER)
		do
			c_set_type (self_ptr, a_type)
		ensure
			type_set: type = a_type
		end

	set_quantifier (a_quantity: INTEGER)
		do
			c_set_quantifier (self_ptr, a_quantity)
		ensure
			quantity_set: quantifier = a_quantity
		end

	set_name (a_name: detachable STRING)
			-- Set the raw `name' field to `a_pointer'
			-- Either a null-terminated C string, or `default_pointer'.
			-- Ownership/lifetime of the pointed-to memory is the caller's responsibility.
		local
			to_c: ANY
		do
			name := a_name
			if attached a_name as l_name then
				to_c := l_name.to_c
				c_set_name (self_ptr, $to_c)
				set_type_and_quantifier (CT_name, QT_none)
			else
				c_set_name (self_ptr, default_pointer)
			end
		ensure
			name_set: name = a_name
			c_name_agrees: attached name as l_name implies new_c_name.to_string ~ l_name
		end

	recycle (particle_pool: ARRAYED_STACK [XT_ELEMENT_PARTICLE])
		local
			i: INTEGER
		do
			if attached particle_list.area as l_area then
				from i := 0 until i = l_area.count loop
					l_area [i].recycle (particle_pool) -- recurse
					i := i + 1
				end
			end
			particle_pool.put (Current)
			wipe_out
		end

	wipe_out
		do
			set_defaults
			particle_list.wipe_out
		end

feature {XT_ELEMENT_PARTICLE} -- Implementation

	attached_name: STRING
		local
			s: XT_STRING_8_ROUTINES
		do
			if attached name as l_name then
				Result := l_name
			else
				Result := s.Empty_string
			end
		end

	list_count: INTEGER
		do
			Result := c_list_count (self_ptr).to_integer_32
		end

	last_shared: XT_ELEMENT_PARTICLE
		-- last item of C struct particle_list
		do
			Result := Shared_particle
			Result.set_shared (c_struct_particle_list, list_count - 1)
		end

	new_c_name: EL_MANAGED_C_STRING_8
		local
			ptr: POINTER
		do
			ptr := name_ptr
			if is_attached (ptr) then
				create Result.make_shared (ptr, c_string_8_length (ptr))
			else
				create Result.make_empty
			end
		end

	same_as (other: XT_ELEMENT_PARTICLE): BOOLEAN
		do
			if type = other.type and then quantifier = other.quantifier and then list_count = other.list_count then
				Result := attached_name ~ other.attached_name
			end
		end

	set_shared (a_struct_particle_list: MANAGED_POINTER; i: INTEGER)
		require
			is_shared: is_shared
			valid_index: 0 < i and then i < a_struct_particle_list.count // struct_size
		local
			ptr: POINTER
		do
			self_ptr := a_struct_particle_list.item + i * struct_size
			ptr := name_ptr
			if is_attached (ptr) then
				Shared_string.from_c (ptr)
				name := Shared_string
			else
				name := Void
			end
		end

feature {NONE} -- Internal attributes

	c_struct_particle_list: MANAGED_POINTER
			-- Backing buffer for the C struct's `particle_list' field: a contiguous
			-- array of `c_struct_list_capacity' `XT_element_particle'-sized cells, of which
			-- `list_count' are populated. Reallocated (never shared) by `grow_to_fit'.

feature {NONE} -- Constants

	Default_c_struct_particle_list: MANAGED_POINTER
		once
			create Result.share_from_pointer (default_pointer, 0)
		end

	Default_particle_list: ARRAYED_LIST [XT_ELEMENT_PARTICLE]
		once
			create Result.make (0)
		end

	Output_template: STRING = "%S: type = %S; quantity = %S; list_count = %S"

	Shared_particle: XT_ELEMENT_PARTICLE
		once
			create Result.make_shareable
		end

	Shared_string: STRING
		once
			create Result.make_empty
		end

invariant
	valid_c_struct_particle_list_size: c_struct_particle_list.count.integer_remainder (struct_size) = 0
	c_struct_list_mirrors_particle_list: c_struct_particle_list.count // struct_size = particle_list.capacity
	c_child_count_agrees_with_particle_list: list_count = particle_list.count

end
