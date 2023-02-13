
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
function(target_set_resource target outname)
    if ("$<BOOL:${outname}>")
        get_target_property(outputname ${target} OUTPUT_NAME)
        set(outname "$<PATH:GET_FILENAME,${outputname}>")
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
            "RC_TARGET_$<IF:$<BOOL:${outname}>,${outname},${target}>"
            "RC_TARGET_NAME=$<IF:$<BOOL:${outname}>,${outname},${target}>"
            "RC_TARGET_FILENAME=$<IF:$<BOOL:${outname}>,${outname},${target}>${extention}"
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
        gpre
        "${FIREBIRD_EXEC_DIR}/boot"
        "${FIREBIRD_EXEC_DIR}/boot/fbclient.dll"
        "${FIREBIRD_EXEC_DIR}/boot/plugins/engine13.dll"
    COMMAND ${CMAKE_COMMAND} -E copy_if_different "$<TARGET_FILE:gpre>" "${FIREBIRD_EXEC_DIR}/boot/gpre.exe"
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
        set(GPRE_EXE gpre_boot)
        set(BASE_DIR "boot")
        set(META_FDB "")
    else()
        set(GPRE_EXE "${FIREBIRD_EXEC_DIR}/boot/gpre.exe")
        set(BASE_DIR "master")
        set(META_FDB "${FIREBIRD_GEN_DIR}/dbs/yachts.lnk")
    endif()

    add_custom_command(
        OUTPUT "${FIREBIRD_GEN_DIR}/${BASE_DIR}/${PREP_DIR}/${PREP_FILE}.cpp"
        DEPENDS
            "${FIREBIRD_SOURCE_DIR}/src/${PREP_DIR}/${PREP_FILE}.epp"
            "${FIREBIRD_GEN_DIR}/${BASE_DIR}/${PREP_DIR}"
            "${FIREBIRD_GEN_DIR}/dbs"
            ${GPRE_EXE}
            ${META_FDB}
        COMMAND ${GPRE_EXE}
                ${GPRE_OPT}
                "${FIREBIRD_SOURCE_DIR}/src/${PREP_DIR}/${PREP_FILE}.epp"
                "${FIREBIRD_GEN_DIR}/${BASE_DIR}/${PREP_DIR}/${PREP_FILE}.gen"
                -b "${FIREBIRD_GEN_DIR}/dbs/"
        COMMAND pwsh.exe -ExecutionPolicy Bypass -Command "\
            if (-not (Test-Path -Path ${FIREBIRD_GEN_DIR}/${BASE_DIR}/${PREP_DIR}/${PREP_FILE}.cpp) -or (Compare-Object -ReferenceObject $(Get-Content ${FIREBIRD_GEN_DIR}/${BASE_DIR}/${PREP_DIR}/${PREP_FILE}.gen) -DifferenceObject $(Get-Content ${FIREBIRD_GEN_DIR}/${BASE_DIR}/${PREP_DIR}/${PREP_FILE}.cpp))) { \
                Move-Item -Force -Path ${FIREBIRD_GEN_DIR}/${BASE_DIR}/${PREP_DIR}/${PREP_FILE}.gen -Destination ${FIREBIRD_GEN_DIR}/${BASE_DIR}/${PREP_DIR}/${PREP_FILE}.cpp \
            } else { \
                Remove-Item -Path ${FIREBIRD_GEN_DIR}/${BASE_DIR}/${PREP_DIR}/${PREP_FILE}.gen \
            }"
        COMMENT "Processing ${FIREBIRD_SOURCE_DIR}/src/${PREP_DIR}/${PREP_FILE}.epp"
        VERBATIM
    )
    set_source_files_properties(
        "${FIREBIRD_GEN_DIR}/${BASE_DIR}/${PREP_DIR}/${PREP_FILE}.cpp"
        PROPERTIES GENERATED TRUE
    )
endfunction()
