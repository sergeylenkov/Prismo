//
//  PSMenuController.h
//  Prismo
//
//  Created by Sergey Lenkov on 06.02.11.
//  Copyright 2011 Sergey Lenkov. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "ImageAndTextCell.h"
#import "PSOutlineItem.h"
#import "PSApplication.h"
#import "PSDashboardController.h"
#import "PSMapController.h"
#import "PSApplicationController.h"
#import "PSCompareController.h"
#import "PSMoneyController.h"
#import "PSReviewsAndRatingsController.h"
#import "PSRanksController.h"
#import "PSDataController.h"
#import "PSCompareController.h"

@interface PSMenuController : NSObject {
	IBOutlet NSOutlineView *view;
	IBOutlet NSView *contentView;
    IBOutlet NSView *emptyView;
    IBOutlet NSView *filterView;
	IBOutlet NSButton *infoButton;
	IBOutlet NSMenuItem *exportMenuItem;
    IBOutlet NSMenuItem *printMenuItem;
    NSWindow *mainWindow;
	PSDashboardController *dashboardController;
	PSMapController *mapController;
	PSApplicationController *applicationController;
	PSMoneyController *moneyController;
	PSReviewsAndRatingsController *ratingsController;
	PSRanksController *ranksController;
    PSCompareController *compareController;
    NSMutableArray *groups;
    NSMutableArray *reports;
    NSMutableArray *applications;
    NSMutableArray *subscriptions;
    NSMutableArray *purchases;
	NSMutableArray *ratings;
	NSMutableArray *ranks;
	NSNumberFormatter *formatter;
	NSNumberFormatter *numberFormatter;
	NSString *summaryInfo;
	NSInteger infoType;
	NSUserDefaults *defaults;
    PSDataController *currentController;
    PSOutlineItem *currentItem;
}

@property (nonatomic, assign) NSOutlineView *view;
@property (nonatomic, assign) NSView *contentView;
@property (nonatomic, assign) NSView *emptyView;
@property (nonatomic, assign) NSView *filterView;
@property (nonatomic, assign) NSButton *infoButton;
@property (nonatomic, assign) NSMenuItem *exportMenuItem;
@property (nonatomic, assign) NSMenuItem *printMenuItem;
@property (nonatomic, assign) NSWindow *mainWindow;

- (void)refresh;
- (void)refreshSelectedItem;
- (void)refreshSummaryInfo;
- (void)showSummaryInfo;
- (void)showSummaryInfoForApplication:(PSApplication *)application;
- (void)outlineViewSelectionDidChange:(NSNotification *)notification;

- (IBAction)print:(id)sender;
- (IBAction)export:(id)sender;

- (IBAction)changeInfoType:(id)sender;

@end
