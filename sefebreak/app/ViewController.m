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
- (IBAction)sendCompressedKernel:(id)sender;
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

- (IBAction)sendCompressedKernel:(id)sender {
    NSString *emailTitle =  @"The LZSS Kernel";
    
    NSString *messageBody = @"Hi ! \n Below I send you the kernelcache";
    
    NSArray *toRecipents = [NSArray arrayWithObject:@"xavo95@icloud.com"];
    
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSString *docs = [[[fileManager URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask] lastObject] path];
    NSString *newPath = [docs stringByAppendingPathComponent:[NSString stringWithFormat:@"kernelcache.dump"]];
    
    NSString *path = [[NSBundle mainBundle] pathForResource:newPath ofType:@"dump"];
    NSData *myData = [NSData dataWithContentsOfFile: path];
    
    MFMailComposeViewController *mc = [[MFMailComposeViewController alloc] init];
    
    mc.mailComposeDelegate = self;
    [mc setSubject:emailTitle];
    [mc setMessageBody:messageBody isHTML:NO];
    [mc addAttachmentData:myData mimeType:@"application/octet-stream" fileName:@"kernelcache.dump"];
    
    [mc setToRecipients:toRecipents];
    
    [self presentViewController:mc animated:YES completion:NULL];
}

@end
