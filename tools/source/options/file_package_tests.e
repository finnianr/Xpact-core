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
		rename
			do_tests as do_xml_tests,
			path as package_content_path
		redefine
			execute, make, new_comparison, sum_fail_count, sum_pass_count
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
		do
			if attached new_find_results (package_content_path, wild_card) as package_results then
				if package_results.has_output then
					do_tests (package_results)
				end
				package_results.cleanup
				put_results (IO.Output, sum_pass_count, sum_fail_count, True)
			else
				IO.put_string_32 (package_content_path.name)
				IO.put_new_line
				IO.put_string ("No files found: " + wild_card)
				IO.put_new_line
			end
		end

feature {NONE} -- Implementation

	do_tests (package_results: XT_COMMAND_OUTPUT_FILE)
		local
			done: BOOLEAN; l_fail_count: INTEGER; package_wild_card: STRING
		do
			package_wild_card := wild_card -- "*.ods" for example
			from until done loop
				package_results.read_line
				if package_results.end_of_file then
					done := True
				else
					set_package_path (package_results.last_path)
					if is_extracted then
						l_fail_count := 0
						across internal_wild_cards (package_wild_card) as internal loop
							wild_card := internal -- "*.xml" for example
							log.reset_path (new_log_path)
							Environment.make_directory (log.path.parent, False)
							if attached new_find_results (package_content_path, wild_card) as find_results then
								if find_results.has_output then
									do_xml_tests (find_results)
									put_results (IO.Output, pass_count, fail_count, False)
									l_fail_count := l_fail_count + fail_count
								end
								find_results.cleanup
							end
							sum_fail_count := sum_fail_count + fail_count
							sum_pass_count := sum_pass_count + pass_count
						end
						if l_fail_count = 0 then
							Environment.remove_directory (log.path.parent, False)
							Environment.remove_directory (package_content_path, True)
						end
					end
				end
			end
		end

	package_name: STRING
		do
			if attached package_path.entry as entry then
				Result := entry.utf_8_name
			else
				create Result.make_empty
			end
		end

	new_comparison (file_path: PATH): XT_EXPAT_COMPARISON
		do
			create Result.make (file_path, log)
			Result.set_package_name (package_name)
		end

	set_package_path (a_package_path: PATH)
		local
			s: XT_STRING_8_ROUTINES
		do
			package_path := a_package_path
			if attached a_package_path.entry as entry then
				package_content_path := Environment.temporary_command_path + entry
				Environment.make_directory (package_content_path, False)
				Environment.do_command (Unzip_template, s.new_string_list (<< a_package_path, package_content_path >>))
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

	Unzip_template: STRING
		once
			Result := "unzip -q %S -d %S"
		end

	Values_differ_template: STRING = "VALUES DIFFER (%S): %S"

end
