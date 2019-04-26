//
//  ViewController.m
//  voucher_swap
//
//  Created by Brandon Azad on 12/7/18.
//  Copyright © 2018 Brandon Azad. All rights reserved.
//

#import "ViewController.h"
#import <Foundation/Foundation.h>
#import <MessageUI/MessageUI.h>

#include "common.h"
#include "pwn.h"
#include "offsets.h"

#import "postexp.h"
#import "log.h"
#import "Unpacker.h"

@interface ViewController ()
- (IBAction)exploit:(id)sender;
- (IBAction)startBootstrap:(id)sender;
- (IBAction)doCleanup:(id)sender;
@property (weak, nonatomic) IBOutlet UILabel *kernelSlide;
@property (weak, nonatomic) IBOutlet UILabel *kernelBase;
@end

@implementation ViewController

uint64_t ext_kernel_slide = 0;
uint64_t ext_kernel_load_base = 0;
mach_port_t tfp0 = 0;
bool exploit_succeded = false;

int get_hsp4_perms(int pid, char *permissions);

- (UIAlertController *)getErrorAlertView:(NSString *)message {
    UIAlertController *alert = [UIAlertController
                                alertControllerWithTitle:@"Error"
                                message:message
                                preferredStyle:UIAlertControllerStyleAlert];
    
    UIAlertAction *noButton = [UIAlertAction
                               actionWithTitle:@"Cancel"
                               style:UIAlertActionStyleDefault
                               handler:nil];
    
    [alert addAction:noButton];
    return alert;
}

- (void)viewDidLoad {
	[super viewDidLoad];
    UIGraphicsBeginImageContext(self.view.frame.size);
    [[UIImage imageNamed:@"Background"] drawInRect:self.view.bounds];
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    self.view.backgroundColor = [UIColor colorWithPatternImage:image];
    self.navigationController.navigationBar.barStyle = UIBarStyleBlackTranslucent;
    self.navigationController.navigationBar.topItem.title = @"Sefebreak";
	// Do any additional setup after loading the view, typically from a nib.
}

- (IBAction)exploit:(id)sender {
    // TODO: Fix jailbreakd
//    get_hsp4_perms(getpid(), "    <key>platform-application</key>\n"
//                   "    <true/>\n"
//                   "    <key>get-task-allow</key>\n"
//                   "    <true/>\n"
//                   "    <key>om.apple.system-task-ports</key>\n"
//                   "    <true/>\n"
//                   "    <key>task_for_pid-allow</key>\n"
//                   "    <true/>");
    enum post_exp_t res = recover_with_hsp4(&tfp0, &ext_kernel_slide, &ext_kernel_load_base);
    exploit_succeded = verify_tfp0();
    if((res == ERROR_TFP0_NOT_RECOVERED) || !exploit_succeded) {
        machswap_offsets_t *offs = get_machswap_offsets();
        if (offs == NULL) {
            ERROR("failed to get offsets!");
            [self presentViewController:[self getErrorAlertView:@"Failed getting offsets for machswap2"] animated:YES completion:nil];
            return;
        }
        kern_return_t ret = machswap2_exploit(offs, &tfp0, &ext_kernel_load_base);
        if (ret != KERN_SUCCESS) {
            ERROR("failed to run exploit: %x %s", ret, mach_error_string(ret));
            [self presentViewController:[self getErrorAlertView:[NSString stringWithFormat:@"Failed to run exploit: %x %s", ret, mach_error_string(ret)]] animated:YES completion:nil];
            return;
        }
        INFO("success!");
        INFO("tfp0: %x", tfp0);
        INFO("kernel base: 0x%llx", ext_kernel_load_base);
        // Start patching
        if (init(tfp0, &ext_kernel_slide, &ext_kernel_load_base) != NO_ERROR) {
            [self presentViewController:[self getErrorAlertView:@"Error initializing postexp"] animated:YES completion:nil];
            return;
        }
        exploit_succeded = verify_tfp0();
        if (!exploit_succeded) {
            [self presentViewController:[self getErrorAlertView:@"Failed to exploit machswap2, retry later"] animated:YES completion:nil];
            return;
        }
        if (get_kernel_file() != NO_ERROR) {
            [self presentViewController:[self getErrorAlertView:@"Error copying the kernelcache"] animated:YES completion:nil];
            cleanup();
            return;
        }
        if (initialize_patchfinder64(true) != NO_ERROR) {
            [self presentViewController:[self getErrorAlertView:@"Error initializing patchfinder64"] animated:YES completion:nil];
            cleanup();
            return;
        }
        if (root_pid(getpid()) != NO_ERROR) {
            [self presentViewController:[self getErrorAlertView:@"Error getting root"] animated:YES completion:nil];
            cleanup();
            return;
        }
        if (unsandbox_pid(getpid()) != NO_ERROR) {
            [self presentViewController:[self getErrorAlertView:@"Error unsandboxing"] animated:YES completion:nil];
            cleanup();
            return;
        }
        if (set_host_special_port_4_patch() != NO_ERROR) {
            [self presentViewController:[self getErrorAlertView:@"Error setting task for pid 0 as host special port 4"] animated:YES completion:nil];
            cleanup();
            return;
        }
        // Dump stuff
        if (dump_apticker() != NO_ERROR) {
            [self presentViewController:[self getErrorAlertView:@"Error dumping APticket"] animated:YES completion:nil];
            cleanup();
            return;
        }
    }
    [_kernelSlide setText:[NSString stringWithFormat:@"0x%016llx", ext_kernel_slide]];
    [_kernelBase setText:[NSString stringWithFormat:@"0x%016llx", ext_kernel_load_base]];
}

- (IBAction)startBootstrap:(id)sender {
    if (!exploit_succeded) {
        [self presentViewController:[self getErrorAlertView:@"To do that you need first to run the exploit successfully"] animated:YES completion:nil];
        return;
    }
    // Start Install
    host_basic_info_data_t basic_info;
    mach_msg_type_number_t count = HOST_BASIC_INFO_COUNT;
    kern_return_t kr = host_info(mach_host_self(), HOST_BASIC_INFO, (host_info_t) &basic_info, &count);
    if(kr != KERN_SUCCESS) {
        return;
    }
    clean_up_previous(false, basic_info.cpu_subtype);
    unpack_binaries(basic_info.cpu_subtype);
    add_to_trustcache("/var/containers/Bundle/iosbinpack64");
    prepare_dropbear();
    unpack_launchdeamons(ext_kernel_load_base);
    respring("/var/containers/Bundle/iosbinpack64/usr/bin/killall");
}

- (IBAction)doCleanup:(id)sender {
    if (!exploit_succeded) {
        [self presentViewController:[self getErrorAlertView:@"To do that you need first to run the exploit successfully"] animated:YES completion:nil];
        return;
    }
    cleanup();
    respring("/var/containers/Bundle/iosbinpack64/usr/bin/killall");
}

@end
