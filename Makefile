
# prefix for install
# only override if not set from env
PREFIX ?= /usr/local

all:
	#
	# CAuto is a commandline tool for automatic compile and link C++
	# projects using CMake and a naming convention in the source tree.
	#
	# install CAuto using
	#  $$ make PREFIX=/usr/local install
	#
	# this creates
	#  PREFIX/bin/cauto
	#  PREFIX/lib/cauto/cauto
	#  PREFIX/lib/CMakeLists.txt
	#  PREFIX/lib/.gitignore
	#
	# for help type
	#  $$ cauto help
	#  $$ cauto doc
	#
	# setup project
	#  $$ mkdir -p myproj/exe
	#  $$ cd myproj
	#  $$ cauto init
	#  $$ touch exe/a.cpp
	#  $$ cauto scan make
	#
.PHONY: all

install:
	mkdir -p $(PREFIX)/bin
	mkdir -p $(PREFIX)/lib/cauto
	install -m 0755 bin/cauto $(PREFIX)/bin
	install -m 0755 lib/cauto/cauto $(PREFIX)/lib/cauto
	install -m 0644 lib/cauto/CMakeLists.txt $(PREFIX)/lib/cauto
	install -m 0644 lib/cauto/.gitignore $(PREFIX)/lib/cauto
.PHONY: install
