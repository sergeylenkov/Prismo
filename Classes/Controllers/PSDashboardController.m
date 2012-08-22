//
//  DashboardController.m
//  Prismo
//
//  Created by Sergey Lenkov on 01.10.11.
//  Copyright 2011 Sergey Lenkov. All rights reserved.
//

#import "PSDashboardController.h"

@implementation PSDashboardController

@synthesize filterController;

- (void)dealloc {
	[formatter release];
	[numberFormatter release];
    [series release];
    [graphTotal release];
	[graphDownloads release];
	[graphSales release];
	[graphUpdates release];
	[graphRefunds release];
    [graphRevenue release];
    [filterController release];
    
	[super dealloc];
}

- (void)awakeFromNib {
	series = [[NSMutableArray alloc] init];
    graphTotal = [[NSMutableArray alloc] init];
	graphDownloads = [[NSMutableArray alloc] init];
	graphSales = [[NSMutableArray alloc] init];
	graphUpdates = [[NSMutableArray alloc] init];
	graphRefunds = [[NSMutableArray alloc] init];
	graphRevenue = [[NSMutableArray alloc] init];
	
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
    mainGraphView.formatter = numberFormatter;
    
    mainGraphView.marker.backgroundColor = [NSColor colorWithDeviceRed:0.0/255.0 green:0.0/255.0 blue:0.0/255.0 alpha:0.8];
	mainGraphView.marker.borderColor = [NSColor colorWithDeviceRed:0.0/255.0 green:0.0/255.0 blue:0.0/255.0 alpha:0.8];
	mainGraphView.marker.textColor = [NSColor whiteColor];
	mainGraphView.marker.type = YBMarkerTypeRectWithArrow;
	mainGraphView.marker.shadow = YES;
    
	downloadsGraphView.showMarker = NO;	
	downloadsGraphView.drawBullets = NO;
    downloadsGraphView.highlightBullet = NO;
	downloadsGraphView.lineWidth = 1.2;
	downloadsGraphView.drawAxesY = NO;
	downloadsGraphView.drawAxesX = NO;
	downloadsGraphView.drawGridY = NO;
	downloadsGraphView.drawGridX = NO;
	downloadsGraphView.formatter = numberFormatter;
	downloadsGraphView.drawInfo = YES;
	downloadsGraphView.fillGraph = YES;
	downloadsGraphView.useMinValue = YES;
    downloadsGraphView.minValue = 0.0;
    
	salesGraphView.showMarker = NO;	
	salesGraphView.drawBullets = NO;
    salesGraphView.highlightBullet = NO;
	salesGraphView.lineWidth = 1.2;
	salesGraphView.drawAxesY = NO;
	salesGraphView.drawAxesX = NO;
	salesGraphView.drawGridY = NO;
	salesGraphView.drawGridX = NO;
	salesGraphView.formatter = numberFormatter;
	salesGraphView.drawInfo = YES;
	salesGraphView.fillGraph = YES;
	salesGraphView.useMinValue = YES;
    salesGraphView.minValue = 0.0;
    
	updatesGraphView.showMarker = NO;	
	updatesGraphView.drawBullets = NO;
    updatesGraphView.highlightBullet = NO;
	updatesGraphView.lineWidth = 1.2;
	updatesGraphView.drawAxesY = NO;
	updatesGraphView.drawAxesX = NO;
	updatesGraphView.drawGridY = NO;
	updatesGraphView.drawGridX = NO;
	updatesGraphView.formatter = numberFormatter;
	updatesGraphView.drawInfo = YES;
	updatesGraphView.fillGraph = YES;
	updatesGraphView.useMinValue = YES;
    updatesGraphView.minValue = 0.0;
    
	revenueGraphView.showMarker = NO;	
	revenueGraphView.drawBullets = NO;
    revenueGraphView.highlightBullet = NO;
	revenueGraphView.lineWidth = 1.2;
	revenueGraphView.drawAxesY = NO;
	revenueGraphView.drawAxesX = NO;
	revenueGraphView.drawGridY = NO;
	revenueGraphView.drawGridX = NO;
	revenueGraphView.formatter = formatter;
	revenueGraphView.drawInfo = YES;
	revenueGraphView.fillGraph = YES;
    revenueGraphView.useMinValue = YES;
    revenueGraphView.minValue = 0.0;
    
    filterController = [[PSDashboardFilterController alloc] initWithWindowNibName:@"DashboardFilterWindow"];
    filterController.delegate = self;
    
    popoverController = [[SFBPopoverWindowController alloc] initWithWindow:filterController.window];

    [super awakeFromNib];
}

- (void)initialization {
    [filterController initialization];

	if ([PSSettings filterValueForKey:@"Dashboard View Index"] == nil) {
		[changeViewButton setSelectedSegment:0];
	} else {
        NSInteger index = [[PSSettings filterValueForKey:@"Dashboard View Index"] intValue];
		[changeViewButton setSelectedSegment:index];
	}
	
	[self viewChanged:self];
}

- (void)refresh {
    PSData *data = [PSData sharedData];

	NSMutableArray *sales = [[NSMutableArray alloc] init];
    NSMutableArray *allSales = [[NSMutableArray alloc] init];
    
    int days = [filterController.fromDate daysCountBetweenDate:filterController.toDate];
    
    for (int i = 0; i <= days; i++) {
        NSDate *date = [filterController.fromDate dateByAddingDays:i];
        [allSales addObject:[data saleForDate:date]];
    }

	if (filterController.groupBy == PSGraphGroupByDay) {
		for (PSSale *sale in allSales) {
			NSMutableArray *details = [[NSMutableArray alloc] init];
						
			for (PSApplication *application in data.allSaleItems) {
                PSSale *detail = [data saleForDate:sale.date application:application];
                
                if ([detail.total intValue] > 0) {
                    detail.description = application.name;
                    detail.isDetail = YES;
                    
                    [details addObject:detail];
                }
			}
			
            if ([sale.date year] == [[NSDate date] year]) {
                sale.description = [PSUtilites localizedShortDateWithFullMonth:sale.date];
            } else {
                sale.description = [PSUtilites localizedMediumDate:sale.date];
            }
            
			sale.details = details;
            sale.isDetail = NO;
            
			[details release];
			
			[sales addObject:sale];			
		}
	}

	if ([allSales count] > 0 && (filterController.groupBy == PSGraphGroupByWeek || filterController.groupBy == PSGraphGroupByMonth)) {
		NSMutableArray *details = [[NSMutableArray alloc] init];
		
        PSSale *sale = [allSales objectAtIndex:0];
        NSDate *startDate = sale.date;
        
        int component;
        
        if (filterController.groupBy == PSGraphGroupByWeek) {
            component = [sale.date week];
        } else {
            component = [sale.date month];
        }
        
        int totalSum = 0;
        int downloadsSum = 0;
        int salesSum = 0;
        int updatesSum = 0;
        int refundsSum = 0;
        float revenueSum = 0.0;
        
		for (int i = 0; i < [allSales count]; i++) {
            PSSale *sale = [allSales objectAtIndex:i];
            sale.isDetail = YES;
            sale.description = [PSUtilites localizedShortDateWithFullMonth:sale.date];
            
            totalSum = totalSum + [sale.total intValue];
            downloadsSum = downloadsSum + [sale.downloads intValue];
            salesSum = salesSum + [sale.sales intValue];
            updatesSum = updatesSum + [sale.updates intValue];
            refundsSum = refundsSum + [sale.refunds intValue];
            revenueSum = revenueSum + [sale.revenue floatValue];
            
            [details addObject:sale];
            
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
                    PSSale *newSale = [[PSSale alloc] init];
                    
                    newSale.date = startDate;
                    newSale.total = [NSNumber numberWithInt:totalSum];
                    newSale.downloads = [NSNumber numberWithInt:downloadsSum];
                    newSale.sales = [NSNumber numberWithInt:salesSum];
                    newSale.updates = [NSNumber numberWithInt:updatesSum];
                    newSale.refunds  = [NSNumber numberWithInt:refundsSum];
                    newSale.revenue = [NSNumber numberWithFloat:revenueSum];
                    newSale.details = [NSMutableArray arrayWithArray:details];
                    newSale.isDetail = YES;
                    
                    [newSale.details reverse];
                    
                    if (filterController.groupBy == PSGraphGroupByWeek) {
                        if ([startDate year] == [[NSDate date] year] && [endDate year] == [[NSDate date] year]) {
                            if ([startDate month] == [endDate month]) {
                                newSale.description = [NSString stringWithFormat:@"%ld - %@", [startDate day], [PSUtilites localizedShortPeriodDateWithFullMonth:endDate]];
                            } else {
                                newSale.description = [NSString stringWithFormat:@"%@ - %@", [PSUtilites localizedShortDateWithFullMonth:startDate], [PSUtilites localizedShortDateWithFullMonth:endDate]];
                            }
                        } else {
                            if ([startDate month] == [endDate month]) {
                                newSale.description = [NSString stringWithFormat:@"%ld - %@", [startDate day], [PSUtilites localizedMediumPeriodDateWithFullMonth:endDate]];
                            } else {
                                newSale.description = [NSString stringWithFormat:@"%@ - %@", [PSUtilites localizedShortDateWithFullMonth:startDate], [PSUtilites localizedMediumDateWithFullMonth:endDate]];
                            }
                        }
                    } else {
                        newSale.description = [PSUtilites localizedMonthName:startDate];
                    }
                    
                    [sales addObject:newSale];
                    [newSale release];
                    
                    totalSum = 0;
                    downloadsSum = 0;
                    salesSum = 0;
                    updatesSum = 0;
                    refundsSum = 0;
                    revenueSum = 0.0;
                    
                    [details removeAllObjects];
                    component = nextComponent;
                    
                    startDate = next.date;                    
                }
            } else {
                PSSale *newSale = [[PSSale alloc] init];
                
                newSale.date = startDate;
                newSale.total = [NSNumber numberWithInt:totalSum];
                newSale.downloads = [NSNumber numberWithInt:downloadsSum];
                newSale.sales = [NSNumber numberWithInt:salesSum];
                newSale.updates = [NSNumber numberWithInt:updatesSum];
                newSale.refunds  = [NSNumber numberWithInt:refundsSum];
                newSale.revenue = [NSNumber numberWithFloat:revenueSum];
                newSale.details = [NSMutableArray arrayWithArray:details];
                newSale.isDetail = YES;
                
                [newSale.details reverse];
                
                if (filterController.groupBy == PSGraphGroupByWeek) {
                    if ([startDate year] == [[NSDate date] year] && [endDate year] == [[NSDate date] year]) {
                        if ([startDate month] == [endDate month]) {
                            newSale.description = [NSString stringWithFormat:@"%ld - %@", [startDate day], [PSUtilites localizedShortPeriodDateWithFullMonth:endDate]];
                        } else {
                            newSale.description = [NSString stringWithFormat:@"%@ - %@", [PSUtilites localizedShortDateWithFullMonth:startDate], [PSUtilites localizedShortDateWithFullMonth:endDate]];
                        }
                    } else {
                        if ([startDate month] == [endDate month]) {
                            newSale.description = [NSString stringWithFormat:@"%ld - %@", [startDate day], [PSUtilites localizedMediumPeriodDateWithFullMonth:endDate]];
                        } else {
                            newSale.description = [NSString stringWithFormat:@"%@ - %@", [PSUtilites localizedShortDateWithFullMonth:startDate], [PSUtilites localizedMediumDateWithFullMonth:endDate]];
                        }
                    }
                } else {
                    newSale.description = [PSUtilites localizedMonthName:startDate];
                }
                
                [sales addObject:newSale];
                [newSale release];
            }
        }
             
		[details release];
	}
	
    int totalDownloads = 0;
	int totalSales = 0;
	int totalUpdates = 0;
	int totalRefunds = 0;
	float totalRevenue = 0.0;
    
    [series removeAllObjects];
    [graphTotal removeAllObjects];
	[graphDownloads removeAllObjects];
	[graphSales removeAllObjects];
	[graphUpdates removeAllObjects];
	[graphRevenue removeAllObjects];
    
	for (PSSale *sale in sales) {
        [series addObject:sale.description];

        totalDownloads = totalDownloads + [sale.downloads intValue];
        totalSales = totalSales + [sale.sales intValue];
        totalUpdates = totalUpdates + [sale.updates intValue];
        totalRefunds = totalRefunds + [sale.refunds intValue];
        totalRevenue = totalRevenue + [sale.revenue floatValue];
        
        [graphTotal addObject:sale.total];
		[graphDownloads addObject:sale.downloads];
		[graphSales addObject:sale.sales];
		[graphUpdates addObject:sale.updates];
		[graphRefunds addObject:sale.refunds];
		[graphRevenue addObject:sale.revenue];
	}

	downloadsGraphView.info = [NSString stringWithFormat:@"%@ Downloads", [numberFormatter stringFromNumber:[NSNumber numberWithInt:totalDownloads]]];	
	updatesGraphView.info = [NSString stringWithFormat:@"%@ Updates", [numberFormatter stringFromNumber:[NSNumber numberWithInt:totalUpdates]]];
	salesGraphView.info = [NSString stringWithFormat:@"%@ Sales", [numberFormatter stringFromNumber:[NSNumber numberWithInt:totalSales]]];
	revenueGraphView.info = [NSString stringWithFormat:@"%@%@ Revenue", data.currencySymbol, [formatter stringFromNumber:[NSNumber numberWithFloat:totalRevenue]]];

	detailsController.sales = sales;
	
	if ([series count] < 70) {
		mainGraphView.drawBullets = YES;
		mainGraphView.lineWidth = 1.8;
	} else {
		mainGraphView.drawBullets = NO;
		mainGraphView.lineWidth = 1.4;
	}
    
	[sales release];
	[allSales release];

	[self draw];
}

- (void)draw {	
	[mainGraphView draw];
	[downloadsGraphView draw];
	[salesGraphView draw];
	[updatesGraphView draw];
	[revenueGraphView draw];
}

- (BOOL)isCanPrint {
    return YES;
}

- (BOOL)isCanExport {
    return YES;
}

- (void)exportToFile:(NSURL *)fileName {
	NSString *csv = @"\"DATE\",\"TOTAL\",\"DOWNLOADS\",\"REFUNDS\",\"UPDATES\",\"SALES\",\"REVENUE\"\n";
	
	for (PSSale *sale in detailsController.sales) {
		NSString *line = [NSString stringWithFormat:@"\"%@\",\"%d\",\"%d\",\"%d\",\"%d\",\"%d\",\"%@\"\n", [sale.date dbDateRepresentation], [sale.total intValue], [sale.downloads intValue], [sale.refunds intValue], [sale.updates intValue], [sale.sales intValue], [numberFormatter stringFromNumber:sale.revenue]];
		csv = [csv stringByAppendingString:line];
	}

    [csv writeToURL:fileName atomically:YES encoding:NSUTF8StringEncoding error:nil];
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
	if (graph == mainGraphView) {
		switch (filterController.type) {
			case PSGraphTypeTotal:
				mainGraphView.formatter = numberFormatter;
				return graphTotal;
				break;
            case PSGraphTypeDownloads:
				mainGraphView.formatter = numberFormatter;
				return graphDownloads;
				break;
			case PSGraphTypeSales:
				mainGraphView.formatter = numberFormatter;
				return graphSales;
				break;
            case PSGraphTypeUpdates:
				mainGraphView.formatter = numberFormatter;
				return graphUpdates;
				break;
			case PSGraphTypeRevenue:
				mainGraphView.formatter = formatter;
				return graphRevenue;
				break;			
			default:
				mainGraphView.formatter = numberFormatter;
				return graphTotal;
				break;
		}
	}
	
	if (graph == downloadsGraphView) {
		return graphDownloads;
	}
	
	if (graph == salesGraphView) {
		return graphSales;
	}
	
	if (graph == updatesGraphView) {
		return graphUpdates;
	}
	
	if (graph == revenueGraphView) {
		return graphRevenue;
	}
	
	return nil;
}

- (NSString *)graphView:(YBGraphView *)graph markerTitleForGraph:(NSInteger)graphIndex forElement:(NSInteger)elementIndex {
	NSString *value = @"";
	
	if (graph == mainGraphView) {
		switch (filterController.type) {
			case PSGraphTypeTotal:
				value = [numberFormatter stringFromNumber:[graphTotal objectAtIndex:elementIndex]];
				break;
			case PSGraphTypeDownloads:
				value = [numberFormatter stringFromNumber:[graphDownloads objectAtIndex:elementIndex]];
				break;
            case PSGraphTypeSales:
				value = [numberFormatter stringFromNumber:[graphSales objectAtIndex:elementIndex]];
				break;
            case PSGraphTypeUpdates:
				value = [numberFormatter stringFromNumber:[graphUpdates objectAtIndex:elementIndex]];
				break;
			case PSGraphTypeRevenue:
				value = [formatter stringFromNumber:[graphRevenue objectAtIndex:elementIndex]];
				break;			
			default:
				value = [numberFormatter stringFromNumber:[graphDownloads objectAtIndex:elementIndex]];
				break;
		}
	}
	
	return [NSString stringWithFormat:@"%@\n%@", [series objectAtIndex:elementIndex], value];
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
	[detailView removeFromSuperview];
	
	if ([changeViewButton selectedSegment] == 0) {
		[graphView setFrame:[contentView bounds]];
		[contentView addSubview:graphView];
        
        printableView = graphView;
	} else {
		[detailView setFrame:[contentView bounds]];
		[contentView addSubview:detailView];
        
        printableView = detailsController.view;
	}
    
    [PSSettings setFilterValue:[NSNumber numberWithInt:changeViewButton.selectedSegment] forKey:@"Dashboard View Index"];
}

@end
