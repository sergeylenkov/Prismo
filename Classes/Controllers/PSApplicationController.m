//
//  PSApplicationController.m
//  Prismo
//
//  Created by Sergey Lenkov on 01.10.11.
//  Copyright 2011 Sergey Lenkov. All rights reserved.
//

#import "PSApplicationController.h"

@implementation PSApplicationController

@synthesize application;

- (void)dealloc {
	[mapValues release];
	[moneyFormatter release];
	[numberFormatter release];
    [dateFormatter release];
	[application release];
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
	moneyFormatter = [[NSNumberFormatter alloc] init];
	
	[moneyFormatter setFormatterBehavior:NSNumberFormatterBehavior10_4];
	[moneyFormatter setNumberStyle:NSNumberFormatterCurrencyStyle];
	[moneyFormatter setPositiveFormat:@"#,##0.00"];
	
	numberFormatter = [[NSNumberFormatter alloc] init];
	
	[numberFormatter setFormatterBehavior:NSNumberFormatterBehavior10_4];
	[numberFormatter setNumberStyle:NSNumberFormatterDecimalStyle];	
	
	dateFormatter = [[NSDateFormatter alloc] init];
	[dateFormatter setDateStyle:NSDateFormatterLongStyle];
	
	mapValues = [[NSMutableDictionary alloc] init];
	
	series = [[NSMutableArray alloc] init];
    graphTotal = [[NSMutableArray alloc] init];
	graphDownloads = [[NSMutableArray alloc] init];
	graphSales = [[NSMutableArray alloc] init];
	graphUpdates = [[NSMutableArray alloc] init];
	graphRefunds = [[NSMutableArray alloc] init];
	graphRevenue = [[NSMutableArray alloc] init];
	   
    mapGraphView.backgroundColor = [NSColor colorWithDeviceRed:255.0/255.0 green:255.0/255.0 blue:255.0/255.0 alpha:1.0];
    mapGraphView.maxColor = [NSColor colorWithDeviceRed:22.0/255.0 green:102.0/255.0 blue:150.0/255.0 alpha:1.0];
	mapGraphView.zeroColor = [NSColor colorWithDeviceRed:239.0/255.0 green:239.0/255.0 blue:239.0/255.0 alpha:1.0];
	mapGraphView.highlightColor = [NSColor colorWithDeviceRed:251.0/255.0 green:216.0/255.0 blue:67.0/255.0 alpha:1.0];
	mapGraphView.showMarker = YES;
	mapGraphView.showMarkerForZeroValue = YES;
    mapGraphView.formatter = numberFormatter;
    
    mapGraphView.marker.backgroundColor = [NSColor colorWithDeviceRed:0.0/255.0 green:0.0/255.0 blue:0.0/255.0 alpha:0.8];
	mapGraphView.marker.borderColor = [NSColor colorWithDeviceRed:0.0/255.0 green:0.0/255.0 blue:0.0/255.0 alpha:0.8];
	mapGraphView.marker.textColor = [NSColor whiteColor];
	mapGraphView.marker.type = YBMarkerTypeRectWithArrow;
	mapGraphView.marker.shadow = YES;
		    
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
	revenueGraphView.formatter = moneyFormatter;
	revenueGraphView.drawInfo = YES;
    revenueGraphView.fillGraph = YES;
    revenueGraphView.useMinValue = YES;
    revenueGraphView.minValue = 0.0;

    
    filterController = [[PSApplicationFilterController alloc] initWithWindowNibName:@"ApplicationFilterWindow"];
    filterController.delegate = self;
    
    popoverController = [[SFBPopoverWindowController alloc] initWithWindow:filterController.window];
    
    [super awakeFromNib];
}

- (void)initialization {
    filterController.application = application;
    [filterController initialization];

	if ([PSSettings filterValueForKey:[NSString stringWithFormat:@"%d View Index", application.identifier]] == nil) {
		[changeViewButton setSelectedSegment:0];
	} else {
		NSInteger index = [[PSSettings filterValueForKey:[NSString stringWithFormat:@"%d View Index", application.identifier]] intValue];
		
		if (index < [changeViewButton segmentCount]) {
			[changeViewButton setSelectedSegment:index];
		} else {
			[changeViewButton setSelectedSegment:0];
		}		
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
        [allSales addObject:[data saleForDate:date application:application]];
    }

	if (filterController.groupBy == PSGraphGroupByDay) {
		for (PSSale *sale in allSales) {
            if ([sale.date year] == [[NSDate date] year]) {
                sale.description = [PSUtilites localizedShortDateWithFullMonth:sale.date];
            } else {
                sale.description = [PSUtilites localizedMediumDate:sale.date];
            }
            
            sale.isDetail = NO;

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
                    newSale.isDetail = NO;
                    
                    [newSale.details reverse];
                    
                    if (filterController.groupBy == PSGraphGroupByWeek) {
                        if ([startDate year] == [[NSDate date] year] && [endDate year] == [[NSDate date] year]) {
                            if ([startDate month] == [endDate month]) {
                                newSale.description = [NSString stringWithFormat:@"%d - %@", [startDate day], [PSUtilites localizedShortPeriodDateWithFullMonth:endDate]];
                            } else {
                                newSale.description = [NSString stringWithFormat:@"%@ - %@", [PSUtilites localizedShortDateWithFullMonth:startDate], [PSUtilites localizedShortDateWithFullMonth:endDate]];
                            }
                        } else {
                            if ([startDate month] == [endDate month]) {
                                newSale.description = [NSString stringWithFormat:@"%d - %@", [startDate day], [PSUtilites localizedMediumPeriodDateWithFullMonth:endDate]];
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
                newSale.isDetail = NO;
                
                [newSale.details reverse];
                
                if (filterController.groupBy == PSGraphGroupByWeek) {
                    if ([startDate year] == [[NSDate date] year] && [endDate year] == [[NSDate date] year]) {
                        if ([startDate month] == [endDate month]) {
                            newSale.description = [NSString stringWithFormat:@"%d - %@", [startDate day], [PSUtilites localizedShortDateWithFullMonth:endDate]];
                        } else {
                            newSale.description = [NSString stringWithFormat:@"%@ - %@", [PSUtilites localizedShortDateWithFullMonth:startDate], [PSUtilites localizedShortDateWithFullMonth:endDate]];
                        }
                    } else {
                        if ([startDate month] == [endDate month]) {
                            newSale.description = [NSString stringWithFormat:@"%d - %@", [startDate day], [PSUtilites localizedMediumDateWithFullMonth:endDate]];
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

	[mapValues removeAllObjects];
	
    NSArray *mapSales = [data salesByCountriesFromDate:filterController.fromDate toDate:filterController.toDate application:application];
    
    for (PSCountrySale *sale in mapSales) {
        switch (filterController.mapType) {
            case PSGraphTypeTotal:
                [mapValues setObject:sale.total forKey:sale.code];
                break;
            case PSGraphTypeDownloads:
                [mapValues setObject:sale.downloads forKey:sale.code];
                break;
            case PSGraphTypeSales:
                [mapValues setObject:sale.sales forKey:sale.code]; 
                break;                
            case PSGraphTypeUpdates:
                [mapValues setObject:sale.updates forKey:sale.code];
                break;                
            case PSGraphTypeRevenue:
                [mapValues setObject:sale.revenue forKey:sale.code];
                break;
            default:
                [mapValues setObject:sale.total forKey:sale.code];
                break;
        }
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
	revenueGraphView.info = [NSString stringWithFormat:@"%@%@ Revenue", data.currencySymbol, [moneyFormatter stringFromNumber:[NSNumber numberWithFloat:totalRevenue]]];
    
    NSDate *minDate = [data minSaleDateForApplication:application];
    NSDate *maxDate = [data maxSaleDateForApplication:application];
    
    [startDateField setTitleWithMnemonic:[PSUtilites localizedMediumDateWithFullMonth:minDate]];
	[endDateField setTitleWithMnemonic:[PSUtilites localizedMediumDateWithFullMonth:maxDate]];
    
    int totalDays = [minDate daysCountBetweenDate:maxDate] + 1;
	
    [nameField setTitleWithMnemonic:application.name];
	[appleIDField setTitleWithMnemonic:[NSString stringWithFormat:@"%d", application.identifier]];
    
    [daysField setTitleWithMnemonic:[NSString stringWithFormat:@"%d", totalDays]];
    
    PSSale *totalSale = [data totalSaleForApplication:application];
    
    [totalField setTitleWithMnemonic:[numberFormatter stringFromNumber:totalSale.total]];
    [downloadsField setTitleWithMnemonic:[numberFormatter stringFromNumber:totalSale.downloads]];
    [salesField setTitleWithMnemonic:[numberFormatter stringFromNumber:totalSale.sales]];
    [updatesField setTitleWithMnemonic:[numberFormatter stringFromNumber:totalSale.updates]];
    [refundsField setTitleWithMnemonic:[numberFormatter stringFromNumber:totalSale.refunds]];
    [revenueField setTitleWithMnemonic:[NSString stringWithFormat:@"%@%@", data.currencySymbol, [moneyFormatter stringFromNumber:totalSale.revenue]]];
    
    [avgTotalField setTitleWithMnemonic:[NSString stringWithFormat:@"%.1f", [totalSale.total floatValue] / totalDays]];
    [avgDownloadsField setTitleWithMnemonic:[NSString stringWithFormat:@"%.1f", [totalSale.downloads floatValue] / totalDays]];
    [avgSalesField setTitleWithMnemonic:[NSString stringWithFormat:@"%.1f", [totalSale.sales floatValue] / totalDays]];
    [avgRevenueField setTitleWithMnemonic:[NSString stringWithFormat:@"%@%@", data.currencySymbol, [moneyFormatter stringFromNumber:[NSNumber numberWithFloat:[totalSale.revenue floatValue] / totalDays]]]];
    
	detailsController.sales = sales;
	
	if ([series count] < 70) {
		mainGraphView.drawBullets = YES;
		mainGraphView.lineWidth = 2.0;
	} else {
		mainGraphView.drawBullets = NO;
		mainGraphView.lineWidth = 1.4;
	}

	[sales release];
	[allSales release];
	
	[self draw];
}

- (void)draw {
	[mapGraphView draw];
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
    if (changeViewButton.selectedSegment == 2) {
        PSData *data = [PSData sharedData];
        
        NSString *csv = @"\"NAME\",\"CODE\",\"TOTAL\",\"DOWNLOADS\",\"REFUNDS\",\"UPDATES\",\"SALES\",\"REVENUE\"\n";
        
        NSArray *mapSales = [data salesByCountriesFromDate:filterController.fromDate toDate:filterController.toDate application:application];
        
        for (PSCountrySale *sale in mapSales) {
            NSString *line = [NSString stringWithFormat:@"\"%@\",\"%@\",\"%d\",\"%d\",\"%d\",\"%d\",\"%d\",\"%@\"\n", [data countryNameByCode:sale.code], sale.code, [sale.total intValue], [sale.downloads intValue], [sale.refunds intValue], [sale.updates intValue], [sale.sales intValue], [numberFormatter stringFromNumber:sale.revenue]];
            csv = [csv stringByAppendingString:line];
        }

        [csv writeToURL:fileName atomically:YES encoding:NSUTF8StringEncoding error:nil];
    } else {
        NSString *csv = @"\"DATE\",\"TOTAL\",\"DOWNLOADS\",\"REFUNDS\",\"UPDATES\",\"SALES\",\"REVENUE\"\n";
	
        for (PSSale *sale in detailsController.sales) {
            NSString *line = [NSString stringWithFormat:@"\"%@\",\"%d\",\"%d\",\"%d\",\"%d\",\"%d\",\"%@\"\n", [sale.date dbDateFormat], [sale.total intValue], [sale.downloads intValue], [sale.refunds intValue], [sale.updates intValue], [sale.sales intValue], [numberFormatter stringFromNumber:sale.revenue]];
            csv = [csv stringByAppendingString:line];
        }
	
        [csv writeToURL:fileName atomically:YES encoding:NSUTF8StringEncoding error:nil];
    }
}

#pragma mark -
#pragma mark YBMapView Protocol
#pragma mark -

- (NSNumber *)mapView:(YBMapView *)map valueForCountry:(NSString *)code {
	if ([mapValues objectForKey:code] == nil) {
		return [NSNumber numberWithInt:0];
	}
	
	return [mapValues objectForKey:code];
}

- (NSString *)mapView:(YBMapView *)map markerTitleForCountry:(NSString *)code {
	NSNumber *value = [NSNumber numberWithInt:0];
	NSString *country = [[PSData sharedData] countryNameByCode:code];
	
	if ([mapValues objectForKey:code] != nil) {
		value = [mapValues objectForKey:code];
	}	
	
    if (filterController.mapType == PSGraphTypeRevenue) {
        return [NSString stringWithFormat:@"%@\n%@", country, [moneyFormatter stringFromNumber:value]];
    }
   
    return [NSString stringWithFormat:@"%@\n%@", country, [numberFormatter stringFromNumber:value]];
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
		switch (filterController.graphType) {
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
				mainGraphView.formatter = moneyFormatter;
				return graphRevenue;
				break;			
			default:
				mainGraphView.formatter = numberFormatter;
				return graphDownloads;
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
		switch (filterController.graphType) {
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
				value = [moneyFormatter stringFromNumber:[graphRevenue objectAtIndex:elementIndex]];
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
	[mapView removeFromSuperview];
	[detailsView removeFromSuperview];
	[infoView removeFromSuperview];
		
	if (changeViewButton.selectedSegment == 0) {
		[infoView setFrame:[contentView bounds]];
		[contentView addSubview:infoView];
        
        printableView = infoView;
	} 
	
	if (changeViewButton.selectedSegment == 1) {
		[graphView setFrame:[contentView bounds]];
		[contentView addSubview:graphView];
        
        printableView = graphView;
	} 
	
	if (changeViewButton.selectedSegment == 2) {
		[mapView setFrame:[contentView bounds]];
		[contentView addSubview:mapView];
        
        printableView = mapView;
	}
	
	if (changeViewButton.selectedSegment == 3) {
		[detailsView setFrame:[contentView bounds]];
		[contentView addSubview:detailsView];
        
        printableView = detailsController.view;
	}
		
	[PSSettings setFilterValue:[NSNumber numberWithInt:changeViewButton.selectedSegment] forKey:[NSString stringWithFormat:@"%d View Index", application.identifier]];
}

@end
