#include "xil_printf.h"
#include "xil_types.h"
#include "xstatus.h"
#include "xil_cache.h"
#include "xil_io.h"
#include <string.h>

/* Include the low-level driver definitions */
#include "sha3_1003_tIP1.h"

/************************** Constant Definitions ***************************/
#define IP_CORE_BASEADDR        XPAR_SHA3_1003_TIP1_0_S0_AXI_BASEADDR

/* Register address offsets (from your working test code) */
#define REG_CONTROL_OFFSET      0x00
#define REG_DIN_LOW_OFFSET      0x04
#define REG_DIN_HIGH_OFFSET     0x08
#define REG_CONTROL2_OFFSET     0x0C
#define REG_STATUS_OFFSET       0x10
#define REG_RESULT_START_OFFSET 0x14

/* Control bit definitions (from your working test code) */
#define CONTROL_START_BIT       (1 << 3)
#define CONTROL2_LAST_DIN_BIT   (1 << 0)
#define CONTROL2_DIN_VALID_BIT  (1 << 5)
#define CONTROL2_DOUT_READY_BIT (1 << 6)
#define STATUS_RESULT_READY_BIT (1 << 5)

#define RESULT_REG_COUNT 42

/************************** Function Prototypes ****************************/
void init_platform();
void cleanup_platform();
int final_hardware_test(u32 base_addr);
void print_hex_inline(const char *label, const unsigned char *data, size_t len);
void reorder_and_swap_bytes(unsigned char* dest, const u32* src, size_t num_bytes_to_reorder);

/*****************************************************************************/
int main()
{
    init_platform();
    xil_printf("\r\n--- Final Hardware SHAKE256 Golden Vector Test ---\r\n");
    xil_printf("--- Using YOUR verified 'abc' result as the golden standard ---\r\n\n");

    int status = final_hardware_test(IP_CORE_BASEADDR);

    cleanup_platform();
    return status;
}

/*****************************************************************************/
int final_hardware_test(u32 base_addr)
{
    u32 result_regs[RESULT_REG_COUNT];
    unsigned char reordered_hardware_output[32];
    int timeout = 1000000;

    /* This is the golden output YOU provided for the input "abc" */
    const unsigned char your_golden_output[32] = {
        0x48, 0x33, 0x66, 0x60, 0x13, 0x60, 0xA8, 0x77, 0x1C, 0x68, 0x63, 0x08,
        0x0C, 0xC4, 0x11, 0x4D, 0x8D, 0xB4, 0x45, 0x30, 0xF8, 0xF1, 0xE1, 0xEE,
        0x4F, 0x94, 0xEA, 0x37, 0xE7, 0x8B, 0x57, 0x39
    };

    /* --- Step 1: Prepare "abc" input data --- */
    u64 write_data = 0x6162630000000000ULL;
    u32 high_32 = (u32)(write_data >> 32);
    u32 low_32  = (u32)(write_data & 0xFFFFFFFF);

    SHA3_1003_TIP1_mWriteReg(base_addr, REG_DIN_HIGH_OFFSET, high_32);
    SHA3_1003_TIP1_mWriteReg(base_addr, REG_DIN_LOW_OFFSET, low_32);

    /* --- Step 2: Set control signals --- */
    u32 control2_val = CONTROL2_LAST_DIN_BIT | (3 << 1) | CONTROL2_DOUT_READY_BIT;
    SHA3_1003_TIP1_mWriteReg(base_addr, REG_CONTROL2_OFFSET, control2_val);

    /* --- Step 3: Start computation --- */
    u32 control_val = 1; /* Mode 1: Shake-256 */
    SHA3_1003_TIP1_mWriteReg(base_addr, REG_CONTROL_OFFSET, control_val);
    SHA3_1003_TIP1_mWriteReg(base_addr, REG_CONTROL_OFFSET, control_val | CONTROL_START_BIT);
    SHA3_1003_TIP1_mWriteReg(base_addr, REG_CONTROL_OFFSET, control_val);
    SHA3_1003_TIP1_mWriteReg(base_addr, REG_CONTROL2_OFFSET, control2_val | CONTROL2_DIN_VALID_BIT);
    SHA3_1003_TIP1_mWriteReg(base_addr, REG_CONTROL2_OFFSET, control2_val);

    /* --- Step 4: Wait for completion --- */
    do {
        timeout--;
    } while (((SHA3_1003_TIP1_mReadReg(base_addr, REG_STATUS_OFFSET) & STATUS_RESULT_READY_BIT) == 0) && (timeout > 0));

    if (timeout <= 0) {
        xil_printf("  [ERROR] Timeout!\r\n");
        return XST_FAILURE;
    }

    /* --- Step 5: Read all raw registers --- */
    for (int i = 0; i < RESULT_REG_COUNT; i++) {
        result_regs[i] = SHA3_1003_TIP1_mReadReg(base_addr, REG_RESULT_START_OFFSET + i * 4);
    }

    /* --- Step 6: Reorder data according to your reverse-read logic --- */
    reorder_and_swap_bytes(reordered_hardware_output, result_regs, 32);

    /* --- Step 7: Final Verdict --- */
    xil_printf("\r\n--- Final Verdict ---\r\n");
    print_hex_inline("  Expected Output (Your Golden Vector)", your_golden_output, 32);
    print_hex_inline("  Actual Reordered Output (Hardware)  ", reordered_hardware_output, 32);

    if (memcmp(reordered_hardware_output, your_golden_output, 32) == 0) {
        xil_printf("\r\n[HARDWARE IP PASSED!] Your IP core and all C driver logic are now PERFECT.\r\n");
        xil_printf("We are ready for the final integration.\r\n");
        return XST_SUCCESS;
    } else {
        xil_printf("\r\n[HARDWARE IP FAILED!] The hardware result does not match your expected value.\r\n");
        xil_printf("There is a mismatch between the C code and the IP core's exact behavior.\r\n");
        return XST_FAILURE;
    }
}

/**
 * @brief Reorders registers from back-to-front and handles endianness.
 */
void reorder_and_swap_bytes(unsigned char* dest, const u32* src, size_t num_bytes_to_reorder) {
    size_t num_regs_to_process = (num_bytes_to_reorder + 3) / 4;
    for (size_t i = 0; i < num_regs_to_process; i++) {
        u32 current_reg_val = src[RESULT_REG_COUNT - 1 - i];
        dest[i * 4 + 0] = (current_reg_val >> 24) & 0xFF;
        dest[i * 4 + 1] = (current_reg_val >> 16) & 0xFF;
        dest[i * 4 + 2] = (current_reg_val >> 8)  & 0xFF;
        dest[i * 4 + 3] = (current_reg_val >> 0)  & 0xFF;
    }
}

/************************** Helper Functions ***************************/
void print_hex_inline(const char *label, const unsigned char *data, size_t len) {
    xil_printf("%s: ", label);
    for (size_t i = 0; i < len; i++) { xil_printf("%02x", data[i]); }
    xil_printf("\r\n");
}
void init_platform() { Xil_ICacheEnable(); Xil_DCacheEnable(); }
void cleanup_platform() { Xil_DCacheDisable(); Xil_ICacheDisable(); }
