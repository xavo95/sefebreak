//
//  Unpacker.m
//  sefebreak
//
//  Created by Xavier Perarnau on 02/04/2019.
//  Copyright © 2019 Brandon Azad. All rights reserved.
//

#import "Unpacker.h"

#import <Foundation/Foundation.h>
#import <sys/utsname.h>
#import <sys/stat.h>
#import "log.h"
#include "payload.h"
#include "postexp.h"

#define in_bundle(obj) strdup([[[[NSBundle mainBundle] bundlePath] stringByAppendingPathComponent:@obj] UTF8String])

#define fileExists(file) [[NSFileManager defaultManager] fileExistsAtPath:@(file)]

#define removeFile(file) if (fileExists(file)) {\
[[NSFileManager defaultManager]  removeItemAtPath:@(file) error:&error]; \
if (error) { \
ERROR("error removing file %s (%s)", file, [[error localizedDescription] UTF8String]); \
} else {\
INFO("deleted old copy from %s", file);\
}\
}

#define copyFile(copyFrom, copyTo) [[NSFileManager defaultManager] copyItemAtPath:@(copyFrom) toPath:@(copyTo) error:&error]; \
INFO("copying %s to %s", copyFrom, copyTo);\
if (error) { \
ERROR("error copying item %s to path %s (%s)", copyFrom, copyTo, [[error localizedDescription] UTF8String]); \
}

#define moveFile(copyFrom, moveTo) [[NSFileManager defaultManager] moveItemAtPath:@(copyFrom) toPath:@(moveTo) error:&error]; \
if (error) {\
ERROR("error moving item %s to path %s (%s)", copyFrom, moveTo, [[error localizedDescription] UTF8String]); \
}

bool clean_up_previous(void) {
    NSError *error = NULL;
    if (!fileExists("/var/containers/Bundle/.installed_rootlessJB3")) {
        
        if (fileExists("/var/containers/Bundle/iosbinpack64")) {
            INFO("uninstalling previous build...");
            
            removeFile("/var/LIB");
            removeFile("/var/ulb");
            removeFile("/var/bin");
            removeFile("/var/sbin");
            removeFile("/var/containers/Bundle/tweaksupport/Applications");
            removeFile("/var/Apps");
            removeFile("/var/profile");
            removeFile("/var/motd");
            removeFile("/var/dropbear");
            removeFile("/var/containers/Bundle/tweaksupport");
            removeFile("/var/containers/Bundle/iosbinpack64");
            removeFile("/var/containers/Bundle/dylibs");
            removeFile("/var/log/testbin.log");
            
            if (fileExists("/var/log/jailbreakd-stdout.log")) removeFile("/var/log/jailbreakd-stdout.log");
            if (fileExists("/var/log/jailbreakd-stderr.log")) removeFile("/var/log/jailbreakd-stderr.log");
        }
        
        INFO("installing bootstrap...");
        
        if(fileExists(in_bundle("iosbinpack.tar"))) {
            chdir("/var/containers/Bundle/");
            FILE *bootstrap = fopen((char*)in_bundle("iosbinpack.tar"), "r");
            extract_tar(bootstrap, "/var/containers/Bundle/");
            fclose(bootstrap);
        }
        
        if(fileExists(in_bundle("tweaksupport.tar"))) {
            FILE *tweaks = fopen((char*)in_bundle("tweaksupport.tar"), "r");
            extract_tar(tweaks, "/var/containers/Bundle/");
            fclose(tweaks);
            
            if(!fileExists("/var/containers/Bundle/tweaksupport") || !fileExists("/var/containers/Bundle/iosbinpack64")) {
                ERROR("[-] Failed to install bootstrap");
            }
        }
        
        // REMOVE THIS LINE WHEN TWEAK SUPPORT IS ADDED
        mkdir("/var/containers/Bundle/tweaksupport", 0777);
        if(!fileExists("/var/containers/Bundle/iosbinpack64")) {
            ERROR("failed to install bootstrap");
            return false;
        }
        
        INFO("creating symlinks...");
        
        //        symlink("/var/containers/Bundle/tweaksupport/Library", "/var/LIB");
        //        symlink("/var/containers/Bundle/tweaksupport/usr/lib", "/var/ulb");
        //        symlink("/var/containers/Bundle/tweaksupport/Applications", "/var/Apps");
        //        symlink("/var/containers/Bundle/tweaksupport/bin", "/var/bin");
        //        symlink("/var/containers/Bundle/tweaksupport/sbin", "/var/sbin");
        //        symlink("/var/containers/Bundle/tweaksupport/usr/libexec", "/var/libexec");
        
        close(open("/var/containers/Bundle/.installed_rootlessJB3", O_CREAT));
        
        //limneos
        symlink("/var/containers/Bundle/iosbinpack64/etc", "/var/etc");
        //        symlink("/var/containers/Bundle/tweaksupport/usr", "/var/usr");
        symlink("/var/containers/Bundle/iosbinpack64/usr/bin/killall", "/var/bin/killall");
        
        INFO("installed bootstrap!");
    }
    return true;
}

void unpack_binaries(void) {
    prepare_payload();
    
    NSError *error = NULL;
    if(fileExists(in_bundle("dropbear.v2018.76.tar"))) {
        removeFile("/var/containers/Bundle/iosbinpack64/usr/local/bin/dropbear");
        removeFile("/var/containers/Bundle/iosbinpack64/usr/bin/scp");
        
        chdir("/var/containers/Bundle/");
        FILE *fixed_dropbear = fopen(in_bundle("dropbear.v2018.76.tar"), "r");
        extract_tar(fixed_dropbear, "/var/containers/Bundle/");
        fclose(fixed_dropbear);
        INFO("installed Dropbear SSH!");
    }
    
    if(fileExists(in_bundle("jailbreakd.tar"))) {
        removeFile("/var/containers/Bundle/iosbinpack64/bin/jailbreakd");
        if (!fileExists(in_bundle("jailbreakd"))) {
            chdir(in_bundle(""));
            
            FILE *jbd = fopen(in_bundle("jailbreakd.tar"), "r");
            extract_tar(jbd, in_bundle("jailbreakd"));
            fclose(jbd);
            
            removeFile(in_bundle("jailbreakd.tar"));
        }
        copyFile(in_bundle("jailbreakd"), "/var/containers/Bundle/iosbinpack64/bin/jailbreakd");
    }
}

void prepare_dropbear(void) {
    NSError *error = NULL;
    mkdir("/var/dropbear", 0777);
    removeFile("/var/profile");
    removeFile("/var/motd");
    chmod("/var/profile", 0777);
    chmod("/var/motd", 0777);
    
    copyFile("/var/containers/Bundle/iosbinpack64/etc/profile", "/var/profile");
    copyFile("/var/containers/Bundle/iosbinpack64/etc/motd", "/var/motd");
    FILE *motd = fopen("/var/motd", "w");
    struct utsname ut;
    uname(&ut);
    fprintf(motd, "A12 dropbear exec by @xavo95\n");
    fprintf(motd, "%s %s %s %s %s\n", ut.sysname, ut.nodename, ut.release, ut.version, ut.machine);
    fclose(motd);
    chmod("/var/motd", 0777);

    launch_binary("/var/containers/Bundle/iosbinpack64/usr/bin/killall", "-SEGV", "dropbear", NULL, NULL, NULL, NULL, NULL);
}

void unpack_launchdeamons(uint64_t kernel_load_base) {
    NSError *error = NULL;
    if(fileExists(in_bundle("dropbear.plist"))) {
        removeFile("/var/containers/Bundle/iosbinpack64/LaunchDaemons/dropbear.plist");
        copyFile(in_bundle("dropbear.plist"), "/var/containers/Bundle/iosbinpack64/LaunchDaemons/dropbear.plist");
    }
    if(fileExists(in_bundle("jailbreakd.plist"))) {
        removeFile("/var/containers/Bundle/iosbinpack64/LaunchDaemons/jailbreakd.plist");
        copyFile(in_bundle("jailbreakd.plist"), "/var/containers/Bundle/iosbinpack64/LaunchDaemons/jailbreakd.plist");
    }
    //------------- launch daeamons -------------//
    //-- you can drop any daemon plist in iosbinpack64/LaunchDaemons and it will be loaded automatically --//
    NSArray *plists = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:@"/var/containers/Bundle/iosbinpack64/LaunchDaemons" error:nil];
    
    for (__strong NSString *file in plists) {
        INFO("adding permissions to plist %s", [file UTF8String]);
        
        file = [@"/var/containers/Bundle/iosbinpack64/LaunchDaemons" stringByAppendingPathComponent:file];
        
        if (strstr([file UTF8String], "jailbreakd")) {
            INFO("found jailbreakd plist, special handling");
            
            NSMutableDictionary *job = [NSPropertyListSerialization propertyListWithData:[NSData dataWithContentsOfFile:file] options:NSPropertyListMutableContainers format:nil error:nil];
            
            job[@"EnvironmentVariables"][@"KernelBase"] = [NSString stringWithFormat:@"0x%16llx", kernel_load_base];
            [job writeToFile:file atomically:YES];
        }
        
        chmod([file UTF8String], 0644);
        chown([file UTF8String], 0, 0);
    }
    
    // clean up
    removeFile("/var/log/testbin.log");
    removeFile("/var/log/jailbreakd-stderr.log");
    removeFile("/var/log/jailbreakd-stdout.log");
    
    launch_binary("/var/containers/Bundle/iosbinpack64/bin/launchctl", "unload", "/var/containers/Bundle/iosbinpack64/LaunchDaemons", NULL, NULL, NULL, NULL, NULL);
    launch_binary("/var/containers/Bundle/iosbinpack64/bin/launchctl", "load", "/var/containers/Bundle/iosbinpack64/LaunchDaemons", NULL, NULL, NULL, NULL, NULL);
    
    sleep(1);
    
    if(!fileExists("/var/log/testbin.log")) {
        ERROR("failed to load launch daemons");
        cleanup();
    }
    if(!fileExists("/var/log/jailbreakd-stdout.log")) {
        ERROR("failed to load jailbreakd");
        cleanup();
    }
}
