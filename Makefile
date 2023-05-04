.PHONY: all clean format debug release duckdb_debug duckdb_release pull update

all: release

MKFILE_PATH := $(abspath $(lastword $(MAKEFILE_LIST)))
PROJ_DIR := $(dir $(MKFILE_PATH))

EXTENSION_STATIC_BUILD=1
BUILD_TPCH=1
BUILD_JSON=1

## These flags will make DuckDB build the extension
#DUCKDB_OOT_EXTENSION_NAMES=substrait
#BUILD_OUT_OF_TREE_EXTENSIONS=substrait

#EXTRA_CMAKE_VARIABLES :=
#EXTRA_CMAKE_VARIABLES += -DDUCKDB_OOT_EXTENSION_SUBSTRAIT_PATH=$(PROJ_DIR)
#EXTRA_CMAKE_VARIABLES += -DDUCKDB_OOT_EXTENSION_SUBSTRAIT_SHOULD_LINK=TRUE
#EXTRA_CMAKE_VARIABLES += -DDUCKDB_OOT_EXTENSION_SUBSTRAIT_INCLUDE_PATH=$(PROJ_DIR)src/include
export

DUCKDB_DIRECTORY=
ifndef DUCKDB_DIR
	DUCKDB_DIRECTORY=./duckdb
else
	DUCKDB_DIRECTORY=${DUCKDB_DIR}
endif

pull:
	git submodule init
	git submodule update --recursive --remote

clean:
	rm -rf ${DUCKDB_DIRECTORY}/build
	rm -rf testext
	cd ${DUCKDB_DIRECTORY} && make clean

# Main build
debug:
	cd ${DUCKDB_DIRECTORY} && make debug

release:
# Have to actually cd there
	cd ${DUCKDB_DIRECTORY} && make release

# Client build
debug_js:
BUILD_NODE=1
BUILD_JSON=1
export
debug_js: debug

debug_r:
BUILD_R=1
export
debug_r: debug

debug_python:
BUILD_PYTHON=1
BUILD_FTS=1
BUILD_VISUALIZER=1
BUILD_TPCDS=1
export
debug_python: debug

release_js:
BUILD_NODE=1
export
release_js: release

release_r:
BUILD_R=1
export
release_r: release

release_python:
BUILD_PYTHON=1
BUILD_FTS=1
BUILD_VISUALIZER=1
BUILD_TPCDS=1
export
release_python: release

# Main tests
test: test_release

test_release: release
	./build/release/test/unittest --test-dir . "[sql]"

test_debug: debug
	./build/debug/test/unittest --test-dir . "[sql]"

# Client tests
test_js: test_debug_js
test_debug_js: debug_js
	cd ${DUCKDB_DIRECTORY}/tools/nodejs && npm run test-path -- "../../../test/nodejs/**/*.js"

test_release_js: release_js
	cd ${DUCKDB_DIRECTORY}/tools/nodejs && npm run test-path -- "../../../test/nodejs/**/*.js"

test_python: test_debug_python
test_debug_python: debug_python
	cd test/python && python3 -m pytest

test_release_python: release_python
	cd test/python && python3 -m pytest

test_release_r: release_r
	cd test/r && R -f test_substrait.R

test_debug_r: debug_r
	cd test/r && DUCKDB_R_DEBUG=1 R -f test_substrait.R

format:
	cp ${DUCKDB_DIRECTORY}/.clang-format .
	find src/ -iname *.hpp -o -iname *.cpp | xargs clang-format --sort-includes=0 -style=file -i
	cmake-format -i CMakeLists.txt
	rm .clang-format

update:
	git submodule update --remote --merge
