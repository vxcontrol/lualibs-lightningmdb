[ `uname` = Linux ] && { export X=i686-w64-mingw32-; }
P=mingw32 C="-fPIC" L="-s -static-libgcc ../../bin/$P/lmdb.a ../../bin/$P/luajit.a" \
    D=lightningmdb.dll A=lightningmdb.a ./build.sh
