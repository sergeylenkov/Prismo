//
//  PSApplicationFilterController.h
//  Prismo
//
//  Created by Sergey Lenkov on 01.11.11.
//  Copyright (c) 2011 Sergey Lenkov. All rights reserved.
//

#import "PSFilterController.h"

@interface PSApplicationFilterController : PSFilterController {
    IBOutlet NSPopUpButton *typeButton;
	IBOutlet NSTextField *typeLabel;
    IBOutlet NSPopUpButton *mapTypeButton;
	IBOutlet NSTextField *mapTypeLabel;
	IBOutlet NSDatePicker *fromDateButton;
	IBOutlet NSTextField *fromDateLabel;
	IBOutlet NSDatePicker *toDateButton;
	IBOutlet NSTextField *toDateLabel;
	IBOutlet NSPopUpButton *byButton;
	IBOutlet NSTextField *byLabel;
    PSApplication *application;
    NSDate *fromDate;
    NSDate *toDate;
    PSGraphGroupBy groupBy;
    PSGraphType graphType;
    PSGraphType mapType;
}

@property (nonatomic, retain) PSApplication *application;
@property (nonatomic, retain) NSDate *fromDate;
@property (nonatomic, retain) NSDate *toDate;
@property (nonatomic, assign) PSGraphGroupBy groupBy;
@property (nonatomic, assign) PSGraphType graphType;
@property (nonatomic, assign) PSGraphType mapType;

- (IBAction)changeDate:(id)sender;
- (IBAction)changeType:(id)sender;
- (IBAction)changeBy:(id)sender;
- (IBAction)changeMapType:(id)sender;

@end
