//
//  PSDataController.h
//  Prismo
//
//  Created by Sergey Lenkov on 06.02.11.
//  Copyright 2011 Sergey Lenkov. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "SFBPopoverWindowController.h"

@interface PSDataController : NSViewController {
    IBOutlet NSButton *filterButton;
    NSView *printableView;
    NSUserDefaults *defaults;
    SFBPopoverWindowController *popoverController;
}

@property (nonatomic, retain) NSView *printableView;

- (void)reloadData;
- (void)initialization;
- (void)refresh;
- (void)print;
- (void)exportToFile:(NSURL *)fileName;
- (BOOL)isCanPrint;
- (BOOL)isCanExport;

- (IBAction)showFilter:(id)sender;

@end
