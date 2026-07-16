

DEST=$PWD/contrib/Eiffel-Loop

EIFFEL_LOOP=$EIFFEL/library/Eiffel-Loop

names=(c_string_8_api el_c_api el_crc_32_digest c_string_8 el_crc_32_constants \
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

