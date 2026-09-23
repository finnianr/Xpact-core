note
	description: "[
		Table of xmlns mappings bound to a name cache defined by ${XT_URI_MAPPED_NAME_CACHE}.bucket_area
		
		Example:
			rdf:RDF -> http://www.w3.org/1999/02/22-rdf-syntax-ns#
	]"

	author: "Finnian Reilly"
	copyright: "Copyright (c) 2001-2026 Finnian Reilly"
	contact: "finnian at eiffel hyphen loop dot com"

	license: "MIT license (See: en.wikipedia.org/wiki/MIT_License)"
	date: "2026-09-23 08:08:00 GMT (Monday 23rd September 2026)"
	revision: "1"

class
	XT_NAMESPACE_SCOPE

inherit
	HASH_TABLE [STRING, STRING]
		rename
			make as make_sized
		redefine
			empty_duplicate
		end

create
	make

feature -- Initialization

	make (a_cache_bucket_area: like cache_bucket_area; n: INTEGER)
		do
			make_sized (n)
			cache_bucket_area := a_cache_bucket_area
			appended_positions := Empty_positions
		end

feature -- Access

	depth: INTEGER
		-- element depth of scope

	cache_bucket_area: SPECIAL [SPECIAL [XT_URI_MAPPED_NAME]]
		-- name cache `bucket_area' from `XT_URI_MAPPED_NAME_CACHE'

feature -- Element change

	append (uri_table: HASH_TABLE [STRING, STRING])
		-- add new entries from `uri_table' and overwrite (shadow) existing ones.
		do
			if attached uri_table as table then
				from table.start until table.after loop
					force (table.item_for_iteration, table.key_for_iteration)
					table.forth
				end
			-- record appended item positions for `endNamespaceDeclHandler'
				create appended_positions.make_empty (uri_table.count)
				from table.start until table.after loop
					internal_search (table.key_for_iteration)
					appended_positions.extend (item_position)
					table.forth
				end
			end
		end

	set_depth (a_depth: INTEGER)
		do
			depth := a_depth
		end

	set_cache_bucket_area (a_cache_bucket_area: like cache_bucket_area)
		do
			cache_bucket_area := a_cache_bucket_area
		end

feature {NONE} -- Duplication

	empty_duplicate (n: INTEGER): like Current
			-- Create an empty copy of Current that can accommodate `n' items
		do
			create Result.make (create {like cache_bucket_area}.make_empty (0), n)
			if object_comparison then
				Result.compare_objects
			end
		end

feature {NONE} -- Internal attributes

	appended_positions: SPECIAL [INTEGER]

feature {NONE} -- Constants

	Empty_positions: SPECIAL [INTEGER]
		once
			create Result.make_empty (0)
		end

end
