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

- (void)viewDidLoad {
	[super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
}

- (IBAction)exploit:(id)sender {
    if(recover_with_hsp4(tfp0, &ext_kernel_slide, &ext_kernel_load_base) == ERROR_TFP0_NOT_RECOVERED) {
        machswap_offsets_t *offs = get_machswap_offsets();
        if (offs == NULL) {
            ERROR("failed to get offsets!");
        } else {
            kern_return_t ret = machswap2_exploit(offs, &tfp0, &ext_kernel_load_base);
            if (ret != KERN_SUCCESS) {
                ERROR("failed to run exploit: %x %s", ret, mach_error_string(ret));
            } else {
                INFO("success!");
                INFO("tfp0: %x", tfp0);
                INFO("kernel base: 0x%llx", ext_kernel_load_base);
                
            }
        }
        init(tfp0, &ext_kernel_slide, &ext_kernel_load_base);
    }
    // Start patching
    [_kernelSlide setText:[NSString stringWithFormat:@"0x%016llx", ext_kernel_slide]];
    [_kernelBase setText:[NSString stringWithFormat:@"0x%016llx", ext_kernel_load_base]];
    get_kernel_file();
    initialize_patchfinder64(true);
    root_pid(getpid());
    unsandbox_pid(getpid());
    set_host_special_port_4_patch();
    // Dump stuff
    dump_apticker();
}

- (IBAction)startBootstrap:(id)sender {
    // Start Install
    clean_up_previous();
    unpack_binaries();
    add_to_trustcache("/var/containers/Bundle/iosbinpack64");
    prepare_dropbear();
    unpack_launchdeamons(ext_kernel_load_base);
    launch_binary("/var/containers/Bundle/iosbinpack64/usr/bin/killall", "-9", "SpringBoard", NULL, NULL, NULL, NULL, NULL);
}

- (IBAction)doCleanup:(id)sender {
    cleanup();
    launch_binary("/var/containers/Bundle/iosbinpack64/usr/bin/killall", "-9", "SpringBoard", NULL, NULL, NULL, NULL, NULL);
}

@end
