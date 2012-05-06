//
//  PSMoneyFilterController.m
//  Prismo
//
//  Created by Sergey Lenkov on 30.10.11.
//  Copyright (c) 2011 Sergey Lenkov. All rights reserved.
//

#import "PSMoneyFilterController.h"

@implementation PSMoneyFilterController

@synthesize fromDate;
@synthesize toDate;
@synthesize groupBy;

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
    
	if ([PSSettings filterValueForKey:@"Money Min Date"] != nil) {
		self.fromDate = [PSSettings filterValueForKey:@"Money Min Date"];
	}
    
    [fromDateButton setDateValue:fromDate];
    [toDateButton setDateValue:toDate];
    
	if ([PSSettings filterValueForKey:@"Money Graph By"] == nil) {
		[byButton selectItem:[byButton itemAtIndex:0]];
	} else {
		NSInteger index = [[PSSettings filterValueForKey:@"Money Graph By"] intValue];
		[byButton selectItem:[byButton itemAtIndex:index]];
	}
    
    groupBy = byButton.indexOfSelectedItem;
}

- (IBAction)changeDate:(id)sender {
    self.fromDate = [fromDateButton dateValue];
    self.toDate = [toDateButton dateValue];
    
	[PSSettings setFilterValue:fromDate forKey:@"Money Min Date"];
	
	[self filterDidChanged];
}

- (IBAction)changeBy:(id)sender {
    groupBy = byButton.indexOfSelectedItem;
    
	[PSSettings setFilterValue:[NSNumber numberWithInt:groupBy] forKey:@"Money Graph By"];	
	[self filterDidChanged];
}

@end
