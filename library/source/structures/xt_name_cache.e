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
	XT_STRING_ROUTINES_I
		export
			{NONE} all
		end

create
	make

feature {NONE} -- Initialization

	make
		do
			create area.make_filled (Default_bucket, Size)
		end

feature -- Access

	item (buffer: SPECIAL [CHARACTER]; start_index, end_index: INTEGER): STRING
		-- UTF-8 encoded name
		require
			valid_range: start_index <= end_index
			not_empty: not is_empty
		local
			i, j, bucket_count: INTEGER; bucket: like area.item
			found: BOOLEAN;
		do
			Result := empty_string
			i := bucket_index (buffer, start_index, end_index)
			bucket := area [i]
			if bucket = Default_bucket then
				create bucket.make_empty (5)

				area [i] := bucket

			else
			-- search for match
				bucket_count := bucket.count
				from j := 0 until j = bucket_count or found loop
					if same_string (buffer, start_index, end_index, bucket [j]) then
						Result := bucket [j]
						found := True
					else
						j := j + 1
					end
				end
			end
			if not found then
				Result := buffer_string_8 (buffer, start_index, end_index)
				if bucket.count + 1 > bucket.capacity then
					bucket := bucket.aliased_resized_area (bucket.capacity + bucket.capacity // 2)
					area [i] := bucket
				end
				bucket.extend (Result)
				check
					well_distributed_hash_indices: across area as a all a /= Default_bucket implies a.count <= 5 end
				end
			end
		ensure
			found_or_created: Result /= empty_string
			null_terminated: Result.area [Result.count] = '%U'
		end

feature -- Status report

	is_empty: BOOLEAN
			-- Is structure empty?
		do
			Result := area.count = 0
		end

feature -- Basic operations

	reset
		local
			i: INTEGER
		do
			if attached area as a then
				from i := 0 until i = Size loop
					a [i].wipe_out
					i := i + 1
				end
			end
		end

feature {XT_PARSING_BUFFERS} -- Implementation

	buffer_string_8 (buffer: SPECIAL [CHARACTER]; start_index, end_index: INTEGER): STRING_8
			-- Buffer bytes [start_index .. end_index) as a STRING_8.
			-- UTF-8 bytes are copied as-is; correct on UTF-8 terminals.
		local
			s: XT_STRING_ROUTINES
		do
			Result := s.new_substring (buffer, start_index, end_index)
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

	same_string (buffer: SPECIAL [CHARACTER]; start_index, end_index: INTEGER; name: STRING_8): BOOLEAN
		local
			i, count: INTEGER
		do
			count := end_index - start_index + 1
			if count = name.count and then attached name.area as l_area
				and then buffer [start_index] = l_area [0]
				and then buffer [end_index] = l_area [count - 1]
			then
				Result := True
				from i := 1 until i = count loop
					if l_area [i] = buffer [start_index + i] then
						i := i + 1
					else
						i := count -- break
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

	area: SPECIAL [SPECIAL [STRING]]

feature {NONE} -- Constants

	Golden_ratio: NATURAL = 2654435769

	Size: INTEGER = 512

	Default_bucket: SPECIAL [STRING]
		once ("PROCESS")
			create Result.make_empty (0)
		end
end
