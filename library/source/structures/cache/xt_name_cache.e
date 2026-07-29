note
	description: "[
		A fast lookup cache of name strings that will enable fast C strlen in library client
		due to L1/L2 caching on CPU.
	]"
	notes: "[
		Largest vocabularies: 100 to 500 names

		XHTML/HTML5 as XML, around 120 element types
		TEI (Text Encoding Initiative): a scholarly text markup standard with over 500 element types, widely used in digital humanities
		DITA (Darwin Information Typing Architecture): technical documentation format with 200+ element types
		UBL (Universal Business Language): XML standard for business documents with hundreds of element types across many schemas
		HL7 FHIR XML:  healthcare data interchange with hundreds of resource types

		The maths for 512 buckets

		10 names across 512 buckets: average 0.02 per bucket, virtually every lookup hits an empty bucket immediately
		50 names across 512 buckets:  average 0.1 per bucket, collisions extremely rare
		200 names across 512 buckets:  average 0.4 per bucket, most buckets still empty or single entry
		500 names across 512 buckets: average 1.0 per bucket, linear search of 1-2 entries is essentially free

		At 512 buckets long linear searchs essentially never triggers, even for the largest realistic vocabularies every bucket
		has 0, 1, or occasionally 2 entries. The Linear_search_count threshold of 10 becomes largely irrelevant because no
		bucket ever gets close to it. The memory cost is genuinely negligible
	]"
	author: "Finnian Reilly`"
	copyright: "Copyright (c) 2001-2026 Finnian Reilly"
	contact: "finnian at eiffel hyphen loop dot com"

	license: "MIT license (See: en.wikipedia.org/wiki/MIT_License)"

	date: "2026-06-20 6:31:14 GMT (Saturday 20th June 2026)"
	revision: "1"

class
	XT_NAME_CACHE

inherit
	STRING_HANDLER

create
	make

feature {NONE} -- Initialization

	make
		local
			s: XT_STRING_ROUTINES
		do
			create area.make_filled (Default_list, Size)
			create utf_8_area.make_filled (Default_list, Size)
			create {XT_DEFAULT_UTF_8_CONVERTER} utf_8_converter.make
			empty_string := s.Empty_string
		end

feature -- Access

	item (buffer: SPECIAL [CHARACTER]; start_index, end_index: INTEGER): STRING
		-- UTF-8 encoded name
		require
			valid_range: start_index <= end_index
			not_empty: not is_empty
		local
			i, j, bucket_count: INTEGER; bucket_list, utf_8_bucket_list: like area.item
			found: BOOLEAN;
		do
			Result := empty_string
			i := bucket_index (buffer, start_index, end_index)
			bucket_list := area [i]
			utf_8_bucket_list := utf_8_area [i]
			if bucket_list.is_empty then
				create bucket_list.make (2)
				create utf_8_bucket_list.make (2)

				area [i] := bucket_list
				utf_8_area [i] := utf_8_bucket_list

			elseif attached bucket_list.area as l_area then
			-- search for match
				bucket_count := bucket_list.count
				from j := 0 until j = bucket_count or found loop
					if same_string (buffer, start_index, end_index, l_area [j]) then
						Result := utf_8_area [i][j + 1]
						found := True
					else
						j := j + 1
					end
				end
			end
			if not found then
				Result := buffer_string_8 (buffer, start_index, end_index)
				bucket_list.extend (Result)
				Result := new_utf_8 (Result)
				utf_8_bucket_list.extend (Result)
				check
					well_distributed_hash_indices: across area as list all list.count <= 3 end
				end
			end
		ensure
			found_or_created: Result /= empty_string
			null_terminated: Result.area [Result.count] = '%U'
		end

feature -- Element change

	set_utf_8_converter (a_utf_8_converter: XT_UTF_8_CONVERTER)
		do
			utf_8_converter := a_utf_8_converter
		end

feature -- Status report

	is_empty: BOOLEAN
			-- Is structure empty?
		do
			Result := area.count = 0
		end

feature {XT_PARSING_BUFFERS} -- Implementation

	buffer_string_8 (buffer: SPECIAL [CHARACTER]; start_index, end_index: INTEGER): STRING_8
			-- Buffer bytes [start_index .. end_index) as a STRING_8.
			-- UTF-8 bytes are copied as-is; correct on UTF-8 terminals.
		local
			count: INTEGER
		do
			count := end_index - start_index + 1
			create Result.make (count)
			Result.area.copy_data (buffer, start_index, 0, count)
			Result.set_count (count)
			Result.area [count] := '%U'
		end

feature {NONE} -- Implementation

	hash_index, bucket_index (buffer: SPECIAL [CHARACTER]; start_index, end_index: INTEGER): INTEGER
		-- very fast well distributed hash with only 3 components
		local
			first, last, count: NATURAL
		do
			first := buffer [start_index].natural_32_code
			count := (end_index - start_index + 1).to_natural_32
			inspect count when 1 then
				Result := size_remainder (first * Golden_ratio, first * Golden_ratio |>> 8)
			else
				last := buffer [end_index].natural_32_code
				Result := size_remainder (first |<< 4, (last |<< 1).bit_xor (count))
			end
		end

	new_utf_8 (name: STRING): STRING
		local
			utf_8_count: INTEGER
		do
			inspect utf_8_converter.char_width
				when 2 then
				-- From UTF-16
					Result := utf_8_converter.as_utf_8 (name, True)
			else
				utf_8_count := utf_8_converter.utf_8_bytes_count (name.area, 0, name.count - 1)
				if utf_8_count = name.count then
					Result := name
				else
					Result := utf_8_converter.as_utf_8 (name, True)
				end
			end
		end

	same_string (buffer: SPECIAL [CHARACTER]; start_index, end_index: INTEGER; name: STRING_8): BOOLEAN
		local
			i, count: INTEGER
		do
			count := end_index - start_index + 1
			if count = name.count and then attached name.area as l_area then
				Result := True
				from i := 0 until i = count or not Result loop
					if l_area [i] = buffer [start_index + i] then
						i := i + 1
					else
						Result := False
					end
				end
			end
		end

	size_remainder (a, b: NATURAL): INTEGER
		do
			Result := a.bit_xor (b).integer_remainder (Size.to_natural_32).to_integer_32
		ensure
			positive: Result >= 0
		end

feature {NONE} -- Internal attributes

	area: SPECIAL [ARRAYED_LIST [STRING]]

	empty_string: STRING_8

	utf_8_area: SPECIAL [ARRAYED_LIST [STRING]]
		-- encoded version of name strings especially UTF-16

	utf_8_converter: XT_UTF_8_CONVERTER

feature {NONE} -- Constants

	Golden_ratio: NATURAL = 2654435769

	Size: INTEGER = 512

	Default_list: ARRAYED_LIST [STRING]
		once ("PROCESS")
			create Result.make (0)
		end
end
