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

void inject_trusts(int pathc, const char *paths[], uint64_t base) {
    INFO("injecting into trust cache...");
        
    static uint64_t tc = 0;
    if (tc == 0) {
        /* loaded_trust_caches
         iPhone11,2-4-6: 0xFFFFFFF008F702C8
         iPhone11,8: 0xFFFFFFF008ED42C8
         */
        tc = base + (0xFFFFFFF008F702C8 - 0xFFFFFFF007004000);
    }
    
    INFO("trust cache: 0x%llx", tc);
    
    struct trust_chain fake_chain;
    fake_chain.next = kernel_read64(tc);
#if (0)
    *(uint64_t *)&fake_chain.uuid[0] = 0xabadbabeabadbabe;
    *(uint64_t *)&fake_chain.uuid[8] = 0xabadbabeabadbabe;
#else
    arc4random_buf(&fake_chain.uuid, 16);
#endif
    
    int cnt = 0;
    uint8_t hash[CC_SHA256_DIGEST_LENGTH];
    hash_t *allhash = malloc(sizeof(hash_t) * pathc);
    for (int i = 0; i != pathc; ++i) {
        uint8_t *cd = getCodeDirectory(paths[i]);
        if (cd != NULL) {
            getSHA256inplace(cd, hash);
            memmove(allhash[cnt], hash, sizeof(hash_t));
            ++cnt;
        }
    }
    
    fake_chain.count = cnt;
    
    size_t length = (sizeof(fake_chain) + cnt * sizeof(hash_t) + 0x3FFF) & ~0x3FFF;
    uint64_t kernel_trust = kalloc(length);
    printf("[+] kalloc: 0x%llx", kernel_trust);
    
    printf("[+] writing fake_chain");
    kernel_write(kernel_trust, &fake_chain, sizeof(fake_chain));
    printf("[+] writing allhash");
    kernel_write(kernel_trust + sizeof(fake_chain), allhash, cnt * sizeof(hash_t));
    printf("[+] writing trust cache");
    
#if (0)
    kernel_write64(tc, kernel_trust);
#else
    /* load_trust_cache
     iPhone11,2-4-6: 0xFFFFFFF007B80504
     iPhone11,8: 0xFFFFFFF007B50504
     */
    uint64_t f_load_trust_cache = base + (0xFFFFFFF007B80504 - 0xFFFFFFF007004000);
    uint32_t ret = kernel_call_7(f_load_trust_cache, 3,
                                 kernel_trust,
                                 length,
                                 0);
    printf("[+] load_trust_cache: 0x%x", ret);
#endif
    
    printf("[+] injected trust cache");
}
