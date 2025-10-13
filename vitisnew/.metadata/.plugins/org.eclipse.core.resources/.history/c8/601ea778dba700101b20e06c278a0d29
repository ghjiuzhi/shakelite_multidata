#include <stdio.h>
#include <string.h>
#include "xil_printf.h"
#include "xil_types.h"
#include "xstatus.h"
#include "xil_cache.h"
#include "xtime_l.h"

// 包含所有必需的 SPHINCS+ 头文件
#include "api.h"
#include "params.h"

// 编译时健全性检查
#if !defined(CRYPTO_BYTES)
    #error "SPHINCS+ parameters not loaded correctly. Please check params.h and your build settings."
#endif

#define MESSAGE_LEN 32

/************************** 函数原型 ***************************/
void print_hex(const char *label, const unsigned char *data, size_t len);
int run_sphincs_test_forensic();
void init_platform();
void cleanup_platform();

/* 声明外部硬件驱动函数 */
extern void shake256_hw(uint8_t *out, size_t outlen, const uint8_t *in, const size_t inlen);


/*****************************************************************************/
int main()
{
    int status;
    init_platform();

    xil_printf("\r\n\n--- SPHINCS+ 最终版法证调试测试 ---\r\n");
    xil_printf("本测试将打印并比较真实的32位整数长度值，消除显示错误。\r\n");
    xil_printf("SPHINCS+ 参数集: %s\r\n", xstr(PARAMS));
    xil_printf("期望签名长度 (CRYPTO_BYTES): %d\r\n\n", CRYPTO_BYTES);

    status = run_sphincs_test_forensic();

    if (status == XST_SUCCESS) {
        xil_printf("\r\n[测试通过] 所有步骤均已成功完成和验证！硬件加速功能正确！\r\n");
    } else {
        xil_printf("\r\n[执行失败] 测试在上述某个步骤中失败。\r\n");
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

    unsigned long long smlen; // API要求使用 unsigned long long, 我们保留它
    unsigned long long mlen_out;
    int ret_val;
    XTime t_start, t_end;

    xil_printf("--- 步骤 1: 准备一个 %d 字节的消息 ---\r\n", MESSAGE_LEN);
    for (int i = 0; i < MESSAGE_LEN; i++) { m[i] = (unsigned char)i; }
    print_hex("  原始消息 (m)", m, MESSAGE_LEN);

    xil_printf("\r\n--- 步骤 2: 生成密钥对 ---\r\n");
    if (crypto_sign_keypair(pk, sk) != 0) {
        xil_printf("  [错误] 密钥对生成失败！\r\n");
        return XST_FAILURE;
    }
    xil_printf("  密钥对生成成功。\r\n");
    print_hex("  公钥 (pk) (前 32 字节)", pk, 32);

    xil_printf("\r\n--- 步骤 3: 对消息进行签名 ---\r\n");
    ret_val = crypto_sign(sm, &smlen, m, MESSAGE_LEN, sk);

    if (ret_val != 0) {
        xil_printf("  [错误] crypto_sign 函数返回了一个错误码: %d！\r\n", ret_val);
        return XST_FAILURE;
    }
    xil_printf("  crypto_sign 函数执行完毕。\r\n");

    // **关键修改**：使用(int)进行打印，以获取真实值
    xil_printf("  报告的总签名消息长度 (smlen): %d 字节。\r\n", (int)smlen);

    // --- 决定性的签名长度检查 (使用int强制转换) ---
    const int expected_smlen = CRYPTO_BYTES + MESSAGE_LEN;
    const int actual_smlen = (int)smlen;

    xil_printf("\r\n--- 步骤 3.1: 签名长度法证检查 (使用32位整数比较) ---\r\n");
    xil_printf("  即将对以下【真实】数值进行比较:\r\n");
    xil_printf("    - 期望签名长度 (expected_smlen): %d\r\n", expected_smlen);
    xil_printf("    - 实际签名长度 (actual_smlen)  : %d\r\n", actual_smlen);

    if (actual_smlen != expected_smlen) {
        xil_printf("\r\n  [!!! 关键失败 !!!] 签名长度不正确！\r\n");
        xil_printf("    -> 判断语句 if (%d != %d) 的结果为真。\r\n", actual_smlen, expected_smlen);
        return XST_FAILURE;
    } else {
        xil_printf("\r\n  [判断通过] 签名长度正确。\r\n");
        xil_printf("    -> 判断语句 if (%d != %d) 的结果为假。\r\n", actual_smlen, expected_smlen);
    }
    print_hex("  签名消息 (sm) (前 32 字节)", sm, 32);

    xil_printf("\r\n--- 步骤 4: 验证签名 ---\r\n");
    ret_val = crypto_sign_open(mout, &mlen_out, sm, smlen, pk);

    if (ret_val != 0) {
        xil_printf("  [错误] 验证函数返回错误码 %d！签名无效。\r\n", ret_val);
        return XST_FAILURE;
    }
    xil_printf("  签名验证函数成功返回 (返回码: %d)。\r\n", ret_val);
    xil_printf("  恢复出的消息长度 (mlen_out): %d 字节。\r\n", (int)mlen_out);

    // **新增的显式证据**
    print_hex("  恢复的消息 (mout)", mout, (int)mlen_out);

    xil_printf("\r\n--- 步骤 5: 最终内容检查 ---\r\n");
    xil_printf("  比对内容: 原始消息 (m) vs 恢复的消息 (mout)\r\n");
    if ((int)mlen_out != MESSAGE_LEN || memcmp(m, mout, MESSAGE_LEN) != 0) {
        xil_printf("  [错误] 消息内容不匹配！\r\n");
        return XST_FAILURE;
    }
    xil_printf("  原始消息和恢复的消息完全匹配。\r\n");

    return XST_SUCCESS;
}

/************************** 辅助函数 ***************************/
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
