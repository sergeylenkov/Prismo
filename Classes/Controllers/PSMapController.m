//
//  PSMapController.m
//  Prismo
//
//  Created by Sergey Lenkov on 01.10.11.
//  Copyright 2011 Sergey Lenkov. All rights reserved.
//

#import "PSMapController.h"

@implementation PSMapController

- (void)dealloc {
	[values release];
    [numberFormatter release];
    [moneyFormatter release];
    [filterController release];
	[super dealloc];
}

- (void)awakeFromNib {    
	values = [[NSMutableDictionary alloc] init];
	
    numberFormatter = [[NSNumberFormatter alloc] init];
	
	[numberFormatter setFormatterBehavior:NSNumberFormatterBehavior10_4];
	[numberFormatter setNumberStyle:NSNumberFormatterDecimalStyle];
    
    moneyFormatter = [[NSNumberFormatter alloc] init];
	
	[moneyFormatter setFormatterBehavior:NSNumberFormatterBehavior10_4];
	[moneyFormatter setNumberStyle:NSNumberFormatterCurrencyStyle];
	[moneyFormatter setPositiveFormat:@"#,##0.00"];
    
    mapView.backgroundColor = [NSColor colorWithDeviceRed:255.0/255.0 green:255.0/255.0 blue:255.0/255.0 alpha:1.0];
    mapView.maxColor = [NSColor colorWithDeviceRed:22.0/255.0 green:102.0/255.0 blue:150.0/255.0 alpha:1.0];
	mapView.zeroColor = [NSColor colorWithDeviceRed:239.0/255.0 green:239.0/255.0 blue:239.0/255.0 alpha:1.0];
	mapView.highlightColor = [NSColor colorWithDeviceRed:251.0/255.0 green:216.0/255.0 blue:67.0/255.0 alpha:1.0];
	mapView.showMarker = YES;
	mapView.showMarkerForZeroValue = YES;
    mapView.formatter = numberFormatter;
    
    mapView.marker.backgroundColor = [NSColor colorWithDeviceRed:0.0/255.0 green:0.0/255.0 blue:0.0/255.0 alpha:0.8];
	mapView.marker.borderColor = [NSColor colorWithDeviceRed:0.0/255.0 green:0.0/255.0 blue:0.0/255.0 alpha:0.8];
	mapView.marker.textColor = [NSColor whiteColor];
	mapView.marker.type = YBMarkerTypeRectWithArrow;
	mapView.marker.shadow = YES;
    
    filterController = [[PSMapFilterController alloc] initWithWindowNibName:@"MapFilterWindow"];
    filterController.delegate = self;
    
    popoverController = [[SFBPopoverWindowController alloc] initWithWindow:filterController.window];
    
    [super awakeFromNib];
}

- (void)initialization {
    [filterController initialization];

	if ([PSSettings filterValueForKey:@"Map View Index"] == nil) {
		[changeViewButton setSelectedSegment:0];
	} else {
        NSInteger index = [[PSSettings filterValueForKey:@"Map View Index"] intValue];
		[changeViewButton setSelectedSegment:index];
	}
	
	[self viewChanged:self];
}

- (void)refresh {
	PSData *data = [PSData sharedData];

	[values removeAllObjects];

    NSArray *sales = [data salesByCountriesFromDate:filterController.fromDate toDate:filterController.toDate];
    
    for (PSCountrySale *sale in sales) {
        switch (filterController.type) {
            case PSGraphTypeTotal:
                [values setObject:sale.total forKey:sale.code];
                break;
            case PSGraphTypeDownloads:
                [values setObject:sale.downloads forKey:sale.code];
                break;
            case PSGraphTypeSales:
                [values setObject:sale.sales forKey:sale.code]; 
                break;                
            case PSGraphTypeUpdates:
                [values setObject:sale.updates forKey:sale.code];
                break;                
            case PSGraphTypeRevenue:
                [values setObject:sale.revenue forKey:sale.code];
                break;
            default:
                [values setObject:sale.total forKey:sale.code];
                break;
        }
    }

	detailController.sales = [NSMutableArray arrayWithArray:sales];

	[mapView draw];
}

- (BOOL)isCanPrint {
    return YES;
}

- (BOOL)isCanExport {
    return YES;
}

- (void)exportToFile:(NSURL *)fileName {
	NSString *csv = @"\"NAME\",\"CODE\",\"TOTAL\",\"DOWNLOADS\",\"REFUNDS\",\"UPDATES\",\"SALES\",\"REVENUE\"\n";
	
	for (PSCountrySale *sale in detailController.sales) {
		NSString *line = [NSString stringWithFormat:@"\"%@\",\"%@\",\"%d\",\"%d\",\"%d\",\"%d\",\"%d\",\"%@\"\n", [[PSData sharedData] countryNameByCode:sale.code], sale.code, [sale.total intValue], [sale.downloads intValue], [sale.refunds intValue], [sale.updates intValue], [sale.sales intValue], [numberFormatter stringFromNumber:sale.revenue]];
		csv = [csv stringByAppendingString:line];
	}
	
	[csv writeToURL:fileName atomically:YES encoding:NSUTF8StringEncoding error:nil];
}

#pragma mark -
#pragma mark YBMapView Protocol
#pragma mark -

- (NSNumber *)mapView:(YBMapView *)map valueForCountry:(NSString *)code {
	if ([values objectForKey:code] == nil) {
		return [NSNumber numberWithInt:0];
	}
	
	return [values objectForKey:code];
}

- (NSString *)mapView:(YBMapView *)map markerTitleForCountry:(NSString *)code {
	NSNumber *value = [NSNumber numberWithInt:0];
	NSString *country = [[PSData sharedData] countryNameByCode:code];
	
	if ([values objectForKey:code] != nil) {        
		value = [values objectForKey:code];
	}
	
    if (filterController.type == PSGraphTypeRevenue) {
        return [NSString stringWithFormat:@"%@\n%@", country, [moneyFormatter stringFromNumber:value]];
    }
    
    return [NSString stringWithFormat:@"%@\n%@", country, [numberFormatter stringFromNumber:value]];
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
        
        printableView = detailController.view;
	}
	
	[PSSettings setFilterValue:[NSNumber numberWithInt:changeViewButton.selectedSegment] forKey:@"Map View Index"];
}

@end
