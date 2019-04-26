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
    ERROR_SAVING_OFFSETS = 5,
    ERROR_SETTING_HSP4 = 6,
    ERROR_TFP0_NOT_RECOVERED = 7,
    ERROR_ADDING_TO_TRUSTCACHE = 8,
};

/*
 * recover_with_hsp4
 *
 * Description:
 *     Recover the task for pid 0 port using the host special port 4 patch by Siguza.
 */
enum post_exp_t recover_with_hsp4(mach_port_t *tfp0, uint64_t *ext_kernel_slide, uint64_t *ext_kernel_load_base);

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
 * dump_apticker
 *
 * Description:
 *     Dump apticket.
 */
enum post_exp_t dump_apticker(void);

/*
 * cleanup
 *
 * Description:
 *     Clean up; unroot, sandbox, deplatformize and stop patchfinder.
 */
void cleanup(void);

/*
 * get_vnode_at_path
 *
 * Description:
 *     Get vnode pointer at path.
 */
uint64_t get_vnode_at_path(const char *path);

/*
 * fix_mmap
 *
 * Description:
 *     Fix mmap for dylibs.
 */
int fix_mmap(char *path);

///////////////////////////////////////////// ADVANCED EXPORT METHODS /////////////////////////////////////////////

/*
 * untar
 *
 * Description:
 *     Untar a file to a specific task.
 */
void untar(FILE *a, const char *path);

/*
 * launch
 *
 * Description:
 *     Launch binary.
 */
int launch(char *binary, char *arg1, char *arg2, char *arg3, char *arg4, char *arg5, char *arg6, char**env);

/*
 * launchAsPlatform
 *
 * Description:
 *     Launch a binary as platform binary.
 */
int launch_as_platform(char *binary, char *arg1, char *arg2, char *arg3, char *arg4, char *arg5, char *arg6, char**env);

/*
 * kernel_call_init_internal
 *
 * Description:
 *     Initialize kernel_call functions.
 */
bool kernel_call_init(void);

/*
 * kernel_call_deinit
 *
 * Description:
 *     Deinitialize the kernel call subsystem and restore the kernel to a safe state.
 */
void kernel_call_deinit(void);

/*
 * kernel_call_7
 *
 * Description:
 *     Call a kernel function with the specified arguments.
 *
 * Restrictions:
 *     See kernel_call_7v().
 */
uint32_t kernel_call_7(uint64_t function, size_t argument_count, ...);

/*
 *
 * kernel_read
 *
 * Description:
 *     Read data from kernel memory.
 */
bool kernel_read(uint64_t address, void *data, size_t size);

/*
 * kernel_write
 *
 * Description:
 *     Write data to kernel memory.
 */
bool kernel_write(uint64_t address, const void *data, size_t size);

/*
 * kernel_read8
 *
 * Description:
 *     Read a single byte from kernel memory. If the read fails, -1 is returned.
 */
uint8_t kernel_read8(uint64_t address);

/*
 * kernel_read16
 *
 * Description:
 *     Read a 16-bit value from kernel memory. If the read fails, -1 is returned.
 */
uint16_t kernel_read16(uint64_t address);

/*
 * kernel_read32
 *
 * Description:
 *     Read a 32-bit value from kernel memory. If the read fails, -1 is returned.
 */
uint32_t kernel_read32(uint64_t address);

/*
 * kernel_read64
 *
 * Description:
 *     Read a 64-bit value from kernel memory. If the read fails, -1 is returned.
 */
uint64_t kernel_read64(uint64_t address);

/*
 * kernel_write8
 *
 * Description:
 *     Write a single byte to kernel memory.
 */
bool kernel_write8(uint64_t address, uint8_t value);

/*
 * kernel_write16
 *
 * Description:
 *     Write a 16-bit value to kernel memory.
 */
bool kernel_write16(uint64_t address, uint16_t value);

/*
 * kernel_write32
 *
 * Description:
 *     Write a 32-bit value to kernel memory.
 */
bool kernel_write32(uint64_t address, uint32_t value);

/*
 * kernel_write64
 *
 * Description:
 *     Write a 64-bit value to kernel memory.
 */
bool kernel_write64(uint64_t address, uint64_t value);

/*
 * kalloc
 *
 * Description:
 *     Allocate data to kernel memory.
 */
uint64_t kalloc(vm_size_t size);

/*
 * kfree
 *
 * Description:
 *     Free data from kernel memory.
 */
bool kfree(mach_vm_address_t address, vm_size_t size);

/*
 * kread
 *
 * Description:
 *     Reads data from kernel memory.
 */
size_t kread(uint64_t where, void *p, size_t size);

/*
 * task_struct_of_pid
 *
 * Description:
 *     Get tasks struc for pid.
 */
uint64_t task_struct_of_pid(pid_t pid);

/*
 * proc_of_pid
 *
 * Description:
 *     Get proc struct for pid.
 */
uint64_t proc_of_pid(pid_t pid);

/*
 * verify_tfp0
 *
 * Description:
 *     Verifies if we have a valid tfp0.
 */
bool verify_tfp0(void);

/*
 * unlock_nvram
 *
 * Description:
 *     Unlocks NVRAM for setting boot nonce.
 */
void unlock_nvram(void);

/*
 * lock_nvram
 *
 * Description:
 *     Locks NVRAM after setting boot nonce.
 */
int lock_nvram(void);

/*
 * respring
 *
 * Description:
 *     Restarts springboard.
 */
int respring(char *killall_path);

/*
 * unload_launchdeamons
 *
 * Description:
 *     Unloads LaunchDaemons at path.
 */
int unload_launchdeamons(char *launchctl_path, char *launchdaemon_folder);

/*
 * load_launchdeamons
 *
 * Description:
 *     Loads LaunchDaemons at path.
 */
int load_launchdeamons(char *launchctl_path, char *launchdaemon_folder);

/*
 * pid_of_proc_name
 *
 * Description:
 *     Returns the pid by proc name.
 */
unsigned int pid_of_proc_name(char *nm);

/*
 * get_symbol_by_name
 *
 * Description:
 *     Returns address of a symbol inside offsetcache.
 */
uint64_t get_symbol_by_name(char *name);

#endif /* postexp_h */
