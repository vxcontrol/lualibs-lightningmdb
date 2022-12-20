[ `uname` = Linux ] && { export X=x86_64-apple-darwin19-; export CC=clang; }
P=osx64 C="-arch x86_64 -fPIC" L="-arch x86_64 ../../bin/$P/liblmdb.a -undefined dynamic_lookup" \
	D=lightningmdb.so A=liblightningmdb.a ./build.sh
