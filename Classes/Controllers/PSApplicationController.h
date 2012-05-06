//
//  PSApplicationController.h
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
#import "PSApplicationFilterController.h"

@interface PSApplicationController : PSDataController <PSFilterControllerDelegate> {
	IBOutlet NSView *graphView;
	IBOutlet NSView *detailsView;
	IBOutlet NSView *mapView;
	IBOutlet NSView *infoView;
	IBOutlet NSView *contentView;
	IBOutlet NSView *bottomView;
	IBOutlet YBGraphView *mainGraphView;
	IBOutlet YBGraphView *downloadsGraphView;
	IBOutlet YBGraphView *salesGraphView;
	IBOutlet YBGraphView *updatesGraphView;
	IBOutlet YBGraphView *revenueGraphView;
	IBOutlet YBMapView *mapGraphView;
	IBOutlet NSSegmentedControl *changeViewButton;
	IBOutlet NSTextField *nameField;
	IBOutlet NSTextField *appleIDField;
	IBOutlet NSTextField *startDateField;
	IBOutlet NSTextField *endDateField;
	IBOutlet NSTextField *daysField;
    IBOutlet NSTextField *totalField;
    IBOutlet NSTextField *downloadsField;
	IBOutlet NSTextField *salesField;
	IBOutlet NSTextField *updatesField;
    IBOutlet NSTextField *refundsField;
	IBOutlet NSTextField *revenueField;
    IBOutlet NSTextField *avgTotalField;
    IBOutlet NSTextField *avgDownloadsField;
	IBOutlet NSTextField *avgSalesField;
	IBOutlet NSTextField *avgRevenueField;
	IBOutlet PSDetailsController *detailsController;
	NSNumberFormatter *moneyFormatter;
	NSNumberFormatter *numberFormatter;
	NSDateFormatter *dateFormatter;
	NSMutableDictionary *mapValues;
	NSMutableArray *series;
    NSMutableArray *graphTotal;
	NSMutableArray *graphDownloads;
	NSMutableArray *graphSales;
	NSMutableArray *graphUpdates;
	NSMutableArray *graphRefunds;
	NSMutableArray *graphRevenue;
	PSApplication *application;
    PSApplicationFilterController *filterController;
}

@property (nonatomic, retain) PSApplication *application;

- (void)draw;
- (IBAction)viewChanged:(id)sender;

@end
