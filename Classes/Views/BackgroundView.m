#import "BackgroundView.h"

@implementation BackgroundView

- (id)initWithFrame:(NSRect)frame {
    self = [super initWithFrame:frame];
	
    if (self) {
        // Initialization code here.
    }
	
    return self;
}

- (void)drawRect:(NSRect)rect {
	[[NSColor whiteColor] set];
	NSRectFill(rect);
}

@end
