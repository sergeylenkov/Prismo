//
//  PSStoresController.m
//  Prismo
//
//  Created by Sergey Lenkov on 16.03.12.
//  Copyright (c) 2012 Sergey Lenkov. All rights reserved.
//

#import "PSStoresController.h"

@implementation PSStoresController

- (void)initialization {
    defaults = [NSUserDefaults standardUserDefaults];
    selection = [[NSMutableDictionary alloc] init];
    
    if ([defaults objectForKey:@"Selected Stores"] != nil) {
        [selection setDictionary:[defaults objectForKey:@"Selected Stores"]];
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
	return [data.stores count];
}

- (id)tableView:(NSTableView *)tableView objectValueForTableColumn:(NSTableColumn *)tableColumn row:(int)row {
    PSData *data = [PSData sharedData];
    PSStore *store = [data.stores objectAtIndex:row];
    
	if ([[tableColumn identifier] isEqualToString:@"name"]) {
        BOOL selected = [[selection objectForKey:[NSString stringWithFormat:@"%d", store.identifier]] boolValue];
        
		NSButtonCell *cell = [tableColumn dataCell];
        
        [cell setTitle:store.name];
		[cell setState:selected];
        
		return cell;
	}
    
	return nil;
}

- (void)tableView:(NSTableView *)tableView setObjectValue:(id)object forTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row {
	if ([[tableColumn identifier] isEqualToString:@"name"]) {
        PSData *data = [PSData sharedData];
        PSStore *store = [data.stores objectAtIndex:row];
        
		NSNumber *value = [NSNumber numberWithBool:[object boolValue]];
        
        if ([value boolValue]) {
            [selection setObject:value forKey:[NSString stringWithFormat:@"%d", store.identifier]];
        } else {
            [selection removeObjectForKey:[NSString stringWithFormat:@"%d", store.identifier]];
        }
        
        [defaults setObject:selection forKey:@"Selected Stores"];
        [defaults synchronize];
        
        [view reloadData];
	}
}

@end
