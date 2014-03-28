#import "AppDelegate.h"

@implementation AppDelegate

- (void)dealloc {
	[preferencesController release];
	[reportDownloader release];
	[reviewParser release];
	[rankParser release];
    [dropbox release];
	[super dealloc];
}

- (void)awakeFromNib {
    #if LOG_IN_FILE
        [[NSApplication sharedApplication] redirectConsoleLogToDocumentFolder];
    #endif

    PSUpdater *updater = [[PSUpdater alloc] initWithDatabase:[Database sharedDatabase]];
    [updater update];
    [updater release];
    
    [[PSData sharedData] reloadData];
    
	dockTile = [NSApp dockTile];
	
	if (![mainWindow setFrameUsingName:@"Main"]) {
		[mainWindow center];
	}

	[mainWindow setAutorecalculatesContentBorderThickness:YES forEdge:NSMinYEdge];
	[mainWindow setContentBorderThickness:35 forEdge:NSMinYEdge];

    menuController.mainWindow = mainWindow;
    
    [progressView setFrame:NSMakeRect(0, 0, scrollView.frame.size.width, 0)];

	[self enableDownloadItems];
    
	preferencesController = [[PSPrefsController alloc] init];
	
	reportDownloader = [[PSReportDownloader alloc] initWithDatabase:[Database sharedDatabase]];
	reportDownloader.delegate = self;
	
	reviewParser = [[PSReviewParser alloc] initWithDatabase:[Database sharedDatabase]];
	reviewParser.delegate = self;
    
	rankParser = [[PSRankParser alloc] initWithDatabase:[Database sharedDatabase]];
	rankParser.delegate = self;
	
    dropbox = [[PSDropboxSync alloc] init];
    dropbox.delegate = self;
}

- (void)applicationDidFinishLaunching:(NSNotification *)notification {
    [menuController refresh];

	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    
	isNeedUpdateRanks = NO;
    isNeedDownloadReports = NO;
    
	if ([defaults objectForKey:@"Download On Startup"] != nil) {	
		NSNumber *number = [defaults objectForKey:@"Download On Startup"];
		
		if ([number boolValue]) {
			[self downloadReports:nil];
		}
	}
	
	if ([defaults objectForKey:@"Check Ranks On Startup"] != nil) {	
		NSNumber *number = [defaults objectForKey:@"Check Ranks On Startup"];
		
		if ([number boolValue]) {
			if (![[defaults objectForKey:@"Download On Startup"] boolValue]) {
				[self updateRanks:nil];
			} else {
				isNeedUpdateRanks = YES;
			}
		}
	}	
	
	if ([defaults objectForKey:@"Check Reports Every"] != nil) {
		NSNumber *number = [defaults objectForKey:@"Check Reports Every"];
		
		if ([number intValue] > 0) {
			timer = [[NSTimer timerWithTimeInterval:(3600.0 * [number intValue]) target:self selector:@selector(downloadReports:) userInfo:nil repeats:YES] retain];
			[[NSRunLoop currentRunLoop] addTimer:timer forMode:NSDefaultRunLoopMode];
		}
	}
    
    if ([defaults objectForKey:@"Update Ranks Every"] != nil) {
		NSNumber *number = [defaults objectForKey:@"Update Ranks Every"];
		
		if ([number intValue] > 0) {
			timer = [[NSTimer timerWithTimeInterval:(3600.0 * [number intValue] + (3600.0 * 0.5)) target:self selector:@selector(updateRanks:) userInfo:nil repeats:YES] retain];
			[[NSRunLoop currentRunLoop] addTimer:timer forMode:NSDefaultRunLoopMode];
		}
	}
}

- (NSApplicationPresentationOptions)window:(NSWindow *)window willUseFullScreenPresentationOptions:(NSApplicationPresentationOptions)proposedOptions {
    return NSApplicationPresentationDefault;
}

- (BOOL)applicationShouldHandleReopen:(NSApplication *)theApplication hasVisibleWindows:(BOOL)flag {
	if (flag) {
		return NO;
	} else {
		[mainWindow makeKeyAndOrderFront:self];
		
		[dockTile setBadgeLabel:@""];
		[dockTile display];
		
		return YES;
	}	
}

- (NSApplicationTerminateReply)applicationShouldTerminate:(NSApplication *)sender {	
	[Database reindex];
	[Database close];
	
	return NSTerminateNow;
}

- (void)application:(NSApplication *)sender openFiles:(NSArray *)filenames {	
	[NSThread detachNewThreadSelector:@selector(importFilesThread:) toTarget:self withObject:filenames];
}

- (void)addTrialButton {
	NSView *mainView = [[mainWindow contentView] superview];
	
	NSRect mainFrame = [mainView frame];
	NSRect accessoryFrame = [accessoryView frame];
    
    int offset = 0;
    
    if ([[NSApplication sharedApplication] isLion]) {
        offset = 14;
    }
    
	NSRect newFrame = NSMakeRect(mainFrame.size.width - accessoryFrame.size.width - offset, mainFrame.size.height - accessoryFrame.size.height, accessoryFrame.size.width, accessoryFrame.size.height);
	
	[accessoryView setFrame:newFrame];
	[mainView addSubview:accessoryView];
}

- (void)downloadReportsThread {
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	
    [self performSelectorOnMainThread:@selector(showProgressView) withObject:nil waitUntilDone:YES];
    [self startProgressAnimationWithTitle:@"Checking reports..." maxValue:0.0 indeterminate:YES];
    
    isNeedDownloadReports = NO;    
    reportDownloader.isCanceled = NO;
	
    PSData *data = [PSData sharedData];
    
	int salesBefore = [data totalDownloads];
	    
	[reportDownloader download];
	
	int salesAfter = [data totalDownloads];
	
	if (salesAfter - salesBefore > 0) {	
		if (!mainWindow.isVisible) {
			[dockTile setBadgeLabel:[NSString stringWithFormat:@"%d", salesAfter - salesBefore]];
			[dockTile display];
		}
		
        [self changePhaseWithMessage:@"Reloading data..."];
        [NSThread sleepForTimeInterval:1.0];
        
        [data reloadReferences];
        
		[self performSelectorOnMainThread:@selector(refreshMenu) withObject:nil waitUntilDone:YES];
	}
	
	if (isNeedUpdateRanks) {
		isNeedUpdateRanks = NO;
		[self performSelectorOnMainThread:@selector(updateRanks:) withObject:nil waitUntilDone:YES];
	}
	
    [self stopProgressAnimation];
    [self performSelectorOnMainThread:@selector(hideProgressView) withObject:nil waitUntilDone:YES];
    
	[pool release];
}

- (void)downloadReviewsThread {
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
    
    PSData *data = [PSData sharedData];
    NSDictionary *applications = [[NSUserDefaults standardUserDefaults] objectForKey:@"Selected Apps"];
    
    [self performSelectorOnMainThread:@selector(showProgressView) withObject:nil waitUntilDone:YES];
    [self startProgressAnimationWithTitle:@"Updating reviews..." maxValue:[applications count] * [data.stores count] indeterminate:NO];
    
	reviewParser.isCanceled = NO;
	[reviewParser parse];
    
    NSInteger count = [data newReviewsCount];
    
	if (!reviewParser.isCanceled) {	
		if (count > 0) {
            [self startProgressAnimationWithTitle:@"Updating reviews..." maxValue:0.0 indeterminate:YES];
            [self changePhaseWithMessage:@"Reloading data..."];
            [NSThread sleepForTimeInterval:1.0];
            
            [self performSelectorOnMainThread:@selector(refreshMenu) withObject:nil waitUntilDone:YES];
            
            if (count == 1) {
                [GrowlApplicationBridge notifyWithTitle:@"Reviews" description:@"You have a new review" notificationName:@"New event" iconData:nil priority:0 isSticky:NO clickContext:nil];
            } else {
                [GrowlApplicationBridge notifyWithTitle:@"Reviews" description:[NSString stringWithFormat:@"You have %ld new reviews", count] notificationName:@"New event" iconData:nil priority:0 isSticky:NO clickContext:nil];
            }
		} else {
			[GrowlApplicationBridge notifyWithTitle:@"Reviews" description:@"No new reviews" notificationName:@"New event" iconData:nil priority:0 isSticky:NO clickContext:nil];
		}
	}
	
    if (isNeedDownloadReports) {
		[self performSelectorOnMainThread:@selector(downloadReports:) withObject:nil waitUntilDone:YES];
	}
    
    if (isNeedUpdateRanks) {		
		[self performSelectorOnMainThread:@selector(updateRanks:) withObject:nil waitUntilDone:YES];
	}
    
    [self stopProgressAnimation];
    [self performSelectorOnMainThread:@selector(hideProgressView) withObject:nil waitUntilDone:YES];
    
	[pool release];
}

- (void)updateRanksThread {
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];

    PSData *data = [PSData sharedData];
    
    NSDictionary *selectedCategories = [[NSUserDefaults standardUserDefaults] objectForKey:@"Selected Tops"];
    NSMutableArray *categories = [[NSMutableArray alloc] init];
    
    for (PSCategory *category in data.categories) {
        if ([[selectedCategories objectForKey:[NSString stringWithFormat:@"%ld", category.identifier]] boolValue]) {
            [categories addObject:category];
        }
    }
    
    NSDictionary *selectedStores = [[NSUserDefaults standardUserDefaults] objectForKey:@"Selected Stores"];
    NSMutableArray *stores = [[NSMutableArray alloc] init];
    
    for (PSStore *store in data.stores) {
        if ([[selectedStores objectForKey:[NSString stringWithFormat:@"%ld", store.identifier]] boolValue]) {
            [stores addObject:store];
        }
    }
    
    [self performSelectorOnMainThread:@selector(showProgressView) withObject:nil waitUntilDone:YES];
    [self startProgressAnimationWithTitle:@"Updating ranks..." maxValue:[stores count] * [categories count] indeterminate:NO];
    
    isNeedUpdateRanks = NO;
	rankParser.isCanceled = NO;
    
	[rankParser parse];
    
	if (!rankParser.isCanceled) {
        [self startProgressAnimationWithTitle:@"Updating ranks..." maxValue:0.0 indeterminate:YES];
        [self changePhaseWithMessage:@"Reloading data..."];
        [NSThread sleepForTimeInterval:1.0];
        
		[self performSelectorOnMainThread:@selector(refreshMenu) withObject:nil waitUntilDone:YES];
        
		[GrowlApplicationBridge notifyWithTitle:@"Ranks" description:@"Ranks checked successfully" notificationName:@"New event" iconData:nil priority:0 isSticky:NO clickContext:nil];	
	}
	
    if (isNeedDownloadReports) {
		isNeedDownloadReports = NO;
		[self performSelectorOnMainThread:@selector(downloadReports:) withObject:nil waitUntilDone:YES];
	}
    
    [self stopProgressAnimation];
    [self performSelectorOnMainThread:@selector(hideProgressView) withObject:nil waitUntilDone:YES];
    
    [categories release];
    [stores release];
	[pool release];
}

- (void)importFilesThread:(NSArray *)files {
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	
	reportDownloader.isCanceled = NO;
	
    [self performSelectorOnMainThread:@selector(showProgressView) withObject:nil waitUntilDone:YES];
	[self startProgressAnimationWithTitle:@"Importing reports..." maxValue:[files count] indeterminate:NO];
	
	for(int i = 0; i < [files count]; i++ ) {
		if (reportDownloader.isCanceled) {
			break;
		}
		
		NSString *fileName = [files objectAtIndex:i];
		[self changePhaseWithMessage:[fileName lastPathComponent]];
		[reportDownloader importFile:fileName forAccount:@""];
		
		[self incrementProgressIndicatorBy:1.0];
	}
	
    [NSThread sleepForTimeInterval:1.0];
    
	if (!reportDownloader.isCanceled) {
        [self startProgressAnimationWithTitle:@"Importing reports..." maxValue:0.0 indeterminate:YES];
        [self changePhaseWithMessage:@"Reloading data..."];
        [NSThread sleepForTimeInterval:1.0];
        
        [[PSData sharedData] reloadReferences];
        
        [self performSelectorOnMainThread:@selector(refreshMenu) withObject:nil waitUntilDone:YES];
        
		[GrowlApplicationBridge notifyWithTitle:@"Import" description:@"Import completed" notificationName:@"New event" iconData:nil priority:0 isSticky:NO clickContext:nil];	
	}
	
    [self stopProgressAnimation];
    [self performSelectorOnMainThread:@selector(hideProgressView) withObject:nil waitUntilDone:YES];
    
	[pool release];
}

- (void)syncDropboxThread {
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
    
    dropbox.isCanceled = NO;
    
    [self performSelectorOnMainThread:@selector(showProgressView) withObject:nil waitUntilDone:YES];
    [self startProgressAnimationWithTitle:@"Sync with Dropbox" maxValue:0.0 indeterminate:YES];
    
    [dropbox startSync];
    
	if (!dropbox.isCanceled) {
        [self startProgressAnimationWithTitle:@"Sync with Dropbox" maxValue:0.0 indeterminate:YES];
        [self changePhaseWithMessage:@"Reloading data..."];
        [NSThread sleepForTimeInterval:1.0];
        
        [[PSData sharedData] reloadData];
        [self performSelectorOnMainThread:@selector(refreshMenu) withObject:nil waitUntilDone:YES];
        
		[GrowlApplicationBridge notifyWithTitle:@"Sync" description:@"Dropbox sync completed" notificationName:@"New event" iconData:nil priority:0 isSticky:NO clickContext:nil];
	}
    
    [self stopProgressAnimation];
    [self performSelectorOnMainThread:@selector(hideProgressView) withObject:nil waitUntilDone:YES];
    
    [pool release];
}

-  (void)refreshMenu {
    [menuController refresh];
    [menuController refreshSelectedItem];
}

- (void)showProgressView {
    [NSAnimationContext beginGrouping];

    [[NSAnimationContext currentContext] setDuration:0.2];
    
    NSRect frame = scrollView.frame;
    frame.origin.y = frame.origin.y + 100;
    frame.size.height = frame.size.height - 100;

    [[scrollView animator] setFrame:frame];
    [[progressView animator] setFrame:NSMakeRect(0, 0, scrollView.frame.size.width, 100)];

    [NSAnimationContext endGrouping];
}

- (void)hideProgressView {
    [NSAnimationContext beginGrouping];
    
    [[NSAnimationContext currentContext] setDuration:0.2];
    
    NSRect frame = scrollView.frame;
    frame.origin.y = frame.origin.y - 100;
    frame.size.height = frame.size.height + 100;
    
    [[scrollView animator] setFrame:frame];
    [[progressView animator] setFrame:NSMakeRect(0, 0, scrollView.frame.size.width, 0)];
    
    [NSAnimationContext endGrouping];
}

- (void)startProgressAnimationWithTitle:(NSString *)title maxValue:(NSInteger)max indeterminate:(BOOL)indeterminate {
	[infoLabel setTitleWithMnemonic:title];
	[detailsLabel setTitleWithMnemonic:@""];
	 
	[progressIndicator setMinValue:0];
	[progressIndicator setMaxValue:max];
	[progressIndicator setDoubleValue:0.0];
	[progressIndicator setIndeterminate:indeterminate];
	[progressIndicator setUsesThreadedAnimation:YES];
	
	[self performSelectorOnMainThread:@selector(startAnimation) withObject:nil waitUntilDone:YES];
}

- (void)stopProgressAnimation {
	[self performSelectorOnMainThread:@selector(stopAnimation) withObject:nil waitUntilDone:YES];
}

- (void)incrementProgressIndicatorBy:(double)value {
	[progressIndicator incrementBy:value];
}

- (void)updateProgress:(double)value {
    [progressIndicator setDoubleValue:value];
}

- (void)changePhaseWithMessage:(NSString *)message {
	[self performSelectorOnMainThread:@selector(changeDetailsInfo:) withObject:message waitUntilDone:YES];
}

- (void)changeDetailsInfo:(NSString *)message {
	[detailsLabel setTitleWithMnemonic:message];
}

- (void)startAnimation {
    [progressIndicator startAnimation:self];
	[self disableDownloadItems];
    [cancelButton setEnabled:YES];
}

- (void)stopAnimation {
    [progressIndicator stopAnimation:self];
	[self enableDownloadItems];
}

- (void)disableDownloadItems {
	[importReportItem setEnabled:NO];
	[downloadReportItem setEnabled:NO];
	[downloadReviewItem setEnabled:NO];
    [downloadRatingItem setEnabled:NO];
	[downloadRanksItem setEnabled:NO];
	[importButton setEnabled:NO];
	[downloadButton setEnabled:NO];
	[syncDropboxItem setEnabled:NO];
	
	isDownloading = YES;
}

- (void)enableDownloadItems {
	[importReportItem setEnabled:YES];
	[downloadReportItem setEnabled:YES];
	[downloadReviewItem setEnabled:YES];
    [downloadRatingItem setEnabled:YES];
	[downloadRanksItem setEnabled:YES];
	[downloadButton setEnabled:YES];
	[importButton setEnabled:YES];
	[syncDropboxItem setEnabled:YES];
	
	isDownloading = NO;
}

#pragma mark -
#pragma mark IBAction
#pragma mark -

- (IBAction)preferences:(id)sender {
	[preferencesController showWindow:sender];
	[preferencesController refresh];
	[[preferencesController window] center];
}

- (IBAction)importReports:(id)sender {
	NSOpenPanel *panel = [NSOpenPanel openPanel];
	
	[panel setCanChooseFiles:YES];
	[panel setCanChooseDirectories:NO];
	[panel setAllowsMultipleSelection:YES];
	[panel setAllowedFileTypes:[NSArray arrayWithObjects:@"txt", nil]];

    [panel beginSheetModalForWindow:mainWindow completionHandler:^(NSInteger result) {
        if (result == NSFileHandlingPanelOKButton) {
            NSMutableArray *files = [[[NSMutableArray alloc] init] autorelease];
            
            for (NSURL *url in [panel URLs]) {
                [files addObject:[url path]];
            }
            
            [NSThread detachNewThreadSelector:@selector(importFilesThread:) toTarget:self withObject:files];
        }
    }];
}

- (IBAction)downloadReports:(id)sender {
	if (isDownloading) {
        isNeedDownloadReports = YES;
		return;
	}
	
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	NSArray *accounts = [defaults objectForKey:@"Accounts"];
	
	if ([accounts count] == 0) {
		[self preferences:nil];
		[preferencesController selectTabWithIndetifier:TOOLBAR_APPLEID];
		return;
	}
	
	for (int i = 0; i < [accounts count]; i++) {	
		NSDictionary *account = [accounts objectAtIndex:i];
		NSString *password = [PTKeychain passwordForLabel:ITUNES_LABEL account:[account objectForKey:@"id"]];
		
		if ([[account objectForKey:@"id"] isEqualToString:@""] || [password isEqualToString:@""]) {
			[self preferences:nil];
			[preferencesController selectTabWithIndetifier:TOOLBAR_APPLEID];
			return;
		}
	}
	
	[NSThread detachNewThreadSelector:@selector(downloadReportsThread) toTarget:self withObject:nil];
}

- (IBAction)downloadReviews:(id)sender {
	[NSThread detachNewThreadSelector:@selector(downloadReviewsThread) toTarget:self withObject:nil];
}

- (IBAction)downloadRatings:(id)sender {
    [NSThread detachNewThreadSelector:@selector(downloadRatingsThread) toTarget:self withObject:nil];
}

- (IBAction)updateRanks:(id)sender {
    if (isDownloading) {
        isNeedUpdateRanks = YES;
		return;
	}
	
	[NSThread detachNewThreadSelector:@selector(updateRanksThread) toTarget:self withObject:nil];
}

- (IBAction)cancelDownloads:(id)sender {
	reportDownloader.isCanceled = YES;
	reviewParser.isCanceled = YES;
	rankParser.isCanceled = YES;
	dropbox.isCanceled = YES;
    
	[cancelButton setEnabled:NO];
}

- (IBAction)syncDropbox:(id)sender {
    [NSThread detachNewThreadSelector:@selector(syncDropboxThread) toTarget:self withObject:nil];
}
    
- (IBAction)visitWebSite:(id)sender {
	[[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:SITE_URL]];
}

- (IBAction)buy:(id)sender {
	[[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:BUY_URL]];
}

- (IBAction)print:(id)sender {
	[[NSNotificationCenter defaultCenter] postNotificationName:@"Print" object:nil];
}

@end
