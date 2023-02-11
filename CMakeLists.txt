
cmake_minimum_required(VERSION 3.8)

project("Firebird" C CXX)

set(FIREBIRD_SOURCE_DIR ${CMAKE_CURRENT_SOURCE_DIR})
set(FIREBIRD_BINARY_DIR ${CMAKE_BINARY_DIR}/${PROJECT_NAME})
set(CMAKE_MODULE_PATH ${FIREBIRD_SOURCE_DIR}/cmake)

set(FIREBIRD_OUTPUT_DIR ${FIREBIRD_BINARY_DIR}/output)
set(FIREBIRD_TEMP_DIR ${FIREBIRD_BINARY_DIR}/temp)
set(FIREBIRD_GEN_DIR ${FIREBIRD_BINARY_DIR}/gen)
#@set FB_INSTALL_SCRIPTS=%FB_ROOT_PATH%\builds\install\arch-specific\win32
#@set FB_ICU_SOURCE_BIN=%FB_ROOT_PATH%\extern\icu\%FB_TARGET_PLATFORM%\release\bin\

# èoóÕêÊ
set(CMAKE_LIBRARY_OUTPUT_DIRECTORY ${FIREBIRD_OUTPUT_DIR})
set(CMAKE_RUNTIME_OUTPUT_DIRECTORY ${FIREBIRD_OUTPUT_DIR})

################################################################################
#
# pre-build
#
################################################################################

if(WIN32)
    # icu
    message(STATUS "Extracting pre-built ICU")
    set(ICU_EXTRACT ${FIREBIRD_SOURCE_DIR}/extern/icu/icu.exe -y
        CACHE STRING "ICU extraction variable")
    execute_process(COMMAND ${ICU_EXTRACT})

    # tzdata
    message(STATUS "Extracting tzdata")
    file(MAKE_DIRECTORY ${FIREBIRD_TEMP_DIR}/tzdata)
    set(TZD_EXTRACT "Expand-Archive -Path ${FIREBIRD_SOURCE_DIR}/extern/icu/tzdata/le.zip -DestinationPath ${FIREBIRD_TEMP_DIR}/tzdata"
        CACHE STRING "tzdata extraction variable")
    execute_process(COMMAND pwsh.exe -ExecutionPolicy Bypass -Command "${TZD_EXTRACT}")
endif()

################################################################################
#
# main
#
################################################################################
include(BuildFunctions)

message(STATUS "Creating directories")
foreach(DIR IN LISTS "alice" "auth" "auth/SecurityDatabase" "burp" "dsql" "gpre" "gpre/std" "isql" "jrd" "misc" "msgs" "qli" "examples" "yvalve" "utilities" "utilities/gstat")
    file(MAKE_DIRECTORY "${FIREBIRD_GEN_DIR}/${DIR}")
endforeach()

# interfaces
message(STATUS "Building CLOOP and generating interfaces...")
file(GLOB cloop_src "extern/cloop/src/cloop/*.cpp" "extern/cloop/src/cloop/*.h")
add_executable(cloop ${cloop_src})
project_group(cloop Extern)

add_executable(def_awk "${FIREBIRD_SOURCE_DIR}/src/misc/def_awk.c")
project_group(def_awk Extern)
add_executable(isc_grep "${FIREBIRD_SOURCE_DIR}/src/misc/isc_grep.c")
project_group(isc_grep Extern)

add_custom_command(
    OUTPUT ${FIREBIRD_SOURCE_DIR}/src/include/firebird/IdlFbInterfaces.h
    DEPENDS
        cloop
        ${FIREBIRD_SOURCE_DIR}/src/include/firebird/FirebirdInterface.idl
    COMMAND cloop
            "${FIREBIRD_SOURCE_DIR}/src/include/firebird/FirebirdInterface.idl"
            c++
            "${FIREBIRD_SOURCE_DIR}/src/include/firebird/IdlFbInterfaces.h"
            IDL_FB_INTERFACES_H Firebird I
    COMMENT "Updating cloop interfaces..."
)
add_custom_command(
    OUTPUT ${FIREBIRD_GEN_DIR}/misc/func.pas
    DEPENDS
        ${FIREBIRD_SOURCE_DIR}/src/misc/pascal/fb_get_master_interface.pas
        ${FIREBIRD_SOURCE_DIR}/src/include/firebird/impl/consts_pub.h
        ${FIREBIRD_SOURCE_DIR}/lang_helpers/gds_codes.pas
        def_awk
        isc_grep
    COMMAND ${CMAKE_COMMAND} -E copy_if_different "${FIREBIRD_SOURCE_DIR}/src/misc/pascal/fb_get_master_interface.pas" "${FIREBIRD_GEN_DIR}/misc/func.pas"
    COMMAND def_awk < "${FIREBIRD_SOURCE_DIR}/src/include/firebird/impl/consts_pub.h" >> "${FIREBIRD_GEN_DIR}/misc/func.pas"
	COMMAND isc_grep < "${FIREBIRD_SOURCE_DIR}/lang_helpers/gds_codes.pas" >> "${FIREBIRD_GEN_DIR}/misc/func.pas"
)
add_custom_command(
    OUTPUT ${FIREBIRD_GEN_DIR}/Firebird.pas
    DEPENDS
        cloop
        ${FIREBIRD_SOURCE_DIR}/src/include/firebird/FirebirdInterface.idl
        ${FIREBIRD_SOURCE_DIR}/src/misc/pascal/Pascal.interface.pas
        ${FIREBIRD_SOURCE_DIR}/src/misc/pascal/Pascal.implementation.pas
        ${FIREBIRD_GEN_DIR}/misc/func.pas
    COMMAND cloop
            "${FIREBIRD_SOURCE_DIR}/src/include/firebird/FirebirdInterface.idl"
            pascal
            "${FIREBIRD_GEN_DIR}/Firebird.pas"
            Firebird
            --uses SysUtils
            --interfaceFile "${FIREBIRD_SOURCE_DIR}/src/misc/pascal/Pascal.interface.pas"
            --implementationFile "${FIREBIRD_SOURCE_DIR}/src/misc/pascal/Pascal.implementation.pas"
            --exceptionClass FbException
            --functionsFile "${FIREBIRD_GEN_DIR}/misc/func.pas"
            --prefix I
)
add_custom_target(UpdateCloopInterfaces
    DEPENDS
        ${FIREBIRD_SOURCE_DIR}/src/include/firebird/IdlFbInterfaces.h
        ${FIREBIRD_GEN_DIR}/Firebird.pas
    SOURCES
        ${FIREBIRD_SOURCE_DIR}/src/include/firebird/FirebirdInterface.idl
)
project_group(UpdateCloopInterfaces "Boot/Custom build steps")

# btyacc
