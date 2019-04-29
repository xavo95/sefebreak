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
#include "vnode.h"
#include "insert_dylib.h"

#define in_bundle(obj) strdup([[[[NSBundle mainBundle] bundlePath] stringByAppendingPathComponent:@(obj)] UTF8String])

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

void if_exists_remove_copy(char *src, char *dst) {
    NSError *error = NULL;
    if(fileExists(in_bundle(src))) {
        removeFile(dst);
    }
    copyFile(in_bundle(src), dst);
}

void extract_resource(char *src, char *dst) {
    chdir(dst);
    FILE *bootstrap = fopen((char*)in_bundle(src), "r");
    untar(bootstrap, dst);
    fclose(bootstrap);
}

void copy_per_arch(char *src_dir, char *dst, char *executable, cpu_subtype_t cpu_subtype) {
    char *path;
    if(cpu_subtype == CPU_SUBTYPE_ARM64E) {
        asprintf(&path, "%s/%s.arm64e", src_dir, executable);
    } else {
        asprintf(&path, "%s/%s.arm64", src_dir, executable);
    }
    NSError *error = NULL;
    removeFile(dst);
    copyFile(path, dst);
    free(path);
}

void extract_dylib(char *src, char *intermediate, char *dst) {
    NSError *error = NULL;
    if(fileExists(src)) {
        char *intermediate_path = in_bundle(intermediate);
        if (!fileExists(intermediate_path)) {
            chdir(in_bundle("bins/"));
            
            FILE *jbd = fopen(src, "r");
            untar(jbd, intermediate_path);
            fclose(jbd);
            
            removeFile(src);
        }
        if_exists_remove_copy(intermediate, dst);
    }
}

bool clean_up_previous(bool force_reinstall, cpu_subtype_t cpu_subtype) {
    NSError *error = NULL;
    if (!fileExists("/var/containers/Bundle/.installed_rootlessJB3") || force_reinstall) {
        
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
        
        if(fileExists(in_bundle("tars/iosbinpack.tar"))) {
            extract_resource("tars/iosbinpack.tar", "/var/containers/Bundle/");
        }
        if(fileExists(in_bundle("tars/tweaksupport.tar"))) {
            extract_resource("tars/tweaksupport.tar", "/var/containers/Bundle/");
        }
        
        if(!fileExists("/var/containers/Bundle/tweaksupport") || !fileExists("/var/containers/Bundle/iosbinpack64")) {
            ERROR("failed to install bootstrap");
            return false;
        }
        
        INFO("creating symlinks...");
        
        symlink("/var/containers/Bundle/tweaksupport/Library", "/var/LIB");
        symlink("/var/containers/Bundle/tweaksupport/usr/lib", "/var/ulb");
        symlink("/var/containers/Bundle/tweaksupport/Applications", "/var/Apps");
        symlink("/var/containers/Bundle/tweaksupport/bin", "/var/bin");
        symlink("/var/containers/Bundle/tweaksupport/sbin", "/var/sbin");
        symlink("/var/containers/Bundle/tweaksupport/usr/libexec", "/var/libexec");
        
        close(open("/var/containers/Bundle/.installed_rootlessJB3", O_CREAT));
        
        //limneos
        symlink("/var/containers/Bundle/iosbinpack64/etc", "/var/etc");
        symlink("/var/containers/Bundle/tweaksupport/usr", "/var/usr");
        symlink("/var/containers/Bundle/iosbinpack64/usr/bin/killall", "/var/bin/killall");
        
        INFO("installed bootstrap!");
    }
    return true;
}

void unpack_binaries(cpu_subtype_t cpu_subtype) {
    NSError *error = NULL;
    if(fileExists(in_bundle("tars/utilspack.tar"))) {
        char *staging_dir = in_bundle("staging");
        mkdir(staging_dir, 0777);
        extract_resource("tars/utilspack.tar", staging_dir);
        copy_per_arch(staging_dir, "/var/containers/Bundle/iosbinpack64/usr/local/bin/binbag", "binbag", cpu_subtype);
        copy_per_arch(staging_dir, "/var/containers/Bundle/iosbinpack64/usr/local/bin/bash", "bash", cpu_subtype);
        if_exists_remove_copy("staging/jtool2", "/var/containers/Bundle/iosbinpack64/usr/local/bin/jtool2");
        if_exists_remove_copy("staging/ldid", "/var/containers/Bundle/iosbinpack64/usr/local/bin/ldid");
        rmdir(staging_dir);
    }
    
    if(fileExists(in_bundle("tars/extrabins.tar"))) {
        char *staging_dir = in_bundle("staging");
        mkdir(staging_dir, 0777);
        extract_resource("tars/extrabins.tar", staging_dir);
        copy_per_arch(staging_dir, "/var/containers/Bundle/iosbinpack64/usr/local/bin/injector", "injector", cpu_subtype);
        copy_per_arch(staging_dir, "/var/containers/Bundle/iosbinpack64/usr/local/bin/unrestrict", "unrestrict", cpu_subtype);
        if_exists_remove_copy("staging/postexp.dylib", "/var/containers/Bundle/tweaksupport/usr/lib/postexp.dylib");
        rmdir(staging_dir);
    }
    
    if(fileExists(in_bundle("tars/dropbear.v2018.76.tar"))) {
        removeFile("/var/containers/Bundle/iosbinpack64/usr/local/bin/dropbear");
        removeFile("/var/containers/Bundle/iosbinpack64/usr/bin/scp");
        
        chdir("/var/containers/Bundle/");
        FILE *fixed_dropbear = fopen(in_bundle("tars/dropbear.v2018.76.tar"), "r");
        untar(fixed_dropbear, "/var/containers/Bundle/");
        fclose(fixed_dropbear);
        INFO("installed Dropbear SSH!");
    }
    
//    if(fileExists(in_bundle("tars/jailbreakd.tar"))) {
//        if (!fileExists(in_bundle("jailbreakd"))) {
//            chdir(in_bundle(""));
//
//            FILE *jbd = fopen(in_bundle("tars/jailbreakd.tar"), "r");
//            untar(jbd, in_bundle("jailbreakd"));
//            fclose(jbd);
//
//            removeFile(in_bundle("tars/jailbreakd.tar"));
//        }
//        if_exists_remove_copy("jailbreakd", "/var/containers/Bundle/iosbinpack64/bin/jailbreakd");
//    }
    
    if(fileExists(in_bundle("tars/jailbreakd2.tar"))) {
        if (!fileExists(in_bundle("jailbreakd"))) {
            chdir(in_bundle(""));
            
            FILE *jbd = fopen(in_bundle("tars/jailbreakd2.tar"), "r");
            untar(jbd, in_bundle("jailbreakd"));
            fclose(jbd);
            
            removeFile(in_bundle("tars/jailbreakd2.tar"));
        }
        if_exists_remove_copy("jailbreakd", "/var/containers/Bundle/iosbinpack64/bin/jailbreakd");
    }
    
    extract_dylib(in_bundle("bins/pspawn.dylib.tar"), "bins/pspawn_hook.dylib", "/var/containers/Bundle/tweaksupport/usr/lib/pspawn.dylib");
    extract_dylib(in_bundle("bins/substitute.dylib.tar"), "bins/libsubstitute.dylib", "/var/containers/Bundle/tweaksupport/usr/lib/libsubstitute.dylib");
    extract_dylib(in_bundle("bins/libjailbreak.dylib.tar"), "bins/libjailbreak.dylib", "/var/containers/Bundle/tweaksupport/usr/lib/libjailbreak.dylib");
    extract_dylib(in_bundle("bins/amfid_payload.dylib.tar"), "bins/amfid_payload.dylib", "/var/containers/Bundle/tweaksupport/usr/lib/amfid_payload.dylib");
    
    prepare_payload();
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

    launch("/var/containers/Bundle/iosbinpack64/usr/bin/killall", "-SEGV", "dropbear", NULL, NULL, NULL, NULL, NULL);
}

void unpack_launchdeamons() {
    NSError *error = NULL;
    if_exists_remove_copy("daemons/dropbear.plist", "/var/containers/Bundle/iosbinpack64/LaunchDaemons/dropbear.plist");
    if_exists_remove_copy("daemons/jailbreakd.plist", "/var/containers/Bundle/iosbinpack64/LaunchDaemons/jailbreakd.plist");
    //------------- launch daeamons -------------//
    //-- you can drop any daemon plist in iosbinpack64/LaunchDaemons and it will be loaded automatically --//
    NSArray *plists = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:@"/var/containers/Bundle/iosbinpack64/LaunchDaemons" error:nil];
    
    for (__strong NSString *file in plists) {
        INFO("adding permissions to plist %s", [file UTF8String]);
        
        file = [@"/var/containers/Bundle/iosbinpack64/LaunchDaemons" stringByAppendingPathComponent:file];
        
        if (strstr([file UTF8String], "jailbreakd")) {
            INFO("found jailbreakd plist, special handling");
            
            NSMutableDictionary *job = [NSPropertyListSerialization propertyListWithData:[NSData dataWithContentsOfFile:file] options:NSPropertyListMutableContainers format:nil error:nil];
            
            job[@"EnvironmentVariables"][@"KernelBase"] = [NSString stringWithFormat:@"0x%16llx", get_symbol_by_name("kernel_load_base")];
            job[@"EnvironmentVariables"][@"KernProcAddr"] = [NSString stringWithFormat:@"0x%16llx", get_symbol_by_name("kernproc")];
            job[@"EnvironmentVariables"][@"ZoneMapOffset"] = [NSString stringWithFormat:@"0x%16llx", get_symbol_by_name("zone_map_ref")];
            job[@"EnvironmentVariables"][@"AddRetGadget"] = [NSString stringWithFormat:@"0x%16llx", get_symbol_by_name("add_x0_x0_0x40_ret")];
            job[@"EnvironmentVariables"][@"OSBooleanTrue"] = [NSString stringWithFormat:@"0x%16llx", get_symbol_by_name("OSBooleanTrue")];
            job[@"EnvironmentVariables"][@"OSBooleanFalse"] = [NSString stringWithFormat:@"0x%16llx", get_symbol_by_name("OSBooleanFalse")];
            job[@"EnvironmentVariables"][@"OSUnserializeXML"] = [NSString stringWithFormat:@"0x%16llx", get_symbol_by_name("OSUnserializeXML")];
            job[@"EnvironmentVariables"][@"Smalloc"] = [NSString stringWithFormat:@"0x%16llx", get_symbol_by_name("smalloc")];
            job[@"EnvironmentVariables"][@"KernelTask"] = [NSString stringWithFormat:@"0x%16llx", get_symbol_by_name("kernel_task")];
            job[@"EnvironmentVariables"][@"PacizaPointerL2TPDomainModuleStart"] = [NSString stringWithFormat:@"0x%16llx", get_symbol_by_name("paciza_pointer__l2tp_domain_module_start")];
            job[@"EnvironmentVariables"][@"PacizaPointerL2TPDomainModuleStop"] = [NSString stringWithFormat:@"0x%16llx", get_symbol_by_name("paciza_pointer__l2tp_domain_module_stop")];
            job[@"EnvironmentVariables"][@"SysctlNetPPPL2TP"] = [NSString stringWithFormat:@"0x%16llx", get_symbol_by_name("sysctl__net_ppp_l2tp")];
            job[@"EnvironmentVariables"][@"SysctlUnregisterOid"] = [NSString stringWithFormat:@"0x%16llx", get_symbol_by_name("sysctl_unregister_oid")];
            job[@"EnvironmentVariables"][@"MovX0X4BrX5"] = [NSString stringWithFormat:@"0x%16llx", get_symbol_by_name("mov_x0_x4__br_x5")];
            job[@"EnvironmentVariables"][@"MovX9X0BrX1"] = [NSString stringWithFormat:@"0x%16llx", get_symbol_by_name("mov_x9_x0__br_x1")];
            job[@"EnvironmentVariables"][@"MovX10X3BrX6"] = [NSString stringWithFormat:@"0x%16llx", get_symbol_by_name("mov_x10_x3__br_x6")];
            job[@"EnvironmentVariables"][@"KernelForgePaciaGadget"] = [NSString stringWithFormat:@"0x%16llx", get_symbol_by_name("kernel_forge_pacia_gadget")];
            job[@"EnvironmentVariables"][@"KernelForgePacdaGadget"] = [NSString stringWithFormat:@"0x%16llx", get_symbol_by_name("kernel_forge_pacda_gadget")];
            job[@"EnvironmentVariables"][@"IOUserClientVtable"] = [NSString stringWithFormat:@"0x%16llx", get_symbol_by_name("IOUserClient__vtable")];
            job[@"EnvironmentVariables"][@"IORegistryEntryGetRegistryEntryID"] = [NSString stringWithFormat:@"0x%16llx", get_symbol_by_name("IORegistryEntry__getRegistryEntryID")];
            [job writeToFile:file atomically:YES];
        }
        
        chmod([file UTF8String], 0644);
        chown([file UTF8String], 0, 0);
    }
    
    // clean up
    removeFile("/var/log/testbin.log");
    removeFile("/var/log/jailbreakd-stderr.log");
    removeFile("/var/log/jailbreakd-stdout.log");
    
    unload_launchdeamons("/var/containers/Bundle/iosbinpack64/bin/launchctl", "/var/containers/Bundle/iosbinpack64/LaunchDaemons");
    load_launchdeamons("/var/containers/Bundle/iosbinpack64/bin/launchctl", "/var/containers/Bundle/iosbinpack64/LaunchDaemons");
    
    sleep(1);
    
    if(!fileExists("/var/log/jailbreakd-stdout.log")) {
        ERROR("failed to load jailbreakd");
        cleanup();
    }
}

void enable_tweaks(void) {
    //----- magic start here -----//
    INFO("time for magic");
    
    char *xpcproxy = "/var/libexec/xpcproxy";
    char *dylib = "/var/ulb/pspawn.dylib";
    
    NSError *error = NULL;
    if (!fileExists(xpcproxy)) {
        bool cp = copyFile("/usr/libexec/xpcproxy", xpcproxy);
        if(!cp) {
            ERROR("can't copy xpcproxy!");
            return;
        }
        symlink("/var/containers/Bundle/iosbinpack64/pspawn.dylib", dylib);
        INFO("patching xpcproxy");
        const char *args[] = { "insert_dylib", "--all-yes", "--inplace", "--overwrite", dylib, xpcproxy, NULL};
        int argn = 6;
        if(add_dylib(argn, args)) {
            ERROR("failed to patch xpcproxy :(");
            return;
        }
        INFO("resigning xpcproxy");
        int res = launch("/var/containers/Bundle/iosbinpack64/usr/local/bin/ldid", "-S/var/containers/Bundle/iosbinpack64/default.ent", xpcproxy, NULL, NULL, NULL, NULL, NULL);
        if(res) {
            ERROR("failed to resign xpcproxy!");
            return;
        }
    }
    
    chown(xpcproxy, 0, 0);
    chmod(xpcproxy, 755);
    if(add_to_trustcache(xpcproxy)) {
        ERROR("failed to trust xpcproxy!");
        return;
    }
    
    kernel_call_init();
    
    uint64_t realxpc = get_vnode_at_path("/usr/libexec/xpcproxy");
    uint64_t fakexpc = get_vnode_at_path(xpcproxy);
    
    struct vnode rvp, fvp;
    kernel_read(realxpc, &rvp, sizeof(struct vnode));
    kernel_read(fakexpc, &fvp, sizeof(struct vnode));

    fvp.v_usecount = rvp.v_usecount;
    fvp.v_kusecount = rvp.v_kusecount;
    fvp.v_parent = rvp.v_parent;
    fvp.v_freelist = rvp.v_freelist;
    fvp.v_mntvnodes = rvp.v_mntvnodes;
    fvp.v_ncchildren = rvp.v_ncchildren;
    fvp.v_nclinks = rvp.v_nclinks;
    
    kernel_write(realxpc, &fvp, sizeof(struct vnode)); // :o
    INFO("are we still alive?!");
    
    //----- magic end here -----//
    
    // cache pid and we're done
    pid_t installd = pid_of_proc_name("installd");
    pid_t bb = pid_of_proc_name("backboardd");
    pid_t amfid = pid_of_proc_name("amfid");
    if (amfid) kill(amfid, SIGKILL);
    
    // AppSync
    
    fix_mmap("/var/ulb/libsubstitute.dylib");
    //fix_mmap("/var/LIB/Frameworks/CydiaSubstrate.framework/CydiaSubstrate");
    //fix_mmap("/var/LIB/MobileSubstrate/DynamicLibraries/AppSyncUnified.dylib");
    
    if (installd) kill(installd, SIGKILL);
    
//    if ([self.installiSuperSU isOn]) {
//        LOG("[*] Installing iSuperSU");
//
//        removeFile("/var/containers/Bundle/tweaksupport/Applications/iSuperSU.app");
//        copyFile(in_bundle("apps/iSuperSU.app"), "/var/containers/Bundle/tweaksupport/Applications/iSuperSU.app");
//
//        failIf(system_("/var/containers/Bundle/tweaksupport/usr/local/bin/jtool --sign --inplace --ent /var/containers/Bundle/tweaksupport/Applications/iSuperSU.app/ent.xml /var/containers/Bundle/tweaksupport/Applications/iSuperSU.app/iSuperSU && /var/containers/Bundle/tweaksupport/usr/bin/inject /var/containers/Bundle/tweaksupport/Applications/iSuperSU.app/iSuperSU"), "[-] Failed to sign iSuperSU");
//
//
//        // just in case
//        fixMmap("/var/ulb/libsubstitute.dylib");
//        fixMmap("/var/LIB/Frameworks/CydiaSubstrate.framework/CydiaSubstrate");
//        fixMmap("/var/LIB/MobileSubstrate/DynamicLibraries/AppSyncUnified.dylib");
//
//        failIf(launch("/var/containers/Bundle/tweaksupport/usr/bin/uicache", NULL, NULL, NULL, NULL, NULL, NULL, NULL), "[-] Failed to install iSuperSU");
//
//    }
//
//    // kill any daemon/executable being hooked by tweaks (except for the obvious, assertiond, backboardd and SpringBoard)
//
//    NSArray *tweaks = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:@"/var/ulb/TweakInject" error:NULL];
//    for (NSString *afile in tweaks) {
//        if ([afile hasSuffix:@"plist"]) {
//
//            NSDictionary *plist = [NSDictionary dictionaryWithContentsOfFile:[NSString stringWithFormat:@"/var/ulb/TweakInject/%@",afile]];
//            NSString *dylibPath = [afile stringByReplacingOccurrencesOfString:@".plist" withString:@".dylib"];
//            fixMmap((char *)[[NSString stringWithFormat:@"/var/ulb/TweakInject/%@", dylibPath] UTF8String]);
//            NSArray *executables = [[plist objectForKey:@"Filter"] objectForKey:@"Executables"];
//
//            for (NSString *processName in executables) {
//                if (![processName isEqual:@"SpringBoard"] && ![processName isEqual:@"backboardd"] && ![processName isEqual:@"assertiond"] && ![processName isEqual:@"launchd"]) { //really?
//                    int procpid = pid_of_procName((char *)[processName UTF8String]);
//                    if (procpid) {
//                        kill(procpid, SIGKILL);
//                    }
//                }
//            }
//
//            NSArray *bundles = [[plist objectForKey:@"Filter"] objectForKey:@"Bundles"];
//            for (NSString *bundleID in bundles) {
//                if (![bundleID isEqual:@"com.apple.springboard"] && ![bundleID isEqual:@"com.apple.backboardd"] && ![bundleID isEqual:@"com.apple.assertiond"] && ![bundleID isEqual:@"com.apple.launchd"]) {
//                    NSString *processName = [bundleID stringByReplacingOccurrencesOfString:@"com.apple." withString:@""];
//                    int procpid = pid_of_procName((char *)[processName UTF8String]);
//                    if (procpid) {
//                        kill(procpid, SIGKILL);
//                    }
//                }
//
//            }
//        }
//    }
//
//    // find which applications are jailbreak applications and inject their executable
//    NSArray *applications = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:@"/var/containers/Bundle/Application/" error:NULL];
//
//    for (NSString *string in applications) {
//        NSString *fullPath = [@"/var/containers/Bundle/Application/" stringByAppendingString:string];
//        NSArray *innerContents = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:fullPath error:NULL];
//        for (NSString *innerFile in innerContents) {
//            if ([innerFile hasSuffix:@"app"]) {
//
//                NSString *fullAppBundlePath = [fullPath stringByAppendingString:[NSString stringWithFormat:@"/%@",innerFile]];
//                NSString *_CodeSignature = [fullPath stringByAppendingString:[NSString stringWithFormat:@"/%@/_CodeSignature",innerFile]];
//
//                NSDictionary *infoPlist = [NSDictionary dictionaryWithContentsOfFile:[NSString stringWithFormat:@"%@/Info.plist",fullAppBundlePath]];
//                NSString *executable = [infoPlist objectForKey:@"CFBundleExecutable"];
//                NSString *BuildMachineOSBuild = [infoPlist objectForKey:@"BuildMachineOSBuild"];
//                BOOL hasDTCompilerRelatedKeys=NO;
//                for (NSString *KEY in [infoPlist allKeys]) {
//                    if ([KEY rangeOfString:@"DT"].location==0) {
//                        hasDTCompilerRelatedKeys=YES;
//                        break;
//                    }
//                }
//                // check for keys added by native/appstore apps and exclude (theos and friends don't add BuildMachineOSBuild and DT_ on apps :-D )
//                // Xcode-added apps set CFBundleExecutable=Executable, exclude them too
//
//                executable = [NSString stringWithFormat:@"%@/%@", fullAppBundlePath, executable];
//
//                if (([[NSFileManager defaultManager] fileExistsAtPath:[NSString stringWithFormat:@"%@/.jb",fullAppBundlePath]] || ![[NSFileManager defaultManager] fileExistsAtPath:_CodeSignature] || (executable && ![executable isEqual:@"Executable"] && !BuildMachineOSBuild & !hasDTCompilerRelatedKeys)) && fileExists([executable UTF8String])) {
//
//                    LOG("Injecting executable %s",[executable UTF8String]);
//                    system_((char *)[[NSString stringWithFormat:@"/var/containers/Bundle/iosbinpack64/usr/bin/inject %s", [executable UTF8String]] UTF8String]);
//                }
//
//            }
//        }
//    }
    
    INFO("really jailbroken!");
    kernel_call_deinit();
    // bye bye
    //    kill(bb, 9);
}
