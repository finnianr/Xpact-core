#ifndef XT_STRUCTS_H
#define XT_STRUCTS_H

#include <eif_eiffel.h>

typedef struct {
	EIF_BOOLEAN has_dtd_section;
	EIF_BOOLEAN in_prolog_section;
	EIF_BOOLEAN in_dtd_section;
	EIF_BOOLEAN in_CDATA_section;
	EIF_NATURAL_64 content_count;
	EIF_NATURAL_64 entity_expansion_count;
} XT_parse_data;

typedef struct XT_particle XT_element_particle;

typedef struct XT_particle {
	EIF_INTEGER type;
	EIF_INTEGER quantity;
	EIF_CHARACTER *name;
	EIF_NATURAL list_count;
	XT_element_particle *particle_list;
} XT_particle ;

#endif
