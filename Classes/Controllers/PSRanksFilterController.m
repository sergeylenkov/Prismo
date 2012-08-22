//
//  PSRanksFilterController.m
//  Prismo
//
//  Created by Sergey Lenkov on 31.10.11.
//  Copyright (c) 2011 Sergey Lenkov. All rights reserved.
//

#import "PSRanksFilterController.h"

@implementation PSRanksFilterController

@synthesize application;
@synthesize top;
@synthesize fromDate;
@synthesize toDate;

- (id)initWithWindowNibName:(NSString *)windowNibName {
    self = [super initWithWindowNibName:windowNibName];
    
    if (self) {
        tops = [[NSMutableArray alloc] init];
    }
    
    return self;
}

- (void)dealloc {
    [tops release];
    [application release];
    [top release];
    [fromDate release];
    [toDate release];
    [super dealloc];
}

- (void)initialization {
    PSData *data = [PSData sharedData];
    
    NSArray *ranks = [data ranksForApplication:application];
    
    if ([ranks count] == 0) {
        top = nil;
        return;
    }
    
    [tops removeAllObjects];
    [topsButton removeAllItems];
    
    NSArray *stores = [ranks valueForKeyPath:@"@distinctUnionOfObjects.store.identifier"];
    
    for (NSString *storeID in stores) {
        PSStore *store = [[PSStore alloc] initWithPrimaryKey:[storeID intValue] database:[Database sharedDatabase]];
        
        NSPredicate *predicate = [NSPredicate predicateWithFormat:@"store.identifier == %d", store.identifier];
        NSArray *filteredArray = [ranks filteredArrayUsingPredicate:predicate];
        NSArray *pops = [filteredArray valueForKeyPath:@"@distinctUnionOfObjects.pop.identifier"];
        
        for (NSString *popID in pops) {
            PSPop *pop = [[PSPop alloc] initWithPrimaryKey:[popID intValue] database:[Database sharedDatabase]];
            
            NSPredicate *predicate = [NSPredicate predicateWithFormat:@"pop.identifier == %d AND store.identifier == %d", pop.identifier, store.identifier];
            NSArray *filteredArray = [ranks filteredArrayUsingPredicate:predicate];
            
            NSArray *categories = [filteredArray valueForKeyPath:@"@distinctUnionOfObjects.category.identifier"];
            
            for (NSString *categoryID in categories) {
                PSCategory *category = [[PSCategory alloc] initWithPrimaryKey:[categoryID intValue] database:[Database sharedDatabase]];
                
                PSTop *item = [[PSTop alloc] init];
                
                item.name = [NSString stringWithFormat:@"%@ (%@ - %@)", store.name, category.name, pop.name];
                item.store = store;
                item.category = category;
                item.pop = pop;
                
                [topsButton addItemWithTitle:item.name];
                
                [tops addObject:item];
                
                [category release];
                [item release];
            }
            
            [pop release];
        }
        
        [store release];
    }
    
    [tops sortUsingSelector:@selector(compareName:)];
    
    for (PSTop *item in tops) {
        [topsButton addItemWithTitle:item.name];
    }
    
    NSString *selectedTop = [PSSettings filterValueForKey:[NSString stringWithFormat:@"%ld Ranks Selected Top", application.identifier]];
    
    for (int i = 0; i < [tops count]; i++) {
        PSTop *item = [tops objectAtIndex:i];
        NSString *key = [NSString stringWithFormat:@"%ld_%ld_%ld_%ld", item.store.identifier, item.category.identifier, item.pop.identifier, item.type];
        
        if ([key isEqualToString:selectedTop]) {
            [topsButton selectItemAtIndex:i];
            break;
        }
    }
    
    [self changeTop:nil];
}

- (IBAction)changeDate:(id)sender {
    self.fromDate = [fromDateButton dateValue];
    self.toDate = [toDateButton dateValue];
    
	[PSSettings setFilterValue:fromDate forKey:[NSString stringWithFormat:@"%ld Ranks Min Date", application.identifier]];	
	[self filterDidChanged];
}

- (IBAction)changeTop:(id)sender {
    PSData *data = [PSData sharedData];
    
    self.top = [tops objectAtIndex:topsButton.indexOfSelectedItem];
    self.fromDate = [data minDateForTop:top application:application];
    self.toDate = [data maxDateForTop:top application:application];
    
    [fromDateButton setMinDate:fromDate];
    [fromDateButton setMaxDate:toDate];
    
    [toDateButton setMinDate:fromDate];
    [toDateButton setMaxDate:toDate];
    
    [fromDateButton setDateValue:fromDate];
    [toDateButton setDateValue:toDate];
    
    NSString *key = [NSString stringWithFormat:@"%ld_%ld_%ld_%ld", top.store.identifier, top.category.identifier, top.pop.identifier, top.type];
    
	[PSSettings setFilterValue:key forKey:[NSString stringWithFormat:@"%ld Ranks Selected Top", application.identifier]];
    
	[self filterDidChanged];
}

@end
