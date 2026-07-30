

DEST=$PWD/contrib/Eiffel-Loop

EIFFEL_LOOP=$EIFFEL/library/Eiffel-Loop

names=(el_string_h_c_api el_c_api el_crc_32_digest el_latin_1_c_string el_utf_16_c_string \ 
	el_utf_8_pointer_codec el_utf_8_c_string	el_crc_32_constants \
	el_expanded_routines el_traceable_crc_32_digest el_routines \
	el_integer_math_i el_integer_math el_memory_routines el_zlib_crc_32_api)
	
args=()
for n in "${names[@]}"; do
	args+=(-o -name "$n.e")
done
pushd .

cd $EIFFEL_LOOP/library

file_list=$(find . \( "${args[@]:1}" \))

while IFS= read -r f; do
	mkdir -p "$DEST/$(dirname "$f")"
	cp -u "$f" "$DEST/$f"
done <<< "$file_list"

popd

