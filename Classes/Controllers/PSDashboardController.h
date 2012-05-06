//
//  DashboardController.h
//  Prismo
//
//  Created by Sergey Lenkov on 01.10.11.
//  Copyright 2011 Sergey Lenkov. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <Yuba/Yuba.h>
#import "PSSale.h"
#import "PSApplication.h"
#import "PSDataController.h"
#import "PSDetailsController.h"
#import "PSDashboardFilterController.h"

@interface PSDashboardController : PSDataController <PSFilterControllerDelegate> {
	IBOutlet YBGraphView *mainGraphView;
	IBOutlet YBGraphView *downloadsGraphView;
	IBOutlet YBGraphView *salesGraphView;
	IBOutlet YBGraphView *updatesGraphView;
	IBOutlet YBGraphView *revenueGraphView;
	IBOutlet NSView *graphView;
	IBOutlet NSView *detailView;
	IBOutlet NSView *contentView;
	IBOutlet NSSegmentedControl *changeViewButton;
	IBOutlet PSDetailsController *detailsController;
	NSNumberFormatter *formatter;
	NSNumberFormatter *numberFormatter;
	NSMutableArray *series;
    NSMutableArray *graphTotal;
	NSMutableArray *graphDownloads;
	NSMutableArray *graphSales;
	NSMutableArray *graphUpdates;
	NSMutableArray *graphRefunds;
	NSMutableArray *graphRevenue;
    PSDashboardFilterController *filterController;
}

@property (nonatomic, retain) PSDashboardFilterController *filterController;

- (void)draw;
- (IBAction)viewChanged:(id)sender;

@end
