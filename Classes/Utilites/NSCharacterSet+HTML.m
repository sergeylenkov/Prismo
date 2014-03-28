//
//  NSCharacterSet+HTML.m
//  Prismo
//
//  Created by Jan on 02.11.13.
//
//

#import "NSCharacterSet+HTML.h"

@implementation NSCharacterSet (HTML)

+ (NSCharacterSet *)newLineCharacterSetHTML
{
	// Strange New lines:
	//	Next Line, U+0085
	//	Form Feed, U+000C
	//	Line Separator, U+2028
	//	Paragraph Separator, U+2029
	
	static NSCharacterSet *_characterSet = nil;
	static dispatch_once_t onceToken;
	
	dispatch_once(&onceToken, ^{
		_characterSet = [[NSCharacterSet characterSetWithCharactersInString:
						  [NSString stringWithFormat:@"\n\r%C%C%C%C",
						   (unichar)0x0085,
						   (unichar)0x000C,
						   (unichar)0x2028,
						   (unichar)0x2029]] retain];
	}
	);
	
	return _characterSet;
}

+ (NSCharacterSet *)newLineAndWhitespaceCharacterSetHTML
{
	static NSCharacterSet *_characterSet = nil;
	static dispatch_once_t onceToken;
	
	dispatch_once(&onceToken, ^{
		NSMutableCharacterSet *mutableCharacterSet = [[NSCharacterSet newLineCharacterSetHTML] mutableCopy];
		[mutableCharacterSet addCharactersInString:@" \t"];
		
		_characterSet = [mutableCharacterSet copy];
	}
	);
	
	return _characterSet;
}

+ (NSCharacterSet *)stopCharacterSetHTML
{
	static NSCharacterSet *_characterSet = nil;
	static dispatch_once_t onceToken;
	
	dispatch_once(&onceToken, ^{
		NSMutableCharacterSet *mutableCharacterSet = [[NSCharacterSet newLineCharacterSetHTML] mutableCopy];
		[mutableCharacterSet addCharactersInString:@"< \t"];
		
		_characterSet = [mutableCharacterSet copy];
	}
	);
	
	return _characterSet;
}

+ (NSCharacterSet *)tagNameCharacterSetHTML
{
	static NSCharacterSet *_characterSet = nil;
	static dispatch_once_t onceToken;
	
	dispatch_once(&onceToken, ^{
		_characterSet = [[NSCharacterSet characterSetWithCharactersInString:@"abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ"] retain];
	}
	);
	
	return _characterSet;
}

@end
