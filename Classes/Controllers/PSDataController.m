//
//  PSDataController.m
//  Prismo
//
//  Created by Sergey Lenkov on 06.02.11.
//  Copyright 2011 Sergey Lenkov. All rights reserved.
//

#import "PSDataController.h"


@implementation PSDataController

@synthesize printableView;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    
    if (self) {
        self.printableView = nil;
        defaults = [NSUserDefaults standardUserDefaults];
    }
    
    return self;
}

- (void)dealloc {
    [popoverController release];
    [super dealloc];
}

- (void)awakeFromNib {
    [super awakeFromNib];
    
    if (popoverController) {
        [popoverController.popoverWindow setBorderColor:[NSColor colorWithDeviceRed:140.0/255.0 green:140.0/255.0 blue:140.0/255.0 alpha:1.0]];
        [popoverController.popoverWindow setBorderWidth:1.0];
        [popoverController.popoverWindow setPopoverBackgroundColor:[NSColor colorWithDeviceRed:255.0/255.0 green:255.0/255.0 blue:255.0/255.0 alpha:0.8]];
        [popoverController.popoverWindow setDrawRoundCornerBesideArrow:YES];
        [popoverController.popoverWindow setDrawsArrow:YES];
    }
}

- (void)reloadData {
    
}

- (void)initialization {
    
}

- (void)refresh {

}

- (void)print {
    if ([self isCanPrint] && printableView != nil) {
        NSPrintInfo *sharedPrintInfo = [NSPrintInfo sharedPrintInfo];
        [sharedPrintInfo setHorizontalPagination:NSFitPagination];
        
        [printableView print:nil];
    }    
}

- (void)exportToFile:(NSURL *)fileName {
    
}

- (BOOL)isCanPrint {
    return NO;
}

- (BOOL)isCanExport {
    return NO;
}

- (IBAction)showFilter:(id)sender {   
    if([[popoverController window] isVisible])
		[popoverController closePopover:sender];
	else {
        NSPoint point = NSMakePoint(NSMidX([sender bounds]), NSMaxY([sender bounds]));
        NSPoint windowPoint = [sender convertPoint:point toView:nil]; // Convert the point to window coordinates

        //[popoverController displayPopoverInWindow:[sender window] atPoint:windowPoint];
        [popoverController displayPopoverInWindow:[sender window] atPoint:windowPoint chooseBestLocation:YES];
    }   
}

@end
