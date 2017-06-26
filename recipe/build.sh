#!/bin/bash

# world-writable files are not allowed
chmod -R o-w "${SRC_DIR}"

# Give install_name_tool enough room to work its magic
if [[ $(uname) == Darwin ]]; then
  LDFLAGS=${LDFLAGS}" -Wl,-headerpad_max_install_names"
fi

if [[ -n ${HOST} ]] && [[ -n ${CC} ]]; then
  SYSROOT=$(dirname $(dirname ${CC}))/$(${CC} -dumpmachine)/sysroot
else
  SYSROOT=/usr
fi

if [[ -n "${CC}" ]]; then
  CC_OPT="-Dcc=${CC}"
fi

# -Dsysroot prevents Configure rummaging around in /usr and
# linking to system libraries (like GDBM, which is GPL). An
# alternative is to pass -Dusecrosscompile but that prevents
# all Configure/run checks which we also do not want.
./Configure -de -Dprefix=${PREFIX}                \
                ${CC_OPT}                         \
                -Dcccdlflags="-fPIC"              \
                -Dlddlflags="-shared ${LDFLAGS}"  \
                -Dldflags="${LDFLAGS}"            \
                -Dusethreads                      \
                -Duserelocatableinc               \
                -Dsysroot=${SYSROOT}
make

# change permissions again after building
chmod -R o-w "${SRC_DIR}"

# Seems we hit:
# lib/perlbug .................................................... # Failed test 21 - [perl \#128020] long body lines are wrapped: maxlen 1157 at ../lib/perlbug.t line 154
# FAILED at test 21
# https://rt.perl.org/Public/Bug/Display.html?id=128020
# make test
make install
