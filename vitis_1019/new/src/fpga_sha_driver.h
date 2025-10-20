#ifndef FPGA_SHA_DRIVER_H_
#define FPGA_SHA_DRIVER_H_

#include <stdint.h>
#include <stddef.h>
#include "xil_types.h"
#include "xparameters.h" // ��횰����@���ļ���@ȡ����ַ

/* * 1. �z��Kʹ����� IP �˵����_����ַ
 * (���Q���� Vivado Block Design)
 * Ո����� xparameters.h �д_�J�@�����Q�Ƿ��
 * XPAR_SHAKE_SHA2_IP_V1_0_S_0_BASEADDR
 * ������ǣ�Ո��Q�� xparameters.h �е����_���Q��
 */
#define IP_CORE_BASEADDR XPAR_SHAKE_SHA2_IP_0_S00_AXI_BASEADDR

/* * 2. ���� shake_sha2_test.c �� .v �ļ������x���_�ļĴ���ƫ����
 */
#define REG_CONTROL_OFFSET        0x00  // ����: algo_mode[3:0], shake_start(4)
#define REG_DIN_LOW_OFFSET        0x04  // SHAKE ݔ��� 32 λ
#define REG_DIN_HIGH_OFFSET       0x08  // SHAKE ݔ��� 32 λ
#define REG_CONTROL2_OFFSET       0x0C  // SHAKE ����: last_din(0), bytes(4:1), din_valid(5), dout_ready(6)
#define REG_SHA2_TDATA_OFFSET     0x10  // SHA2 tdata (�� 8 λ)
#define REG_SHA2_TID_OFFSET       0x14  // SHA2 tid
#define REG_SHA2_CONTROL_OFFSET   0x18  // SHA2 tvalid(0), tlast(1)
#define REG_STATUS_OFFSET         0x1C  // ��B�Ĵ��� (REG7)
#define REG_RESULT_START_OFFSET   0x2C  // �Y���Ĵ�����ʼ��ַ (REG11)

/* * 3. ���� .v �ļ������x���_�Ŀ���λ
 */
// REG_CONTROL (0x00)
#define CONTROL_SHAKE_START_BIT   (1 << 4) // SHAKE ����λ�� bit 4

// REG_CONTROL2 (0x0C)
#define CONTROL2_LAST_DIN_BIT     (1 << 0)
#define CONTROL2_DIN_VALID_BIT    (1 << 5)
#define CONTROL2_DOUT_READY_BIT   (1 << 6)

// REG_SHA2_CONTROL (0x18)
#define SHA2_CONTROL_TVALID_BIT   (1 << 0)
#define SHA2_CONTROL_TLAST_BIT    (1 << 1)

/* * 4. ���� .v �� shake_sha2_test.c�����x���_�Ġ�Bλ
 */
// REG_STATUS (0x1C)
#define STATUS_DOUT_VALID_BIT     (1 << 3)
#define STATUS_BUSY_BIT           (1 << 4)
#define STATUS_RESULT_READY_BIT   (1 << 5) // ��Ĝyԇ���a��ه��λ
#define STATUS_SHA2_TREADY_BIT    (1 << 6)

/* * 5. ���� shake_sha2_top.v�����x���_��ģʽֵ
 */
typedef enum {
    HW_MODE_SHA2_256  = 0, // 4'b0000
    HW_MODE_SHA2_512  = 1, // 4'b0001
    HW_MODE_SHAKE_128 = 8, // 4'b1000
    HW_MODE_SHAKE_256 = 9  // 4'b1001 (�@����֮ǰ���� 1 �����_ֵ)
} HwHashMode;

#define RESULT_REG_COUNT 42 // 1344 bits / 32 bits = 42
#define SHA256_REG_COUNT 8  // 256 bits / 32 bits
#define SHA512_REG_COUNT 16 // 512 bits / 32 bits

/* --- ���� API (�ṩ�o SPHINCS+ �{��) --- */

/**
 * @brief (SPHINCS+ API) ʹ��Ӳ������ SHAKE256
 */
void shake256_hw(uint8_t *out, size_t outlen, const uint8_t *in, size_t inlen);

/**
 * @brief (SPHINCS+ API) ʹ��Ӳ������ SHA256
 */
void sha256_hw(uint8_t *out, const uint8_t *in, size_t inlen);

/**
 * @brief (SPHINCS+ API) ʹ��Ӳ������ SHA512
 */
void sha512_hw(uint8_t *out, const uint8_t *in, size_t inlen);

#endif // FPGA_SHA_DRIVER_H_
