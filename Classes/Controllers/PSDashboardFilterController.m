//
//  PSDashboardFilterController.m
//  Prismo
//
//  Created by Sergey Lenkov on 29.10.11.
//  Copyright (c) 2011 Sergey Lenkov. All rights reserved.
//

#import "PSDashboardFilterController.h"

@implementation PSDashboardFilterController

@synthesize fromDate;
@synthesize toDate;
@synthesize groupBy;
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
    
    if ([PSSettings filterValueForKey:@"Dashboard Min Date"] != nil) {
        NSDate *date = [PSSettings filterValueForKey:@"Dashboard Min Date"];
        
        if ([date timeIntervalSince1970] >= [fromDate timeIntervalSince1970]) {
            self.fromDate = date;
        }
    }
    
    [fromDateButton setDateValue:fromDate];
    [toDateButton setDateValue:toDate];
    
    if ([PSSettings filterValueForKey:@"Dashboard Graph Type"] == nil) {
		[typeButton selectItem:[typeButton itemAtIndex:0]];
	} else {
        NSInteger index = [[PSSettings filterValueForKey:@"Dashboard Graph Type"] intValue];
		[typeButton selectItem:[typeButton itemAtIndex:index]];
	}
	
	if ([PSSettings filterValueForKey:@"Dashboard Graph By"] == nil) {
		[byButton selectItem:[byButton itemAtIndex:0]];
	} else {
        NSInteger index = [[PSSettings filterValueForKey:@"Dashboard Graph By"] intValue];
		[byButton selectItem:[byButton itemAtIndex:index]];
	}

    type = typeButton.indexOfSelectedItem;
    groupBy = byButton.indexOfSelectedItem;
}

- (IBAction)changeDate:(id)sender {
    self.fromDate = [fromDateButton dateValue];
    self.toDate = [toDateButton dateValue];
    
	[PSSettings setFilterValue:fromDate forKey:@"Dashboard Min Date"];
	
	[self filterDidChanged];
}

- (IBAction)changeType:(id)sender {
    type = typeButton.indexOfSelectedItem;
    
    [PSSettings setFilterValue:[NSNumber numberWithInt:type] forKey:@"Dashboard Graph Type"];
	[self filterDidChanged];
}

- (IBAction)changeBy:(id)sender {
    groupBy = byButton.indexOfSelectedItem;
    
    [PSSettings setFilterValue:[NSNumber numberWithInt:groupBy] forKey:@"Dashboard Graph By"];
	[self filterDidChanged];
}

@end
