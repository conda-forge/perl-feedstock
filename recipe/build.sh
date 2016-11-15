#!/bin/bash
sh Configure -Duserelocatableinc -Dprefix="${PREFIX}" -de
make
make test
make install
