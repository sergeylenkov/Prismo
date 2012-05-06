//
//  PSRanksFilterController.h
//  Prismo
//
//  Created by Sergey Lenkov on 31.10.11.
//  Copyright (c) 2011 Sergey Lenkov. All rights reserved.
//

#import "PSFilterController.h"
#import "PSApplication.h"
#import "PSTop.h"

@interface PSRanksFilterController : PSFilterController {
    IBOutlet NSDatePicker *fromDateButton;
	IBOutlet NSDatePicker *toDateButton;
    IBOutlet NSPopUpButton *topsButton;
    NSMutableArray *tops;
    PSApplication *application;
    PSTop *top;
    NSDate *fromDate;
    NSDate *toDate;
}

@property (nonatomic, retain) PSApplication *application;
@property (nonatomic, retain) PSTop *top;
@property (nonatomic, retain) NSDate *fromDate;
@property (nonatomic, retain) NSDate *toDate;

- (IBAction)changeDate:(id)sender;
- (IBAction)changeTop:(id)sender;

@end
