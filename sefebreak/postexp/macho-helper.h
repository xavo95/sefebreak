//
//  macho-helper.h
//  sefebreak
//
//  Created by Xavier Perarnau on 16/02/2019.
//  Copyright © 2019 Xavier Perarnau. All rights reserved.
//

#ifndef macho_helper_h
#define macho_helper_h

#include <stdio.h>

/*
 * load_bytes
 *
 * Description:
 *     Load bytes from file from starting offset and specific size.
 */
void *load_bytes(FILE *obj_file, off_t offset, uint32_t size);

/*
 * find_macho_header
 *
 * Description:
 *     Find the macho header.
 */
uint32_t find_macho_header(FILE *file);

#endif /* macho_helper_h */
