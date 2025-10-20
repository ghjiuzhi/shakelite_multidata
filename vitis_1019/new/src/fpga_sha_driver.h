#ifndef FPGA_SHA_DRIVER_H_
#define FPGA_SHA_DRIVER_H_

#include <stdint.h>
#include <stddef.h>
#include "xil_types.h"
#include "xparameters.h" // 必須包含這個文件來獲取基地址

/* * 1. 檢查並使用你的 IP 核的正確基地址
 * (名稱來自 Vivado Block Design)
 * 請在你的 xparameters.h 中確認這個名稱是否為
 * XPAR_SHAKE_SHA2_IP_V1_0_S_0_BASEADDR
 * 如果不是，請替換成 xparameters.h 中的正確名稱。
 */
#define IP_CORE_BASEADDR XPAR_SHAKE_SHA2_IP_0_S00_AXI_BASEADDR

/* * 2. 根據 shake_sha2_test.c 和 .v 文件，定義正確的寄存器偏移量
 */
#define REG_CONTROL_OFFSET        0x00  // 控制: algo_mode[3:0], shake_start(4)
#define REG_DIN_LOW_OFFSET        0x04  // SHAKE 輸入低 32 位
#define REG_DIN_HIGH_OFFSET       0x08  // SHAKE 輸入高 32 位
#define REG_CONTROL2_OFFSET       0x0C  // SHAKE 控制: last_din(0), bytes(4:1), din_valid(5), dout_ready(6)
#define REG_SHA2_TDATA_OFFSET     0x10  // SHA2 tdata (低 8 位)
#define REG_SHA2_TID_OFFSET       0x14  // SHA2 tid
#define REG_SHA2_CONTROL_OFFSET   0x18  // SHA2 tvalid(0), tlast(1)
#define REG_STATUS_OFFSET         0x1C  // 狀態寄存器 (REG7)
#define REG_RESULT_START_OFFSET   0x2C  // 結果寄存器起始地址 (REG11)

/* * 3. 根據 .v 文件，定義正確的控制位
 */
// REG_CONTROL (0x00)
#define CONTROL_SHAKE_START_BIT   (1 << 4) // SHAKE 啟動位是 bit 4

// REG_CONTROL2 (0x0C)
#define CONTROL2_LAST_DIN_BIT     (1 << 0)
#define CONTROL2_DIN_VALID_BIT    (1 << 5)
#define CONTROL2_DOUT_READY_BIT   (1 << 6)

// REG_SHA2_CONTROL (0x18)
#define SHA2_CONTROL_TVALID_BIT   (1 << 0)
#define SHA2_CONTROL_TLAST_BIT    (1 << 1)

/* * 4. 根據 .v 和 shake_sha2_test.c，定義正確的狀態位
 */
// REG_STATUS (0x1C)
#define STATUS_DOUT_VALID_BIT     (1 << 3)
#define STATUS_BUSY_BIT           (1 << 4)
#define STATUS_RESULT_READY_BIT   (1 << 5) // 你的測試代碼依賴此位
#define STATUS_SHA2_TREADY_BIT    (1 << 6)

/* * 5. 根據 shake_sha2_top.v，定義正確的模式值
 */
typedef enum {
    HW_MODE_SHA2_256  = 0, // 4'b0000
    HW_MODE_SHA2_512  = 1, // 4'b0001
    HW_MODE_SHAKE_128 = 8, // 4'b1000
    HW_MODE_SHAKE_256 = 9  // 4'b1001 (這是你之前驅動中 1 的正確值)
} HwHashMode;

#define RESULT_REG_COUNT 42 // 1344 bits / 32 bits = 42
#define SHA256_REG_COUNT 8  // 256 bits / 32 bits
#define SHA512_REG_COUNT 16 // 512 bits / 32 bits

/* --- 公共 API (提供給 SPHINCS+ 調用) --- */

/**
 * @brief (SPHINCS+ API) 使用硬件執行 SHAKE256
 */
void shake256_hw(uint8_t *out, size_t outlen, const uint8_t *in, size_t inlen);

/**
 * @brief (SPHINCS+ API) 使用硬件執行 SHA256
 */
void sha256_hw(uint8_t *out, const uint8_t *in, size_t inlen);

/**
 * @brief (SPHINCS+ API) 使用硬件執行 SHA512
 */
void sha512_hw(uint8_t *out, const uint8_t *in, size_t inlen);

#endif // FPGA_SHA_DRIVER_H_
