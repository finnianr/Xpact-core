note
	description: "[
		Parse a corpus information file structured as follows:
		
			<?xml version="1.0" encoding="UTF-8"?>
			<!-- XML testing corpus in the wild-->
			<test-corpus>
				<partition name = "Linux Mint" mount_point="/">
					<directory path = "/home/finnian/Dev/Eiffel/library/Xpact-core/tools/data"
						pattern_list = "*.xml; *.eant; *.xsl; *.svg"
					/>
				</partition>
				<partition  name="Windows 11" mount_point="/media/finnian/Windows">
					<directory path = "Windows/Windows/System32"
						pattern_list = "*.xml; *.man; *.mof"
					/>
					<directory path = "Windows/Windows/WinSxS"
						pattern_list = "*.manifest"
					/>
				</partition>
			</test-corpus>
	]"

	author: "Finnian Reilly"
	copyright: "Copyright (c) 2001-2026 Finnian Reilly"
	contact: "finnian at eiffel hyphen loop dot com"

	license: "MIT license (See: en.wikipedia.org/wiki/MIT_License)"

	date: "2026-08-03 17:00:00 GMT (Monday 3rd August 2026)"
	revision: "1"

class
	XML_CORPUS_TESTER

inherit
	XT_XML_PARSER
		redefine
			make, on_finish
		end

	FILE_TREE_TESTS_FACTORY

	XT_SHARED_EXECUTION_ENVIRONMENT

create
	make

feature {NONE} -- Initialisation

	make
		do
			Precursor
			create mount_point.make_empty
			create partition_name.make (20)
			create report_file.make_with_name ("Test-files.txt")
			create padding.make (12)
		end

feature {NONE} -- Event handlers

	on_comment (text: STRING_8)
		do
		end

	on_content (text: STRING)
		do
		end

	on_finish (a_status: INTEGER)
		do
			if a_status = Status_OK and then attached last_tests as tests then
				tests.put_results (IO.Output, sum_pass_count, sum_fail_count, True)
				report_file.put_new_line
				tests.put_results (report_file, sum_pass_count, sum_fail_count, True)
			end
			report_file.close
		end

	on_processing_instruction (a_name, value: STRING)
		do
		end

	on_tag_end (a_name: STRING_8)
		do
		end

	on_tag_start (a_name: STRING_8; depth: INTEGER; attribute_table: HASH_TABLE [STRING, STRING])
		local
			directory: DIRECTORY; exception: DEVELOPER_EXCEPTION
		do
			if a_name ~ Name.partition then
				if attached attribute_table [Name.mount_point] as str then
					create mount_point.make_from_string (str)
				end
				if attached attribute_table [Name.name] as str then
					set_partition_name (str)
				end
			elseif a_name ~ Name.directory then
				if attached attribute_table [Name.path] as relative_path
					and then attached mount_point.extended (relative_path) as path
				then
					create directory.make_with_path (path)
					if directory.exists then
						put_directory (directory.path, True)

						if attached attribute_table [Name.pattern_list] as pattern_list then
							do_tests (directory.path, pattern_list)
						end
					else
						put_directory (directory.path, False)
					end
				end
			elseif name ~ Name.test_corpus and then attached attribute_table [Name.report_path] as report_path then
				report_file.reset_path (create {PATH}.make_from_string (report_path))
				if Environment.directory_exists (report_file.path.parent) then
					report_file.open_write
				else
					create exception
					exception.set_description ("No such directory: " + report_file.path.parent.utf_8_name)
					exception.raise
				end
			end
		end

feature {NONE} -- Implementation

	do_tests (dir_path: PATH; pattern_list: STRING)
		local
			s: XT_STRING_ROUTINES; tests: FILE_TREE_TESTS
		do
			across s.to_list (pattern_list, ';') as pattern loop
				put_tabs (1)
				IO.put_string ("Test all files: " + pattern)
				IO.put_new_line
				if attached dir_path.extended (pattern) as path_pattern then
					tests := new_tests (path_pattern, True)
					tests.execute
					report_results (tests, pattern)
					last_tests := tests
					sum_fail_count := sum_fail_count + tests.sum_fail_count
					sum_pass_count := sum_pass_count + tests.sum_pass_count
				end
			end
			report_file.put_new_line
		end

	put_directory (path: PATH; exists: BOOLEAN)
		do
			across << IO.Output, report_file >> as medium loop
				medium.put_string ("Directory")
				if exists then
					medium.put_string (": ")
				else
					medium.put_string (" not found: ")
				end
				medium.put_string (path.utf_8_name)
				medium.put_new_line
			end
		end

	report_results (tests: FILE_TREE_TESTS; pattern: STRING)
		local
			s: XT_STRING_ROUTINES; line: STRING
		do
			padding.wipe_out
			padding.fill_character (' ')
			padding.remove_tail (pattern.count)
			line := s.substitute (Result_template, << pattern, padding, tests.pass_count.out, tests.fail_count.out >>)
			report_file.put_string (line)
			report_file.put_new_line
		end

	set_partition_name (a_partition_name: STRING)
		do
			partition_name.wipe_out
			partition_name.append (a_partition_name)
			report_file.put_string ("PARTITION: " + a_partition_name)
			report_file.put_new_line
			report_file.put_new_line
		end

feature {NONE} -- Internal attributes

	last_tests: detachable FILE_TREE_TESTS

	mount_point: PATH

	partition_name: STRING

	sum_fail_count: INTEGER

	sum_pass_count: INTEGER

	report_file: PLAIN_TEXT_FILE

feature {NONE} -- Constants

	Name: TUPLE [directory, mount_point, name, path, pattern_list, partition, report_path, test_corpus: STRING]
		local
			s: XT_STRING_ROUTINES
		once
			create Result
			s.fill_tuple (
				Result, "directory, mount_point, name, path, pattern_list, partition, report_path, test_corpus"
			)
		end

	padding: STRING

	Result_template: STRING = "%S	%SPassed: %S Failed: %S"

end
