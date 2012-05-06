//
//  PSCompareFilterController.m
//  Prismo
//
//  Created by Sergey Lenkov on 30.10.11.
//  Copyright (c) 2011 Sergey Lenkov. All rights reserved.
//

#import "PSCompareFilterController.h"

@implementation PSCompareFilterController

@synthesize fromDate;
@synthesize toDate;
@synthesize groupBy;
@synthesize selection;
@synthesize applications;

- (void)dealloc {
    [fromDate release];
    [toDate release];
    [selection release];
    [applications release];
    [super dealloc];
}

- (id)initWithWindowNibName:(NSString *)windowNibName {
    self = [super initWithWindowNibName:windowNibName];
    
    if (self) {
        selection = [[NSMutableDictionary alloc] init];
        applications = [[NSMutableArray alloc] init];
    }
    
    return self;
}

- (void)initialization {
    PSData *data = [PSData sharedData];
    
    self.fromDate = [data minSaleDate];
    self.toDate = [data maxSaleDate];
	
    [fromDateButton setMinDate:fromDate];
	[fromDateButton setMaxDate:toDate];
	
	[toDateButton setMinDate:fromDate];
	[toDateButton setMaxDate:toDate];
    
    if ([PSSettings filterValueForKey:@"Compare Min Date"] != nil) {
        NSDate *date = [PSSettings filterValueForKey:@"Compare Min Date"];
        
        if ([date timeIntervalSince1970] >= [fromDate timeIntervalSince1970]) {
            self.fromDate = date;
        }
    }
    
    [fromDateButton setDateValue:fromDate];
    [toDateButton setDateValue:toDate];
    
	if ([PSSettings filterValueForKey:@"Compare Graph By"] == nil) {
		[byButton selectItem:[byButton itemAtIndex:0]];
	} else {
        NSInteger index = [[PSSettings filterValueForKey:@"Compare Graph By"] intValue];
		[byButton selectItem:[byButton itemAtIndex:index]];
	}
	
    groupBy = byButton.indexOfSelectedItem;
    
    [selection removeAllObjects];
    [applications removeAllObjects];
    
    [selection addEntriesFromDictionary:[PSSettings filterValueForKey:@"Compare Selection"]];

    for (PSApplication *application in data.allSaleItems) {
        for (int i = 0; i < [data.graphTypes count]; i++) {
            PSCompare *compare = [[PSCompare alloc] init];
            
            compare.name = [NSString stringWithFormat:@"%@ - %@", application.name, [data.graphTypes objectAtIndex:i]];
            compare.application = application;
            compare.type = i;
            
            [applications addObject:compare];
            [compare release];
        }
    }
   
    [applicationsView reloadData];
}

- (int)numberOfRowsInTableView:(NSTableView *)tableView {
	return [applications count];
}

- (id)tableView:(NSTableView *)tableView objectValueForTableColumn:(NSTableColumn *)tableColumn row:(int)row {
    PSCompare *compare = [applications objectAtIndex:row];
    NSString *key = [NSString stringWithFormat:@"%d_%d", compare.application.identifier, compare.type];
   
	if ([[tableColumn identifier] isEqualToString:@"name"]) {
        BOOL selected = [[selection objectForKey:key] boolValue];
        
		NSButtonCell *cell = [tableColumn dataCell];
        
        [cell setTitle:compare.name];
		[cell setState:selected];
        
		return cell;
	}
    
	return nil;
}

- (void)tableView:(NSTableView *)tableView setObjectValue:(id)object forTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row {
	if ([[tableColumn identifier] isEqualToString:@"name"]) {
        PSCompare *compare = [applications objectAtIndex:row];
        NSString *key = [NSString stringWithFormat:@"%d_%d", compare.application.identifier, compare.type];
        
		NSNumber *value = [NSNumber numberWithBool:[object boolValue]];
        
        if ([value boolValue]) {
            [selection setObject:value forKey:key];
        } else {
            [selection removeObjectForKey:key];
        }
        
        [tableView reloadData];
        [self filterDidChanged];
        
        [PSSettings setFilterValue:selection forKey:@"Compare Selection"];
	}
}

- (IBAction)changeDate:(id)sender {
    self.fromDate = [fromDateButton dateValue];
    self.toDate = [toDateButton dateValue];
    
	[PSSettings setFilterValue:fromDate forKey:@"Compare Min Date"];
	
	[self filterDidChanged];
}

- (IBAction)changeBy:(id)sender {
    groupBy = byButton.indexOfSelectedItem;
    
    [PSSettings setFilterValue:[NSNumber numberWithInt:groupBy] forKey:@"Compare Graph By"];
	[self filterDidChanged];
}

@end
