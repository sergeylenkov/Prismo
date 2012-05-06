//
//  PSDashboardFilterController.h
//  Prismo
//
//  Created by Sergey Lenkov on 29.10.11.
//  Copyright (c) 2011 Sergey Lenkov. All rights reserved.
//

#import "PSFilterController.h"

@interface PSDashboardFilterController : PSFilterController {
	IBOutlet NSDatePicker *fromDateButton;
	IBOutlet NSDatePicker *toDateButton;
	IBOutlet NSPopUpButton *byButton;
    IBOutlet NSPopUpButton *typeButton;	
    NSDate *fromDate;
    NSDate *toDate;
    PSGraphGroupBy groupBy;
    PSGraphType type;
}

@property (nonatomic, retain) NSDate *fromDate;
@property (nonatomic, retain) NSDate *toDate;
@property (nonatomic, assign) PSGraphGroupBy groupBy;
@property (nonatomic, assign) PSGraphType type;

- (IBAction)changeDate:(id)sender;
- (IBAction)changeType:(id)sender;
- (IBAction)changeBy:(id)sender;

@end
