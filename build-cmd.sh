#!/bin/bash

# turn on verbose debugging output for parabuild logs.
set -x
# make errors fatal
set -e

TOP="$(readlink -f $(dirname "$0"))"

OPENAL_SOURCE_DIR="openal-soft"

FREEALUT_VERSION="1.1.0"
FREEALUT_SOURCE_DIR="freealut"

if [ -z "$AUTOBUILD" ] ; then 
    fail
fi

if [ "$OSTYPE" = "cygwin" ] ; then
    export AUTOBUILD="$(cygpath -u $AUTOBUILD)"
fi

# load autbuild provided shell functions and variables
set +x
eval "$("$AUTOBUILD" source_environment)"
set -x

stage="$(pwd)"

build=${AUTOBUILD_BUILD_ID:=0}

case "$AUTOBUILD_PLATFORM" in
    "linux64")
        mkdir -p openal
        pushd openal
            cmake ../../$OPENAL_SOURCE_DIR -DCMAKE_BUILD_TYPE=Release -DCMAKE_C_FLAGS="${AUTOBUILD_GCC_ARCH} ${LL_BUILD_RELEASE}" 
            make -j `nproc`
			OPENAL_VERSION=`cat version.h  | gawk '/ ALSOFT_VERSION /{print $3}' | tr -d '"'`
        popd

        mkdir -p "$stage/lib/release"
        cp  -a  "$stage"/openal/libopenal.so* "$stage"/lib/release

        mkdir -p freealut
        pushd freealut
            cmake ../../$FREEALUT_SOURCE_DIR -DCMAKE_C_FLAGS="${AUTOBUILD_GCC_ARCH} ${LL_BUILD_RELEASE}"  \
                -DOPENAL_LIB_DIR="$stage/openal" -DOPENAL_INCLUDE_DIR="$TOP/$OPENAL_SOURCE_DIR/include"
            make -j `nproc`
			
            cp -a src/libalut.so* "$stage"/lib/release
        popd

        rm -rf openal/
        rm -rf freealut/
    ;;

esac

echo "${OPENAL_VERSION}-${FREEALUT_VERSION}.${build}" > "${stage}/VERSION.txt"
cp -r "$TOP/$OPENAL_SOURCE_DIR/include" "$stage"
cp -r "$TOP/$FREEALUT_SOURCE_DIR/include" "$stage"

mkdir -p "$stage/LICENSES"
cp "$TOP/$OPENAL_SOURCE_DIR/COPYING" "$stage/LICENSES/openal.txt"
cp "$TOP/$FREEALUT_SOURCE_DIR/COPYING" "$stage/LICENSES/freealut.txt"



