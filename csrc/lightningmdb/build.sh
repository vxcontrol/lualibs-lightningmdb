[ "$CC" ] || CC=gcc
mkdir -p ../../bin/$P/clib
CD="-Isrc -Ilmdb -I../lua-headers -DUSE_GLOBALS"
${X}${CC} -c -O2 $C $CD src/lightningmdb.c
${X}${CC} *.o -shared -o ../../bin/$P/clib/$D $L
rm -f      ../../bin/$P/$A
${X}ar rcs ../../bin/$P/$A *.o
rm *.o
