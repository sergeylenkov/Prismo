//
//  PSMoneyController.h
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
#import "PSMoneyFilterController.h"

@interface PSMoneyController : PSDataController <PSFilterControllerDelegate> {	
	IBOutlet NSView *contentView;	
	IBOutlet NSView *graphView;
	IBOutlet NSView *currenciesView;
	IBOutlet NSView *regionsView;
	IBOutlet NSView *bottomView;
	IBOutlet YBGraphView *mainGraphView;
	IBOutlet NSSegmentedControl *changeViewButton;
	IBOutlet NSTextField *USDField;
	IBOutlet NSTextField *EURField;
	IBOutlet NSTextField *GBPField;
	IBOutlet NSTextField *JPYField;
	IBOutlet NSTextField *CADField;
	IBOutlet NSTextField *AUDField;
	IBOutlet NSTextField *USField;
	IBOutlet NSTextField *EUField;
	IBOutlet NSTextField *CAField;
	IBOutlet NSTextField *AUField;
	IBOutlet NSTextField *GBField;
	IBOutlet NSTextField *JPField;
	IBOutlet NSTextField *WWField;
	IBOutlet NSTextField *ALLField;
	NSNumberFormatter *formatter;
	NSNumberFormatter *numberFormatter;
	NSMutableArray *series;
	NSMutableArray *values;
    PSMoneyFilterController *filterController;
}

- (void)draw;
- (IBAction)viewChanged:(id)sender;

@end
