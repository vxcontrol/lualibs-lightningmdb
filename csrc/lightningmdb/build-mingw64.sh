[ `uname` = Linux ] && { export X=x86_64-w64-mingw32-; }
P=mingw64 C="-fPIC" L="-s -static-libgcc ../../bin/$P/lmdb.a ../../bin/$P/luajit.a" \
    D=lightningmdb.dll A=lightningmdb.a ./build.sh
