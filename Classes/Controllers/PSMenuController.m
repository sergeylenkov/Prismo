//
//  PSMenuController.m
//  Prismo
//
//  Created by Sergey Lenkov on 06.02.11.
//  Copyright 2011 Sergey Lenkov. All rights reserved.
//

#import "PSMenuController.h"

@implementation PSMenuController

@synthesize mainWindow;
@synthesize view;
@synthesize contentView;
@synthesize emptyView;
@synthesize filterView;
@synthesize infoButton;
@synthesize exportMenuItem;
@synthesize printMenuItem;

- (void)dealloc {
    [groups release];
    [reports release];
    [applications release];
    [subscriptions release];
    [purchases release];
	[ratings release];
	[ranks release];
	[formatter release];
	[numberFormatter release];
    [dashboardController release];
    [mapController release];
    [moneyController release];
    [applicationController release];
    [ratingsController release];
    [ranksController release];
    [compareController release];
    
	[super dealloc];
}

- (void)awakeFromNib {
    groups = [[NSMutableArray alloc] init];
    reports = [[NSMutableArray alloc] init];
    
    applications = [[NSMutableArray alloc] init];
    subscriptions = [[NSMutableArray alloc] init];
    purchases = [[NSMutableArray alloc] init];
	ratings = [[NSMutableArray alloc] init];
	ranks = [[NSMutableArray alloc] init];
		
	dashboardController = [[PSDashboardController alloc] initWithNibName:@"DashboardView" bundle:nil];
	[dashboardController loadView];
	
	mapController = [[PSMapController alloc] initWithNibName:@"MapView" bundle:nil];	
	[mapController loadView];
	
	applicationController = [[PSApplicationController alloc] initWithNibName:@"ApplicationView" bundle:nil];
	[applicationController loadView];
	
	moneyController = [[PSMoneyController alloc] initWithNibName:@"MoneyView" bundle:nil];
	[moneyController loadView];
	
	ratingsController = [[PSReviewsAndRatingsController alloc] initWithNibName:@"RatingsView" bundle:nil];
	[ratingsController loadView];
	
	ranksController = [[PSRanksController alloc] initWithNibName:@"RanksView" bundle:nil];
	[ranksController loadView];
		
    compareController = [[PSCompareController alloc] initWithNibName:@"CompareView" bundle:nil];
    [compareController loadView];
    
	PSOutlineItem *item = [[PSOutlineItem alloc] init];
	item.name = @"SUMMARY";
    item.type = PSOutlineItemTypeGroup;
    
	[groups addObject:item];
	[item release];
	
	item = [[PSOutlineItem alloc] init];
	item.name = @"APPLICATIONS";
    item.type = PSOutlineItemTypeGroup;
    
	[groups addObject:item];
	[item release];
	
	item = [[PSOutlineItem alloc] init];
	item.name = @"PURCHASES";
    item.type = PSOutlineItemTypeGroup;
    
	[groups addObject:item];
	[item release];
	
	item = [[PSOutlineItem alloc] init];
	item.name = @"SUBSCRIPTIONS";
    item.type = PSOutlineItemTypeGroup;
    
	[groups addObject:item];
	[item release];
	
	item = [[PSOutlineItem alloc] init];
	item.name = @"REVIEWS & RATINGS";
    item.type = PSOutlineItemTypeGroup;
    
	[groups addObject:item];
	[item release];
	
	item = [[PSOutlineItem alloc] init];
	item.name = @"RANKS";
    item.type = PSOutlineItemTypeGroup;
    
	[groups addObject:item];
	[item release];
	
    item = [[PSOutlineItem alloc] init];
	item.name = @"Dashboard";
    item.type = PSOutlineItemTypeReport;
    
    [reports addObject:item];
    [item release];
    
    item = [[PSOutlineItem alloc] init];
	item.name = @"Geography";
    item.type = PSOutlineItemTypeReport;
    
    [reports addObject:item];
    [item release];
    
    item = [[PSOutlineItem alloc] init];
	item.name = @"Money";
    item.type = PSOutlineItemTypeReport;
    
    [reports addObject:item];
    [item release];
    
    item = [[PSOutlineItem alloc] init];
	item.name = @"Compare";
    item.type = PSOutlineItemTypeReport;
    
    [reports addObject:item];
    [item release];
    
	formatter = [[NSNumberFormatter alloc] init];
	
	[formatter setFormatterBehavior:NSNumberFormatterBehavior10_4];
	[formatter setNumberStyle:NSNumberFormatterCurrencyStyle];
	[formatter setPositiveFormat:[NSString stringWithFormat:@"#,##0.00"]];
	
	numberFormatter = [[NSNumberFormatter alloc] init];
	
	[numberFormatter setFormatterBehavior:NSNumberFormatterBehavior10_4];
	[numberFormatter setNumberStyle:NSNumberFormatterDecimalStyle];
	
	defaults = [NSUserDefaults standardUserDefaults];
	
	if ([defaults objectForKey:@"Summary Info Type"] == nil) {
		infoType = 0;
	} else {
		infoType = [[defaults objectForKey:@"Summary Info Type"] intValue];
	}
    
    summaryInfo = @"";
}

- (void)refresh {
    PSData *data = [PSData sharedData];
    
    [applications removeAllObjects];
    [subscriptions removeAllObjects];
    [purchases removeAllObjects];
	[ratings removeAllObjects];
	[ranks removeAllObjects];

    for (PSApplication *application in data.applications) {
        PSOutlineItem *item = [[PSOutlineItem alloc] init];
        
        item.name = application.name;
        item.type = PSOutlineItemTypeApp;
        item.object = application;
        
        [applications addObject:item];
        
        [item release];
    }

    for (PSApplication *application in data.subscriptions) {
        PSOutlineItem *item = [[PSOutlineItem alloc] init];
        
        item.name = application.name;
        item.type = PSOutlineItemTypeApp;
        item.object = application;
        
        [subscriptions addObject:item];        
        [item release];
    }
    
    for (PSApplication *application in data.purchases) {
        PSOutlineItem *item = [[PSOutlineItem alloc] init];
        
        item.name = application.name;
        item.type = PSOutlineItemTypeApp;
        item.object = application;
        
        [purchases addObject:item];        
        [item release];
    }
    
    for (PSApplication *application in data.applications) {
        PSOutlineItem *item = [[PSOutlineItem alloc] init];
        
        item.name = application.name;
        item.type = PSOutlineItemTypeReviews;
        item.object = application;
        
        [ratings addObject:item];
        
        [item release];
    }
    
    for (PSApplication *application in data.applications) {
        PSOutlineItem *item = [[PSOutlineItem alloc] init];
        
        item.name = application.name;
        item.type = PSOutlineItemTypeRanks;
        item.object = application;
        
        [ranks addObject:item];
        
        [item release];
    }

    [dashboardController initialization];
    [mapController initialization];
    [moneyController initialization];
    [compareController initialization];

    [self refreshSummaryInfo];

	[view reloadData];

	for (int i = 0; i < [view numberOfRows]; i++ ) {
        PSOutlineItem *menuItem = (PSOutlineItem *)[view itemAtRow:i];
        
		if (menuItem.type == PSOutlineItemTypeGroup) {
			NSNumber *expand = [defaults objectForKey:[NSString stringWithFormat:@"%@ Expand", menuItem.name]];
			
			if (expand != nil && [expand boolValue]) {
				[view expandItem:[view itemAtRow:i]];
			}
		}
	}
	
	int index = 1;
	
	if ([defaults objectForKey:@"Selected Menu Item"] != nil) {		
		index = [[defaults objectForKey:@"Selected Menu Item"] intValue];
	} else {
        [view expandItem:nil expandChildren:YES];
    }
	
    if (currentItem && currentItem == [view itemAtRow:view.selectedRow]) {
        [self outlineViewSelectionDidChange:[NSNotification notificationWithName:@"NSObject" object:view]];
    } else {
        [view selectRowIndexes:[NSIndexSet indexSetWithIndex:index] byExtendingSelection:YES];
        currentItem = [view itemAtRow:view.selectedRow];
    }
}

- (void)refreshSelectedItem {
    if (currentController) {
        [currentController initialization];
        [currentController refresh];
    }
}

- (void)refreshSummaryInfo {
    PSData *data = [PSData sharedData];
    PSSale *sale = [data totalSale];

	if (infoType == 0) {
		summaryInfo = [[NSString stringWithFormat:@"%ld applications, %@ sales, %@%@", [data.applications count], [numberFormatter stringFromNumber:sale.sales], data.currencySymbol, [formatter stringFromNumber:sale.revenue]] copy];
	} else {
		summaryInfo = [[NSString stringWithFormat:@"%@ downloads, %@ sales, %@ updates, %@ refunds, %@%@", [numberFormatter stringFromNumber:sale.downloads], [numberFormatter stringFromNumber:sale.sales], [numberFormatter stringFromNumber:sale.updates], [numberFormatter stringFromNumber:sale.refunds], data.currencySymbol, [formatter stringFromNumber:sale.revenue]] copy];
	}
}

- (void)showSummaryInfo {	
	[infoButton setTitle:summaryInfo];
}

- (void)showSummaryInfoForApplication:(PSApplication *)application {
    PSData *data = [PSData sharedData];
    PSSale *sale = [data totalSaleForApplication:application];

    NSString *info = [NSString stringWithFormat:@"%@ downloads, %@ sales, %@ updates, %@ refunds, %@%@", [numberFormatter stringFromNumber:sale.downloads], [numberFormatter stringFromNumber:sale.sales], [numberFormatter stringFromNumber:sale.updates], [numberFormatter stringFromNumber:sale.refunds], data.currencySymbol, [formatter stringFromNumber:sale.revenue]];
    [infoButton setTitle:info];
}

#pragma mark -
#pragma mark NSOutlineView Protocol
#pragma mark -

- (int)outlineView:(NSOutlineView *)outlineView numberOfChildrenOfItem:(id)item {
    PSOutlineItem *menuItem = (PSOutlineItem *)item;
    
    if (!menuItem) {
		int count = 1;
		
		if ([applications count] > 0) {
			count = count + 3;
		}
		
		if ([purchases count] > 0) {
			count = count + 1;
		}		
		
		if ([subscriptions count] > 0) {
			count = count + 1;
		}
		
		return count;
    }

	if (menuItem.type == PSOutlineItemTypeGroup) {
		if ([menuItem.name isEqualToString:@"SUMMARY"]) {
			return [reports count];
		}
		
		if ([menuItem.name isEqualToString:@"APPLICATIONS"]) {
			return [applications count];
		}
		
		if ([menuItem.name isEqualToString:@"PURCHASES"]) {
			return [purchases count];
		}
		
		if ([menuItem.name isEqualToString:@"SUBSCRIPTIONS"]) {
			return [subscriptions count];
		}
		
		if ([menuItem.name isEqualToString:@"REVIEWS & RATINGS"]) {
			return [ratings count];
		}
		
		if ([menuItem.name isEqualToString:@"RANKS"]) {
			return [ranks count];
		}
	}
	
	return 0;
}

- (id)outlineView:(NSOutlineView *)outlineView child:(int)index ofItem:(id)item {
    PSOutlineItem *menuItem = (PSOutlineItem *)item;

    if (!menuItem) {
		if (index == 0) {
			return [groups objectAtIndex:0];
		}
		
		int lastIndex = 1;

		if ([applications count] > 0) {
			if (index == lastIndex) {
				return [groups objectAtIndex:1];
			}
			
			lastIndex = lastIndex + 1;
		}

		if ([purchases count] > 0) {
			if (index == lastIndex) {
				return [groups objectAtIndex:2];
			}
			
			lastIndex = lastIndex + 1;
		}

		if ([subscriptions count] > 0) {
			if (index == lastIndex) {
				return [groups objectAtIndex:3];
			}
			
			lastIndex = lastIndex + 1;
		}

		if (index == lastIndex) {
			return [groups objectAtIndex:4];
		}

		if (index == lastIndex + 1) {
			return [groups objectAtIndex:5];
		}
	} else {
		if (menuItem.type == PSOutlineItemTypeGroup) {
			if ([menuItem.name isEqualToString:@"SUMMARY"]) {
				return [reports objectAtIndex:index];
			}
			
			if ([menuItem.name isEqualToString:@"APPLICATIONS"]) {								
				return [applications objectAtIndex:index];
			}
			
			if ([menuItem.name isEqualToString:@"PURCHASES"]) {								
				return [purchases objectAtIndex:index];
			}
			
			if ([menuItem.name isEqualToString:@"SUBSCRIPTIONS"]) {								
				return [subscriptions objectAtIndex:index];
			}
			
			if ([menuItem.name isEqualToString:@"REVIEWS & RATINGS"]) {
				return [ratings objectAtIndex:index];
			}
			
			if ([menuItem.name isEqualToString:@"RANKS"]) {
				return [ranks objectAtIndex:index];
			}
		}
	}
	
	return nil;
}

- (BOOL)outlineView:(NSOutlineView *)outlineView isItemExpandable:(id)item {
    PSOutlineItem *menuItem = (PSOutlineItem *)item;
    
	if (menuItem.type == PSOutlineItemTypeGroup) {
		return YES;
	}
	
	return NO;
}

- (id)outlineView:(NSOutlineView *)outlineView objectValueForTableColumn:(NSTableColumn *)tableColumn byItem:(id)item {
    PSOutlineItem *menuItem = (PSOutlineItem *)item;
    
	if (menuItem != nil) {
		return menuItem.name;		
	}
    
    return nil;
}

- (void)outlineView:(NSOutlineView *)outlineView willDisplayCell:(NSCell*)cell forTableColumn:(NSTableColumn *)tableColumn item:(id)item {	
    PSOutlineItem *menuItem = (PSOutlineItem *)item;
    
	if (menuItem.type == PSOutlineItemTypeGroup) {
		[cell setImage:[NSImage imageNamed:@""]];
	} else {		
        BOOL isLion = [[NSApplication sharedApplication] isLion];
        
		if (menuItem.type == PSOutlineItemTypeReport) {
			if ([menuItem.name isEqualToString:@"Dashboard"]) {
                if (isLion) {
                    [cell setImage:[NSImage imageNamed:@"DashboardLion"]];
                } else {
                    [cell setImage:[NSImage imageNamed:@"Dashboard"]];
                }
			} 
			
			if ([menuItem.name isEqualToString:@"Geography"]) {
                if (isLion) {
                    [cell setImage:[NSImage imageNamed:@"Places"]];
                } else {
                    [cell setImage:[NSImage imageNamed:@"Earth"]];
                }
			}
			
			if ([menuItem.name isEqualToString:@"Money"]) {
				if (isLion) {
                    [cell setImage:[NSImage imageNamed:@"MoneyLion"]];
                } else {
                    [cell setImage:[NSImage imageNamed:@"Money"]];
                }
			}
            
            if ([menuItem.name isEqualToString:@"Compare"]) {
				if (isLion) {
                    [cell setImage:[NSImage imageNamed:@"CompareLion"]];
                } else {
                    [cell setImage:[NSImage imageNamed:@"Compare"]];
                }
			}
		}
		
		if (menuItem.type == PSOutlineItemTypeApp) {
            if (isLion) {
                PSApplication *application = (PSApplication *)menuItem.object;
                
                [cell setImage:[NSImage imageNamed:@"ApplicationLion"]];
                
                if ([application.type isEqualToString:@"iphone"] || [application.type isEqualToString:@"universal"]) {
                    [cell setImage:[NSImage imageNamed:@"iPhone"]];
                }
                
                if ([application.type isEqualToString:@"ipad"]) {
                    [cell setImage:[NSImage imageNamed:@"iPad"]];
                }
                
                if ([application.type isEqualToString:@"mac"]) {
                    [cell setImage:[NSImage imageNamed:@"MacBook"]];
                }
                
                if ([application.type isEqualToString:@"in-app"] || [application.type isEqualToString:@"subscription"]) {
                    [cell setImage:[NSImage imageNamed:@"Downloads"]];
                }
            } else {
                [cell setImage:[NSImage imageNamed:@"Application"]];
            }
		}
		
		if (menuItem.type == PSOutlineItemTypeReviews) {
            if (isLion) {
                [cell setImage:[NSImage imageNamed:@"People"]];
            } else {
                [cell setImage:[NSImage imageNamed:@"Reviews"]];
            }
		}
		
		if (menuItem.type == PSOutlineItemTypeRanks) {
            if (isLion) {
                [cell setImage:[NSImage imageNamed:@"RanksLion"]];
            } else {
                [cell setImage:[NSImage imageNamed:@"Ranks"]];
            }
		}
	}
}

- (BOOL)outlineView:(NSOutlineView *)outlineView shouldEditTableColumn:(NSTableColumn *)tableColumn item:(id)item {
	return NO;
}

- (BOOL)outlineView:(NSOutlineView *)outlineView shouldSelectItem:(id)item {
    PSOutlineItem *menuItem = (PSOutlineItem *)item;
    
	if (menuItem.type == PSOutlineItemTypeGroup) {
		return NO;
	}
	
	return YES;
}

- (BOOL)outlineView:(NSOutlineView *)outlineView isGroupItem:(id)item {
    PSOutlineItem *menuItem = (PSOutlineItem *)item;
    
	if (menuItem.type == PSOutlineItemTypeGroup) {
		return YES;
	}
	
	return NO;
}

- (void)outlineViewItemWillExpand:(NSNotification *)notification {
	PSOutlineItem *menuItem = [[notification userInfo] objectForKey:@"NSObject"];
	
	if (menuItem.type == PSOutlineItemTypeGroup) {
		[defaults setBool:YES forKey:[NSString stringWithFormat:@"%@ Expand", [menuItem name]]];
	}
}

- (void)outlineViewItemWillCollapse:(NSNotification *)notification {
	PSOutlineItem *menuItem = [[notification userInfo] objectForKey:@"NSObject"];
	
	if (menuItem.type == PSOutlineItemTypeGroup) {
		[defaults setBool:NO forKey:[NSString stringWithFormat:@"%@ Expand", [menuItem name]]];
	}
}

- (void)outlineViewSelectionDidChange:(NSNotification *)notification {
	int selectedRow = view.selectedRow;

    [emptyView removeFromSuperview];
	[dashboardController.view removeFromSuperview];
	[mapController.view removeFromSuperview];
	[applicationController.view removeFromSuperview];
	[moneyController.view removeFromSuperview];
	[ratingsController.view removeFromSuperview];
	[ranksController.view removeFromSuperview];
    [compareController.view removeFromSuperview];

	[infoButton setHidden:NO];
	
	[exportMenuItem setEnabled:NO];
	[printMenuItem setEnabled:NO];
	
    if ([applications count] == 0 && [subscriptions count] == 0 && [purchases count] == 0) {
        [emptyView setFrame:contentView.bounds];
        [contentView addSubview:emptyView];
        
        return;
    }
    
	if (selectedRow != -1) {
		PSOutlineItem *menuItem = [view itemAtRow:selectedRow];
        currentItem = [view itemAtRow:view.selectedRow];
        
		if (menuItem.type == PSOutlineItemTypeReport) {
            if ([menuItem.name isEqualToString:@"Dashboard"]) {
                currentController = dashboardController;
                
                [dashboardController refresh];
                
                [dashboardController.view setFrame:[contentView bounds]];
                [contentView addSubview:dashboardController.view];
            } 
			
            if ([menuItem.name isEqualToString:@"Geography"]) {
                currentController = mapController;
                
                [mapController refresh];
                
                [mapController.view setFrame:[contentView bounds]];
                [contentView addSubview:mapController.view];
            }
			
            if ([menuItem.name isEqualToString:@"Money"]) {
                currentController = moneyController;
                
                [moneyController refresh];
                
                [moneyController.view setFrame:[contentView bounds]];
                [contentView addSubview:moneyController.view];
            }
			
            if ([menuItem.name isEqualToString:@"Compare"]) {
                currentController = compareController;
                
                [compareController refresh];
                
                [compareController.view setFrame:[contentView bounds]];
                [contentView addSubview:compareController.view];
            }
            
			[self showSummaryInfo];
		}
		
		if (menuItem.type == PSOutlineItemTypeApp) {
            currentController = applicationController;
            
			applicationController.application = menuItem.object;
			
			[applicationController initialization];
			[applicationController refresh];
					
			[applicationController.view setFrame:[contentView bounds]];
			[contentView addSubview:applicationController.view];
            
            [self showSummaryInfoForApplication:menuItem.object];
		}
		
		if (menuItem.type == PSOutlineItemTypeReviews) {
            currentController = ratingsController;
            
			ratingsController.application = menuItem.object;
			
			[ratingsController initialization];
			[ratingsController refresh];
			
			[ratingsController.view setFrame:[contentView bounds]];
			[contentView addSubview:ratingsController.view];
			
			[self showSummaryInfo];
		}
		
		if (menuItem.type == PSOutlineItemTypeRanks) {
            currentController = ranksController;
            
			ranksController.application = menuItem.object;

			[ranksController initialization];
			[ranksController refresh];

			[ranksController.view setFrame:[contentView bounds]];
			[contentView addSubview:ranksController.view];
            
			[self showSummaryInfo];
		}
        
        [exportMenuItem setEnabled:[currentController isCanExport]];
        [printMenuItem setEnabled:[currentController isCanPrint]];
        
		[defaults setObject:[NSNumber numberWithInt:selectedRow] forKey:@"Selected Menu Item"];
	} else {
		[self showSummaryInfo];
	}
}

#pragma mark -
#pragma mark IBAction
#pragma mark -

- (IBAction)print:(id)sender {
    [currentController print];
}

- (IBAction)export:(id)sender {
    NSSavePanel *panel = [NSSavePanel savePanel];
    [panel setNameFieldStringValue:@""];

    [panel beginSheetModalForWindow:mainWindow completionHandler:^(NSInteger result) {
        if (result == NSFileHandlingPanelOKButton) {
            [currentController exportToFile:panel.URL];
        }
    }];
}

- (IBAction)changeInfoType:(id)sender {
	if (infoType == 0) {
		infoType = 1;
	} else {
		infoType = 0;
	}

	[defaults setInteger:infoType forKey:@"Summary Info Type"];
		
	[self refreshSummaryInfo];
	[self showSummaryInfo];
}

@end
