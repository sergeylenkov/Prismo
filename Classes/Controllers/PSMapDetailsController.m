//
//  PSMapDetailsController.m
//  Prismo
//
//  Created by Sergey Lenkov on 01.10.11.
//  Copyright 2011 Sergey Lenkov. All rights reserved.
//

#import "PSMapDetailsController.h"

@implementation PSMapDetailsController

@synthesize view;
@synthesize sales = _sales;

- (void)dealloc {
	[_sales release];
	[formatter release];
	[numberFormatter release];
	[super dealloc];
}

- (void)awakeFromNib {	
	defaults = [NSUserDefaults standardUserDefaults];
	
	formatter = [[NSNumberFormatter alloc] init];
	
	[formatter setFormatterBehavior:NSNumberFormatterBehavior10_4];
	[formatter setNumberStyle:NSNumberFormatterCurrencyStyle];
	[formatter setPositiveFormat:[NSString stringWithFormat:@"#,##0.00"]];
	
	numberFormatter = [[NSNumberFormatter alloc] init];
	
	[numberFormatter setFormatterBehavior:NSNumberFormatterBehavior10_4];
	[numberFormatter setNumberStyle:NSNumberFormatterDecimalStyle];
}

- (void)setSales:(NSMutableArray *)sales {
    if (sales != _sales) {
        [_sales release];
        _sales = [[NSMutableArray arrayWithArray:sales] retain];
        
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

- (int)numberOfRowsInTableView:(NSTableView *)tableView {
	return [_sales count];
}

- (id)tableView:(NSTableView *)tableView objectValueForTableColumn:(NSTableColumn *)tableColumn row:(int)row {
	PSCountrySale *sale = [_sales objectAtIndex:row];	
	
	if ([[tableColumn identifier] isEqualToString:@"icon"]) {
		return [NSImage imageNamed:[NSString stringWithFormat:@"%@.gif", [sale.code lowercaseString]]];
	}
	
	if ([[tableColumn identifier] isEqualToString:@"country"]) {
		return sale.name;
	}
	
    if ([[tableColumn identifier] isEqualToString:@"total"]) {
		return [numberFormatter stringFromNumber:sale.total];
	}
    
	if ([[tableColumn identifier] isEqualToString:@"downloads"]) {
		return [numberFormatter stringFromNumber:sale.downloads];
	}
	
	if ([[tableColumn identifier] isEqualToString:@"sales"]) {
		return [numberFormatter stringFromNumber:sale.sales];
	}
	
	if ([[tableColumn identifier] isEqualToString:@"updates"]) {
		return [numberFormatter stringFromNumber:sale.updates];
	}
	
	if ([[tableColumn identifier] isEqualToString:@"refunds"]) {
		return [numberFormatter stringFromNumber:sale.refunds];
	}
	
	if ([[tableColumn identifier] isEqualToString:@"revenue"]) {
		return [formatter stringFromNumber:sale.revenue];
	}
	
	return @"";
}

- (void)tableView:(NSTableView *)tableView willDisplayCell:(id)cell forTableColumn:(NSTableColumn *)tableColumn row:(int)row {
	//
}

- (void)tableView:(NSTableView *)tableView didClickTableColumn:(NSTableColumn *)tableColumn {
	if (![[tableColumn identifier] isEqualToString:@"icon"]) {
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
    if ([identifier isEqualToString:@"total"]) {
		[_sales sortUsingSelector:@selector(compareTotal:)];
	}
    
	if ([identifier isEqualToString:@"downloads"]) {
		[_sales sortUsingSelector:@selector(compareDownloads:)];
	}
	
	if ([identifier isEqualToString:@"sales"]) {
		[_sales sortUsingSelector:@selector(compareSales:)];
	}
	
	if ([identifier isEqualToString:@"updates"]) {
		[_sales sortUsingSelector:@selector(compareUpdates:)];
	}
	
	if ([identifier isEqualToString:@"refunds"]) {
		[_sales sortUsingSelector:@selector(compareRefunds:)];
	}
	
	if ([identifier isEqualToString:@"revenue"]) {
		[_sales sortUsingSelector:@selector(compareRevenue:)];
	}
	
	if ([identifier isEqualToString:@"country"]) {
		[_sales sortUsingSelector:@selector(compareName:)];
	}
	
	if (sortAscending) {
		[_sales reverse];
	}
	
	[PSSettings setFilterValue:identifier forKey:[NSString stringWithFormat:@"%@ Sorting Column", [tableView autosaveName]]];
	[PSSettings setFilterValue:[NSNumber numberWithBool:order] forKey:[NSString stringWithFormat:@"%@ Sort Order", [tableView autosaveName]]];
	
    [tableView reloadData];
}

@end
