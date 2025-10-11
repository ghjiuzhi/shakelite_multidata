#include "xil_printf.h"
#include <string.h> // For memcmp

// SPHINCS+ and HAL includes
#include "api.h"
#include "thash.h" // For the software version
#include "fpga_sha_driver.h" // <-- 包含我们自己的头文件

void print_separator()
{
    xil_printf("=====================================================================\r\n");
}

int main()
{
    init_platform();

    xil_printf("\r\n--- SPHINCS+ SHAKE256 Hardware Acceleration Verification ---\r\n");

    // 1. Prepare SPHINCS+ context and test data
    spx_ctx ctx;
    unsigned char message[32];
    uint32_t addr[8] = {0};

    // Fill with some random data
    randombytes(ctx.pub_seed, SPX_N);
    randombytes(ctx.sk_seed, SPX_N);
    randombytes(ctx.sk_prf, SPX_N);
    randombytes(message, 32);

    // 2. Define buffers for software and hardware results
    unsigned char software_hash_output[SPX_N];
    unsigned char hardware_hash_output[SPX_N];

    // 3. Run the pure software version to get a golden reference
    print_separator();
    xil_printf("Running original SOFTWARE version of thash...\r\n");
    thash_shake_simple(software_hash_output, message, 32, &ctx, addr);

    xil_printf("Software Result (first 16 bytes): ");
    for(int i = 0; i < SPX_N; i++) xil_printf("%02X ", software_hash_output[i]);
    xil_printf("\r\n");

    // 4. Run our hardware-accelerated version
    print_separator();
    xil_printf("Running HARDWARE accelerated version of thash...\r\n");
    thash_shake_fpga(hardware_hash_output, message, 32, &ctx, addr);

    xil_printf("Hardware Result (first 16 bytes): ");
    for(int i = 0; i < SPX_N; i++) xil_printf("%02X ", hardware_hash_output[i]);
    xil_printf("\r\n");

    // 5. Compare the results
    print_separator();
    xil_printf("Comparing results...\r\n");
    if (memcmp(software_hash_output, hardware_hash_output, SPX_N) == 0) {
        xil_printf("\r\n[SUCCESS] Verification PASSED! Hardware and Software results match perfectly.\r\n");
    } else {
        xil_printf("\r\n[FAILURE] Verification FAILED! Hardware and Software results DO NOT match.\r\n");
    }
    print_separator();

    cleanup_platform();
    return 0;
}
