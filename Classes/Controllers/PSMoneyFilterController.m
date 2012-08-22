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
@synthesize application;

- (void)dealloc {
    [fromDate release];
    [toDate release];
    [application release];
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
    
    [appButton removeAllItems];
    [appButton addItemWithTitle:@"All"];
    
    for (PSApplication *app in data.applications) {
        [appButton addItemWithTitle:app.name];
    }
    
    if ([PSSettings filterValueForKey:@"Money App"] == nil) {
		[appButton selectItem:[appButton itemAtIndex:0]];
	} else {
        NSInteger identifier = [[PSSettings filterValueForKey:@"Money App"] intValue];
        NSInteger index = 1;
        
        for (PSApplication *app in data.applications) {
            if (identifier == app.identifier) {
                [appButton selectItem:[appButton itemAtIndex:index]];
                self.application = app;
                break;
            }
            
            index++;
        }
	}
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

- (IBAction)changeApp:(id)sender {
    if (appButton.indexOfSelectedItem == 0) {
        self.application = nil;
        [PSSettings removeFilterValueForKey:@"Money App"];
    } else {
        PSData *data = [PSData sharedData];
        self.application = [data.applications objectAtIndex:appButton.indexOfSelectedItem - 1];
        
        [PSSettings setFilterValue:[NSNumber numberWithInt:application.identifier] forKey:@"Money App"];
    }
    
	[self filterDidChanged];
}

@end
