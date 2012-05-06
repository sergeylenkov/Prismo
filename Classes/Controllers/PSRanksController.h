//
//  PSRanksController.h
//  Prismo
//
//  Created by Sergey Lenkov on 01.10.11.
//  Copyright 2011 Sergey Lenkov. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <Yuba/Yuba.h>
#import "PSStore.h"
#import "PSCategory.h"
#import "PSPop.h"
#import "PSTop.h"
#import "PSRank.h"
#import "PSDataController.h"
#import "PSRankDetailsController.h"
#import "PSRanksFilterController.h"

@interface PSRanksController : PSDataController <PSFilterControllerDelegate> {
	IBOutlet NSView *graphView;
	IBOutlet NSView *detailView;
	IBOutlet NSView *contentView;
	IBOutlet NSView *noDataView;
	IBOutlet YBGraphView *mainGraphView;
	IBOutlet NSSegmentedControl *changeViewButton;
    IBOutlet PSRankDetailsController *detailsController;
	PSApplication *application;
	NSNumberFormatter *formatter;
    NSMutableArray *graphs;
    NSMutableArray *series;
    PSRanksFilterController *filterController;
}

@property (nonatomic, retain) PSApplication *application;

- (void)draw;
- (IBAction)viewChanged:(id)sender;

@end
