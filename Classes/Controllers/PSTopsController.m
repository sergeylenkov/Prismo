//
//  PSTopsController.m
//  Prismo
//
//  Created by Sergey Lenkov on 08.02.11.
//  Copyright 2011 Sergey Lenkov. All rights reserved.
//

#import "PSTopsController.h"

@implementation PSTopsController

- (void)initialization {
    defaults = [NSUserDefaults standardUserDefaults];
    selection = [[NSMutableDictionary alloc] init];
    
    if ([defaults objectForKey:@"Selected Tops"] != nil) {
        [selection setDictionary:[defaults objectForKey:@"Selected Tops"]];
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
	return [data.categories count];
}

- (id)tableView:(NSTableView *)tableView objectValueForTableColumn:(NSTableColumn *)tableColumn row:(int)row {
    PSData *data = [PSData sharedData];
    PSCategory *category = [data.categories objectAtIndex:row];
    
	if ([[tableColumn identifier] isEqualToString:@"name"]) {
        BOOL selected = [[selection objectForKey:[NSString stringWithFormat:@"%ld", category.identifier]] boolValue];
        
		NSButtonCell *cell = [tableColumn dataCell];
        
        if (category.type == 1 || category.type == 3) {
            [cell setTitle:[NSString stringWithFormat:@"Games - %@", category.name]];
        } else {
            [cell setTitle:category.name];
        }
        
		[cell setState:selected];
        
		return cell;
	}
	
    if ([[tableColumn identifier] isEqualToString:@"type"]) {
        NSString *type = @"App Store";
        
        if (category.type == 2 || category.type == 3) {
            type = @"Mac App Store";
        }
        
        return type;
    }
    
	return nil;
}

- (void)tableView:(NSTableView *)tableView setObjectValue:(id)object forTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row {
	if ([[tableColumn identifier] isEqualToString:@"name"]) {
        PSData *data = [PSData sharedData];
        PSCategory *category = [data.categories objectAtIndex:row];
        
		NSNumber *value = [NSNumber numberWithBool:[object boolValue]];
        
        if ([value boolValue]) {
            [selection setObject:value forKey:[NSString stringWithFormat:@"%ld", category.identifier]];
        } else {
            [selection removeObjectForKey:[NSString stringWithFormat:@"%ld", category.identifier]];
        }

        [defaults setObject:selection forKey:@"Selected Tops"];
        [defaults synchronize];
        
        [view reloadData];
	}
}

@end
