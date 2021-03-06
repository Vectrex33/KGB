#pragma once

#include <stddef.h>
#include <stdbool.h>
#include <string.h>
#include <stdint.h>

typedef uint8_t       u8;
typedef uint16_t      u16;
typedef uint32_t      u32;
typedef uint64_t      u64;

typedef int8_t        s8;
typedef int16_t       s16;
typedef int32_t       s32;
typedef int64_t       s64;

typedef volatile u8	  vu8;
typedef volatile u16  vu16;
typedef volatile u32  vu32;
typedef volatile u64  vu64;

typedef volatile s8	  vs8;
typedef volatile s16  vs16;
typedef volatile s32  vs32;
typedef volatile s64  vs64;

#include <ctr9/ctr_system.h>
#include <ctr9/i2c.h>
#include <ctr9/ctr_interrupt.h>
#include <ctr9/io.h>
#include <ctr9/io/ctr_fatfs.h>
#include <ctr9/sha.h>

#define SECTOR_SIZE 0x200
#define SD_INSERTED ((*(u8*)0x1000601C) & (1 << 5))
#define PAYLOADPATH "/arm9loaderhax.bin"

const char *ff_err[20];
void chainload(const char *payload_path);
void error(char *err_msg);

#include "ui.h"
#include "firm.h"
#include "crypto.h"
#include "patcher.h"
#include "printf.h"
