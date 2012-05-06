//
//  PSMapController.h
//  Prismo
//
//  Created by Sergey Lenkov on 01.10.11.
//  Copyright 2011 Sergey Lenkov. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <Yuba/Yuba.h>
#import "PSCountrySale.h"
#import "PSDataController.h"
#import "PSMapDetailsController.h"
#import "PSMapFilterController.h"

@interface PSMapController : PSDataController <PSFilterControllerDelegate> {
	IBOutlet YBMapView *mapView;
	IBOutlet NSView *graphView;
	IBOutlet NSView *detailView;
	IBOutlet NSView *contentView;
	IBOutlet NSSegmentedControl *changeViewButton;
	IBOutlet PSMapDetailsController *detailController;
	NSMutableDictionary *values;
    NSNumberFormatter *numberFormatter;
    NSNumberFormatter *moneyFormatter;
    PSMapFilterController *filterController;
}

- (IBAction)viewChanged:(id)sender;

@end
