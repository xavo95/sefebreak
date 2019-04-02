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
    ERROR_INITIALAZING_LIBRARY = 1,
    ERROR_GETTING_ROOT = 2,
    ERROR_ESCAPING_SANDBOX = 3,
    ERROR_SETTING_PATCHFINDER64 = 4,
    ERROR_INSTALLING_BOOTSTRAP = 5,
    ERROR_LOADING_LAUNCHDAEMONS = 6,
    ERROR_LOADING_JAILBREAKD = 7,
    ERROR_SAVING_OFFSETS = 8,
    ERROR_SETTING_HSP4 = 9,
    ERROR_TFP0_NOT_RECOVERED = 10,
};

/*
 * recover_with_hsp4
 *
 * Description:
 *     Recover the task for pid 0 port using the host special port 4 patch by Siguza.
 */
enum post_exp_t recover_with_hsp4(mach_port_t tfp0, uint64_t *ext_kernel_slide, uint64_t *ext_kernel_load_base);

/*
 * init
 *
 * Description:
 *     Initialize the library; offsets init, root, unsandbox, initialize patchfinder.
 */
enum post_exp_t init(mach_port_t tfp0, uint64_t *ext_kernel_slide, uint64_t *ext_kernel_load_base);

/*
 * root_pid
 *
 * Description:
 *     Get's root for the pid.
 */
enum post_exp_t root_pid(pid_t pid);

/*
 * unsandbox_pid
 *
 * Description:
 *     Unsandbox for the pid.
 */
enum post_exp_t unsandbox_pid(pid_t pid);

/*
 * get_kernel_file
 *
 * Description:
 *     Copy the kernelcache decompressed to the documents folder.
 */
enum post_exp_t get_kernel_file(void);

/*
 * initialize_patchfinder64
 *
 * Description:
 *     Initialize patchfinder64.
 */
enum post_exp_t initialize_patchfinder64(bool use_static_kernel);

/*
 * set_host_special_port_4_patch
 *
 * Description:
 *     Patches HSP4 to get tfp0.
 */
enum post_exp_t set_host_special_port_4_patch(void);

/*
 * add_to_trustcache
 *
 * Description:
 *     Trust all binaries in path by adding into trustcache.
 */
enum post_exp_t add_to_trustcache(char *trust_path);

/*
 * extract_tar
 *
 * Description:
 *     Untar a file to a specific task.
 */
void extract_tar(FILE *a, const char *path);

/*
 * launch_binary
 *
 * Description:
 *     Launch binary.
 */
int launch_binary(char *binary, char *arg1, char *arg2, char *arg3, char *arg4, char *arg5, char *arg6, char**env);

/*
 * cleanup
 *
 * Description:
 *     Clean up; unroot, sandbox, deplatformize and stop patchfinder.
 */
void cleanup(void);

#endif /* postexp_h */
