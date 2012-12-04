#import <Cocoa/Cocoa.h>
#import <Growl/GrowlApplicationBridge.h>
#import <Sparkle/Sparkle.h>
#import "PTKeychain.h"
#import "PSMenuController.h"
#import "PSPrefsController.h"
#import "PSReportDownloader.h"
#import "PSReviewParser.h"
#import "PSRankParser.h"
#import "PSDropboxSync.h"
#import "PSUpdater.h"

@interface AppDelegate : NSObject <GrowlApplicationBridgeDelegate> {
	IBOutlet NSWindow *mainWindow;
	IBOutlet PSMenuController *menuController;
	IBOutlet NSButton *downloadButton;
	IBOutlet NSButton *importButton;
	IBOutlet NSProgressIndicator *progressIndicator;
	IBOutlet NSView *menuView;
	IBOutlet NSScrollView *scrollView;
	IBOutlet NSTextField *infoLabel;
	IBOutlet NSTextField *detailsLabel;
	IBOutlet NSMenuItem *importReportItem;
	IBOutlet NSMenuItem *downloadReportItem;
	IBOutlet NSMenuItem *downloadReviewItem;
    IBOutlet NSMenuItem *downloadRatingItem;
	IBOutlet NSMenuItem *downloadRanksItem;
	IBOutlet NSMenuItem *syncDropboxItem;
	IBOutlet NSButton *cancelButton;
	IBOutlet NSView *progressView;
	IBOutlet NSView *accessoryView;
	IBOutlet NSButton *trialPeriodLabel;
	PSPrefsController *preferencesController;
	NSDockTile *dockTile;
	NSTimer *timer;
    BOOL isNeedUpdateRanks;
    BOOL isNeedDownloadReports;
	BOOL isDownloading;
	PSReviewParser *reviewParser;
	PSRankParser *rankParser;
	PSReportDownloader *reportDownloader;
    PSDropboxSync *dropbox;
}

- (void)addTrialButton;
- (void)showProgressView;
- (void)hideProgressView;
- (void)startProgressAnimationWithTitle:(NSString *)title maxValue:(NSInteger)max indeterminate:(BOOL)indeterminate;
- (void)stopProgressAnimation;
- (void)incrementProgressIndicatorBy:(double)value;
- (void)changePhaseWithMessage:(NSString *)message;
- (void)startAnimation;
- (void)stopAnimation;
- (void)changeDetailsInfo:(NSString *)message;
- (void)disableDownloadItems;
- (void)enableDownloadItems;

- (IBAction)preferences:(id)sender;
- (IBAction)importReports:(id)sender;
- (IBAction)downloadReports:(id)sender;
- (IBAction)downloadReviews:(id)sender;
- (IBAction)updateRanks:(id)sender;
- (IBAction)cancelDownloads:(id)sender;
- (IBAction)syncDropbox:(id)sender;
- (IBAction)visitWebSite:(id)sender;
- (IBAction)buy:(id)sender;
- (IBAction)print:(id)sender;

@end
