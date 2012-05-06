//
//  PSMoneyController.m
//  Prismo
//
//  Created by Sergey Lenkov on 01.10.11.
//  Copyright 2011 Sergey Lenkov. All rights reserved.
//

#import "PSMoneyController.h"

@implementation PSMoneyController

- (void)dealloc {
	[formatter release];
    [numberFormatter release];
	[series release];
	[values release];
    [filterController release];
	[super dealloc];
}

- (void)awakeFromNib {
	series = [[NSMutableArray alloc] init];
	values = [[NSMutableArray alloc] init];
	
	formatter = [[NSNumberFormatter alloc] init];
	
	[formatter setFormatterBehavior:NSNumberFormatterBehavior10_4];
	[formatter setNumberStyle:NSNumberFormatterCurrencyStyle];
	[formatter setPositiveFormat:@"#,##0.00"];
	
	numberFormatter = [[NSNumberFormatter alloc] init];
	
	[numberFormatter setFormatterBehavior:NSNumberFormatterBehavior10_4];
	[numberFormatter setNumberStyle:NSNumberFormatterDecimalStyle];
	
	mainGraphView.showMarker = YES;
	mainGraphView.lineWidth = 1.4;
	mainGraphView.drawBullets = NO;
    mainGraphView.highlightBullet = YES;
    mainGraphView.drawBottomMarker = NO;
    mainGraphView.useMinValue = YES;
    mainGraphView.minValue = 0.0;
    mainGraphView.formatter = formatter;
    
    mainGraphView.marker.backgroundColor = [NSColor colorWithDeviceRed:0.0/255.0 green:0.0/255.0 blue:0.0/255.0 alpha:0.8];
	mainGraphView.marker.borderColor = [NSColor colorWithDeviceRed:0.0/255.0 green:0.0/255.0 blue:0.0/255.0 alpha:0.8];
	mainGraphView.marker.textColor = [NSColor whiteColor];
	mainGraphView.marker.type = YBMarkerTypeRectWithArrow;
	mainGraphView.marker.shadow = YES;
    
    filterController = [[PSMoneyFilterController alloc] initWithWindowNibName:@"MoneyFilterWindow"];
    filterController.delegate = self;
    
    popoverController = [[SFBPopoverWindowController alloc] initWithWindow:filterController.window];
    
    [super awakeFromNib];
}

- (void)initialization {
    [filterController initialization];

	if ([PSSettings filterValueForKey:@"Money View Index"] == nil) {
		[changeViewButton setSelectedSegment:0];
	} else {
		NSInteger index = [[PSSettings filterValueForKey:@"Money View Index"] intValue];
		[changeViewButton setSelectedSegment:index];
	}
	
	[self viewChanged:self];
}

- (void)refresh {
	PSData *data = [PSData sharedData];
    
    [series removeAllObjects];
    [values removeAllObjects];

    NSMutableArray *allSales = [[NSMutableArray alloc] initWithArray:[data salesFromDate:filterController.fromDate toDate:filterController.toDate]];

	if (filterController.groupBy == PSGraphGroupByDay) {
		for (PSSale *sale in allSales) {
            if ([sale.date year] == [[NSDate date] year]) {
                [series addObject:[PSUtilites localizedShortDateWithFullMonth:sale.date]];
            } else {
                [series addObject:[PSUtilites localizedMediumDateWithFullMonth:sale.date]];
            }
            
            [values addObject:sale.revenue];
		}
	}
    
	if ([allSales count] > 0 && (filterController.groupBy == PSGraphGroupByWeek || filterController.groupBy == PSGraphGroupByMonth)) {
        PSSale *sale = [allSales objectAtIndex:0];
        NSDate *startDate = sale.date;
        
        int component;
        
        if (filterController.groupBy ==PSGraphGroupByWeek) {
            component = [sale.date week];
        } else {
            component = [sale.date month];
        }
        
        float revenueSum = 0.0;
        
		for (int i = 0; i < [allSales count]; i++) {
            PSSale *sale = [allSales objectAtIndex:i];
            
            if ([sale.date year] == [[NSDate date] year]) {
                sale.description = [PSUtilites localizedShortDateWithFullMonth:sale.date];
            } else {
                sale.description = [PSUtilites localizedMediumDateWithFullMonth:sale.date];
            }
            
            revenueSum = revenueSum + [sale.revenue floatValue];

            NSDate *endDate = sale.date;
            
            if (i < [allSales count] - 1) {
                PSSale *next = [allSales objectAtIndex:i + 1];
                int nextComponent;
                
                if (filterController.groupBy == PSGraphGroupByWeek) {
                    nextComponent = [next.date week];
                } else {
                    nextComponent = [next.date month];
                }
                
                if (nextComponent != component) {
                    if (filterController.groupBy == PSGraphGroupByWeek) {
                        if ([startDate year] == [[NSDate date] year] && [endDate year] == [[NSDate date] year]) {
                            if ([startDate month] == [endDate month]) {
                                [series addObject:[NSString stringWithFormat:@"%d - %@", [startDate day], [PSUtilites localizedShortPeriodDateWithFullMonth:endDate]]];
                            } else {
                                [series addObject:[NSString stringWithFormat:@"%@ - %@", [PSUtilites localizedShortDateWithFullMonth:startDate], [PSUtilites localizedShortDateWithFullMonth:endDate]]];
                            }
                        } else {
                            if ([startDate month] == [endDate month]) {
                                [series addObject:[NSString stringWithFormat:@"%d - %@", [startDate day], [PSUtilites localizedMediumPeriodDateWithFullMonth:endDate]]];
                            } else {
                                [series addObject:[NSString stringWithFormat:@"%@ - %@", [PSUtilites localizedShortDateWithFullMonth:startDate], [PSUtilites localizedMediumDateWithFullMonth:endDate]]];
                            }
                        }
                    } else {
                        [series addObject:[PSUtilites localizedMonthName:startDate]];
                    }
                    
                    [values addObject:[NSNumber numberWithFloat:revenueSum]];

                    revenueSum = 0.0;
                    component = nextComponent;
                    startDate = next.date;                    
                }
            } else {
                if (filterController.groupBy == PSGraphGroupByWeek) {
                    if ([startDate year] == [[NSDate date] year] && [endDate year] == [[NSDate date] year]) {
                        if ([startDate month] == [endDate month]) {
                            [series addObject:[NSString stringWithFormat:@"%d - %@", [startDate day], [PSUtilites localizedShortPeriodDateWithFullMonth:endDate]]];
                        } else {
                            [series addObject:[NSString stringWithFormat:@"%@ - %@", [PSUtilites localizedShortDateWithFullMonth:startDate], [PSUtilites localizedShortDateWithFullMonth:endDate]]];
                        }
                    } else {
                        if ([startDate month] == [endDate month]) {
                            [series addObject:[NSString stringWithFormat:@"%d - %@", [startDate day], [PSUtilites localizedMediumPeriodDateWithFullMonth:endDate]]];
                        } else {
                            [series addObject:[NSString stringWithFormat:@"%@ - %@", [PSUtilites localizedShortDateWithFullMonth:startDate], [PSUtilites localizedMediumDateWithFullMonth:endDate]]];
                        }
                    }
                } else {
                    [series addObject:[PSUtilites localizedMonthName:startDate]];
                }
                
                [values addObject:[NSNumber numberWithFloat:revenueSum]];
            }
        }
	}

    [allSales release];
    
    if ([series count] < 70) {
		mainGraphView.drawBullets = YES;
		mainGraphView.lineWidth = 1.8;
	} else {
		mainGraphView.drawBullets = NO;
		mainGraphView.lineWidth = 1.4;
	}
    
    [self draw];
    
    NSDictionary *dict = [data revenueByCurrenciesFromDate:filterController.fromDate toDate:filterController.toDate];

    if ([dict objectForKey:@"USD"] == nil) {
		[USDField setStringValue:[NSString stringWithFormat:@"$%@", [formatter stringFromNumber:[NSNumber numberWithInt:0]]]];
	} else {
		[USDField setStringValue:[NSString stringWithFormat:@"$%@", [formatter stringFromNumber:[dict objectForKey:@"USD"]]]];
	}
    
	if ([dict objectForKey:@"EUR"] == nil) {
		[EURField setStringValue:[NSString stringWithFormat:@"€%@", [formatter stringFromNumber:[NSNumber numberWithInt:0]]]];
	} else {
		[EURField setStringValue:[NSString stringWithFormat:@"€%@", [formatter stringFromNumber:[dict objectForKey:@"EUR"]]]];
	}
	
	if ([dict objectForKey:@"GBP"] == nil) {
		[GBPField setStringValue:[NSString stringWithFormat:@"£%@", [formatter stringFromNumber:[NSNumber numberWithInt:0]]]];
	} else {
		[GBPField setStringValue:[NSString stringWithFormat:@"£%@", [formatter stringFromNumber:[dict objectForKey:@"GBP"]]]];
	}
	
	if ([dict objectForKey:@"JPY"] == nil) {
		[JPYField setStringValue:[NSString stringWithFormat:@"¥%@", [formatter stringFromNumber:[NSNumber numberWithInt:0]]]];
	} else {
		[JPYField setStringValue:[NSString stringWithFormat:@"¥%@", [formatter stringFromNumber:[dict objectForKey:@"JPY"]]]];
	}
	
	if ([dict objectForKey:@"CAD"] == nil) {
		[CADField setStringValue:[NSString stringWithFormat:@"$%@", [formatter stringFromNumber:[NSNumber numberWithInt:0]]]];
	} else {
		[CADField setStringValue:[NSString stringWithFormat:@"$%@", [formatter stringFromNumber:[dict objectForKey:@"CAD"]]]];
	}
	
	if ([dict objectForKey:@"AUD"] == nil) {
		[AUDField setStringValue:[NSString stringWithFormat:@"$%@", [formatter stringFromNumber:[NSNumber numberWithInt:0]]]];
	} else {
		[AUDField setStringValue:[NSString stringWithFormat:@"$%@", [formatter stringFromNumber:[dict objectForKey:@"AUD"]]]];
	}
    	
	NSNumber *revenueUS = [data revenueForRegion:@"AMERICAS" fromDate:filterController.fromDate toDate:filterController.toDate];
	NSNumber *revenueEU = [data revenueForRegion:@"EUROPE" fromDate:filterController.fromDate toDate:filterController.toDate];
	NSNumber *revenueCA = [data revenueForRegion:@"CA" fromDate:filterController.fromDate toDate:filterController.toDate];
	NSNumber *revenueAU = [data revenueForRegion:@"AU" fromDate:filterController.fromDate toDate:filterController.toDate];
	NSNumber *revenueGB = [data revenueForRegion:@"GB" fromDate:filterController.fromDate toDate:filterController.toDate];
	NSNumber *revenueJP = [data revenueForRegion:@"JP" fromDate:filterController.fromDate toDate:filterController.toDate];
	
	NSNumber *revenueTotal = [data revenueFromDate:filterController.fromDate toDate:filterController.toDate];
	NSNumber *revenueWW = [NSNumber numberWithFloat:[revenueTotal floatValue] - [revenueUS floatValue] - [revenueEU floatValue] - [revenueCA floatValue] -
												    [revenueAU floatValue] - [revenueGB floatValue] - [revenueJP floatValue]];
	
	NSString *currency = data.currencySymbol;

	[USField setStringValue:[NSString stringWithFormat:@"%@%@", currency, [formatter stringFromNumber:revenueUS]]];
	[EUField setStringValue:[NSString stringWithFormat:@"%@%@", currency, [formatter stringFromNumber:revenueEU]]];
	[CAField setStringValue:[NSString stringWithFormat:@"%@%@", currency, [formatter stringFromNumber:revenueCA]]];
	[AUField setStringValue:[NSString stringWithFormat:@"%@%@", currency, [formatter stringFromNumber:revenueAU]]];
	[GBField setStringValue:[NSString stringWithFormat:@"%@%@", currency, [formatter stringFromNumber:revenueGB]]];
	[JPField setStringValue:[NSString stringWithFormat:@"%@%@", currency, [formatter stringFromNumber:revenueJP]]];
	[WWField setStringValue:[NSString stringWithFormat:@"%@%@", currency, [formatter stringFromNumber:revenueWW]]];
	[ALLField setStringValue:[NSString stringWithFormat:@"%@%@", currency, [formatter stringFromNumber:revenueTotal]]];
}

- (void)draw {
	[mainGraphView draw];
}

#pragma mark -
#pragma mark YBGraphView Protocol
#pragma mark -

- (NSInteger)numberOfGraphsInGraphView:(YBGraphView *)graph {
	return 1;
}

- (NSArray *)seriesForGraphView:(YBGraphView *)graph {
	return series;
}

- (NSArray *)graphView:(YBGraphView *)graph valuesForGraph:(NSInteger)index {	
	return values;
}

- (NSString *)graphView:(YBGraphView *)graph markerTitleForGraph:(NSInteger)graphIndex forElement:(NSInteger)elementIndex {
	return [NSString stringWithFormat:@"%@\n%@", [series objectAtIndex:elementIndex], [formatter stringFromNumber:[values objectAtIndex:elementIndex]]];
}

#pragma mark -
#pragma mark PSFilterControllerDelegate
#pragma mark -

- (void)filterDidChanged:(PSFilterController *)controller {
    [self refresh];
}

#pragma mark -
#pragma mark IBAction
#pragma mark -

- (IBAction)viewChanged:(id)sender {
	[graphView removeFromSuperview];
	[currenciesView removeFromSuperview];
	[regionsView removeFromSuperview];

	if ([changeViewButton selectedSegment] == 0) {
		[graphView setFrame:[contentView bounds]];
		[contentView addSubview:graphView];
	}
	
	if ([changeViewButton selectedSegment] == 1) {	
		[regionsView setFrame:[contentView bounds]];
		[contentView addSubview:regionsView];
	}
	
	if ([changeViewButton selectedSegment] == 2) {		
		[currenciesView setFrame:[contentView bounds]];
		[contentView addSubview:currenciesView];
	}

	[PSSettings setFilterValue:[NSNumber numberWithInt:changeViewButton.selectedSegment] forKey:@"Money View Index"];
}

@end
