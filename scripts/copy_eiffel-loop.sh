
pushd .

DEST=$PWD/library/source/eiffel-loop

cd $EIFFEL/library/Eiffel-Loop/library/language_interface/C/string/managed

cp -u c_string*.e $DEST
cp -u c_nulled_string_8.e $DEST

cd $EIFFEL/library/Eiffel-Loop/library/utility/compression

for name in el_zlib_crc_32_api el_crc_32_constants el_crc_32_digest; do
	cp -u $name.e $DEST
done


popd
