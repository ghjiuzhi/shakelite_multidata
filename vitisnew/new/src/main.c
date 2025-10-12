#include <stdio.h>
#include <string.h>
#include "xil_printf.h"
#include "xil_types.h"
#include "xstatus.h"
#include "xil_cache.h"
#include "xtime_l.h"

// Include SPHINCS+ core API and parameters
#include "api.h"
#include "params.h"

// COMPILE-TIME SANITY CHECK:
// If the SPHINCS+ parameters were not loaded correctly, CRYPTO_BYTES will not be defined.
// This will cause a compile error, preventing a silent failure.
#if !defined(CRYPTO_BYTES)
    #error "SPHINCS+ parameters not loaded correctly. Check params.h and build settings."
#endif

#define MESSAGE_LEN 32

/************************** Function Prototypes ***************************/
void print_hex(const char *label, const unsigned char *data, size_t len);
int run_sphincs_test();
void init_platform();
void cleanup_platform();

/*****************************************************************************/
int main()
{
    int status;
    init_platform();

    xil_printf("\r\n\n--- SPHINCS+ Hardware Accelerated Test ---\r\n");
    xil_printf("SPHINCS+ Parameter Set: %s\r\n", xstr(PARAMS));
    xil_printf("Timer clock frequency: %lu Hz\r\n\n", COUNTS_PER_SECOND);

    status = run_sphincs_test();

    if (status == XST_SUCCESS) {
        xil_printf("\r\n[TRUE SUCCESS] SPHINCS+ signature and verification flow completed successfully!\r\n");
    } else {
        xil_printf("\r\n[FAILURE] SPHINCS+ signature and verification flow FAILED.\r\n");
    }

    cleanup_platform();
    return status;
}

/*****************************************************************************/
int run_sphincs_test()
{
    static unsigned char pk[CRYPTO_PUBLICKEYBYTES];
    static unsigned char sk[CRYPTO_SECRETKEYBYTES];
    static unsigned char m[MESSAGE_LEN];
    static unsigned char sm[CRYPTO_BYTES + MESSAGE_LEN];
    static unsigned char mout[CRYPTO_BYTES + MESSAGE_LEN];

    unsigned long long smlen;
    unsigned long long mlen_out;
    int ret_val;
    XTime t_start, t_end;

    // --- Step 1: Prepare Message ---
    xil_printf("--- Step 1: Preparing a %d-byte message ---\r\n", MESSAGE_LEN);
    for (int i = 0; i < MESSAGE_LEN; i++) {
        m[i] = (unsigned char)i;
    }
    print_hex("  Original Message", m, MESSAGE_LEN);

    // --- Step 2: Generate Keypair ---
    xil_printf("\r\n--- Step 2: Generating keypair (PK: %d bytes, SK: %d bytes) ---\r\n", CRYPTO_PUBLICKEYBYTES, CRYPTO_SECRETKEYBYTES);
    XTime_GetTime(&t_start);
    if (crypto_sign_keypair(pk, sk) != 0) {
        xil_printf("  [ERROR] Keypair generation failed!\r\n");
        return XST_FAILURE;
    }
    XTime_GetTime(&t_end);
    xil_printf("  Keypair generated successfully in %llu clock cycles.\r\n", (unsigned long long)(t_end - t_start));
    print_hex("  Public Key (first 32 bytes)", pk, 32);

    // --- Step 3: Sign Message ---
    xil_printf("\r\n--- Step 3: Signing the message ---\r\n");
    XTime_GetTime(&t_start);
    if (crypto_sign(sm, &smlen, m, MESSAGE_LEN, sk) != 0) {
        xil_printf("  [ERROR] Signing function failed!\r\n");
        return XST_FAILURE;
    }
    XTime_GetTime(&t_end);
    xil_printf("  Message signed in %llu clock cycles.\r\n", (unsigned long long)(t_end - t_start));
    xil_printf("  Reported signed message length: %llu bytes.\r\n", smlen);

    // --- CRITICAL CHECK ---
    if (smlen != (CRYPTO_BYTES + MESSAGE_LEN)) {
        xil_printf("\r\n  [CRITICAL FAILURE] Signature length is INCORRECT!\r\n");
        xil_printf("    Expected length: %d bytes\r\n", CRYPTO_BYTES + MESSAGE_LEN);
        xil_printf("    Actual length:   %llu bytes\r\n", smlen);
        xil_printf("    This proves the hardware accelerator is not producing the correct hash value.\r\n");
        return XST_FAILURE;
    }
    xil_printf("  Signature length is CORRECT.\r\n");

    // --- Step 4: Verify Signature ---
    xil_printf("\r\n--- Step 4: Verifying the signature ---\r\n");
    XTime_GetTime(&t_start);
    ret_val = crypto_sign_open(mout, &mlen_out, sm, smlen, pk);
    XTime_GetTime(&t_end);

    if (ret_val != 0) {
        xil_printf("  [ERROR] Verification function returned code %d! Signature is INVALID.\r\n", ret_val);
        return XST_FAILURE;
    }
    xil_printf("  Signature verified successfully in %llu clock cycles.\r\n", (unsigned long long)(t_end - t_start));

    // --- Step 5: Final Check ---
    xil_printf("\r\n--- Step 5: Final Check ---\r\n");
    if (mlen_out != MESSAGE_LEN || memcmp(m, mout, MESSAGE_LEN) != 0) {
        xil_printf("  [ERROR] Message content mismatch! Verification is faulty.\r\n");
        return XST_FAILURE;
    }
    xil_printf("  Original and recovered messages match perfectly.\r\n");

    return XST_SUCCESS;
}

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
