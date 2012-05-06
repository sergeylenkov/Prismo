//
//  PSDetailsController.m
//  Prismo
//
//  Created by Sergey Lenkov on 01.10.11.
//  Copyright 2011 Sergey Lenkov. All rights reserved.
//

#import "PSDetailsController.h"

@implementation PSDetailsController

@synthesize view;
@synthesize sales = _sales;

- (void)dealloc {
	[_sales release];
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

- (int)outlineView:(NSOutlineView *)outlineView numberOfChildrenOfItem:(id)item {
    if (!item) {
		return [_sales count];
    } else {
		PSSale *sale = (PSSale *)item;
		return [sale.details count];
	}
}

- (id)outlineView:(NSOutlineView *)outlineView child:(int)index ofItem:(id)item {
    if (!item) {
		return [_sales objectAtIndex:index];
	} else {
		PSSale *sale = (PSSale *)item;
		return [sale.details objectAtIndex:index];
	}	
}

- (BOOL)outlineView:(NSOutlineView *)outlineView isItemExpandable:(id)item {
    PSSale *sale = (PSSale *)item;
    
	if ([sale.details count] > 0) {
		return YES;
	}
	
	return NO;
}

- (id)outlineView:(NSOutlineView *)outlineView objectValueForTableColumn:(NSTableColumn *)tableColumn byItem:(id)item {
    id val = @"";
	
	PSSale *sale = (PSSale *)item;

    if ([[tableColumn identifier] isEqualToString:@"icon"]) {
        if (sale.isDetail) {
            val = [NSImage imageNamed:@""];
        } else {
            val = [NSImage imageNamed:@"Trolley.png"];
        }
    }
		
    if ([[tableColumn identifier] isEqualToString:@"date"]) {			
        val = sale.description;
    }
		
    if ([[tableColumn identifier] isEqualToString:@"total"]) {			
        val = [numberFormatter stringFromNumber:sale.total];
    }
        
    if ([[tableColumn identifier] isEqualToString:@"downloads"]) {			
        val = [numberFormatter stringFromNumber:sale.downloads];
    }
		
    if ([[tableColumn identifier] isEqualToString:@"sales"]) {			
        val = [numberFormatter stringFromNumber:sale.sales];
    }
		
    if ([[tableColumn identifier] isEqualToString:@"updates"]) {			
        val = [numberFormatter stringFromNumber:sale.updates];
    }
		
    if ([[tableColumn identifier] isEqualToString:@"refunds"]) {			
        val = [numberFormatter stringFromNumber:sale.refunds];
    }
				
    if ([[tableColumn identifier] isEqualToString:@"revenue"]) {
        val = [formatter stringFromNumber:sale.revenue];
    }
    
    return val;
}

- (void)outlineView:(NSOutlineView *)outlineView willDisplayCell:(NSCell *)cell forTableColumn:(NSTableColumn *)tableColumn item:(id)item {
	//
}

- (BOOL)outlineView:(NSOutlineView *)outlineView shouldEditTableColumn:(NSTableColumn *)tableColumn item:(id)item {
	return NO;
}

- (BOOL)outlineView:(NSOutlineView *)outlineView shouldSelectItem:(id)item {
	return YES;
}

- (BOOL)outlineView:(NSOutlineView *)outlineView isGroupItem:(id)item {
	return NO;
}

- (void)outlineView:(NSOutlineView *)outlineView didClickTableColumn:(NSTableColumn *)tableColumn {
	if (![[tableColumn identifier] isEqualToString:@"icon"]) {
		if (![lastIdentifier isEqualToString:[tableColumn identifier]]) {
			sortAscending = YES;
			lastIdentifier = [tableColumn identifier];
		} else {
			sortAscending = !sortAscending;
		}
		
		[self sortTableView:outlineView byIdentifier:[tableColumn identifier] ascending:sortAscending];
	}
}

- (void)sortTableView:(NSOutlineView *)outlineView byIdentifier:(NSString *)identifier ascending:(BOOL)order {
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
	
	if ([identifier isEqualToString:@"date"]) {
		[_sales sortUsingSelector:@selector(compareDate:)];
	}
	
	if (order) {
		[_sales reverse];
	}
	
    [PSSettings setFilterValue:identifier forKey:[NSString stringWithFormat:@"%@ Sorting Column", [outlineView autosaveName]]];
    [PSSettings setFilterValue:[NSNumber numberWithBool:order] forKey:[NSString stringWithFormat:@"%@ Sort Order", [outlineView autosaveName]]];

    [outlineView reloadData];
}

@end
