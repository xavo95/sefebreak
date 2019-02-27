//
//  postexp.h
//  sefebreak
//
//  Created by Xavier Perarnau on 04/02/2019.
//  Copyright © 2019 Xavier Perarnau.. All rights reserved.
//

#ifndef postexp_h
#define postexp_h

#include <stdio.h>

enum post_exp_t {
    NO_ERROR = 0,
    ERROR_GETTING_ROOT = 1,
    ERROR_ESCAPING_SANDBOX = 2,
    ERROR_INITIALIZING_PATCHFINDER64 = 3,
    ERROR_SETTING_PATCHFINDER64 = 4
};

enum post_exp_t root_and_escape(void);
enum post_exp_t get_kernel_file(void);
enum post_exp_t initialize_patchfinder64(void);
enum post_exp_t launch_dropbear(void);
void cleanup(void);

#endif /* postexp_h */
