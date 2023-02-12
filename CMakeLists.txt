
cmake_minimum_required(VERSION 3.24)

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
set(CMAKE_ARCHIVE_OUTPUT_DIRECTORY ${FIREBIRD_OUTPUT_DIR})
set(CMAKE_LIBRARY_OUTPUT_DIRECTORY ${FIREBIRD_OUTPUT_DIR})
set(CMAKE_RUNTIME_OUTPUT_DIRECTORY ${FIREBIRD_OUTPUT_DIR})

if(CMAKE_SIZEOF_VOID_P EQUAL 8)
    # 64 bits
    set(PLATFORM "x64")
    set(RC_ARCH "RC_ARH_x64")
elseif(CMAKE_SIZEOF_VOID_P EQUAL 4)
    # 32 bits
    set(PLATFORM "x86")
    set(RC_ARCH "RC_ARH_x86")
endif()

function(target_set_resource target)
    get_target_property(outname ${target} OUTPUT_NAME)
    set(outname "$<PATH:GET_FILENAME,${outname}>")
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

foreach(DIR IN ITEMS
    ""
    "/alice"
    "/auth"
    "/auth/SecurityDatabase"
    "/burp"
    "/dbs"
    "/dsql"
    "/gpre"
    "/gpre/std"
    "/isql"
    "/jrd"
    "/misc"
    "/msgs"
    "/qli"
    "/examples"
    "/yvalve"
    "/utilities"
    "/utilities/gstat")

    add_custom_command(
        OUTPUT "${FIREBIRD_GEN_DIR}${DIR}"
        COMMAND ${CMAKE_COMMAND} -E make_directory "${FIREBIRD_GEN_DIR}${DIR}"
        COMMENT "Creating directory: ${FIREBIRD_GEN_DIR}${DIR}"
    )
endforeach()

# interfaces
message(STATUS "Building CLOOP and generating interfaces...")
add_executable(cloop)
target_sources(cloop
    PRIVATE
        "${FIREBIRD_SOURCE_DIR}/extern/cloop/src/cloop/Action.cpp"
        "${FIREBIRD_SOURCE_DIR}/extern/cloop/src/cloop/Expr.cpp"
        "${FIREBIRD_SOURCE_DIR}/extern/cloop/src/cloop/Generator.cpp"
        "${FIREBIRD_SOURCE_DIR}/extern/cloop/src/cloop/Lexer.cpp"
        "${FIREBIRD_SOURCE_DIR}/extern/cloop/src/cloop/Main.cpp"
        "${FIREBIRD_SOURCE_DIR}/extern/cloop/src/cloop/Parser.cpp"
)

add_executable(def_awk)
target_sources(def_awk
    PRIVATE "${FIREBIRD_SOURCE_DIR}/src/misc/def_awk.c"
)
add_executable(isc_grep)
target_sources(isc_grep
    PRIVATE "${FIREBIRD_SOURCE_DIR}/src/misc/isc_grep.c"
)

add_custom_command(
    OUTPUT "${FIREBIRD_SOURCE_DIR}/src/include/firebird/IdlFbInterfaces.h"
    DEPENDS
        cloop
        "${FIREBIRD_SOURCE_DIR}/src/include/firebird/FirebirdInterface.idl"
    COMMAND cloop
            "${FIREBIRD_SOURCE_DIR}/src/include/firebird/FirebirdInterface.idl"
            c++
            "${FIREBIRD_SOURCE_DIR}/src/include/firebird/IdlFbInterfaces.h"
            IDL_FB_INTERFACES_H Firebird I
    COMMENT "Updating cloop interfaces..."
)
add_custom_command(
    OUTPUT "${FIREBIRD_GEN_DIR}/misc/func.pas"
    DEPENDS
        "${FIREBIRD_GEN_DIR}"
        "${FIREBIRD_SOURCE_DIR}/src/misc/pascal/fb_get_master_interface.pas"
        "${FIREBIRD_SOURCE_DIR}/src/include/firebird/impl/consts_pub.h"
        "${FIREBIRD_SOURCE_DIR}/lang_helpers/gds_codes.pas"
        def_awk
        isc_grep
    COMMAND ${CMAKE_COMMAND} -E copy_if_different "${FIREBIRD_SOURCE_DIR}/src/misc/pascal/fb_get_master_interface.pas" "${FIREBIRD_GEN_DIR}/misc/func.pas"
    COMMAND def_awk < "${FIREBIRD_SOURCE_DIR}/src/include/firebird/impl/consts_pub.h" >> "${FIREBIRD_GEN_DIR}/misc/func.pas"
    COMMAND isc_grep < "${FIREBIRD_SOURCE_DIR}/lang_helpers/gds_codes.pas" >> "${FIREBIRD_GEN_DIR}/misc/func.pas"
)
add_custom_command(
    OUTPUT "${FIREBIRD_GEN_DIR}/Firebird.pas"
    DEPENDS
        cloop
        "${FIREBIRD_SOURCE_DIR}/src/include/firebird/FirebirdInterface.idl"
        "${FIREBIRD_SOURCE_DIR}/src/misc/pascal/Pascal.interface.pas"
        "${FIREBIRD_SOURCE_DIR}/src/misc/pascal/Pascal.implementation.pas"
        "${FIREBIRD_GEN_DIR}/misc/func.pas"
        "${FIREBIRD_GEN_DIR}"
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
set_source_files_properties(
    "${FIREBIRD_SOURCE_DIR}/src/include/firebird/IdlFbInterfaces.h"
    "${FIREBIRD_GEN_DIR}/misc/func.pas"
    "${FIREBIRD_GEN_DIR}/Firebird.pas"
    PROPERTIES GENERATED TRUE
)
#add_custom_target(UpdateCloopInterfaces ALL
#    DEPENDS
#        "${FIREBIRD_SOURCE_DIR}/src/include/firebird/IdlFbInterfaces.h"
#        "${FIREBIRD_GEN_DIR}/Firebird.pas"
#    SOURCES
#        "${FIREBIRD_SOURCE_DIR}/src/include/firebird/FirebirdInterface.idl"
#)

# btyacc
add_executable(btyacc)
target_sources(btyacc
    PRIVATE
        "${FIREBIRD_SOURCE_DIR}/extern/btyacc/readskel.c"
        "${FIREBIRD_SOURCE_DIR}/extern/btyacc/skel2c"
        "${FIREBIRD_SOURCE_DIR}/extern/btyacc/skeleton.c"
        "${FIREBIRD_SOURCE_DIR}/extern/btyacc/symtab.c"
        "${FIREBIRD_SOURCE_DIR}/extern/btyacc/verbose.c"
        "${FIREBIRD_SOURCE_DIR}/extern/btyacc/warshall.c"
        "${FIREBIRD_SOURCE_DIR}/extern/btyacc/closure.c"
        "${FIREBIRD_SOURCE_DIR}/extern/btyacc/error.c"
        "${FIREBIRD_SOURCE_DIR}/extern/btyacc/lalr.c"
        "${FIREBIRD_SOURCE_DIR}/extern/btyacc/lr0.c"
        "${FIREBIRD_SOURCE_DIR}/extern/btyacc/main.c"
        "${FIREBIRD_SOURCE_DIR}/extern/btyacc/mkpar.c"
        "${FIREBIRD_SOURCE_DIR}/extern/btyacc/mstring.c"
        "${FIREBIRD_SOURCE_DIR}/extern/btyacc/output.c"
        "${FIREBIRD_SOURCE_DIR}/extern/btyacc/reader.c"
)

# libtommath
add_library(libtommath STATIC)
set_target_properties(libtommath PROPERTIES OUTPUT_NAME tommath)
target_include_directories(libtommath
    PUBLIC "${FIREBIRD_SOURCE_DIR}/extern/libtommath"
)
target_sources(libtommath
    PRIVATE
        "${FIREBIRD_SOURCE_DIR}/extern/libtommath/bn_mp_toom_sqr.c"
        "${FIREBIRD_SOURCE_DIR}/extern/libtommath/bn_mp_toradix.c"
        "${FIREBIRD_SOURCE_DIR}/extern/libtommath/bn_mp_toradix_n.c"
        "${FIREBIRD_SOURCE_DIR}/extern/libtommath/bn_mp_unsigned_bin_size.c"
        "${FIREBIRD_SOURCE_DIR}/extern/libtommath/bn_mp_xor.c"
        "${FIREBIRD_SOURCE_DIR}/extern/libtommath/bn_mp_zero.c"
        "${FIREBIRD_SOURCE_DIR}/extern/libtommath/bn_prime_tab.c"
        "${FIREBIRD_SOURCE_DIR}/extern/libtommath/bn_reverse.c"
        "${FIREBIRD_SOURCE_DIR}/extern/libtommath/bn_s_mp_add.c"
        "${FIREBIRD_SOURCE_DIR}/extern/libtommath/bn_s_mp_exptmod.c"
        "${FIREBIRD_SOURCE_DIR}/extern/libtommath/bn_s_mp_mul_digs.c"
        "${FIREBIRD_SOURCE_DIR}/extern/libtommath/bn_s_mp_mul_high_digs.c"
        "${FIREBIRD_SOURCE_DIR}/extern/libtommath/bn_s_mp_sqr.c"
        "${FIREBIRD_SOURCE_DIR}/extern/libtommath/bn_s_mp_sub.c"
        "${FIREBIRD_SOURCE_DIR}/extern/libtommath/bncore.c"
        "${FIREBIRD_SOURCE_DIR}/extern/libtommath/bn_error.c"
        "${FIREBIRD_SOURCE_DIR}/extern/libtommath/bn_fast_mp_invmod.c"
        "${FIREBIRD_SOURCE_DIR}/extern/libtommath/bn_fast_mp_montgomery_reduce.c"
        "${FIREBIRD_SOURCE_DIR}/extern/libtommath/bn_fast_s_mp_mul_digs.c"
        "${FIREBIRD_SOURCE_DIR}/extern/libtommath/bn_fast_s_mp_mul_high_digs.c"
        "${FIREBIRD_SOURCE_DIR}/extern/libtommath/bn_fast_s_mp_sqr.c"
        "${FIREBIRD_SOURCE_DIR}/extern/libtommath/bn_mp_2expt.c"
        "${FIREBIRD_SOURCE_DIR}/extern/libtommath/bn_mp_abs.c"
        "${FIREBIRD_SOURCE_DIR}/extern/libtommath/bn_mp_add.c"
        "${FIREBIRD_SOURCE_DIR}/extern/libtommath/bn_mp_add_d.c"
        "${FIREBIRD_SOURCE_DIR}/extern/libtommath/bn_mp_addmod.c"
        "${FIREBIRD_SOURCE_DIR}/extern/libtommath/bn_mp_and.c"
        "${FIREBIRD_SOURCE_DIR}/extern/libtommath/bn_mp_clamp.c"
        "${FIREBIRD_SOURCE_DIR}/extern/libtommath/bn_mp_clear.c"
        "${FIREBIRD_SOURCE_DIR}/extern/libtommath/bn_mp_clear_multi.c"
        "${FIREBIRD_SOURCE_DIR}/extern/libtommath/bn_mp_cmp.c"
        "${FIREBIRD_SOURCE_DIR}/extern/libtommath/bn_mp_cmp_d.c"
        "${FIREBIRD_SOURCE_DIR}/extern/libtommath/bn_mp_cmp_mag.c"
        "${FIREBIRD_SOURCE_DIR}/extern/libtommath/bn_mp_cnt_lsb.c"
        "${FIREBIRD_SOURCE_DIR}/extern/libtommath/bn_mp_copy.c"
        "${FIREBIRD_SOURCE_DIR}/extern/libtommath/bn_mp_count_bits.c"
        "${FIREBIRD_SOURCE_DIR}/extern/libtommath/bn_mp_div.c"
        "${FIREBIRD_SOURCE_DIR}/extern/libtommath/bn_mp_div_2.c"
        "${FIREBIRD_SOURCE_DIR}/extern/libtommath/bn_mp_div_2d.c"
        "${FIREBIRD_SOURCE_DIR}/extern/libtommath/bn_mp_div_3.c"
        "${FIREBIRD_SOURCE_DIR}/extern/libtommath/bn_mp_div_d.c"
        "${FIREBIRD_SOURCE_DIR}/extern/libtommath/bn_mp_dr_is_modulus.c"
        "${FIREBIRD_SOURCE_DIR}/extern/libtommath/bn_mp_dr_reduce.c"
        "${FIREBIRD_SOURCE_DIR}/extern/libtommath/bn_mp_dr_setup.c"
        "${FIREBIRD_SOURCE_DIR}/extern/libtommath/bn_mp_exch.c"
        "${FIREBIRD_SOURCE_DIR}/extern/libtommath/bn_mp_expt_d.c"
        "${FIREBIRD_SOURCE_DIR}/extern/libtommath/bn_mp_exptmod.c"
        "${FIREBIRD_SOURCE_DIR}/extern/libtommath/bn_mp_exptmod_fast.c"
        "${FIREBIRD_SOURCE_DIR}/extern/libtommath/bn_mp_exteuclid.c"
        "${FIREBIRD_SOURCE_DIR}/extern/libtommath/bn_mp_fread.c"
        "${FIREBIRD_SOURCE_DIR}/extern/libtommath/bn_mp_fwrite.c"
        "${FIREBIRD_SOURCE_DIR}/extern/libtommath/bn_mp_gcd.c"
        "${FIREBIRD_SOURCE_DIR}/extern/libtommath/bn_mp_get_int.c"
        "${FIREBIRD_SOURCE_DIR}/extern/libtommath/bn_mp_grow.c"
        "${FIREBIRD_SOURCE_DIR}/extern/libtommath/bn_mp_init.c"
        "${FIREBIRD_SOURCE_DIR}/extern/libtommath/bn_mp_init_copy.c"
        "${FIREBIRD_SOURCE_DIR}/extern/libtommath/bn_mp_init_multi.c"
        "${FIREBIRD_SOURCE_DIR}/extern/libtommath/bn_mp_init_set.c"
        "${FIREBIRD_SOURCE_DIR}/extern/libtommath/bn_mp_init_set_int.c"
        "${FIREBIRD_SOURCE_DIR}/extern/libtommath/bn_mp_init_size.c"
        "${FIREBIRD_SOURCE_DIR}/extern/libtommath/bn_mp_invmod.c"
        "${FIREBIRD_SOURCE_DIR}/extern/libtommath/bn_mp_invmod_slow.c"
        "${FIREBIRD_SOURCE_DIR}/extern/libtommath/bn_mp_is_square.c"
        "${FIREBIRD_SOURCE_DIR}/extern/libtommath/bn_mp_jacobi.c"
        "${FIREBIRD_SOURCE_DIR}/extern/libtommath/bn_mp_karatsuba_mul.c"
        "${FIREBIRD_SOURCE_DIR}/extern/libtommath/bn_mp_karatsuba_sqr.c"
        "${FIREBIRD_SOURCE_DIR}/extern/libtommath/bn_mp_lcm.c"
        "${FIREBIRD_SOURCE_DIR}/extern/libtommath/bn_mp_lshd.c"
        "${FIREBIRD_SOURCE_DIR}/extern/libtommath/bn_mp_mod.c"
        "${FIREBIRD_SOURCE_DIR}/extern/libtommath/bn_mp_mod_2d.c"
        "${FIREBIRD_SOURCE_DIR}/extern/libtommath/bn_mp_mod_d.c"
        "${FIREBIRD_SOURCE_DIR}/extern/libtommath/bn_mp_montgomery_calc_normalization.c"
        "${FIREBIRD_SOURCE_DIR}/extern/libtommath/bn_mp_montgomery_reduce.c"
        "${FIREBIRD_SOURCE_DIR}/extern/libtommath/bn_mp_montgomery_setup.c"
        "${FIREBIRD_SOURCE_DIR}/extern/libtommath/bn_mp_mul.c"
        "${FIREBIRD_SOURCE_DIR}/extern/libtommath/bn_mp_mul_2.c"
        "${FIREBIRD_SOURCE_DIR}/extern/libtommath/bn_mp_mul_2d.c"
        "${FIREBIRD_SOURCE_DIR}/extern/libtommath/bn_mp_mul_d.c"
        "${FIREBIRD_SOURCE_DIR}/extern/libtommath/bn_mp_mulmod.c"
        "${FIREBIRD_SOURCE_DIR}/extern/libtommath/bn_mp_n_root.c"
        "${FIREBIRD_SOURCE_DIR}/extern/libtommath/bn_mp_neg.c"
        "${FIREBIRD_SOURCE_DIR}/extern/libtommath/bn_mp_or.c"
        "${FIREBIRD_SOURCE_DIR}/extern/libtommath/bn_mp_prime_fermat.c"
        "${FIREBIRD_SOURCE_DIR}/extern/libtommath/bn_mp_prime_is_divisible.c"
        "${FIREBIRD_SOURCE_DIR}/extern/libtommath/bn_mp_prime_is_prime.c"
        "${FIREBIRD_SOURCE_DIR}/extern/libtommath/bn_mp_prime_miller_rabin.c"
        "${FIREBIRD_SOURCE_DIR}/extern/libtommath/bn_mp_prime_next_prime.c"
        "${FIREBIRD_SOURCE_DIR}/extern/libtommath/bn_mp_prime_rabin_miller_trials.c"
        "${FIREBIRD_SOURCE_DIR}/extern/libtommath/bn_mp_prime_random_ex.c"
        "${FIREBIRD_SOURCE_DIR}/extern/libtommath/bn_mp_radix_size.c"
        "${FIREBIRD_SOURCE_DIR}/extern/libtommath/bn_mp_radix_smap.c"
        "${FIREBIRD_SOURCE_DIR}/extern/libtommath/bn_mp_rand.c"
        "${FIREBIRD_SOURCE_DIR}/extern/libtommath/bn_mp_read_radix.c"
        "${FIREBIRD_SOURCE_DIR}/extern/libtommath/bn_mp_read_signed_bin.c"
        "${FIREBIRD_SOURCE_DIR}/extern/libtommath/bn_mp_read_unsigned_bin.c"
        "${FIREBIRD_SOURCE_DIR}/extern/libtommath/bn_mp_reduce.c"
        "${FIREBIRD_SOURCE_DIR}/extern/libtommath/bn_mp_reduce_2k.c"
        "${FIREBIRD_SOURCE_DIR}/extern/libtommath/bn_mp_reduce_2k_l.c"
        "${FIREBIRD_SOURCE_DIR}/extern/libtommath/bn_mp_reduce_2k_setup.c"
        "${FIREBIRD_SOURCE_DIR}/extern/libtommath/bn_mp_reduce_2k_setup_l.c"
        "${FIREBIRD_SOURCE_DIR}/extern/libtommath/bn_mp_reduce_is_2k.c"
        "${FIREBIRD_SOURCE_DIR}/extern/libtommath/bn_mp_reduce_is_2k_l.c"
        "${FIREBIRD_SOURCE_DIR}/extern/libtommath/bn_mp_reduce_setup.c"
        "${FIREBIRD_SOURCE_DIR}/extern/libtommath/bn_mp_rshd.c"
        "${FIREBIRD_SOURCE_DIR}/extern/libtommath/bn_mp_set.c"
        "${FIREBIRD_SOURCE_DIR}/extern/libtommath/bn_mp_set_int.c"
        "${FIREBIRD_SOURCE_DIR}/extern/libtommath/bn_mp_shrink.c"
        "${FIREBIRD_SOURCE_DIR}/extern/libtommath/bn_mp_signed_bin_size.c"
        "${FIREBIRD_SOURCE_DIR}/extern/libtommath/bn_mp_sqr.c"
        "${FIREBIRD_SOURCE_DIR}/extern/libtommath/bn_mp_sqrmod.c"
        "${FIREBIRD_SOURCE_DIR}/extern/libtommath/bn_mp_sqrt.c"
        "${FIREBIRD_SOURCE_DIR}/extern/libtommath/bn_mp_sub.c"
        "${FIREBIRD_SOURCE_DIR}/extern/libtommath/bn_mp_sub_d.c"
        "${FIREBIRD_SOURCE_DIR}/extern/libtommath/bn_mp_submod.c"
        "${FIREBIRD_SOURCE_DIR}/extern/libtommath/bn_mp_to_signed_bin.c"
        "${FIREBIRD_SOURCE_DIR}/extern/libtommath/bn_mp_to_signed_bin_n.c"
        "${FIREBIRD_SOURCE_DIR}/extern/libtommath/bn_mp_to_unsigned_bin.c"
        "${FIREBIRD_SOURCE_DIR}/extern/libtommath/bn_mp_to_unsigned_bin_n.c"
        "${FIREBIRD_SOURCE_DIR}/extern/libtommath/bn_mp_toom_mul.c"
    )

# libtomcrypt
add_library(libtomcrypt STATIC)
set_target_properties(libtomcrypt PROPERTIES OUTPUT_NAME tomcrypt)
target_link_libraries(libtomcrypt 
    PRIVATE libtommath
)
target_compile_definitions(libtomcrypt
    PRIVATE
        LTM_DESC
        LTC_SOURCE
        LTC_NO_TEST
)
target_include_directories(libtomcrypt
    PUBLIC "${FIREBIRD_SOURCE_DIR}/extern/libtomcrypt/src/headers"
)
target_sources(libtomcrypt
    PRIVATE
        "${FIREBIRD_SOURCE_DIR}/extern/libtomcrypt/src/ciphers/aes/aes.c"
        "${FIREBIRD_SOURCE_DIR}/extern/libtomcrypt/src/ciphers/anubis.c"
        "${FIREBIRD_SOURCE_DIR}/extern/libtomcrypt/src/ciphers/blowfish.c"
        "${FIREBIRD_SOURCE_DIR}/extern/libtomcrypt/src/ciphers/camellia.c"
        "${FIREBIRD_SOURCE_DIR}/extern/libtomcrypt/src/ciphers/cast5.c"
        "${FIREBIRD_SOURCE_DIR}/extern/libtomcrypt/src/ciphers/des.c"
        "${FIREBIRD_SOURCE_DIR}/extern/libtomcrypt/src/ciphers/kasumi.c"
        "${FIREBIRD_SOURCE_DIR}/extern/libtomcrypt/src/ciphers/khazad.c"
        "${FIREBIRD_SOURCE_DIR}/extern/libtomcrypt/src/ciphers/kseed.c"
        "${FIREBIRD_SOURCE_DIR}/extern/libtomcrypt/src/ciphers/multi2.c"
        "${FIREBIRD_SOURCE_DIR}/extern/libtomcrypt/src/ciphers/noekeon.c"
        "${FIREBIRD_SOURCE_DIR}/extern/libtomcrypt/src/ciphers/rc2.c"
        "${FIREBIRD_SOURCE_DIR}/extern/libtomcrypt/src/ciphers/rc5.c"
        "${FIREBIRD_SOURCE_DIR}/extern/libtomcrypt/src/ciphers/rc6.c"
        "${FIREBIRD_SOURCE_DIR}/extern/libtomcrypt/src/ciphers/safer/safer.c"
        "${FIREBIRD_SOURCE_DIR}/extern/libtomcrypt/src/ciphers/safer/saferp.c"
        "${FIREBIRD_SOURCE_DIR}/extern/libtomcrypt/src/ciphers/skipjack.c"
        "${FIREBIRD_SOURCE_DIR}/extern/libtomcrypt/src/ciphers/twofish/twofish.c"
        "${FIREBIRD_SOURCE_DIR}/extern/libtomcrypt/src/ciphers/xtea.c"
        "${FIREBIRD_SOURCE_DIR}/extern/libtomcrypt/src/encauth/ccm/ccm_add_aad.c"
        "${FIREBIRD_SOURCE_DIR}/extern/libtomcrypt/src/encauth/ccm/ccm_add_nonce.c"
        "${FIREBIRD_SOURCE_DIR}/extern/libtomcrypt/src/encauth/ccm/ccm_done.c"
        "${FIREBIRD_SOURCE_DIR}/extern/libtomcrypt/src/encauth/ccm/ccm_init.c"
        "${FIREBIRD_SOURCE_DIR}/extern/libtomcrypt/src/encauth/ccm/ccm_memory.c"
        "${FIREBIRD_SOURCE_DIR}/extern/libtomcrypt/src/encauth/ccm/ccm_process.c"
        "${FIREBIRD_SOURCE_DIR}/extern/libtomcrypt/src/encauth/ccm/ccm_reset.c"
        "${FIREBIRD_SOURCE_DIR}/extern/libtomcrypt/src/encauth/ccm/ccm_test.c"
        "${FIREBIRD_SOURCE_DIR}/extern/libtomcrypt/src/encauth/chachapoly/chacha20poly1305_add_aad.c"
        "${FIREBIRD_SOURCE_DIR}/extern/libtomcrypt/src/encauth/chachapoly/chacha20poly1305_decrypt.c"
        "${FIREBIRD_SOURCE_DIR}/extern/libtomcrypt/src/encauth/chachapoly/chacha20poly1305_done.c"
        "${FIREBIRD_SOURCE_DIR}/extern/libtomcrypt/src/encauth/chachapoly/chacha20poly1305_encrypt.c"
        "${FIREBIRD_SOURCE_DIR}/extern/libtomcrypt/src/encauth/chachapoly/chacha20poly1305_init.c"
        "${FIREBIRD_SOURCE_DIR}/extern/libtomcrypt/src/encauth/chachapoly/chacha20poly1305_memory.c"
        "${FIREBIRD_SOURCE_DIR}/extern/libtomcrypt/src/encauth/chachapoly/chacha20poly1305_setiv.c"
        "${FIREBIRD_SOURCE_DIR}/extern/libtomcrypt/src/encauth/chachapoly/chacha20poly1305_setiv_rfc7905.c"
        "${FIREBIRD_SOURCE_DIR}/extern/libtomcrypt/src/encauth/chachapoly/chacha20poly1305_test.c"
        "${FIREBIRD_SOURCE_DIR}/extern/libtomcrypt/src/encauth/eax/eax_addheader.c"
        "${FIREBIRD_SOURCE_DIR}/extern/libtomcrypt/src/encauth/eax/eax_decrypt.c"
        "${FIREBIRD_SOURCE_DIR}/extern/libtomcrypt/src/encauth/eax/eax_decrypt_verify_memory.c"
        "${FIREBIRD_SOURCE_DIR}/extern/libtomcrypt/src/encauth/eax/eax_done.c"
        "${FIREBIRD_SOURCE_DIR}/extern/libtomcrypt/src/encauth/eax/eax_encrypt.c"
        "${FIREBIRD_SOURCE_DIR}/extern/libtomcrypt/src/encauth/eax/eax_encrypt_authenticate_memory.c"
        "${FIREBIRD_SOURCE_DIR}/extern/libtomcrypt/src/encauth/eax/eax_init.c"
        "${FIREBIRD_SOURCE_DIR}/extern/libtomcrypt/src/encauth/eax/eax_test.c"
        "${FIREBIRD_SOURCE_DIR}/extern/libtomcrypt/src/encauth/gcm/gcm_add_aad.c"
        "${FIREBIRD_SOURCE_DIR}/extern/libtomcrypt/src/encauth/gcm/gcm_add_iv.c"
        "${FIREBIRD_SOURCE_DIR}/extern/libtomcrypt/src/encauth/gcm/gcm_done.c"
        "${FIREBIRD_SOURCE_DIR}/extern/libtomcrypt/src/encauth/gcm/gcm_gf_mult.c"
        "${FIREBIRD_SOURCE_DIR}/extern/libtomcrypt/src/encauth/gcm/gcm_init.c"
        "${FIREBIRD_SOURCE_DIR}/extern/libtomcrypt/src/encauth/gcm/gcm_memory.c"
        "${FIREBIRD_SOURCE_DIR}/extern/libtomcrypt/src/encauth/gcm/gcm_mult_h.c"
        "${FIREBIRD_SOURCE_DIR}/extern/libtomcrypt/src/encauth/gcm/gcm_process.c"
        "${FIREBIRD_SOURCE_DIR}/extern/libtomcrypt/src/encauth/gcm/gcm_reset.c"
        "${FIREBIRD_SOURCE_DIR}/extern/libtomcrypt/src/encauth/gcm/gcm_test.c"
        "${FIREBIRD_SOURCE_DIR}/extern/libtomcrypt/src/encauth/ocb3/ocb3_add_aad.c"
        "${FIREBIRD_SOURCE_DIR}/extern/libtomcrypt/src/encauth/ocb3/ocb3_decrypt.c"
        "${FIREBIRD_SOURCE_DIR}/extern/libtomcrypt/src/encauth/ocb3/ocb3_decrypt_last.c"
        "${FIREBIRD_SOURCE_DIR}/extern/libtomcrypt/src/encauth/ocb3/ocb3_decrypt_verify_memory.c"
        "${FIREBIRD_SOURCE_DIR}/extern/libtomcrypt/src/encauth/ocb3/ocb3_done.c"
        "${FIREBIRD_SOURCE_DIR}/extern/libtomcrypt/src/encauth/ocb3/ocb3_encrypt.c"
        "${FIREBIRD_SOURCE_DIR}/extern/libtomcrypt/src/encauth/ocb3/ocb3_encrypt_authenticate_memory.c"
        "${FIREBIRD_SOURCE_DIR}/extern/libtomcrypt/src/encauth/ocb3/ocb3_encrypt_last.c"
        "${FIREBIRD_SOURCE_DIR}/extern/libtomcrypt/src/encauth/ocb3/ocb3_init.c"
        "${FIREBIRD_SOURCE_DIR}/extern/libtomcrypt/src/encauth/ocb3/ocb3_int_ntz.c"
        "${FIREBIRD_SOURCE_DIR}/extern/libtomcrypt/src/encauth/ocb3/ocb3_int_xor_blocks.c"
        "${FIREBIRD_SOURCE_DIR}/extern/libtomcrypt/src/encauth/ocb3/ocb3_test.c"
        "${FIREBIRD_SOURCE_DIR}/extern/libtomcrypt/src/encauth/ocb/ocb_decrypt.c"
        "${FIREBIRD_SOURCE_DIR}/extern/libtomcrypt/src/encauth/ocb/ocb_decrypt_verify_memory.c"
        "${FIREBIRD_SOURCE_DIR}/extern/libtomcrypt/src/encauth/ocb/ocb_done_decrypt.c"
        "${FIREBIRD_SOURCE_DIR}/extern/libtomcrypt/src/encauth/ocb/ocb_done_encrypt.c"
        "${FIREBIRD_SOURCE_DIR}/extern/libtomcrypt/src/encauth/ocb/ocb_encrypt.c"
        "${FIREBIRD_SOURCE_DIR}/extern/libtomcrypt/src/encauth/ocb/ocb_encrypt_authenticate_memory.c"
        "${FIREBIRD_SOURCE_DIR}/extern/libtomcrypt/src/encauth/ocb/ocb_init.c"
        "${FIREBIRD_SOURCE_DIR}/extern/libtomcrypt/src/encauth/ocb/ocb_ntz.c"
        "${FIREBIRD_SOURCE_DIR}/extern/libtomcrypt/src/encauth/ocb/ocb_shift_xor.c"
        "${FIREBIRD_SOURCE_DIR}/extern/libtomcrypt/src/encauth/ocb/ocb_test.c"
        "${FIREBIRD_SOURCE_DIR}/extern/libtomcrypt/src/encauth/ocb/s_ocb_done.c"
        "${FIREBIRD_SOURCE_DIR}/extern/libtomcrypt/src/hashes/blake2b.c"
        "${FIREBIRD_SOURCE_DIR}/extern/libtomcrypt/src/hashes/blake2s.c"
        "${FIREBIRD_SOURCE_DIR}/extern/libtomcrypt/src/hashes/chc/chc.c"
        "${FIREBIRD_SOURCE_DIR}/extern/libtomcrypt/src/hashes/helper/hash_file.c"
        "${FIREBIRD_SOURCE_DIR}/extern/libtomcrypt/src/hashes/helper/hash_filehandle.c"
        "${FIREBIRD_SOURCE_DIR}/extern/libtomcrypt/src/hashes/helper/hash_memory.c"
        "${FIREBIRD_SOURCE_DIR}/extern/libtomcrypt/src/hashes/helper/hash_memory_multi.c"
        "${FIREBIRD_SOURCE_DIR}/extern/libtomcrypt/src/hashes/md2.c"
        "${FIREBIRD_SOURCE_DIR}/extern/libtomcrypt/src/hashes/md4.c"
        "${FIREBIRD_SOURCE_DIR}/extern/libtomcrypt/src/hashes/md5.c"
        "${FIREBIRD_SOURCE_DIR}/extern/libtomcrypt/src/hashes/rmd128.c"
        "${FIREBIRD_SOURCE_DIR}/extern/libtomcrypt/src/hashes/rmd160.c"
        "${FIREBIRD_SOURCE_DIR}/extern/libtomcrypt/src/hashes/rmd256.c"
        "${FIREBIRD_SOURCE_DIR}/extern/libtomcrypt/src/hashes/rmd320.c"
        "${FIREBIRD_SOURCE_DIR}/extern/libtomcrypt/src/hashes/sha1.c"
        "${FIREBIRD_SOURCE_DIR}/extern/libtomcrypt/src/hashes/sha2/sha224.c"
        "${FIREBIRD_SOURCE_DIR}/extern/libtomcrypt/src/hashes/sha2/sha256.c"
        "${FIREBIRD_SOURCE_DIR}/extern/libtomcrypt/src/hashes/sha2/sha384.c"
        "${FIREBIRD_SOURCE_DIR}/extern/libtomcrypt/src/hashes/sha2/sha512.c"
        "${FIREBIRD_SOURCE_DIR}/extern/libtomcrypt/src/hashes/sha2/sha512_224.c"
        "${FIREBIRD_SOURCE_DIR}/extern/libtomcrypt/src/hashes/sha2/sha512_256.c"
        "${FIREBIRD_SOURCE_DIR}/extern/libtomcrypt/src/hashes/sha3.c"
        "${FIREBIRD_SOURCE_DIR}/extern/libtomcrypt/src/hashes/sha3_test.c"
        "${FIREBIRD_SOURCE_DIR}/extern/libtomcrypt/src/hashes/tiger.c"
        "${FIREBIRD_SOURCE_DIR}/extern/libtomcrypt/src/hashes/whirl/whirl.c"
        "${FIREBIRD_SOURCE_DIR}/extern/libtomcrypt/src/mac/blake2/blake2bmac.c"
        "${FIREBIRD_SOURCE_DIR}/extern/libtomcrypt/src/mac/blake2/blake2bmac_file.c"
        "${FIREBIRD_SOURCE_DIR}/extern/libtomcrypt/src/mac/blake2/blake2bmac_memory.c"
        "${FIREBIRD_SOURCE_DIR}/extern/libtomcrypt/src/mac/blake2/blake2bmac_memory_multi.c"
        "${FIREBIRD_SOURCE_DIR}/extern/libtomcrypt/src/mac/blake2/blake2bmac_test.c"
        "${FIREBIRD_SOURCE_DIR}/extern/libtomcrypt/src/mac/blake2/blake2smac.c"
        "${FIREBIRD_SOURCE_DIR}/extern/libtomcrypt/src/mac/blake2/blake2smac_file.c"
        "${FIREBIRD_SOURCE_DIR}/extern/libtomcrypt/src/mac/blake2/blake2smac_memory.c"
        "${FIREBIRD_SOURCE_DIR}/extern/libtomcrypt/src/mac/blake2/blake2smac_memory_multi.c"
        "${FIREBIRD_SOURCE_DIR}/extern/libtomcrypt/src/mac/blake2/blake2smac_test.c"
        "${FIREBIRD_SOURCE_DIR}/extern/libtomcrypt/src/mac/f9/f9_done.c"
        "${FIREBIRD_SOURCE_DIR}/extern/libtomcrypt/src/mac/f9/f9_file.c"
        "${FIREBIRD_SOURCE_DIR}/extern/libtomcrypt/src/mac/f9/f9_init.c"
        "${FIREBIRD_SOURCE_DIR}/extern/libtomcrypt/src/mac/f9/f9_memory.c"
        "${FIREBIRD_SOURCE_DIR}/extern/libtomcrypt/src/mac/f9/f9_memory_multi.c"
        "${FIREBIRD_SOURCE_DIR}/extern/libtomcrypt/src/mac/f9/f9_process.c"
        "${FIREBIRD_SOURCE_DIR}/extern/libtomcrypt/src/mac/f9/f9_test.c"
        "${FIREBIRD_SOURCE_DIR}/extern/libtomcrypt/src/mac/hmac/hmac_done.c"
        "${FIREBIRD_SOURCE_DIR}/extern/libtomcrypt/src/mac/hmac/hmac_file.c"
        "${FIREBIRD_SOURCE_DIR}/extern/libtomcrypt/src/mac/hmac/hmac_init.c"
        "${FIREBIRD_SOURCE_DIR}/extern/libtomcrypt/src/mac/hmac/hmac_memory.c"
        "${FIREBIRD_SOURCE_DIR}/extern/libtomcrypt/src/mac/hmac/hmac_memory_multi.c"
        "${FIREBIRD_SOURCE_DIR}/extern/libtomcrypt/src/mac/hmac/hmac_process.c"
        "${FIREBIRD_SOURCE_DIR}/extern/libtomcrypt/src/mac/hmac/hmac_test.c"
        "${FIREBIRD_SOURCE_DIR}/extern/libtomcrypt/src/mac/omac/omac_done.c"
        "${FIREBIRD_SOURCE_DIR}/extern/libtomcrypt/src/mac/omac/omac_file.c"
        "${FIREBIRD_SOURCE_DIR}/extern/libtomcrypt/src/mac/omac/omac_init.c"
        "${FIREBIRD_SOURCE_DIR}/extern/libtomcrypt/src/mac/omac/omac_memory.c"
        "${FIREBIRD_SOURCE_DIR}/extern/libtomcrypt/src/mac/omac/omac_memory_multi.c"
        "${FIREBIRD_SOURCE_DIR}/extern/libtomcrypt/src/mac/omac/omac_process.c"
        "${FIREBIRD_SOURCE_DIR}/extern/libtomcrypt/src/mac/omac/omac_test.c"
        "${FIREBIRD_SOURCE_DIR}/extern/libtomcrypt/src/mac/pelican/pelican.c"
        "${FIREBIRD_SOURCE_DIR}/extern/libtomcrypt/src/mac/pelican/pelican_memory.c"
        "${FIREBIRD_SOURCE_DIR}/extern/libtomcrypt/src/mac/pelican/pelican_test.c"
        "${FIREBIRD_SOURCE_DIR}/extern/libtomcrypt/src/mac/pmac/pmac_done.c"
        "${FIREBIRD_SOURCE_DIR}/extern/libtomcrypt/src/mac/pmac/pmac_file.c"
        "${FIREBIRD_SOURCE_DIR}/extern/libtomcrypt/src/mac/pmac/pmac_init.c"
        "${FIREBIRD_SOURCE_DIR}/extern/libtomcrypt/src/mac/pmac/pmac_memory.c"
        "${FIREBIRD_SOURCE_DIR}/extern/libtomcrypt/src/mac/pmac/pmac_memory_multi.c"
        "${FIREBIRD_SOURCE_DIR}/extern/libtomcrypt/src/mac/pmac/pmac_ntz.c"
        "${FIREBIRD_SOURCE_DIR}/extern/libtomcrypt/src/mac/pmac/pmac_process.c"
        "${FIREBIRD_SOURCE_DIR}/extern/libtomcrypt/src/mac/pmac/pmac_shift_xor.c"
        "${FIREBIRD_SOURCE_DIR}/extern/libtomcrypt/src/mac/pmac/pmac_test.c"
        "${FIREBIRD_SOURCE_DIR}/extern/libtomcrypt/src/mac/poly1305/poly1305.c"
        "${FIREBIRD_SOURCE_DIR}/extern/libtomcrypt/src/mac/poly1305/poly1305_file.c"
        "${FIREBIRD_SOURCE_DIR}/extern/libtomcrypt/src/mac/poly1305/poly1305_memory.c"
        "${FIREBIRD_SOURCE_DIR}/extern/libtomcrypt/src/mac/poly1305/poly1305_memory_multi.c"
        "${FIREBIRD_SOURCE_DIR}/extern/libtomcrypt/src/mac/poly1305/poly1305_test.c"
        "${FIREBIRD_SOURCE_DIR}/extern/libtomcrypt/src/mac/xcbc/xcbc_done.c"
        "${FIREBIRD_SOURCE_DIR}/extern/libtomcrypt/src/mac/xcbc/xcbc_file.c"
        "${FIREBIRD_SOURCE_DIR}/extern/libtomcrypt/src/mac/xcbc/xcbc_init.c"
        "${FIREBIRD_SOURCE_DIR}/extern/libtomcrypt/src/mac/xcbc/xcbc_memory.c"
        "${FIREBIRD_SOURCE_DIR}/extern/libtomcrypt/src/mac/xcbc/xcbc_memory_multi.c"
        "${FIREBIRD_SOURCE_DIR}/extern/libtomcrypt/src/mac/xcbc/xcbc_process.c"
        "${FIREBIRD_SOURCE_DIR}/extern/libtomcrypt/src/mac/xcbc/xcbc_test.c"
        "${FIREBIRD_SOURCE_DIR}/extern/libtomcrypt/src/math/fp/ltc_ecc_fp_mulmod.c"
        "${FIREBIRD_SOURCE_DIR}/extern/libtomcrypt/src/math/gmp_desc.c"
        "${FIREBIRD_SOURCE_DIR}/extern/libtomcrypt/src/math/ltm_desc.c"
        "${FIREBIRD_SOURCE_DIR}/extern/libtomcrypt/src/math/multi.c"
        "${FIREBIRD_SOURCE_DIR}/extern/libtomcrypt/src/math/radix_to_bin.c"
        "${FIREBIRD_SOURCE_DIR}/extern/libtomcrypt/src/math/rand_bn.c"
        "${FIREBIRD_SOURCE_DIR}/extern/libtomcrypt/src/math/rand_prime.c"
        "${FIREBIRD_SOURCE_DIR}/extern/libtomcrypt/src/math/tfm_desc.c"
        "${FIREBIRD_SOURCE_DIR}/extern/libtomcrypt/src/misc/adler32.c"
        "${FIREBIRD_SOURCE_DIR}/extern/libtomcrypt/src/misc/base64/base64_decode.c"
        "${FIREBIRD_SOURCE_DIR}/extern/libtomcrypt/src/misc/base64/base64_encode.c"
        "${FIREBIRD_SOURCE_DIR}/extern/libtomcrypt/src/misc/burn_stack.c"
        "${FIREBIRD_SOURCE_DIR}/extern/libtomcrypt/src/misc/compare_testvector.c"
        "${FIREBIRD_SOURCE_DIR}/extern/libtomcrypt/src/misc/crc32.c"
        "${FIREBIRD_SOURCE_DIR}/extern/libtomcrypt/src/misc/crypt/crypt.c"
        "${FIREBIRD_SOURCE_DIR}/extern/libtomcrypt/src/misc/crypt/crypt_argchk.c"
        "${FIREBIRD_SOURCE_DIR}/extern/libtomcrypt/src/misc/crypt/crypt_cipher_descriptor.c"
        "${FIREBIRD_SOURCE_DIR}/extern/libtomcrypt/src/misc/crypt/crypt_cipher_is_valid.c"
        "${FIREBIRD_SOURCE_DIR}/extern/libtomcrypt/src/misc/crypt/crypt_constants.c"
        "${FIREBIRD_SOURCE_DIR}/extern/libtomcrypt/src/misc/crypt/crypt_find_cipher.c"
        "${FIREBIRD_SOURCE_DIR}/extern/libtomcrypt/src/misc/crypt/crypt_find_cipher_any.c"
        "${FIREBIRD_SOURCE_DIR}/extern/libtomcrypt/src/misc/crypt/crypt_find_cipher_id.c"
        "${FIREBIRD_SOURCE_DIR}/extern/libtomcrypt/src/misc/crypt/crypt_find_hash.c"
        "${FIREBIRD_SOURCE_DIR}/extern/libtomcrypt/src/misc/crypt/crypt_find_hash_any.c"
        "${FIREBIRD_SOURCE_DIR}/extern/libtomcrypt/src/misc/crypt/crypt_find_hash_id.c"
        "${FIREBIRD_SOURCE_DIR}/extern/libtomcrypt/src/misc/crypt/crypt_find_hash_oid.c"
        "${FIREBIRD_SOURCE_DIR}/extern/libtomcrypt/src/misc/crypt/crypt_find_prng.c"
        "${FIREBIRD_SOURCE_DIR}/extern/libtomcrypt/src/misc/crypt/crypt_fsa.c"
        "${FIREBIRD_SOURCE_DIR}/extern/libtomcrypt/src/misc/crypt/crypt_hash_descriptor.c"
        "${FIREBIRD_SOURCE_DIR}/extern/libtomcrypt/src/misc/crypt/crypt_hash_is_valid.c"
        "${FIREBIRD_SOURCE_DIR}/extern/libtomcrypt/src/misc/crypt/crypt_inits.c"
        "${FIREBIRD_SOURCE_DIR}/extern/libtomcrypt/src/misc/crypt/crypt_ltc_mp_descriptor.c"
        "${FIREBIRD_SOURCE_DIR}/extern/libtomcrypt/src/misc/crypt/crypt_prng_descriptor.c"
        "${FIREBIRD_SOURCE_DIR}/extern/libtomcrypt/src/misc/crypt/crypt_prng_is_valid.c"
        "${FIREBIRD_SOURCE_DIR}/extern/libtomcrypt/src/misc/crypt/crypt_prng_rng_descriptor.c"
        "${FIREBIRD_SOURCE_DIR}/extern/libtomcrypt/src/misc/crypt/crypt_register_all_ciphers.c"
        "${FIREBIRD_SOURCE_DIR}/extern/libtomcrypt/src/misc/crypt/crypt_register_all_hashes.c"
        "${FIREBIRD_SOURCE_DIR}/extern/libtomcrypt/src/misc/crypt/crypt_register_all_prngs.c"
        "${FIREBIRD_SOURCE_DIR}/extern/libtomcrypt/src/misc/crypt/crypt_register_cipher.c"
        "${FIREBIRD_SOURCE_DIR}/extern/libtomcrypt/src/misc/crypt/crypt_register_hash.c"
        "${FIREBIRD_SOURCE_DIR}/extern/libtomcrypt/src/misc/crypt/crypt_register_prng.c"
        "${FIREBIRD_SOURCE_DIR}/extern/libtomcrypt/src/misc/crypt/crypt_sizes.c"
        "${FIREBIRD_SOURCE_DIR}/extern/libtomcrypt/src/misc/crypt/crypt_unregister_cipher.c"
        "${FIREBIRD_SOURCE_DIR}/extern/libtomcrypt/src/misc/crypt/crypt_unregister_hash.c"
        "${FIREBIRD_SOURCE_DIR}/extern/libtomcrypt/src/misc/crypt/crypt_unregister_prng.c"
        "${FIREBIRD_SOURCE_DIR}/extern/libtomcrypt/src/misc/error_to_string.c"
        "${FIREBIRD_SOURCE_DIR}/extern/libtomcrypt/src/misc/hkdf/hkdf.c"
        "${FIREBIRD_SOURCE_DIR}/extern/libtomcrypt/src/misc/hkdf/hkdf_test.c"
        "${FIREBIRD_SOURCE_DIR}/extern/libtomcrypt/src/misc/mem_neq.c"
        "${FIREBIRD_SOURCE_DIR}/extern/libtomcrypt/src/misc/pkcs5/pkcs_5_1.c"
        "${FIREBIRD_SOURCE_DIR}/extern/libtomcrypt/src/misc/pkcs5/pkcs_5_2.c"
        "${FIREBIRD_SOURCE_DIR}/extern/libtomcrypt/src/misc/pkcs5/pkcs_5_test.c"
        "${FIREBIRD_SOURCE_DIR}/extern/libtomcrypt/src/misc/pk_get_oid.c"
        "${FIREBIRD_SOURCE_DIR}/extern/libtomcrypt/src/misc/zeromem.c"
        "${FIREBIRD_SOURCE_DIR}/extern/libtomcrypt/src/modes/cbc/cbc_decrypt.c"
        "${FIREBIRD_SOURCE_DIR}/extern/libtomcrypt/src/modes/cbc/cbc_done.c"
        "${FIREBIRD_SOURCE_DIR}/extern/libtomcrypt/src/modes/cbc/cbc_encrypt.c"
        "${FIREBIRD_SOURCE_DIR}/extern/libtomcrypt/src/modes/cbc/cbc_getiv.c"
        "${FIREBIRD_SOURCE_DIR}/extern/libtomcrypt/src/modes/cbc/cbc_setiv.c"
        "${FIREBIRD_SOURCE_DIR}/extern/libtomcrypt/src/modes/cbc/cbc_start.c"
        "${FIREBIRD_SOURCE_DIR}/extern/libtomcrypt/src/modes/cfb/cfb_decrypt.c"
        "${FIREBIRD_SOURCE_DIR}/extern/libtomcrypt/src/modes/cfb/cfb_done.c"
        "${FIREBIRD_SOURCE_DIR}/extern/libtomcrypt/src/modes/cfb/cfb_encrypt.c"
        "${FIREBIRD_SOURCE_DIR}/extern/libtomcrypt/src/modes/cfb/cfb_getiv.c"
        "${FIREBIRD_SOURCE_DIR}/extern/libtomcrypt/src/modes/cfb/cfb_setiv.c"
        "${FIREBIRD_SOURCE_DIR}/extern/libtomcrypt/src/modes/cfb/cfb_start.c"
        "${FIREBIRD_SOURCE_DIR}/extern/libtomcrypt/src/modes/ctr/ctr_decrypt.c"
        "${FIREBIRD_SOURCE_DIR}/extern/libtomcrypt/src/modes/ctr/ctr_done.c"
        "${FIREBIRD_SOURCE_DIR}/extern/libtomcrypt/src/modes/ctr/ctr_encrypt.c"
        "${FIREBIRD_SOURCE_DIR}/extern/libtomcrypt/src/modes/ctr/ctr_getiv.c"
        "${FIREBIRD_SOURCE_DIR}/extern/libtomcrypt/src/modes/ctr/ctr_setiv.c"
        "${FIREBIRD_SOURCE_DIR}/extern/libtomcrypt/src/modes/ctr/ctr_start.c"
        "${FIREBIRD_SOURCE_DIR}/extern/libtomcrypt/src/modes/ctr/ctr_test.c"
        "${FIREBIRD_SOURCE_DIR}/extern/libtomcrypt/src/modes/ecb/ecb_decrypt.c"
        "${FIREBIRD_SOURCE_DIR}/extern/libtomcrypt/src/modes/ecb/ecb_done.c"
        "${FIREBIRD_SOURCE_DIR}/extern/libtomcrypt/src/modes/ecb/ecb_encrypt.c"
        "${FIREBIRD_SOURCE_DIR}/extern/libtomcrypt/src/modes/ecb/ecb_start.c"
        "${FIREBIRD_SOURCE_DIR}/extern/libtomcrypt/src/modes/f8/f8_decrypt.c"
        "${FIREBIRD_SOURCE_DIR}/extern/libtomcrypt/src/modes/f8/f8_done.c"
        "${FIREBIRD_SOURCE_DIR}/extern/libtomcrypt/src/modes/f8/f8_encrypt.c"
        "${FIREBIRD_SOURCE_DIR}/extern/libtomcrypt/src/modes/f8/f8_getiv.c"
        "${FIREBIRD_SOURCE_DIR}/extern/libtomcrypt/src/modes/f8/f8_setiv.c"
        "${FIREBIRD_SOURCE_DIR}/extern/libtomcrypt/src/modes/f8/f8_start.c"
        "${FIREBIRD_SOURCE_DIR}/extern/libtomcrypt/src/modes/f8/f8_test_mode.c"
        "${FIREBIRD_SOURCE_DIR}/extern/libtomcrypt/src/modes/lrw/lrw_decrypt.c"
        "${FIREBIRD_SOURCE_DIR}/extern/libtomcrypt/src/modes/lrw/lrw_done.c"
        "${FIREBIRD_SOURCE_DIR}/extern/libtomcrypt/src/modes/lrw/lrw_encrypt.c"
        "${FIREBIRD_SOURCE_DIR}/extern/libtomcrypt/src/modes/lrw/lrw_getiv.c"
        "${FIREBIRD_SOURCE_DIR}/extern/libtomcrypt/src/modes/lrw/lrw_process.c"
        "${FIREBIRD_SOURCE_DIR}/extern/libtomcrypt/src/modes/lrw/lrw_setiv.c"
        "${FIREBIRD_SOURCE_DIR}/extern/libtomcrypt/src/modes/lrw/lrw_start.c"
        "${FIREBIRD_SOURCE_DIR}/extern/libtomcrypt/src/modes/lrw/lrw_test.c"
        "${FIREBIRD_SOURCE_DIR}/extern/libtomcrypt/src/modes/ofb/ofb_decrypt.c"
        "${FIREBIRD_SOURCE_DIR}/extern/libtomcrypt/src/modes/ofb/ofb_done.c"
        "${FIREBIRD_SOURCE_DIR}/extern/libtomcrypt/src/modes/ofb/ofb_encrypt.c"
        "${FIREBIRD_SOURCE_DIR}/extern/libtomcrypt/src/modes/ofb/ofb_getiv.c"
        "${FIREBIRD_SOURCE_DIR}/extern/libtomcrypt/src/modes/ofb/ofb_setiv.c"
        "${FIREBIRD_SOURCE_DIR}/extern/libtomcrypt/src/modes/ofb/ofb_start.c"
        "${FIREBIRD_SOURCE_DIR}/extern/libtomcrypt/src/modes/xts/xts_decrypt.c"
        "${FIREBIRD_SOURCE_DIR}/extern/libtomcrypt/src/modes/xts/xts_done.c"
        "${FIREBIRD_SOURCE_DIR}/extern/libtomcrypt/src/modes/xts/xts_encrypt.c"
        "${FIREBIRD_SOURCE_DIR}/extern/libtomcrypt/src/modes/xts/xts_init.c"
        "${FIREBIRD_SOURCE_DIR}/extern/libtomcrypt/src/modes/xts/xts_mult_x.c"
        "${FIREBIRD_SOURCE_DIR}/extern/libtomcrypt/src/modes/xts/xts_test.c"
        "${FIREBIRD_SOURCE_DIR}/extern/libtomcrypt/src/pk/asn1/der/bit/der_decode_bit_string.c"
        "${FIREBIRD_SOURCE_DIR}/extern/libtomcrypt/src/pk/asn1/der/bit/der_decode_raw_bit_string.c"
        "${FIREBIRD_SOURCE_DIR}/extern/libtomcrypt/src/pk/asn1/der/bit/der_encode_bit_string.c"
        "${FIREBIRD_SOURCE_DIR}/extern/libtomcrypt/src/pk/asn1/der/bit/der_encode_raw_bit_string.c"
        "${FIREBIRD_SOURCE_DIR}/extern/libtomcrypt/src/pk/asn1/der/bit/der_length_bit_string.c"
        "${FIREBIRD_SOURCE_DIR}/extern/libtomcrypt/src/pk/asn1/der/boolean/der_decode_boolean.c"
        "${FIREBIRD_SOURCE_DIR}/extern/libtomcrypt/src/pk/asn1/der/boolean/der_encode_boolean.c"
        "${FIREBIRD_SOURCE_DIR}/extern/libtomcrypt/src/pk/asn1/der/boolean/der_length_boolean.c"
        "${FIREBIRD_SOURCE_DIR}/extern/libtomcrypt/src/pk/asn1/der/choice/der_decode_choice.c"
        "${FIREBIRD_SOURCE_DIR}/extern/libtomcrypt/src/pk/asn1/der/generalizedtime/der_decode_generalizedtime.c"
        "${FIREBIRD_SOURCE_DIR}/extern/libtomcrypt/src/pk/asn1/der/generalizedtime/der_encode_generalizedtime.c"
        "${FIREBIRD_SOURCE_DIR}/extern/libtomcrypt/src/pk/asn1/der/generalizedtime/der_length_generalizedtime.c"
        "${FIREBIRD_SOURCE_DIR}/extern/libtomcrypt/src/pk/asn1/der/ia5/der_decode_ia5_string.c"
        "${FIREBIRD_SOURCE_DIR}/extern/libtomcrypt/src/pk/asn1/der/ia5/der_encode_ia5_string.c"
        "${FIREBIRD_SOURCE_DIR}/extern/libtomcrypt/src/pk/asn1/der/ia5/der_length_ia5_string.c"
        "${FIREBIRD_SOURCE_DIR}/extern/libtomcrypt/src/pk/asn1/der/integer/der_decode_integer.c"
        "${FIREBIRD_SOURCE_DIR}/extern/libtomcrypt/src/pk/asn1/der/integer/der_encode_integer.c"
        "${FIREBIRD_SOURCE_DIR}/extern/libtomcrypt/src/pk/asn1/der/integer/der_length_integer.c"
        "${FIREBIRD_SOURCE_DIR}/extern/libtomcrypt/src/pk/asn1/der/object_identifier/der_decode_object_identifier.c"
        "${FIREBIRD_SOURCE_DIR}/extern/libtomcrypt/src/pk/asn1/der/object_identifier/der_encode_object_identifier.c"
        "${FIREBIRD_SOURCE_DIR}/extern/libtomcrypt/src/pk/asn1/der/object_identifier/der_length_object_identifier.c"
        "${FIREBIRD_SOURCE_DIR}/extern/libtomcrypt/src/pk/asn1/der/octet/der_decode_octet_string.c"
        "${FIREBIRD_SOURCE_DIR}/extern/libtomcrypt/src/pk/asn1/der/octet/der_encode_octet_string.c"
        "${FIREBIRD_SOURCE_DIR}/extern/libtomcrypt/src/pk/asn1/der/octet/der_length_octet_string.c"
        "${FIREBIRD_SOURCE_DIR}/extern/libtomcrypt/src/pk/asn1/der/printable_string/der_decode_printable_string.c"
        "${FIREBIRD_SOURCE_DIR}/extern/libtomcrypt/src/pk/asn1/der/printable_string/der_encode_printable_string.c"
        "${FIREBIRD_SOURCE_DIR}/extern/libtomcrypt/src/pk/asn1/der/printable_string/der_length_printable_string.c"
        "${FIREBIRD_SOURCE_DIR}/extern/libtomcrypt/src/pk/asn1/der/sequence/der_decode_sequence_ex.c"
        "${FIREBIRD_SOURCE_DIR}/extern/libtomcrypt/src/pk/asn1/der/sequence/der_decode_sequence_flexi.c"
        "${FIREBIRD_SOURCE_DIR}/extern/libtomcrypt/src/pk/asn1/der/sequence/der_decode_sequence_multi.c"
        "${FIREBIRD_SOURCE_DIR}/extern/libtomcrypt/src/pk/asn1/der/sequence/der_decode_subject_public_key_info.c"
        "${FIREBIRD_SOURCE_DIR}/extern/libtomcrypt/src/pk/asn1/der/sequence/der_encode_sequence_ex.c"
        "${FIREBIRD_SOURCE_DIR}/extern/libtomcrypt/src/pk/asn1/der/sequence/der_encode_sequence_multi.c"
        "${FIREBIRD_SOURCE_DIR}/extern/libtomcrypt/src/pk/asn1/der/sequence/der_encode_subject_public_key_info.c"
        "${FIREBIRD_SOURCE_DIR}/extern/libtomcrypt/src/pk/asn1/der/sequence/der_length_sequence.c"
        "${FIREBIRD_SOURCE_DIR}/extern/libtomcrypt/src/pk/asn1/der/sequence/der_sequence_free.c"
        "${FIREBIRD_SOURCE_DIR}/extern/libtomcrypt/src/pk/asn1/der/sequence/der_sequence_shrink.c"
        "${FIREBIRD_SOURCE_DIR}/extern/libtomcrypt/src/pk/asn1/der/set/der_encode_set.c"
        "${FIREBIRD_SOURCE_DIR}/extern/libtomcrypt/src/pk/asn1/der/set/der_encode_setof.c"
        "${FIREBIRD_SOURCE_DIR}/extern/libtomcrypt/src/pk/asn1/der/short_integer/der_decode_short_integer.c"
        "${FIREBIRD_SOURCE_DIR}/extern/libtomcrypt/src/pk/asn1/der/short_integer/der_encode_short_integer.c"
        "${FIREBIRD_SOURCE_DIR}/extern/libtomcrypt/src/pk/asn1/der/short_integer/der_length_short_integer.c"
        "${FIREBIRD_SOURCE_DIR}/extern/libtomcrypt/src/pk/asn1/der/teletex_string/der_decode_teletex_string.c"
        "${FIREBIRD_SOURCE_DIR}/extern/libtomcrypt/src/pk/asn1/der/teletex_string/der_length_teletex_string.c"
        "${FIREBIRD_SOURCE_DIR}/extern/libtomcrypt/src/pk/asn1/der/utctime/der_decode_utctime.c"
        "${FIREBIRD_SOURCE_DIR}/extern/libtomcrypt/src/pk/asn1/der/utctime/der_encode_utctime.c"
        "${FIREBIRD_SOURCE_DIR}/extern/libtomcrypt/src/pk/asn1/der/utctime/der_length_utctime.c"
        "${FIREBIRD_SOURCE_DIR}/extern/libtomcrypt/src/pk/asn1/der/utf8/der_decode_utf8_string.c"
        "${FIREBIRD_SOURCE_DIR}/extern/libtomcrypt/src/pk/asn1/der/utf8/der_encode_utf8_string.c"
        "${FIREBIRD_SOURCE_DIR}/extern/libtomcrypt/src/pk/asn1/der/utf8/der_length_utf8_string.c"
        "${FIREBIRD_SOURCE_DIR}/extern/libtomcrypt/src/pk/dh/dh.c"
        "${FIREBIRD_SOURCE_DIR}/extern/libtomcrypt/src/pk/dh/dh_check_pubkey.c"
        "${FIREBIRD_SOURCE_DIR}/extern/libtomcrypt/src/pk/dh/dh_export.c"
        "${FIREBIRD_SOURCE_DIR}/extern/libtomcrypt/src/pk/dh/dh_export_key.c"
        "${FIREBIRD_SOURCE_DIR}/extern/libtomcrypt/src/pk/dh/dh_free.c"
        "${FIREBIRD_SOURCE_DIR}/extern/libtomcrypt/src/pk/dh/dh_generate_key.c"
        "${FIREBIRD_SOURCE_DIR}/extern/libtomcrypt/src/pk/dh/dh_import.c"
        "${FIREBIRD_SOURCE_DIR}/extern/libtomcrypt/src/pk/dh/dh_set.c"
        "${FIREBIRD_SOURCE_DIR}/extern/libtomcrypt/src/pk/dh/dh_set_pg_dhparam.c"
        "${FIREBIRD_SOURCE_DIR}/extern/libtomcrypt/src/pk/dh/dh_shared_secret.c"
        "${FIREBIRD_SOURCE_DIR}/extern/libtomcrypt/src/pk/dsa/dsa_decrypt_key.c"
        "${FIREBIRD_SOURCE_DIR}/extern/libtomcrypt/src/pk/dsa/dsa_encrypt_key.c"
        "${FIREBIRD_SOURCE_DIR}/extern/libtomcrypt/src/pk/dsa/dsa_export.c"
        "${FIREBIRD_SOURCE_DIR}/extern/libtomcrypt/src/pk/dsa/dsa_free.c"
        "${FIREBIRD_SOURCE_DIR}/extern/libtomcrypt/src/pk/dsa/dsa_generate_key.c"
        "${FIREBIRD_SOURCE_DIR}/extern/libtomcrypt/src/pk/dsa/dsa_generate_pqg.c"
        "${FIREBIRD_SOURCE_DIR}/extern/libtomcrypt/src/pk/dsa/dsa_import.c"
        "${FIREBIRD_SOURCE_DIR}/extern/libtomcrypt/src/pk/dsa/dsa_make_key.c"
        "${FIREBIRD_SOURCE_DIR}/extern/libtomcrypt/src/pk/dsa/dsa_set.c"
        "${FIREBIRD_SOURCE_DIR}/extern/libtomcrypt/src/pk/dsa/dsa_set_pqg_dsaparam.c"
        "${FIREBIRD_SOURCE_DIR}/extern/libtomcrypt/src/pk/dsa/dsa_shared_secret.c"
        "${FIREBIRD_SOURCE_DIR}/extern/libtomcrypt/src/pk/dsa/dsa_sign_hash.c"
        "${FIREBIRD_SOURCE_DIR}/extern/libtomcrypt/src/pk/dsa/dsa_verify_hash.c"
        "${FIREBIRD_SOURCE_DIR}/extern/libtomcrypt/src/pk/dsa/dsa_verify_key.c"
        "${FIREBIRD_SOURCE_DIR}/extern/libtomcrypt/src/pk/ecc/ecc.c"
        "${FIREBIRD_SOURCE_DIR}/extern/libtomcrypt/src/pk/ecc/ecc_ansi_x963_export.c"
        "${FIREBIRD_SOURCE_DIR}/extern/libtomcrypt/src/pk/ecc/ecc_ansi_x963_import.c"
        "${FIREBIRD_SOURCE_DIR}/extern/libtomcrypt/src/pk/ecc/ecc_decrypt_key.c"
        "${FIREBIRD_SOURCE_DIR}/extern/libtomcrypt/src/pk/ecc/ecc_encrypt_key.c"
        "${FIREBIRD_SOURCE_DIR}/extern/libtomcrypt/src/pk/ecc/ecc_export.c"
        "${FIREBIRD_SOURCE_DIR}/extern/libtomcrypt/src/pk/ecc/ecc_free.c"
        "${FIREBIRD_SOURCE_DIR}/extern/libtomcrypt/src/pk/ecc/ecc_get_size.c"
        "${FIREBIRD_SOURCE_DIR}/extern/libtomcrypt/src/pk/ecc/ecc_import.c"
        "${FIREBIRD_SOURCE_DIR}/extern/libtomcrypt/src/pk/ecc/ecc_make_key.c"
        "${FIREBIRD_SOURCE_DIR}/extern/libtomcrypt/src/pk/ecc/ecc_shared_secret.c"
        "${FIREBIRD_SOURCE_DIR}/extern/libtomcrypt/src/pk/ecc/ecc_sign_hash.c"
        "${FIREBIRD_SOURCE_DIR}/extern/libtomcrypt/src/pk/ecc/ecc_sizes.c"
        "${FIREBIRD_SOURCE_DIR}/extern/libtomcrypt/src/pk/ecc/ecc_test.c"
        "${FIREBIRD_SOURCE_DIR}/extern/libtomcrypt/src/pk/ecc/ecc_verify_hash.c"
        "${FIREBIRD_SOURCE_DIR}/extern/libtomcrypt/src/pk/ecc/ltc_ecc_is_valid_idx.c"
        "${FIREBIRD_SOURCE_DIR}/extern/libtomcrypt/src/pk/ecc/ltc_ecc_map.c"
        "${FIREBIRD_SOURCE_DIR}/extern/libtomcrypt/src/pk/ecc/ltc_ecc_mul2add.c"
        "${FIREBIRD_SOURCE_DIR}/extern/libtomcrypt/src/pk/ecc/ltc_ecc_mulmod.c"
        "${FIREBIRD_SOURCE_DIR}/extern/libtomcrypt/src/pk/ecc/ltc_ecc_mulmod_timing.c"
        "${FIREBIRD_SOURCE_DIR}/extern/libtomcrypt/src/pk/ecc/ltc_ecc_points.c"
        "${FIREBIRD_SOURCE_DIR}/extern/libtomcrypt/src/pk/ecc/ltc_ecc_projective_add_point.c"
        "${FIREBIRD_SOURCE_DIR}/extern/libtomcrypt/src/pk/ecc/ltc_ecc_projective_dbl_point.c"
        "${FIREBIRD_SOURCE_DIR}/extern/libtomcrypt/src/pk/katja/katja_decrypt_key.c"
        "${FIREBIRD_SOURCE_DIR}/extern/libtomcrypt/src/pk/katja/katja_encrypt_key.c"
        "${FIREBIRD_SOURCE_DIR}/extern/libtomcrypt/src/pk/katja/katja_export.c"
        "${FIREBIRD_SOURCE_DIR}/extern/libtomcrypt/src/pk/katja/katja_exptmod.c"
        "${FIREBIRD_SOURCE_DIR}/extern/libtomcrypt/src/pk/katja/katja_free.c"
        "${FIREBIRD_SOURCE_DIR}/extern/libtomcrypt/src/pk/katja/katja_import.c"
        "${FIREBIRD_SOURCE_DIR}/extern/libtomcrypt/src/pk/katja/katja_make_key.c"
        "${FIREBIRD_SOURCE_DIR}/extern/libtomcrypt/src/pk/pkcs1/pkcs_1_i2osp.c"
        "${FIREBIRD_SOURCE_DIR}/extern/libtomcrypt/src/pk/pkcs1/pkcs_1_mgf1.c"
        "${FIREBIRD_SOURCE_DIR}/extern/libtomcrypt/src/pk/pkcs1/pkcs_1_oaep_decode.c"
        "${FIREBIRD_SOURCE_DIR}/extern/libtomcrypt/src/pk/pkcs1/pkcs_1_oaep_encode.c"
        "${FIREBIRD_SOURCE_DIR}/extern/libtomcrypt/src/pk/pkcs1/pkcs_1_os2ip.c"
        "${FIREBIRD_SOURCE_DIR}/extern/libtomcrypt/src/pk/pkcs1/pkcs_1_pss_decode.c"
        "${FIREBIRD_SOURCE_DIR}/extern/libtomcrypt/src/pk/pkcs1/pkcs_1_pss_encode.c"
        "${FIREBIRD_SOURCE_DIR}/extern/libtomcrypt/src/pk/pkcs1/pkcs_1_v1_5_decode.c"
        "${FIREBIRD_SOURCE_DIR}/extern/libtomcrypt/src/pk/pkcs1/pkcs_1_v1_5_encode.c"
        "${FIREBIRD_SOURCE_DIR}/extern/libtomcrypt/src/pk/rsa/rsa_decrypt_key.c"
        "${FIREBIRD_SOURCE_DIR}/extern/libtomcrypt/src/pk/rsa/rsa_encrypt_key.c"
        "${FIREBIRD_SOURCE_DIR}/extern/libtomcrypt/src/pk/rsa/rsa_export.c"
        "${FIREBIRD_SOURCE_DIR}/extern/libtomcrypt/src/pk/rsa/rsa_exptmod.c"
        "${FIREBIRD_SOURCE_DIR}/extern/libtomcrypt/src/pk/rsa/rsa_free.c"
        "${FIREBIRD_SOURCE_DIR}/extern/libtomcrypt/src/pk/rsa/rsa_get_size.c"
        "${FIREBIRD_SOURCE_DIR}/extern/libtomcrypt/src/pk/rsa/rsa_import.c"
        "${FIREBIRD_SOURCE_DIR}/extern/libtomcrypt/src/pk/rsa/rsa_import_pkcs8.c"
        "${FIREBIRD_SOURCE_DIR}/extern/libtomcrypt/src/pk/rsa/rsa_import_x509.c"
        "${FIREBIRD_SOURCE_DIR}/extern/libtomcrypt/src/pk/rsa/rsa_make_key.c"
        "${FIREBIRD_SOURCE_DIR}/extern/libtomcrypt/src/pk/rsa/rsa_set.c"
        "${FIREBIRD_SOURCE_DIR}/extern/libtomcrypt/src/pk/rsa/rsa_sign_hash.c"
        "${FIREBIRD_SOURCE_DIR}/extern/libtomcrypt/src/pk/rsa/rsa_sign_saltlen_get.c"
        "${FIREBIRD_SOURCE_DIR}/extern/libtomcrypt/src/pk/rsa/rsa_verify_hash.c"
        "${FIREBIRD_SOURCE_DIR}/extern/libtomcrypt/src/prngs/chacha20.c"
        "${FIREBIRD_SOURCE_DIR}/extern/libtomcrypt/src/prngs/fortuna.c"
        "${FIREBIRD_SOURCE_DIR}/extern/libtomcrypt/src/prngs/rc4.c"
        "${FIREBIRD_SOURCE_DIR}/extern/libtomcrypt/src/prngs/rng_get_bytes.c"
        "${FIREBIRD_SOURCE_DIR}/extern/libtomcrypt/src/prngs/rng_make_prng.c"
        "${FIREBIRD_SOURCE_DIR}/extern/libtomcrypt/src/prngs/sober128.c"
        "${FIREBIRD_SOURCE_DIR}/extern/libtomcrypt/src/prngs/sprng.c"
        "${FIREBIRD_SOURCE_DIR}/extern/libtomcrypt/src/prngs/yarrow.c"
        "${FIREBIRD_SOURCE_DIR}/extern/libtomcrypt/src/stream/chacha/chacha_crypt.c"
        "${FIREBIRD_SOURCE_DIR}/extern/libtomcrypt/src/stream/chacha/chacha_done.c"
        "${FIREBIRD_SOURCE_DIR}/extern/libtomcrypt/src/stream/chacha/chacha_ivctr32.c"
        "${FIREBIRD_SOURCE_DIR}/extern/libtomcrypt/src/stream/chacha/chacha_ivctr64.c"
        "${FIREBIRD_SOURCE_DIR}/extern/libtomcrypt/src/stream/chacha/chacha_keystream.c"
        "${FIREBIRD_SOURCE_DIR}/extern/libtomcrypt/src/stream/chacha/chacha_setup.c"
        "${FIREBIRD_SOURCE_DIR}/extern/libtomcrypt/src/stream/chacha/chacha_test.c"
        "${FIREBIRD_SOURCE_DIR}/extern/libtomcrypt/src/stream/rc4/rc4_stream.c"
        "${FIREBIRD_SOURCE_DIR}/extern/libtomcrypt/src/stream/rc4/rc4_test.c"
        "${FIREBIRD_SOURCE_DIR}/extern/libtomcrypt/src/stream/sober128/sober128_stream.c"
        "${FIREBIRD_SOURCE_DIR}/extern/libtomcrypt/src/stream/sober128/sober128_test.c"
)

# decNumber
add_library(decNumber STATIC)
set_target_properties(decNumber PROPERTIES OUTPUT_NAME decnumber)
target_sources(decNumber
    PRIVATE
        "${FIREBIRD_SOURCE_DIR}/extern/decNumber/decSingle.c"
        "${FIREBIRD_SOURCE_DIR}/extern/decNumber/decContext.c"
        "${FIREBIRD_SOURCE_DIR}/extern/decNumber/decDouble.c"
        "${FIREBIRD_SOURCE_DIR}/extern/decNumber/decimal32.c"
        "${FIREBIRD_SOURCE_DIR}/extern/decNumber/decimal64.c"
        "${FIREBIRD_SOURCE_DIR}/extern/decNumber/decimal128.c"
        "${FIREBIRD_SOURCE_DIR}/extern/decNumber/decNumber.c"
        "${FIREBIRD_SOURCE_DIR}/extern/decNumber/decPacked.c"
        "${FIREBIRD_SOURCE_DIR}/extern/decNumber/decQuad.c"
)

# ttmath
if(${PLATFORM} STREQUAL "x64")
    # @ml64.exe /c /Fo %FB_TEMP_DIR%\..\%FB_OBJ_DIR%\common\ttmathuint_x86_64_msvc.obj %FB_ROOT_PATH%\extern\ttmath\ttmathuint_x86_64_msvc.asm
endif()

# re2
subdirs(extern/re2)

# zlib
add_custom_command(
    OUTPUT "${FIREBIRD_SOURCE_DIR}/extern/zlib/zlib.h"
    COMMAND ${FIREBIRD_SOURCE_DIR}/extern/zlib/zlib.exe -y
    COMMENT "Extracting pre-built zlib"
)

# parse
add_custom_command(
    OUTPUT
        "${FIREBIRD_SOURCE_DIR}/src/include/gen/parse.h"
        "${FIREBIRD_SOURCE_DIR}/src/dsql/parse.cpp"
    DEPENDS
        btyacc
        "${FIREBIRD_SOURCE_DIR}/src/dsql/parse.y"
        "${FIREBIRD_SOURCE_DIR}/src/dsql/btyacc_fb.ske"
    COMMAND pwsh.exe -ExecutionPolicy Bypass -Command "\
        (Get-Content -Path ${FIREBIRD_SOURCE_DIR}/src/dsql/parse.y) | \
        foreach { if ($_ -match '%type .*') { Write-Output $_ }} | \
        Set-Content -Path types.y"
    COMMAND pwsh.exe -ExecutionPolicy Bypass -Command "\
        (Get-Content -Path ${FIREBIRD_SOURCE_DIR}/src/dsql/parse.y) | \
        foreach { if (-not ($_ -match '%type .*')) { Write-Output $_ }} | \
        Set-Content -Path y.y"
    COMMAND btyacc -l -d -S "${FIREBIRD_SOURCE_DIR}/src/dsql/btyacc_fb.ske" y.y

    COMMAND pwsh.exe -ExecutionPolicy Bypass -Command "\
        (Get-Content -Path y_tab.h) | \
        foreach { $_ -replace '#define ([A-Z].*)', '#define TOK_$1' } | \
        Set-Content -Path y_tab.h"
    COMMAND pwsh.exe -ExecutionPolicy Bypass -Command "\
        (Get-Content -Path y_tab.h) | \
        foreach { $_ -replace '#define TOK_YY(.*)', '#define YY$1' } | \
        Set-Content -Path y_tab.h"
    COMMAND ${CMAKE_COMMAND} -E copy_if_different "y_tab.h" "${FIREBIRD_SOURCE_DIR}/src/include/gen/parse.h"
    COMMAND ${CMAKE_COMMAND} -E copy_if_different "y_tab.c" "${FIREBIRD_SOURCE_DIR}/src/dsql/parse.cpp"
    COMMENT "Generating parse.cpp, parse.h"
    VERBATIM
)
set_source_files_properties(
    "${FIREBIRD_SOURCE_DIR}/src/dsql/parse.cpp"
    "${FIREBIRD_SOURCE_DIR}/src/include/gen/parse.h"
    PROPERTIES GENERATED TRUE
)

# common
add_library(common STATIC)
target_compile_definitions(common
    PRIVATE
        DEV_BUILD
        SUPERSERVER
)
target_link_libraries(common
    PUBLIC
        ws2_32
        mpr
        libtommath
        libtomcrypt
        decNumber
        re2
)
target_include_directories(common
    PUBLIC
        "${FIREBIRD_SOURCE_DIR}/src/include"
        "${FIREBIRD_SOURCE_DIR}/extern/icu/include"
        "${FIREBIRD_SOURCE_DIR}/extern/re2"
    PRIVATE
        "${FIREBIRD_SOURCE_DIR}/extern/zlib"
)
target_sources(common
    PRIVATE
        "${FIREBIRD_SOURCE_DIR}/extern/zlib/zlib.h"
        "${FIREBIRD_SOURCE_DIR}/src/include/gen/parse.h"

        "${FIREBIRD_SOURCE_DIR}/src/common/Auth.cpp"
        "${FIREBIRD_SOURCE_DIR}/src/common/BigInteger.cpp"
        "${FIREBIRD_SOURCE_DIR}/src/common/call_service.cpp"
        "${FIREBIRD_SOURCE_DIR}/src/common/CharSet.cpp"
        "${FIREBIRD_SOURCE_DIR}/src/common/classes/alloc.cpp"
        "${FIREBIRD_SOURCE_DIR}/src/common/classes/BaseStream.cpp"
        "${FIREBIRD_SOURCE_DIR}/src/common/classes/BlobWrapper.cpp"
        "${FIREBIRD_SOURCE_DIR}/src/common/classes/BlrWriter.cpp"
        "${FIREBIRD_SOURCE_DIR}/src/common/classes/ClumpletReader.cpp"
        "${FIREBIRD_SOURCE_DIR}/src/common/classes/ClumpletWriter.cpp"
        "${FIREBIRD_SOURCE_DIR}/src/common/classes/DbImplementation.cpp"
        "${FIREBIRD_SOURCE_DIR}/src/common/classes/fb_string.cpp"
        "${FIREBIRD_SOURCE_DIR}/src/common/classes/Hash.cpp"
        "${FIREBIRD_SOURCE_DIR}/src/common/classes/ImplementHelper.cpp"
        "${FIREBIRD_SOURCE_DIR}/src/common/classes/init.cpp"
        "${FIREBIRD_SOURCE_DIR}/src/common/classes/InternalMessageBuffer.cpp"
        "${FIREBIRD_SOURCE_DIR}/src/common/classes/locks.cpp"
        "${FIREBIRD_SOURCE_DIR}/src/common/classes/MetaString.cpp"
        "${FIREBIRD_SOURCE_DIR}/src/common/classes/MsgPrint.cpp"
        "${FIREBIRD_SOURCE_DIR}/src/common/classes/NoThrowTimeStamp.cpp"
        "${FIREBIRD_SOURCE_DIR}/src/common/classes/ParsedList.cpp"
        "${FIREBIRD_SOURCE_DIR}/src/common/classes/SafeArg.cpp"
        "${FIREBIRD_SOURCE_DIR}/src/common/classes/semaphore.cpp"
        "${FIREBIRD_SOURCE_DIR}/src/common/classes/Switches.cpp"
        "${FIREBIRD_SOURCE_DIR}/src/common/classes/Synchronize.cpp"
        "${FIREBIRD_SOURCE_DIR}/src/common/classes/SyncObject.cpp"
        "${FIREBIRD_SOURCE_DIR}/src/common/classes/TempFile.cpp"
        "${FIREBIRD_SOURCE_DIR}/src/common/classes/TimerImpl.cpp"
        "${FIREBIRD_SOURCE_DIR}/src/common/classes/timestamp.cpp"
        "${FIREBIRD_SOURCE_DIR}/src/common/classes/TomCryptHash.cpp"
        "${FIREBIRD_SOURCE_DIR}/src/common/classes/UserBlob.cpp"
        "${FIREBIRD_SOURCE_DIR}/src/common/classes/zip.cpp"
        "${FIREBIRD_SOURCE_DIR}/src/common/config/config.cpp"
        "${FIREBIRD_SOURCE_DIR}/src/common/config/ConfigCache.cpp"
        "${FIREBIRD_SOURCE_DIR}/src/common/config/config_file.cpp"
        "${FIREBIRD_SOURCE_DIR}/src/common/config/dir_list.cpp"
        "${FIREBIRD_SOURCE_DIR}/src/common/CRC32C.cpp"
        # <IntrinsicFunctions Condition="'$(Configuration)|$(Platform)'=='Debug|Win32'">true</IntrinsicFunctions>
        # <EnableEnhancedInstructionSet Condition="'$(Configuration)|$(Platform)'=='Debug|Win32'">StreamingSIMDExtensions2</EnableEnhancedInstructionSet>
        # <IntrinsicFunctions Condition="'$(Configuration)|$(Platform)'=='Debug|x64'">true</IntrinsicFunctions>
        # <EnableEnhancedInstructionSet Condition="'$(Configuration)|$(Platform)'=='Release|Win32'">StreamingSIMDExtensions2</EnableEnhancedInstructionSet>
        "${FIREBIRD_SOURCE_DIR}/src/common/cvt.cpp"
        "${FIREBIRD_SOURCE_DIR}/src/common/db_alias.cpp"
        "${FIREBIRD_SOURCE_DIR}/src/common/DecFloat.cpp"
        "${FIREBIRD_SOURCE_DIR}/src/common/dllinst.cpp"
        "${FIREBIRD_SOURCE_DIR}/src/common/dsc.cpp"
        "${FIREBIRD_SOURCE_DIR}/src/common/DynamicStrings.cpp"
        "${FIREBIRD_SOURCE_DIR}/src/common/enc.cpp"
        "${FIREBIRD_SOURCE_DIR}/src/common/fb_exception.cpp"
        "${FIREBIRD_SOURCE_DIR}/src/common/Int128.cpp"
        "${FIREBIRD_SOURCE_DIR}/src/common/IntlParametersBlock.cpp"
        "${FIREBIRD_SOURCE_DIR}/src/common/IntlUtil.cpp"
        "${FIREBIRD_SOURCE_DIR}/src/common/isc.cpp"
        "${FIREBIRD_SOURCE_DIR}/src/common/isc_file.cpp"
        "${FIREBIRD_SOURCE_DIR}/src/common/isc_sync.cpp"
        "${FIREBIRD_SOURCE_DIR}/src/common/keywords.cpp"
        "${FIREBIRD_SOURCE_DIR}/src/common/MsgMetadata.cpp"
        "${FIREBIRD_SOURCE_DIR}/src/common/os/win32/fbsyslog.cpp"
        "${FIREBIRD_SOURCE_DIR}/src/common/os/win32/guid.cpp"
        "${FIREBIRD_SOURCE_DIR}/src/common/os/win32/isc_ipc.cpp"
        "${FIREBIRD_SOURCE_DIR}/src/common/os/win32/mod_loader.cpp"
        "${FIREBIRD_SOURCE_DIR}/src/common/os/win32/os_utils.cpp"
        "${FIREBIRD_SOURCE_DIR}/src/common/os/win32/path_utils.cpp"
        "${FIREBIRD_SOURCE_DIR}/src/common/pretty.cpp"
        "${FIREBIRD_SOURCE_DIR}/src/common/ScanDir.cpp"
        "${FIREBIRD_SOURCE_DIR}/src/common/sdl.cpp"
        "${FIREBIRD_SOURCE_DIR}/src/common/security.cpp"
        "${FIREBIRD_SOURCE_DIR}/src/common/sha.cpp"
        "${FIREBIRD_SOURCE_DIR}/src/common/sha2/sha2.cpp"
        "${FIREBIRD_SOURCE_DIR}/src/common/SimilarToRegex.cpp"
        "${FIREBIRD_SOURCE_DIR}/src/common/StatementMetadata.cpp"
        "${FIREBIRD_SOURCE_DIR}/src/common/StatusArg.cpp"
        "${FIREBIRD_SOURCE_DIR}/src/common/StatusHolder.cpp"
        "${FIREBIRD_SOURCE_DIR}/src/common/TextType.cpp"
        "${FIREBIRD_SOURCE_DIR}/src/common/ThreadData.cpp"
        "${FIREBIRD_SOURCE_DIR}/src/common/ThreadStart.cpp"
        "${FIREBIRD_SOURCE_DIR}/src/common/TimeZoneUtil.cpp"
        "${FIREBIRD_SOURCE_DIR}/src/common/Tokens.cpp"
        "${FIREBIRD_SOURCE_DIR}/src/common/unicode_util.cpp"
        "${FIREBIRD_SOURCE_DIR}/src/common/utils.cpp"
        "${FIREBIRD_SOURCE_DIR}/src/common/UtilSvc.cpp"
        "${FIREBIRD_SOURCE_DIR}/src/common/xdr.cpp"
)

# gpre_common
add_library(gpre_common STATIC)
target_compile_definitions(gpre_common
    PRIVATE
        GPRE_FORTRAN
        GPRE_PASCAL
        GPRE_COBOL
        GPRE_ADA
        SUPERCLIENT
        DEV_BUILD
)
target_include_directories(gpre_common
    PUBLIC
        "${FIREBIRD_SOURCE_DIR}/src/include"
    PRIVATE
        "${FIREBIRD_SOURCE_DIR}/src/include/gen"
)
target_sources(gpre_common
    PRIVATE
        "${FIREBIRD_SOURCE_DIR}/src/gpre/cmd.cpp"
        "${FIREBIRD_SOURCE_DIR}/src/gpre/cme.cpp"
        "${FIREBIRD_SOURCE_DIR}/src/gpre/cmp.cpp"
        "${FIREBIRD_SOURCE_DIR}/src/gpre/c_cxx.cpp"
        "${FIREBIRD_SOURCE_DIR}/src/gpre/exp.cpp"
        "${FIREBIRD_SOURCE_DIR}/src/gpre/gpre.cpp"
        "${FIREBIRD_SOURCE_DIR}/src/gpre/hsh.cpp"
        "${FIREBIRD_SOURCE_DIR}/src/gpre/int_cxx.cpp"
        "${FIREBIRD_SOURCE_DIR}/src/gpre/jrdmet.cpp"
        "${FIREBIRD_SOURCE_DIR}/src/gpre/languages/ada.cpp"
        "${FIREBIRD_SOURCE_DIR}/src/gpre/languages/cob.cpp"
        "${FIREBIRD_SOURCE_DIR}/src/gpre/languages/fbrmclib.cpp"
        "${FIREBIRD_SOURCE_DIR}/src/gpre/languages/ftn.cpp"
        "${FIREBIRD_SOURCE_DIR}/src/gpre/languages/pas.cpp"
        "${FIREBIRD_SOURCE_DIR}/src/gpre/languages/rmc.cpp"
        "${FIREBIRD_SOURCE_DIR}/src/gpre/movg.cpp"
        "${FIREBIRD_SOURCE_DIR}/src/gpre/msc.cpp"
        "${FIREBIRD_SOURCE_DIR}/src/gpre/obj_cxx.cpp"
        "${FIREBIRD_SOURCE_DIR}/src/gpre/par.cpp"
        "${FIREBIRD_SOURCE_DIR}/src/gpre/pat.cpp"
        "${FIREBIRD_SOURCE_DIR}/src/gpre/sqe.cpp"
        "${FIREBIRD_SOURCE_DIR}/src/gpre/sql.cpp"
)

# gpre_boot
add_executable(gpre_boot)
target_set_resource(gpre_boot)
target_compile_definitions(gpre_boot
    PRIVATE
        DEV_BUILD
        SUPERCLIENT
        CLIENT
)
target_link_libraries(gpre_boot
    PRIVATE
        common
        gpre_common
)
target_include_directories(gpre_boot
    PRIVATE
        "${FIREBIRD_SOURCE_DIR}/src/include"
        "${FIREBIRD_SOURCE_DIR}/extern/icu/include"
)
target_sources(gpre_boot
    PRIVATE
        "${FIREBIRD_SOURCE_DIR}/src/gpre/boot/gpre_meta_boot.cpp"
        "${FIREBIRD_SOURCE_DIR}/src/yvalve/gds.cpp"
)

# preprocess(boot)
function(preprocess DIR PREP_FILE GPRE_OPT)
    add_custom_command(
        OUTPUT "${FIREBIRD_GEN_DIR}/${PREP_FILE}.cpp"
        DEPENDS
            "${FIREBIRD_SOURCE_DIR}/src/${PREP_FILE}.epp"
            "${FIREBIRD_GEN_DIR}"
            "${FIREBIRD_GEN_DIR}/${DIR}"
            "${FIREBIRD_GEN_DIR}/dbs"
            gpre_boot
        COMMAND gpre_boot
                ${GPRE_OPT}
                "${FIREBIRD_SOURCE_DIR}/src/${PREP_FILE}.epp"
                "${FIREBIRD_GEN_DIR}/${PREP_FILE}.gen"
                -b "${FIREBIRD_GEN_DIR}/dbs/"
        COMMAND pwsh.exe -ExecutionPolicy Bypass -Command "\
            if (-not (Test-Path -Path ${FIREBIRD_GEN_DIR}/${PREP_FILE}.cpp) -or (Compare-Object -ReferenceObject $(Get-Content ${FIREBIRD_GEN_DIR}/${PREP_FILE}.gen) -DifferenceObject $(Get-Content ${FIREBIRD_GEN_DIR}/${PREP_FILE}.cpp))) { \
                Move-Item -Force -Path ${FIREBIRD_GEN_DIR}/${PREP_FILE}.gen -Destination ${FIREBIRD_GEN_DIR}/${PREP_FILE}.cpp \
            } else { \
                Remove-Item -Path ${FIREBIRD_GEN_DIR}/${PREP_FILE}.gen \
            }"
        COMMENT "Processing ${FIREBIRD_SOURCE_DIR}/src/${PREP_FILE}.epp"
        VERBATIM
    )
    set_source_files_properties(
        "${FIREBIRD_GEN_DIR}/${PREP_FILE}.cpp"
        PROPERTIES GENERATED TRUE
    )
endfunction()

foreach(PREP_FILE IN ITEMS
    "burp/backup"
    "burp/restore"
    "burp/OdsDetection")

    preprocess("burp" "${PREP_FILE}" "-lang_internal;-n;-ids;-ocxx;-m")
endforeach()

foreach(PREP_FILE IN ITEMS
    "isql/extract"
    "isql/isql"
    "isql/show")

    preprocess("isql" "${PREP_FILE}" "-lang_internal;-n;-ids;-ocxx")
endforeach()

foreach(PREP_FILE IN ITEMS
    "utilities/gstat/dba")

    preprocess("utilities/gstat" "${PREP_FILE}" "-lang_internal;-n;-m")
endforeach()

foreach(PREP_FILE IN ITEMS
    "alice/alice_meta")

    preprocess("alice" "${PREP_FILE}" "-n;-m")
endforeach()

foreach(PREP_FILE IN ITEMS
    "yvalve/array"
    "yvalve/blob")

    preprocess("yvalve" "${PREP_FILE}" "-n;-m")
endforeach()

foreach(PREP_FILE IN ITEMS
    "dsql/metd"
    "dsql/DdlNodes"
    "dsql/PackageNodes")

    preprocess("dsql" "${PREP_FILE}" "-n;-ids;-gds_cxx")
endforeach()

foreach(PREP_FILE IN ITEMS
    "gpre/std/gpre_meta")

    preprocess("gpre/std" "${PREP_FILE}" "-n;-m")
endforeach()

foreach(PREP_FILE IN ITEMS
    "jrd/dfw"
    "jrd/dpm"
    "jrd/dyn_util"
    "jrd/fun"
    "jrd/grant"
    "jrd/ini"
    "jrd/met"
    "jrd/scl"
    "jrd/Function")

    preprocess("jrd" "${PREP_FILE}" "-n;-ids;-gds_cxx")
endforeach()

foreach(PREP_FILE IN ITEMS
    "utilities/stats")

    preprocess("utilities" "${PREP_FILE}" "-n;-m")
endforeach()

# alice
add_library(alice STATIC)
target_compile_definitions(alice
    PRIVATE
        DEV_BUILD
)
target_include_directories(alice
    PRIVATE
        "${FIREBIRD_SOURCE_DIR}/src/include"
)
target_sources(alice
    PRIVATE
        "${FIREBIRD_GEN_DIR}/alice/alice_meta.cpp"

        "${FIREBIRD_SOURCE_DIR}/src/alice/alice.cpp"
        "${FIREBIRD_SOURCE_DIR}/src/alice/exe.cpp"
        "${FIREBIRD_SOURCE_DIR}/src/alice/tdr.cpp"
)

# burp
add_library(burp STATIC)
target_compile_definitions(burp
    PRIVATE
        DEV_BUILD
)
target_include_directories(burp
    PRIVATE
        "${FIREBIRD_SOURCE_DIR}/src/include"
        "${FIREBIRD_SOURCE_DIR}/extern/re2"
        "${FIREBIRD_SOURCE_DIR}/extern/zlib"
)
target_sources(burp
    PRIVATE
        "${FIREBIRD_GEN_DIR}/burp/backup.cpp"
        "${FIREBIRD_GEN_DIR}/burp/OdsDetection.cpp"
        "${FIREBIRD_GEN_DIR}/burp/restore.cpp"
        "${FIREBIRD_SOURCE_DIR}/extern/zlib/zlib.h"

        "${FIREBIRD_SOURCE_DIR}/src/burp/burp.cpp"
        "${FIREBIRD_SOURCE_DIR}/src/burp/canonical.cpp"
        "${FIREBIRD_SOURCE_DIR}/src/burp/misc.cpp"
        "${FIREBIRD_SOURCE_DIR}/src/burp/mvol.cpp"
)

# remote
add_library(remote STATIC)
target_compile_definitions(remote
    PRIVATE
        DEV_BUILD
)
target_include_directories(remote
    PRIVATE
        "${FIREBIRD_SOURCE_DIR}/src/include"
        "${FIREBIRD_SOURCE_DIR}/extern/zlib"
        "${FIREBIRD_SOURCE_DIR}/extern/libtommath"
)
target_sources(remote
    PRIVATE
        "${FIREBIRD_SOURCE_DIR}/extern/zlib/zlib.h"

        "${FIREBIRD_SOURCE_DIR}/src/auth/SecureRemotePassword/srp.cpp"
        "${FIREBIRD_SOURCE_DIR}/src/remote/inet.cpp"
        "${FIREBIRD_SOURCE_DIR}/src/remote/merge.cpp"
        "${FIREBIRD_SOURCE_DIR}/src/remote/os/win32/xnet.cpp"
        "${FIREBIRD_SOURCE_DIR}/src/remote/parser.cpp"
        "${FIREBIRD_SOURCE_DIR}/src/remote/protocol.cpp"
        "${FIREBIRD_SOURCE_DIR}/src/remote/remote.cpp"
        "${FIREBIRD_SOURCE_DIR}/src/remote/os/win32/wnet.cpp"
        "${FIREBIRD_SOURCE_DIR}/src/auth/trusted/AuthSspi.cpp"
)

# yvalve
add_library(yvalve SHARED)
set_target_properties(yvalve PROPERTIES OUTPUT_NAME fbclient)
target_set_resource(yvalve)
target_compile_definitions(yvalve
    PRIVATE
        SUPERSERVER
        DEV_BUILD
)
target_link_libraries(yvalve
    PRIVATE
        common
        remote
)
target_include_directories(yvalve
    PRIVATE
        "${FIREBIRD_SOURCE_DIR}/extern/zlib"
        "${FIREBIRD_SOURCE_DIR}/extern/libtommath"
)
target_sources(yvalve
    PRIVATE
        "${FIREBIRD_GEN_DIR}/yvalve/array.cpp"
        "${FIREBIRD_GEN_DIR}/yvalve/blob.cpp"
        "${FIREBIRD_SOURCE_DIR}/extern/zlib/zlib.h"

        "${FIREBIRD_SOURCE_DIR}/src/auth/SecureRemotePassword/client/SrpClient.cpp"
        "${FIREBIRD_SOURCE_DIR}/src/auth/SecurityDatabase/LegacyClient.cpp"
        "${FIREBIRD_SOURCE_DIR}/src/jrd/os/win32/ibinitdll.cpp"
        "${FIREBIRD_SOURCE_DIR}/src/plugins/crypt/arc4/Arc4.cpp"
        "${FIREBIRD_SOURCE_DIR}/src/remote/client/BlrFromMessage.cpp"
        "${FIREBIRD_SOURCE_DIR}/src/remote/client/interface.cpp"
        "${FIREBIRD_SOURCE_DIR}/src/yvalve/alt.cpp"
        "${FIREBIRD_SOURCE_DIR}/src/yvalve/config/os/win32/config_root.cpp"
        "${FIREBIRD_SOURCE_DIR}/src/yvalve/DistributedTransaction.cpp"
        "${FIREBIRD_SOURCE_DIR}/src/yvalve/gds.cpp"
        "${FIREBIRD_SOURCE_DIR}/src/yvalve/keywordsStub.cpp"
        "${FIREBIRD_SOURCE_DIR}/src/yvalve/MasterImplementation.cpp"
        "${FIREBIRD_SOURCE_DIR}/src/yvalve/perf.cpp"
        "${FIREBIRD_SOURCE_DIR}/src/yvalve/PluginManager.cpp"
        "${FIREBIRD_SOURCE_DIR}/src/yvalve/preparse.cpp"
        "${FIREBIRD_SOURCE_DIR}/src/yvalve/user_dsql.cpp"
        "${FIREBIRD_SOURCE_DIR}/src/yvalve/utl.cpp"
        "${FIREBIRD_SOURCE_DIR}/src/yvalve/why.cpp"

        "${FIREBIRD_SOURCE_DIR}/builds/win32/defs/firebird.def"
)

# engine
add_library(engine SHARED)
set_target_properties(engine PROPERTIES OUTPUT_NAME "plugins/engine13")
target_set_resource(engine)
target_compile_definitions(engine
    PRIVATE
        SUPERSERVER
        DEV_BUILD
        NAMESPACE=Vulcan
)
target_link_libraries(engine
    PRIVATE
        alice
        burp
        common
        yvalve
)
target_include_directories(engine
    PRIVATE
        "${FIREBIRD_SOURCE_DIR}/src/jrd"
        "${FIREBIRD_SOURCE_DIR}/extern/libtomcrypt/src/headers"
)
target_sources(engine
    PRIVATE
        "${FIREBIRD_GEN_DIR}/dsql/DdlNodes.cpp"
        "${FIREBIRD_GEN_DIR}/dsql/metd.cpp"
        "${FIREBIRD_GEN_DIR}/dsql/PackageNodes.cpp"
        "${FIREBIRD_GEN_DIR}/jrd/dfw.cpp"
        "${FIREBIRD_GEN_DIR}/jrd/dpm.cpp"
        "${FIREBIRD_GEN_DIR}/jrd/dyn_util.cpp"
        "${FIREBIRD_GEN_DIR}/jrd/fun.cpp"
        "${FIREBIRD_GEN_DIR}/jrd/Function.cpp"
        "${FIREBIRD_GEN_DIR}/jrd/grant.cpp"
        "${FIREBIRD_GEN_DIR}/jrd/ini.cpp"
        "${FIREBIRD_GEN_DIR}/jrd/met.cpp"
        "${FIREBIRD_GEN_DIR}/jrd/scl.cpp"
        "${FIREBIRD_GEN_DIR}/utilities/gstat/dba.cpp"

        "${FIREBIRD_SOURCE_DIR}/src/dsql/AggNodes.cpp"
        "${FIREBIRD_SOURCE_DIR}/src/dsql/BlrDebugWriter.cpp"
        "${FIREBIRD_SOURCE_DIR}/src/dsql/BoolNodes.cpp"
        "${FIREBIRD_SOURCE_DIR}/src/dsql/ddl.cpp"
        "${FIREBIRD_SOURCE_DIR}/src/dsql/dsql.cpp"
        "${FIREBIRD_SOURCE_DIR}/src/dsql/DsqlBatch.cpp"
        "${FIREBIRD_SOURCE_DIR}/src/dsql/DsqlCompilerScratch.cpp"
        "${FIREBIRD_SOURCE_DIR}/src/dsql/DsqlCursor.cpp"
        "${FIREBIRD_SOURCE_DIR}/src/dsql/DSqlDataTypeUtil.cpp"
        "${FIREBIRD_SOURCE_DIR}/src/dsql/errd.cpp"
        "${FIREBIRD_SOURCE_DIR}/src/dsql/ExprNodes.cpp"
        "${FIREBIRD_SOURCE_DIR}/src/dsql/gen.cpp"
        "${FIREBIRD_SOURCE_DIR}/src/dsql/make.cpp"
        "${FIREBIRD_SOURCE_DIR}/src/dsql/movd.cpp"
        "${FIREBIRD_SOURCE_DIR}/src/dsql/parse.cpp"
        "${FIREBIRD_SOURCE_DIR}/src/dsql/Parser.cpp"
        "${FIREBIRD_SOURCE_DIR}/src/dsql/pass1.cpp"
        "${FIREBIRD_SOURCE_DIR}/src/dsql/StmtNodes.cpp"
        "${FIREBIRD_SOURCE_DIR}/src/dsql/utld.cpp"
        "${FIREBIRD_SOURCE_DIR}/src/dsql/WinNodes.cpp"
        "${FIREBIRD_SOURCE_DIR}/src/jrd/Attachment.cpp"
        "${FIREBIRD_SOURCE_DIR}/src/jrd/blb.cpp"
        "${FIREBIRD_SOURCE_DIR}/src/jrd/blob_filter.cpp"
        "${FIREBIRD_SOURCE_DIR}/src/jrd/btn.cpp"
        "${FIREBIRD_SOURCE_DIR}/src/jrd/btr.cpp"
        "${FIREBIRD_SOURCE_DIR}/src/jrd/builtin.cpp"
        "${FIREBIRD_SOURCE_DIR}/src/jrd/cch.cpp"
        "${FIREBIRD_SOURCE_DIR}/src/jrd/cmp.cpp"
        "${FIREBIRD_SOURCE_DIR}/src/jrd/Coercion.cpp"
        "${FIREBIRD_SOURCE_DIR}/src/jrd/Collation.cpp"
        "${FIREBIRD_SOURCE_DIR}/src/jrd/ConfigTable.cpp"
        "${FIREBIRD_SOURCE_DIR}/src/jrd/CryptoManager.cpp"
        "${FIREBIRD_SOURCE_DIR}/src/jrd/cvt.cpp"
        "${FIREBIRD_SOURCE_DIR}/src/jrd/cvt2.cpp"
        "${FIREBIRD_SOURCE_DIR}/src/jrd/Database.cpp"
        "${FIREBIRD_SOURCE_DIR}/src/jrd/DataTypeUtil.cpp"
        "${FIREBIRD_SOURCE_DIR}/src/jrd/DbCreators.cpp"
        "${FIREBIRD_SOURCE_DIR}/src/jrd/DebugInterface.cpp"
        "${FIREBIRD_SOURCE_DIR}/src/jrd/err.cpp"
        "${FIREBIRD_SOURCE_DIR}/src/jrd/event.cpp"
        "${FIREBIRD_SOURCE_DIR}/src/jrd/evl.cpp"
        "${FIREBIRD_SOURCE_DIR}/src/jrd/exe.cpp"
        "${FIREBIRD_SOURCE_DIR}/src/jrd/ext.cpp"
        "${FIREBIRD_SOURCE_DIR}/src/jrd/extds/ExtDS.cpp"
        "${FIREBIRD_SOURCE_DIR}/src/jrd/extds/InternalDS.cpp"
        "${FIREBIRD_SOURCE_DIR}/src/jrd/extds/IscDS.cpp"
        "${FIREBIRD_SOURCE_DIR}/src/jrd/extds/ValidatePassword.cpp"
        "${FIREBIRD_SOURCE_DIR}/src/jrd/ExtEngineManager.cpp"
        "${FIREBIRD_SOURCE_DIR}/src/jrd/filters.cpp"
        "${FIREBIRD_SOURCE_DIR}/src/jrd/flu.cpp"
        "${FIREBIRD_SOURCE_DIR}/src/jrd/GarbageCollector.cpp"
        "${FIREBIRD_SOURCE_DIR}/src/jrd/GlobalRWLock.cpp"
        "${FIREBIRD_SOURCE_DIR}/src/jrd/idx.cpp"
        "${FIREBIRD_SOURCE_DIR}/src/jrd/inf.cpp"
        "${FIREBIRD_SOURCE_DIR}/src/jrd/intl.cpp"
        "${FIREBIRD_SOURCE_DIR}/src/jrd/IntlManager.cpp"
        "${FIREBIRD_SOURCE_DIR}/src/jrd/intl_builtin.cpp"
        "${FIREBIRD_SOURCE_DIR}/src/jrd/jrd.cpp"
        "${FIREBIRD_SOURCE_DIR}/src/jrd/JrdStatement.cpp"
        "${FIREBIRD_SOURCE_DIR}/src/jrd/lck.cpp"
        "${FIREBIRD_SOURCE_DIR}/src/jrd/Mapping.cpp"
        "${FIREBIRD_SOURCE_DIR}/src/jrd/MetaName.cpp"
        "${FIREBIRD_SOURCE_DIR}/src/jrd/Monitoring.cpp"
        "${FIREBIRD_SOURCE_DIR}/src/jrd/mov.cpp"
        "${FIREBIRD_SOURCE_DIR}/src/jrd/nbak.cpp"
        "${FIREBIRD_SOURCE_DIR}/src/jrd/nodebug.cpp"
        "${FIREBIRD_SOURCE_DIR}/src/jrd/ods.cpp"
        "${FIREBIRD_SOURCE_DIR}/src/jrd/opt.cpp"
        "${FIREBIRD_SOURCE_DIR}/src/jrd/Optimizer.cpp"
        "${FIREBIRD_SOURCE_DIR}/src/jrd/os/win32/winnt.cpp"
        "${FIREBIRD_SOURCE_DIR}/src/jrd/pag.cpp"
        "${FIREBIRD_SOURCE_DIR}/src/jrd/par.cpp"
        "${FIREBIRD_SOURCE_DIR}/src/jrd/PreparedStatement.cpp"
        "${FIREBIRD_SOURCE_DIR}/src/jrd/RandomGenerator.cpp"
        "${FIREBIRD_SOURCE_DIR}/src/jrd/RecordBuffer.cpp"
        "${FIREBIRD_SOURCE_DIR}/src/jrd/RecordSourceNodes.cpp"
        "${FIREBIRD_SOURCE_DIR}/src/jrd/recsrc/AggregatedStream.cpp"
        "${FIREBIRD_SOURCE_DIR}/src/jrd/recsrc/BitmapTableScan.cpp"
        "${FIREBIRD_SOURCE_DIR}/src/jrd/recsrc/BufferedStream.cpp"
        "${FIREBIRD_SOURCE_DIR}/src/jrd/recsrc/ConditionalStream.cpp"
        "${FIREBIRD_SOURCE_DIR}/src/jrd/recsrc/Cursor.cpp"
        "${FIREBIRD_SOURCE_DIR}/src/jrd/recsrc/ExternalTableScan.cpp"
        "${FIREBIRD_SOURCE_DIR}/src/jrd/recsrc/FilteredStream.cpp"
        "${FIREBIRD_SOURCE_DIR}/src/jrd/recsrc/FirstRowsStream.cpp"
        "${FIREBIRD_SOURCE_DIR}/src/jrd/recsrc/FullOuterJoin.cpp"
        "${FIREBIRD_SOURCE_DIR}/src/jrd/recsrc/FullTableScan.cpp"
        "${FIREBIRD_SOURCE_DIR}/src/jrd/recsrc/HashJoin.cpp"
        "${FIREBIRD_SOURCE_DIR}/src/jrd/recsrc/IndexTableScan.cpp"
        "${FIREBIRD_SOURCE_DIR}/src/jrd/recsrc/LockedStream.cpp"
        "${FIREBIRD_SOURCE_DIR}/src/jrd/recsrc/MergeJoin.cpp"
        "${FIREBIRD_SOURCE_DIR}/src/jrd/recsrc/NestedLoopJoin.cpp"
        "${FIREBIRD_SOURCE_DIR}/src/jrd/recsrc/ProcedureScan.cpp"
        "${FIREBIRD_SOURCE_DIR}/src/jrd/recsrc/RecordSource.cpp"
        "${FIREBIRD_SOURCE_DIR}/src/jrd/recsrc/RecursiveStream.cpp"
        "${FIREBIRD_SOURCE_DIR}/src/jrd/recsrc/SingularStream.cpp"
        "${FIREBIRD_SOURCE_DIR}/src/jrd/recsrc/SkipRowsStream.cpp"
        "${FIREBIRD_SOURCE_DIR}/src/jrd/recsrc/SortedStream.cpp"
        "${FIREBIRD_SOURCE_DIR}/src/jrd/recsrc/Union.cpp"
        "${FIREBIRD_SOURCE_DIR}/src/jrd/recsrc/VirtualTableScan.cpp"
        "${FIREBIRD_SOURCE_DIR}/src/jrd/recsrc/WindowedStream.cpp"
        "${FIREBIRD_SOURCE_DIR}/src/jrd/replication/Applier.cpp"
        "${FIREBIRD_SOURCE_DIR}/src/jrd/replication/ChangeLog.cpp"
        "${FIREBIRD_SOURCE_DIR}/src/jrd/replication/Config.cpp"
        "${FIREBIRD_SOURCE_DIR}/src/jrd/replication/Manager.cpp"
        "${FIREBIRD_SOURCE_DIR}/src/jrd/replication/Publisher.cpp"
        "${FIREBIRD_SOURCE_DIR}/src/jrd/replication/Replicator.cpp"
        "${FIREBIRD_SOURCE_DIR}/src/jrd/replication/Utils.cpp"
        "${FIREBIRD_SOURCE_DIR}/src/jrd/Relation.cpp"
        "${FIREBIRD_SOURCE_DIR}/src/jrd/ResultSet.cpp"
        "${FIREBIRD_SOURCE_DIR}/src/jrd/rlck.cpp"
        "${FIREBIRD_SOURCE_DIR}/src/jrd/Routine.cpp"
        "${FIREBIRD_SOURCE_DIR}/src/jrd/rpb_chain.cpp"
        "${FIREBIRD_SOURCE_DIR}/src/jrd/RuntimeStatistics.cpp"
        "${FIREBIRD_SOURCE_DIR}/src/jrd/Savepoint.cpp"
        "${FIREBIRD_SOURCE_DIR}/src/jrd/sdw.cpp"
        "${FIREBIRD_SOURCE_DIR}/src/jrd/shut.cpp"
        "${FIREBIRD_SOURCE_DIR}/src/jrd/sort.cpp"
        "${FIREBIRD_SOURCE_DIR}/src/jrd/sqz.cpp"
        "${FIREBIRD_SOURCE_DIR}/src/jrd/svc.cpp"
        "${FIREBIRD_SOURCE_DIR}/src/jrd/SysFunction.cpp"
        "${FIREBIRD_SOURCE_DIR}/src/jrd/SystemPackages.cpp"
        "${FIREBIRD_SOURCE_DIR}/src/jrd/TempSpace.cpp"
        "${FIREBIRD_SOURCE_DIR}/src/jrd/TimeZone.cpp"
        "${FIREBIRD_SOURCE_DIR}/src/jrd/tpc.cpp"
        "${FIREBIRD_SOURCE_DIR}/src/jrd/tra.cpp"
        "${FIREBIRD_SOURCE_DIR}/src/jrd/trace/TraceCmdLine.cpp"
        "${FIREBIRD_SOURCE_DIR}/src/jrd/trace/TraceConfigStorage.cpp"
        "${FIREBIRD_SOURCE_DIR}/src/jrd/trace/TraceLog.cpp"
        "${FIREBIRD_SOURCE_DIR}/src/jrd/trace/TraceManager.cpp"
        "${FIREBIRD_SOURCE_DIR}/src/jrd/trace/TraceObjects.cpp"
        "${FIREBIRD_SOURCE_DIR}/src/jrd/trace/TraceService.cpp"
        "${FIREBIRD_SOURCE_DIR}/src/jrd/UserManagement.cpp"
        "${FIREBIRD_SOURCE_DIR}/src/jrd/validation.cpp"
        "${FIREBIRD_SOURCE_DIR}/src/jrd/vio.cpp"
        "${FIREBIRD_SOURCE_DIR}/src/jrd/VirtualTable.cpp"
        "${FIREBIRD_SOURCE_DIR}/src/lock/lock.cpp"
        "${FIREBIRD_SOURCE_DIR}/src/utilities/gsec/gsec.cpp"
        "${FIREBIRD_SOURCE_DIR}/src/utilities/gstat/ppg.cpp"
        "${FIREBIRD_SOURCE_DIR}/src/utilities/nbackup/nbackup.cpp"

        "${FIREBIRD_SOURCE_DIR}/builds/win32/defs/plugin.def"
)

# gbak
add_executable(gbak)
target_set_resource(gbak)
target_compile_definitions(gbak
    PRIVATE
        SUPERCLIENT
        DEV_BUILD
)
target_link_libraries(gbak
    PRIVATE
        burp
        common
        yvalve
)
target_sources(gbak
    PRIVATE
        "${FIREBIRD_SOURCE_DIR}/src/burp/main/burpMain.cpp"
)

# gpre
add_executable(gpre)
target_set_resource(gpre)
target_compile_definitions(gpre
    PRIVATE
        GPRE_FORTRAN
        GPRE_PASCAL
        GPRE_COBOL
        GPRE_ADA
        SUPERCLIENT
        DEV_BUILD
)
target_link_libraries(gpre
    PRIVATE
        common
        gpre_common
        yvalve
)
target_sources(gpre
    PRIVATE
        "${FIREBIRD_GEN_DIR}/gpre/std/gpre_meta.cpp"
)

# isql
add_executable(isql)
target_set_resource(isql)
target_compile_definitions(isql
    PRIVATE
        SUPERCLIENT
        DEV_BUILD
)
target_link_libraries(isql
    PRIVATE
        common
        yvalve
)
target_sources(isql
    PRIVATE
        "${FIREBIRD_GEN_DIR}/isql/extract.cpp"
        "${FIREBIRD_GEN_DIR}/isql/isql.cpp"
        "${FIREBIRD_GEN_DIR}/isql/show.cpp"

        "${FIREBIRD_SOURCE_DIR}/src/isql/ColList.cpp"
        "${FIREBIRD_SOURCE_DIR}/src/isql/Extender.cpp"
        "${FIREBIRD_SOURCE_DIR}/src/common/fb_exception.cpp"
        "${FIREBIRD_SOURCE_DIR}/src/isql/InputDevices.cpp"
        "${FIREBIRD_SOURCE_DIR}/src/isql/iutils.cpp"
        "${FIREBIRD_SOURCE_DIR}/src/isql/OptionsBase.cpp"
)

# firebird.conf
add_custom_command(
    OUTPUT "${FIREBIRD_OUTPUT_DIR}/firebird.conf"
    DEPENDS "${FIREBIRD_SOURCE_DIR}/builds/install/misc/firebird.conf"
    COMMAND ${CMAKE_COMMAND} -E copy "${FIREBIRD_SOURCE_DIR}/builds/install/misc/firebird.conf" "${FIREBIRD_OUTPUT_DIR}/firebird.conf"
)

# databases
add_custom_command(
    OUTPUT
        "${FIREBIRD_GEN_DIR}/dbs/SECURITY4.FDB"
        "${FIREBIRD_GEN_DIR}/dbs/SECURITY.FDB"
    DEPENDS
        isql
        engine
        "${FIREBIRD_SOURCE_DIR}/src/dbs/security.sql"
        "${FIREBIRD_OUTPUT_DIR}/firebird.conf"
    COMMAND ${CMAKE_COMMAND} -E rm -f "${FIREBIRD_GEN_DIR}/dbs/SECURITY4.FDB" "${FIREBIRD_GEN_DIR}/dbs/SECURITY.FDB"
    COMMAND pwsh.exe -ExecutionPolicy Bypass -Command "\
        [string[]] $sql = @(\"CREATE DATABASE '${FIREBIRD_GEN_DIR}/dbs/SECURITY4.FDB' PAGE_SIZE 8192;\"); \
        $sql += (Get-Content -Path '${FIREBIRD_SOURCE_DIR}/src/dbs/security.sql'); \
        Write-Output $sql | $<TARGET_FILE:isql>;"
    COMMAND ${CMAKE_COMMAND} -E copy "${FIREBIRD_GEN_DIR}/dbs/SECURITY4.FDB" "${FIREBIRD_GEN_DIR}/dbs/SECURITY.FDB"
    COMMENT "Create SECURITY4.FDB"
    VERBATIM
)
add_custom_command(
    OUTPUT
        "${FIREBIRD_GEN_DIR}/dbs/METADATA.FDB"
    DEPENDS
        gbak
        "${FIREBIRD_SOURCE_DIR}/builds/misc/metadata.gbak"
        "${FIREBIRD_OUTPUT_DIR}/firebird.conf"
    COMMAND ${CMAKE_COMMAND} -E rm -f "${FIREBIRD_GEN_DIR}/dbs/METADATA.FDB"
    COMMAND gbak -r "${FIREBIRD_SOURCE_DIR}/builds/misc/metadata.gbak" "${FIREBIRD_GEN_DIR}/dbs/METADATA.FDB"
    COMMAND ${CMAKE_COMMAND} -E copy "${FIREBIRD_GEN_DIR}/dbs/METADATA.FDB" "${FIREBIRD_GEN_DIR}/dbs/yachts.lnk"
    COMMENT "Create METADATA.FDB"
    VERBATIM
)
add_custom_command(
    OUTPUT
        "${FIREBIRD_GEN_DIR}/dbs/MSG.FDB"
    DEPENDS
        isql
        engine
        "${FIREBIRD_SOURCE_DIR}/src/msgs/msg.sql"
        "${FIREBIRD_SOURCE_DIR}/src/msgs/facilities2.sql"
        "${FIREBIRD_SOURCE_DIR}/src/msgs/sqlstates.sql"
        "${FIREBIRD_SOURCE_DIR}/src/msgs/locales.sql"
        "${FIREBIRD_SOURCE_DIR}/src/msgs/history2.sql"
        "${FIREBIRD_SOURCE_DIR}/src/msgs/messages2.sql"
        "${FIREBIRD_SOURCE_DIR}/src/msgs/symbols2.sql"
        "${FIREBIRD_SOURCE_DIR}/src/msgs/system_errors2.sql"
        "${FIREBIRD_SOURCE_DIR}/src/msgs/transmsgs.fr_FR2.sql"
        "${FIREBIRD_SOURCE_DIR}/src/msgs/transmsgs.de_DE2.sql"
    COMMAND ${CMAKE_COMMAND} -E rm -f "${FIREBIRD_GEN_DIR}/dbs/MSG.FDB"
    COMMAND pwsh.exe -ExecutionPolicy Bypass -Command
        "Write-Output \"CREATE DATABASE '${FIREBIRD_GEN_DIR}/dbs/MSG.FDB' PAGE_SIZE 8192;\" | $<TARGET_FILE:isql>;"
    COMMAND isql -b -q "${FIREBIRD_GEN_DIR}/dbs/MSG.FDB" -i "${FIREBIRD_SOURCE_DIR}/src/msgs/msg.sql"
    COMMAND isql -b -q "${FIREBIRD_GEN_DIR}/dbs/MSG.FDB" -i "${FIREBIRD_SOURCE_DIR}/src/msgs/facilities2.sql"
    COMMAND isql -b -q "${FIREBIRD_GEN_DIR}/dbs/MSG.FDB" -i "${FIREBIRD_SOURCE_DIR}/src/msgs/sqlstates.sql"
    COMMAND isql -b -q "${FIREBIRD_GEN_DIR}/dbs/MSG.FDB" -i "${FIREBIRD_SOURCE_DIR}/src/msgs/locales.sql"
    COMMAND isql -b -q "${FIREBIRD_GEN_DIR}/dbs/MSG.FDB" -i "${FIREBIRD_SOURCE_DIR}/src/msgs/history2.sql"
    COMMAND isql -b -q "${FIREBIRD_GEN_DIR}/dbs/MSG.FDB" -i "${FIREBIRD_SOURCE_DIR}/src/msgs/messages2.sql"
    COMMAND isql -b -q "${FIREBIRD_GEN_DIR}/dbs/MSG.FDB" -i "${FIREBIRD_SOURCE_DIR}/src/msgs/symbols2.sql"
    COMMAND isql -b -q "${FIREBIRD_GEN_DIR}/dbs/MSG.FDB" -i "${FIREBIRD_SOURCE_DIR}/src/msgs/system_errors2.sql"
    COMMAND isql -b -q "${FIREBIRD_GEN_DIR}/dbs/MSG.FDB" -i "${FIREBIRD_SOURCE_DIR}/src/msgs/transmsgs.fr_FR2.sql"
    COMMAND isql -b -q "${FIREBIRD_GEN_DIR}/dbs/MSG.FDB" -i "${FIREBIRD_SOURCE_DIR}/src/msgs/transmsgs.de_DE2.sql"
    COMMENT "Create MSG.FDB"
    VERBATIM
)
add_custom_command(
    OUTPUT
        "${FIREBIRD_GEN_DIR}/dbs/HELP.FDB"
    DEPENDS
        gbak
        "${FIREBIRD_SOURCE_DIR}/builds/misc/help.gbak"
        "${FIREBIRD_OUTPUT_DIR}/firebird.conf"
    COMMAND ${CMAKE_COMMAND} -E rm -f "${FIREBIRD_GEN_DIR}/dbs/HELP.FDB"
    COMMAND gbak -r "${FIREBIRD_SOURCE_DIR}/builds/misc/help.gbak" "${FIREBIRD_GEN_DIR}/dbs/HELP.FDB"
    COMMENT "Create HELP.FDB"
    VERBATIM
)
add_custom_target(databases ALL
    DEPENDS
        "${FIREBIRD_GEN_DIR}/dbs/SECURITY4.FDB"
        "${FIREBIRD_GEN_DIR}/dbs/METADATA.FDB"
        "${FIREBIRD_GEN_DIR}/dbs/MSG.FDB"
        "${FIREBIRD_GEN_DIR}/dbs/HELP.FDB"
)

# preprocess(master)
# TODO: çlÇ¶íÜ...
#@set GPRE=%FB_BIN_DIR%\gpre
#@for %%i in (alice_meta) do @call :PREPROCESS alice %%i
#@for %%i in (LegacyManagement) do @call :PREPROCESS auth/SecurityDatabase %%i
#@for %%i in (backup, restore, OdsDetection) do @call :PREPROCESS burp %%i -ocxx -m
#@for %%i in (array, blob) do @call :PREPROCESS yvalve %%i
#@for %%i in (metd) do @call :PREPROCESS dsql %%i -gds_cxx
#@for %%i in (DdlNodes, PackageNodes) do @call :PREPROCESS dsql %%i -gds_cxx
#@for %%i in (gpre_meta) do @call :PREPROCESS gpre/std %%i
#@for %%i in (dfw, dpm, dyn_util, fun, grant, ini, met, scl, Function) do @call :PREPROCESS jrd %%i -gds_cxx
#@for %%i in (codes) do @call :PREPROCESS misc %%i
#@for %%i in (build_file) do @call :PREPROCESS msgs %%i
#@for %%i in (help, meta, proc, show) do @call :PREPROCESS qli %%i
#@for %%i in (extract, isql, show) do @call :PREPROCESS isql %%i -ocxx
#@for %%i in (dba) do @call :PREPROCESS utilities/gstat %%i
#@for %%i in (stats) do @call :PREPROCESS utilities %%i


# gfix
add_executable(gfix)
target_set_resource(gfix)
target_compile_definitions(gfix
    PRIVATE
        SUPERCLIENT
        DEV_BUILD
)
target_link_libraries(gfix
    PRIVATE
        alice
        common
        yvalve
)
target_sources(gfix
    PRIVATE
        "${FIREBIRD_SOURCE_DIR}/src/alice/main/aliceMain.cpp"
)
