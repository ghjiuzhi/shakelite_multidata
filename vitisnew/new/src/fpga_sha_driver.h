#ifndef FPGA_SHA_DRIVER_H_
#define FPGA_SHA_DRIVER_H_

#include <stddef.h>
#include "xil_types.h"

/**
 * @brief Uses the custom FPGA IP core to perform SHAKE256 hashing.
 *
 * This function is designed to replace the software implementation of SHAKE256.
 * It handles the specific register--based, pulsed-signal protocol of your IP.
 *
 * @param out    Pointer to the output buffer where the hash result will be stored.
 * @param outlen The desired length of the hash output in bytes.
 * @param in     Pointer to the input data to be hashed.
 * @param inlen  The length of the input data in bytes.
 */
void shake256_hw(uint8_t *out, size_t outlen, const uint8_t *in, size_t inlen);

#endif /* FPGA_SHA_DRIVER_H_ */
