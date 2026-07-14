
pushd .

DEST=$PWD/library/source/eiffel-loop

cd $EIFFEL/library/Eiffel-Loop/library/language_interface/C/string/managed

cp -u c_string*.e $DEST

cd $EIFFEL/library/Eiffel-Loop/library/utility/compression/crc-32

cp -u *.e $DEST

cd ../zlib

cp -u el_zlib_crc_32_api.e $DEST

popd
