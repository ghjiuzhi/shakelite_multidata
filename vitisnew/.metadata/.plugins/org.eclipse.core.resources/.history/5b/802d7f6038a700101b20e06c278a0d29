#include "fpga_sha_driver.h"
#include "xparameters.h"
#include "xil_io.h"
#include <string.h>
#include "sha3_1003_tIP1.h" // Includes low-level macros

/* Definitions from your verified test code */
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
 * @brief Reorders registers from back-to-front and handles endianness.
 */
static void reorder_hardware_output(unsigned char* dest, const u32* src_regs, size_t bytes_to_copy) {
    size_t num_regs_to_process = (bytes_to_copy + 3) / 4;
    for (size_t i = 0; i < num_regs_to_process; i++) {
        u32 current_reg_val = src_regs[RESULT_REG_COUNT - 1 - i];
        dest[i * 4 + 0] = (current_reg_val >> 24) & 0xFF;
        dest[i * 4 + 1] = (current_reg_val >> 16) & 0xFF;
        dest[i * 4 + 2] = (current_reg_val >> 8)  & 0xFF;
        dest[i * 4 + 3] = (current_reg_val >> 0)  & 0xFF;
    }
}

/**
 * @brief Drives the SHAKE256 hardware IP. (Final Integration Version)
 */
void shake256_hw(uint8_t *out, size_t outlen, const uint8_t *in, const size_t inlen)
{
    u32 base_addr = IP_CORE_BASEADDR;
    size_t remaining_len = inlen;
    const uint8_t *data_ptr = in;
    int timeout;

    u32 control_val = 1; // Mode 1: Shake-256
    Xil_Out32(base_addr + REG_CONTROL_OFFSET, control_val);
    u32 control2_base = CONTROL2_DOUT_READY_BIT;
    Xil_Out32(base_addr + REG_CONTROL2_OFFSET, control2_base);

    Xil_Out32(base_addr + REG_CONTROL_OFFSET, control_val | CONTROL_START_BIT);
    Xil_Out32(base_addr + REG_CONTROL_OFFSET, control_val);

    while (remaining_len >= 8) {
        u64 chunk = 0;
        for(int i=0; i<8; i++) {
            chunk |= (u64)data_ptr[i] << (56 - (i * 8));
        }
        Xil_Out32(base_addr + REG_DIN_HIGH_OFFSET, (u32)(chunk >> 32));
        Xil_Out32(base_addr + REG_DIN_LOW_OFFSET,  (u32)(chunk & 0xFFFFFFFF));
        Xil_Out32(base_addr + REG_CONTROL2_OFFSET, control2_base | CONTROL2_DIN_VALID_BIT);
        Xil_Out32(base_addr + REG_CONTROL2_OFFSET, control2_base);
        data_ptr += 8;
        remaining_len -= 8;
    }

    u64 last_chunk = 0;
    if (remaining_len > 0) {
        for (size_t i = 0; i < remaining_len; i++) {
            last_chunk |= (u64)data_ptr[i] << (56 - (i * 8));
        }
    }
    Xil_Out32(base_addr + REG_DIN_HIGH_OFFSET, (u32)(last_chunk >> 32));
    Xil_Out32(base_addr + REG_DIN_LOW_OFFSET,  (u32)(last_chunk & 0xFFFFFFFF));
    u32 control2_final = control2_base | CONTROL2_LAST_DIN_BIT | ((u32)remaining_len << 1);
    Xil_Out32(base_addr + REG_CONTROL2_OFFSET, control2_final);
    Xil_Out32(base_addr + REG_CONTROL2_OFFSET, control2_final | CONTROL2_DIN_VALID_BIT);
    Xil_Out32(base_addr + REG_CONTROL2_OFFSET, control2_final);

    timeout = 1000000;
    while (((Xil_In32(base_addr + REG_STATUS_OFFSET) & STATUS_RESULT_READY_BIT) == 0) && (timeout > 0)) {
        timeout--;
    }
    if (timeout <= 0) { return; }

    u32 result_regs[RESULT_REG_COUNT];
    for (int i = 0; i < RESULT_REG_COUNT; i++) {
        result_regs[i] = Xil_In32(base_addr + REG_RESULT_START_OFFSET + i * 4);
    }

    unsigned char reordered_buffer[sizeof(result_regs)];
    reorder_hardware_output(reordered_buffer, result_regs, sizeof(reordered_buffer));

    memcpy(out, reordered_buffer, outlen);
}
