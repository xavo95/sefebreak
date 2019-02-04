//
//  amfi_utils.h
//  electra
//
//  Created by Jamie on 27/01/2018.
//  Copyright © 2018 Electra Team. All rights reserved.
//


#import <stdio.h>
#import <sys/types.h>

#define MACHO(p) ((*(unsigned int *)(p) & ~1) == 0xfeedface)

int strtail(const char *str, const char *tail);
void getSHA256inplace(const uint8_t* code_dir, uint8_t *out);
uint8_t *getSHA256(const uint8_t* code_dir);
uint8_t *getCodeDirectory(const char* name);

// Trust cache types
typedef char hash_t[20];

struct trust_chain {
    uint64_t next;
    unsigned char uuid[16];
    unsigned int count;
} __attribute__((packed));
