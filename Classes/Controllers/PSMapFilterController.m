//
//  PSMapFilter.m
//  Prismo
//
//  Created by Sergey Lenkov on 30.10.11.
//  Copyright (c) 2011 Sergey Lenkov. All rights reserved.
//

#import "PSMapFilterController.h"

@implementation PSMapFilterController

@synthesize fromDate;
@synthesize toDate;
@synthesize type;

- (void)dealloc {
    [fromDate release];
    [toDate release];
    [super dealloc];
}

- (void)initialization {
    PSData *data = [PSData sharedData];
    
    self.fromDate = [data minSaleDate];
    self.toDate = [data maxSaleDate];
    
    [fromDateButton setMinDate:fromDate];
	[fromDateButton setMaxDate:toDate];
	
	[toDateButton setMinDate:fromDate];
	[toDateButton setMaxDate:toDate];
    
    if ([PSSettings filterValueForKey:@"Map Min Date"] != nil) {
        self.fromDate = [PSSettings filterValueForKey:@"Map Min Date"];
    }
    
    [fromDateButton setDateValue:fromDate];
    [toDateButton setDateValue:toDate];
    
    if ([PSSettings filterValueForKey:@"Map Type"] == nil) {
		[typeButton selectItem:[typeButton itemAtIndex:0]];
	} else {
        NSInteger index = [[PSSettings filterValueForKey:@"Map Type"] intValue];
        [typeButton selectItem:[typeButton itemAtIndex:index]];
	}
    
    type = typeButton.indexOfSelectedItem;
}

- (IBAction)changeDate:(id)sender {
    self.fromDate = [fromDateButton dateValue];
    self.toDate = [toDateButton dateValue];
    
	[PSSettings setFilterValue:fromDate forKey:@"Map Min Date"];
	
	[self filterDidChanged];
}

- (IBAction)changeType:(id)sender {
    type = typeButton.indexOfSelectedItem;
    
    [PSSettings setFilterValue:[NSNumber numberWithInt:type] forKey:@"Map Type"];
	[self filterDidChanged];
}

@end
