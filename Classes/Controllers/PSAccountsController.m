//
//  PSAccountsController.m
//  Prismo
//
//  Created by Sergey Lenkov on 08.02.11.
//  Copyright 2011 Sergey Lenkov. All rights reserved.
//

#import "PSAccountsController.h"

@implementation PSAccountsController

- (void)initialization {	
	NSTableColumn *tableColumn = [view tableColumnWithIdentifier:@"id"];
	
	NSTextFieldCell *dataCell = [[[NSTextFieldCell alloc] initTextCell:@""] autorelease];
	[dataCell setEditable:YES];
	[dataCell setAlignment:NSLeftTextAlignment];
	[dataCell setFont:[NSFont systemFontOfSize:13]];	
	[tableColumn setDataCell:dataCell];
	
	tableColumn = [view tableColumnWithIdentifier:@"password"];
	
	NSSecureTextFieldCell *secureCell = [[[NSSecureTextFieldCell alloc] initTextCell:@""] autorelease];
	[secureCell setEditable:YES];
	[secureCell setEchosBullets:YES];
	[secureCell setAlignment:NSLeftTextAlignment];
	[secureCell setFont:[NSFont systemFontOfSize:13]];
	[tableColumn setDataCell:secureCell];

	accounts = [[NSMutableArray alloc] init];
}

- (void)refresh {
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	[accounts removeAllObjects];
	
	if ([defaults objectForKey:@"Accounts"] != nil) {
		NSArray *array = [defaults objectForKey:@"Accounts"];
		
		for (int i = 0; i < [array count]; i++) {			
			NSMutableDictionary *account = [NSMutableDictionary dictionaryWithDictionary:[array objectAtIndex:i]];
			NSString *password = [PTKeychain passwordForLabel:ITUNES_LABEL account:[account objectForKey:@"id"]];

			[account setObject:password forKey:@"password"];
			[accounts addObject:account];
		}
	}

	[view reloadData];
	[deleteButton setEnabled:NO];
}

- (void)save {
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];	
	NSMutableArray *array = [[NSMutableArray alloc] init];
	
	for (int i = 0; i < [accounts count]; i++) {
		NSMutableDictionary *account = [NSMutableDictionary dictionaryWithDictionary:[accounts objectAtIndex:i]];
        [account removeObjectForKey:@"password"];
        
		[array addObject:account];
	}
	
	[defaults setObject:array forKey:@"Accounts"];	
	[defaults synchronize];
    
    [array release];
}

#pragma mark -
#pragma mark NSTableViewDelegate
#pragma mark -

- (int)numberOfRowsInTableView:(NSTableView *)tableView {
	return [accounts count];
}

- (id)tableView:(NSTableView *)tableView objectValueForTableColumn:(NSTableColumn *)tableColumn row:(int)row {
	NSMutableDictionary *account = [accounts objectAtIndex:row];
	
	if ([[tableColumn identifier] isEqualToString:@"id"]) {
		return [account objectForKey:@"id"];
	}
	
    if ([[tableColumn identifier] isEqualToString:@"vendor"]) {
		return [account objectForKey:@"vendor"];
	}
    
	if ([[tableColumn identifier] isEqualToString:@"password"]) {
		return [account objectForKey:@"password"];
	}
	
	return @"";
}

- (void)tableView:(NSTableView *)aTableView setObjectValue:(id)anObject forTableColumn:(NSTableColumn *)aTableColumn row:(int)rowIndex {
	if ([[aTableColumn identifier] isEqualToString:@"id"]) {
		if ([anObject isEqualToString:@""]) {
			return;
		}
	}
	
	NSMutableDictionary *account = [accounts objectAtIndex:rowIndex];
	[account setObject:anObject forKey:[aTableColumn identifier]];
	
	if ([[aTableColumn identifier] isEqualToString:@"password"]) {
		if ([PTKeychain keychainExistsWithLabel:ITUNES_LABEL forAccount:[account objectForKey:@"id"]] > 0) {
			[PTKeychain modifyKeychainPassword:anObject withLabel:ITUNES_LABEL forAccount:[account objectForKey:@"id"]];
		} else {
			[PTKeychain addKeychainPassword:anObject withLabel:ITUNES_LABEL forAccount:[account objectForKey:@"id"]];
		}
	}	
	
	[self save];
}

- (void)tableViewSelectionDidChange:(NSNotification *)notification {
	int selectedRow = [[notification object] selectedRow];
	
	if (selectedRow != -1) {
		[deleteButton setEnabled:YES];
	} else {
		[deleteButton setEnabled:NO];
	}

}

- (IBAction)addAccount:(id)sender {
	NSMutableDictionary *account = [[NSMutableDictionary alloc] initWithObjectsAndKeys:@"Apple ID", @"id", @"Vendor ID", @"vendor", @"", @"password", nil];
	[accounts addObject:account];
	[account release];
	
	[view reloadData];	
    [view editColumn:0 row:([accounts count] - 1) withEvent:nil select:YES];
	
	[self save];
}

- (IBAction)removeAccount:(id)sender {
	int selectedRow = [view selectedRow];

	if (selectedRow != -1) {
        NSMutableDictionary *account = [accounts objectAtIndex:selectedRow];
        
        if ([PTKeychain keychainExistsWithLabel:ITUNES_LABEL forAccount:[account objectForKey:@"id"]] > 0) {
            [PTKeychain deleteKeychainPasswordForLabel:ITUNES_LABEL account:[account objectForKey:@"id"]];
        }
		
		[accounts removeObjectAtIndex:selectedRow];
		
		[view reloadData];		
		[self save];
	}
}

@end
