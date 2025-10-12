#include "fpga_sha_driver.h"
#include "xparameters.h"
#include "xil_io.h"
#include <string.h>

// 硬件IP核的基地址
#define IP_CORE_BASEADDR        XPAR_SHA3_1003_TIP1_0_S0_AXI_BASEADDR

// 寄存器地址偏移
#define REG_CONTROL_OFFSET      0x00
#define REG_DIN_LOW_OFFSET      0x04
#define REG_DIN_HIGH_OFFSET     0x08
#define REG_CONTROL2_OFFSET     0x0C
#define REG_STATUS_OFFSET       0x10
#define REG_RESULT_START_OFFSET 0x14

// 控制位定义
#define CONTROL_START_BIT       (1 << 3)
#define CONTROL2_LAST_DIN_BIT   (1 << 0)
#define CONTROL2_DIN_VALID_BIT  (1 << 5)
#define CONTROL2_DOUT_READY_BIT (1 << 6)
#define STATUS_RESULT_READY_BIT (1 << 5)

#define RESULT_REG_COUNT 42

/**
 * @brief 使用 FPGA IP 核执行 SHAKE256 哈希运算 (最终无打印版本)
 */
void shake256_hw(uint8_t *out, size_t outlen, const uint8_t *in, const size_t inlen)
{
    u32 base_addr = IP_CORE_BASEADDR;
    size_t remaining_len = inlen;
    const uint8_t *data_ptr = in;
    int timeout;

    // --- 1. 设置模式并准备好接收输出 ---
    u32 control_val = 1; // Mode 1: Shake-256
    Xil_Out32(base_addr + REG_CONTROL_OFFSET, control_val);

    u32 control2_base = CONTROL2_DOUT_READY_BIT;
    Xil_Out32(base_addr + REG_CONTROL2_OFFSET, control2_base);

    // --- 2. 发送启动脉冲 ---
    Xil_Out32(base_addr + REG_CONTROL_OFFSET, control_val | CONTROL_START_BIT);
    Xil_Out32(base_addr + REG_CONTROL_OFFSET, control_val);

    // --- 3. 以8字节为单位，流式传输大部分输入数据 ---
    while (remaining_len >= 8) {
        // **修正字节序的关键步骤**
        // 逐字节精确构建64位整数，确保大端序 (MSB first)
        u64 chunk = 0;
        chunk |= (u64)data_ptr[0] << 56;
        chunk |= (u64)data_ptr[1] << 48;
        chunk |= (u64)data_ptr[2] << 40;
        chunk |= (u64)data_ptr[3] << 32;
        chunk |= (u64)data_ptr[4] << 24;
        chunk |= (u64)data_ptr[5] << 16;
        chunk |= (u64)data_ptr[6] << 8;
        chunk |= (u64)data_ptr[7] << 0;

        // 写入高32位和低32位
        Xil_Out32(base_addr + REG_DIN_HIGH_OFFSET, (u32)(chunk >> 32));
        Xil_Out32(base_addr + REG_DIN_LOW_OFFSET,  (u32)(chunk & 0xFFFFFFFF));

        // 发送din_valid脉冲，通知IP核接收数据
        Xil_Out32(base_addr + REG_CONTROL2_OFFSET, control2_base | CONTROL2_DIN_VALID_BIT);
        Xil_Out32(base_addr + REG_CONTROL2_OFFSET, control2_base);

        data_ptr += 8;
        remaining_len -= 8;
    }

    // --- 4. 发送最后的数据块（可能不足8字节） ---
    u64 last_chunk = 0;
    if (remaining_len > 0) {
        // 同样逐字节构建，保证字节序正确
        for (size_t i = 0; i < remaining_len; i++) {
            last_chunk |= (u64)data_ptr[i] << (56 - (i * 8));
        }
    }

    Xil_Out32(base_addr + REG_DIN_HIGH_OFFSET, (u32)(last_chunk >> 32));
    Xil_Out32(base_addr + REG_DIN_LOW_OFFSET,  (u32)(last_chunk & 0xFFFFFFFF));

    // 准备最后的控制字：包含LAST位和剩余的字节数
    u32 control2_final = control2_base | CONTROL2_LAST_DIN_BIT | ((u32)remaining_len << 1);
    Xil_Out32(base_addr + REG_CONTROL2_OFFSET, control2_final);

    // 发送最后的din_valid脉冲
    Xil_Out32(base_addr + REG_CONTROL2_OFFSET, control2_final | CONTROL2_DIN_VALID_BIT);
    Xil_Out32(base_addr + REG_CONTROL2_OFFSET, control2_final);

    // --- 5. 等待计算完成 ---
    timeout = 1000000;
    while (((Xil_In32(base_addr + REG_STATUS_OFFSET) & STATUS_RESULT_READY_BIT) == 0) && (timeout > 0)) {
        timeout--;
    }

    if (timeout <= 0) {
        // 如果发生超时，可以在这里加打印来报告错误
        // xil_printf("[HW DRIVER ERROR] Timeout!\r\n");
        return;
    }

    // --- 6. 读出结果 ---
    u32 result_buffer[RESULT_REG_COUNT];
    for (int i = 0; i < RESULT_REG_COUNT; i++) {
        result_buffer[i] = Xil_In32(base_addr + REG_RESULT_START_OFFSET + i * 4);
    }

    // 只复制算法需要的长度
    size_t copy_len = (outlen > sizeof(result_buffer)) ? sizeof(result_buffer) : outlen;
    memcpy(out, result_buffer, copy_len);
}
