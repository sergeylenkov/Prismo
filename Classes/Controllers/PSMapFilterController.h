//
//  PSMapFilter.h
//  Prismo
//
//  Created by Sergey Lenkov on 30.10.11.
//  Copyright (c) 2011 Sergey Lenkov. All rights reserved.
//

#import "PSFilterController.h"

@interface PSMapFilterController : PSFilterController {
    IBOutlet NSDatePicker *fromDateButton;
    IBOutlet NSDatePicker *toDateButton;
    IBOutlet NSPopUpButton *typeButton;	
    NSDate *fromDate;
    NSDate *toDate;
    PSGraphType type;
}

@property (nonatomic, retain) NSDate *fromDate;
@property (nonatomic, retain) NSDate *toDate;
@property (nonatomic, assign) PSGraphType type;

- (IBAction)changeDate:(id)sender;
- (IBAction)changeType:(id)sender;

@end
