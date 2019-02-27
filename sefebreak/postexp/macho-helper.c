//
//  macho-helper.c
//  sefebreak
//
//  Created by Xavier Perarnau on 16/02/2019.
//  Copyright © 2019 Xavier Perarnau. All rights reserved.
//

#include "macho-helper.h"
#include <stdlib.h>

void *load_bytes(FILE *obj_file, off_t offset, uint32_t size) {
    void *buf = calloc(1, size);
    fseek(obj_file, offset, SEEK_SET);
    fread(buf, size, 1, obj_file);
    return buf;
}

uint32_t find_macho_header(FILE *file) {
    uint32_t off = 0;
    uint32_t *magic = load_bytes(file, off, sizeof(uint32_t));
    while ((*magic & ~1) != 0xFEEDFACE) {
        off++;
        magic = load_bytes(file, off, sizeof(uint32_t));
    }
    return off - 1;
}
