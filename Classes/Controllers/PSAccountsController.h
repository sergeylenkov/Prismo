//
//  PSAccountsController.h
//  Prismo
//
//  Created by Sergey Lenkov on 08.02.11.
//  Copyright 2011 Sergey Lenkov. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "PTKeychain.h"

@interface PSAccountsController : NSObject {
	IBOutlet NSTableView *view;
	IBOutlet NSButton *deleteButton;
	NSMutableArray *accounts;
}

- (void)initialization;
- (void)refresh;
- (void)save;
- (IBAction)addAccount:(id)sender;
- (IBAction)removeAccount:(id)sender;

@end
