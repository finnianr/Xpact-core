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
	XT_STRING_8_ROUTINES_I
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

feature -- Measurement

	average_bucket_item_count: INTEGER
		local
			count, item_count: INTEGER
		do
			across area as bucket loop
				if bucket.count > 0 then
					count := count + 1
					item_count := item_count + bucket.count
				end
			end
			Result := (item_count / count).rounded
		end

	buckets_used_count: INTEGER
		do
			across area as bucket loop
				if bucket.count > 0 then
					Result := Result + 1
				end
			end
		end

feature -- Access

	bucket_distribution_gt_1: XT_NAME_OCCURRENCE_COUNT_TABLE
		do
			create Result.make (50)
			across area as bucket loop
				if bucket.count > 1 then
					Result.put (substitute (Stats_template, << bucket.count.out >>))
				end
			end
		end

	item (buffer: SPECIAL [CHARACTER]; start_index, end_index, colon_index: INTEGER): like Default_string
		-- UTF-8 encoded name
		require
			valid_range: start_index <= end_index
			not_empty: not is_empty
			valid_colon_index: colon_index > 0 implies buffer [colon_index] = ':'
		local
			i, j, bucket_count: INTEGER; bucket: like area.item
			found: BOOLEAN;
		do
			Result := Default_string
			inspect colon_index when 0 then
				i := bucket_index (buffer, start_index, end_index)
			else
			-- proveably better distribution if you use character after ':'
				i := bucket_index (buffer, colon_index + 1, end_index)
			end
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
				-- Tested mandarin-names-and-text.xsl
					well_distributed_hash_indices: bucket.count <= 4
				end
			end
		ensure
			found_or_created: Result /= Default_string
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

	print_stats
		do
			IO.put_string ("NAME CACHING")
			IO.put_new_line
			IO.put_string ("Buckets used count: ")
			IO.put_integer (buckets_used_count)
			IO.put_new_line
			IO.put_string ("Average hash bucket count: ")
			IO.put_integer (average_bucket_item_count)
			IO.put_new_line
			IO.put_string ("Hash bucket counts greater than 1")
			IO.put_string (":%N")
			if attached bucket_distribution_gt_1.sorted_occurrence_list (False) as sorted_list then
				if sorted_list.count = 0 then
					print ("None")
				else
					across sorted_list as bucket_count loop
						print ("   ")
						bucket_count.io_print
					end
				end
			end
			IO.put_new_line
		end

feature {NONE} -- Implementation

	buffer_string_8 (buffer: SPECIAL [CHARACTER]; start_index, end_index: INTEGER): like Default_string
			-- Buffer bytes [start_index .. end_index) as a STRING_8.
			-- UTF-8 bytes are copied as-is; correct on UTF-8 terminals.
		local
			s: XT_STRING_8_ROUTINES
		do
			Result := s.new_substring (buffer, start_index, end_index)
		end

	hash_index, bucket_index (buffer: SPECIAL [CHARACTER]; start_index, end_index: INTEGER): INTEGER
		-- very fast well distributed hash with only 3 components
		local
			first, last, count: NATURAL; i, utf_byte_count: INTEGER
		do
			count := (end_index - start_index + 1).to_natural_32
			inspect count
				when 1 then
					first := buffer [start_index].natural_32_code
					Result := size_remainder (first * Golden_ratio, first * Golden_ratio |>> 8)
				when 2 .. 4 then
					first := buffer [start_index].natural_32_code
					last := buffer [end_index].natural_32_code
					Result := size_remainder (first |<< 4, (last |<< 1).bit_xor (count))

			else
				first := buffer [start_index].natural_32_code
				if first > 0x7F then
					if first <= 0x7FF then
						-- 110xxxxx 10xxxxxx
						utf_byte_count := 2

					elseif first <= 0xFFFF then
						-- 1110xxxx 10xxxxxx 10xxxxxx
						utf_byte_count := 3
					else
						-- first <= 1FFFFF - there are no higher code points
						-- 11110xxx 10xxxxxx 10xxxxxx 10xxxxxx
						utf_byte_count := 4
					end
					from i := 1 until i = utf_byte_count loop
						first := (first |<< 8) | buffer [start_index + i].natural_32_code
						i := i + 1
					end
				end
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

	area: SPECIAL [like Default_bucket]

feature {NONE} -- Constants

	Default_string: STRING
		once
			create Result.make_empty
		end

	Golden_ratio: NATURAL = 2654435769

	Size: INTEGER = 607

	Stats_template: STRING = "has %S items"

	Default_bucket: SPECIAL [STRING]
		once ("PROCESS")
			create Result.make_empty (0)
		end

end
