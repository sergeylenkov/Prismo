//
//  PSReviewsController.m
//  Prismo
//
//  Created by Sergey Lenkov on 01.10.11.
//  Copyright 2011 Sergey Lenkov. All rights reserved.
//

#import "PSReviewsController.h"

@implementation PSReviewsController

@synthesize reviews = _reviews;
@synthesize printableView = reviewTextView;

- (void)dealloc {
	[_reviews release];
	[super dealloc];
}

- (void)awakeFromNib {
	defaults = [NSUserDefaults standardUserDefaults];
	[reviewTextView setUIDelegate:self];
}

- (void)setReviews:(NSArray *)reviews {
    if (reviews != _reviews) {
        [_reviews release];
        _reviews = [[NSMutableArray arrayWithArray:reviews] retain];
        
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

	[self tableViewSelectionDidChange:[NSNotification notificationWithName:@"NSObject" object:view]];
}

- (int)numberOfRowsInTableView:(NSTableView *)tableView {
	return [_reviews count];
}

- (id)tableView:(NSTableView *)tableView objectValueForTableColumn:(NSTableColumn *)tableColumn row:(int)row {
	PSReview *review = [_reviews objectAtIndex:row];
	
	if ([[tableColumn identifier] isEqualToString:@"icon"]) {
        BOOL isLion = [[NSApplication sharedApplication] isLion];
        
        if (review.isNew) {
            if (isLion) {
                return [NSImage imageNamed:@"Unread"];
            } else {
                return [NSImage imageNamed:@"Point"];
            }
        }
        
        if (isLion) {
            return [NSImage imageNamed:@"People"];
        } else {
            return [NSImage imageNamed:@"User"];
        }
	}
	
	if ([[tableColumn identifier] isEqualToString:@"date"]) {
		if ([review.date year] == [[NSDate date] year]) {
            return [PSUtilites localizedShortDateWithFullMonth:review.date];
        } else {
            return [PSUtilites localizedMediumDateWithFullMonth:review.date];
        }
	}
	
	if ([[tableColumn identifier] isEqualToString:@"name"]) {
		return review.name;
	}
	
	if ([[tableColumn identifier] isEqualToString:@"title"]) {
		return review.title;
	}
	
	if ([[tableColumn identifier] isEqualToString:@"version"]) {
		return review.version;
	}
	
	if ([[tableColumn identifier] isEqualToString:@"store"]) {
		return review.store.name;
	}
	
	if ([[tableColumn identifier] isEqualToString:@"rating"]) {
		return [NSImage imageNamed:[NSString stringWithFormat:@"Stars%ld", review.rating]];
	}
    
	return @"";
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

- (void)tableViewSelectionDidChange:(NSNotification *)notification {
	int selectedRow = [[notification object] selectedRow];
	
	if (selectedRow != -1) {
		PSReview *review = [_reviews objectAtIndex:selectedRow];
		[self showReview:review];
	} else {
		[[reviewTextView mainFrame] loadHTMLString:@"" baseURL:nil];
	}
}

- (void)sortTableView:(NSTableView *)tableView byIdentifier:(NSString *)identifier ascending:(BOOL)order {
    if ([identifier isEqualToString:@"icon"]) {
		[_reviews sortUsingSelector:@selector(compareNew:)];		
	}
    
	if ([identifier isEqualToString:@"name"]) {
		[_reviews sortUsingSelector:@selector(compareName:)];
	}
	
	if ([identifier isEqualToString:@"title"]) {
		[_reviews sortUsingSelector:@selector(compareTitle:)];		
	}
	
	if ([identifier isEqualToString:@"version"]) {
		[_reviews sortUsingSelector:@selector(compareVersion:)];		
	}
	
	if ([identifier isEqualToString:@"store"]) {
		[_reviews sortUsingSelector:@selector(compareStore:)];		
	}
	
	if ([identifier isEqualToString:@"rating"]) {
		[_reviews sortUsingSelector:@selector(compareRating:)];		
	}
	
	if ([identifier isEqualToString:@"date"]) {
		[_reviews sortUsingSelector:@selector(compareDate:)];		
	}
    
	if (order) {
		[_reviews reverse];
	}
	
	[PSSettings setFilterValue:identifier forKey:[NSString stringWithFormat:@"%@ Sorting Column", [tableView autosaveName]]];
	[PSSettings setFilterValue:[NSNumber numberWithBool:order] forKey:[NSString stringWithFormat:@"%@ Sort Order", [tableView autosaveName]]];
	
    [tableView reloadData];
}

- (NSArray *)webView:(WebView *)sender contextMenuItemsForElement:(NSDictionary *)element defaultMenuItems:(NSArray *)defaultMenuItems {
	NSMutableArray *newMenu = [[[NSMutableArray alloc] init] autorelease];
	
	for (int i = 0; i < [defaultMenuItems count]; i++) {
		NSMenuItem *item = [defaultMenuItems objectAtIndex:i];
		
		if (![[item title] isEqualToString:@"Reload"]) {
			[newMenu addObject:item];
		}
	}
	
	return newMenu;
}

- (void)showReview:(PSReview *)review {
	[[reviewTextView mainFrame] loadHTMLString:[NSString stringWithFormat:@"<html><head><style>body{color:#000000;background-color:#ffffff;font-size:12px;font-family:\"Helvetica Neue\",\"Tahoma\",sans-serif;line-height:1.6em;}</style></head><body><h2>%@</h2>%@</body></html>", review.title, review.text] baseURL:nil];
    
    if (review.isNew) {
        review.isNew = NO;
        [review save];
    }
}

@end
