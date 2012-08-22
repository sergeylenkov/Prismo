//
//  PSCompareController.m
//  Prismo
//
//  Created by Sergey Lenkov on 01.10.11.
//  Copyright 2011 Sergey Lenkov. All rights reserved.
//

#import "PSCompareController.h"

@implementation PSCompareController

- (void)dealloc {
	[formatter release];
	[numberFormatter release];
    [series release];
    [graphs release];
    [charts release];
    [applications release];
    [filterController release];
	[super dealloc];
}

- (void)awakeFromNib {
	series = [[NSMutableArray alloc] init];
    graphs = [[NSMutableArray alloc] init];
    charts = [[NSMutableArray alloc] init];
    applications = [[NSMutableArray alloc] init];
    
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
    mainGraphView.drawLegend = YES;
    mainGraphView.showMarkerNearPoint = YES;
    
    mainGraphView.marker.backgroundColor = [NSColor colorWithDeviceRed:0.0/255.0 green:0.0/255.0 blue:0.0/255.0 alpha:0.8];
	mainGraphView.marker.borderColor = [NSColor colorWithDeviceRed:0.0/255.0 green:0.0/255.0 blue:0.0/255.0 alpha:0.8];
	mainGraphView.marker.textColor = [NSColor whiteColor];
	mainGraphView.marker.type = YBMarkerTypeRectWithArrow;
	mainGraphView.marker.shadow = YES;
    
    mainChartView.delegate = self;
    mainChartView.dataSource = self;
    mainChartView.drawLegend = YES;
    mainChartView.showMarker = YES;
    
    mainChartView.marker.backgroundColor = [NSColor colorWithDeviceRed:0.0/255.0 green:0.0/255.0 blue:0.0/255.0 alpha:0.8];
	mainChartView.marker.borderColor = [NSColor colorWithDeviceRed:0.0/255.0 green:0.0/255.0 blue:0.0/255.0 alpha:0.8];
	mainChartView.marker.textColor = [NSColor whiteColor];
	mainChartView.marker.type = YBMarkerTypeRectWithArrow;
	mainChartView.marker.shadow = YES;
    
    filterController = [[PSCompareFilterController alloc] initWithWindowNibName:@"CompareFilterWindow"];
    filterController.delegate = self;
    
    popoverController = [[SFBPopoverWindowController alloc] initWithWindow:filterController.window];
    
    [super awakeFromNib];
}

- (void)initialization {
    [filterController initialization];
    
	if ([PSSettings filterValueForKey:@"Compare View Index"] == nil) {
		[changeViewButton setSelectedSegment:0];
	} else {
        NSInteger index = [[PSSettings filterValueForKey:@"Compare View Index"] intValue];
		[changeViewButton setSelectedSegment:index];
	}
    
	[self viewChanged:self];
}

- (void)refresh {
    PSData *data = [PSData sharedData];
    
    [series removeAllObjects];
    [graphs removeAllObjects];
    [charts removeAllObjects];
    [applications removeAllObjects];

    for (PSCompare *compare in filterController.applications) {
        NSString *key = [NSString stringWithFormat:@"%ld_%ld", compare.application.identifier, compare.type];

        if ([filterController.selection objectForKey:key]) {
            [applications addObject:compare];
            
            NSMutableArray *values = [[NSMutableArray alloc] init];

            PSSale *sale = [data totalSaleFromDate:filterController.fromDate toDate:filterController.toDate application:compare.application];
            float chartValue = 0;

            switch (compare.type) {
                case 0:
                    chartValue = [sale.total intValue];
                    break;
                case 1:
                    chartValue = [sale.downloads intValue];
                    break;
                case 2:
                    chartValue = [sale.sales intValue];
                    break;
                case 3:
                    chartValue = [sale.updates intValue];
                    break;
                case 4:
                    chartValue = [sale.revenue floatValue];
                    break;
                default:
                    chartValue = [sale.total intValue];
                    break;
            }
            
            [series removeAllObjects];

            NSMutableArray *allSales = [[NSMutableArray alloc] init];
            int days = [filterController.fromDate daysCountBetweenDate:filterController.toDate];

            for (int i = 0; i <= days; i++) {
                NSDate *date = [filterController.fromDate dateByAddingDays:i];
                [allSales addObject:[data saleForDate:date application:compare.application]];
            }

            if (filterController.groupBy == PSGraphGroupByDay) {
                for (PSSale *sale in allSales) {
                    if ([sale.date year] == [[NSDate date] year]) {
                        [series addObject:[PSUtilites localizedShortDateWithFullMonth:sale.date]];
                    } else {
                        [series addObject:[PSUtilites localizedMediumDate:sale.date]];
                    }
                    
                    switch (compare.type) {
                        case 0:
                            [values addObject:sale.total];
                            break;
                        case 1:
                            [values addObject:sale.downloads];
                            break;
                        case 2:
                            [values addObject:sale.sales];
                            break;
                        case 3:
                            [values addObject:sale.updates];
                            break;
                        case 4:
                            [values addObject:sale.revenue];
                            break;
                        default:
                            [values addObject:sale.total];
                            break;
                    }
                }
            }

            if (filterController.groupBy == PSGraphGroupByWeek || filterController.groupBy == PSGraphGroupByMonth) {
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
                    
                    totalSum = totalSum + [sale.total intValue];
                    downloadsSum = downloadsSum + [sale.downloads intValue];
                    salesSum = salesSum + [sale.sales intValue];
                    updatesSum = updatesSum + [sale.updates intValue];
                    refundsSum = refundsSum + [sale.refunds intValue];
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
                            switch (compare.type) {
                                case 0:
                                    [values addObject:[NSNumber numberWithInt:totalSum]];
                                    break;
                                case 1:
                                    [values addObject:[NSNumber numberWithInt:downloadsSum]];
                                    break;
                                case 2:
                                    [values addObject:[NSNumber numberWithInt:salesSum]];
                                    break;
                                case 3:
                                    [values addObject:[NSNumber numberWithInt:updatesSum]];
                                    break;
                                case 4:
                                    [values addObject:[NSNumber numberWithFloat:revenueSum]];
                                    break;
                                default:
                                    [values addObject:[NSNumber numberWithInt:totalSum]];
                                    break;
                            }
                            
                            if (filterController.groupBy == PSGraphGroupByWeek) {
                                if ([startDate year] == [[NSDate date] year] && [endDate year] == [[NSDate date] year]) {
                                    if ([startDate month] == [endDate month]) {
                                        [series addObject:[NSString stringWithFormat:@"%ld - %@", [startDate day], [PSUtilites localizedShortPeriodDateWithFullMonth:endDate]]];
                                    } else {
                                        [series addObject:[NSString stringWithFormat:@"%@ - %@", [PSUtilites localizedShortDateWithFullMonth:startDate], [PSUtilites localizedShortDateWithFullMonth:endDate]]];
                                    }
                                } else {
                                    if ([startDate month] == [endDate month]) {
                                        [series addObject:[NSString stringWithFormat:@"%ld - %@", [startDate day], [PSUtilites localizedMediumPeriodDateWithFullMonth:endDate]]];
                                    } else {
                                        [series addObject:[NSString stringWithFormat:@"%@ - %@", [PSUtilites localizedShortDateWithFullMonth:startDate], [PSUtilites localizedMediumDateWithFullMonth:endDate]]];
                                    }
                                }
                            } else {
                                [series addObject:[startDate monthName]];
                            }
                            
                            totalSum = 0;
                            downloadsSum = 0;
                            salesSum = 0;
                            updatesSum = 0;
                            refundsSum = 0;
                            revenueSum = 0.0;
                            
                            component = nextComponent;
                            startDate = next.date; 
                        }
                    } else {
                        switch (compare.type) {
                            case 0:
                                [values addObject:[NSNumber numberWithInt:totalSum]];
                                break;
                            case 1:
                                [values addObject:[NSNumber numberWithInt:downloadsSum]];
                                break;
                            case 2:
                                [values addObject:[NSNumber numberWithInt:salesSum]];
                                break;
                            case 3:
                                [values addObject:[NSNumber numberWithInt:updatesSum]];
                                break;
                            case 4:
                                [values addObject:[NSNumber numberWithFloat:revenueSum]];
                                break;
                            default:
                                [values addObject:[NSNumber numberWithInt:totalSum]];
                                break;
                        }
                        
                        if (filterController.groupBy == PSGraphGroupByWeek) {
                            if ([startDate year] == [[NSDate date] year] && [endDate year] == [[NSDate date] year]) {
                                if ([startDate month] == [endDate month]) {
                                    [series addObject:[NSString stringWithFormat:@"%ld - %@", [startDate day], [PSUtilites localizedShortPeriodDateWithFullMonth:endDate]]];
                                } else {
                                    [series addObject:[NSString stringWithFormat:@"%@ - %@", [PSUtilites localizedShortDateWithFullMonth:startDate], [PSUtilites localizedShortDateWithFullMonth:endDate]]];
                                }
                            } else {
                                if ([startDate month] == [endDate month]) {
                                    [series addObject:[NSString stringWithFormat:@"%ld - %@", [startDate day], [PSUtilites localizedMediumPeriodDateWithFullMonth:endDate]]];
                                } else {
                                    [series addObject:[NSString stringWithFormat:@"%@ - %@", [PSUtilites localizedShortDateWithFullMonth:startDate], [PSUtilites localizedMediumDateWithFullMonth:endDate]]];
                                }
                            }
                        } else {
                            [series addObject:[startDate monthName]];
                        }
                    }
                }
            }
            
            [graphs addObject:values];
            [values release];
            [allSales release];
            
            [charts addObject:[NSNumber numberWithFloat:chartValue]];
        }
    }

	if ([series count] < 70) {
		mainGraphView.drawBullets = YES;
		mainGraphView.lineWidth = 1.8;
	} else {
		mainGraphView.drawBullets = NO;
		mainGraphView.lineWidth = 1.4;
	}

	[self draw];
}

- (void)draw {	
	[mainGraphView draw];
    [mainChartView draw];
}

- (BOOL)isCanPrint {
    return YES;
}

- (BOOL)isCanExport {
    return YES;
}

- (void)exportToFile:(NSURL *)fileName {
    NSString *csv = @"\"DATE\"";
    
    for (PSCompare *compare in applications) {
        csv = [csv stringByAppendingFormat:@",\"%@\"", compare.name];
    }
    
    csv = [csv stringByAppendingString:@"\n"];
    
    for (int i = 0; i < [series count]; i++) {
        NSString *line = [NSString stringWithFormat:@"\"%@\"", [series objectAtIndex:i]];
        
        for (int n = 0; n < [applications count]; n++) {
            PSCompare *compare = [applications objectAtIndex:n];
            NSArray *values = [graphs objectAtIndex:n];
            
            switch (compare.type) {
                case 0:
                    line = [line stringByAppendingFormat:@",\"%d\"", [[values objectAtIndex:i] intValue]];
                    break;
                case 1:
                    line = [line stringByAppendingFormat:@",\"%d\"", [[values objectAtIndex:i] intValue]];
                    break;
                case 2:
                    line = [line stringByAppendingFormat:@",\"%d\"", [[values objectAtIndex:i] intValue]];
                    break;
                case 3:
                    line = [line stringByAppendingFormat:@",\"%d\"", [[values objectAtIndex:i] intValue]];
                    break;
                case 4:
                    line = [line stringByAppendingFormat:@",\"%@\"", [numberFormatter stringFromNumber:[values objectAtIndex:i]]];
                    break;
                default:
                    line = [line stringByAppendingFormat:@",\"%d\"", [[values objectAtIndex:i] intValue]];
                    break;
            }
        }
        
        line = [line stringByAppendingString:@"\n"];
        csv = [csv stringByAppendingString:line];
    }
    
    [csv writeToURL:fileName atomically:YES encoding:NSUTF8StringEncoding error:nil];
}

#pragma mark -
#pragma mark YBGraphView Protocol
#pragma mark -

- (NSInteger)numberOfGraphsInGraphView:(YBGraphView *)graph {
	return [graphs count];
}

- (NSArray *)seriesForGraphView:(YBGraphView *)graph {
	return series;
}

- (NSString *)graphView:(YBGraphView *)graph legendTitleForGraph:(NSInteger)index {
    PSCompare *compare = [applications objectAtIndex:index];
    return compare.name;
}

- (NSArray *)graphView:(YBGraphView *)graph valuesForGraph:(NSInteger)index {
    return [graphs objectAtIndex:index];
}

- (NSString *)graphView:(YBGraphView *)graph markerTitleForGraph:(NSInteger)graphIndex forElement:(NSInteger)elementIndex {
    PSCompare *compare = [applications objectAtIndex:graphIndex];
    NSArray *values = [graphs objectAtIndex:graphIndex];
    
	NSString *value = @"";
	
    switch (compare.type) {
        case 0:
            value = [numberFormatter stringFromNumber:[values objectAtIndex:elementIndex]];
            break;
        case 1:
            value = [numberFormatter stringFromNumber:[values objectAtIndex:elementIndex]];
            break;
        case 2:
            value = [numberFormatter stringFromNumber:[values objectAtIndex:elementIndex]];
            break;
        case 3:
            value = [numberFormatter stringFromNumber:[values objectAtIndex:elementIndex]];
            break;
        case 4:
            value = [formatter stringFromNumber:[values objectAtIndex:elementIndex]];
            break;			
        default:
            value = [numberFormatter stringFromNumber:[values objectAtIndex:elementIndex]];
            break;
    }
	
	return [NSString stringWithFormat:@"%@\n%@", [series objectAtIndex:elementIndex], value];
}

#pragma mark -
#pragma mark YBChartView Protocol
#pragma mark -

- (NSInteger)numberOfCharts {
    return [applications count];
}

- (NSNumber *)chartView:(YBChartView *)chart valueForChart:(NSInteger)index {
    return [charts objectAtIndex:index];
}

- (NSString *)chartView:(YBChartView *)chart titleForChart:(NSInteger)index {
    PSCompare *compare = [applications objectAtIndex:index];
    return compare.name;
}

- (NSString *)chartView:(YBChartView *)chart legendTitleForChart:(NSString *)title withValue:(NSNumber *)value andPercent:(NSNumber *)percent {
    NSString *result = [numberFormatter stringFromNumber:value];
    return [NSString stringWithFormat:@"%@ (%.2f%%)", result, [percent floatValue]];
}

- (NSString *)chartView:(YBChartView *)chart markerTitleForChart:(NSString *)title withValue:(NSNumber *)value andPercent:(NSNumber *)percent {
    NSString *result = [numberFormatter stringFromNumber:value];
    return [NSString stringWithFormat:@"%@\n%.2f%%", result, [percent floatValue]];
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
	[chartView removeFromSuperview];
    
	if ([changeViewButton selectedSegment] == 0) {
		[graphView setFrame:[contentView bounds]];
		[contentView addSubview:graphView];
        
        printableView = graphView;
	}
    
    if ([changeViewButton selectedSegment] == 1) {
		[chartView setFrame:[contentView bounds]];
		[contentView addSubview:chartView];
        
        printableView = chartView;
	}
    
    [PSSettings setFilterValue:[NSNumber numberWithInt:changeViewButton.selectedSegment] forKey:@"Compare View Index"];
}

@end
