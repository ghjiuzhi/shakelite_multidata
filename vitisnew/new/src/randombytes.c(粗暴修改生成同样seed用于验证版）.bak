#include "randombytes.h"
#include "xtime_l.h" // 包含Xilinx的时间函数库

// xoroshiro128+ 的状态 (种子)
static uint64_t s[2];

// 辅助函数：一个64位的 splitmix64 PRNG，用于给 xoroshiro128+ 初始化一个好的种子
static uint64_t splitmix64(uint64_t *x)
{
    uint64_t z = (*x += 0x9e3779b97f4a7c15);
    z = (z ^ (z >> 30)) * 0xbf58476d1ce4e5b9;
    z = (z ^ (z >> 27)) * 0x94d049bb133111eb;
    return z ^ (z >> 31);
}

// xoroshiro128+ 核心生成函数
static uint64_t next(void)
{
    const uint64_t s0 = s[0];
    uint64_t s1 = s[1];
    const uint64_t result = s0 + s1;

    s1 ^= s0;
    s[0] = ((s0 << 24) | (s0 >> (64 - 24))) ^ s1 ^ (s1 << 16); // a, b = 24, 16
    s[1] = (s1 << 37) | (s1 >> (64 - 37)); // c = 37

    return result;
}

void randombytes(unsigned char *x, unsigned long long xlen)
{
    // --- “粗暴”的修改点 ---
    // 删除了 'if (s[0] == 0 && s[1] == 0)' 的检查。
    // 这意味着下面的代码块【每次】调用 randombytes 时都会执行。

    // 1. 使用一个固定的、硬编码的64位常数作为种子
    uint64_t seed = 0xDEADBEEF12345678;

    // 2. 强制用这个固定的种子重新初始化 xoroshiro128+ 的状态
    s[0] = splitmix64(&seed);
    s[1] = splitmix64(&seed);

    // --- 修改结束 ---


    // 后续的随机数生成逻辑保持不变
    for (unsigned long long i = 0; i < xlen; i++) {
        if (i % 8 == 0) {
            uint64_t rand_val = next();
            for (int j = 0; j < 8 && (i + j) < xlen; j++) {
                x[i + j] = (unsigned char)(rand_val >> (j * 8));
            }
        }
    }
}
