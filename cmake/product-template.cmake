set(CMAKE_EXPORT_COMPILE_COMMANDS ON CACHE INTERNAL "")

message("Compiler: ${CMAKE_CXX_COMPILER}")
message("Compiler version: ${CMAKE_CXX_COMPILER_VERSION}")

if(${CMAKE_SYSTEM_NAME} STREQUAL "Linux")
	string(REGEX REPLACE "([0-9]+.[0-9]+.[0.9]+).*" "\\1" COMPILER_VERSION ${CMAKE_CXX_COMPILER_VERSION})
	string(TOLOWER ${CMAKE_CXX_COMPILER_ID} COMPILER_PREFIX)
	set(TARGET_COMPILER ${COMPILER_PREFIX}${COMPILER_VERSION} CACHE STRING "TARGET COMPILER")
else()
	string(REGEX REPLACE "([0-9]+.[0-9]+).*" "\\1" COMPILER_VERSION ${CMAKE_CXX_COMPILER_VERSION})
	string(TOLOWER ${CMAKE_CXX_COMPILER_ID} COMPILER_PREFIX)
	set(TARGET_COMPILER ${COMPILER_PREFIX}${COMPILER_VERSION} CACHE STRING "TARGET COMPILER")
endif()

set(PRODUCT_CONFIGURATION_FILE "${CMAKE_CURRENT_SOURCE_DIR}/product-config.json")
if(NOT EXISTS ${PRODUCT_CONFIGURATION_FILE})
	message(FATAL_ERROR "No product-config.json file in the product directory")
endif()

file(READ ${PRODUCT_CONFIGURATION_FILE} PRODUCT_CONTENT)
string(JSON PRODUCT_NAME ERROR_VARIABLE JSON_STATUS GET ${PRODUCT_CONTENT} "name")
if(NOT ${JSON_STATUS} STREQUAL "NOTFOUND")
	message(FATAL_ERROR "product 'name' missing from product-config.json " ${JSON_STATUS})
endif()	

string(JSON PRODUCT_DESCRIPTION ERROR_VARIABLE JSON_STATUS GET ${PRODUCT_CONTENT} "description")
if(NOT ${JSON_STATUS} STREQUAL "NOTFOUND")
	message(FATAL_ERROR "product 'description' missing from product-config.json " ${JSON_STATUS})
endif()

string(JSON PRODUCT_TYPE ERROR_VARIABLE JSON_STATUS GET ${PRODUCT_CONTENT} "type")
if(NOT ${JSON_STATUS} STREQUAL "NOTFOUND")
	message(FATAL_ERROR "product 'type' missing from product-config.json " ${JSON_STATUS})
endif()

string(JSON PRODUCT_VERSION ERROR_VARIABLE JSON_STATUS GET ${PRODUCT_CONTENT} "version")
if(NOT ${JSON_STATUS} STREQUAL "NOTFOUND")
	message(FATAL_ERROR "product 'version' missing from product-config.json " ${JSON_STATUS})
endif()

set(CMAKE_CXX_STANDARD_REQUIRED ON)
string(JSON PRODUCT_CPP_STANDARD ERROR_VARIABLE JSON_STATUS GET ${PRODUCT_CONTENT} "cpp_standard")
if(NOT ${JSON_STATUS} STREQUAL "NOTFOUND")
	message(FATAL_ERROR "product 'cpp_standard' missing from product-config.json " ${JSON_STATUS})
endif()
set(CMAKE_CXX_STANDARD ${PRODUCT_CPP_STANDARD})
if (NOT CMAKE_CXX_STANDARD MATCHES "11|14|17|20|23")
	message(FATAL_ERROR "Invalid C++ standard: ${CMAKE_CXX_STANDARD}")
endif()
set(CXX_STANDARD "cxx_std_${CMAKE_CXX_STANDARD}")

string(JSON PRODUCT_INSTALL ERROR_VARIABLE JSON_STATUS GET ${PRODUCT_CONTENT} "install_artifact")
if(NOT ${JSON_STATUS} STREQUAL "NOTFOUND")
	set(INSTALL_PRODUCT ON)
else()
	set(INSTALL_PRODUCT ${PRODUCT_INSTALL})
endif()

string(JSON source ERROR_VARIABLE JSON_STATUS GET ${PRODUCT_CONTENT} "source")
foreach(index RANGE 0 999)
	string(JSON file ERROR_VARIABLE JSON_STATUS GET ${source} ${index})
	if(NOT ${JSON_STATUS} STREQUAL "NOTFOUND")
		break()
	endif()
	list(APPEND SOURCE_FILES ${file})	
endforeach()

string(JSON deployed_headers ERROR_VARIABLE JSON_STATUS GET ${PRODUCT_CONTENT} "deployed_headers")
foreach(index RANGE 0 999)
	string(JSON file ERROR_VARIABLE JSON_STATUS GET ${deployed_headers} ${index})
	if(NOT ${JSON_STATUS} STREQUAL "NOTFOUND")
		break()
	endif()
	list(APPEND DEPLOYED_HEADERS ${file})	
endforeach()

set(PRODUCT_SPEC ${PRODUCT_NAME}-${PRODUCT_VERSION}-${ARCHITECTURE}-${OS}-${TARGET_COMPILER})
set(PRODUCT_PATH ${CMAKE_CURRENT_SOURCE_DIR})

set(RUNTIME_OUTPUT_DIRECTORY ${CMAKE_BINARY_DIR}/runtime)

cmake_path(GET PRODUCT_PATH PARENT_PATH include_path)
if(${PRODUCT_TYPE} STREQUAL "header-only")
	add_library(${PRODUCT_NAME} INTERFACE ${SOURCE_FILES})
	target_compile_features(${PRODUCT_NAME} INTERFACE ${CXX_STANDARD})
	target_include_directories(${PRODUCT_NAME}
		INTERFACE
		$<BUILD_INTERFACE:${include_path}>
		$<INSTALL_INTERFACE:$<INSTALL_PREFIX>/${PRODUCT_SPEC}/include>
	)
elseif(${PRODUCT_TYPE} STREQUAL "static")
	add_library(${PRODUCT_NAME} STATIC ${SOURCE_FILES})
	target_compile_features(${PRODUCT_NAME} PUBLIC ${CXX_STANDARD})
	target_include_directories(${PRODUCT_NAME}
		PUBLIC
		$<BUILD_INTERFACE:${include_path}>
		$<INSTALL_INTERFACE:$<INSTALL_PREFIX>/${PRODUCT_SPEC}/include>
	)
elseif(${PRODUCT_TYPE} STREQUAL "shared")
	add_library(${PRODUCT_NAME} SHARED ${SOURCE_FILES})
	target_compile_features(${PRODUCT_NAME} PUBLIC ${CXX_STANDARD})
	target_include_directories(${PRODUCT_NAME}
		PUBLIC
		$<BUILD_INTERFACE:${include_path}>
		$<INSTALL_INTERFACE:$<INSTALL_PREFIX>/${PRODUCT_SPEC}/include>
	)
elseif("${PRODUCT_TYPE}" STREQUAL "binary")
	add_executable(${PRODUCT_NAME} ${SOURCE_FILES})
	target_compile_features(${PRODUCT_NAME} PUBLIC ${CXX_STANDARD})
	target_include_directories(${PRODUCT_NAME}
		PUBLIC
		$<BUILD_INTERFACE:${include_path}>
		$<INSTALL_INTERFACE:$<INSTALL_PREFIX>/${PRODUCT_SPEC}/include>
	)
else()
	message(FATAL "Invalid product type in product-info.json: ${PRODUCT_TYPE}")
endif()

if(${CMAKE_SYSTEM_NAME} STREQUAL "Linux")
	if(NOT ${PRODUCT_TYPE} STREQUAL "header-only")
		find_package(Threads REQUIRED)
		target_link_libraries(${PRODUCT_NAME}
			PUBLIC
				dl
				stdc++fs
				rt
				Threads::Threads
		)
	endif()
	set_target_properties(${PRODUCT_NAME}
		PROPERTIES
			LINKER_LANGUAGE CXX
			POSITION_INDEPENDENT_CODE TRUE
			DEBUG_POSTFIX ""
			RELEASE_POSTFIX ""
	)
endif()

if(${CMAKE_SYSTEM_NAME} STREQUAL "Windows")
	if(NOT ${PRODUCT_TYPE} STREQUAL "header-only")
		target_link_libraries(${PRODUCT_NAME}
			PUBLIC
				Ws2_32
		)
	endif()
	set_target_properties(${PRODUCT_NAME}
		PROPERTIES
			LINKER_LANGUAGE_CXX
			POSITION_INDEPENDENT_CODE TRUE
			DEBUG_POSTFIX ""
			RELEASE_POSTFIX ""
	)
endif()

if(${PRODUCT_INSTALL})
	install(TARGETS ${PRODUCT_NAME} EXPORT ${PRODUCT_NAME}-targets
		RUNTIME DESTINATION ${PRODUCT_SPEC}/bin/${CMAKE_BUILD_TYPE}
		LIBRARY DESTINATION ${PRODUCT_SPEC}/lib/${CMAKE_BUILD_TYPE}
		ARCHIVE DESTINATION ${PRODUCT_SPEC}/lib/${CMAKE_BUILD_TYPE}
	)

	# Iterate through each header file
	foreach(file ${DEPLOYED_HEADERS})
		get_filename_component(directory "${file}" DIRECTORY)
		# Install the file with its directory structure preserved
		install(
			FILES "${file}"
			DESTINATION "${PRODUCT_SPEC}/include/${PRODUCT_NAME}/${directory}"
		)
	endforeach()

	if(MSVC AND ${CMAKE_BUILD_TYPE} STREQUAL "debug" AND (${PRODUCT_TYPE} STREQUAL "static" OR ${PRODUCT_TYPE} STREQUAL "shared"))
		install(DIRECTORY ${CMAKE_CURRENT_BINARY_DIR}/${CMAKE_BUILD_TYPE} DESTINATION ${PRODUCT_SPEC}/lib FILES_MATCHING PATTER "*.pdb")
	elseif(MSVC AND ${PRODUCT_TYPE} STREQUAL "binary")
		install(FILES $<TARGET_PDB_FILE:${PRODUCT_NAME}> DESTINATION ${PRODUCT_SPEC}/bin/${CMAKE_BUILD_TYPE} OPTIONAL)
	endif()

	set(DEPLOYED_CMAKE_TEMP_PATH "${RUNTIME_OUTPUT_DIRECTORY}/${PRODUCT_NAME}/cmake")
	set(DEPLOYED_CMAKE_PATH "${PRODUCT_SPEC}/share/cmake/${PRODUCT_NAME}")

	install(EXPORT ${PRODUCT_NAME}-targets
		FILE "${PRODUCT_NAME}-targets.cmake"
		DESTINATION ${DEPLOYED_CMAKE_PATH}
	)

	configure_file("${CMAKE_SOURCE_DIR}/cmake/project-config.cmake"
		"${DEPLOYED_CMAKE_TEMP_PATH}/${PRODUCT_NAME}-config.cmake"
		@ONLY
	)

	include(CMakePackageConfigHelpers)
	write_basic_package_version_file(
		"${DEPLOYED_CMAKE_TEMP_PATH}/${PRODUCT_NAME}-config-version.cmake"
		VERSION ${PRODUCT_VERSION}
		COMPATIBILITY AnyNewerVersion
	)

	install(
		FILES
			"${DEPLOYED_CMAKE_TEMP_PATH}/${PRODUCT_NAME}-config.cmake"
			"${DEPLOYED_CMAKE_TEMP_PATH}/${PRODUCT_NAME}-config-version.cmake"
		DESTINATION "${DEPLOYED_CMAKE_PATH}"
	)
endif()

message("Finalized configuration of product: ${PRODUCT_NAME}")
message("")