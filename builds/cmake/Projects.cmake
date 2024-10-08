################################################################################
#
# Projects Definitions
#
################################################################################

################################################################################
# cloop
################################################################################
fb_add_executable(cloop COMMON)
fb_target_sources(cloop
    ROOT_PRIVATE
        "extern/cloop/src/cloop/Action.cpp"
        "extern/cloop/src/cloop/Expr.cpp"
        "extern/cloop/src/cloop/Generator.cpp"
        "extern/cloop/src/cloop/Lexer.cpp"
        "extern/cloop/src/cloop/Main.cpp"
        "extern/cloop/src/cloop/Parser.cpp"
)

################################################################################
# def_awk
################################################################################
fb_add_executable(def_awk COMMON)
fb_target_sources(def_awk
    ROOT_PRIVATE
        "src/misc/def_awk.c"
)

################################################################################
# isc_grep
################################################################################
fb_add_executable(isc_grep COMMON)
fb_target_sources(isc_grep
    ROOT_PRIVATE
        "src/misc/isc_grep.c"
)

################################################################################
# btyacc
################################################################################
fb_add_executable(btyacc COMMON)
fb_target_sources(btyacc
    ROOT_PRIVATE
        "extern/btyacc/readskel.c"
        "extern/btyacc/skel2c"
        "extern/btyacc/skeleton.c"
        "extern/btyacc/symtab.c"
        "extern/btyacc/verbose.c"
        "extern/btyacc/warshall.c"
        "extern/btyacc/closure.c"
        "extern/btyacc/error.c"
        "extern/btyacc/lalr.c"
        "extern/btyacc/lr0.c"
        "extern/btyacc/main.c"
        "extern/btyacc/mkpar.c"
        "extern/btyacc/mstring.c"
        "extern/btyacc/output.c"
        "extern/btyacc/reader.c"
)

################################################################################
# libtommath
################################################################################
fb_add_library(libtommath STATIC COMMON OUTPUT_NAME tommath)
fb_target_include_directories(libtommath
    ROOT_PUBLIC
        "extern/libtommath"
)
fb_target_sources(libtommath
    ROOT_PRIVATE
        "extern/libtommath/bn_mp_toom_sqr.c"
        "extern/libtommath/bn_mp_toradix.c"
        "extern/libtommath/bn_mp_toradix_n.c"
        "extern/libtommath/bn_mp_unsigned_bin_size.c"
        "extern/libtommath/bn_mp_xor.c"
        "extern/libtommath/bn_mp_zero.c"
        "extern/libtommath/bn_prime_tab.c"
        "extern/libtommath/bn_reverse.c"
        "extern/libtommath/bn_s_mp_add.c"
        "extern/libtommath/bn_s_mp_exptmod.c"
        "extern/libtommath/bn_s_mp_mul_digs.c"
        "extern/libtommath/bn_s_mp_mul_high_digs.c"
        "extern/libtommath/bn_s_mp_sqr.c"
        "extern/libtommath/bn_s_mp_sub.c"
        "extern/libtommath/bncore.c"
        "extern/libtommath/bn_error.c"
        "extern/libtommath/bn_fast_mp_invmod.c"
        "extern/libtommath/bn_fast_mp_montgomery_reduce.c"
        "extern/libtommath/bn_fast_s_mp_mul_digs.c"
        "extern/libtommath/bn_fast_s_mp_mul_high_digs.c"
        "extern/libtommath/bn_fast_s_mp_sqr.c"
        "extern/libtommath/bn_mp_2expt.c"
        "extern/libtommath/bn_mp_abs.c"
        "extern/libtommath/bn_mp_add.c"
        "extern/libtommath/bn_mp_add_d.c"
        "extern/libtommath/bn_mp_addmod.c"
        "extern/libtommath/bn_mp_and.c"
        "extern/libtommath/bn_mp_clamp.c"
        "extern/libtommath/bn_mp_clear.c"
        "extern/libtommath/bn_mp_clear_multi.c"
        "extern/libtommath/bn_mp_cmp.c"
        "extern/libtommath/bn_mp_cmp_d.c"
        "extern/libtommath/bn_mp_cmp_mag.c"
        "extern/libtommath/bn_mp_cnt_lsb.c"
        "extern/libtommath/bn_mp_copy.c"
        "extern/libtommath/bn_mp_count_bits.c"
        "extern/libtommath/bn_mp_div.c"
        "extern/libtommath/bn_mp_div_2.c"
        "extern/libtommath/bn_mp_div_2d.c"
        "extern/libtommath/bn_mp_div_3.c"
        "extern/libtommath/bn_mp_div_d.c"
        "extern/libtommath/bn_mp_dr_is_modulus.c"
        "extern/libtommath/bn_mp_dr_reduce.c"
        "extern/libtommath/bn_mp_dr_setup.c"
        "extern/libtommath/bn_mp_exch.c"
        "extern/libtommath/bn_mp_expt_d.c"
        "extern/libtommath/bn_mp_exptmod.c"
        "extern/libtommath/bn_mp_exptmod_fast.c"
        "extern/libtommath/bn_mp_exteuclid.c"
        "extern/libtommath/bn_mp_fread.c"
        "extern/libtommath/bn_mp_fwrite.c"
        "extern/libtommath/bn_mp_gcd.c"
        "extern/libtommath/bn_mp_get_int.c"
        "extern/libtommath/bn_mp_grow.c"
        "extern/libtommath/bn_mp_init.c"
        "extern/libtommath/bn_mp_init_copy.c"
        "extern/libtommath/bn_mp_init_multi.c"
        "extern/libtommath/bn_mp_init_set.c"
        "extern/libtommath/bn_mp_init_set_int.c"
        "extern/libtommath/bn_mp_init_size.c"
        "extern/libtommath/bn_mp_invmod.c"
        "extern/libtommath/bn_mp_invmod_slow.c"
        "extern/libtommath/bn_mp_is_square.c"
        "extern/libtommath/bn_mp_jacobi.c"
        "extern/libtommath/bn_mp_karatsuba_mul.c"
        "extern/libtommath/bn_mp_karatsuba_sqr.c"
        "extern/libtommath/bn_mp_lcm.c"
        "extern/libtommath/bn_mp_lshd.c"
        "extern/libtommath/bn_mp_mod.c"
        "extern/libtommath/bn_mp_mod_2d.c"
        "extern/libtommath/bn_mp_mod_d.c"
        "extern/libtommath/bn_mp_montgomery_calc_normalization.c"
        "extern/libtommath/bn_mp_montgomery_reduce.c"
        "extern/libtommath/bn_mp_montgomery_setup.c"
        "extern/libtommath/bn_mp_mul.c"
        "extern/libtommath/bn_mp_mul_2.c"
        "extern/libtommath/bn_mp_mul_2d.c"
        "extern/libtommath/bn_mp_mul_d.c"
        "extern/libtommath/bn_mp_mulmod.c"
        "extern/libtommath/bn_mp_n_root.c"
        "extern/libtommath/bn_mp_neg.c"
        "extern/libtommath/bn_mp_or.c"
        "extern/libtommath/bn_mp_prime_fermat.c"
        "extern/libtommath/bn_mp_prime_is_divisible.c"
        "extern/libtommath/bn_mp_prime_is_prime.c"
        "extern/libtommath/bn_mp_prime_miller_rabin.c"
        "extern/libtommath/bn_mp_prime_next_prime.c"
        "extern/libtommath/bn_mp_prime_rabin_miller_trials.c"
        "extern/libtommath/bn_mp_prime_random_ex.c"
        "extern/libtommath/bn_mp_radix_size.c"
        "extern/libtommath/bn_mp_radix_smap.c"
        "extern/libtommath/bn_mp_rand.c"
        "extern/libtommath/bn_mp_read_radix.c"
        "extern/libtommath/bn_mp_read_signed_bin.c"
        "extern/libtommath/bn_mp_read_unsigned_bin.c"
        "extern/libtommath/bn_mp_reduce.c"
        "extern/libtommath/bn_mp_reduce_2k.c"
        "extern/libtommath/bn_mp_reduce_2k_l.c"
        "extern/libtommath/bn_mp_reduce_2k_setup.c"
        "extern/libtommath/bn_mp_reduce_2k_setup_l.c"
        "extern/libtommath/bn_mp_reduce_is_2k.c"
        "extern/libtommath/bn_mp_reduce_is_2k_l.c"
        "extern/libtommath/bn_mp_reduce_setup.c"
        "extern/libtommath/bn_mp_rshd.c"
        "extern/libtommath/bn_mp_set.c"
        "extern/libtommath/bn_mp_set_int.c"
        "extern/libtommath/bn_mp_shrink.c"
        "extern/libtommath/bn_mp_signed_bin_size.c"
        "extern/libtommath/bn_mp_sqr.c"
        "extern/libtommath/bn_mp_sqrmod.c"
        "extern/libtommath/bn_mp_sqrt.c"
        "extern/libtommath/bn_mp_sub.c"
        "extern/libtommath/bn_mp_sub_d.c"
        "extern/libtommath/bn_mp_submod.c"
        "extern/libtommath/bn_mp_to_signed_bin.c"
        "extern/libtommath/bn_mp_to_signed_bin_n.c"
        "extern/libtommath/bn_mp_to_unsigned_bin.c"
        "extern/libtommath/bn_mp_to_unsigned_bin_n.c"
        "extern/libtommath/bn_mp_toom_mul.c"
)

################################################################################
# libtomcrypt
################################################################################
fb_add_library(libtomcrypt STATIC COMMON OUTPUT_NAME tomcrypt)
fb_target_compile_definitions(libtomcrypt
    PRIVATE
        LTM_DESC
        LTC_SOURCE
        LTC_NO_TEST
)
fb_target_link_libraries(libtomcrypt 
    PRIVATE
        libtommath
)
fb_target_include_directories(libtomcrypt
    ROOT_PUBLIC
        "extern/libtomcrypt/src/headers"
)
fb_target_sources(libtomcrypt
    ROOT_PRIVATE
        "extern/libtomcrypt/src/ciphers/aes/aes.c"
        "extern/libtomcrypt/src/ciphers/anubis.c"
        "extern/libtomcrypt/src/ciphers/blowfish.c"
        "extern/libtomcrypt/src/ciphers/camellia.c"
        "extern/libtomcrypt/src/ciphers/cast5.c"
        "extern/libtomcrypt/src/ciphers/des.c"
        "extern/libtomcrypt/src/ciphers/kasumi.c"
        "extern/libtomcrypt/src/ciphers/khazad.c"
        "extern/libtomcrypt/src/ciphers/kseed.c"
        "extern/libtomcrypt/src/ciphers/multi2.c"
        "extern/libtomcrypt/src/ciphers/noekeon.c"
        "extern/libtomcrypt/src/ciphers/rc2.c"
        "extern/libtomcrypt/src/ciphers/rc5.c"
        "extern/libtomcrypt/src/ciphers/rc6.c"
        "extern/libtomcrypt/src/ciphers/safer/safer.c"
        "extern/libtomcrypt/src/ciphers/safer/saferp.c"
        "extern/libtomcrypt/src/ciphers/skipjack.c"
        "extern/libtomcrypt/src/ciphers/twofish/twofish.c"
        "extern/libtomcrypt/src/ciphers/xtea.c"
        "extern/libtomcrypt/src/encauth/ccm/ccm_add_aad.c"
        "extern/libtomcrypt/src/encauth/ccm/ccm_add_nonce.c"
        "extern/libtomcrypt/src/encauth/ccm/ccm_done.c"
        "extern/libtomcrypt/src/encauth/ccm/ccm_init.c"
        "extern/libtomcrypt/src/encauth/ccm/ccm_memory.c"
        "extern/libtomcrypt/src/encauth/ccm/ccm_process.c"
        "extern/libtomcrypt/src/encauth/ccm/ccm_reset.c"
        "extern/libtomcrypt/src/encauth/ccm/ccm_test.c"
        "extern/libtomcrypt/src/encauth/chachapoly/chacha20poly1305_add_aad.c"
        "extern/libtomcrypt/src/encauth/chachapoly/chacha20poly1305_decrypt.c"
        "extern/libtomcrypt/src/encauth/chachapoly/chacha20poly1305_done.c"
        "extern/libtomcrypt/src/encauth/chachapoly/chacha20poly1305_encrypt.c"
        "extern/libtomcrypt/src/encauth/chachapoly/chacha20poly1305_init.c"
        "extern/libtomcrypt/src/encauth/chachapoly/chacha20poly1305_memory.c"
        "extern/libtomcrypt/src/encauth/chachapoly/chacha20poly1305_setiv.c"
        "extern/libtomcrypt/src/encauth/chachapoly/chacha20poly1305_setiv_rfc7905.c"
        "extern/libtomcrypt/src/encauth/chachapoly/chacha20poly1305_test.c"
        "extern/libtomcrypt/src/encauth/eax/eax_addheader.c"
        "extern/libtomcrypt/src/encauth/eax/eax_decrypt.c"
        "extern/libtomcrypt/src/encauth/eax/eax_decrypt_verify_memory.c"
        "extern/libtomcrypt/src/encauth/eax/eax_done.c"
        "extern/libtomcrypt/src/encauth/eax/eax_encrypt.c"
        "extern/libtomcrypt/src/encauth/eax/eax_encrypt_authenticate_memory.c"
        "extern/libtomcrypt/src/encauth/eax/eax_init.c"
        "extern/libtomcrypt/src/encauth/eax/eax_test.c"
        "extern/libtomcrypt/src/encauth/gcm/gcm_add_aad.c"
        "extern/libtomcrypt/src/encauth/gcm/gcm_add_iv.c"
        "extern/libtomcrypt/src/encauth/gcm/gcm_done.c"
        "extern/libtomcrypt/src/encauth/gcm/gcm_gf_mult.c"
        "extern/libtomcrypt/src/encauth/gcm/gcm_init.c"
        "extern/libtomcrypt/src/encauth/gcm/gcm_memory.c"
        "extern/libtomcrypt/src/encauth/gcm/gcm_mult_h.c"
        "extern/libtomcrypt/src/encauth/gcm/gcm_process.c"
        "extern/libtomcrypt/src/encauth/gcm/gcm_reset.c"
        "extern/libtomcrypt/src/encauth/gcm/gcm_test.c"
        "extern/libtomcrypt/src/encauth/ocb3/ocb3_add_aad.c"
        "extern/libtomcrypt/src/encauth/ocb3/ocb3_decrypt.c"
        "extern/libtomcrypt/src/encauth/ocb3/ocb3_decrypt_last.c"
        "extern/libtomcrypt/src/encauth/ocb3/ocb3_decrypt_verify_memory.c"
        "extern/libtomcrypt/src/encauth/ocb3/ocb3_done.c"
        "extern/libtomcrypt/src/encauth/ocb3/ocb3_encrypt.c"
        "extern/libtomcrypt/src/encauth/ocb3/ocb3_encrypt_authenticate_memory.c"
        "extern/libtomcrypt/src/encauth/ocb3/ocb3_encrypt_last.c"
        "extern/libtomcrypt/src/encauth/ocb3/ocb3_init.c"
        "extern/libtomcrypt/src/encauth/ocb3/ocb3_int_ntz.c"
        "extern/libtomcrypt/src/encauth/ocb3/ocb3_int_xor_blocks.c"
        "extern/libtomcrypt/src/encauth/ocb3/ocb3_test.c"
        "extern/libtomcrypt/src/encauth/ocb/ocb_decrypt.c"
        "extern/libtomcrypt/src/encauth/ocb/ocb_decrypt_verify_memory.c"
        "extern/libtomcrypt/src/encauth/ocb/ocb_done_decrypt.c"
        "extern/libtomcrypt/src/encauth/ocb/ocb_done_encrypt.c"
        "extern/libtomcrypt/src/encauth/ocb/ocb_encrypt.c"
        "extern/libtomcrypt/src/encauth/ocb/ocb_encrypt_authenticate_memory.c"
        "extern/libtomcrypt/src/encauth/ocb/ocb_init.c"
        "extern/libtomcrypt/src/encauth/ocb/ocb_ntz.c"
        "extern/libtomcrypt/src/encauth/ocb/ocb_shift_xor.c"
        "extern/libtomcrypt/src/encauth/ocb/ocb_test.c"
        "extern/libtomcrypt/src/encauth/ocb/s_ocb_done.c"
        "extern/libtomcrypt/src/hashes/blake2b.c"
        "extern/libtomcrypt/src/hashes/blake2s.c"
        "extern/libtomcrypt/src/hashes/chc/chc.c"
        "extern/libtomcrypt/src/hashes/helper/hash_file.c"
        "extern/libtomcrypt/src/hashes/helper/hash_filehandle.c"
        "extern/libtomcrypt/src/hashes/helper/hash_memory.c"
        "extern/libtomcrypt/src/hashes/helper/hash_memory_multi.c"
        "extern/libtomcrypt/src/hashes/md2.c"
        "extern/libtomcrypt/src/hashes/md4.c"
        "extern/libtomcrypt/src/hashes/md5.c"
        "extern/libtomcrypt/src/hashes/rmd128.c"
        "extern/libtomcrypt/src/hashes/rmd160.c"
        "extern/libtomcrypt/src/hashes/rmd256.c"
        "extern/libtomcrypt/src/hashes/rmd320.c"
        "extern/libtomcrypt/src/hashes/sha1.c"
        "extern/libtomcrypt/src/hashes/sha2/sha224.c"
        "extern/libtomcrypt/src/hashes/sha2/sha256.c"
        "extern/libtomcrypt/src/hashes/sha2/sha384.c"
        "extern/libtomcrypt/src/hashes/sha2/sha512.c"
        "extern/libtomcrypt/src/hashes/sha2/sha512_224.c"
        "extern/libtomcrypt/src/hashes/sha2/sha512_256.c"
        "extern/libtomcrypt/src/hashes/sha3.c"
        "extern/libtomcrypt/src/hashes/sha3_test.c"
        "extern/libtomcrypt/src/hashes/tiger.c"
        "extern/libtomcrypt/src/hashes/whirl/whirl.c"
        "extern/libtomcrypt/src/mac/blake2/blake2bmac.c"
        "extern/libtomcrypt/src/mac/blake2/blake2bmac_file.c"
        "extern/libtomcrypt/src/mac/blake2/blake2bmac_memory.c"
        "extern/libtomcrypt/src/mac/blake2/blake2bmac_memory_multi.c"
        "extern/libtomcrypt/src/mac/blake2/blake2bmac_test.c"
        "extern/libtomcrypt/src/mac/blake2/blake2smac.c"
        "extern/libtomcrypt/src/mac/blake2/blake2smac_file.c"
        "extern/libtomcrypt/src/mac/blake2/blake2smac_memory.c"
        "extern/libtomcrypt/src/mac/blake2/blake2smac_memory_multi.c"
        "extern/libtomcrypt/src/mac/blake2/blake2smac_test.c"
        "extern/libtomcrypt/src/mac/f9/f9_done.c"
        "extern/libtomcrypt/src/mac/f9/f9_file.c"
        "extern/libtomcrypt/src/mac/f9/f9_init.c"
        "extern/libtomcrypt/src/mac/f9/f9_memory.c"
        "extern/libtomcrypt/src/mac/f9/f9_memory_multi.c"
        "extern/libtomcrypt/src/mac/f9/f9_process.c"
        "extern/libtomcrypt/src/mac/f9/f9_test.c"
        "extern/libtomcrypt/src/mac/hmac/hmac_done.c"
        "extern/libtomcrypt/src/mac/hmac/hmac_file.c"
        "extern/libtomcrypt/src/mac/hmac/hmac_init.c"
        "extern/libtomcrypt/src/mac/hmac/hmac_memory.c"
        "extern/libtomcrypt/src/mac/hmac/hmac_memory_multi.c"
        "extern/libtomcrypt/src/mac/hmac/hmac_process.c"
        "extern/libtomcrypt/src/mac/hmac/hmac_test.c"
        "extern/libtomcrypt/src/mac/omac/omac_done.c"
        "extern/libtomcrypt/src/mac/omac/omac_file.c"
        "extern/libtomcrypt/src/mac/omac/omac_init.c"
        "extern/libtomcrypt/src/mac/omac/omac_memory.c"
        "extern/libtomcrypt/src/mac/omac/omac_memory_multi.c"
        "extern/libtomcrypt/src/mac/omac/omac_process.c"
        "extern/libtomcrypt/src/mac/omac/omac_test.c"
        "extern/libtomcrypt/src/mac/pelican/pelican.c"
        "extern/libtomcrypt/src/mac/pelican/pelican_memory.c"
        "extern/libtomcrypt/src/mac/pelican/pelican_test.c"
        "extern/libtomcrypt/src/mac/pmac/pmac_done.c"
        "extern/libtomcrypt/src/mac/pmac/pmac_file.c"
        "extern/libtomcrypt/src/mac/pmac/pmac_init.c"
        "extern/libtomcrypt/src/mac/pmac/pmac_memory.c"
        "extern/libtomcrypt/src/mac/pmac/pmac_memory_multi.c"
        "extern/libtomcrypt/src/mac/pmac/pmac_ntz.c"
        "extern/libtomcrypt/src/mac/pmac/pmac_process.c"
        "extern/libtomcrypt/src/mac/pmac/pmac_shift_xor.c"
        "extern/libtomcrypt/src/mac/pmac/pmac_test.c"
        "extern/libtomcrypt/src/mac/poly1305/poly1305.c"
        "extern/libtomcrypt/src/mac/poly1305/poly1305_file.c"
        "extern/libtomcrypt/src/mac/poly1305/poly1305_memory.c"
        "extern/libtomcrypt/src/mac/poly1305/poly1305_memory_multi.c"
        "extern/libtomcrypt/src/mac/poly1305/poly1305_test.c"
        "extern/libtomcrypt/src/mac/xcbc/xcbc_done.c"
        "extern/libtomcrypt/src/mac/xcbc/xcbc_file.c"
        "extern/libtomcrypt/src/mac/xcbc/xcbc_init.c"
        "extern/libtomcrypt/src/mac/xcbc/xcbc_memory.c"
        "extern/libtomcrypt/src/mac/xcbc/xcbc_memory_multi.c"
        "extern/libtomcrypt/src/mac/xcbc/xcbc_process.c"
        "extern/libtomcrypt/src/mac/xcbc/xcbc_test.c"
        "extern/libtomcrypt/src/math/fp/ltc_ecc_fp_mulmod.c"
        "extern/libtomcrypt/src/math/gmp_desc.c"
        "extern/libtomcrypt/src/math/ltm_desc.c"
        "extern/libtomcrypt/src/math/multi.c"
        "extern/libtomcrypt/src/math/radix_to_bin.c"
        "extern/libtomcrypt/src/math/rand_bn.c"
        "extern/libtomcrypt/src/math/rand_prime.c"
        "extern/libtomcrypt/src/math/tfm_desc.c"
        "extern/libtomcrypt/src/misc/adler32.c"
        "extern/libtomcrypt/src/misc/base64/base64_decode.c"
        "extern/libtomcrypt/src/misc/base64/base64_encode.c"
        "extern/libtomcrypt/src/misc/burn_stack.c"
        "extern/libtomcrypt/src/misc/compare_testvector.c"
        "extern/libtomcrypt/src/misc/crc32.c"
        "extern/libtomcrypt/src/misc/crypt/crypt.c"
        "extern/libtomcrypt/src/misc/crypt/crypt_argchk.c"
        "extern/libtomcrypt/src/misc/crypt/crypt_cipher_descriptor.c"
        "extern/libtomcrypt/src/misc/crypt/crypt_cipher_is_valid.c"
        "extern/libtomcrypt/src/misc/crypt/crypt_constants.c"
        "extern/libtomcrypt/src/misc/crypt/crypt_find_cipher.c"
        "extern/libtomcrypt/src/misc/crypt/crypt_find_cipher_any.c"
        "extern/libtomcrypt/src/misc/crypt/crypt_find_cipher_id.c"
        "extern/libtomcrypt/src/misc/crypt/crypt_find_hash.c"
        "extern/libtomcrypt/src/misc/crypt/crypt_find_hash_any.c"
        "extern/libtomcrypt/src/misc/crypt/crypt_find_hash_id.c"
        "extern/libtomcrypt/src/misc/crypt/crypt_find_hash_oid.c"
        "extern/libtomcrypt/src/misc/crypt/crypt_find_prng.c"
        "extern/libtomcrypt/src/misc/crypt/crypt_fsa.c"
        "extern/libtomcrypt/src/misc/crypt/crypt_hash_descriptor.c"
        "extern/libtomcrypt/src/misc/crypt/crypt_hash_is_valid.c"
        "extern/libtomcrypt/src/misc/crypt/crypt_inits.c"
        "extern/libtomcrypt/src/misc/crypt/crypt_ltc_mp_descriptor.c"
        "extern/libtomcrypt/src/misc/crypt/crypt_prng_descriptor.c"
        "extern/libtomcrypt/src/misc/crypt/crypt_prng_is_valid.c"
        "extern/libtomcrypt/src/misc/crypt/crypt_prng_rng_descriptor.c"
        "extern/libtomcrypt/src/misc/crypt/crypt_register_all_ciphers.c"
        "extern/libtomcrypt/src/misc/crypt/crypt_register_all_hashes.c"
        "extern/libtomcrypt/src/misc/crypt/crypt_register_all_prngs.c"
        "extern/libtomcrypt/src/misc/crypt/crypt_register_cipher.c"
        "extern/libtomcrypt/src/misc/crypt/crypt_register_hash.c"
        "extern/libtomcrypt/src/misc/crypt/crypt_register_prng.c"
        "extern/libtomcrypt/src/misc/crypt/crypt_sizes.c"
        "extern/libtomcrypt/src/misc/crypt/crypt_unregister_cipher.c"
        "extern/libtomcrypt/src/misc/crypt/crypt_unregister_hash.c"
        "extern/libtomcrypt/src/misc/crypt/crypt_unregister_prng.c"
        "extern/libtomcrypt/src/misc/error_to_string.c"
        "extern/libtomcrypt/src/misc/hkdf/hkdf.c"
        "extern/libtomcrypt/src/misc/hkdf/hkdf_test.c"
        "extern/libtomcrypt/src/misc/mem_neq.c"
        "extern/libtomcrypt/src/misc/pkcs5/pkcs_5_1.c"
        "extern/libtomcrypt/src/misc/pkcs5/pkcs_5_2.c"
        "extern/libtomcrypt/src/misc/pkcs5/pkcs_5_test.c"
        "extern/libtomcrypt/src/misc/pk_get_oid.c"
        "extern/libtomcrypt/src/misc/zeromem.c"
        "extern/libtomcrypt/src/modes/cbc/cbc_decrypt.c"
        "extern/libtomcrypt/src/modes/cbc/cbc_done.c"
        "extern/libtomcrypt/src/modes/cbc/cbc_encrypt.c"
        "extern/libtomcrypt/src/modes/cbc/cbc_getiv.c"
        "extern/libtomcrypt/src/modes/cbc/cbc_setiv.c"
        "extern/libtomcrypt/src/modes/cbc/cbc_start.c"
        "extern/libtomcrypt/src/modes/cfb/cfb_decrypt.c"
        "extern/libtomcrypt/src/modes/cfb/cfb_done.c"
        "extern/libtomcrypt/src/modes/cfb/cfb_encrypt.c"
        "extern/libtomcrypt/src/modes/cfb/cfb_getiv.c"
        "extern/libtomcrypt/src/modes/cfb/cfb_setiv.c"
        "extern/libtomcrypt/src/modes/cfb/cfb_start.c"
        "extern/libtomcrypt/src/modes/ctr/ctr_decrypt.c"
        "extern/libtomcrypt/src/modes/ctr/ctr_done.c"
        "extern/libtomcrypt/src/modes/ctr/ctr_encrypt.c"
        "extern/libtomcrypt/src/modes/ctr/ctr_getiv.c"
        "extern/libtomcrypt/src/modes/ctr/ctr_setiv.c"
        "extern/libtomcrypt/src/modes/ctr/ctr_start.c"
        "extern/libtomcrypt/src/modes/ctr/ctr_test.c"
        "extern/libtomcrypt/src/modes/ecb/ecb_decrypt.c"
        "extern/libtomcrypt/src/modes/ecb/ecb_done.c"
        "extern/libtomcrypt/src/modes/ecb/ecb_encrypt.c"
        "extern/libtomcrypt/src/modes/ecb/ecb_start.c"
        "extern/libtomcrypt/src/modes/f8/f8_decrypt.c"
        "extern/libtomcrypt/src/modes/f8/f8_done.c"
        "extern/libtomcrypt/src/modes/f8/f8_encrypt.c"
        "extern/libtomcrypt/src/modes/f8/f8_getiv.c"
        "extern/libtomcrypt/src/modes/f8/f8_setiv.c"
        "extern/libtomcrypt/src/modes/f8/f8_start.c"
        "extern/libtomcrypt/src/modes/f8/f8_test_mode.c"
        "extern/libtomcrypt/src/modes/lrw/lrw_decrypt.c"
        "extern/libtomcrypt/src/modes/lrw/lrw_done.c"
        "extern/libtomcrypt/src/modes/lrw/lrw_encrypt.c"
        "extern/libtomcrypt/src/modes/lrw/lrw_getiv.c"
        "extern/libtomcrypt/src/modes/lrw/lrw_process.c"
        "extern/libtomcrypt/src/modes/lrw/lrw_setiv.c"
        "extern/libtomcrypt/src/modes/lrw/lrw_start.c"
        "extern/libtomcrypt/src/modes/lrw/lrw_test.c"
        "extern/libtomcrypt/src/modes/ofb/ofb_decrypt.c"
        "extern/libtomcrypt/src/modes/ofb/ofb_done.c"
        "extern/libtomcrypt/src/modes/ofb/ofb_encrypt.c"
        "extern/libtomcrypt/src/modes/ofb/ofb_getiv.c"
        "extern/libtomcrypt/src/modes/ofb/ofb_setiv.c"
        "extern/libtomcrypt/src/modes/ofb/ofb_start.c"
        "extern/libtomcrypt/src/modes/xts/xts_decrypt.c"
        "extern/libtomcrypt/src/modes/xts/xts_done.c"
        "extern/libtomcrypt/src/modes/xts/xts_encrypt.c"
        "extern/libtomcrypt/src/modes/xts/xts_init.c"
        "extern/libtomcrypt/src/modes/xts/xts_mult_x.c"
        "extern/libtomcrypt/src/modes/xts/xts_test.c"
        "extern/libtomcrypt/src/pk/asn1/der/bit/der_decode_bit_string.c"
        "extern/libtomcrypt/src/pk/asn1/der/bit/der_decode_raw_bit_string.c"
        "extern/libtomcrypt/src/pk/asn1/der/bit/der_encode_bit_string.c"
        "extern/libtomcrypt/src/pk/asn1/der/bit/der_encode_raw_bit_string.c"
        "extern/libtomcrypt/src/pk/asn1/der/bit/der_length_bit_string.c"
        "extern/libtomcrypt/src/pk/asn1/der/boolean/der_decode_boolean.c"
        "extern/libtomcrypt/src/pk/asn1/der/boolean/der_encode_boolean.c"
        "extern/libtomcrypt/src/pk/asn1/der/boolean/der_length_boolean.c"
        "extern/libtomcrypt/src/pk/asn1/der/choice/der_decode_choice.c"
        "extern/libtomcrypt/src/pk/asn1/der/generalizedtime/der_decode_generalizedtime.c"
        "extern/libtomcrypt/src/pk/asn1/der/generalizedtime/der_encode_generalizedtime.c"
        "extern/libtomcrypt/src/pk/asn1/der/generalizedtime/der_length_generalizedtime.c"
        "extern/libtomcrypt/src/pk/asn1/der/ia5/der_decode_ia5_string.c"
        "extern/libtomcrypt/src/pk/asn1/der/ia5/der_encode_ia5_string.c"
        "extern/libtomcrypt/src/pk/asn1/der/ia5/der_length_ia5_string.c"
        "extern/libtomcrypt/src/pk/asn1/der/integer/der_decode_integer.c"
        "extern/libtomcrypt/src/pk/asn1/der/integer/der_encode_integer.c"
        "extern/libtomcrypt/src/pk/asn1/der/integer/der_length_integer.c"
        "extern/libtomcrypt/src/pk/asn1/der/object_identifier/der_decode_object_identifier.c"
        "extern/libtomcrypt/src/pk/asn1/der/object_identifier/der_encode_object_identifier.c"
        "extern/libtomcrypt/src/pk/asn1/der/object_identifier/der_length_object_identifier.c"
        "extern/libtomcrypt/src/pk/asn1/der/octet/der_decode_octet_string.c"
        "extern/libtomcrypt/src/pk/asn1/der/octet/der_encode_octet_string.c"
        "extern/libtomcrypt/src/pk/asn1/der/octet/der_length_octet_string.c"
        "extern/libtomcrypt/src/pk/asn1/der/printable_string/der_decode_printable_string.c"
        "extern/libtomcrypt/src/pk/asn1/der/printable_string/der_encode_printable_string.c"
        "extern/libtomcrypt/src/pk/asn1/der/printable_string/der_length_printable_string.c"
        "extern/libtomcrypt/src/pk/asn1/der/sequence/der_decode_sequence_ex.c"
        "extern/libtomcrypt/src/pk/asn1/der/sequence/der_decode_sequence_flexi.c"
        "extern/libtomcrypt/src/pk/asn1/der/sequence/der_decode_sequence_multi.c"
        "extern/libtomcrypt/src/pk/asn1/der/sequence/der_decode_subject_public_key_info.c"
        "extern/libtomcrypt/src/pk/asn1/der/sequence/der_encode_sequence_ex.c"
        "extern/libtomcrypt/src/pk/asn1/der/sequence/der_encode_sequence_multi.c"
        "extern/libtomcrypt/src/pk/asn1/der/sequence/der_encode_subject_public_key_info.c"
        "extern/libtomcrypt/src/pk/asn1/der/sequence/der_length_sequence.c"
        "extern/libtomcrypt/src/pk/asn1/der/sequence/der_sequence_free.c"
        "extern/libtomcrypt/src/pk/asn1/der/sequence/der_sequence_shrink.c"
        "extern/libtomcrypt/src/pk/asn1/der/set/der_encode_set.c"
        "extern/libtomcrypt/src/pk/asn1/der/set/der_encode_setof.c"
        "extern/libtomcrypt/src/pk/asn1/der/short_integer/der_decode_short_integer.c"
        "extern/libtomcrypt/src/pk/asn1/der/short_integer/der_encode_short_integer.c"
        "extern/libtomcrypt/src/pk/asn1/der/short_integer/der_length_short_integer.c"
        "extern/libtomcrypt/src/pk/asn1/der/teletex_string/der_decode_teletex_string.c"
        "extern/libtomcrypt/src/pk/asn1/der/teletex_string/der_length_teletex_string.c"
        "extern/libtomcrypt/src/pk/asn1/der/utctime/der_decode_utctime.c"
        "extern/libtomcrypt/src/pk/asn1/der/utctime/der_encode_utctime.c"
        "extern/libtomcrypt/src/pk/asn1/der/utctime/der_length_utctime.c"
        "extern/libtomcrypt/src/pk/asn1/der/utf8/der_decode_utf8_string.c"
        "extern/libtomcrypt/src/pk/asn1/der/utf8/der_encode_utf8_string.c"
        "extern/libtomcrypt/src/pk/asn1/der/utf8/der_length_utf8_string.c"
        "extern/libtomcrypt/src/pk/dh/dh.c"
        "extern/libtomcrypt/src/pk/dh/dh_check_pubkey.c"
        "extern/libtomcrypt/src/pk/dh/dh_export.c"
        "extern/libtomcrypt/src/pk/dh/dh_export_key.c"
        "extern/libtomcrypt/src/pk/dh/dh_free.c"
        "extern/libtomcrypt/src/pk/dh/dh_generate_key.c"
        "extern/libtomcrypt/src/pk/dh/dh_import.c"
        "extern/libtomcrypt/src/pk/dh/dh_set.c"
        "extern/libtomcrypt/src/pk/dh/dh_set_pg_dhparam.c"
        "extern/libtomcrypt/src/pk/dh/dh_shared_secret.c"
        "extern/libtomcrypt/src/pk/dsa/dsa_decrypt_key.c"
        "extern/libtomcrypt/src/pk/dsa/dsa_encrypt_key.c"
        "extern/libtomcrypt/src/pk/dsa/dsa_export.c"
        "extern/libtomcrypt/src/pk/dsa/dsa_free.c"
        "extern/libtomcrypt/src/pk/dsa/dsa_generate_key.c"
        "extern/libtomcrypt/src/pk/dsa/dsa_generate_pqg.c"
        "extern/libtomcrypt/src/pk/dsa/dsa_import.c"
        "extern/libtomcrypt/src/pk/dsa/dsa_make_key.c"
        "extern/libtomcrypt/src/pk/dsa/dsa_set.c"
        "extern/libtomcrypt/src/pk/dsa/dsa_set_pqg_dsaparam.c"
        "extern/libtomcrypt/src/pk/dsa/dsa_shared_secret.c"
        "extern/libtomcrypt/src/pk/dsa/dsa_sign_hash.c"
        "extern/libtomcrypt/src/pk/dsa/dsa_verify_hash.c"
        "extern/libtomcrypt/src/pk/dsa/dsa_verify_key.c"
        "extern/libtomcrypt/src/pk/ecc/ecc.c"
        "extern/libtomcrypt/src/pk/ecc/ecc_ansi_x963_export.c"
        "extern/libtomcrypt/src/pk/ecc/ecc_ansi_x963_import.c"
        "extern/libtomcrypt/src/pk/ecc/ecc_decrypt_key.c"
        "extern/libtomcrypt/src/pk/ecc/ecc_encrypt_key.c"
        "extern/libtomcrypt/src/pk/ecc/ecc_export.c"
        "extern/libtomcrypt/src/pk/ecc/ecc_free.c"
        "extern/libtomcrypt/src/pk/ecc/ecc_get_size.c"
        "extern/libtomcrypt/src/pk/ecc/ecc_import.c"
        "extern/libtomcrypt/src/pk/ecc/ecc_make_key.c"
        "extern/libtomcrypt/src/pk/ecc/ecc_shared_secret.c"
        "extern/libtomcrypt/src/pk/ecc/ecc_sign_hash.c"
        "extern/libtomcrypt/src/pk/ecc/ecc_sizes.c"
        "extern/libtomcrypt/src/pk/ecc/ecc_test.c"
        "extern/libtomcrypt/src/pk/ecc/ecc_verify_hash.c"
        "extern/libtomcrypt/src/pk/ecc/ltc_ecc_is_valid_idx.c"
        "extern/libtomcrypt/src/pk/ecc/ltc_ecc_map.c"
        "extern/libtomcrypt/src/pk/ecc/ltc_ecc_mul2add.c"
        "extern/libtomcrypt/src/pk/ecc/ltc_ecc_mulmod.c"
        "extern/libtomcrypt/src/pk/ecc/ltc_ecc_mulmod_timing.c"
        "extern/libtomcrypt/src/pk/ecc/ltc_ecc_points.c"
        "extern/libtomcrypt/src/pk/ecc/ltc_ecc_projective_add_point.c"
        "extern/libtomcrypt/src/pk/ecc/ltc_ecc_projective_dbl_point.c"
        "extern/libtomcrypt/src/pk/katja/katja_decrypt_key.c"
        "extern/libtomcrypt/src/pk/katja/katja_encrypt_key.c"
        "extern/libtomcrypt/src/pk/katja/katja_export.c"
        "extern/libtomcrypt/src/pk/katja/katja_exptmod.c"
        "extern/libtomcrypt/src/pk/katja/katja_free.c"
        "extern/libtomcrypt/src/pk/katja/katja_import.c"
        "extern/libtomcrypt/src/pk/katja/katja_make_key.c"
        "extern/libtomcrypt/src/pk/pkcs1/pkcs_1_i2osp.c"
        "extern/libtomcrypt/src/pk/pkcs1/pkcs_1_mgf1.c"
        "extern/libtomcrypt/src/pk/pkcs1/pkcs_1_oaep_decode.c"
        "extern/libtomcrypt/src/pk/pkcs1/pkcs_1_oaep_encode.c"
        "extern/libtomcrypt/src/pk/pkcs1/pkcs_1_os2ip.c"
        "extern/libtomcrypt/src/pk/pkcs1/pkcs_1_pss_decode.c"
        "extern/libtomcrypt/src/pk/pkcs1/pkcs_1_pss_encode.c"
        "extern/libtomcrypt/src/pk/pkcs1/pkcs_1_v1_5_decode.c"
        "extern/libtomcrypt/src/pk/pkcs1/pkcs_1_v1_5_encode.c"
        "extern/libtomcrypt/src/pk/rsa/rsa_decrypt_key.c"
        "extern/libtomcrypt/src/pk/rsa/rsa_encrypt_key.c"
        "extern/libtomcrypt/src/pk/rsa/rsa_export.c"
        "extern/libtomcrypt/src/pk/rsa/rsa_exptmod.c"
        "extern/libtomcrypt/src/pk/rsa/rsa_free.c"
        "extern/libtomcrypt/src/pk/rsa/rsa_get_size.c"
        "extern/libtomcrypt/src/pk/rsa/rsa_import.c"
        "extern/libtomcrypt/src/pk/rsa/rsa_import_pkcs8.c"
        "extern/libtomcrypt/src/pk/rsa/rsa_import_x509.c"
        "extern/libtomcrypt/src/pk/rsa/rsa_make_key.c"
        "extern/libtomcrypt/src/pk/rsa/rsa_set.c"
        "extern/libtomcrypt/src/pk/rsa/rsa_sign_hash.c"
        "extern/libtomcrypt/src/pk/rsa/rsa_sign_saltlen_get.c"
        "extern/libtomcrypt/src/pk/rsa/rsa_verify_hash.c"
        "extern/libtomcrypt/src/prngs/chacha20.c"
        "extern/libtomcrypt/src/prngs/fortuna.c"
        "extern/libtomcrypt/src/prngs/rc4.c"
        "extern/libtomcrypt/src/prngs/rng_get_bytes.c"
        "extern/libtomcrypt/src/prngs/rng_make_prng.c"
        "extern/libtomcrypt/src/prngs/sober128.c"
        "extern/libtomcrypt/src/prngs/sprng.c"
        "extern/libtomcrypt/src/prngs/yarrow.c"
        "extern/libtomcrypt/src/stream/chacha/chacha_crypt.c"
        "extern/libtomcrypt/src/stream/chacha/chacha_done.c"
        "extern/libtomcrypt/src/stream/chacha/chacha_ivctr32.c"
        "extern/libtomcrypt/src/stream/chacha/chacha_ivctr64.c"
        "extern/libtomcrypt/src/stream/chacha/chacha_keystream.c"
        "extern/libtomcrypt/src/stream/chacha/chacha_setup.c"
        "extern/libtomcrypt/src/stream/chacha/chacha_test.c"
        "extern/libtomcrypt/src/stream/rc4/rc4_stream.c"
        "extern/libtomcrypt/src/stream/rc4/rc4_test.c"
        "extern/libtomcrypt/src/stream/sober128/sober128_stream.c"
        "extern/libtomcrypt/src/stream/sober128/sober128_test.c"
)

################################################################################
# decNumber
################################################################################
fb_add_library(decNumber STATIC COMMON OUTPUT_NAME decnumber)
fb_target_sources(decNumber
    ROOT_PRIVATE
        "extern/decNumber/decSingle.c"
        "extern/decNumber/decContext.c"
        "extern/decNumber/decDouble.c"
        "extern/decNumber/decimal32.c"
        "extern/decNumber/decimal64.c"
        "extern/decNumber/decimal128.c"
        "extern/decNumber/decNumber.c"
        "extern/decNumber/decPacked.c"
        "extern/decNumber/decQuad.c"
)

################################################################################
# ttmath
################################################################################
if(MSVC)
    fb_add_library(libttmath STATIC COMMON OUTPUT_NAME ttmath)
    set_property(TARGET libttmath_common
        PROPERTY
            MSVC_RUNTIME_LIBRARY ""
    )
    fb_target_sources(libttmath
        ROOT_PRIVATE
            "extern/ttmath/ttmathuint_x86_64_msvc.asm"
    )
endif()

################################################################################
# common
################################################################################
fb_add_library(common STATIC COMMON)
fb_target_compile_definitions(common
    PRIVATE
        DEV_BUILD
        SUPERSERVER
)
fb_target_link_libraries(common
    PUBLIC
        libtommath
        libtomcrypt
        decNumber
        $<$<BOOL:${MSVC}>:libttmath>
)
if(WIN32)
    fb_target_link_libraries(common
        PUBLIC
            ws2_32
            mpr
    )
elseif(APPLE)
    fb_target_link_libraries(common
        PRIVATE
            "-framework CoreFoundation"
            "-framework Foundation"
            "-framework Security"
            iconv
            "-L ${FIREBIRD_OUTPUT_DIR}/common"
            ${COMMON_ICU_DEPS}
    )
endif()
fb_target_include_directories(common
    ROOT_PUBLIC
        "src/include"
        "extern/re2"
    PUBLIC
        "${ICU_INC_PATH}"
        $<$<BOOL:${ZLIB_INC_PATH}>:${ZLIB_INC_PATH}>
)
fb_target_sources(common
    PRIVATE
        ${COMMON_ICU_DEPS}
        $<$<BOOL:${ZLIB_INC_PATH}>:${ZLIB_INC_PATH}/zlib.h>

    ROOT_PRIVATE
        "src/include/firebird/IdlFbInterfaces.h"
        "src/include/gen/parse.h"

        "src/common/Auth.cpp"
        "src/common/BigInteger.cpp"
        "src/common/call_service.cpp"
        "src/common/CharSet.cpp"
        "src/common/classes/alloc.cpp"
        "src/common/classes/BaseStream.cpp"
        "src/common/classes/BlobWrapper.cpp"
        "src/common/classes/BlrWriter.cpp"
        "src/common/classes/ClumpletReader.cpp"
        "src/common/classes/ClumpletWriter.cpp"
        "src/common/classes/DbImplementation.cpp"
        "src/common/classes/fb_string.cpp"
        "src/common/classes/Hash.cpp"
        "src/common/classes/ImplementHelper.cpp"
        "src/common/classes/init.cpp"
        "src/common/classes/InternalMessageBuffer.cpp"
        "src/common/classes/locks.cpp"
        "src/common/classes/MetaString.cpp"
        "src/common/classes/MsgPrint.cpp"
        "src/common/classes/NoThrowTimeStamp.cpp"
        "src/common/classes/ParsedList.cpp"
        "src/common/classes/SafeArg.cpp"
        "src/common/classes/semaphore.cpp"
        "src/common/classes/Switches.cpp"
        "src/common/classes/Synchronize.cpp"
        "src/common/classes/SyncObject.cpp"
        "src/common/classes/TempFile.cpp"
        "src/common/classes/TimerImpl.cpp"
        "src/common/classes/timestamp.cpp"
        "src/common/classes/TomCryptHash.cpp"
        "src/common/classes/UserBlob.cpp"
        "src/common/classes/zip.cpp"
        "src/common/config/config.cpp"
        "src/common/config/ConfigCache.cpp"
        "src/common/config/config_file.cpp"
        "src/common/config/dir_list.cpp"
        "src/common/CRC32C.cpp"
        "src/common/cvt.cpp"
        "src/common/db_alias.cpp"
        "src/common/DecFloat.cpp"
        "src/common/dllinst.cpp"
        "src/common/dsc.cpp"
        "src/common/DynamicStrings.cpp"
        "src/common/enc.cpp"
        "src/common/fb_exception.cpp"
        "src/common/Int128.cpp"
        "src/common/IntlParametersBlock.cpp"
        "src/common/IntlUtil.cpp"
        "src/common/isc.cpp"
        "src/common/isc_file.cpp"
        "src/common/isc_sync.cpp"
        "src/common/MsgMetadata.cpp"
        "src/common/MsgUtil.cpp"
        "src/common/pretty.cpp"
        "src/common/ScanDir.cpp"
        "src/common/sdl.cpp"
        "src/common/security.cpp"
        "src/common/sha.cpp"
        "src/common/sha2/sha2.cpp"
        "src/common/SimilarToRegex.cpp"
        "src/common/StatementMetadata.cpp"
        "src/common/StatusArg.cpp"
        "src/common/StatusHolder.cpp"
        "src/common/Task.cpp"
        "src/common/TextType.cpp"
        "src/common/ThreadData.cpp"
        "src/common/ThreadStart.cpp"
        "src/common/TimeZoneUtil.cpp"
        "src/common/Tokens.cpp"
        "src/common/unicode_util.cpp"
        "src/common/utils.cpp"
        "src/common/UtilSvc.cpp"
        "src/common/xdr.cpp"
)
if(WIN32)
    fb_target_sources(common
        ROOT_PRIVATE
            "src/common/os/win32/fbsyslog.cpp"
            "src/common/os/win32/guid.cpp"
            "src/common/os/win32/isc_ipc.cpp"
            "src/common/os/win32/mod_loader.cpp"
            "src/common/os/win32/os_utils.cpp"
            "src/common/os/win32/path_utils.cpp"
    )
elseif(APPLE)
    fb_target_sources(common
        ROOT_PRIVATE
            "src/common/os/posix/divorce.cpp"
            "src/common/os/posix/fbsyslog.cpp"
            "src/common/os/posix/guid.cpp"
            "src/common/os/posix/isc_ipc.cpp"
            "src/common/os/posix/os_utils.cpp"
            "src/common/os/posix/path_utils.cpp"
            "src/common/os/posix/SyncSignals.cpp"
            "src/common/os/darwin/mod_loader.cpp"
            "src/common/os/darwin/mac_utils.m"
    )
endif()
set_source_files_properties(
    "${FIREBIRD_SOURCE_DIR}/src/common/CRC32C.cpp"
    PROPERTIES
        COMPILE_OPTIONS "-msse4.2"
)

################################################################################
# gpre_common
################################################################################
fb_add_library(gpre_common STATIC COMMON)
fb_target_compile_definitions(gpre_common
    PRIVATE
        GPRE_FORTRAN
        GPRE_PASCAL
        GPRE_COBOL
        GPRE_ADA
        SUPERCLIENT
        DEV_BUILD
)
fb_target_include_directories(gpre_common
    ROOT_PUBLIC
        "src/include"
    ROOT_PRIVATE
        "src/include/gen"
)
fb_target_sources(gpre_common
    ROOT_PRIVATE
        "src/include/firebird/IdlFbInterfaces.h"

        "src/gpre/cmd.cpp"
        "src/gpre/cme.cpp"
        "src/gpre/cmp.cpp"
        "src/gpre/c_cxx.cpp"
        "src/gpre/exp.cpp"
        "src/gpre/gpre.cpp"
        "src/gpre/hsh.cpp"
        "src/gpre/int_cxx.cpp"
        "src/gpre/jrdmet.cpp"
        "src/gpre/languages/ada.cpp"
        "src/gpre/languages/cob.cpp"
        "src/gpre/languages/fbrmclib.cpp"
        "src/gpre/languages/ftn.cpp"
        "src/gpre/languages/pas.cpp"
        "src/gpre/languages/rmc.cpp"
        "src/gpre/movg.cpp"
        "src/gpre/msc.cpp"
        "src/gpre/obj_cxx.cpp"
        "src/gpre/par.cpp"
        "src/gpre/pat.cpp"
        "src/gpre/sqe.cpp"
        "src/gpre/sql.cpp"
)

################################################################################
# gpre
################################################################################
fb_add_executable(gpre BOOT MAIN)
fb_target_resources(gpre)
fb_target_compile_definitions(gpre
    PRIVATE
        DEV_BUILD
        SUPERCLIENT
        CLIENT
)
fb_target_link_libraries(gpre
    PRIVATE
        common
        gpre_common
)
fb_target_include_directories(gpre
    ROOT_PRIVATE
        "src/include"
#    PRIVATE
#        "${ICU_INC_PATH}"
)
# gpreはbootとmainで内容が異なる
# boot
target_sources(gpre_boot
    PRIVATE
        "${FIREBIRD_SOURCE_DIR}/src/gpre/boot/gpre_meta_boot.cpp"
        "${FIREBIRD_SOURCE_DIR}/src/yvalve/gds.cpp"
)
add_custom_command(
    OUTPUT  "${FIREBIRD_EXEC_DIR}/boot${LODIR_BIN}/gpre_boot${CMAKE_EXECUTABLE_SUFFIX}"
    DEPENDS gpre_boot
    COMMAND ${CMAKE_COMMAND} -E copy_if_different "$<TARGET_FILE:gpre_boot>" "${FIREBIRD_EXEC_DIR}/boot${LODIR_BIN}/gpre_boot${CMAKE_EXECUTABLE_SUFFIX}"
    VERBATIM
)

# main
target_compile_definitions(gpre_main
    PRIVATE
        GPRE_FORTRAN
        GPRE_PASCAL
        GPRE_COBOL
        GPRE_ADA
)
target_link_libraries(gpre_main
    PRIVATE
        yvalve_boot
)
target_sources(gpre_main
    PRIVATE
        "${FIREBIRD_GEN_DIR}/boot/gpre/std/gpre_meta.cpp"
)
add_custom_command(
    OUTPUT  "${FIREBIRD_EXEC_DIR}/boot${LODIR_BIN}/gpre${CMAKE_EXECUTABLE_SUFFIX}"
    DEPENDS gpre_main
    COMMAND ${CMAKE_COMMAND} -E copy_if_different "$<TARGET_FILE:gpre_main>" "${FIREBIRD_EXEC_DIR}/boot${LODIR_BIN}/gpre${CMAKE_EXECUTABLE_SUFFIX}"
    VERBATIM
)

################################################################################
# alice
################################################################################
fb_add_library(alice STATIC BOOT MAIN)
fb_target_compile_definitions(alice
    PRIVATE
        DEV_BUILD
)
fb_target_include_directories(alice
    ROOT_PRIVATE
        "src/include"
)
fb_target_sources(alice
    GEN_PRIVATE
        "alice/alice_meta.cpp"

    ROOT_PRIVATE
        "src/alice/alice.cpp"
        "src/alice/exe.cpp"
        "src/alice/tdr.cpp"
)

################################################################################
# burp
################################################################################
fb_add_library(burp STATIC BOOT MAIN)
fb_target_compile_definitions(burp
    PRIVATE
        DEV_BUILD
)
fb_target_include_directories(burp
    ROOT_PRIVATE
        "src/include"
        "extern/re2"
    PRIVATE
        $<$<BOOL:${ZLIB_INC_PATH}>:${ZLIB_INC_PATH}>
)
fb_target_sources(burp
    GEN_PRIVATE
        "burp/backup.cpp"
        "burp/OdsDetection.cpp"
        "burp/restore.cpp"

    PRIVATE
        $<$<BOOL:${ZLIB_INC_PATH}>:${ZLIB_INC_PATH}/zlib.h>

    ROOT_PRIVATE
        "src/burp/burp.cpp"
        "src/burp/BurpTasks.cpp"
        "src/burp/canonical.cpp"
        "src/burp/misc.cpp"
        "src/burp/mvol.cpp"
)

################################################################################
# remote
################################################################################
fb_add_library(remote STATIC BOOT MAIN)
fb_target_compile_definitions(remote
    PRIVATE
        DEV_BUILD
)
fb_target_include_directories(remote
    ROOT_PRIVATE
        "src/include"
        "extern/libtommath"
    PRIVATE
        $<$<BOOL:${ZLIB_INC_PATH}>:${ZLIB_INC_PATH}>
)
fb_target_sources(remote
    PRIVATE
        $<$<BOOL:${ZLIB_INC_PATH}>:${ZLIB_INC_PATH}/zlib.h>

    ROOT_PRIVATE
        "src/auth/SecureRemotePassword/srp.cpp"
        "src/remote/inet.cpp"
        "src/remote/merge.cpp"
        "src/remote/parser.cpp"
        "src/remote/protocol.cpp"
        "src/remote/remote.cpp"
)
if(WIN32)
    fb_target_sources(remote
        ROOT_PRIVATE
            "src/remote/os/win32/xnet.cpp"
            "src/auth/trusted/AuthSspi.cpp"
        )
endif()

################################################################################
# yvalve
################################################################################
fb_add_library(yvalve SHARED BOOT MAIN
    LAYOUT_DIR ${LODIR_LIB}
    OUTPUT_NAME fbclient
)
fb_target_symbols(yvalve
    SYMBOL WIN32 "${FIREBIRD_SOURCE_DIR}/builds/win32/defs/firebird.def"
    SYMBOL UNIX  "${FIREBIRD_GEN_DIR}/common/firebird.vers"
)
fb_target_resources(yvalve)
fb_target_compile_definitions(yvalve
    PRIVATE
        SUPERSERVER
        DEV_BUILD
)
fb_target_link_libraries(yvalve
    PRIVATE
        common
        remote
)
fb_target_include_directories(yvalve
    ROOT_PRIVATE
        "extern/libtommath"
        "src/include/gen"
#        $<$<BOOL:${ZLIB_INC_PATH}>:${ZLIB_INC_PATH}>
)
fb_target_sources(yvalve
    ROOT_PRIVATE
#        $<$<BOOL:${ZLIB_INC_PATH}>:${ZLIB_INC_PATH}/zlib.h>

        "src/auth/SecureRemotePassword/client/SrpClient.cpp"
        "src/auth/SecurityDatabase/LegacyClient.cpp"
        "src/plugins/crypt/arc4/Arc4.cpp"
        "src/remote/client/BlrFromMessage.cpp"
        "src/remote/client/interface.cpp"
        "src/yvalve/alt.cpp"
        "src/yvalve/array.cpp"
        "src/yvalve/blob.cpp"
        "src/yvalve/DistributedTransaction.cpp"
        "src/yvalve/gds.cpp"
        "src/yvalve/keywordsStub.cpp"
        "src/yvalve/MasterImplementation.cpp"
        "src/yvalve/perf.cpp"
        "src/yvalve/PluginManager.cpp"
        "src/yvalve/preparse.cpp"
        "src/yvalve/user_dsql.cpp"
        "src/yvalve/utl.cpp"
        "src/yvalve/why.cpp"
)
if(WIN32)
    fb_target_sources(yvalve
        ROOT_PRIVATE
            "src/jrd/os/win32/ibinitdll.cpp"
            "src/yvalve/config/os/win32/config_root.cpp"
    )
elseif(APPLE)
    fb_target_sources(yvalve
        ROOT_PRIVATE
            "src/yvalve/config/os/posix/binreloc.c"
            "src/yvalve/config/os/darwin/config_root.cpp"
    )
endif()

################################################################################
# engine_static
################################################################################
fb_add_library(engine_static STATIC BOOT MAIN)
fb_target_compile_definitions(engine_static
    PRIVATE
        SUPERSERVER
        DEV_BUILD
        NAMESPACE=Vulcan
        CDS_BUILD_STATIC_LIB
)
fb_target_link_libraries(engine_static
    PRIVATE
        cds-s
)
fb_target_include_directories(engine_static
    PUBLIC
        "${ICU_INC_PATH}"
    ROOT_PRIVATE
        "src/include"
        "src/jrd"
        "extern/libtomcrypt/src/headers"
        "extern/re2"
)
fb_target_sources(engine_static
    GEN_PRIVATE
        "dsql/DdlNodes.cpp"
        "dsql/metd.cpp"
        "dsql/PackageNodes.cpp"
        "jrd/dfw.cpp"
        "jrd/dpm.cpp"
        "jrd/dyn_util.cpp"
        "jrd/fun.cpp"
        "jrd/Function.cpp"
        "jrd/grant.cpp"
        "jrd/ini.cpp"
        "jrd/met.cpp"
        "jrd/scl.cpp"
        "utilities/gstat/dba.cpp"

    ROOT_PRIVATE
        "src/dsql/AggNodes.cpp"
        "src/dsql/BlrDebugWriter.cpp"
        "src/dsql/BoolNodes.cpp"
        "src/dsql/ddl.cpp"
        "src/dsql/dsql.cpp"
        "src/dsql/DsqlBatch.cpp"
        "src/dsql/DsqlCompilerScratch.cpp"
        "src/dsql/DsqlCursor.cpp"
        "src/dsql/DSqlDataTypeUtil.cpp"
        "src/dsql/DsqlRequests.cpp"
        "src/dsql/DsqlStatementCache.cpp"
        "src/dsql/DsqlStatements.cpp"
        "src/dsql/errd.cpp"
        "src/dsql/ExprNodes.cpp"
        "src/dsql/gen.cpp"
        "src/dsql/Keywords.cpp"
        "src/dsql/make.cpp"
        "src/dsql/movd.cpp"
        "src/dsql/parse.cpp"
        "src/dsql/Parser.cpp"
        "src/dsql/pass1.cpp"
        "src/dsql/StmtNodes.cpp"
        "src/dsql/utld.cpp"
        "src/dsql/WinNodes.cpp"
        "src/jrd/Attachment.cpp"
        "src/jrd/blb.cpp"
        "src/jrd/blob_filter.cpp"
        "src/jrd/BlobUtil.cpp"
        "src/jrd/btn.cpp"
        "src/jrd/btr.cpp"
        "src/jrd/builtin.cpp"
        "src/jrd/cch.cpp"
        "src/jrd/cmp.cpp"
        "src/jrd/Coercion.cpp"
        "src/jrd/Collation.cpp"
        "src/jrd/ConfigTable.cpp"
        "src/jrd/CryptoManager.cpp"
        "src/jrd/cvt.cpp"
        "src/jrd/cvt2.cpp"
        "src/jrd/Database.cpp"
        "src/jrd/DataTypeUtil.cpp"
        "src/jrd/DbCreators.cpp"
        "src/jrd/DebugInterface.cpp"
        "src/jrd/err.cpp"
        "src/jrd/event.cpp"
        "src/jrd/evl.cpp"
        "src/jrd/exe.cpp"
        "src/jrd/ext.cpp"
        "src/jrd/extds/ExtDS.cpp"
        "src/jrd/extds/InternalDS.cpp"
        "src/jrd/extds/IscDS.cpp"
        "src/jrd/extds/ValidatePassword.cpp"
        "src/jrd/ExtEngineManager.cpp"
        "src/jrd/filters.cpp"
        "src/jrd/flu.cpp"
        "src/jrd/GarbageCollector.cpp"
        "src/jrd/GlobalRWLock.cpp"
        "src/jrd/idx.cpp"
        "src/jrd/inf.cpp"
        "src/jrd/InitCDSLib.cpp"
        "src/jrd/intl.cpp"
        "src/jrd/IntlManager.cpp"
        "src/jrd/intl_builtin.cpp"
        "src/jrd/jrd.cpp"
        "src/jrd/KeywordsTable.cpp"
        "src/jrd/lck.cpp"
        "src/jrd/Mapping.cpp"
        "src/jrd/MetaName.cpp"
        "src/jrd/Monitoring.cpp"
        "src/jrd/mov.cpp"
        "src/jrd/nbak.cpp"
        "src/jrd/nodebug.cpp"
        "src/jrd/ods.cpp"
        "src/jrd/optimizer/Optimizer.cpp"
        "src/jrd/optimizer/Retrieval.cpp"
        "src/jrd/optimizer/InnerJoin.cpp"
        "src/jrd/pag.cpp"
        "src/jrd/par.cpp"
        "src/jrd/PreparedStatement.cpp"
        "src/jrd/ProfilerManager.cpp"
        "src/jrd/RandomGenerator.cpp"
        "src/jrd/RecordBuffer.cpp"
        "src/jrd/RecordSourceNodes.cpp"
        "src/jrd/recsrc/AggregatedStream.cpp"
        "src/jrd/recsrc/BitmapTableScan.cpp"
        "src/jrd/recsrc/BufferedStream.cpp"
        "src/jrd/recsrc/ConditionalStream.cpp"
        "src/jrd/recsrc/Cursor.cpp"
        "src/jrd/recsrc/ExternalTableScan.cpp"
        "src/jrd/recsrc/FilteredStream.cpp"
        "src/jrd/recsrc/FirstRowsStream.cpp"
        "src/jrd/recsrc/FullOuterJoin.cpp"
        "src/jrd/recsrc/FullTableScan.cpp"
        "src/jrd/recsrc/HashJoin.cpp"
        "src/jrd/recsrc/IndexTableScan.cpp"
        "src/jrd/recsrc/LocalTableStream.cpp"
        "src/jrd/recsrc/LockedStream.cpp"
        "src/jrd/recsrc/MergeJoin.cpp"
        "src/jrd/recsrc/NestedLoopJoin.cpp"
        "src/jrd/recsrc/ProcedureScan.cpp"
        "src/jrd/recsrc/RecordSource.cpp"
        "src/jrd/recsrc/RecursiveStream.cpp"
        "src/jrd/recsrc/SingularStream.cpp"
        "src/jrd/recsrc/SkipRowsStream.cpp"
        "src/jrd/recsrc/SortedStream.cpp"
        "src/jrd/recsrc/Union.cpp"
        "src/jrd/recsrc/VirtualTableScan.cpp"
        "src/jrd/recsrc/WindowedStream.cpp"
        "src/jrd/replication/Applier.cpp"
        "src/jrd/replication/ChangeLog.cpp"
        "src/jrd/replication/Config.cpp"
        "src/jrd/replication/Manager.cpp"
        "src/jrd/replication/Publisher.cpp"
        "src/jrd/replication/Replicator.cpp"
        "src/jrd/replication/Utils.cpp"
        "src/jrd/Relation.cpp"
        "src/jrd/ResultSet.cpp"
        "src/jrd/rlck.cpp"
        "src/jrd/Routine.cpp"
        "src/jrd/rpb_chain.cpp"
        "src/jrd/RuntimeStatistics.cpp"
        "src/jrd/Savepoint.cpp"
        "src/jrd/sdw.cpp"
        "src/jrd/shut.cpp"
        "src/jrd/sort.cpp"
        "src/jrd/sqz.cpp"
        "src/jrd/Statement.cpp"
        "src/jrd/svc.cpp"
        "src/jrd/SysFunction.cpp"
        "src/jrd/SystemPackages.cpp"
        "src/jrd/TempSpace.cpp"
        "src/jrd/TimeZone.cpp"
        "src/jrd/tpc.cpp"
        "src/jrd/tra.cpp"
        "src/jrd/trace/TraceCmdLine.cpp"
        "src/jrd/trace/TraceConfigStorage.cpp"
        "src/jrd/trace/TraceLog.cpp"
        "src/jrd/trace/TraceManager.cpp"
        "src/jrd/trace/TraceObjects.cpp"
        "src/jrd/trace/TraceService.cpp"
        "src/jrd/UserManagement.cpp"
        "src/jrd/validation.cpp"
        "src/jrd/vio.cpp"
        "src/jrd/VirtualTable.cpp"
        "src/jrd/WorkerAttachment.cpp"
        "src/lock/lock.cpp"
        "src/utilities/gsec/gsec.cpp"
        "src/utilities/gstat/ppg.cpp"
        "src/utilities/nbackup/nbackup.cpp"
)
if(WIN32)
    fb_target_sources(engine_static
        ROOT_PRIVATE
            "src/jrd/os/win32/winnt.cpp"
    )
elseif(APPLE)
    fb_target_sources(engine_static
        ROOT_PRIVATE
            "src/jrd/os/posix/unix.cpp"
    )
endif()

################################################################################
# engine
################################################################################
fb_add_library(engine SHARED BOOT MAIN
    LAYOUT_DIR ${LODIR_PLUGINS}
    OUTPUT_NAME engine13
)
fb_target_symbols(engine
    SYMBOL WIN32 "${FIREBIRD_SOURCE_DIR}/builds/win32/defs/plugin.def"
    SYMBOL UNIX  "${FIREBIRD_GEN_DIR}/common/fbplugin.vers"
)
fb_target_resources(engine)
fb_target_compile_definitions(engine
    PRIVATE
        SUPERSERVER
        DEV_BUILD
        NAMESPACE=Vulcan
)
fb_target_link_libraries(engine
    PRIVATE
        common
        re2
    GEN_PRIVATE
        engine_static
        alice
        burp
        yvalve
)

################################################################################
# gbak
################################################################################
fb_add_executable(gbak MAIN
    LAYOUT_DIR ${LODIR_BIN}
    GEN_DEPENDS
        yvalve
        engine
)
fb_target_resources(gbak)
fb_target_compile_definitions(gbak
    PRIVATE
        SUPERCLIENT
        DEV_BUILD
)
fb_target_link_libraries(gbak
    PRIVATE
        common
        re2
    GEN_PRIVATE
        burp
        yvalve
)
fb_target_sources(gbak
    ROOT_PRIVATE
        "src/burp/main/burpMain.cpp"
)

################################################################################
# isql
################################################################################
fb_add_executable(isql BOOT MAIN
    LAYOUT_DIR ${LODIR_BIN}
    GEN_DEPENDS
        yvalve
        engine
)
fb_target_symbols(isql
    SYMBOL UNIX "${FIREBIRD_GEN_DIR}/common/empty.vers"
)
fb_target_resources(isql)
fb_target_compile_definitions(isql
    PRIVATE
        SUPERCLIENT
        DEV_BUILD
)
fb_target_link_libraries(isql
    PRIVATE
        common
    GEN_PRIVATE
        yvalve
)
fb_target_sources(isql
    GEN_PRIVATE
        "isql/extract.cpp"
        "isql/isql.cpp"
        "isql/show.cpp"

    ROOT_PRIVATE
        "src/isql/ColList.cpp"
        "src/isql/Extender.cpp"
#        "src/common/fb_exception.cpp"
        "src/isql/InputDevices.cpp"
        "src/isql/iutils.cpp"
        "src/isql/OptionsBase.cpp"
)

################################################################################
# build_msg
################################################################################
fb_add_executable(build_msg MAIN
    LAYOUT_DIR ${LODIR_BIN}
)
fb_target_resources(build_msg)
fb_target_compile_definitions(build_msg
    PRIVATE
        SUPERCLIENT
)
fb_target_include_directories(build_msg
    ROOT_PRIVATE
        "src/include"
)
fb_target_sources(build_msg
    ROOT_PRIVATE
        "src/msgs/build_file.cpp"
)

################################################################################
# fb_lock_print
################################################################################
fb_add_executable(fb_lock_print MAIN
    LAYOUT_DIR ${LODIR_BIN}
)
fb_target_resources(fb_lock_print)
fb_target_compile_definitions(fb_lock_print
    PRIVATE
        CLIENT
        SUPERCLIENT
        DEV_BUILD
)
fb_target_link_libraries(fb_lock_print
    PRIVATE
        common
    GEN_PRIVATE
        yvalve
)
fb_target_sources(fb_lock_print
    ROOT_PRIVATE
        "src/lock/print.cpp"
)

################################################################################
# fbguard
################################################################################
if(WIN32)
    fb_add_executable(fbguard WIN32 MAIN)
    fb_target_compile_definitions(fbguard
        PRIVATE
            SUPERCLIENT
            DEV_BUILD
    )
    fb_target_link_libraries(fbguard
        PRIVATE
            version
            comctl32
            common
        GEN_PRIVATE
            yvalve
    )
    fb_target_sources(fbguard
        ROOT_PRIVATE
            "src/iscguard/cntl_guard.cpp"
            "src/iscguard/iscguard.cpp"
            "src/remote/server/os/win32/chop.cpp"

            "src/iscguard/iscguard.rc"
    )
else()
    fb_add_executable(fbguard MAIN)
    fb_target_compile_definitions(fbguard
        PRIVATE
            SUPERCLIENT
            DEV_BUILD
    )
    fb_target_link_libraries(fbguard
        PRIVATE
            common
        GEN_PRIVATE
            yvalve
    )
    fb_target_sources(fbguard
        ROOT_PRIVATE
            "src/utilities/guard/guard.cpp"
            "src/utilities/guard/util.cpp"
    )
endif()

################################################################################
# fbserver
################################################################################
fb_add_executable(fbserver WIN32 MAIN
    LAYOUT_DIR ${LODIR_BIN}
    OUTPUT_NAME firebird
)
fb_target_compile_definitions(fbserver
    PRIVATE
        SUPERSERVER
        DEV_BUILD
)
fb_target_link_libraries(fbserver
    PRIVATE
        common
        remote
    GEN_PRIVATE
        yvalve
)
fb_target_include_directories(fbserver
    ROOT_PRIVATE
#        $<$<BOOL:${ZLIB_INC_PATH}>:${ZLIB_INC_PATH}>
)
fb_target_sources(fbserver
    ROOT_PRIVATE
        "src/auth/SecDbCache.cpp"
        "src/auth/SecureRemotePassword/server/SrpServer.cpp"
        "src/remote/server/server.cpp"
        "src/remote/server/ReplServer.cpp"
        "src/jrd/replication/Config.cpp"
        "src/jrd/replication/Utils.cpp"
)
if(WIN32)
    fb_target_link_libraries(fbserver
        PRIVATE
            comctl32
    )
    fb_target_sources(fbserver
        ROOT_PRIVATE
            "src/remote/server/os/win32/chop.cpp"
            "src/remote/server/os/win32/cntl.cpp"
            "src/remote/server/os/win32/property.cpp"
            "src/remote/server/os/win32/srvr_w32.cpp"
            "src/remote/server/os/win32/window.cpp"

            "src/remote/server/os/win32/window.rc"
    )
else()
    fb_target_sources(fbserver
        ROOT_PRIVATE
            "src/remote/server/os/posix/inet_server.cpp"
    )
endif()

################################################################################
# gfix
################################################################################
fb_add_executable(gfix MAIN
    LAYOUT_DIR ${LODIR_BIN}
)
fb_target_resources(gfix)
fb_target_compile_definitions(gfix
    PRIVATE
        SUPERCLIENT
        DEV_BUILD
)
fb_target_link_libraries(gfix
    PRIVATE
        common
    GEN_PRIVATE
        alice
        yvalve
)
fb_target_sources(gfix
    ROOT_PRIVATE
        "src/alice/main/aliceMain.cpp"
)

################################################################################
# gsec
################################################################################
fb_add_executable(gsec MAIN
    LAYOUT_DIR ${LODIR_BIN}
)
fb_target_resources(gsec)
fb_target_compile_definitions(gsec
    PRIVATE
        SUPERCLIENT
        DEV_BUILD
)
fb_target_link_libraries(gsec
    PRIVATE
        common
    GEN_PRIVATE
        yvalve
)
fb_target_sources(gsec
    ROOT_PRIVATE
        "src/utilities/gsec/gsec.cpp"
        "src/utilities/gsec/main/gsecMain.cpp"
)

################################################################################
# gsplit
################################################################################
fb_add_executable(gsplit MAIN
    LAYOUT_DIR ${LODIR_BIN}
)
fb_target_resources(gsplit)
fb_target_compile_definitions(gsplit
    PRIVATE
        SUPERCLIENT
        DEV_BUILD
)
fb_target_link_libraries(gsplit
    PRIVATE
        common
    GEN_PRIVATE
        burp
        yvalve
)
fb_target_sources(gsplit
    ROOT_PRIVATE
        "src/burp/split/spit.cpp"
)

################################################################################
# gstat
################################################################################
fb_add_executable(gstat MAIN
    LAYOUT_DIR ${LODIR_BIN}
)
fb_target_resources(gstat)
fb_target_compile_definitions(gstat
    PRIVATE
        SUPERCLIENT
        CLIENT
        DEV_BUILD
)
fb_target_link_libraries(gstat
    PRIVATE
        common
    GEN_PRIVATE
        yvalve
)
fb_target_sources(gstat
    GEN_PRIVATE
        "utilities/gstat/dba.cpp"

    ROOT_PRIVATE
        "src/utilities/gstat/main/gstatMain.cpp"
        "src/utilities/gstat/ppg.cpp"
        "src/jrd/btn.cpp"
        "src/jrd/ods.cpp"
)

################################################################################
# ib_util
################################################################################
fb_add_library(ib_util SHARED BOOT MAIN
    LAYOUT_DIR ${LODIR_LIB}
)
fb_target_symbols(ib_util
    SYMBOL WIN32 "${FIREBIRD_SOURCE_DIR}/builds/win32/defs/ib_util.def"
    SYMBOL UNIX  "${FIREBIRD_GEN_DIR}/common/ib_util.vers"
)
fb_target_resources(ib_util)
fb_target_include_directories(ib_util
    ROOT_PRIVATE
        "src/include"
)
fb_target_sources(ib_util
    ROOT_PRIVATE
        "src/extlib/ib_util.cpp"
)

################################################################################
# instreg
################################################################################
if(WIN32)
    fb_add_executable(instreg MAIN
        LAYOUT_DIR ${LODIR_BIN}
    )
    fb_target_resources(instreg)
    fb_target_compile_definitions(instreg
        PRIVATE
            DEV_BUILD
    )
    fb_target_include_directories(instreg
        ROOT_PRIVATE
            "src/include"
    )
    fb_target_sources(instreg
        ROOT_PRIVATE
            "src/utilities/install/install_reg.cpp"
            "src/utilities/install/registry.cpp"
    )
endif()

################################################################################
# instsvc
################################################################################
if(WIN32)
    fb_add_executable(instsvc MAIN
        LAYOUT_DIR ${LODIR_BIN}
    )
    fb_target_resources(instsvc)
    fb_target_compile_definitions(instsvc
        PRIVATE
            SUPERCLIENT
            DEV_BUILD
    )
    fb_target_link_libraries(instsvc
        PRIVATE
            common
        GEN_PRIVATE
            yvalve
    )
    fb_target_sources(instsvc
        ROOT_PRIVATE
            "src/utilities/install/install_svc.cpp"
            "src/utilities/install/services.cpp"
    )
endif()

################################################################################
# intl
################################################################################
fb_add_library(intl SHARED MAIN
    LAYOUT_DIR /intl
    OUTPUT_NAME fbintl
)
fb_target_symbols(intl
    SYMBOL UNIX "${FIREBIRD_GEN_DIR}/common/fbintl.vers"
)
fb_target_resources(intl)
fb_target_compile_definitions(intl
    PRIVATE
        WINDOWS_ONLY
        SUPERCLIENT
        DEV_BUILD
)
fb_target_link_libraries(intl
    PRIVATE
        common
    GEN_PRIVATE
        yvalve
)
fb_target_sources(intl
    ROOT_PRIVATE
        "src/intl/cs_big5.cpp"
        "src/intl/cs_gb2312.cpp"
        "src/intl/cs_icu.cpp"
        "src/intl/cs_jis.cpp"
        "src/intl/cs_ksc.cpp"
        "src/intl/cs_narrow.cpp"
        "src/intl/cs_unicode_fss.cpp"
        "src/intl/cs_unicode_ucs2.cpp"
        "src/intl/cv_big5.cpp"
        "src/intl/cv_gb2312.cpp"
        "src/intl/cv_icu.cpp"
        "src/intl/cv_jis.cpp"
        "src/intl/cv_ksc.cpp"
        "src/intl/cv_narrow.cpp"
        "src/intl/cv_unicode_fss.cpp"
        "src/intl/kanji.cpp"
        "src/intl/lc_ascii.cpp"
        "src/intl/lc_big5.cpp"
        "src/intl/lc_dos.cpp"
        "src/intl/lc_gb2312.cpp"
        "src/intl/lc_icu.cpp"
        "src/intl/lc_iso8859_1.cpp"
        "src/intl/lc_iso8859_13.cpp"
        "src/intl/lc_iso8859_2.cpp"
        "src/intl/lc_jis.cpp"
        "src/intl/lc_ksc.cpp"
        "src/intl/lc_narrow.cpp"
        "src/intl/lc_unicode_ucs2.cpp"
        "src/intl/ld.cpp"
)

################################################################################
# nbackup
################################################################################
fb_add_executable(nbackup MAIN
    LAYOUT_DIR ${LODIR_BIN}
)
fb_target_resources(nbackup)
fb_target_compile_definitions(nbackup
    PRIVATE
        CLIENT
        SUPERCLIENT
        DEV_BUILD
)
fb_target_link_libraries(nbackup
    PRIVATE
        common
    GEN_PRIVATE
        yvalve
)
fb_target_sources(nbackup
    PRIVATE
        "src/utilities/nbackup/main/nbkMain.cpp"
        "src/utilities/nbackup/nbackup.cpp"
        "src/jrd/ods.cpp"
)

################################################################################
# instclient
################################################################################
if(WIN32)
    fb_add_executable(instclient MAIN
        LAYOUT_DIR ${LODIR_BIN}
    )
    fb_target_resources(instclient)
    fb_target_compile_definitions(instclient
        PRIVATE
            SUPERCLIENT
            DEV_BUILD
    )
    fb_target_link_libraries(instclient
        PRIVATE
            version
    )
    fb_target_include_directories(instclient
        ROOT_PRIVATE
            "src/include"
    )
    fb_target_sources(instclient
        ROOT_PRIVATE
            "src/utilities/install/install.cpp"
            "src/utilities/install/install_client.cpp"
    )
endif()

################################################################################
# fbrmclib
################################################################################
if(${PLATFORM} STREQUAL "x86")
    fb_add_library(fbrmclib SHARED MAIN)
    fb_target_resources(fbrmclib)
    fb_target_compile_definitions(fbrmclib
        PRIVATE
            DEV_BUILD
            SUPERCLIENT
            CLIENT
            GDS32_EXPORTS
    )
    fb_target_link_libraries(fbrmclib
        PRIVATE
            common
        GEN_PRIVATE
            yvalve
    )
    fb_target_sources(fbrmclib
        ROOT_PRIVATE
            "src/gpre/languages/fbrmclib.cpp"
    )
endif()

################################################################################
# fbsvcmgr
################################################################################
fb_add_executable(fbsvcmgr MAIN
    LAYOUT_DIR ${LODIR_BIN}
)
fb_target_resources(fbsvcmgr)
fb_target_compile_definitions(fbsvcmgr
    PRIVATE
        SUPERCLIENT
        CLIENT
        DEV_BUILD
)
fb_target_link_libraries(fbsvcmgr
    PRIVATE
        common
    GEN_PRIVATE
        yvalve
)
fb_target_sources(fbsvcmgr
    ROOT_PRIVATE
        "src/utilities/fbsvcmgr/fbsvcmgr.cpp"
)

################################################################################
# fbtrace
################################################################################
fb_add_library(fbtrace SHARED MAIN
    LAYOUT_DIR ${LODIR_PLUGINS}
)
fb_target_symbols(fbtrace
    SYMBOL WIN32 "${FIREBIRD_SOURCE_DIR}/builds/win32/defs/plugin.def"
    SYMBOL UNIX  "${FIREBIRD_GEN_DIR}/common/fbplugin.vers"
)
fb_target_resources(fbtrace)
fb_target_compile_definitions(fbtrace
    PRIVATE
        DEV_BUILD
        SUPERCLIENT
        FBTRACE_EXPORTS
        NAMESPACE=Vulcan
)
fb_target_link_libraries(fbtrace
    PRIVATE
        common
        re2
    GEN_PRIVATE
        yvalve
)
fb_target_include_directories(fbtrace
    ROOT_PRIVATE
        "src/include/gen"
)
fb_target_sources(fbtrace
    ROOT_PRIVATE
        "src/utilities/ntrace/PluginLogWriter.cpp"
        "src/utilities/ntrace/TraceConfiguration.cpp"
        "src/utilities/ntrace/traceplugin.cpp"
        "src/utilities/ntrace/TracePluginImpl.cpp"
)
if(WIN32)
    fb_target_sources(fbtrace
        ROOT_PRIVATE
            "src/utilities/ntrace/os/win32/platform.cpp"
    )
else()
    fb_target_sources(fbtrace
        ROOT_PRIVATE
            "src/utilities/ntrace/os/posix/platform.cpp"
    )
endif()

################################################################################
# fbtracemgr
################################################################################
fb_add_executable(fbtracemgr MAIN
    LAYOUT_DIR ${LODIR_BIN}
)
fb_target_resources(fbtracemgr)
fb_target_compile_definitions(fbtracemgr
    PRIVATE
        SUPERCLIENT
        CLIENT
        DEV_BUILD
)
fb_target_link_libraries(fbtracemgr
    PRIVATE
        common
    GEN_PRIVATE
        yvalve
)
fb_target_include_directories(fbtracemgr
    ROOT_PRIVATE
        "src/include/gen"
)
fb_target_sources(fbtracemgr
    ROOT_PRIVATE
        "src/utilities/fbtracemgr/traceMgrMain.cpp"
        "src/jrd/trace/TraceCmdLine.cpp"
)

################################################################################
# udr_engine
################################################################################
fb_add_library(udr_engine SHARED MAIN
    LAYOUT_DIR ${LODIR_PLUGINS}
)
fb_target_symbols(udr_engine
    SYMBOL WIN32 "${FIREBIRD_SOURCE_DIR}/builds/win32/defs/plugin.def"
    SYMBOL UNIX  "${FIREBIRD_GEN_DIR}/common/fbplugin.vers"
)
fb_target_resources(udr_engine)
fb_target_compile_definitions(udr_engine
    PRIVATE
        WINDOWS_ONLY
        DEV_BUILD
        SUPERCLIENT
)
fb_target_link_libraries(udr_engine
    PRIVATE
        common
    GEN_PRIVATE
        yvalve
)
fb_target_sources(udr_engine
    ROOT_PRIVATE
        "src/plugins/udr_engine/UdrEngine.cpp"
)

################################################################################
# legacy_usermanager
################################################################################
fb_add_library(legacy_usermanager SHARED MAIN
    LAYOUT_DIR ${LODIR_PLUGINS}
)
fb_target_symbols(legacy_usermanager
    SYMBOL WIN32 "${FIREBIRD_SOURCE_DIR}/builds/win32/defs/plugin.def"
    SYMBOL UNIX  "${FIREBIRD_GEN_DIR}/common/fbplugin.vers"
)
fb_target_resources(legacy_usermanager)
fb_target_compile_definitions(legacy_usermanager
    PRIVATE
        DEV_BUILD
)
fb_target_link_libraries(legacy_usermanager
    PRIVATE
        common
    GEN_PRIVATE
        yvalve
)
fb_target_sources(legacy_usermanager
    GEN_PRIVATE
        "auth/SecurityDatabase/LegacyManagement.cpp"
)

################################################################################
# srp
################################################################################
fb_add_library(srp SHARED MAIN
    LAYOUT_DIR ${LODIR_PLUGINS}
)
fb_target_symbols(srp
    SYMBOL WIN32 "${FIREBIRD_SOURCE_DIR}/builds/win32/defs/plugin.def"
    SYMBOL UNIX  "${FIREBIRD_GEN_DIR}/common/fbplugin.vers"
)
fb_target_resources(srp)
fb_target_compile_definitions(srp
    PRIVATE
        DEV_BUILD
)
fb_target_link_libraries(srp
    PRIVATE
        common
        remote
    GEN_PRIVATE
        yvalve
)
fb_target_sources(srp
    ROOT_PRIVATE
        "src/auth/SecureRemotePassword/manage/SrpManagement.cpp"
)

################################################################################
# legacy_auth
################################################################################
fb_add_library(legacy_auth SHARED MAIN
    LAYOUT_DIR ${LODIR_PLUGINS}
)
fb_target_symbols(legacy_auth
    SYMBOL WIN32 "${FIREBIRD_SOURCE_DIR}/builds/win32/defs/plugin.def"
    SYMBOL UNIX  "${FIREBIRD_GEN_DIR}/common/fbplugin.vers"
)
fb_target_resources(legacy_auth)
fb_target_compile_definitions(legacy_auth
    PRIVATE
        DEV_BUILD
)
fb_target_link_libraries(legacy_auth
    PRIVATE
        common
    GEN_PRIVATE
        yvalve
)
fb_target_sources(legacy_auth
    ROOT_PRIVATE
        "src/auth/SecDbCache.cpp"
        "src/auth/SecurityDatabase/LegacyServer.cpp"
)

################################################################################
# udf_compat
################################################################################
fb_add_library(udf_compat SHARED MAIN
    LAYOUT_DIR /plugins/udr
)
fb_target_resources(udf_compat)
fb_target_compile_definitions(udf_compat
    PRIVATE
        DEV_BUILD
        SUPERCLIENT
        FBUDF_EXPORTS
)
fb_target_include_directories(udf_compat
    ROOT_PRIVATE
        "src/include"
)
fb_target_sources(udf_compat
    ROOT_PRIVATE
        "src/extlib/UdfBackwardCompatibility.cpp"

        "builds/win32/defs/udr_plugin.def"
)

################################################################################
# chacha
################################################################################
fb_add_library(chacha SHARED MAIN
    LAYOUT_DIR ${LODIR_PLUGINS}
)
fb_target_symbols(chacha
    SYMBOL WIN32 "${FIREBIRD_SOURCE_DIR}/builds/win32/defs/plugin.def"
    SYMBOL UNIX  "${FIREBIRD_GEN_DIR}/common/fbplugin.vers"
)
fb_target_resources(chacha)
fb_target_compile_definitions(chacha
    PRIVATE
        DEV_BUILD
)
fb_target_link_libraries(chacha
    PRIVATE
        common
    GEN_PRIVATE
        yvalve
)
fb_target_sources(chacha
    ROOT_PRIVATE
        "src/plugins/crypt/chacha/ChaCha.cpp"
)
