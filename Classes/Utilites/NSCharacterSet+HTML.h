//
//  NSCharacterSet+HTML.h
//  Prismo
//
//  Created by Jan on 02.11.13.
//
//

#import <Foundation/Foundation.h>

@interface NSCharacterSet (HTML)

+ (NSCharacterSet *)newLineCharacterSetHTML;
+ (NSCharacterSet *)newLineAndWhitespaceCharacterSetHTML;
+ (NSCharacterSet *)stopCharacterSetHTML;
+ (NSCharacterSet *)tagNameCharacterSetHTML;

@end
