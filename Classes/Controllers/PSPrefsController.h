//
//  PSPrefsController.h
//  Prismo
//
//  Created by Sergey Lenkov on 08.02.11.
//  Copyright 2011 Sergey Lenkov. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "PTKeychain.h"
#import "PSAccountsController.h"
#import "PSTopsController.h"
#import "PSAppsController.h"
#import "PSStoresController.h"

#define TOOLBAR_GENERAL @"TOOLBAR_GENERAL"
#define TOOLBAR_REPORTS @"TOOLBAR_REPORTS"
#define TOOLBAR_TOPS @"TOOLBAR_TOPS"
#define TOOLBAR_APPS @"TOOLBAR_APPS"
#define TOOLBAR_APPLEID @"TOOLBAR_APPLEID"
#define TOOLBAR_UPDATE @"TOOLBAR_UPDATE"

@interface PSPrefsController : NSWindowController <NSToolbarDelegate> {
	IBOutlet NSView *generalView;
	IBOutlet NSView *reportsView;
    IBOutlet NSView *appleIDView;
    IBOutlet NSView *topsView;
    IBOutlet NSView *appsView;
	IBOutlet NSView *updateView;
	IBOutlet NSButton *startupButton;
	IBOutlet NSButton *checkStartupButton;
	IBOutlet NSPopUpButton *periodButton;
	IBOutlet NSPopUpButton *pathButton;
	IBOutlet NSPopUpButton *currencyButton;
    IBOutlet NSPopUpButton *ranksPeriodButton;
	IBOutlet NSTextField *lastCheckField;
	IBOutlet NSTextField *lastCheckStatusField;
    IBOutlet NSTextField *lastRanksUpdateField;
	IBOutlet NSTextField *lastRanksUpdateStatusField;
    IBOutlet NSTextField *lastReviewsUpdateField;
	IBOutlet NSTextField *lastReviewsUpdateStatusField;
    IBOutlet NSTextField *lastRatingsUpdateField;
	IBOutlet NSTextField *lastRatingsUpdateStatusField;
	IBOutlet PSAccountsController *accountsController;
    IBOutlet PSTopsController *topsController;
    IBOutlet PSAppsController *appsController;
    IBOutlet PSStoresController *storesController;
	NSUserDefaults *defaults;
	NSMutableArray *currencies;
}

- (IBAction)setOnStartup:(id)sender;
- (IBAction)setCheckOnStartup:(id)sender;
- (IBAction)changePeriod:(id)sender;
- (IBAction)changeRanksPeriod:(id)sender;
- (IBAction)changePath:(id)sender;
- (IBAction)changeCurrency:(id)sender;

- (void)refresh;
- (void)setPrefView:(id)sender;
- (void)selectTabWithIndetifier:(NSString *)identifier;

@end
