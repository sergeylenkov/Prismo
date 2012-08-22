//
//  PSApplicationFilterController.m
//  Prismo
//
//  Created by Sergey Lenkov on 01.11.11.
//  Copyright (c) 2011 Sergey Lenkov. All rights reserved.
//

#import "PSApplicationFilterController.h"

@implementation PSApplicationFilterController

@synthesize application;
@synthesize fromDate;
@synthesize toDate;
@synthesize groupBy;
@synthesize graphType;
@synthesize mapType;

- (void)dealloc {
    [application release];
    [fromDate release];
    [toDate release];
    [super dealloc];
}

- (void)initialization {
    PSData *data = [PSData sharedData];

    self.fromDate = [data minSaleDateForApplication:application];
    self.toDate = [data maxSaleDateForApplication:application];
    
	[fromDateButton setMinDate:fromDate];
	[fromDateButton setMaxDate:toDate];
	
	[toDateButton setMinDate:fromDate];
	[toDateButton setMaxDate:toDate];
    
    if ([PSSettings filterValueForKey:[NSString stringWithFormat:@"%ld Min Date", application.identifier]] != nil) {
		self.fromDate = [PSSettings filterValueForKey:[NSString stringWithFormat:@"%ld Min Date", application.identifier]];
	}	
	
    [fromDateButton setDateValue:fromDate];
    [toDateButton setDateValue:toDate];
    
    if ([PSSettings filterValueForKey:[NSString stringWithFormat:@"%ld Graph Type", application.identifier]] == nil) {
		[typeButton selectItem:[typeButton itemAtIndex:0]];
	} else {
        NSInteger index = [[PSSettings filterValueForKey:[NSString stringWithFormat:@"%ld Graph Type", application.identifier]] intValue];
		[typeButton selectItem:[typeButton itemAtIndex:index]];
	}
	
	if ([PSSettings filterValueForKey:[NSString stringWithFormat:@"%ld Graph By", application.identifier]] == nil) {
		[byButton selectItem:[byButton itemAtIndex:0]];
	} else {
        NSInteger index = [[PSSettings filterValueForKey:[NSString stringWithFormat:@"%ld Graph By", application.identifier]] intValue];
		[byButton selectItem:[byButton itemAtIndex:index]];
	}
	
    if ([PSSettings filterValueForKey:[NSString stringWithFormat:@"%ld Map Type", application.identifier]] == nil) {
		[mapTypeButton selectItem:[mapTypeButton itemAtIndex:0]];
	} else {
        NSInteger index = [[PSSettings filterValueForKey:[NSString stringWithFormat:@"%ld Map Type", application.identifier]] intValue];
		[mapTypeButton selectItem:[mapTypeButton itemAtIndex:index]];
	}
    
    graphType = typeButton.indexOfSelectedItem;
    groupBy = byButton.indexOfSelectedItem;
    mapType = mapTypeButton.indexOfSelectedItem;
}

- (IBAction)changeDate:(id)sender {
    self.fromDate = [fromDateButton dateValue];
    self.toDate = [toDateButton dateValue];
    
	[PSSettings setFilterValue:fromDate forKey:[NSString stringWithFormat:@"%ld Min Date", application.identifier]];
	[self filterDidChanged];
}

- (IBAction)changeType:(id)sender {
    graphType = typeButton.indexOfSelectedItem;
    
	[PSSettings setFilterValue:[NSNumber numberWithInt:graphType] forKey:[NSString stringWithFormat:@"%ld Graph Type", application.identifier]];
	[self filterDidChanged];
}

- (IBAction)changeBy:(id)sender {
    groupBy = byButton.indexOfSelectedItem;
    
	[PSSettings setFilterValue:[NSNumber numberWithInt:groupBy] forKey:[NSString stringWithFormat:@"%ld Graph By", application.identifier]];
	[self filterDidChanged];
}

- (IBAction)changeMapType:(id)sender {
    mapType = mapTypeButton.indexOfSelectedItem;
    
	[PSSettings setFilterValue:[NSNumber numberWithInt:mapType] forKey:[NSString stringWithFormat:@"%ld Map Type", application.identifier]];
	[self filterDidChanged];
}

@end
