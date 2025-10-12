/*
 * main.c (最终完整、未经删节版 V3.4)
 *
 * 功能:
 * 1. 纯软件基准测试 (签名 + 验证 + 计时)
 * 2. 纯硬件加速测试 (签名 + 验证 + 计时)
 * 3. 交叉验证 (软签->硬验, 硬签->软验) 以确保功能完全兼容
 * 4. 将软件和硬件生成的签名以可复制的格式打印到终端
 * 5. 打印详细的、修正过的性能对比报告
 */
#include <stdio.h>
#include <string.h>
#include "xil_printf.h"
#include "xstatus.h"
#include "xtime_l.h"         // 引入 Zynq 的计时库
#include "xparameters.h"     // 包含处理器时钟频率等宏定义
#include "xil_cache.h"       // 包含缓存控制函数

#include "api.h"
#include "fips202.h"
#include "randombytes.h"

#define MLEN 32 // 消息长度

// --- 函数原型 ---
void print_hex(const char *label, const unsigned char *data, size_t len);
void print_hex_for_file(const unsigned char *data, size_t len); // 用于文件输出的打印函数
void init_platform();
void cleanup_platform();
void print_llu(const char *label, unsigned long long val); // 用于正确打印64位整数的函数

int main()
{
    init_platform();
    xil_printf("\r\n--- SPHINCS+ SW/HW Full-Flow Verification & Benchmarking ---\r\n");

    int final_status = XST_SUCCESS;
    XTime t_start, t_end;
    u64 sw_sign_ticks = 0, sw_verify_ticks = 0, hw_sign_ticks = 0, hw_verify_ticks = 0;

    // --- 为了避免 PS 栈溢出，所有大数据都使用静态内存 ---
    static unsigned char pk_sw[CRYPTO_PUBLICKEYBYTES];
    static unsigned char sk_sw[CRYPTO_SECRETKEYBYTES];
    static unsigned char m[MLEN];
    static unsigned char sm_sw[CRYPTO_BYTES + MLEN];
    static unsigned char mout_hw[CRYPTO_BYTES + MLEN];

    static unsigned char pk_hw[CRYPTO_PUBLICKEYBYTES];
    static unsigned char sk_hw[CRYPTO_SECRETKEYBYTES];
    static unsigned char sm_hw[CRYPTO_BYTES + MLEN];
    static unsigned char mout_sw[CRYPTO_BYTES + MLEN];

    unsigned long long smlen, mlen_out;

    // 生成一条固定的随机消息用于所有测试
    randombytes(m, MLEN);
    xil_printf("A %d-byte random message has been generated for all tests.\r\n", MLEN);
    print_hex("  Original Message (m)", m, MLEN);

    // ===================================================================
    //  Flow 1: 纯软件签名与验证 (SW -> SW)
    // ===================================================================
    xil_printf("\r\n--- Flow 1: Pure Software Signing and Verification (Baseline) ---\r\n");
    use_sw_shake_for_sphincs(); // **切换到软件**
    XTime_GetTime(&t_start);
    crypto_sign_keypair(pk_sw, sk_sw);
    crypto_sign(sm_sw, &smlen, m, MLEN, sk_sw);
    XTime_GetTime(&t_end);
    sw_sign_ticks = t_end - t_start;

    XTime_GetTime(&t_start);
    int sw_verify_result = crypto_sign_open(mout_sw, &mlen_out, sm_sw, smlen, pk_sw);
    XTime_GetTime(&t_end);
    sw_verify_ticks = t_end - t_start;

    if (sw_verify_result != 0 || mlen_out != MLEN || memcmp(m, mout_sw, MLEN) != 0) {
        xil_printf("  [FAIL] SW signing and verification are NOT internally consistent.\r\n");
        final_status = XST_FAILURE;
    } else {
        xil_printf("  [SUCCESS] SW signing and verification are internally consistent.\r\n");
    }

    // ===================================================================
    //  Flow 2: 纯硬件加速测试 (HW -> HW)
    // ===================================================================
    xil_printf("\r\n--- Flow 2: Pure Hardware-Accelerated Signing and Verification ---\r\n");
    use_hw_shake_for_sphincs(); // **切换到硬件**
    XTime_GetTime(&t_start);
    crypto_sign_keypair(pk_hw, sk_hw);
    crypto_sign(sm_hw, &smlen, m, MLEN, sk_hw);
    XTime_GetTime(&t_end);
    hw_sign_ticks = t_end - t_start;

    XTime_GetTime(&t_start);
    int hw_verify_result = crypto_sign_open(mout_hw, &mlen_out, sm_hw, smlen, pk_hw);
    XTime_GetTime(&t_end);
    hw_verify_ticks = t_end - t_start;

    if (hw_verify_result != 0 || mlen_out != MLEN || memcmp(m, mout_hw, MLEN) != 0) {
        xil_printf("  [FAIL] HW signing and verification are NOT internally consistent.\r\n");
        final_status = XST_FAILURE;
    } else {
        xil_printf("  [SUCCESS] HW signing and verification are internally consistent.\r\n");
    }

    // ===================================================================
    //  Flow 3 & 4: 交叉验证以确保兼容性
    // ===================================================================
    xil_printf("\r\n--- Flow 3 & 4: Cross-Verification for Compatibility ---\r\n");

    // 流程3: SW Sign (使用之前生成的软件密钥和签名) -> HW Verify
    use_hw_shake_for_sphincs();
    if (crypto_sign_open(mout_hw, &mlen_out, sm_sw, CRYPTO_BYTES + MLEN, pk_sw) != 0) {
        xil_printf("  [FAIL] Cross-Verification (SW Sign -> HW Verify) FAILED!\r\n");
        final_status = XST_FAILURE;
    } else {
        xil_printf("  [SUCCESS] Cross-Verification (SW Sign -> HW Verify) PASSED.\r\n");
    }

    // 流程4: HW Sign (使用之前生成的硬件密钥和签名) -> SW Verify
    use_sw_shake_for_sphincs();
    if (crypto_sign_open(mout_sw, &mlen_out, sm_hw, CRYPTO_BYTES + MLEN, pk_hw) != 0) {
        xil_printf("  [FAIL] Cross-Verification (HW Sign -> SW Verify) FAILED!\r\n");
        final_status = XST_FAILURE;
    } else {
        xil_printf("  [SUCCESS] Cross-Verification (HW Sign -> SW Verify) PASSED.\r\n");
    }

    // ===================================================================
    //  签名输出部分
    // ===================================================================
    xil_printf("\r\n\n--- SIGNATURE FILE OUTPUT ---\r\n");
    xil_printf("Copy the hexadecimal string between the BEGIN/END markers into a text file.\r\n");

    // --- 输出软件签名 ---
    xil_printf("\r\n--- BEGIN SOFTWARE SIGNATURE FILE (sm_sw.txt) ---\r\n");
    print_hex_for_file(sm_sw, smlen);
    xil_printf("\r\n--- END SOFTWARE SIGNATURE FILE ---\r\n");

    // --- 输出硬件签名 ---
    xil_printf("\r\n--- BEGIN HARDWARE SIGNATURE FILE (sm_hw.txt) ---\r\n");
    print_hex_for_file(sm_hw, smlen);
    xil_printf("\r\n--- END HARDWARE SIGNATURE FILE ---\r\n");


    // ===================================================================
    //  最终性能对比报告
    // ===================================================================
    xil_printf("\r\n\n--- Final Performance Report ---\r\n");
    xil_printf("NOTE: 'cycles' are raw 64-bit timer ticks. 'ms' is calculated time.\r\n");

    print_llu(" - SW Signing:    ", sw_sign_ticks);
    print_llu(" - HW Signing:    ", hw_sign_ticks);
    print_llu(" - SW Verification:", sw_verify_ticks);
    print_llu(" - HW Verification:", hw_verify_ticks);

    if (hw_sign_ticks > 0) {
        printf("  => Signing Performance Speed-up: %.2f X\r\n", (float)sw_sign_ticks / hw_sign_ticks);
    }
    if (hw_verify_ticks > 0) {
        printf("  => Verification Performance Speed-up: %.2f X\r\n", (float)hw_verify_ticks / hw_verify_ticks);
    }

    #if defined(XPAR_CPU_CORTEXA9_0_CPU_CLK_FREQ_HZ)
        const double CPU_FREQ_MHZ = (double)XPAR_CPU_CORTEXA9_0_CPU_CLK_FREQ_HZ / 1000000.0;
    #elif defined(XPAR_PSU_CORTEXA53_0_CPU_CLK_FREQ_HZ)
        const double CPU_FREQ_MHZ = (double)XPAR_PSU_CORTEXA53_0_CPU_CLK_FREQ_HZ / 1000000.0;
    #else
        const double CPU_FREQ_MHZ = 1.0; // 如果找不到频率定义，默认为1，避免除零
    #endif

    xil_printf("\r\n--- Time in Milliseconds (assuming %.0f MHz CPU clock) ---\r\n", CPU_FREQ_MHZ);
    printf(" - SW Signing:     %.3f ms\r\n", (double)sw_sign_ticks / (CPU_FREQ_MHZ * 1000.0));
    printf(" - HW Signing:     %.3f ms\r\n", (double)hw_sign_ticks / (CPU_FREQ_MHZ * 1000.0));
    printf(" - SW Verification:  %.3f ms\r\n", (double)sw_verify_ticks / (CPU_FREQ_MHZ * 1000.0));
    printf(" - HW Verification:  %.3f ms\r\n", (double)hw_verify_ticks / (CPU_FREQ_MHZ * 1000.0));

    if (final_status == XST_SUCCESS) {
        xil_printf("\r\n[FINAL CONCLUSION: ALL PASSED] Functionality is correct and performance data has been collected.\r\n");
    } else {
        xil_printf("\r\n[FINAL CONCLUSION: FAILED] A functional verification step failed.\r\n");
    }

    cleanup_platform();
    return final_status;
}


/******************************************************************************
*
* 辅助函数实现
*
******************************************************************************/

/**
 * @brief 新增: 以纯十六进制格式打印数据，不带任何前缀或换行，便于复制
 */
void print_hex_for_file(const unsigned char *data, size_t len) {
    for (size_t i = 0; i < len; i++) {
        xil_printf("%02x", data[i]);
    }
}

/**
 * @brief 安全地打印64位无符号整数
 */
void print_llu(const char *label, unsigned long long val)
{
    // 将64位数转换为十进制字符串
    char buffer[21]; // 2^64-1 是 20 位数
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

/**
 * @brief 以带标签的格式打印十六进制数据
 */
void print_hex(const char *label, const unsigned char *data, size_t len) {
    xil_printf("%s: ", label);
    for (size_t i = 0; i < len; i++) {
        xil_printf("%02x", data[i]);
    }
    xil_printf("\r\n");
}

/**
 * @brief 初始化平台 (例如，开启缓存)
 */
void init_platform()
{
    Xil_ICacheEnable();
    Xil_DCacheEnable();
    xil_printf("Platform initialized (Caches Enabled)\r\n");
}

/**
 * @brief 清理平台 (例如，关闭缓存)
 */
void cleanup_platform()
{
    Xil_DCacheDisable();
    Xil_ICacheDisable();
    xil_printf("Platform cleaned up (Caches Disabled)\r\n");
}
