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

@interface ViewController ()
- (IBAction)exploit:(id)sender;
- (IBAction)startBootstrap:(id)sender;
- (IBAction)doCleanup:(id)sender;
@property (weak, nonatomic) IBOutlet UILabel *kernelSlide;
@property (weak, nonatomic) IBOutlet UILabel *kernelBase;
@end

@implementation ViewController

- (void)viewDidLoad {
	[super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
}

- (IBAction)exploit:(id)sender {
    uint64_t ext_kernel_slide = 0;
    uint64_t ext_kernel_load_base = 0;
    if(recover_with_hsp4(true, &ext_kernel_slide, &ext_kernel_load_base) == ERROR_TFP0_NOT_RECOVERED) {
        mach_port_t tfp0 = 0;
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
        init(tfp0, true, &ext_kernel_slide, &ext_kernel_load_base);
    }
    [_kernelSlide setText:[NSString stringWithFormat:@"0x%016llx", ext_kernel_slide]];
    [_kernelBase setText:[NSString stringWithFormat:@"0x%016llx", ext_kernel_load_base]];
    initialize_patchfinder64();
    root_pid(getpid());
    unsandbox_pid(getpid());
    get_kernel_file();
    set_host_special_port_4_patch();
}

- (IBAction)startBootstrap:(id)sender {
    bootstrap();
}

- (IBAction)doCleanup:(id)sender {
    cleanup();
}

@end
