//
//  post-common.c
//  sefebreak
//
//  Created by Xavier Perarnau on 04/02/2019.
//  Copyright © 2019 Xavier Perarnau All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CommonCrypto/CommonDigest.h>
#import <UIKit/UIKit.h>

#include "post-common.h"
#include "kernel_memory.h"
#include "kernel_call.h"
#include "parameters.h"
#include "offsetof.h"
#include "mach_vm.h"
#include "log.h"
#include "amfi_utils.h"

uint64_t kernel_get_proc_for_task(uint64_t task) {
    return kernel_read64(task + OFFSET(task, bsd_info));
}

uint64_t kernel_get_ucred_for_task(uint64_t task) {
    uint64_t proc_self = kernel_get_proc_for_task(task);
    return kernel_read64(proc_self + off_p_ucred);
}

uint64_t kernel_get_cr_label_for_task(uint64_t task) {
    uint64_t ucred = kernel_get_ucred_for_task(task);
    return kernel_read64(ucred + off_ucred_cr_label);
}

const char *sha512OfPath(const char *path) {
    NSFileManager *fileManager = [NSFileManager defaultManager];
    // Make sure the file exists
    NSString *pathNS = [NSString stringWithCString:path encoding:NSASCIIStringEncoding];
    if([fileManager fileExistsAtPath:pathNS isDirectory:nil]) {
        NSData *data = [NSData dataWithContentsOfFile:pathNS];
        unsigned char digest[CC_SHA512_DIGEST_LENGTH];
        CC_SHA512( data.bytes, (CC_LONG)data.length, digest);
        
        NSMutableString *output = [NSMutableString stringWithCapacity:CC_SHA512_DIGEST_LENGTH * 2];
        for( int i = 0; i < CC_SHA512_DIGEST_LENGTH; i++ ) {
            [output appendFormat:@"%02x", digest[i]];
        }
        return [output UTF8String];
    } else {
        return "";
    }
}

bool compareFiles(const char *from, const char *to) {
    NSString *fromSHA512 = [NSString stringWithCString:sha512OfPath(from) encoding:NSASCIIStringEncoding];
    NSString *toSHA512 = [NSString stringWithCString:sha512OfPath(to) encoding:NSASCIIStringEncoding];
    if([fromSHA512 isEqual: @""] || [toSHA512 isEqual: @""]) {
        return false;
    }
    if(![fromSHA512 isEqual:toSHA512]) {
        return false;
    } else {
        return true;
    }
}

uint64_t kalloc(vm_size_t size) {
    mach_vm_address_t address = 0;
    mach_vm_allocate(kernel_task_port, (mach_vm_address_t *)&address, size, VM_FLAGS_ANYWHERE);
    return address;
}

void kfree(mach_vm_address_t address, vm_size_t size) {
    mach_vm_deallocate(kernel_task_port, address, size);
}

size_t kread(uint64_t address, void *data, size_t size) {
    mach_vm_size_t size_out;
    kern_return_t kr = mach_vm_read_overwrite(kernel_task_port, address,
                                              size, (mach_vm_address_t) data, &size_out);
    if (kr != KERN_SUCCESS) {
        ERROR("%s returned %d: %s", "mach_vm_read_overwrite", kr, mach_error_string(kr));
        ERROR("could not %s address 0x%016llx", "read", address);
        return -1;
    }
    return size_out;
}

bool entitle_pid(uint64_t task, const char *ent, bool val) {
    if (!task) return false;
    
    uint64_t proc = kernel_get_proc_for_task(task);
    uint64_t ucred = kernel_read64(proc + off_p_ucred);
    uint64_t cr_label = kernel_read64(ucred + off_ucred_cr_label);
    uint64_t entitlements = kernel_read64(cr_label + off_amfi_slot);
    
    //    TODO: Generate osobject from XNU SOurce
//    if (OSDictionary_GetItem(entitlements, ent) == 0) {
//        INFO("setting Entitlements...\n");
//        uint64_t entval = OSDictionary_GetItem(entitlements, ent);
//
//        INFO("before: %s is 0x%llx\n", ent, entval);
//        OSDictionary_SetItem(entitlements, ent, (val) ? Find_OSBoolean_True() : Find_OSBoolean_False());
//
//        entval = OSDictionary_GetItem(entitlements, ent);
//        INFO("after: %s is 0x%llx\n", ent, entval);
//
//        return (entval) ? YES : NO;
//    }
    return true;
}
