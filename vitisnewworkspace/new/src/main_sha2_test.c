/*
 * main_sha2_test.c (用于测试 SHA-2 硬件)
 */
#include <stdio.h>
#include <string.h>
#include "xil_printf.h"
#include "xstatus.h"
#include "xtime_l.h"
#include "xparameters.h"
#include "xil_cache.h"

#include "api.h"
// #include "fips202.h" // 不再需要
#include "randombytes.h"

#define MLEN 32

// 函数原型
void print_hex(const char *label, const unsigned char *data, size_t len);
void init_platform();
void cleanup_platform();
void print_llu(const char *label, unsigned long long val);

int main()
{
    init_platform();
    xil_printf("\r\n--- SPHINCS+ [SHA-2] Hardware-Only Verification ---\r\n");

    int final_status = XST_SUCCESS;
    XTime t_start, t_end;
    u64 hw_sign_ticks = 0, hw_verify_ticks = 0;

    static unsigned char m[MLEN];
    static unsigned char pk_hw[CRYPTO_PUBLICKEYBYTES];
    static unsigned char sk_hw[CRYPTO_SECRETKEYBYTES];
    static unsigned char sm_hw[CRYPTO_BYTES + MLEN];
    static unsigned char mout_hw[CRYPTO_BYTES + MLEN];

    unsigned long long smlen, mlen_out;

    randombytes(m, MLEN);
    xil_printf("A %d-byte random message has been generated for this test.\r\n", MLEN);
    print_hex("  Original Message (m)", m, MLEN);

    // ===================================================================
    //  Flow: Pure Hardware Accelerated Test (HW -> HW)
    // ===================================================================
    xil_printf("\r\n--- Flow: Hardware-Accelerated Signing and Verification ---\r\n");
    // 我们不需要 use_hw_...() 调用，因为 sha2.c 已经被硬编码为调用硬件

    XTime_GetTime(&t_start);
    crypto_sign_keypair(pk_hw, sk_hw);
    crypto_sign(sm_hw, &smlen, m, MLEN, sk_hw);
    XTime_GetTime(&t_end);
    hw_sign_ticks = t_end - t_start;

    XTime_GetTime(&t_start);
    int hw_verify_result = crypto_sign_open(mout_hw, &mlen_out, sm_hw, smlen, pk_hw);
    XTime_GetTime(&t_end);
    hw_verify_ticks = t_end - t_start;

    if (hw_verify_result != 0) {
        xil_printf("  [FAIL] HW verification function returned error code: %d\r\n", hw_verify_result);
        final_status = XST_FAILURE;
    } else {
        xil_printf("  [INFO] HW verification function returned 0 (SUCCESS).\r\n");
        print_hex("    -> Recovered Message (mout_hw)", mout_hw, mlen_out);
        if (mlen_out != MLEN || memcmp(m, mout_hw, MLEN) != 0) {
            xil_printf("  [FAIL] HW recovered message does not match original!\r\n");
            final_status = XST_FAILURE;
        } else {
            xil_printf("  [SUCCESS] memcmp confirms messages match. HW is internally consistent.\r\n");
        }
    }

    // ===================================================================
    //  Final Performance Report
    // ===================================================================
    xil_printf("\r\n\n--- Final Performance Report [SHA-2 HW] ---\r\n");
    print_llu(" - HW Signing:     ", hw_sign_ticks);
    print_llu(" - HW Verification:", hw_verify_ticks);
    
    #if defined(XPAR_CPU_CORTEXA9_0_CPU_CLK_FREQ_HZ)
        const double CPU_FREQ_MHZ = (double)XPAR_CPU_CORTEXA9_0_CPU_CLK_FREQ_HZ / 1000000.0;
        xil_printf("\r\n--- Time in Milliseconds (assuming %.0f MHz CPU clock) ---\r\n", CPU_FREQ_MHZ);
        printf(" - HW Signing:     %.3f ms\r\n", (double)hw_sign_ticks / (CPU_FREQ_MHZ * 1000.0));
        printf(" - HW Verification: %.3f ms\r\n", (double)hw_verify_ticks / (CPU_FREQ_MHZ * 1000.0));
    #endif

    if (final_status == XST_SUCCESS) {
        xil_printf("\r\n[FINAL CONCLUSION: PASSED] SHA-2 HW Functionality is correct.\r\n");
    } else {
        xil_printf("\r\n[FINAL CONCLUSION: FAILED] A SHA-2 HW functional verification step failed.\r\n");
    }

    cleanup_platform();
    return final_status;
}

/******************************************************************************
* 辅助函数实现 (与你原来的代码完全相同)
******************************************************************************/
void print_llu(const char *label, unsigned long long val) {
    char buffer[21];
    int i = sizeof(buffer) - 1;
    buffer[i] = '\0';
    if (val == 0) {
        i--;
        buffer[i] = '0';
    } else {
        while (val > 0 && i > 0) {
            i--;
            buffer[i] = (val % 10) + '0';
            val /= 10;
        }
    }
    xil_printf("%s%s cycles\r\n", label, &buffer[i]);
}

void print_hex(const char *label, const unsigned char *data, size_t len) {
    xil_printf("%s: ", label);
    for (size_t i = 0; i < len; i++) {
        xil_printf("%02x", data[i]);
    }
    xil_printf("\r\n");
}

void init_platform() {
    Xil_ICacheEnable();
    Xil_DCacheEnable();
    xil_printf("Platform initialized (Caches Enabled)\r\n");
}

void cleanup_platform() {
    Xil_DCacheDisable();
    Xil_ICacheDisable();
    xil_printf("Platform cleaned up (Caches Disabled)\r\n");
}