#ifndef XT_STRUCTS_H
#define XT_STRUCTS_H

#include <eif_eiffel.h>

typedef struct {
	EIF_BOOLEAN in_prolog_section;
	EIF_BOOLEAN in_dtd_section;
	EIF_BOOLEAN in_CDATA_section;
	EIF_BOOLEAN in_parameter_entity;
	EIF_NATURAL_64 content_count;
	EIF_NATURAL_64 entity_expansion_count;
} XT_parse_data;

#endif
