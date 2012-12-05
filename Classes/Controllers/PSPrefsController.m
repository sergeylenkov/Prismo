//
//  PSPrefsController.h
//  Prismo
//
//  Created by Sergey Lenkov on 08.02.11.
//  Copyright 2011 Sergey Lenkov. All rights reserved.
//

#import "PSPrefsController.h"

@implementation PSPrefsController

- (id)init {
    self = [super initWithWindowNibName: @"PrefsWindow"];
    
    if (self) {
        defaults = [NSUserDefaults standardUserDefaults];
		
		if ([defaults objectForKey:@"Download Path"] == nil) {
			NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDownloadsDirectory, NSUserDomainMask, YES);
			NSString *folder = [paths objectAtIndex:0];
			[defaults setObject:folder forKey:@"Download Path"];
		}
		
		if ([defaults objectForKey:@"Download On Startup"] == nil) {
			[defaults setBool:NO forKey:@"Download On Startup"];
		}
		
		if ([defaults objectForKey:@"Check Ranks On Startup"] == nil) {
			[defaults setBool:NO forKey:@"Check Ranks On Startup"];
		}
		
		if ([defaults objectForKey:@"Check Reports Every"] == nil) {
			[defaults setInteger:0 forKey:@"Check Reports Every"];
		}

        if ([defaults objectForKey:@"Update Ranks Every"] == nil) {
			[defaults setInteger:0 forKey:@"Update Ranks Every"];
		}
		
		if ([defaults objectForKey:@"Currency"] == nil) {
			[defaults setObject:0 forKey:@"Currency"];
		}
		
		if ([defaults objectForKey:@"Translate To"] == nil) {
			[defaults setInteger:11 forKey:@"Translate To"];
		}
		
        [defaults synchronize];
        
		currencies = [[NSMutableArray alloc] init];
		
		[currencies addObject:@"USD"];
		[currencies addObject:@"EUR"];
		[currencies addObject:@"GBP"];
		[currencies addObject:@"JPY"];
		[currencies addObject:@"AUD"];
		[currencies addObject:@"CAD"];
    }
    
    return self;
}

- (void)awakeFromNib {    
    NSToolbar *toolbar = [[NSToolbar alloc] initWithIdentifier:@"Preferences Toolbar"];
    [toolbar setDelegate:self];
    [toolbar setAllowsUserCustomization:NO];
    [toolbar setDisplayMode:NSToolbarDisplayModeIconAndLabel];
    [toolbar setSizeMode:NSToolbarSizeModeRegular];
    [toolbar setSelectedItemIdentifier:TOOLBAR_GENERAL];
    [[self window] setToolbar:toolbar];
    [toolbar release];

	if (![[self window] setFrameUsingName:@"Preferences"]) {
		[[self window] center];
	}
	
	[startupButton setState:[[defaults objectForKey:@"Download On Startup"] boolValue]];	
	[checkStartupButton setState:[[defaults objectForKey:@"Check Ranks On Startup"] boolValue]];
	
	if ([[defaults objectForKey:@"Check Reports Every"] intValue] == 0) {
		[periodButton selectItemAtIndex:0];
	}
	
	if ([[defaults objectForKey:@"Check Reports Every"] intValue] == 1) {
		[periodButton selectItemAtIndex:2];
	}
	
	if ([[defaults objectForKey:@"Check Reports Every"] intValue] == 2) {
		[periodButton selectItemAtIndex:3];
	}
	
	if ([[defaults objectForKey:@"Check Reports Every"] intValue] == 6) {
		[periodButton selectItemAtIndex:4];
	}
	
    if ([[defaults objectForKey:@"Update Ranks Every"] intValue] == 0) {
		[ranksPeriodButton selectItemAtIndex:0];
	}
	
	if ([[defaults objectForKey:@"Update Ranks Every"] intValue] == 6) {
		[ranksPeriodButton selectItemAtIndex:2];
	}
	
	if ([[defaults objectForKey:@"Update Ranks Every"] intValue] == 12) {
		[ranksPeriodButton selectItemAtIndex:3];
	}
	
	if ([[defaults objectForKey:@"Update Ranks Every"] intValue] == 24) {
		[ranksPeriodButton selectItemAtIndex:4];
	}
    
	NSString *folder = [defaults objectForKey:@"Download Path"];
	NSImage *iconImage = [[NSWorkspace sharedWorkspace] iconForFile:folder];
	[iconImage setSize:NSMakeSize(16, 16)];
	
	[[pathButton itemAtIndex:0] setImage:iconImage];
	[[pathButton itemAtIndex:0] setTitle:[folder lastPathComponent]];
	[pathButton selectItemAtIndex:0];
	
	[currencyButton removeAllItems];
	
	for (int i = 0; i < [currencies count]; i++) {
		[currencyButton addItemWithTitle:[currencies objectAtIndex:i]];
	}
	
	[accountsController initialization];	
	[topsController initialization];
    [appsController initialization];
    [storesController initialization];
    
	[self setPrefView:nil];
}

- (void)refresh {
	if ([defaults objectForKey:@"Last Reports Check"] == nil) {
		[lastCheckField setTitleWithMnemonic:@"Last check: Never"];
	} else {
		NSDate *date = [defaults objectForKey:@"Last Reports Check"];
        NSString *dateString = [PSUtilites localizedMediumDateWithFullMonth:date];
        
        if ([date year] == [[NSDate date] year]) {
            dateString = [PSUtilites localizedShortDateWithFullMonth:date];
        }
        
		[lastCheckField setTitleWithMnemonic:[NSString stringWithFormat:@"Last check: %@ at %@", dateString, [date timeRepresentation]]];
	}
	
	if ([defaults objectForKey:@"Last Reports Check Status"] == nil) {
		[lastCheckStatusField setTitleWithMnemonic:@"Last check status: Unknown"];
	} else {
		[lastCheckStatusField setTitleWithMnemonic:[NSString stringWithFormat:@"Last check status: %@", [defaults objectForKey:@"Last Reports Check Status"]]];
	}
	
    if ([defaults objectForKey:@"Last Ranks Update"] == nil) {
		[lastRanksUpdateField setTitleWithMnemonic:@"Last update: Never"];
	} else {
		NSDate *date = [defaults objectForKey:@"Last Ranks Update"];
        NSString *dateString = [PSUtilites localizedMediumDateWithFullMonth:date];
        
        if ([date year] == [[NSDate date] year]) {
            dateString = [PSUtilites localizedShortDateWithFullMonth:date];
        }
        
		[lastRanksUpdateField setTitleWithMnemonic:[NSString stringWithFormat:@"Last update: %@ at %@", dateString, [date timeRepresentation]]];
	}
	
	if ([defaults objectForKey:@"Last Ranks Update Status"] == nil) {
		[lastRanksUpdateStatusField setTitleWithMnemonic:@"Last update status: Unknown"];
	} else {
		[lastRanksUpdateStatusField setTitleWithMnemonic:[NSString stringWithFormat:@"Last update status: %@", [defaults objectForKey:@"Last Ranks Update Status"]]];
	}
    
    if ([defaults objectForKey:@"Last Reviews Update"] == nil) {
		[lastReviewsUpdateField setTitleWithMnemonic:@"Last reviews update: Never"];
	} else {
		NSDate *date = [defaults objectForKey:@"Last Reviews Update"];
        NSString *dateString = [PSUtilites localizedMediumDateWithFullMonth:date];
        
        if ([date year] == [[NSDate date] year]) {
            dateString = [PSUtilites localizedShortDateWithFullMonth:date];
        }
        
		[lastReviewsUpdateField setTitleWithMnemonic:[NSString stringWithFormat:@"Last update: %@ at %@", dateString, [date timeRepresentation]]];
	}
	
	if ([defaults objectForKey:@"Last Reviews Update Status"] == nil) {
		[lastReviewsUpdateStatusField setTitleWithMnemonic:@"Last update status: Unknown"];
	} else {
		[lastReviewsUpdateStatusField setTitleWithMnemonic:[NSString stringWithFormat:@"Last update status: %@", [defaults objectForKey:@"Last Reviews Update Status"]]];
	}
    
	[currencyButton selectItemAtIndex:[[defaults objectForKey:@"Currency"] intValue]];
		
	[accountsController refresh];
    [topsController refresh];
    [appsController refresh];
    [storesController refresh];
}

- (NSToolbarItem *)toolbar:(NSToolbar *)toolbar itemForItemIdentifier:(NSString *)ident willBeInsertedIntoToolbar:(BOOL)flag {
    NSToolbarItem *item = [[NSToolbarItem alloc] initWithItemIdentifier:ident];

    if ([ident isEqualToString:TOOLBAR_GENERAL]) {
        [item setLabel:@"General"];
        [item setImage:[NSImage imageNamed:@"NSPreferencesGeneral"]];
        [item setTarget:self];
        [item setAction:@selector(setPrefView:)];
        [item setAutovalidates:NO];
	} else if ([ident isEqualToString:TOOLBAR_REPORTS]) {
        [item setLabel:@"Reports"];
        [item setImage:[NSImage imageNamed:@"Reports32.png"]];
        [item setTarget:self];
        [item setAction:@selector(setPrefView:)];
        [item setAutovalidates:NO];
    } else if ([ident isEqualToString:TOOLBAR_TOPS]) {
        [item setLabel:@"Ranks"];
        [item setImage:[NSImage imageNamed:@"Ranks32.png"]];
        [item setTarget:self];
        [item setAction:@selector(setPrefView:)];
        [item setAutovalidates:NO];
    } else if ([ident isEqualToString:TOOLBAR_APPLEID]) {
        [item setLabel:@"Accounts"];
        [item setImage:[NSImage imageNamed:@"NSUserAccounts"]];
        [item setTarget:self];
        [item setAction:@selector(setPrefView:)];
        [item setAutovalidates:NO];
    } else if ([ident isEqualToString:TOOLBAR_APPS]) {
        [item setLabel:@"Reviews"];
        [item setImage:[NSImage imageNamed:@"Reviews32"]];
        [item setTarget:self];
        [item setAction:@selector(setPrefView:)];
        [item setAutovalidates:NO];
	} else if ([ident isEqualToString:TOOLBAR_UPDATE]) {
        [item setLabel:@"Update"];
        [item setImage:[NSImage imageNamed:@"PreferenceUpdate.tiff"]];
        [item setTarget:self];
        [item setAction:@selector(setPrefView:)];
        [item setAutovalidates:NO];
    } else {
        [item release];
        return nil;
    }

    return [item autorelease];
}

- (NSArray *)toolbarSelectableItemIdentifiers:(NSToolbar *)toolbar {
    return [self toolbarDefaultItemIdentifiers:toolbar];
}

- (NSArray *)toolbarDefaultItemIdentifiers:(NSToolbar *)toolbar {
    return [self toolbarAllowedItemIdentifiers:toolbar];
}

- (NSArray *)toolbarAllowedItemIdentifiers: (NSToolbar *)toolbar {
    return [NSArray arrayWithObjects:TOOLBAR_GENERAL, TOOLBAR_APPLEID, TOOLBAR_REPORTS, TOOLBAR_TOPS, TOOLBAR_APPS, TOOLBAR_UPDATE, nil];
}

- (void)setPrefView:(id)sender {
    NSString *identifier;
	
    if (sender) {
        identifier = [sender itemIdentifier];
        [[NSUserDefaults standardUserDefaults] setObject:identifier forKey:@"SelectedPrefView"];
    } else {
        identifier = [[NSUserDefaults standardUserDefaults] stringForKey:@"SelectedPrefView"];
    }
	
    NSView *view;
	
    if ([identifier isEqualToString:TOOLBAR_APPLEID]) {		
        view = appleIDView;
	} else if ([identifier isEqualToString:TOOLBAR_REPORTS]) {
		view = reportsView;
    } else if ([identifier isEqualToString:TOOLBAR_TOPS]) {
		view = topsView;
    } else if ([identifier isEqualToString:TOOLBAR_APPS]) {
        view = appsView;
	} else if ([identifier isEqualToString:TOOLBAR_UPDATE]) {
		 view = updateView;
	} else {
        identifier = TOOLBAR_GENERAL;
        view = generalView;
    }
    
    [[[self window] toolbar] setSelectedItemIdentifier:identifier];
    
    NSWindow *window = [self window];
	
    if ([window contentView] == view) {
        return;
    }

    NSRect windowRect = [window frame];
    float difference = ([view frame].size.height - [[window contentView] frame].size.height) * [window userSpaceScaleFactor];
    windowRect.origin.y -= difference;
    windowRect.size.height += difference;
   
	difference = ([view frame].size.width - [[window contentView] frame].size.width) * [window userSpaceScaleFactor];
    windowRect.size.width += difference;
	
    [view setHidden:YES];
    [window setContentView:view];
    [window setFrame:windowRect display:YES animate:YES];
    [view setHidden:NO];
    
    if (sender) {
        [window setTitle:[sender label]];
    } else {
        NSToolbar *toolbar = [window toolbar];
        NSString *itemIdentifier = [toolbar selectedItemIdentifier];
        NSEnumerator *enumerator = [[toolbar items] objectEnumerator];
        NSToolbarItem *item;
		
        while ((item = [enumerator nextObject])) {
            if ([[item itemIdentifier] isEqualToString:itemIdentifier]) {
                [window setTitle:[item label]];
                break;
            }
		}
    }
}

- (void)selectTabWithIndetifier:(NSString *)identifier {
	NSView *view;
	
    if ([identifier isEqualToString:TOOLBAR_APPLEID]) {		
        view = appleIDView;
	} else if ([identifier isEqualToString:TOOLBAR_REPORTS]) {
		view = reportsView;
    } else if ([identifier isEqualToString:TOOLBAR_TOPS]) {
		view = topsView;
    } else if ([identifier isEqualToString:TOOLBAR_APPS]) {
        view = appsView;
	} else if ([identifier isEqualToString:TOOLBAR_UPDATE]) {
		view = updateView;
	} else {
        identifier = TOOLBAR_GENERAL;
        view = generalView;
    }
    
    [[[self window] toolbar] setSelectedItemIdentifier:identifier];
    
    NSWindow *window = [self window];
	
    if ([window contentView] == view) {
        return;
    }
	
    NSRect windowRect = [window frame];
    float difference = ([view frame].size.height - [[window contentView] frame].size.height) * [window userSpaceScaleFactor];
    windowRect.origin.y -= difference;
    windowRect.size.height += difference;
	
	difference = ([view frame].size.width - [[window contentView] frame].size.width) * [window userSpaceScaleFactor];
    windowRect.size.width += difference;
	
    [view setHidden:YES];
    [window setContentView:view];
    [window setFrame:windowRect display:YES animate:YES];
    [view setHidden:NO];
    
	NSToolbar *toolbar = [window toolbar];
	NSString *itemIdentifier = [toolbar selectedItemIdentifier];
	NSEnumerator *enumerator = [[toolbar items] objectEnumerator];
	NSToolbarItem *item;
		
	while ((item = [enumerator nextObject])) {
		if ([[item itemIdentifier] isEqualToString:itemIdentifier]) {
			[window setTitle:[item label]];
			break;
		}
	}
}

- (IBAction)setOnStartup:(id)sender {
	[defaults setBool:[startupButton state] forKey:@"Download On Startup"];
}

- (IBAction)setCheckOnStartup:(id)sender {
	[defaults setBool:[checkStartupButton state] forKey:@"Check Ranks On Startup"];
}

- (IBAction)changePeriod:(id)sender {	
	if ([periodButton indexOfSelectedItem] == 0) {
		[defaults setInteger:0 forKey:@"Check Reports Every"];
	}
	
	if ([periodButton indexOfSelectedItem] == 2) {
		[defaults setInteger:1 forKey:@"Check Reports Every"];
	}
	
	if ([periodButton indexOfSelectedItem] == 3) {
		[defaults setInteger:2 forKey:@"Check Reports Every"];
	}
	
	if ([periodButton indexOfSelectedItem] == 4) {
		[defaults setInteger:6 forKey:@"Check Reports Every"];
	}
}

- (IBAction)changeRanksPeriod:(id)sender {
    if ([periodButton indexOfSelectedItem] == 0) {
		[defaults setInteger:0 forKey:@"Update Ranks Every"];
	}
	
	if ([periodButton indexOfSelectedItem] == 2) {
		[defaults setInteger:6 forKey:@"Update Ranks Every"];
	}
	
	if ([periodButton indexOfSelectedItem] == 3) {
		[defaults setInteger:12 forKey:@"Update Ranks Every"];
	}
	
	if ([periodButton indexOfSelectedItem] == 4) {
		[defaults setInteger:24 forKey:@"Update Ranks Every"];
	}
}

- (IBAction)changePath:(id)sender {
	if ([pathButton indexOfSelectedItem] == 2) {
		NSOpenPanel *panel = [NSOpenPanel openPanel];
		
		[panel setPrompt:@""];
		[panel setAllowsMultipleSelection:NO];
		[panel setCanChooseFiles:NO];
		[panel setCanChooseDirectories:YES];
		[panel setCanCreateDirectories:YES];
		
        [panel beginSheetModalForWindow:[self window] completionHandler:^(NSInteger result) {
            if (result == NSFileHandlingPanelOKButton) {
                NSString *folder = [[[panel URLs] objectAtIndex:0] path];		
                [defaults setObject:folder forKey:@"Download Path"];
                
                NSImage *iconImage = [[NSWorkspace sharedWorkspace] iconForFile:folder];
                [iconImage setSize:NSMakeSize(16, 16)];
                
                [[pathButton itemAtIndex:0] setImage:iconImage];
                [[pathButton itemAtIndex:0] setTitle:[[defaults objectForKey:@"Download Path"] lastPathComponent]];
                [pathButton selectItemAtIndex:0];
            }
        }];
	}
}

- (IBAction)changeCurrency:(id)sender {
	[defaults setInteger:[currencyButton indexOfSelectedItem] forKey:@"Currency"];
	[[NSNotificationCenter defaultCenter] postNotificationName:@"Refresh" object:nil];
}

- (void)dealloc {
	[currencies release];
    [super dealloc];
}

@end
