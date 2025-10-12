#include <stdio.h>
#include <string.h>
#include "xil_printf.h"
#include "xil_types.h"
#include "xstatus.h"
#include "xil_cache.h"
#include "xtime_l.h"

// �������б���� SPHINCS+ ͷ�ļ�
#include "api.h"
#include "params.h"

// ����ʱ��ȫ�Լ��
#if !defined(CRYPTO_BYTES)
    #error "SPHINCS+ parameters not loaded correctly. Please check params.h and your build settings."
#endif

#define MESSAGE_LEN 32

/************************** ����ԭ�� ***************************/
void print_hex(const char *label, const unsigned char *data, size_t len);
int run_sphincs_test_forensic();
void init_platform();
void cleanup_platform();

/* �����ⲿӲ���������� */
extern void shake256_hw(uint8_t *out, size_t outlen, const uint8_t *in, const size_t inlen);


/*****************************************************************************/
int main()
{
    int status;
    init_platform();

    xil_printf("\r\n\n--- SPHINCS+ ���հ淨֤���Բ��� ---\r\n");
    xil_printf("�����Խ���ӡ���Ƚ���ʵ��32λ��������ֵ��������ʾ����\r\n");
    xil_printf("SPHINCS+ ������: %s\r\n", xstr(PARAMS));
    xil_printf("����ǩ������ (CRYPTO_BYTES): %d\r\n\n", CRYPTO_BYTES);

    status = run_sphincs_test_forensic();

    if (status == XST_SUCCESS) {
        xil_printf("\r\n[����ͨ��] ���в�����ѳɹ���ɺ���֤��Ӳ�����ٹ�����ȷ��\r\n");
    } else {
        xil_printf("\r\n[ִ��ʧ��] ����������ĳ��������ʧ�ܡ�\r\n");
    }

    cleanup_platform();
    return status;
}

/*****************************************************************************/
int run_sphincs_test_forensic()
{
    static unsigned char pk[CRYPTO_PUBLICKEYBYTES];
    static unsigned char sk[CRYPTO_SECRETKEYBYTES];
    static unsigned char m[MESSAGE_LEN];
    static unsigned char sm[CRYPTO_BYTES + MESSAGE_LEN];
    static unsigned char mout[CRYPTO_BYTES + MESSAGE_LEN];

    unsigned long long smlen; // APIҪ��ʹ�� unsigned long long, ���Ǳ�����
    unsigned long long mlen_out;
    int ret_val;
    XTime t_start, t_end;

    xil_printf("--- ���� 1: ׼��һ�� %d �ֽڵ���Ϣ ---\r\n", MESSAGE_LEN);
    for (int i = 0; i < MESSAGE_LEN; i++) { m[i] = (unsigned char)i; }
    print_hex("  ԭʼ��Ϣ (m)", m, MESSAGE_LEN);

    xil_printf("\r\n--- ���� 2: ������Կ�� ---\r\n");
    if (crypto_sign_keypair(pk, sk) != 0) {
        xil_printf("  [����] ��Կ������ʧ�ܣ�\r\n");
        return XST_FAILURE;
    }
    xil_printf("  ��Կ�����ɳɹ���\r\n");
    print_hex("  ��Կ (pk) (ǰ 32 �ֽ�)", pk, 32);

    xil_printf("\r\n--- ���� 3: ����Ϣ����ǩ�� ---\r\n");
    ret_val = crypto_sign(sm, &smlen, m, MESSAGE_LEN, sk);

    if (ret_val != 0) {
        xil_printf("  [����] crypto_sign ����������һ��������: %d��\r\n", ret_val);
        return XST_FAILURE;
    }
    xil_printf("  crypto_sign ����ִ����ϡ�\r\n");

    // **�ؼ��޸�**��ʹ��(int)���д�ӡ���Ի�ȡ��ʵֵ
    xil_printf("  �������ǩ����Ϣ���� (smlen): %d �ֽڡ�\r\n", (int)smlen);

    // --- �����Ե�ǩ�����ȼ�� (ʹ��intǿ��ת��) ---
    const int expected_smlen = CRYPTO_BYTES + MESSAGE_LEN;
    const int actual_smlen = (int)smlen;

    xil_printf("\r\n--- ���� 3.1: ǩ�����ȷ�֤��� (ʹ��32λ�����Ƚ�) ---\r\n");
    xil_printf("  ���������¡���ʵ����ֵ���бȽ�:\r\n");
    xil_printf("    - ����ǩ������ (expected_smlen): %d\r\n", expected_smlen);
    xil_printf("    - ʵ��ǩ������ (actual_smlen)  : %d\r\n", actual_smlen);

    if (actual_smlen != expected_smlen) {
        xil_printf("\r\n  [!!! �ؼ�ʧ�� !!!] ǩ�����Ȳ���ȷ��\r\n");
        xil_printf("    -> �ж���� if (%d != %d) �Ľ��Ϊ�档\r\n", actual_smlen, expected_smlen);
        return XST_FAILURE;
    } else {
        xil_printf("\r\n  [�ж�ͨ��] ǩ��������ȷ��\r\n");
        xil_printf("    -> �ж���� if (%d != %d) �Ľ��Ϊ�١�\r\n", actual_smlen, expected_smlen);
    }
    print_hex("  ǩ����Ϣ (sm) (ǰ 32 �ֽ�)", sm, 32);

    xil_printf("\r\n--- ���� 4: ��֤ǩ�� ---\r\n");
    ret_val = crypto_sign_open(mout, &mlen_out, sm, smlen, pk);

    if (ret_val != 0) {
        xil_printf("  [����] ��֤�������ش����� %d��ǩ����Ч��\r\n", ret_val);
        return XST_FAILURE;
    }
    xil_printf("  ǩ����֤�����ɹ����� (������: %d)��\r\n", ret_val);
    xil_printf("  �ָ�������Ϣ���� (mlen_out): %d �ֽڡ�\r\n", (int)mlen_out);

    // **��������ʽ֤��**
    print_hex("  �ָ�����Ϣ (mout)", mout, (int)mlen_out);

    xil_printf("\r\n--- ���� 5: �������ݼ�� ---\r\n");
    xil_printf("  �ȶ�����: ԭʼ��Ϣ (m) vs �ָ�����Ϣ (mout)\r\n");
    if ((int)mlen_out != MESSAGE_LEN || memcmp(m, mout, MESSAGE_LEN) != 0) {
        xil_printf("  [����] ��Ϣ���ݲ�ƥ�䣡\r\n");
        return XST_FAILURE;
    }
    xil_printf("  ԭʼ��Ϣ�ͻָ�����Ϣ��ȫƥ�䡣\r\n");

    return XST_SUCCESS;
}

/************************** �������� ***************************/
void print_hex(const char *label, const unsigned char *data, size_t len) {
    xil_printf("%s: ", label);
    for (size_t i = 0; i < len; i++) {
        xil_printf("%02x", data[i]);
    }
    xil_printf("\r\n");
}

void init_platform() {
    Xil_DCacheDisable();
    Xil_ICacheEnable();
    Xil_DCacheEnable();
}

void cleanup_platform() {
    Xil_DCacheDisable();
    Xil_ICacheDisable();
}
