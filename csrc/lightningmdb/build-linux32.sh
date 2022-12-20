P=linux32 C="-m32 -fPIC" L="-m32 -s -static-libgcc ../../bin/$P/liblmdb.a" \
    D=lightningmdb.so A=liblightningmdb.a ./build.sh
