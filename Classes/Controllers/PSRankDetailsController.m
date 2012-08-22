//
//  PSRankDetailsController.m
//  Prismo
//
//  Created by Sergey Lenkov on 01.10.11.
//  Copyright 2011 Sergey Lenkov. All rights reserved.
//

#import "PSRankDetailsController.h"

@implementation PSRankDetailsController

@synthesize view;
@synthesize ranks = _ranks;

- (void)dealloc {
	[_ranks release];
	[formatter release];
	[super dealloc];
}

- (void)awakeFromNib {
	defaults = [NSUserDefaults standardUserDefaults];
	
	formatter = [[NSNumberFormatter alloc] init];
	
	[formatter setFormatterBehavior:NSNumberFormatterBehavior10_4];
	[formatter setNumberStyle:NSNumberFormatterDecimalStyle];
}

- (void)setRanks:(NSArray *)ranks {
    if (ranks != _ranks) {
        [_ranks release];
        _ranks = [[NSMutableArray arrayWithArray:ranks] retain];
        
        [self refresh];
    }
}

- (void)refresh {
	if ([PSSettings filterValueForKey:[NSString stringWithFormat:@"%@ Sorting Column", [view autosaveName]]] == nil) {
		sortAscending = YES;		
		[self sortTableView:view byIdentifier:@"date" ascending:sortAscending];
	} else {
		lastIdentifier = [PSSettings filterValueForKey:[NSString stringWithFormat:@"%@ Sorting Column", [view autosaveName]]];
		sortAscending = [[PSSettings filterValueForKey:[NSString stringWithFormat:@"%@ Sort Order", [view autosaveName]]] boolValue];
		
		[self sortTableView:view byIdentifier:lastIdentifier ascending:sortAscending];
	}
}

#pragma mark -
#pragma mark NSTableView Protocol
#pragma mark -

- (int)numberOfRowsInTableView:(NSTableView *)tableView {
	return [_ranks count];
}

- (id)tableView:(NSTableView *)tableView objectValueForTableColumn:(NSTableColumn *)tableColumn row:(int)row {
	PSRank *rank = [_ranks objectAtIndex:row];	
	int change;

	if (row == [_ranks count] - 1) {
		change = 0;
	} else {
		PSRank *previous = [_ranks objectAtIndex:row + 1];
		change = previous.place - rank.place;
	}
	
	if ([[tableColumn identifier] isEqualToString:@"icon"]) {
		if (change > 0) {
			return [NSImage imageNamed:@"Up.png"];
		}
		
		if (change < 0) {
			return [NSImage imageNamed:@"Down.png"];
		}
		
		return nil;
	}
	
	if ([[tableColumn identifier] isEqualToString:@"date"]) {
        if ([rank.date year] == [[NSDate date] year]) {
            return [PSUtilites localizedShortDateWithFullMonth:rank.date];
        } else {
            return [PSUtilites localizedMediumDateWithFullMonth:rank.date];
        }
	}
	
	if ([[tableColumn identifier] isEqualToString:@"rank"]) {
		if (rank.place == -1) {
			return @"-";
		} else {
			return [NSString stringWithFormat:@"%ld", rank.place];
		}
	}
	
	if ([[tableColumn identifier] isEqualToString:@"change"]) {
		if (change > 0) {
			return [NSString stringWithFormat:@"+%d", change];
		} else if (change < 0) {
			return [NSString stringWithFormat:@"%d", change];
		} else {
            return @"";
        }
	}
	
	return @"";
}

- (void)tableView:(NSTableView *)tableView didClickTableColumn:(NSTableColumn *)tableColumn {
	if ([[tableColumn identifier] isEqualToString:@"date"]) {
		if (![lastIdentifier isEqualToString:[tableColumn identifier]]) {
			sortAscending = YES;
			lastIdentifier = [tableColumn identifier];
		} else {
			sortAscending = !sortAscending;
		}
		
		[self sortTableView:tableView byIdentifier:[tableColumn identifier] ascending:sortAscending];
	}
}

- (void)tableView:(NSTableView *)tableView sortDescriptorsDidChange:(NSArray *)oldDescriptors {
	//
}

- (void)sortTableView:(NSTableView *)tableView byIdentifier:(NSString *)identifier ascending:(BOOL)order {
	if ([identifier isEqualToString:@"date"]) {
		[_ranks sortUsingSelector:@selector(compareDate:)];
	}
	
	if (sortAscending) {
		[_ranks reverse];
	}
	
	[PSSettings setFilterValue:identifier forKey:[NSString stringWithFormat:@"%@ Sorting Column", [tableView autosaveName]]];
	[PSSettings setFilterValue:[NSNumber numberWithBool:order] forKey:[NSString stringWithFormat:@"%@ Sort Order", [tableView autosaveName]]];
	
    [tableView reloadData];
}

@end
