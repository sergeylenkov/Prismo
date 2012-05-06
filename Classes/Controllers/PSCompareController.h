//
//  PSCompareController.h
//  Prismo
//
//  Created by Sergey Lenkov on 01.10.11.
//  Copyright 2011 Sergey Lenkov. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <Yuba/Yuba.h>
#import "PSSale.h"
#import "PSCompare.h"
#import "PSDataController.h"
#import "PSCompareFilterController.h"

@interface PSCompareController : PSDataController <PSFilterControllerDelegate> {
    IBOutlet YBGraphView *mainGraphView;
    IBOutlet YBChartView *mainChartView;
	IBOutlet NSView *graphView;
    IBOutlet NSView *chartView;
	IBOutlet NSView *contentView;
	IBOutlet NSSegmentedControl *changeViewButton;
	NSNumberFormatter *formatter;
	NSNumberFormatter *numberFormatter;
	NSMutableArray *series;
    NSMutableArray *graphs;
    NSMutableArray *charts;
    NSMutableArray *applications;
    PSCompareFilterController *filterController;
}

- (void)draw;
- (IBAction)viewChanged:(id)sender;

@end
