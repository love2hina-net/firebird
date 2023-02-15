
if(CMAKE_SIZEOF_VOID_P EQUAL 8)
    # 64 bits
    set(PLATFORM "x64")
    set(RC_ARCH "RC_ARH_x64")
elseif(CMAKE_SIZEOF_VOID_P EQUAL 4)
    # 32 bits
    set(PLATFORM "x86")
    set(RC_ARCH "RC_ARH_x86")
endif()

# resource
function(target_resource target)
    cmake_parse_arguments(RES "" "OUTPUT_NAME" "" ${ARGN})

    if(NOT DEFINED RES_OUTPUT_NAME)
        set(RES_OUTPUT_NAME ${target})
    endif()

    get_target_property(type ${target} TYPE)
    if("${type}" STREQUAL "SHARED_LIBRARY")
        set(extention ".dll")
    elseif("${type}" STREQUAL "EXECUTABLE")
        set(extention ".exe")
    endif()

    target_compile_definitions(${target}
        PRIVATE
            "${RC_ARCH}"
            "RC_TARGET_${RES_OUTPUT_NAME}"
            "RC_TARGET_NAME=${RES_OUTPUT_NAME}"
            "RC_TARGET_FILENAME=${RES_OUTPUT_NAME}${extention}"
    )
    target_sources(${target}
        PRIVATE
            "${FIREBIRD_SOURCE_DIR}/src/jrd/version.rc"
    )
endfunction()

# layout
foreach(DIR IN ITEMS
    ""
    "alice"
    "auth"
    "auth/SecurityDatabase"
    "burp"
    "dsql"
    "gpre"
    "gpre/std"
    "isql"
    "jrd"
    "misc"
    "msgs"
    "qli"
    "examples"
    "yvalve"
    "utilities"
    "utilities/gstat")

    add_custom_command(
        OUTPUT "${FIREBIRD_GEN_DIR}/boot/${DIR}"
        COMMAND ${CMAKE_COMMAND} -E make_directory "${FIREBIRD_GEN_DIR}/boot/${DIR}"
        COMMENT "Creating directory: ${FIREBIRD_GEN_DIR}/boot/${DIR}"
        VERBATIM
    )
    add_custom_command(
        OUTPUT "${FIREBIRD_GEN_DIR}/master/${DIR}"
        COMMAND ${CMAKE_COMMAND} -E make_directory "${FIREBIRD_GEN_DIR}/master/${DIR}"
        COMMENT "Creating directory: ${FIREBIRD_GEN_DIR}/master/${DIR}"
        VERBATIM
    )
endforeach()
add_custom_command(
    OUTPUT "${FIREBIRD_GEN_DIR}/dbs"
    COMMAND ${CMAKE_COMMAND} -E make_directory "${FIREBIRD_GEN_DIR}/dbs"
    COMMENT "Creating directory: ${FIREBIRD_GEN_DIR}/dbs"
    VERBATIM
)
add_custom_command(
    OUTPUT "${FIREBIRD_GEN_DIR}/include"
    COMMAND ${CMAKE_COMMAND} -E make_directory "${FIREBIRD_GEN_DIR}/include"
    COMMENT "Creating directory: ${FIREBIRD_GEN_DIR}/include"
    VERBATIM
)

foreach(DIR IN ITEMS
    ""
    "plugins")

    add_custom_command(
        OUTPUT "${FIREBIRD_EXEC_DIR}/boot/${DIR}"
        COMMAND ${CMAKE_COMMAND} -E make_directory "${FIREBIRD_EXEC_DIR}/boot/${DIR}"
        COMMENT "Creating directory: ${FIREBIRD_EXEC_DIR}/boot/${DIR}"
        VERBATIM
    )
    add_custom_command(
        OUTPUT "${FIREBIRD_EXEC_DIR}/master/${DIR}"
        COMMAND ${CMAKE_COMMAND} -E make_directory "${FIREBIRD_EXEC_DIR}/master/${DIR}"
        COMMENT "Creating directory: ${FIREBIRD_EXEC_DIR}/master/${DIR}"
        VERBATIM
    )
endforeach()

# add_library
function (add_dual_library target type)
    cmake_parse_arguments(LIB "" "OUTPUT_NAME" "" ${ARGN})
    if(NOT DEFINED LIB_OUTPUT_NAME)
        set(LIB_OUTPUT_NAME ${target})
    endif()

    foreach(BASE IN ITEMS "boot" "master")
        add_library("${target}_${BASE}" ${type})
        set_target_properties("${target}_${BASE}" PROPERTIES OUTPUT_NAME "${BASE}/${LIB_OUTPUT_NAME}")
    endforeach()
endfunction()

# add_executable
function (add_dual_executable target)
    cmake_parse_arguments(EXE "WIN32;MACOSX_BUNDLE" "OUTPUT_NAME" "" ${ARGN})
    if(EXE_WIN32)
        list(APPEND EXE_FLAGS "WIN32")
    endif()
    if(EXE_MACOSX_BUNDLE)
        list(APPEND EXE_FLAGS "MACOSX_BUNDLE")
    endif()
    if(NOT DEFINED EXE_OUTPUT_NAME)
        set(EXE_OUTPUT_NAME ${target})
    endif()

    foreach(BASE IN ITEMS "boot" "master")
        add_executable("${target}_${BASE}" ${EXE_FLAGS})
        set_target_properties("${target}_${BASE}" PROPERTIES OUTPUT_NAME "${BASE}/${EXE_OUTPUT_NAME}")
    endforeach()
endfunction()

# target_resource
function(target_dual_resource target)
    cmake_parse_arguments(RES "" "OUTPUT_NAME" "" ${ARGN})

    if(NOT DEFINED RES_OUTPUT_NAME)
        set(RES_OUTPUT_NAME ${target})
    endif()
    foreach(BASE IN ITEMS "boot" "master")
        target_resource("${target}_${BASE}" OUTPUT_NAME ${RES_OUTPUT_NAME})
    endforeach()
endfunction()

# target_compile_definitions
function (target_dual_compile_definitions target)
    cmake_parse_arguments(DEF "" "" "INTERFACE;PUBLIC;PRIVATE" ${ARGN})

    foreach(BASE IN ITEMS "boot" "master")
        target_compile_definitions("${target}_${BASE}"
            INTERFACE ${DEF_INTERFACE}
            PUBLIC ${DEF_PUBLIC}
            PRIVATE ${DEF_PRIVATE})
    endforeach()
endfunction()

# target_include_directories
function (target_dual_include_directories target)
    cmake_parse_arguments(INC "" "" "INTERFACE;PUBLIC;PRIVATE" ${ARGN})

    foreach(BASE IN ITEMS "boot" "master")
        target_include_directories("${target}_${BASE}"
            INTERFACE ${INC_INTERFACE}
            PUBLIC ${INC_PUBLIC}
            PRIVATE ${INC_PRIVATE})
    endforeach()
endfunction()

# target_sources
function (target_dual_sources target)
    cmake_parse_arguments(SRC "" ""
        "INTERFACE;PUBLIC;PRIVATE;ROOT_INTERFACE;ROOT_PUBLIC;ROOT_PRIVATE;GEN_INTERFACE;GEN_PUBLIC;GEN_PRIVATE" ${ARGN})

    list(TRANSFORM SRC_ROOT_INTERFACE PREPEND "${FIREBIRD_SOURCE_DIR}/")
    list(TRANSFORM SRC_ROOT_PUBLIC    PREPEND "${FIREBIRD_SOURCE_DIR}/")
    list(TRANSFORM SRC_ROOT_PRIVATE   PREPEND "${FIREBIRD_SOURCE_DIR}/")
    foreach(BASE IN ITEMS "boot" "master")
        list(TRANSFORM SRC_GEN_INTERFACE PREPEND "${FIREBIRD_GEN_DIR}/${BASE}/" OUTPUT_VARIABLE SET_GEN_INTERFACE)
        list(TRANSFORM SRC_GEN_PUBLIC}   PREPEND "${FIREBIRD_GEN_DIR}/${BASE}/" OUTPUT_VARIABLE SET_GEN_PUBLIC)
        list(TRANSFORM SRC_GEN_PRIVATE   PREPEND "${FIREBIRD_GEN_DIR}/${BASE}/" OUTPUT_VARIABLE SET_GEN_PRIVATE)

        target_sources("${target}_${BASE}"
            INTERFACE ${SRC_INTERFACE} ${SRC_ROOT_INTERFACE} ${SET_GEN_INTERFACE}
            PUBLIC ${SRC_PUBLIC} ${SRC_ROOT_PUBLIC} ${SET_GEN_PUBLIC}
            PRIVATE ${SRC_PRIVATE} ${SRC_ROOT_PRIVATE} ${SET_GEN_PRIVATE})
    endforeach()
endfunction()

# yvalve
add_custom_command(
    OUTPUT "${FIREBIRD_EXEC_DIR}/boot/fbclient.dll"
    DEPENDS
        yvalve_boot
        "${FIREBIRD_EXEC_DIR}/boot"
    COMMAND ${CMAKE_COMMAND} -E copy_if_different "$<TARGET_FILE:yvalve_boot>" "${FIREBIRD_EXEC_DIR}/boot/fbclient.dll"
    VERBATIM
)

# engine
add_custom_command(
    OUTPUT "${FIREBIRD_EXEC_DIR}/boot/plugins/engine13.dll"
    DEPENDS
        engine_boot
        "${FIREBIRD_EXEC_DIR}/boot/plugins"
    COMMAND ${CMAKE_COMMAND} -E copy_if_different "$<TARGET_FILE:engine_boot>" "${FIREBIRD_EXEC_DIR}/boot/plugins/engine13.dll"
    VERBATIM
)

# gbak
add_custom_command(
    OUTPUT "${FIREBIRD_EXEC_DIR}/boot/gbak.exe"
    DEPENDS
        gbak_boot
        "${FIREBIRD_EXEC_DIR}/boot"
        "${FIREBIRD_EXEC_DIR}/boot/fbclient.dll"
        "${FIREBIRD_EXEC_DIR}/boot/plugins/engine13.dll"
    COMMAND ${CMAKE_COMMAND} -E copy_if_different "$<TARGET_FILE:gbak_boot>" "${FIREBIRD_EXEC_DIR}/boot/gbak.exe"
    VERBATIM
)

# gpre
add_custom_command(
    OUTPUT "${FIREBIRD_EXEC_DIR}/boot/gpre.exe"
    DEPENDS
        gpre_master
        "${FIREBIRD_EXEC_DIR}/boot"
        "${FIREBIRD_EXEC_DIR}/boot/fbclient.dll"
        "${FIREBIRD_EXEC_DIR}/boot/plugins/engine13.dll"
    COMMAND ${CMAKE_COMMAND} -E copy_if_different "$<TARGET_FILE:gpre_master>" "${FIREBIRD_EXEC_DIR}/boot/gpre.exe"
    VERBATIM
)

# isql
add_custom_command(
    OUTPUT "${FIREBIRD_EXEC_DIR}/boot/isql.exe"
    DEPENDS
        isql_boot
        "${FIREBIRD_EXEC_DIR}/boot"
        "${FIREBIRD_EXEC_DIR}/boot/fbclient.dll"
        "${FIREBIRD_EXEC_DIR}/boot/plugins/engine13.dll"
    COMMAND ${CMAKE_COMMAND} -E copy_if_different "$<TARGET_FILE:isql_boot>" "${FIREBIRD_EXEC_DIR}/boot/isql.exe"
    VERBATIM
)

set_source_files_properties(
    "${FIREBIRD_EXEC_DIR}/boot/fbclient.dll"
    "${FIREBIRD_EXEC_DIR}/boot/plugins/engine13.dll"
    "${FIREBIRD_EXEC_DIR}/boot/gpre.exe"
    "${FIREBIRD_EXEC_DIR}/boot/isql.exe"
    PROPERTIES GENERATED TRUE
)

# preprocess
function(preprocess PREP_TYPE PREP_DIR PREP_FILE GPRE_OPT)
    if(${PREP_TYPE} STRLESS_EQUAL "boot")
        set(GPRE_EXE "$<TARGET_FILE:gpre_boot>")
        set(BASE_DIR "boot")
        set(META_FDB "")
    else()
        set(GPRE_EXE "${FIREBIRD_EXEC_DIR}/boot/gpre.exe")
        set(BASE_DIR "master")
        set(META_FDB "${FIREBIRD_GEN_DIR}/dbs/yachts.lnk;${FIREBIRD_GEN_DIR}/dbs/MSG.FDB;${FIREBIRD_GEN_DIR}/dbs/HELP.FDB")
    endif()

    add_custom_command(
        OUTPUT "${FIREBIRD_GEN_DIR}/${BASE_DIR}/${PREP_DIR}/${PREP_FILE}.cpp"
        DEPENDS
            "${FIREBIRD_SOURCE_DIR}/src/${PREP_DIR}/${PREP_FILE}.epp"
            "${FIREBIRD_GEN_DIR}/${BASE_DIR}/${PREP_DIR}"
            "${FIREBIRD_GEN_DIR}/dbs"
            ${GPRE_EXE}
            ${META_FDB}
        COMMAND pwsh.exe -ExecutionPolicy Bypass -Command "\
            $mutex = New-Object -TypeName 'System.Threading.Mutex' -ArgumentList @($false, 'Global\\firebird_gpre');\
            [void] $mutex.WaitOne();\
            & '${GPRE_EXE}' $<JOIN:${GPRE_OPT}, >\
            '${FIREBIRD_SOURCE_DIR}/src/${PREP_DIR}/${PREP_FILE}.epp'\
            '${FIREBIRD_GEN_DIR}/${BASE_DIR}/${PREP_DIR}/${PREP_FILE}.gen'\
            -b '${FIREBIRD_GEN_DIR}/dbs/';\
            [void] $mutex.ReleaseMutex();\
            if (-not (Test-Path -Path '${FIREBIRD_GEN_DIR}/${BASE_DIR}/${PREP_DIR}/${PREP_FILE}.cpp') -or \
               (Compare-Object -ReferenceObject $(Get-Content '${FIREBIRD_GEN_DIR}/${BASE_DIR}/${PREP_DIR}/${PREP_FILE}.gen') -DifferenceObject $(Get-Content '${FIREBIRD_GEN_DIR}/${BASE_DIR}/${PREP_DIR}/${PREP_FILE}.cpp'))) {\
                Move-Item -Force -Path '${FIREBIRD_GEN_DIR}/${BASE_DIR}/${PREP_DIR}/${PREP_FILE}.gen' -Destination '${FIREBIRD_GEN_DIR}/${BASE_DIR}/${PREP_DIR}/${PREP_FILE}.cpp'\
            } else {\
                Remove-Item -Path '${FIREBIRD_GEN_DIR}/${BASE_DIR}/${PREP_DIR}/${PREP_FILE}.gen'\
            }"
        COMMENT "Processing ${PREP_TYPE}: ${FIREBIRD_SOURCE_DIR}/src/${PREP_DIR}/${PREP_FILE}.epp"
        VERBATIM
    )
    set_source_files_properties(
        "${FIREBIRD_GEN_DIR}/${BASE_DIR}/${PREP_DIR}/${PREP_FILE}.cpp"
        PROPERTIES GENERATED TRUE
    )
endfunction()
