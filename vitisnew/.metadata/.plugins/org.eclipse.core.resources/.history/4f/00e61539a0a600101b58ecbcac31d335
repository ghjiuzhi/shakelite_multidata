#ifndef FPGA_SHA_DRIVER_H_
#define FPGA_SHA_DRIVER_H_

#include "xil_types.h"
#include "sphincs/sphincsplus/sphincsplus-7ec789ace6874d875f4bb84cb61b81155398167e/ref/context.h" // 包含SPHINCS+的上下文定义
#include "sphincs/sphincsplus/sphincsplus-7ec789ace6874d875f4bb84cb61b81155398167e/ref/params.h"

// 从main.c中移动过来的硬件相关定义
#define IP_CORE_BASEADDR        XPAR_SHA3_1003_TIP1_0_S0_AXI_BASEADDR
#define REG_CONTROL_OFFSET      0x00
#define REG_DIN_LOW_OFFSET      0x04
#define REG_DIN_HIGH_OFFSET     0x08
#define REG_CONTROL2_OFFSET     0x0C
#define REG_STATUS_OFFSET       0x10
#define REG_RESULT_START_OFFSET 0x14
#define CONTROL_START_BIT       (1 << 3)
#define CONTROL2_LAST_DIN_BIT   (1 << 0)
#define CONTROL2_DIN_VALID_BIT  (1 << 5)
#define CONTROL2_DOUT_READY_BIT (1 << 6)
#define STATUS_RESULT_READY_BIT (1 << 5)
#define RESULT_REG_COUNT 42

/**
 * @brief 使用FPGA硬件加速版的thash函数
 * 这是我们对外提供的核心功能函数
 */
void thash_shake_fpga(unsigned char *out, const unsigned char *in,
                      unsigned long long inlen, const spx_ctx *ctx,
                      uint32_t addr[8]);

#endif /* FPGA_SHA_DRIVER_H_ */
