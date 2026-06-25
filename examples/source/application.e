note
	description: "[
		Entry point for the xpact-incremental example.

		Reads an XML file named on the command line and prints each XML
		event to standard output via XT_XML_PRINTER.

		Usage:
			xpact_example <operation> <xml-file> [-chunk_size <value>]")
			
		Valid operations: {print, count_tags}

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

create make

feature {NONE} -- Initialisation

	make
		local
			file: PLAIN_TEXT_FILE; time_start: TIME; count, duration_ms: INTEGER
		do
			if argument_count >= 2
				and then attached new_argument_8 (1, Void) as task and then Task_type.has (task)
				and then attached new_argument_8 (2, Void) as file_path
			then
				create file.make_with_name (file_path)
				io.put_string ("Program: Xpact-core XML parser (Eiffel)")
				io.put_new_line
				if file.exists then
					duration_ms := new_integer_argument ("duration", 500)
					if duration_ms = 0 then
						do_task (task, file_path, True)
					else
						from create time_start.make_now until elapsed_milliseconds (time_start) > duration_ms loop
							count := count + 1
							do_task (task, file_path, count = 1)
						end
						io.put_string ("Total number of passes in ")
						io.put_string (duration_ms.out + " ms: " + count.out)
						io.put_new_line
					end
				else
					io.put_string ("File not found: " + file_path + "%N")
				end
			else
				put_usage
			end
		end

feature {NONE} -- Implementation

	elapsed_milliseconds (time_start: TIME): INTEGER
		local
			time_now: TIME
		do
			create time_now.make_now
			Result := (time_now.relative_duration (time_start).fine_seconds_count * 1000).rounded
		end

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

	compile: TUPLE [XT_ASCII_ENCODING, XT_LATIN1_ENCODING, XP_EXPAT_CALLBACK_HANDLER]
		do
			create Result
		end

	do_task (task, file_path: STRING; is_first: BOOLEAN)
		local
			file: XT_XML_FILE; parser: XT_XML_PARSER
		do
			if task ~ Task_type [1] then
				create {XT_TAG_COUNTER} parser.make
			else
				create {XT_XML_PRINTER} parser.make
			end

			create file.make (file_path, parser, new_integer_argument ("chunk_size", Default_chunk_size))

			if file.is_readable then
				if is_first then
					IO.put_string ("Parsing: " + file_path)
					IO.put_new_line
				end
				Memory.collection_off
				file.parse
				Memory.collection_on
				Memory.full_collect

				if file.status = Status_error then
					io.put_string ("Parse error code: " + parser.error_code.out)

				elseif is_first and then attached {XT_TAG_COUNTER} parser as counter then
					counter.print_stats
				end
				if is_first then
					IO.put_new_line
				end
			else
				io.put_string ("Cannot read: " + file_path)
				io.put_new_line
			end
		end

	put_usage
		do
			io.put_string ("Usage: xpact_example <operation> <xml-file> [-chunk_size <value>] [-duration <millisecs>]")
			io.put_string ("Valid operations: {count_tags, print}")
			io.put_string ("OPTIONAL: -chunk_size. Defaults to: " + Default_chunk_size.out)
			io.put_string ("OPTIONAL: -duration. Defaults to: 500")
			io.put_integer (Default_chunk_size)
			io.put_new_line
		end

feature {NONE} -- Constants

	Task_type: ARRAY [STRING]
		once
			Result := << "count_tags", "print" >>
			Result.compare_objects
		end

	Default_chunk_size: INTEGER = 4096

	Memory: MEMORY
		once
			create Result
		end

end
