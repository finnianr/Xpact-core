#ifndef XT_STRUCTS_H
#define XT_STRUCTS_H

#include <eif_eiffel.h>

typedef void (*XML_start_element_handler)(void *user_data, const char *name, const char **attributes);
typedef void (*XML_end_element_handler)(void *user_data, const char *name);

// generic event handler
typedef void (*XML_on_event)(void *user_data);

typedef struct {
	EIF_BOOLEAN has_dtd_section;
	EIF_BOOLEAN in_prolog_section;
	EIF_BOOLEAN in_dtd_section;
	EIF_BOOLEAN in_CDATA_section;
	EIF_NATURAL_64 content_count;
	EIF_NATURAL_64 entity_expansion_count;
//	Callbacks element tags
	XML_start_element_handler on_start_element;
	XML_end_element_handler on_end_element;
//	Callbacks CDATA section
	XML_on_event on_start_CDATA_section;
	XML_on_event on_end_CDATA_section;
} XT_parse_data;

typedef struct XT_particle XT_element_particle;

typedef struct XT_particle {
	EIF_INTEGER type;
	EIF_INTEGER quantifier;
	EIF_CHARACTER *name;
	EIF_NATURAL list_count;
	XT_element_particle *particle_list;
} XT_particle ;

#endif
