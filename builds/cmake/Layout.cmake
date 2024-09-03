################################################################################
#
# Execution File Layout Definitions
#
################################################################################

################################################################################
# configurations
################################################################################
# 中間出力先
set(FIREBIRD_OUTPUT_DIR "${FIREBIRD_BINARY_DIR}/output")
set(CMAKE_ARCHIVE_OUTPUT_DIRECTORY ${FIREBIRD_OUTPUT_DIR})
set(CMAKE_LIBRARY_OUTPUT_DIRECTORY ${FIREBIRD_OUTPUT_DIR})
set(CMAKE_RUNTIME_OUTPUT_DIRECTORY ${FIREBIRD_OUTPUT_DIR})

# 配置先
set(FIREBIRD_GEN_DIR    "${FIREBIRD_BINARY_DIR}/gen")
set(FIREBIRD_EXEC_DIR   "${FIREBIRD_BINARY_DIR}/exec")

# レイアウト定義
if(WIN32)
    set(LODIR_BIN       "/")
    set(LODIR_LIB       "/")
    set(LODIR_PLUGINS   "/plugins")
else()
    set(LODIR_BIN       "/bin")
    set(LODIR_LIB       "/lib")
    set(LODIR_PLUGINS   "/plugins")
endif()

if(CMAKE_SIZEOF_VOID_P EQUAL 8)
    # 64 bits
    set(PLATFORM "x64")
    set(RC_ARCH "RC_ARH_x64")
elseif(CMAKE_SIZEOF_VOID_P EQUAL 4)
    # 32 bits
    set(PLATFORM "x86")
    set(RC_ARCH "RC_ARH_x86")
endif()

################################################################################
# properties
################################################################################

# 配置するファイル
define_property(DIRECTORY PROPERTY FB_LAYOUT_FILES)
# ターゲットのビルド区分
define_property(TARGET PROPERTY FB_BUILD_TYPES)
# ターゲットのデプロイパス
define_property(TARGET PROPERTY FB_DEPLOY_PATH)

################################################################################
# functions
################################################################################

macro(_fb_fetch_arguments type flag)
    if(NOT _ARG_FLAG)
        # フラグなし
        if(_ARG_BUFF)
            message(WARNING "SPECIFIED INVALID PARAMS BEFORE KEYWORD, PARAMS: ${_ARG_BUFF}")
            list(APPEND "_${prefix}_UNPARSED_ARGUMENTS" ${_ARG_BUFF})
        endif()
    elseif(${_ARG_TYPE} STREQUAL "OPTION")
        set("_${prefix}_${_ARG_FLAG}" TRUE)
        if(_ARG_BUFF)
            message(WARNING "SPECIFIED INVALID PARAMS AFTER OPTIONAL KEYWORD, KEYWORD: ${_ARG_FLAG}, PARAMS: ${_ARG_BUFF}")
            list(APPEND "_${prefix}_UNPARSED_ARGUMENTS" ${_ARG_BUFF})
        endif()
    elseif(${_ARG_TYPE} STREQUAL "ONE")
        if(NOT _ARG_BUFF)
            list(APPEND "_${prefix}_KEYWORDS_MISSING_VALUES" "${_ARG_FLAG}")
        else()
            list(POP_FRONT _ARG_BUFF _ARG_VALUE)
            set("_${prefix}_${_ARG_FLAG}" "${_ARG_VALUE}")
            if(_ARG_BUFF)
                message(WARNING "SPECIFIED TOO MANY PARAMS, KEYWORD: ${_ARG_FLAG}, PARAMS: ${_ARG_BUFF}")
                list(APPEND "_${prefix}_UNPARSED_ARGUMENTS" ${_ARG_BUFF})
            endif()
        endif()
    elseif(${_ARG_TYPE} STREQUAL "MULTI")
        if(NOT _ARG_BUFF)
            list(APPEND "_${prefix}_KEYWORDS_MISSING_VALUES" "${_ARG_FLAG}")
        else()
            set("_${prefix}_${_ARG_FLAG}" ${_ARG_BUFF})
        endif()
    elseif(${_ARG_TYPE} STREQUAL "CONDITION")
        if(NOT _ARG_BUFF)
            list(APPEND "_${prefix}_KEYWORDS_MISSING_VALUES" "${_ARG_FLAG}")
        else()
            list(POP_FRONT _ARG_BUFF _ARG_CONDITION)
            if(NOT _ARG_BUFF)
                # 条件のみあって、値がない
                list(APPEND "_${prefix}_KEYWORDS_MISSING_VALUES" "${_ARG_FLAG}")
            elseif(DEFINED "${_ARG_CONDITION}" AND "${${_ARG_CONDITION}}")
                string(REPLACE ";" "\\;" _ARG_VALUES "${_ARG_BUFF}")
                list(APPEND "_${prefix}_${_ARG_FLAG}" "${_ARG_VALUES}")
            endif()
        endif()
    else()
        message(FATAL_ERROR "INTERNAL INCONSISTENCY, UNKNOWN TYPE: ${_ARG_TYPE}")
    endif()

    set(_ARG_TYPE "${type}")
    set(_ARG_FLAG "${flag}")
    set(_ARG_BUFF "")
endmacro()

# fb_parse_arguments
#   <prefix>
#   <options>
#   <onevalue>
#   <multivalue>
#   <condset>
#   <args>...
function(fb_parse_arguments prefix options onevalue multivalue condset)

    # チェック
    if(NOT prefix)
        message(WARNING "prefix WAS EMPTY.")
    endif()

    # 初期化
    set(_ARG_TYPE "")
    set(_ARG_FLAG "")
    set(_ARG_BUFF "")

    # 結果変数の初期化
    foreach(FLAG IN LISTS options)
        set("_${prefix}_${FLAG}" FALSE)
    endforeach()
    foreach(FLAG IN LISTS onevalue multivalue condset)
        unset("_${prefix}_${FLAG}")
    endforeach()
    set("_${prefix}_UNPARSED_ARGUMENTS"         "")
    set("_${prefix}_KEYWORDS_MISSING_VALUES"    "")

    # パース
    foreach(i IN LISTS ARGN)
        if(i IN_LIST options)
            _fb_fetch_arguments("OPTION" "${i}")
        elseif(i IN_LIST onevalue)
            _fb_fetch_arguments("ONE" "${i}")
        elseif(i IN_LIST multivalue)
            _fb_fetch_arguments("MULTI" "${i}")
        elseif(i IN_LIST condset)
            _fb_fetch_arguments("CONDITION" "${i}")
        else()
            list(APPEND _ARG_BUFF "${i}")
        endif()
    endforeach()

    _fb_fetch_arguments("" "")

    # 結果変数の転記
    foreach(FLAG IN ITEMS
        ${options}
        ${onevalue}
        ${multivalue}
        ${condset}
        "UNPARSED_ARGUMENTS"
        "KEYWORDS_MISSING_VALUES")
        
        if(DEFINED "_${prefix}_${FLAG}")
            set("${prefix}_${FLAG}" "${_${prefix}_${FLAG}}" PARENT_SCOPE)
        else()
            unset("${prefix}_${FLAG}" PARENT_SCOPE)
        endif()
    endforeach()
endfunction()
# for fb_parse_arguments
set(COMMON TRUE)

# get_target_suffix
#   <variable>
#   <target>
function(get_target_suffix variable target)
    get_target_property(TGT_TYPE "${target}" TYPE)

    if("${TGT_TYPE}" STREQUAL "STATIC_LIBRARY")
        set(${variable} "${CMAKE_STATIC_LIBRARY_SUFFIX}" PARENT_SCOPE)
    elseif("${TGT_TYPE}" STREQUAL "SHARED_LIBRARY")
        set(${variable} "${CMAKE_SHARED_LIBRARY_SUFFIX}" PARENT_SCOPE)
    elseif("${TGT_TYPE}" STREQUAL "EXECUTABLE")
        set(${variable} "${CMAKE_EXECUTABLE_SUFFIX}" PARENT_SCOPE)
    else()
        message(FATAL_ERROR "UNKNOWN TARGET TYPE, ${TGT_TYPE}. target: ${target}")
    endif()
endfunction()

# fb_add_files
#   COMMON
#   BOOT
#   MAIN
#   LAYOUT_DIR  <directory>
#   OUTPUT_NAME <output>
#   FILES       <files>
#   ROOT_FILES  <files>
#   GEN_FILES   <files>
function(fb_add_files)
    cmake_parse_arguments(FILE
        "COMMON;BOOT;MAIN"
        "LAYOUT_DIR;OUTPUT_NAME"
        "FILES;ROOT_FILES;GEN_FILES"
        ${ARGN}
    )

    # ビルド区分
    set(FILE_BUILD_TYPES "")
    foreach(BUILD IN ITEMS "MAIN" "COMMON" "BOOT")
        if(FILE_${BUILD})
            string(TOLOWER "${BUILD}" LC_BUILD)
            list(APPEND FILE_BUILD_TYPES "${LC_BUILD}")
        endif()
    endforeach()
    if(NOT FILE_BUILD_TYPES)
        message(FATAL_ERROR "NOT DEFINED TARGET BUILD TYPE, REQUIRED COMMON or BOOT or MAIN FLAGS.")
    endif()
    # レイアウト配置先
    if(NOT DEFINED FILE_LAYOUT_DIR)
        message(FATAL_ERROR "NOT DEFINED LAYOUT_DIR.")
    endif()
    # ファイル指定整合性チェック
    list(APPEND
        FILE_CHECKS
        ${FILE_FILES}
        ${FILE_ROOT_FILES}
        ${FILE_GEN_FILES}
    )
    list(LENGTH FILE_CHECKS FILE_COUNTS)
    if(FILE_COUNTS EQUAL 0)
        message(FATAL_ERROR "NOT DEFINED SOURCE FILES.")
    elseif(DEFINED FILE_OUTPUT_NAME AND FILE_COUNTS GREATER 1)
        message(FATAL_ERROR "CAN NOT SPECIFIED MULTIPLE SOURCE FILES WHEN SPECIFIED OUTPUT_NAME.")
    endif()

    # レイアウト処理
    set(LST_ADD_LAYOUTS "")
    list(TRANSFORM FILE_ROOT_FILES PREPEND "${FIREBIRD_SOURCE_DIR}/")

    foreach(BUILD IN LISTS FILE_BUILD_TYPES)
        list(TRANSFORM FILE_GEN_FILES PREPEND "${FIREBIRD_GEN_DIR}/${BUILD}/" OUTPUT_VARIABLE SET_GEN_FILES)

        foreach(ITEM IN LISTS
            FILE_FILES
            FILE_ROOT_FILES
            SET_GEN_FILES)

            # 配置先のパスを作成
            if(DEFINED FILE_OUTPUT_NAME)
                set(ITEM_DEST_PATH "${FIREBIRD_EXEC_DIR}/${BUILD}${FILE_LAYOUT_DIR}/${FILE_OUTPUT_NAME}")
            else()
                cmake_path(GET ITEM FILENAME ITEM_NAME)
                set(ITEM_DEST_PATH "${FIREBIRD_EXEC_DIR}/${BUILD}${FILE_LAYOUT_DIR}/${ITEM_NAME}")
            endif()

            add_custom_command(
                OUTPUT "${ITEM_DEST_PATH}"
                DEPENDS ${ITEM}
                COMMAND ${CMAKE_COMMAND} -E make_directory "${FIREBIRD_EXEC_DIR}/${BUILD}${FILE_LAYOUT_DIR}"
                COMMAND ${CMAKE_COMMAND} -E copy_if_different "${ITEM}" "${ITEM_DEST_PATH}"
                COMMENT "Deploying... ${ITEM_DEST_PATH}"
                VERBATIM
            )
            set_source_files_properties(
                "${ITEM_DEST_PATH}"
                PROPERTIES GENERATED TRUE
            )
            list(APPEND LST_ADD_LAYOUTS "${ITEM_DEST_PATH}")
        endforeach()
    endforeach()

    # レイアウトに追加する
    get_directory_property(LST_LAYOUTS FB_LAYOUT_FILES)
    list(APPEND LST_LAYOUTS ${LST_ADD_LAYOUTS})
    set_directory_properties(PROPERTIES FB_LAYOUT_FILES "${LST_LAYOUTS}")
endfunction()

#
function(_fb_add_layout target dir file)
    cmake_parse_arguments(LO "" "" "DEPENDS;GEN_DEPENDS" ${ARGN})

    list(TRANSFORM
        LO_GEN_DEPENDS
        REPLACE
            [[.+]]
            [[$<TARGET_PROPERTY:\0,FB_DEPLOY_PATH>]]
        OUTPUT_VARIABLE SET_GEN_DEPENDS
    )

    add_custom_command(
        OUTPUT "${FIREBIRD_EXEC_DIR}/${dir}/${file}"
        DEPENDS
            "${target}"
            ${LO_DEPENDS}
            ${SET_GEN_DEPENDS}
        COMMAND ${CMAKE_COMMAND} -E make_directory "${FIREBIRD_EXEC_DIR}/${dir}"
        COMMAND ${CMAKE_COMMAND} -E copy_if_different "$<TARGET_FILE:${target}>" "${FIREBIRD_EXEC_DIR}/${dir}/${file}"
        COMMENT "Deploying... ${FIREBIRD_EXEC_DIR}/${dir}/${file}"
        VERBATIM
    )
    set_target_properties("${target}"
        PROPERTIES
            FB_DEPLOY_PATH "${FIREBIRD_EXEC_DIR}/${dir}/${file}"
            FB_DEPLOY_DIR  "${FIREBIRD_EXEC_DIR}/${dir}"
    )
    set_source_files_properties(
        "${FIREBIRD_EXEC_DIR}/${dir}/${file}"
        PROPERTIES GENERATED TRUE
    )

    get_directory_property(LST_LAYOUTS FB_LAYOUT_FILES)
    list(APPEND LST_LAYOUTS "${FIREBIRD_EXEC_DIR}/${dir}/${file}")
    set_directory_properties(PROPERTIES FB_LAYOUT_FILES "${LST_LAYOUTS}")
endfunction()

#
macro(_fb_resolve_target build input output)
    set(${output} "")

    foreach(_ITEM IN LISTS ${input})
        if(TARGET "${_ITEM}")
            list(APPEND ${output} "${_ITEM}_${build}")
        else()
            message(FATAL_ERROR "THIS LINK ITEM WAS NOT CMAKE TARGET: ${_ITEM}")
        endif()
    endforeach()
endmacro()

# fb_finalize
function(fb_finalize)
    get_directory_property(LST_LAYOUTS FB_LAYOUT_FILES)

    add_custom_target(layout ALL
        DEPENDS
            ${LST_LAYOUTS}
    )
endfunction()

# fb_add_library
#   <target>
#   STATIC | SHARED | MODULE
#   COMMON
#   BOOT
#   MAIN
#   LAYOUT_DIR  <directory>
#   OUTPUT_NAME <output>
#   DEPENDS     <depedencies>
function(fb_add_library target type)
    cmake_parse_arguments(LIB "COMMON;BOOT;MAIN" "LAYOUT_DIR;OUTPUT_NAME" "DEPENDS;GEN_DEPENDS" ${ARGN})

    set(LIB_BUILD_TYPES "")
    foreach(BUILD IN ITEMS "MAIN" "COMMON" "BOOT")
        if(LIB_${BUILD})
            string(TOLOWER "${BUILD}" LC_BUILD)
            list(APPEND LIB_BUILD_TYPES "${LC_BUILD}")
        endif()
    endforeach()
    if(NOT LIB_BUILD_TYPES)
        message(FATAL_ERROR "NOT DEFINED TARGET BUILD TYPE, REQUIRED COMMON or BOOT or MAIN FLAGS. target: ${target}")
    else()
        list(GET LIB_BUILD_TYPES 0 LIB_BUILD_BASE)
    endif()
    if(NOT DEFINED LIB_OUTPUT_NAME)
        set(LIB_OUTPUT_NAME "${target}")
    endif()

    foreach(BUILD IN LISTS LIB_BUILD_TYPES)
        add_library("${target}_${BUILD}" ${type})
        target_compile_features("${target}_${BUILD}"
            PUBLIC
                cxx_std_17
        )
        set_target_properties("${target}_${BUILD}"
            PROPERTIES
                FB_BUILD_TYPES  "${LIB_BUILD_TYPES}"
                ARCHIVE_OUTPUT_DIRECTORY "${FIREBIRD_OUTPUT_DIR}/${BUILD}"
                LIBRARY_OUTPUT_DIRECTORY "${FIREBIRD_OUTPUT_DIR}/${BUILD}"
                RUNTIME_OUTPUT_DIRECTORY "${FIREBIRD_OUTPUT_DIR}/${BUILD}"
                OUTPUT_NAME     "${LIB_OUTPUT_NAME}"
        )
        if(CMAKE_CXX_COMPILER_ID STREQUAL "MSVC")
            target_compile_options("${target}_${BUILD}"
                PRIVATE
                    "/utf-8"
            )
            set_target_properties("${target}_${BUILD}"
                PROPERTIES
                    MSVC_RUNTIME_LIBRARY "MultiThreaded$<$<CONFIG:Debug>:Debug>DLL"
            )
        elseif(APPLE)
            set_target_properties("${target}_${BUILD}"
                PROPERTIES
                    MACOSX_RPATH true
                    LINK_OPTIONS "LINKER:-seg1addr,0x30000000,-current_version,4.0.2,-compatibility_version,4.0.2"
            )
        endif()

        if(DEFINED LIB_LAYOUT_DIR)
            get_target_suffix(TGT_SUFFIX "${target}_${BUILD}")
            _fb_resolve_target("${BUILD}" LIB_GEN_DEPENDS SET_GEN_DEPENDS)

            _fb_add_layout("${target}_${BUILD}"
                "${BUILD}${LIB_LAYOUT_DIR}"
                "${CMAKE_SHARED_LIBRARY_PREFIX}${LIB_OUTPUT_NAME}${TGT_SUFFIX}"
                DEPENDS ${LIB_DEPENDS}
                GEN_DEPENDS ${SET_GEN_DEPENDS}
            )
        endif()
    endforeach()
    add_library("${target}" ALIAS "${target}_${LIB_BUILD_BASE}")
endfunction()

# fb_add_executable
#   <target>
#   WIN32 | MACOSX_BUNDLE
#   COMMON
#   BOOT
#   MAIN
#   LAYOUT_DIR  <directory>
#   OUTPUT_NAME <output>
#   DEPENDS     <depedencies>
function(fb_add_executable target)
    cmake_parse_arguments(EXE
        "WIN32;MACOSX_BUNDLE;COMMON;BOOT;MAIN"
        "LAYOUT_DIR;OUTPUT_NAME"
        "DEPENDS;GEN_DEPENDS"
        ${ARGN}
    )

    set(EXE_FLAGS "")
    if(EXE_WIN32)
        list(APPEND EXE_FLAGS "WIN32")
    elseif(EXE_MACOSX_BUNDLE)
        list(APPEND EXE_FLAGS "MACOSX_BUNDLE")
    endif()
    set(EXE_BUILD_TYPES "")
    foreach(BUILD IN ITEMS "MAIN" "COMMON" "BOOT")
        if(EXE_${BUILD})
            string(TOLOWER "${BUILD}" LC_BUILD)
            list(APPEND EXE_BUILD_TYPES "${LC_BUILD}")
        endif()
    endforeach()
    if(NOT EXE_BUILD_TYPES)
        message(FATAL_ERROR "NOT DEFINED TARGET BUILD TYPE, REQUIRED COMMON or BOOT or MAIN FLAGS. target: ${target}")
    else()
        list(GET EXE_BUILD_TYPES 0 EXE_BUILD_BASE)
    endif()
    if(NOT DEFINED EXE_OUTPUT_NAME)
        set(EXE_OUTPUT_NAME "${target}")
    endif()

    foreach(BUILD IN LISTS EXE_BUILD_TYPES)
        add_executable("${target}_${BUILD}" ${EXE_FLAGS})
        target_compile_features("${target}_${BUILD}"
            PUBLIC
                cxx_std_17
        )
        set_target_properties("${target}_${BUILD}"
            PROPERTIES
                FB_BUILD_TYPES  "${EXE_BUILD_TYPES}"
                RUNTIME_OUTPUT_DIRECTORY "${FIREBIRD_OUTPUT_DIR}/${BUILD}"
                OUTPUT_NAME     "${EXE_OUTPUT_NAME}"
        )
        if(CMAKE_CXX_COMPILER_ID STREQUAL "MSVC")
            target_compile_options("${target}_${BUILD}"
                PRIVATE
                    "/utf-8"
            )
            set_target_properties("${target}_${BUILD}"
                PROPERTIES
                    MSVC_RUNTIME_LIBRARY "MultiThreaded$<$<CONFIG:Debug>:Debug>DLL"
            )
        elseif(UNIX)
            set_target_properties("${target}_${BUILD}"
                PROPERTIES
                    BUILD_RPATH "../lib;../plugins"
            )
        endif()

        if(DEFINED EXE_LAYOUT_DIR)
            _fb_resolve_target("${BUILD}" EXE_GEN_DEPENDS SET_GEN_DEPENDS)

            _fb_add_layout("${target}_${BUILD}"
                "${BUILD}${EXE_LAYOUT_DIR}"
                "${EXE_OUTPUT_NAME}${CMAKE_EXECUTABLE_SUFFIX}"
                DEPENDS ${EXE_DEPENDS}
                GEN_DEPENDS ${SET_GEN_DEPENDS}
            )
        endif()
    endforeach()
    add_executable("${target}" ALIAS "${target}_${EXE_BUILD_BASE}")
endfunction()

# fb_target_symbols
#   <target>
#   SYMBOL <cond> <files>
function(fb_target_symbols target)
    fb_parse_arguments(SYM "" "" "" "SYMBOL" ${ARGN})

    get_target_property(TGT_BUILDS "${target}" FB_BUILD_TYPES)
    foreach(BUILD IN LISTS TGT_BUILDS)
        target_sources("${target}_${BUILD}"
            PRIVATE
                ${SYM_SYMBOL}
        )
        if(APPLE)
            list(TRANSFORM SYM_SYMBOL PREPEND "-exported_symbols_list," OUTPUT_VARIABLE SYM_LINKER)
            list(JOIN SYM_LINKER "," SYM_LINKER)
            set_target_properties("${target}_${BUILD}"
                PROPERTIES
                    LINK_OPTIONS "LINKER:${SYM_LINKER}"
            )
        endif()
    endforeach()
endfunction()

# fb_target_resources
#   <target>
function(fb_target_resources target)

    get_target_property(TGT_BUILDS      "${target}" FB_BUILD_TYPES)
    get_target_property(TGT_OUTPUT_NAME "${target}" OUTPUT_NAME)

    cmake_path(GET TGT_OUTPUT_NAME FILENAME TGT_OUTPUT_NAME)
    get_target_suffix(TGT_SUFFIX "${target}")

    foreach(BUILD IN LISTS TGT_BUILDS)
        target_compile_definitions("${target}_${BUILD}"
            PRIVATE
                "${RC_ARCH}"
                "RC_TARGET_${TGT_OUTPUT_NAME}"
                "RC_TARGET_NAME=${TGT_OUTPUT_NAME}"
                "RC_TARGET_FILENAME=${TGT_OUTPUT_NAME}${TGT_SUFFIX}"
        )
        target_sources("${target}_${BUILD}"
            PRIVATE
                "${FIREBIRD_SOURCE_DIR}/src/jrd/version.rc"
        )
    endforeach()
endfunction()

# fb_target_compile_options
#   <target>
#   INTERFACE       <definitions>
#   PUBLIC          <definitions>
#   PRIVATE         <definitions>
function(fb_target_compile_options target)
    cmake_parse_arguments(OPT "" "" "INTERFACE;PUBLIC;PRIVATE" ${ARGN})

    get_target_property(TGT_BUILDS "${target}" FB_BUILD_TYPES)

    foreach(BUILD IN LISTS TGT_BUILDS)
        target_compile_options("${target}_${BUILD}"
            INTERFACE
                ${OPT_INTERFACE}
            PUBLIC
                ${OPT_PUBLIC}
            PRIVATE
                ${OPT_PRIVATE}
        )
    endforeach()
endfunction()

# fb_target_compile_definitions
#   <target>
#   INTERFACE       <definitions>
#   PUBLIC          <definitions>
#   PRIVATE         <definitions>
function(fb_target_compile_definitions target)
    cmake_parse_arguments(DEF "" "" "INTERFACE;PUBLIC;PRIVATE" ${ARGN})

    get_target_property(TGT_BUILDS "${target}" FB_BUILD_TYPES)

    foreach(BUILD IN LISTS TGT_BUILDS)
        target_compile_definitions("${target}_${BUILD}"
            INTERFACE
                ${DEF_INTERFACE}
            PUBLIC
                ${DEF_PUBLIC}
            PRIVATE
                ${DEF_PRIVATE}
        )
    endforeach()
endfunction()

# fb_target_link_libraries
#   <target>
#   INTERFACE       <libraries>
#   PUBLIC          <libraries>
#   PRIVATE         <libraries>
#   GEN_INTERFACE   <libraries>
#   GEN_PUBLIC      <libraries>
#   GEN_PRIVATE     <libraries>
function(fb_target_link_libraries target)
    cmake_parse_arguments(LNK
        ""
        "" 
        "INTERFACE;PUBLIC;PRIVATE;GEN_INTERFACE;GEN_PUBLIC;GEN_PRIVATE"
        ${ARGN}
    )

    get_target_property(TGT_BUILDS "${target}" FB_BUILD_TYPES)

    foreach(BUILD IN LISTS TGT_BUILDS)
        _fb_resolve_target("${BUILD}" LNK_GEN_INTERFACE SET_GEN_INTERFACE)
        _fb_resolve_target("${BUILD}" LNK_GEN_PUBLIC    SET_GEN_PUBLIC)
        _fb_resolve_target("${BUILD}" LNK_GEN_PRIVATE   SET_GEN_PRIVATE)

        target_link_libraries("${target}_${BUILD}"
            INTERFACE
                ${LNK_INTERFACE}
                ${SET_GEN_INTERFACE}
            PUBLIC
                ${LNK_PUBLIC}
                ${SET_GEN_PUBLIC}
            PRIVATE
                ${LNK_PRIVATE}
                ${SET_GEN_PRIVATE}
        )
    endforeach()
endfunction()

# fb_target_include_directories
#   <target>
#   INTERFACE       <directories>
#   PUBLIC          <directories>
#   PRIVATE         <directories>
#   ROOT_INTERFACE  <directories>
#   ROOT_PUBLIC     <directories>
#   ROOT_PRIVATE    <directories>
#   GEN_INTERFACE   <directories>
#   GEN_PUBLIC      <directories>
#   GEN_PRIVATE     <directories>
function(fb_target_include_directories target)
    cmake_parse_arguments(INC
        ""
        ""
        "INTERFACE;PUBLIC;PRIVATE;ROOT_INTERFACE;ROOT_PUBLIC;ROOT_PRIVATE;GEN_INTERFACE;GEN_PUBLIC;GEN_PRIVATE"
        ${ARGN}
    )

    get_target_property(TGT_BUILDS "${target}" FB_BUILD_TYPES)

    list(TRANSFORM INC_ROOT_INTERFACE PREPEND "${FIREBIRD_SOURCE_DIR}/")
    list(TRANSFORM INC_ROOT_PUBLIC    PREPEND "${FIREBIRD_SOURCE_DIR}/")
    list(TRANSFORM INC_ROOT_PRIVATE   PREPEND "${FIREBIRD_SOURCE_DIR}/")

    foreach(BUILD IN LISTS TGT_BUILDS)
        list(TRANSFORM INC_GEN_INTERFACE PREPEND "${FIREBIRD_GEN_DIR}/${BUILD}/" OUTPUT_VARIABLE SET_GEN_INTERFACE)
        list(TRANSFORM INC_GEN_PUBLIC}   PREPEND "${FIREBIRD_GEN_DIR}/${BUILD}/" OUTPUT_VARIABLE SET_GEN_PUBLIC)
        list(TRANSFORM INC_GEN_PRIVATE   PREPEND "${FIREBIRD_GEN_DIR}/${BUILD}/" OUTPUT_VARIABLE SET_GEN_PRIVATE)

        target_include_directories("${target}_${BUILD}"
            INTERFACE
                ${INC_INTERFACE}
                ${INC_ROOT_INTERFACE}
                ${SET_GEN_INTERFACE}
            PUBLIC
                ${INC_PUBLIC}
                ${INC_ROOT_PUBLIC}
                ${SET_GEN_PUBLIC}
            PRIVATE
                ${INC_PRIVATE}
                ${INC_ROOT_PRIVATE}
                ${SET_GEN_PRIVATE}
        )
    endforeach()
endfunction()

# fb_target_sources
#   <target>
#   INTERFACE       <sources>
#   PUBLIC          <sources>
#   PRIVATE         <sources>
#   ROOT_INTERFACE  <sources>
#   ROOT_PUBLIC     <sources>
#   ROOT_PRIVATE    <sources>
#   GEN_INTERFACE   <sources>
#   GEN_PUBLIC      <sources>
#   GEN_PRIVATE     <sources>
function(fb_target_sources target)
    cmake_parse_arguments(SRC
        ""
        ""
        "INTERFACE;PUBLIC;PRIVATE;ROOT_INTERFACE;ROOT_PUBLIC;ROOT_PRIVATE;GEN_INTERFACE;GEN_PUBLIC;GEN_PRIVATE"
        ${ARGN}
    )

    get_target_property(TGT_BUILDS "${target}" FB_BUILD_TYPES)

    list(TRANSFORM SRC_ROOT_INTERFACE PREPEND "${FIREBIRD_SOURCE_DIR}/")
    list(TRANSFORM SRC_ROOT_PUBLIC    PREPEND "${FIREBIRD_SOURCE_DIR}/")
    list(TRANSFORM SRC_ROOT_PRIVATE   PREPEND "${FIREBIRD_SOURCE_DIR}/")

    foreach(BUILD IN LISTS TGT_BUILDS)
        list(TRANSFORM SRC_GEN_INTERFACE PREPEND "${FIREBIRD_GEN_DIR}/${BUILD}/" OUTPUT_VARIABLE SET_GEN_INTERFACE)
        list(TRANSFORM SRC_GEN_PUBLIC    PREPEND "${FIREBIRD_GEN_DIR}/${BUILD}/" OUTPUT_VARIABLE SET_GEN_PUBLIC)
        list(TRANSFORM SRC_GEN_PRIVATE   PREPEND "${FIREBIRD_GEN_DIR}/${BUILD}/" OUTPUT_VARIABLE SET_GEN_PRIVATE)

        target_sources("${target}_${BUILD}"
            INTERFACE
                ${SRC_INTERFACE}
                ${SRC_ROOT_INTERFACE}
                ${SET_GEN_INTERFACE}
            PUBLIC
                ${SRC_PUBLIC}
                ${SRC_ROOT_PUBLIC}
                ${SET_GEN_PUBLIC}
            PRIVATE
                ${SRC_PRIVATE}
                ${SRC_ROOT_PRIVATE}
                ${SET_GEN_PRIVATE}
        )
    endforeach()
endfunction()
