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

NSString *binPath = @"/var/containers/Bundle/iosbinpack64";
NSString *kernelPath = @"/System/Library/Caches/com.apple.kernelcaches/kernelcache";

int launchAsPlatform(char *binary, char *arg1, char *arg2, char *arg3, char *arg4, char *arg5, char *arg6, char**env) {
    pid_t pd;
    const char* args[] = {binary, arg1, arg2, arg3, arg4, arg5, arg6,  NULL};

    posix_spawnattr_t attr;
    posix_spawnattr_init(&attr);
    posix_spawnattr_setflags(&attr, POSIX_SPAWN_START_SUSPENDED); //this flag will make the created process stay frozen until we send the CONT signal. This so we can platformize it before it launches.

    int rv = posix_spawn(&pd, binary, NULL, &attr, (char **)&args, env);
    if (rv) return rv;

    platformize(pd);

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
    INFO("The application is now a platform binary");
    
    return NO_ERROR;
}

enum post_exp_t get_kernel_file(void) {
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSError *error;
    
    NSString *docs = [[[fileManager URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask] lastObject] path];
    mkdir((char *)[docs UTF8String], 0777);
    
    NSString *newPath = [docs stringByAppendingPathComponent:[NSString stringWithFormat:@"kernelcache.dump"]];
    if(!compareFiles([kernelPath UTF8String], [newPath UTF8String])) {
        [fileManager removeItemAtPath:newPath error:&error];
        if(!error) {
            INFO("deleted old copy from %s", [newPath UTF8String]);
        }
        
        INFO("copying to %s", [newPath UTF8String]);
        error = nil;
        [fileManager copyItemAtPath:kernelPath toPath:newPath error:&error];
        if (error) {
            ERROR("failed to copy kernelcache with error: %s", [[error localizedDescription] UTF8String]);
            return ERROR_ESCAPING_SANDBOX;
        }
    }
    return NO_ERROR;
}

enum post_exp_t initialize_patchfinder64() {
//    int rc = init_kernel(kread, STATIC_ADDRESS(kernel_base) + kernel_slide, NULL);
//    if(rc != 0) {
//        ERROR("failed to initialize patchfinder");
//        return ERROR_SETTING_PATCHFINDER64;
//    }
    NSFileManager *fileManager = [NSFileManager defaultManager];

    if (![fileManager fileExistsAtPath:binPath]) {
        mkdir((char *)[binPath UTF8String], 0777);
        INFO("installing ios binary pack...");
    
    NSError *error;
        [fileManager copyItemAtPath:[[[NSBundle mainBundle] bundlePath] stringByAppendingPathComponent:@"dropbear"] toPath:[binPath stringByAppendingPathComponent:@"dropbear"] error:&error];
    
//        chdir("/var/containers/Bundle/");
//        FILE *bootstrap = fopen((char*)in_bundle("tars/iosbinpack.tar"), "r");
//        untar(bootstrap, "/var/containers/Bundle/");
//        fclose(bootstrap);
    
        chmod([[binPath stringByAppendingPathComponent:@"dropbear.tar"] UTF8String], 0777);
        INFO("installed Dropbear SSH!");
    }
    
    kernel_call_init();
    const char *paths[] = {[[binPath stringByAppendingString:@"/dropbear"] UTF8String]};
//    inject_trusts(1, paths, STATIC_ADDRESS(kernel_base) + kernel_slide);
    kernel_call_deinit();
    
//    launchAsPlatform([[binPath stringByAppendingPathComponent:@"dropbear"] UTF8String], "-R", "-E", NULL, NULL, NULL, NULL, NULL);
    
    return NO_ERROR;
}
