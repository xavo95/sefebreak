//
//  sandbox.h
//  sefebreak
//
//  Created by Xavier Perarnau on 04/02/2019.
//  Copyright © 2019 Xavier Perarnau. All rights reserved.
//

#ifndef sandbox_h
#define sandbox_h

#include <stdio.h>
#include <stdbool.h>

/*
 * save_proc_sandbox_struct
 *
 * Description:
 *     Backup the sandbox struct of our process.
 */
void save_proc_sandbox_struct(uint64_t task);

/*
 * unsandbox
 *
 * Description:
 *     Modify our proc struc to escape sandbox.
 */
bool unsandbox(uint64_t task);

/*
 * sandbox
 *
 * Description:
 *     Modify our proc struc to get back to sandbox.
 */
bool sandbox(uint64_t task);

/*
 * setcsflags
 *
 * Description:
 *     Modify our proc struc to get custom cs flags.
 */
bool setcsflags(uint64_t task);

/*
 * platformize
 *
 * Description:
 *     Modify our proc struc to become a platform binary.
 */
void platformize(uint64_t task);

/*
 * restore_csflags
 *
 * Description:
 *     Restore the csflags to the previous step.
 */
void restore_csflags(uint64_t task);

/*
 * platformize_pid
 *
 * Description:
 *     Modify our proc struc to become a platform binary.
 */
void platformize_pid(pid_t pid);

#endif /* sandbox_h */
