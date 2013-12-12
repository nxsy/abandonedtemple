#!/bin/sh

set -e
set -u

cd `dirname $0`
cd ..

if [ ! -d build/bin ]; then
    mkdir -p build/bin
fi

# .libs will contain links to 
if [ ! -d .libs ]; then
    mkdir .libs
fi

if [ -n "${LIBGLFWPATH:-}" ]; then
    if [ -e "${LIBGLFWPATH}" ]; then
        cp "${LIBGLFWPATH}" .libs/libglfw.3.dylib
    fi
fi

while [ ! -e .libs/libglfw.3.dylib ]; do
    read -p "Please provide full path to libglfw.3.dylib:" LIBGLFWPATH
    if [ -e "${LIBGLFWPATH}" ]; then
        cp "${LIBGLFWPATH}" .libs/libglfw.3.dylib
        break
    fi
    echo "Could not find libglfw.3.dylib at ${LIBGLFWPATH}"
done

if [ ! -e build/bin/libglfw.3.dylib ]; then
    cp .libs/libglfw.3.dylib build/bin/libglfw.3.dylib
fi
