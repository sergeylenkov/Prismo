//
//  PSRanksController.m
//  Prismo
//
//  Created by Sergey Lenkov on 01.10.11.
//  Copyright 2011 Sergey Lenkov. All rights reserved.
//

#import "PSRanksController.h"

@implementation PSRanksController

@synthesize application;

- (void)dealloc {
	[application release];
	[formatter release];
    [series release];
    [graphs release];
    [filterController release];
	[super dealloc];
}

- (void)awakeFromNib {
	formatter = [[NSNumberFormatter alloc] init];
	
	[formatter setFormatterBehavior:NSNumberFormatterBehavior10_4];
	[formatter setNumberStyle:NSNumberFormatterNoStyle];
	
    series = [[NSMutableArray alloc] init];
    graphs = [[NSMutableArray alloc] init];
    
	mainGraphView.showMarker = YES;
	mainGraphView.lineWidth = 1.4;
	mainGraphView.drawBullets = NO;
    mainGraphView.highlightBullet = YES;
	mainGraphView.isRevert = YES;
    mainGraphView.useMinValue = YES;
    mainGraphView.minValue = 1;
    mainGraphView.formatter = formatter;
    
	mainGraphView.marker.backgroundColor = [NSColor colorWithDeviceRed:0.0/255.0 green:0.0/255.0 blue:0.0/255.0 alpha:0.8];
	mainGraphView.marker.borderColor = [NSColor colorWithDeviceRed:0.0/255.0 green:0.0/255.0 blue:0.0/255.0 alpha:0.8];
	mainGraphView.marker.textColor = [NSColor whiteColor];
	mainGraphView.marker.type = YBMarkerTypeRectWithArrow;
	mainGraphView.marker.shadow = YES;
    
    filterController = [[PSRanksFilterController alloc] initWithWindowNibName:@"RanksFilterWindow"];
    filterController.delegate = self;
    
    popoverController = [[SFBPopoverWindowController alloc] initWithWindow:filterController.window];
    
    [super awakeFromNib];
}

- (void)initialization {
    filterController.application = application;
    [filterController initialization];
    
    if (filterController.top == nil) {
        filterButton.enabled = NO;
    } else {
        filterButton.enabled = YES;
    }
    
    if ([PSSettings filterValueForKey:[NSString stringWithFormat:@"%d Ranks View Index", application.identifier]] == nil) {
        [changeViewButton setSelectedSegment:0];
    } else {
        NSInteger index = [[PSSettings filterValueForKey:[NSString stringWithFormat:@"%d Ranks View Index", application.identifier]] intValue];
        [changeViewButton setSelectedSegment:index];
    }
    
	[self viewChanged:self];
}

- (void)refresh {	
    if (filterController.top == nil) {
        return;
    }
    
	PSData *data = [PSData sharedData];
    
    [series removeAllObjects];
    [graphs removeAllObjects];

    NSArray *allRanks = [data ranksFromDate:filterController.fromDate toDate:filterController.toDate application:application top:filterController.top]; //[data.ranks filteredArrayUsingPredicate:predicate];
    
    for (PSRank *rank in allRanks) {
        [graphs addObject:[NSNumber numberWithInt:rank.place]];
        
        if ([rank.date year] == [[NSDate date] year]) {
            [series addObject:[PSUtilites localizedShortDateWithFullMonth:rank.date]];
        } else {
            [series addObject:[PSUtilites localizedMediumDateWithFullMonth:rank.date]];
        }
    }
    
    detailsController.ranks = allRanks;
    
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
}

- (BOOL)isCanPrint {
    return YES;
}

- (BOOL)isCanExport {
    return YES;
}

- (void)exportToFile:(NSURL *)fileName {
	NSString *csv = @"\"DATE\",\"RANK\",\"CHANGE\"\n";
	
	for (int i = 0; i < [detailsController.ranks count]; i++) {
		PSRank *rank = [detailsController.ranks objectAtIndex:i];
		
		int change;
		
		if (i == [detailsController.ranks count] - 1) {
			change = 0;
		} else {
			PSRank *previous = [detailsController.ranks objectAtIndex:i + 1];
			change = previous.place - rank.place;
		}
		
		NSString *line = [NSString stringWithFormat:@"\"%@\",\"%d\",\"%d\"\n", [rank.date dbDateFormat], rank.place, change];
		csv = [csv stringByAppendingString:line];
	}
	
	[csv writeToURL:fileName atomically:YES encoding:NSUTF8StringEncoding error:nil];
}

#pragma mark -
#pragma mark YBGraphViewDelegate
#pragma mark -

- (NSInteger)numberOfGraphsInGraphView:(YBGraphView *)graph {
	return 1;
}

- (NSArray *)seriesForGraphView:(YBGraphView *)graph {
	return series;
}

- (NSArray *)graphView:(YBGraphView *)graph valuesForGraph:(NSInteger)index {
	return graphs;
}

- (NSString *)graphView:(YBGraphView *)graph markerTitleForGraph:(NSInteger)graphIndex forElement:(NSInteger)elementIndex {
	return [NSString stringWithFormat:@"%@\n%@", [series objectAtIndex:elementIndex], [formatter stringFromNumber:[graphs objectAtIndex:elementIndex]]];
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
	[noDataView removeFromSuperview];
	
    if (filterController.top == nil) {
        [noDataView setFrame:[contentView bounds]];
        [contentView addSubview:noDataView];
        
        return;
    }
    
	if (changeViewButton.selectedSegment == 0) {
        [graphView setFrame:[contentView bounds]];
        [contentView addSubview:graphView];
        
        printableView = graphView;
	}
	
	if (changeViewButton.selectedSegment == 1) {
        [detailView setFrame:[contentView bounds]];
        [contentView addSubview:detailView];
        
        printableView = detailsController.view;
	}
	
	[PSSettings setFilterValue:[NSNumber numberWithInt:changeViewButton.selectedSegment] forKey:[NSString stringWithFormat:@"%d Ranks View Index", application.identifier]];
}

@end
