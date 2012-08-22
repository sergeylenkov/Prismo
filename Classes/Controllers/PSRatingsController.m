//
//  PSRatingsController.m
//  Prismo
//
//  Created by Sergey Lenkov on 01.10.11.
//  Copyright 2011 Sergey Lenkov. All rights reserved.
//

#import "PSRatingsController.h"

@implementation PSRatingsController

@synthesize ratings = _ratings;
@synthesize view;

- (void)dealloc {
	[_ratings release];
	[super dealloc];
}

- (void)awakeFromNib {
	defaults = [NSUserDefaults standardUserDefaults];
}

- (void)setRatings:(NSArray *)ratings {
    if (ratings != _ratings) {
        [_ratings release];
        _ratings = [[NSMutableArray arrayWithArray:ratings] retain];
        
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
	return [_ratings count];
}

- (id)tableView:(NSTableView *)tableView objectValueForTableColumn:(NSTableColumn *)tableColumn row:(int)row {
	PSRating *rating = [_ratings objectAtIndex:row];
	
	if ([[tableColumn identifier] isEqualToString:@"icon"]) {
        if ([[NSApplication sharedApplication] isLion]) {
            return [NSImage imageNamed:@"RanksLion.png"];
        }
        
        return [NSImage imageNamed:@"Ranks.png"];
	}
	
	if ([[tableColumn identifier] isEqualToString:@"average"]) {
		return [NSImage imageNamed:[NSString stringWithFormat:@"Stars%d.png", (int)round([rating.average floatValue])]];
	}
	
	if ([[tableColumn identifier] isEqualToString:@"store"]) {
		return rating.store.name;
	}
	
	if ([[tableColumn identifier] isEqualToString:@"stars_5"]) {
		if (rating.stars5 == 0) {
			return @"-";
		}
		
		return [NSString stringWithFormat:@"%ld", rating.stars5];
	}
	
	if ([[tableColumn identifier] isEqualToString:@"stars_4"]) {
		if (rating.stars4 == 0) {
			return @"-";
		}
		
		return [NSString stringWithFormat:@"%ld", rating.stars4];
	}
	
	if ([[tableColumn identifier] isEqualToString:@"stars_3"]) {
		if (rating.stars3 == 0) {
			return @"-";
		}
		
		return [NSString stringWithFormat:@"%ld", rating.stars3];
	}
	
	if ([[tableColumn identifier] isEqualToString:@"stars_2"]) {
		if (rating.stars2 == 0) {
			return @"-";
		}
		
		return [NSString stringWithFormat:@"%ld", rating.stars2];
	}

	if ([[tableColumn identifier] isEqualToString:@"stars_1"]) {
		if (rating.stars1 == 0) {
			return @"-";
		}
		
		return [NSString stringWithFormat:@"%ld", rating.stars1];
	}
	
	return @"";
}

- (void)tableView:(NSTableView *)tableView willDisplayCell:(id)cell forTableColumn:(NSTableColumn *)tableColumn row:(int)row {
	//
}

- (void)tableView:(NSTableView *)tableView didClickTableColumn:(NSTableColumn *)tableColumn {
	if (![lastIdentifier isEqualToString:[tableColumn identifier]]) {
		sortAscending = YES;
		lastIdentifier = [tableColumn identifier];
	} else {
		sortAscending = !sortAscending;
	}
		
	[self sortTableView:tableView byIdentifier:[tableColumn identifier] ascending:sortAscending];
}

- (void)tableView:(NSTableView *)tableView sortDescriptorsDidChange:(NSArray *)oldDescriptors {
	//
}

- (void)sortTableView:(NSTableView *)tableView byIdentifier:(NSString *)identifier ascending:(BOOL)order {
	if ([identifier isEqualToString:@"store"]) {
		[_ratings sortUsingSelector:@selector(compareStore:)];
	}
	
	if ([identifier isEqualToString:@"average"]) {
		[_ratings sortUsingSelector:@selector(compareAverage:)];		
	}
	
	if ([identifier isEqualToString:@"stars_5"]) {
		[_ratings sortUsingSelector:@selector(compareStars5:)];
	}
	
	if ([identifier isEqualToString:@"stars_4"]) {
		[_ratings sortUsingSelector:@selector(compareStars4:)];
	}
	
	if ([identifier isEqualToString:@"stars_3"]) {
		[_ratings sortUsingSelector:@selector(compareStars3:)];
	}
	
	if ([identifier isEqualToString:@"stars_2"]) {
		[_ratings sortUsingSelector:@selector(compareStars2:)];
	}
	
	if ([identifier isEqualToString:@"stars_1"]) {
		[_ratings sortUsingSelector:@selector(compareStars1:)];
	}
	
	if (order) {
		[_ratings reverse];
	}

	[PSSettings setFilterValue:identifier forKey:[NSString stringWithFormat:@"%@ Sorting Column", [tableView autosaveName]]];
	[PSSettings setFilterValue:[NSNumber numberWithBool:order] forKey:[NSString stringWithFormat:@"%@ Sort Order", [tableView autosaveName]]];
	
    [tableView reloadData];
}

@end
