#import "PrefsWindow.h"

@implementation PrefsWindow

- (void)keyDown: (NSEvent *) event {
    if ([event keyCode] == 53) {
        [self close];
	} else {
        [super keyDown: event];
	}
}

- (void)close {
    [self makeFirstResponder: nil];
    [super close];
}

@end
