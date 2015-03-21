
########################################################################
# CAuto ################################################################
########################################################################
## CAuto is a tool for automatic compile and link c++ projects
## using CMake and a naming convention in the source tree.
##

## TODO
#	dont conf target if deps not found
#	cauto scan make should run without error

CMAKE_MINIMUM_REQUIRED(VERSION 2.8.12)

########################################################################
# FUNCTIONS ############################################################
########################################################################

########################################################################
FUNCTION(CAUTO_LIST_VARIABLES)
	MESSAGE(STATUS "")
	GET_CMAKE_PROPERTY(vars VARIABLES)
	FOREACH(var IN LISTS vars)
		MESSAGE(STATUS "${var} = '${${var}}'")
	ENDFOREACH()
	MESSAGE(STATUS "")
ENDFUNCTION()

########################################################################
FUNCTION(CAUTO_LOG_FIND_SCRIPTS)
	FILE(GLOB_RECURSE
		script_files1
		FOLLOW_SYMLINKS
		${CMAKE_ROOT}/*/Find*.cmake
	)
	FILE(GLOB_RECURSE
		script_files2
		FOLLOW_SYMLINKS
		${CMAKE_MODULE_PATH}/*/Find*.cmake
	)
	LIST(APPEND script_files1 ${script_files2})
	LIST(SORT script_files1)
	CAUTO_FILE_WRITE_LIST(${CAUTO_FILES_DIR}/FindScripts "${script_files1}")
ENDFUNCTION()

########################################################################
FUNCTION(CAUTO_MESSAGE
	message
)
	MESSAGE("++ ${message}")
ENDFUNCTION()

########################################################################
FUNCTION(CAUTO_MESSAGE_LIST
	message_prefix
	message_list
)
	FOREACH(str IN LISTS message_list)
		CAUTO_MESSAGE("${message_prefix} ${str}")
	ENDFOREACH()
ENDFUNCTION()

########################################################################
FUNCTION(CAUTO_SET_TARGET_PROPERTIES
	target_name
	property
	string_list
)
	STRING(REPLACE ";" " " string_list "${string_list}")
	SET_TARGET_PROPERTIES(${target_name} PROPERTIES ${property} "${string_list}")
ENDFUNCTION()

########################################################################
FUNCTION(CAUTO_FILE_READ_LIST
	file_name
	return
)
	IF(EXISTS ${file_name})
		FILE(READ ${file_name} file_text)
		STRING(REPLACE "\n" " " file_text "${file_text}")
		SEPARATE_ARGUMENTS(file_text UNIX_COMMAND "${file_text}")
		#~ STRING(REPLACE " " ";" file_text "${file_text}")
		SET(${return} "${file_text}" PARENT_SCOPE)
	ELSEIF(ARGC STREQUAL 2)
		FILE(WRITE ${file_name} "${${return}}")
	ENDIF()
ENDFUNCTION()

########################################################################
FUNCTION(CAUTO_FILE_WRITE_LIST
	file_name
	content
)
	FILE(WRITE ${file_name} "")
	FOREACH(item IN LISTS content)
		FILE(APPEND ${file_name} "${item}\n")
	ENDFOREACH()
ENDFUNCTION()

########################################################################
FUNCTION(CAUTO_FILE_WRITE_VARS
	file_name
	var_names
)
	FILE(WRITE ${file_name} "")
	FOREACH(var IN LISTS var_names)
		FILE(APPEND ${file_name} "${var} = '${${var}}'\n")
	ENDFOREACH()
ENDFUNCTION()

########################################################################
FUNCTION(CAUTO_FILE_READ_CONF_LIST
	target_type
	target_basename
	file_name return
)
	SET(str_list1 "")
	CAUTO_FILE_READ_LIST(${CAUTO_CONF_DIR}/${target_basename}.${file_name} str_list1 NOCREATE)
	WHILE(target_basename)
		GET_FILENAME_COMPONENT(target_basename ${target_basename} DIRECTORY)
		SET(str_list2 "")
		CAUTO_FILE_READ_LIST(${CAUTO_CONF_DIR}/${target_basename}/${file_name} str_list2 NOCREATE)
		IF(str_list2)
			LIST(APPEND str_list1 "${str_list2}")
		ENDIF()
	ENDWHILE()
	SET(${return} "${str_list1}" PARENT_SCOPE)
ENDFUNCTION()

########################################################################
FUNCTION(CAUTO_FILE_MAKE_CONF_DEPS
	target_type
	target_basename
	file_names
	return
)
	SET(str_list "")
	FOREACH(file_name IN LISTS file_names)
		SET(file_path ${CAUTO_CONF_DIR}/${target_basename}.${file_name})
		IF(EXISTS ${file_path})
			LIST(APPEND str_list ${file_path})
		ENDIF()
	ENDFOREACH()
	WHILE(target_basename)
		GET_FILENAME_COMPONENT(target_basename ${target_basename} DIRECTORY)
		FOREACH(file_name IN LISTS file_names)
			LIST(APPEND str_list ${CAUTO_CONF_DIR}/${target_basename}/${file_name})
		ENDFOREACH()
	ENDWHILE()
	SET(${return} "${str_list}" PARENT_SCOPE)
ENDFUNCTION()

########################################################################
FUNCTION(ADD_PACKAGE
	package_prefix
	package_name
)
	GET_CMAKE_PROPERTY(add_pkg_vars1 VARIABLES)
	CAUTO_MESSAGE("Add Package: ${package_prefix}")
	FIND_PACKAGE(${package_name} ${ARGN})
	SET(package_file "")
	INCLUDE(${CAUTO_CONF_DIR}/${package_prefix}.cauto OPTIONAL)
	IF(
		NOT ${package_prefix}_FOUND AND
		NOT ${package_name}_FOUND
	)
		CAUTO_MESSAGE("Package ${package_name} not found.")
	ELSE()
		IF(NOT ${package_prefix}_INCLUDE_DIRS)
			SET(${package_prefix}_INCLUDE_DIRS "")
		ENDIF()
		IF(${package_prefix}_INCLUDE)
			LIST(APPEND ${package_prefix}_INCLUDE_DIRS "${${package_prefix}_INCLUDE}")
		ELSEIF(${package_prefix}_INCLUDES)
			LIST(APPEND ${package_prefix}_INCLUDE_DIRS "${${package_prefix}_INCLUDES}")
		ELSEIF(${package_prefix}_INCLUDE_DIR)
			LIST(APPEND ${package_prefix}_INCLUDE_DIRS "${${package_prefix}_INCLUDE_DIR}")
		ELSEIF(${package_name}_INCLUDE)
			LIST(APPEND ${package_prefix}_INCLUDE_DIRS "${${package_name}_INCLUDE}")
		ELSEIF(${package_name}_INCLUDES)
			LIST(APPEND ${package_prefix}_INCLUDE_DIRS "${${package_name}_INCLUDES}")
		ELSEIF(${package_name}_INCLUDE_DIR)
			LIST(APPEND ${package_prefix}_INCLUDE_DIRS "${${package_name}_INCLUDE_DIR}")
		ELSEIF(${package_name}_INCLUDE_DIRS)
			LIST(APPEND ${package_prefix}_INCLUDE_DIRS "${${package_name}_INCLUDE_DIRS}")
		ENDIF()
		CAUTO_MESSAGE_LIST(${package_prefix}_INCLUDE_DIRS "${${package_prefix}_INCLUDE_DIRS}")
		SET(${package_prefix}_INCLUDE_DIRS "${${package_prefix}_INCLUDE_DIRS}" PARENT_SCOPE)

		IF(NOT ${package_prefix}_LIBRARIES)
			SET(${package_prefix}_LIBRARIES "")
		ENDIF()
		IF(${package_prefix}_LIB)
			LIST(APPEND ${package_prefix}_LIBRARIES "${${package_prefix}_LIB}")
		ELSEIF(${package_prefix}_LIBS)
			LIST(APPEND ${package_prefix}_LIBRARIES "${${package_prefix}_LIBS}")
		ELSEIF(${package_prefix}_LIBRARY)
			LIST(APPEND ${package_prefix}_LIBRARIES "${${package_prefix}_LIBRARY}")
		ELSEIF(${package_name}_LIB)
			LIST(APPEND ${package_prefix}_LIBRARIES "${${package_name}_LIB}")
		ELSEIF(${package_name}_LIBS)
			LIST(APPEND ${package_prefix}_LIBRARIES "${${package_name}_LIBS}")
		ELSEIF(${package_name}_LIBRARY)
			LIST(APPEND ${package_prefix}_LIBRARIES "${${package_name}_LIBRARY}")
		ELSEIF(${package_name}_LIBRARIES)
			LIST(APPEND ${package_prefix}_LIBRARIES "${${package_name}_LIBRARIES}")
		ENDIF()
		CAUTO_MESSAGE_LIST(${package_prefix}_LIBRARIES "${${package_prefix}_LIBRARIES}")
		SET(${package_prefix}_LIBRARIES "${${package_prefix}_LIBRARIES}" PARENT_SCOPE)

		IF(NOT ${package_prefix}_DEFINITIONS)
			SET(${package_prefix}_DEFINITIONS "")
		ENDIF()
		IF(${package_prefix}_DEF)
			LIST(APPEND ${package_prefix}_DEFINITIONS "${${package_prefix}_DEF}")
		ELSEIF(${package_prefix}_DEFS)
			LIST(APPEND ${package_prefix}_DEFINITIONS "${${package_prefix}_DEFS}")
		ELSEIF(${package_prefix}_DEFINITION)
			LIST(APPEND ${package_prefix}_DEFINITIONS "${${package_prefix}_DEFINITION}")
		ELSEIF(${package_name}_DEF)
			LIST(APPEND ${package_prefix}_DEFINITIONS "${${package_name}_DEF}")
		ELSEIF(${package_name}_DEFS)
			LIST(APPEND ${package_prefix}_DEFINITIONS "${${package_name}_DEFS}")
		ELSEIF(${package_name}_DEFINITION)
			LIST(APPEND ${package_prefix}_DEFINITIONS "${${package_name}_DEFINITION}")
		ELSEIF(${package_name}_DEFINITIONS)
			LIST(APPEND ${package_prefix}_DEFINITIONS "${${package_name}_DEFINITIONS}")
		ENDIF()
		CAUTO_MESSAGE_LIST(${package_prefix}_DEFINITIONS "${${package_prefix}_DEFINITIONS}")
		SET(${package_prefix}_DEFINITIONS "${${package_prefix}_DEFINITIONS}" PARENT_SCOPE)
	ENDIF()
	GET_CMAKE_PROPERTY(add_pkg_vars2 VARIABLES)
	LIST(REMOVE_ITEM add_pkg_vars2 add_pkg_vars1 ${add_pkg_vars1})
	LIST(SORT add_pkg_vars2)
	CAUTO_FILE_WRITE_VARS(${CAUTO_FILES_DIR}/AddPackage-${package_prefix} "${add_pkg_vars2}")
ENDFUNCTION()

########################################################################
FUNCTION(FIND_TARGET
	target_type
	source_ext_list
	add_command
)
	SET(target_all "")
	FOREACH(source_ext IN LISTS source_ext_list)
		FILE(GLOB_RECURSE
			target_sources_rel
			RELATIVE ${CAUTO_PROJECT_ROOT}/${target_type}
			FOLLOW_SYMLINKS
			${CAUTO_PROJECT_ROOT}/${target_type}/*${source_ext}
		)

		FOREACH(target_source_rel IN LISTS target_sources_rel)
			SET(target_source ${CAUTO_PROJECT_ROOT}/${target_type}/${target_source_rel})
			GET_FILENAME_COMPONENT(target_dirname_rel ${target_source_rel} DIRECTORY)
			STRING(REPLACE ${source_ext} "" target_basename_rel ${target_source_rel})
			GET_FILENAME_COMPONENT(target_binname ${target_basename_rel} NAME)
			STRING(REPLACE / _ target_name ${target_basename_rel})
			LIST(APPEND target_all ${target_name})
			CAUTO_MESSAGE("${target_name}")
			#~ CAUTO_MESSAGE("${target_name} source ${target_source}")
			#~ CAUTO_MESSAGE("${target_name} binary ${CAUTO_BUILD_DIR}/${target_dirname_rel}/${target_binname}")

			SET(target_cxxflags "")
			SET(target_ldflags "")
			SET(target_package "")
			SET(target_incdirs "")
			SET(target_lddirs "")
			SET(target_defs "")
			SET(target_libs "")
			CAUTO_FILE_READ_CONF_LIST(${target_type} ${target_basename_rel} "cxxflags" target_cxxflags)
			CAUTO_FILE_READ_CONF_LIST(${target_type} ${target_basename_rel} "ldflags" target_ldflags)
			CAUTO_FILE_READ_CONF_LIST(${target_type} ${target_basename_rel} "package" target_package)
			CAUTO_FILE_READ_CONF_LIST(${target_type} ${target_basename_rel} "incdirs" target_incdirs)
			CAUTO_FILE_READ_CONF_LIST(${target_type} ${target_basename_rel} "lddirs" target_lddirs)
			CAUTO_FILE_READ_CONF_LIST(${target_type} ${target_basename_rel} "defs" target_defs)
			CAUTO_FILE_READ_CONF_LIST(${target_type} ${target_basename_rel} "libs" target_libs)
			#~ CAUTO_MESSAGE_LIST("${target_name} cxxflags" "${target_cxxflags}")
			#~ CAUTO_MESSAGE_LIST("${target_name} ldflags" "${target_ldflags}")
			#~ CAUTO_MESSAGE_LIST("${target_name} package" "${target_package}")
			#~ CAUTO_MESSAGE_LIST("${target_name} incdirs" "${target_incdirs}")
			#~ CAUTO_MESSAGE_LIST("${target_name} lddirs" "${target_lddirs}")
			#~ CAUTO_MESSAGE_LIST("${target_name} defs" "${target_defs}")
			#~ CAUTO_MESSAGE_LIST("${target_name} libs" "${target_libs}")

			#~ SET(conf_sources "")
			#~ CAUTO_FILE_MAKE_CONF_DEPS(${target_type} ${target_basename_rel} "cxxflags;ldflags;package" conf_sources)
			#~ CAUTO_MESSAGE_LIST("${target_name} conf" "${conf_sources}")

			SET(target_include_dirs "")
			FOREACH(include_dir IN LISTS target_incdirs)
				IF(IS_ABSOLUTE ${include_dir})
					LIST(APPEND target_include_dirs ${include_dir})
				ELSE()
					LIST(APPEND target_include_dirs ${CAUTO_PROJECT_ROOT}/${include_dir})
				ENDIF()
			ENDFOREACH()

			SET(target_libraries "${target_libs}")
			SET(target_definitions "${target_defs}")
			FOREACH(package_prefix IN LISTS target_package)
				IF(package_prefix)
					IF(${package_prefix}_INCLUDE_DIRS)
						#~ CAUTO_MESSAGE("${target_name} include ${package_prefix}")
						LIST(APPEND target_include_dirs "${${package_prefix}_INCLUDE_DIRS}")
					ENDIF()
					IF (${package_prefix}_LIBRARIES)
						#~ CAUTO_MESSAGE("${target_name} link ${package_prefix}")
						LIST(APPEND target_libraries "${${package_prefix}_LIBRARIES}")
					ENDIF()
					IF (${package_prefix}_DEFINITIONS)
						#~ CAUTO_MESSAGE("${target_name} define ${package_prefix}")
						LIST(APPEND target_definitions "${${package_prefix}_DEFINITIONS}")
					ENDIF()
				ENDIF()
			ENDFOREACH()

			SET(compiler_include_dirs "-I${CAUTO_INCLUDE_DIR}")
			FOREACH(include_dir IN LISTS target_include_dirs)
				SET(compiler_include_dirs "${compiler_include_dirs} -I${include_dir}")
			ENDFOREACH()
			STRING(REPLACE ";" " " compiler_include_dirs "${compiler_include_dirs}")
			SEPARATE_ARGUMENTS(compiler_include_dirs UNIX_COMMAND "${compiler_include_dirs}")

			EXECUTE_PROCESS(
				COMMAND ${CMAKE_CXX_COMPILER} ${target_cxxflags} ${compiler_include_dirs} -c -MM ${target_source}
				COMMAND tr -d "\\\\"
				COMMAND tr -d "\\n"
				COMMAND tr " " "\\t"
				COMMAND cut -f3-
				OUTPUT_VARIABLE dep_headers
			)
			SEPARATE_ARGUMENTS(dep_headers UNIX_COMMAND "${dep_headers}")

			SET(dep_sources "")
			FOREACH(dep_header IN LISTS dep_headers)
				GET_FILENAME_COMPONENT(dep_header_ext "${dep_header}" EXT)
				IF(NOT source_ext STREQUAL dep_header_ext)
					STRING(REPLACE "${CAUTO_INCLUDE_DIR}" "${CAUTO_SOURCE_DIR}" dep_source1 "${dep_header}")
					FOREACH(dep_source_ext IN LISTS source_ext_list)
						STRING(REPLACE "${dep_header_ext}" "${dep_source_ext}" dep_source2 "${dep_source1}")
						IF(EXISTS ${dep_source2})
							LIST(APPEND dep_sources ${dep_source2})
							#~ CAUTO_MESSAGE("${target_name} source ${dep_source2}")
						ENDIF()
					ENDFOREACH()
					#~ CAUTO_MESSAGE("${target_name} header ${dep_header}")
				ENDIF()
			ENDFOREACH()

			IF(add_command STREQUAL ADD_EXECUTABLE)
				SET(target_binary ${target_name})
				ADD_EXECUTABLE(${target_name} ${ARGN} ${target_source} ${dep_sources})
				#~ SET_TARGET_PROPERTIES(${target_name} PROPERTIES RUNTIME_OUTPUT_DIRECTORY ${CAUTO_BUILD_DIR}/${target_dirname_rel})
				#~ SET_TARGET_PROPERTIES(${target_name} PROPERTIES RUNTIME_OUTPUT_NAME ${target_binname})
			ELSEIF(add_command STREQUAL ADD_LIBRARY)
				SET(target_binary lib${target_name}.so)
				ADD_LIBRARY(${target_name} ${ARGN} ${target_source} ${dep_sources})
				#~ SET_TARGET_PROPERTIES(${target_name} PROPERTIES LIBRARY_OUTPUT_DIRECTORY ${CAUTO_BUILD_DIR}/${target_dirname_rel})
				#~ SET_TARGET_PROPERTIES(${target_name} PROPERTIES LIBRARY_OUTPUT_NAME ${target_binname})
			ENDIF()
			CAUTO_SET_TARGET_PROPERTIES(${target_name} COMPILE_FLAGS "${target_cxxflags}")
			CAUTO_SET_TARGET_PROPERTIES(${target_name} LINK_FLAGS "${target_ldflags}")
			TARGET_INCLUDE_DIRECTORIES(${target_name} PUBLIC ${target_include_dirs})
            TARGET_COMPILE_OPTIONS(${target_name} PUBLIC ${target_cxxflags})
			TARGET_COMPILE_DEFINITIONS(${target_name} PUBLIC ${target_definitions})
			TARGET_LINK_LIBRARIES(${target_name} PUBLIC ${target_libraries})
		ENDFOREACH()
	ENDFOREACH()

	ADD_CUSTOM_TARGET(list_${target_type} COMMAND echo \""${target_all}\"")
ENDFUNCTION()

########################################################################
# IMPLEMENTATION #######################################################
########################################################################

# init project #########################################################
CAUTO_MESSAGE("CAuto")
SET(CAUTO_PROJECT_FILE ${CMAKE_CURRENT_SOURCE_DIR}/conf/project)
SET(CAUTO_PROJECT "CAutoProj CXX")
CAUTO_FILE_READ_LIST(${CAUTO_PROJECT_FILE} CAUTO_PROJECT)
PROJECT(${CAUTO_PROJECT})
CAUTO_MESSAGE("Project: ${CMAKE_PROJECT_NAME}")

# vars #################################################################
SET(CAUTO_PROJECT_NAME ${CMAKE_PROJECT_NAME})
SET(CAUTO_PROJECT_ROOT ${${CMAKE_PROJECT_NAME}_SOURCE_DIR})

SET(CAUTO_INCLUDE_DIR ${CAUTO_PROJECT_ROOT}/inc)
SET(CAUTO_SOURCE_DIR ${CAUTO_PROJECT_ROOT}/src)
SET(CAUTO_BUILD_DIR ${CAUTO_PROJECT_ROOT}/build)
SET(CAUTO_CONF_DIR ${CAUTO_PROJECT_ROOT}/conf)
SET(CAUTO_PACKAGE_FILE ${CAUTO_PROJECT_ROOT}/conf/package.cmake)
SET(CAUTO_FILES_DIR ${CMAKE_CURRENT_BINARY_DIR}/CAutoFiles)

# includes #############################################################
INCLUDE_DIRECTORIES(${CAUTO_INCLUDE_DIR})

SET(CMAKE_ARCHIVE_OUTPUT_DIRECTORY ${CAUTO_PROJECT_ROOT}/lib)
SET(CMAKE_LIBRARY_OUTPUT_DIRECTORY ${CAUTO_PROJECT_ROOT}/lib)
SET(CMAKE_RUNTIME_OUTPUT_DIRECTORY ${CAUTO_PROJECT_ROOT}/bin)
LIST(APPEND CMAKE_MODULE_PATH "/usr/share/cmake/Modules")
LIST(APPEND CMAKE_MODULE_PATH "${CAUTO_PROJECT_ROOT}/find")
CAUTO_LOG_FIND_SCRIPTS()

CAUTO_MESSAGE("Root: ${CAUTO_PROJECT_ROOT}")
CAUTO_MESSAGE("Include: ${CAUTO_INCLUDE_DIR}")
CAUTO_MESSAGE("Source: ${CAUTO_SOURCE_DIR}")
CAUTO_MESSAGE("Build: ${CAUTO_BUILD_DIR}")
CAUTO_MESSAGE("Config: ${CAUTO_CONF_DIR}")
CAUTO_MESSAGE("Package: ${CAUTO_PACKAGE_FILE}")
CAUTO_MESSAGE("Modules: ${CMAKE_MODULE_PATH}")

# find packages ########################################################
# use package file to call FIND_PACKAGE()
# default-vars (see cmake find_package docs)
# are used if a target is to be build with
# this package by CAuto.
# NOTE: some packages require setting the
#       variables manually
#	Package_FOUND
#	Package_INCLUDE_DIRS
#	Package_LIBRARIES
#	Package_DEFINITIONS
INCLUDE(${CAUTO_PACKAGE_FILE} OPTIONAL)
IF(NOT EXISTS ${CAUTO_PACKAGE_FILE})
	FILE(WRITE ${CAUTO_PACKAGE_FILE} "
#
#	ADD_PACKAGE(<VAR_PREFIX> <FIND_SUFFIX> [REQUIRED] [COMPONENTS ...])
#	ADD_PACKAGE(VTK VTK REQUIRED)
#	ADD_PACKAGE(Boost Boost REQUIRED COMPONENTS system filesystem program_options)
#	ADD_PACKAGE(OSG osg REQUIRED)
#
	\n")

ENDIF()

# exe targets ##########################################################
FIND_TARGET(exe ".cpp" ADD_EXECUTABLE)
FIND_TARGET(so ".cpp" ADD_LIBRARY SHARED)
