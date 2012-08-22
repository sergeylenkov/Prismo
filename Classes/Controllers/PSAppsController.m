//
//  PSAppsController.m
//  Prismo
//
//  Created by Sergey Lenkov on 11.02.12.
//  Copyright (c) 2012 Sergey Lenkov. All rights reserved.
//

#import "PSAppsController.h"

@implementation PSAppsController

- (void)initialization {
    defaults = [NSUserDefaults standardUserDefaults];
    selection = [[NSMutableDictionary alloc] init];
    
    if ([defaults objectForKey:@"Selected Apps"] != nil) {
        [selection setDictionary:[defaults objectForKey:@"Selected Apps"]];
    }
}

- (void)dealloc {
    [super dealloc];
    [selection release];
}

- (void)refresh {    
    [view reloadData];
}

- (int)numberOfRowsInTableView:(NSTableView *)tableView {
    PSData *data = [PSData sharedData];
	return [data.applications count];
}

- (id)tableView:(NSTableView *)tableView objectValueForTableColumn:(NSTableColumn *)tableColumn row:(int)row {
    PSData *data = [PSData sharedData];
    PSApplication *application = [data.applications objectAtIndex:row];
    
	if ([[tableColumn identifier] isEqualToString:@"name"]) {
        BOOL selected = [[selection objectForKey:[NSString stringWithFormat:@"%ld", application.identifier]] boolValue];
        
		NSButtonCell *cell = [tableColumn dataCell];
        
        [cell setTitle:application.name];
		[cell setState:selected];
        
		return cell;
	}
    
	return nil;
}

- (void)tableView:(NSTableView *)tableView setObjectValue:(id)object forTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row {
	if ([[tableColumn identifier] isEqualToString:@"name"]) {
        PSData *data = [PSData sharedData];
        PSApplication *application = [data.applications objectAtIndex:row];
        
		NSNumber *value = [NSNumber numberWithBool:[object boolValue]];
        
        if ([value boolValue]) {
            [selection setObject:value forKey:[NSString stringWithFormat:@"%ld", application.identifier]];
        } else {
            [selection removeObjectForKey:[NSString stringWithFormat:@"%ld", application.identifier]];
        }
        
        [defaults setObject:selection forKey:@"Selected Apps"];
        [defaults synchronize];
        
        [view reloadData];
	}
}

@end
