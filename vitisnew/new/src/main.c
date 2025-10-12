/*
 * main.c (����������δ��ɾ�ڰ� V3.4)
 *
 * ����:
 * 1. �������׼���� (ǩ�� + ��֤ + ��ʱ)
 * 2. ��Ӳ�����ٲ��� (ǩ�� + ��֤ + ��ʱ)
 * 3. ������֤ (��ǩ->Ӳ��, Ӳǩ->����) ��ȷ��������ȫ����
 * 4. �������Ӳ�����ɵ�ǩ���Կɸ��Ƶĸ�ʽ��ӡ���ն�
 * 5. ��ӡ��ϸ�ġ������������ܶԱȱ���
 */
#include <stdio.h>
#include <string.h>
#include "xil_printf.h"
#include "xstatus.h"
#include "xtime_l.h"         // ���� Zynq �ļ�ʱ��
#include "xparameters.h"     // ����������ʱ��Ƶ�ʵȺ궨��
#include "xil_cache.h"       // ����������ƺ���

#include "api.h"
#include "fips202.h"
#include "randombytes.h"

#define MLEN 32 // ��Ϣ����

// --- ����ԭ�� ---
void print_hex(const char *label, const unsigned char *data, size_t len);
void print_hex_for_file(const unsigned char *data, size_t len); // �����ļ�����Ĵ�ӡ����
void init_platform();
void cleanup_platform();
void print_llu(const char *label, unsigned long long val); // ������ȷ��ӡ64λ�����ĺ���

int main()
{
    init_platform();
    xil_printf("\r\n--- SPHINCS+ SW/HW Full-Flow Verification & Benchmarking ---\r\n");

    int final_status = XST_SUCCESS;
    XTime t_start, t_end;
    u64 sw_sign_ticks = 0, sw_verify_ticks = 0, hw_sign_ticks = 0, hw_verify_ticks = 0;

    // --- Ϊ�˱��� PS ջ��������д����ݶ�ʹ�þ�̬�ڴ� ---
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

    // ����һ���̶��������Ϣ�������в���
    randombytes(m, MLEN);
    xil_printf("A %d-byte random message has been generated for all tests.\r\n", MLEN);
    print_hex("  Original Message (m)", m, MLEN);

    // ===================================================================
    //  Flow 1: �����ǩ������֤ (SW -> SW)
    // ===================================================================
    xil_printf("\r\n--- Flow 1: Pure Software Signing and Verification (Baseline) ---\r\n");
    use_sw_shake_for_sphincs(); // **�л������**
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
    //  Flow 2: ��Ӳ�����ٲ��� (HW -> HW)
    // ===================================================================
    xil_printf("\r\n--- Flow 2: Pure Hardware-Accelerated Signing and Verification ---\r\n");
    use_hw_shake_for_sphincs(); // **�л���Ӳ��**
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
    //  Flow 3 & 4: ������֤��ȷ��������
    // ===================================================================
    xil_printf("\r\n--- Flow 3 & 4: Cross-Verification for Compatibility ---\r\n");

    // ����3: SW Sign (ʹ��֮ǰ���ɵ������Կ��ǩ��) -> HW Verify
    use_hw_shake_for_sphincs();
    if (crypto_sign_open(mout_hw, &mlen_out, sm_sw, CRYPTO_BYTES + MLEN, pk_sw) != 0) {
        xil_printf("  [FAIL] Cross-Verification (SW Sign -> HW Verify) FAILED!\r\n");
        final_status = XST_FAILURE;
    } else {
        xil_printf("  [SUCCESS] Cross-Verification (SW Sign -> HW Verify) PASSED.\r\n");
    }

    // ����4: HW Sign (ʹ��֮ǰ���ɵ�Ӳ����Կ��ǩ��) -> SW Verify
    use_sw_shake_for_sphincs();
    if (crypto_sign_open(mout_sw, &mlen_out, sm_hw, CRYPTO_BYTES + MLEN, pk_hw) != 0) {
        xil_printf("  [FAIL] Cross-Verification (HW Sign -> SW Verify) FAILED!\r\n");
        final_status = XST_FAILURE;
    } else {
        xil_printf("  [SUCCESS] Cross-Verification (HW Sign -> SW Verify) PASSED.\r\n");
    }

    // ===================================================================
    //  ǩ���������
    // ===================================================================
    xil_printf("\r\n\n--- SIGNATURE FILE OUTPUT ---\r\n");
    xil_printf("Copy the hexadecimal string between the BEGIN/END markers into a text file.\r\n");

    // --- ������ǩ�� ---
    xil_printf("\r\n--- BEGIN SOFTWARE SIGNATURE FILE (sm_sw.txt) ---\r\n");
    print_hex_for_file(sm_sw, smlen);
    xil_printf("\r\n--- END SOFTWARE SIGNATURE FILE ---\r\n");

    // --- ���Ӳ��ǩ�� ---
    xil_printf("\r\n--- BEGIN HARDWARE SIGNATURE FILE (sm_hw.txt) ---\r\n");
    print_hex_for_file(sm_hw, smlen);
    xil_printf("\r\n--- END HARDWARE SIGNATURE FILE ---\r\n");


    // ===================================================================
    //  �������ܶԱȱ���
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
        const double CPU_FREQ_MHZ = 1.0; // ����Ҳ���Ƶ�ʶ��壬Ĭ��Ϊ1���������
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
* ��������ʵ��
*
******************************************************************************/

/**
 * @brief ����: �Դ�ʮ�����Ƹ�ʽ��ӡ���ݣ������κ�ǰ׺���У����ڸ���
 */
void print_hex_for_file(const unsigned char *data, size_t len) {
    for (size_t i = 0; i < len; i++) {
        xil_printf("%02x", data[i]);
    }
}

/**
 * @brief ��ȫ�ش�ӡ64λ�޷�������
 */
void print_llu(const char *label, unsigned long long val)
{
    // ��64λ��ת��Ϊʮ�����ַ���
    char buffer[21]; // 2^64-1 �� 20 λ��
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
 * @brief �Դ���ǩ�ĸ�ʽ��ӡʮ����������
 */
void print_hex(const char *label, const unsigned char *data, size_t len) {
    xil_printf("%s: ", label);
    for (size_t i = 0; i < len; i++) {
        xil_printf("%02x", data[i]);
    }
    xil_printf("\r\n");
}

/**
 * @brief ��ʼ��ƽ̨ (���磬��������)
 */
void init_platform()
{
    Xil_ICacheEnable();
    Xil_DCacheEnable();
    xil_printf("Platform initialized (Caches Enabled)\r\n");
}

/**
 * @brief ����ƽ̨ (���磬�رջ���)
 */
void cleanup_platform()
{
    Xil_DCacheDisable();
    Xil_ICacheDisable();
    xil_printf("Platform cleaned up (Caches Disabled)\r\n");
}
