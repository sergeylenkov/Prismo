//
//  PSCompareFilterController.h
//  Prismo
//
//  Created by Sergey Lenkov on 30.10.11.
//  Copyright (c) 2011 Sergey Lenkov. All rights reserved.
//

#import "PSFilterController.h"
#import "PSCompare.h"

@interface PSCompareFilterController : PSFilterController {
    IBOutlet NSTableView *applicationsView;
    IBOutlet NSDatePicker *fromDateButton;
    IBOutlet NSDatePicker *toDateButton;
    IBOutlet NSPopUpButton *byButton;
    NSDate *fromDate;
    NSDate *toDate;
    PSGraphGroupBy groupBy;
    NSMutableDictionary *selection;
    NSMutableArray *applications;
}

@property (nonatomic, retain) NSDate *fromDate;
@property (nonatomic, retain) NSDate *toDate;
@property (nonatomic, assign) PSGraphGroupBy groupBy;
@property (nonatomic, retain) NSDictionary *selection;
@property (nonatomic, retain) NSArray *applications;

- (IBAction)changeDate:(id)sender;
- (IBAction)changeBy:(id)sender;

@end
