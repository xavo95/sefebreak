//
//  sandbox.c
//  sefebreak
//
//  Created by Xavier Perarnau on 04/02/2019.
//  Copyright © 2019 Xavier Perarnau. All rights reserved.
//

#include "sandbox.h"
#include "post-common.h"
#include "kernel_memory.h"
#include "offsetof.h"

uint64_t old_sandbox_slot = 0;
uint32_t old_csflags = 0;
uint32_t old_t_flags = 0;

void save_proc_sandbox_struct(uint64_t task) {
    uint64_t cr_label = kernel_get_cr_label_for_task(task);
    old_sandbox_slot = kernel_read64(cr_label + off_sandbox_slot);
}

bool unsandbox(uint64_t task) {
    uint64_t cr_label = kernel_get_cr_label_for_task(task);
    kernel_write64(cr_label + off_sandbox_slot, 0);
    return (kernel_read32(cr_label + off_sandbox_slot) == 0) ? true : false;
}

bool sandbox(uint64_t task) {
    uint64_t cr_label = kernel_get_cr_label_for_task(task);
    kernel_write64(cr_label + off_sandbox_slot, old_sandbox_slot);
    return (kernel_read32(cr_label + off_sandbox_slot) == old_sandbox_slot) ? true : false;
}

bool setcsflags(uint64_t task) {
    uint64_t proc = kernel_get_proc_for_task(task);
    old_csflags = kernel_read32(proc + off_p_csflags);
    uint32_t newflags = (old_csflags | CS_PLATFORM_BINARY | CS_INSTALLER | CS_GET_TASK_ALLOW | CS_DEBUGGED) & ~(CS_RESTRICT | CS_HARD | CS_KILL);
    kernel_write32(proc + off_p_csflags, newflags);
    return (kernel_read32(proc + off_p_csflags) == newflags) ? true : false;
}

void platformize(uint64_t task) {
    uint64_t proc = kernel_get_proc_for_task(task);
    old_t_flags = kernel_read32(task + off_t_flags);
    uint32_t t_flags = old_t_flags | 0x400; // add TF_PLATFORM flag, = 0x400
    kernel_write32(task + off_t_flags, t_flags);
    uint32_t csflags = kernel_read32(proc + off_p_csflags);
    kernel_write32(proc + off_p_csflags, csflags | 0x24004001u); //patch csflags
}

void restore_csflags(uint64_t task) {
    uint64_t proc = kernel_get_proc_for_task(task);
    kernel_write32(task + off_t_flags, old_t_flags);
    kernel_write32(proc + off_p_csflags, old_csflags); //patch csflags
}

uint64_t proc_of_pid(pid_t pid) {
//    uint64_t proc = kernel_read64(Find_allproc()), pd;
    uint64_t proc = 0;
    while (proc) { //iterate over all processes till we find the one we're looking for
        uint32_t pd = kernel_read32(proc + off_p_pid);
        if (pd == pid) return proc;
        proc = kernel_read64(proc);
    }
    
    return 0;
}

void platformize_pid(pid_t pid) {
    if (!pid) return;
    
    uint64_t proc = proc_of_pid(pid);
    uint64_t task = kernel_read64(proc + off_task);
    platformize(task);
}
