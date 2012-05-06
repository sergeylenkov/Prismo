//
//  PSMoneyFilterController.h
//  Prismo
//
//  Created by Sergey Lenkov on 30.10.11.
//  Copyright (c) 2011 Sergey Lenkov. All rights reserved.
//

#import "PSFilterController.h"

@interface PSMoneyFilterController : PSFilterController {
    IBOutlet NSDatePicker *fromDateButton;
    IBOutlet NSDatePicker *toDateButton;
    IBOutlet NSPopUpButton *byButton;
    NSDate *fromDate;
    NSDate *toDate;
    PSGraphGroupBy groupBy;
}

@property (nonatomic, retain) NSDate *fromDate;
@property (nonatomic, retain) NSDate *toDate;
@property (nonatomic, assign) PSGraphGroupBy groupBy;

- (IBAction)changeDate:(id)sender;
- (IBAction)changeBy:(id)sender;

@end
