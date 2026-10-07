

EXPAT=$HOME/Dev/C/libexpat/expat/lib

# rg xmlns tools/data -l

rg -n -w -g '*.c' XmlParseXmlDecl $EXPAT
