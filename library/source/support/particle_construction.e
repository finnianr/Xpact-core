note
	description: "[
		Demonstration of ${XT_CONTENT_PARTICLE} construction for every <!ELEMENT ...>
		declaration in the shared-mime-info DTD:

			<!DOCTYPE mime-info [
				<!ELEMENT mime-info (mime-type)+>
				<!ELEMENT mime-type (comment+ , (acronym , expanded-acronym)? ,
					(icon | generic-icon | glob | magic | treemagic | root-XML | alias | sub-class-of)*)>
				<!ELEMENT comment (#PCDATA)>
				<!ELEMENT acronym (#PCDATA)>
				<!ELEMENT expanded-acronym (#PCDATA)>
				<!ELEMENT icon EMPTY>
				<!ELEMENT generic-icon EMPTY>
				<!ELEMENT glob EMPTY>
				<!ELEMENT magic (match)+>
				<!ELEMENT match (match)*>
				<!ELEMENT treemagic (treematch)+>
				<!ELEMENT treematch (treematch)*>
				<!ELEMENT root-XML EMPTY>
				<!ELEMENT alias EMPTY>
				<!ELEMENT sub-class-of EMPTY>
			]>

		Each query below returns the ${XT_CONTENT_PARTICLE} tree eXpat's
		${XML_ElementDeclHandler} would report for that one declaration.

		Every parenthesised group -- even one wrapping a single name, such as
		"(mime-type)+" or "(match)*" -- becomes its own CT_sequence particle in
		eXpat's model (see XML_ROLE_GROUP_OPEN / build_model in xmlparse.c): a
		group defaults to CT_sequence and only becomes CT_choice if a '|'
		appears inside it. A bare "(#PCDATA)" is the one case where the just-
		opened group itself is converted to CT_mixed instead of wrapping a
		child. ATTLIST declarations are not part of the content model and are
		not represented here.
	]"

	author: "Finnian Reilly"
	copyright: "Copyright (c) 2001-2026 Finnian Reilly"
	contact: "finnian at eiffel hyphen loop dot com"

	license: "MIT license (See: en.wikipedia.org/wiki/MIT_License)"
	date: "2026-09-02 16:00:00 GMT (Wednesday 2nd September 2026)"
	revision: "1"

class
	PARTICLE_CONSTRUCTION

inherit
	XT_ELEMENT_PARTICLE_CONSTANTS
		-- gives unqualified access to the CT_*/QT_* constants used below

feature -- Access

	mime_info_model: XT_CONTENT_PARTICLE
			-- <!ELEMENT mime-info (mime-type)+>
			-- One required child element, repeated one or more times.
		do
			create Result.make (CT_sequence, QT_plus)
			Result.add_named_particle (CT_name, QT_none, "mime-type")
		end

	mime_type_model: XT_CONTENT_PARTICLE
			-- <!ELEMENT mime-type (comment+ , (acronym , expanded-acronym)? ,
			--   (icon | generic-icon | glob | magic | treemagic | root-XML | alias | sub-class-of)*)>
			
			-- A 3-part sequence: one or more <comment>, an optional
			-- <acronym>/<expanded-acronym> pair, then zero or more of eight
			-- alternative elements.
		local
			acronym_pair, alternatives: XT_CONTENT_PARTICLE
		do
			create Result.make (CT_sequence, QT_none)

			Result.add_named_particle (CT_name, QT_plus, "comment")

			create acronym_pair.make (CT_sequence, QT_option)
			acronym_pair.add_named_particle (CT_name, QT_none, "acronym")
			acronym_pair.add_named_particle (CT_name, QT_none, "expanded-acronym")
			Result.add_child_particle (acronym_pair)

			create alternatives.make (CT_choice, QT_repetition)
			across
				<<"icon", "generic-icon", "glob", "magic", "treemagic",
					"root-XML", "alias", "sub-class-of">> as name
			loop
				alternatives.add_named_particle (CT_name, QT_none, name)
			end
			Result.add_child_particle (alternatives)
		end

	comment_model: XT_CONTENT_PARTICLE
			-- <!ELEMENT comment (#PCDATA)>
		do
			create Result.make (CT_mixed, QT_none)
		end

	acronym_model: XT_CONTENT_PARTICLE
			-- <!ELEMENT acronym (#PCDATA)>
		do
			create Result.make (CT_mixed, QT_none)
		end

	expanded_acronym_model: XT_CONTENT_PARTICLE
			-- <!ELEMENT expanded-acronym (#PCDATA)>
		do
			create Result.make (CT_mixed, QT_none)
		end

	icon_model: XT_CONTENT_PARTICLE
			-- <!ELEMENT icon EMPTY>
		do
			create Result.make (CT_empty, QT_none)
		end

	generic_icon_model: XT_CONTENT_PARTICLE
			-- <!ELEMENT generic-icon EMPTY>
		do
			create Result.make (CT_empty, QT_none)
		end

	glob_model: XT_CONTENT_PARTICLE
			-- <!ELEMENT glob EMPTY>
		do
			create Result.make (CT_empty, QT_none)
		end

	magic_model: XT_CONTENT_PARTICLE
			-- <!ELEMENT magic (match)+>
		do
			create Result.make (CT_sequence, QT_plus)
			Result.add_named_particle (CT_name, QT_none, "match")
		end

	match_model: XT_CONTENT_PARTICLE
			-- <!ELEMENT match (match)*>
			-- Recursive: a <match> may itself contain zero or more nested <match>.
		do
			create Result.make (CT_sequence, QT_repetition)
			Result.add_named_particle (CT_name, QT_none, "match")
		end

	treemagic_model: XT_CONTENT_PARTICLE
			-- <!ELEMENT treemagic (treematch)+>
		do
			create Result.make (CT_sequence, QT_plus)
			Result.add_named_particle (CT_name, QT_none, "treematch")
		end

	treematch_model: XT_CONTENT_PARTICLE
			-- <!ELEMENT treematch (treematch)*>
		do
			create Result.make (CT_sequence, QT_repetition)
			Result.add_named_particle (CT_name, QT_none, "treematch")
		end

	root_xml_model: XT_CONTENT_PARTICLE
			-- <!ELEMENT root-XML EMPTY>
		do
			create Result.make (CT_empty, QT_none)
		end

	alias_model: XT_CONTENT_PARTICLE
			-- <!ELEMENT alias EMPTY>
		do
			create Result.make (CT_empty, QT_none)
		end

	sub_class_of_model: XT_CONTENT_PARTICLE
			-- <!ELEMENT sub-class-of EMPTY>
		do
			create Result.make (CT_empty, QT_none)
		end

end
