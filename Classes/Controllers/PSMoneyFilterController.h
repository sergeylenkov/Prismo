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
    IBOutlet NSPopUpButton *appButton;
    NSDate *fromDate;
    NSDate *toDate;
    PSGraphGroupBy groupBy;
    PSApplication *application;
}

@property (nonatomic, retain) NSDate *fromDate;
@property (nonatomic, retain) NSDate *toDate;
@property (nonatomic, assign) PSGraphGroupBy groupBy;
@property (nonatomic, retain) PSApplication *application;

- (IBAction)changeDate:(id)sender;
- (IBAction)changeBy:(id)sender;

@end
