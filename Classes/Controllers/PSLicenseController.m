#import "PSLicenseController.h"

@implementation PSLicenseController

- (void)showOnWindow:(NSWindow *)sender {
	NSWindow *window = [self window];
	
	[titleLabel setFont:[NSFont boldSystemFontOfSize:18]];
	[titleLabel setFrame:NSRectFromCGRect(CGRectMake(15, 0, 300, 32))];
	
	NSUserDefaults  *defaults = [NSUserDefaults standardUserDefaults];
	
	if ([defaults objectForKey:@"Registration Name"] != nil) {
		[nameField setTitleWithMnemonic:[defaults objectForKey:@"Registration Name"]];
	}
	
	if ([defaults objectForKey:@"Registration Key"] != nil) {
		[keyField setTitleWithMnemonic:[defaults objectForKey:@"Registration Key"]];
	}
	
	[NSApp beginSheet:window modalForWindow:sender modalDelegate:nil didEndSelector:nil contextInfo:nil];
	[NSApp runModalForWindow:window];
	
	[NSApp endSheet:window];
	[window orderOut:self];	
}

- (IBAction)cancel:(id)sender {
	[NSApp stopModal];
}

- (IBAction)done:(id)sender {
	NSString *name = [nameField stringValue];
	NSString *key = [keyField stringValue];
		
	if ([PSLicense checkLicenseForName:name andKey:key]) {
		NSRunAlertPanel(@"Registration successful!", @"Thank you for purchasing Prismo.", @"Ok", nil, nil);
			
		NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
			
		[defaults setObject:[nameField stringValue] forKey:@"Registration Name"];
		[defaults setObject:[keyField stringValue] forKey:@"Registration Key"];
			
		[NSApp stopModal];
	} else {
		NSRunAlertPanel(@"Registration information is invalid!", @"Check registration name and key.", @"Ok", nil, nil);
	}
}

- (void)dealloc {
	[nameField release];
    [keyField release];
	[super dealloc];
}

@end
