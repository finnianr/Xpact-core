note
	description: "[
		**Xpact-core example program**
	
		Usage:
			xpact_example <operation> [-chunk_size <value>] [-duration <duration-window-ms>] <XML-file-path>
			
		Valid operations: {-print, -count_tags}

		**-print** Reads from specified XML path and prints each XML event to standard output via XT_XML_PRINTER.

		**-count_tags** Reads from specified XML path and compiles a table of tag occurrence frequency.
		
		**-test** Peforms tests on various classes developed for the Xpact-core project. The name of the test
		can be specified as an argument

	]"

	author: "Finnian Reilly"
	copyright: "Copyright (c) 2001-2026 Finnian Reilly"
	contact: "finnian at eiffel hyphen loop dot com"

	license: "MIT license (See: en.wikipedia.org/wiki/MIT_License)"
	date: "2026-06-20 18:21:11 GMT (Saturday 20th June 2026)"
	revision: "1"

class APPLICATION

inherit
	XT_PARSE_CONSTANTS

	ARGUMENTS_32
		export
			{NONE} all
		end

	XT_TOKEN_CONSTANTS
		rename
			Tok_data_chars as Tok_text,
			Tok_cdata_sect_open as Tok_cdata,
			Tok_end_tag as Tok_tag,
			Tok_attribute_value_s as Tok_attribute
		export
			{NONE} all
		end

create make

feature {NONE} -- Initialisation

	make
		local
			file_path: PATH
		do
			IO.put_string ("Program: Xpact-core XML parser (Eiffel)")
			IO.put_new_line
			create file_path.make_empty
			if argument_count >= 2 then
				if attached new_argument_8 (0, "test") as name and then name.count > 0 then
					do_tests (name)

				elseif attached new_parser as parser and then attached argument (argument_count) as path_arg then
					create file_path.make_from_string (path_arg)
					do_parsing (parser, file_path, new_integer_argument ("chunk_size", 0))

				elseif invalid_event_type then
					put_parse_event_error
				else
					put_usage
				end
			else
				put_usage
			end
		end

feature {NONE} -- Factory

	new_argument_8 (index: INTEGER; a_option: detachable STRING): STRING
		local
			i: INTEGER
		do
			if attached a_option as option then
				i := index_of_word_option (option)
				if i > 0 then
					i := i + 1
				end
			else
				i := index
			end
			if 0 < i and i <= argument_count then
				Result := argument (i).to_string_8
			else
				create Result.make_empty
			end
		end

	new_integer_argument (a_option: STRING; default_value: INTEGER): INTEGER
		do
			if attached new_argument_8 (0, a_option) as str and then str.is_integer then
				Result := str.to_integer_32
			else
				Result := default_value
			end
		end

	new_parser: detachable XT_XML_PARSER_BASE
		do
			if index_of_word_option ("count_tags") > 0 then
				create {XT_TAG_COUNTER} Result.make

			elseif index_of_word_option ("print") > 0 then
				create {XT_XML_PRINTER} Result.make

			else
				if attached new_argument_8 (0, "crc_32") as data_type then
					if Parse_event_types.has_key (data_type) then
						create {XT_TAG_CRC_32_GENERATOR} Result.make (Parse_event_types.found_item, data_type)
					else
						invalid_event_type := True
					end
				end
			end
		end

feature {NONE} -- Implementation

	do_parsing (parser: XT_XML_PARSER_BASE; file_path: PATH; chunk_size: INTEGER)
		local
			file: PLAIN_TEXT_FILE; time_start: TIME;
		do
			create file.make_with_path (file_path)

			if file.exists then
				IO.put_string ("Parsing: " + file_path.out)
				IO.put_new_line

				create time_start.make_now -- start timer
				parse (parser, file_path, chunk_size)
				inspect parse_status
					when Status_error then
						IO.put_string ("Parse error code: " + parser.error_code.out)

					when Status_unreadable then
						IO.put_string ("Cannot read: " + file_path.out)
						IO.put_new_line
				else
					if attached {XT_DOCUMENT_STATS} parser as counter then
						counter.print_stats
						do_benchmarking (parser, file_path, time_start, new_integer_argument ("duration", 500), chunk_size)
					end
				end
			else
				IO.put_string ("File not found: " + file_path.out + "%N")
			end
		end

	do_benchmarking (parser: XT_XML_PARSER_BASE; file_path: PATH; time_start: TIME; duration_ms, chunk_size: INTEGER)
		local
			count: INTEGER
		do
			if duration_ms > 0 then
			-- Do benchmarking
				from count := 1 until elapsed_milliseconds (time_start) > duration_ms loop
					count := count + 1
					parser.reset
					parse (parser, file_path, chunk_size)
				end
				IO.put_string ("Total number of passes in ")
				IO.put_string (duration_ms.out + " ms: " + count.out)
				IO.put_new_line
				check_compare_to_expat (file_path, count, duration_ms)
			end
		end

	do_tests (name: STRING)
		local
			test_set: XT_TEST_SET
		do
			create test_set.make
			test_set.execute (name)
		end

	check_compare_to_expat (file_path: PATH; xpact_pass_count, duration_ms: INTEGER)
		do
			if index_of_word_option ("compare_to_expat") > 0 then
				if attached Environ.item ("BENCHMARKS_DIR") as dir_path then
					compare_to_expat (create {PATH}.make_from_string (dir_path), file_path, xpact_pass_count, duration_ms)
				else
					io.put_string ("BENCHMARKS_DIR not defined")
					io.put_new_line
				end
			end
		end

	compile: TUPLE [XT_ASCII_SCANNER, XT_LATIN_1_SCANNER, XP_EXPAT_CALLBACK_HANDLER] --
		do
			create Result
		end

	compare_to_expat (benchmark_dir, file_path: PATH; xpact_pass_count, duration_ms: INTEGER)
		--
		local
			command, log_line, xml_file_name: STRING
			index_colon, expat_pass_count: INTEGER; time_stamp: DATE_TIME
			expat_output, log_file: PLAIN_TEXT_FILE done: BOOLEAN; s: XT_STRING_ROUTINES
			log_path: PATH
		do
			create log_line.make_empty

			if attached file_path.entry as base_name then
				xml_file_name := base_name.out
			else
				create xml_file_name.make_empty
			end
			log_path := benchmark_dir.extended (s.substitute (Log_name_template, << xml_file_name >>))
			command := "xml_tag_counter $path -duration $duration > $temp_path"
			command.replace_substring_all ("$path", file_path.out)
			command.replace_substring_all ("$duration", duration_ms.out)
			if attached Environ.Temporary_directory_path as temp_dir
				and then attached temp_dir.extended ("xml_tag_counter.txt") as temp_path
			then
				command.replace_substring_all ("$temp_path", temp_path.out)
				Environ.system (command)
				if Environ.return_code = 0 then
					create expat_output.make_open_read (temp_path.name)
					from  until done loop
						expat_output.read_line
						if expat_output.end_of_file then
							done := true
						elseif attached expat_output.last_string as line then
							IO.put_string (line)
							IO.put_new_line
							if line.starts_with ("Number of passes") then
								index_colon := line.last_index_of (':', line.count)
								expat_pass_count := line.substring (index_colon + 2, line.count).to_integer
								log_line := s.substitute (Log_template, <<
									xml_file_name, expat_pass_count.out, xpact_pass_count.out,
									relative_performance (xpact_pass_count, expat_pass_count)
								>>)
							end
						end
					end
					expat_output.close; expat_output.delete

					create time_stamp.make_now
					create log_file.make_with_path (log_path)
					if not log_file.exists then
						log_file.open_write
						log_file.put_string ("Log of benchmarks for parsing file: " + xml_file_name)
						log_file.put_new_line
						log_file.close
					end
					log_file.open_append
					log_file.put_new_line
					log_file.put_string (time_stamp.formatted_out (Date_format))
					log_file.put_new_line
					log_file.put_string (log_line)
					log_file.put_new_line
					log_file.close
				end
			end
		end

	elapsed_milliseconds (time_start: TIME): INTEGER
		local
			time_now: TIME
		do
			create time_now.make_now
			Result := (time_now.relative_duration (time_start).fine_seconds_count * 1000).rounded
		end

	parse (parser: XT_XML_PARSER_BASE; file_path: PATH; chunk_size: INTEGER)
		local
			file: XT_XML_FILE
		do
			create file.make (file_path, parser)
			file.collection_off

			if chunk_size > 0 then
				file.set_chunk_size (chunk_size)
			end
			if file.is_readable then
				file.parse
				parse_status := file.status
			else
				parse_status := Status_unreadable
			end
		end

	put_parse_event_error
		do
			IO.put_string ("ERROR: Invalid parse event type for CRC-32 scan")
			IO.put_new_line
			IO.put_string ("Must be one of: {")
			across Parse_event_types.current_keys as type loop
				if not @ type.is_first then
					IO.put_string (", ")
				end
				IO.put_string (type)
			end
			IO.put_character ('}')
			IO.put_new_line
		end

	put_usage
		do
			IO.put_string (
				"Usage: xml_reader <operation> [-chunk_size <value>] [-duration <duration-window-ms>] <XML-file-path>"
			)
			IO.put_string ("Valid operations: {-count_tags, -print}")
			IO.put_string ("OPTIONAL: -chunk_size. Defaults to: 4096")
			IO.put_string ("OPTIONAL: -duration. Defaults to: 500")
			IO.put_new_line
		end

	relative_performance (xpact_pass_count, expat_pass_count: INTEGER): STRING
		local
			ratio: DOUBLE
		do
			ratio := xpact_pass_count / expat_pass_count
			Result := (ratio * 100).rounded.out
			if ratio < ratio.one then
				Result.prepend ("0.")
			else
				Result.insert_character ('.', 2)
			end
		end

feature {NONE} -- Internal attributes

	parse_status: INTEGER

	invalid_event_type: BOOLEAN

feature {NONE} -- Constants

	Environ: EXECUTION_ENVIRONMENT
		once
			create Result
		end

	Log_name_template: STRING
		once
			create Result.make_from_string ("Xpact VS expat %S.log")
		end

	Log_template: STRING
		once
			Result := "%S: eXpat passes = %S; Xpact-core passes = %S (x%S to eXpat)"
		end

	Parse_event_types: HASH_TABLE [INTEGER, STRING]
		once
			create Result.make_from_iterable_tuples (<<
				[Tok_text, "text"],
				[Tok_cdata, "cdata"],
				[Tok_comment, "comment"],
				[Tok_tag, "tag"],
				[Tok_attribute, "attribute"]
			>>)
		end

	Status_unreadable: INTEGER = 4

	Date_format: STRING
		once
			Result := "yyyy [0]dd Mmm hh:[0]mi"
		end
end
