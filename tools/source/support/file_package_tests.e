note
	description: "Test XML files in compressed package"

	author: "Finnian Reilly`"
	copyright: "Copyright (c) 2001-2026 Finnian Reilly"
	contact: "finnian at eiffel hyphen loop dot com"

	license: "MIT license (See: en.wikipedia.org/wiki/MIT_License)"

	date: "2026-08-01 17:15:00 GMT (Saturday 1th August 2026)"
	revision: "1"

class
	FILE_PACKAGE_TESTS

inherit
	FILE_TREE_TESTS
		redefine
			execute, make, new_base_log_path, put_log_values_differ
		end

create
	make

feature {NONE} -- Initialization

	make (a_package_path: PATH)
		do
			package_path := a_package_path
			Precursor (a_package_path)
		end

feature -- Access

	sum_fail_count: INTEGER

	sum_pass_count: INTEGER

feature -- Basic operations

	execute
		local
			done: BOOLEAN; l_fail_count: INTEGER
		do
			if attached new_find_results as package_results and then package_results.has_output then
				from until done loop
					package_results.read_line
					if package_results.end_of_file then
						done := True
					else
						set_package_path (package_results.last_path)
						if is_extracted then
							l_fail_count := 0
							across Package_wild_cards as l_wild_card loop
								wild_card := l_wild_card
								log.reset_path (new_log_path)
								if attached new_find_results as find_results and then find_results.has_output
									and then find_results.file_readable
								then
									do_tests (find_results)
									put_results (False, pass_count, fail_count)
									l_fail_count := l_fail_count + fail_count
								end
								sum_fail_count := sum_fail_count + fail_count
								sum_pass_count := sum_pass_count + pass_count
							end
							if l_fail_count = 0 then
								Environment.remove_directory (dir_path, True)
							end
						end
					end
				end
				package_results.close
				put_results (True, sum_pass_count, sum_fail_count)
			else
				IO.put_string_32 (dir_path.name)
				IO.put_new_line
				IO.put_string ("No files found: " + wild_card)
				IO.put_new_line
			end
		end

feature {NONE} -- Implementation

	new_base_log_path: PATH
		do
			if attached Environment.Temporary_directory_path as temp_path
				and then attached dir_path.entry as entry
			then
				Result := temp_path.extended (entry.name)
			else
				create Result.make_empty
			end
		end

	package_name: STRING
		do
			if attached package_path.entry as entry then
				Result := entry.name.to_string_8
			else
				create Result.make_empty
			end
		end

	put_log_values_differ (file_path: PATH)
		do
			log.put_string (substitute (Values_differ_template, << package_name, file_path.out >>))
			log.put_new_line
		end

	set_package_path (a_package_path: PATH)
		do
			package_path := a_package_path
			if attached a_package_path.entry as entry and then attached entry.name as name
				and then attached Environment.temporary_path (name) as temp_path
			then
				dir_path := temp_path
				Environment.make_directory (dir_path, False)
				Environment.do_command (Unzip_template, << a_package_path, dir_path >>)
				if Environment.return_code = 0 then
					make_log
					is_extracted := True
				else
					is_extracted := False
					IO.put_string ("Failed to extract ")
					IO.put_string_32 (package_path.name)
					IO.put_new_line
				end
			end
		end

feature {NONE} -- Internal attributes

	package_path: PATH

	is_extracted: BOOLEAN

feature {NONE} -- Constants

	Package_wild_cards: ARRAY [STRING]
		once
			Result := << Default_wild_card, "*.rdf", "*.rels" >>
		end

	Unzip_template: STRING
		once
			Result := "unzip -q %S -d %S"
		end

	Values_differ_template: STRING = "VALUES DIFFER (%S): %S"

end
