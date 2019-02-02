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
    uint32_t csflags = kernel_read32(proc + off_p_csflags);
    uint32_t newflags = (csflags | CS_PLATFORM_BINARY | CS_INSTALLER | CS_GET_TASK_ALLOW | CS_DEBUGGED) & ~(CS_RESTRICT | CS_HARD | CS_KILL);
    kernel_write32(proc + off_p_csflags, newflags);
    return (kernel_read32(proc + off_p_csflags) == newflags) ? true : false;
}

void platformize(uint64_t task) {
    uint64_t proc = kernel_get_proc_for_task(task);
    uint32_t t_flags = kernel_read32(task + off_t_flags);
    t_flags |= 0x400; // add TF_PLATFORM flag, = 0x400
    kernel_write32(task + off_t_flags, t_flags);
    uint32_t csflags = kernel_read32(proc + off_p_csflags);
    kernel_write32(proc + off_p_csflags, csflags | 0x24004001u); //patch csflags
}
