//
//  post-common.h
//  sefebreak
//
//  Created by Xavier Perarnau on 04/02/2019.
//  Copyright © 2019 Xavier Perarnau. All rights reserved.
//

#ifndef post_common_h
#define post_common_h

#include <stdio.h>

/*
 * kernel_get_proc_for_task
 *
 * Description:
 *     Get the proc struct for a task.
 */
uint64_t kernel_get_proc_for_task(uint64_t task);

/*
 * kernel_get_ucred_for_task
 *
 * Description:
 *     Get the ucred struct for a task.
 */
uint64_t kernel_get_ucred_for_task(uint64_t task);

/*
 * kernel_get_cr_label_for_task
 *
 * Description:
 *     Get the cr_label struct for a task.
 */
uint64_t kernel_get_cr_label_for_task(uint64_t task);

/*
 * sha512OfPath
 *
 * Description:
 *     Get the sha512 for a file in a path, returns empty string if file not exists.
 */
const char *sha512OfPath(const char *path);

/*
 * compareFiles
 *
 * Description:
 *     Compares two files given their locations in the file system.
 */
bool compareFiles(const char *from, const char *to);

/*
 * kread
 *
 * Description:
 *     Reads data from kernel memory.
 */
size_t kread(uint64_t where, void *p, size_t size);

/*
 * inject_trusts
 *
 * Description:
 *     Injects to trustcache.
 */
void inject_trusts(int pathc, const char *paths[], uint64_t base);


#endif /* post_common_h */
