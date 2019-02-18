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

#import "voucher_swap.h"
#import "kernel_slide.h"
#import "log.h"
#import "parameters.h"
#import "postexp.h"

@interface ViewController ()
- (IBAction)getTaskForPid:(id)sender;
- (IBAction)getRootAndEscape:(id)sender;
- (IBAction)copyKernel:(id)sender;
- (IBAction)initializePatchfinder64:(id)sender;
- (IBAction)launchSSH:(id)sender;
@property (weak, nonatomic) IBOutlet UILabel *kernelSlide;
@property (weak, nonatomic) IBOutlet UILabel *kernelBase;
@end

@implementation ViewController

- (void)viewDidLoad {
	[super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
}

- (IBAction)getTaskForPid:(id)sender {
    // Run the exploit
    voucher_swap();
    // Initialize kernel slide (for latter on)
    bool ok = kernel_slide_init();
    if (!ok) {
        ERROR("Error getting kernel slide");
    } else {
        _kernelSlide.text = [NSString stringWithFormat:@"0x%016llx", kernel_slide];
        _kernelBase.text = [NSString stringWithFormat:@"0x%016llx", STATIC_ADDRESS(kernel_base) + kernel_slide];
    }
}

- (IBAction)getRootAndEscape:(id)sender {
    root_and_escape();
}

- (IBAction)copyKernel:(id)sender {
    get_kernel_file();
}

- (IBAction)initializePatchfinder64:(id)sender {
    initialize_patchfinder64();
}

- (IBAction)launchSSH:(id)sender {
    launch_dropbear();
}

@end
