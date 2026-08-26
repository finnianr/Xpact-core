note
	description: "[
		Test all files specified in XML corpus information file structured as follows:
		
			<?xml version="1.0" encoding="UTF-8"?>
			<!-- XML testing corpus in the wild-->
			<test-corpus>
				<section name = "Linux Mint" path="/">
					<directory path = "/home/finnian/Dev/Eiffel/library/Xpact-core/tools/data"
						pattern_list = "*.xml; *.eant; *.xsl; *.svg"
					/>
				</section>
				<section name="Windows 11" path="/media/finnian/Windows">
					<directory path = "Windows/Windows/System32"
						pattern_list = "*.xml; *.man; *.mof"
					/>
					<directory path = "Windows/Windows/WinSxS"
						pattern_list = "*.manifest"
					/>
				</section>
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
	XT_XML_PARSER_BASE
		redefine
			make, on_finish
		end

	XT_DEFAULT_PARSE_EVENTS
		rename
			on_attribute_list_declaration_ as on_attribute_list_declaration,
			on_cdata_section_close_ as on_cdata_section_close,
			on_comment_ as on_comment,
			on_content_ as on_content,
			on_xml_declaration_ as on_xml_declaration,
			on_doctype_declaration_start_ as on_doctype_declaration_start,
			on_processing_instruction_ as on_processing_instruction,
			on_tag_end_ as on_tag_end
		end

	FILE_TREE_TESTS_FACTORY

	XT_SHARED_EXECUTION_ENVIRONMENT

create
	make

feature {NONE} -- Initialisation

	make
		do
			Precursor
			create section_path.make_empty
			create section_name.make (20)
			create report_file.make_with_name ("Test-files.txt")
			create padding.make (12)
		end

feature {NONE} -- Event handlers

	on_finish (a_status: INTEGER)
		do
			if a_status = Status_OK and then attached last_tests as tests then
				tests.put_results (IO.Output, sum_pass_count, sum_fail_count, True)
				report_file.put_new_line
				tests.put_results (report_file, sum_pass_count, sum_fail_count, True)
			end
			report_file.close
		end

	on_tag_start (buf: like buffer; context: XT_ELEMENT_CONTEXT; attributes: XT_ATTRIBUTE_LIST; token: INTEGER)
		local
			directory: DIRECTORY; report_path: PATH; attribute_table: HASH_TABLE [STRING, STRING]
		do
			attribute_table := attributes.as_table (buf, False)
			if context.name ~ Name.section then
				if attached attribute_table [Name.path] as str then
					create section_path.make_from_string (str)
				else
					create section_path.make_empty
				end
				if attached attribute_table [Name.name] as l_name then
					set_section_name (l_name)
				else
					set_section_name ("<Unspecified>")
				end

			elseif context.name ~ Name.directory then
				if attached attribute_table [Name.path] as relative_path
					and then attached section_path.extended (relative_path) as path
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
			elseif context.name ~ Name.test_corpus then
				if attached attribute_table [Name.report_path] as table_item then
					create report_path.make_from_string (table_item)
					report_file.reset_path (report_path)
					if Environment.directory_exists (report_file.path.parent, Void) then
						report_file.open_write
					else
						raise_exception ("No such directory: " + report_file.path.parent.utf_8_name)
					end
				else
					raise_exception ("No report path specified in element: " + Name.test_corpus)
				end
			end
		end

feature {NONE} -- Implementation

	do_tests (dir_path: PATH; pattern_list: STRING)
		local
			s: XT_STRING_8_ROUTINES; tests: FILE_TREE_TESTS
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

	raise_exception (a_description: READABLE_STRING_GENERAL)
		local
			exception: DEVELOPER_EXCEPTION
		do
			create exception
			exception.set_description (a_description)
			exception.raise
		end

	report_results (tests: FILE_TREE_TESTS; pattern: STRING)
		local
			s: XT_STRING_8_ROUTINES; line: STRING
		do
			padding.wipe_out
			padding.fill_character (' ')
			padding.remove_tail (pattern.count)
			line := s.substitute (Result_template, << pattern, padding, tests.pass_count.out, tests.fail_count.out >>)
			report_file.put_string (line)
			report_file.put_new_line
		end

	set_section_name (a_section_name: STRING)
		do
			section_name.wipe_out
			section_name.append (a_section_name)
			if report_file.is_open_write then
				report_file.put_string ("SECTION: " + a_section_name)
				report_file.put_new_line
				report_file.put_new_line
			else
				raise_exception ("Report file not open: " + report_file.path.parent.utf_8_name)
			end
		end

feature {NONE} -- Internal attributes

	last_tests: detachable FILE_TREE_TESTS

	section_path: PATH

	section_name: STRING

	sum_fail_count: INTEGER

	sum_pass_count: INTEGER

	report_file: PLAIN_TEXT_FILE

feature {NONE} -- Constants

	Name: TUPLE [directory, name, path, pattern_list, report_path, section, test_corpus: STRING]
		local
			s: XT_STRING_8_ROUTINES
		once
			create Result
			s.fill_tuple (Result,
				"directory, name, path, pattern_list, report_path, section, test_corpus"
			)
		end

	padding: STRING

	Result_template: STRING = "%S	%SPassed: %S Failed: %S"

end
