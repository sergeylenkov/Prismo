/*
	This file is part of the PolKit library.
	Copyright (C) 2008-2009 Pierre-Olivier Latour <info@pol-online.net>
	
	This program is free software: you can redistribute it and/or modify
	it under the terms of the GNU General Public License as published by
	the Free Software Foundation, either version 3 of the License, or
	(at your option) any later version.
	
	This program is distributed in the hope that it will be useful,
	but WITHOUT ANY WARRANTY; without even the implied warranty of
	MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
	GNU General Public License for more details.
	
	You should have received a copy of the GNU General Public License
	along with this program.  If not, see <http://www.gnu.org/licenses/>.
*/

#import <zlib.h>

#import "NSData+GZip.h"

#define kMemoryChunkSize		1024
#define kFileChunkSize			(128 * 1024) //128Kb

@implementation NSData (GZip)

- (NSData*) compressGZip
{
	NSUInteger		length = [self length];
	int				windowBits = 15 + 16, //Default + gzip header instead of zlib header
					memLevel = 8, //Default
					retCode;
	NSMutableData*	result;
	z_stream		stream;
	unsigned char	output[kMemoryChunkSize];
	uInt			gotBack;
	
	if((length == 0) || (length > UINT_MAX)) //FIXME: Support 64 bit inputs
	return nil;

	bzero(&stream, sizeof(z_stream));
	stream.avail_in = (uInt)length;
	stream.next_in = (unsigned char*)[self bytes];
	
	retCode = deflateInit2(&stream, Z_BEST_COMPRESSION, Z_DEFLATED, windowBits, memLevel, Z_DEFAULT_STRATEGY);
	if(retCode != Z_OK) {
		NSLog(@"%s: deflateInit2() failed with error %i", __FUNCTION__, retCode);
		return nil;
	}
	
	result = [NSMutableData dataWithCapacity:(length / 4)];
	do {
		stream.avail_out = kMemoryChunkSize;
		stream.next_out = output;
		retCode = deflate(&stream, Z_FINISH);
		if((retCode != Z_OK) && (retCode != Z_STREAM_END)) {
			NSLog(@"%s: deflate() failed with error %i", __FUNCTION__, retCode);
			deflateEnd(&stream);
			return nil;
		}
		gotBack = kMemoryChunkSize - stream.avail_out;
		if(gotBack > 0)
		[result appendBytes:output length:gotBack];
	} while (retCode == Z_OK);
	deflateEnd(&stream);
	
	if((stream.avail_in != 0) || (retCode != Z_STREAM_END)) {
		NSLog(@"%s: Internal error during deflate()", __FUNCTION__);
		return nil;
	}
	
	return result;
}

- (NSData*) decompressGZip
{
	NSUInteger		length = [self length];
	int				windowBits = 15 + 16, //Default + gzip header instead of zlib header
					retCode;
	unsigned char	output[kMemoryChunkSize];
	uInt			gotBack;
	NSMutableData*	result;
	z_stream		stream;
	uLong			size;
	
	if((length == 0) || (length > UINT_MAX)) //FIXME: Support 64 bit inputs
	return nil;
	
	//FIXME: Remove support for original implementation of -compressGZip which wasn't generating real gzip data 
	if((length >= sizeof(unsigned int)) && ((*((unsigned char*)[self bytes]) != 0x1F) || (*((unsigned char*)[self bytes] + 1) != 0x8B))) {
		size = NSSwapBigIntToHost(*((unsigned int*)[self bytes]));
		result = (size < 0x40000000 ? [NSMutableData dataWithLength:size] : nil); //HACK: Prevent allocating more than 1 Gb
		if(result && (uncompress([result mutableBytes], &size, (unsigned char*)[self bytes] + sizeof(unsigned int), [self length] - sizeof(unsigned int)) != Z_OK))
		result = nil;
		return result;
	}
	
	bzero(&stream, sizeof(z_stream));
	stream.avail_in = (uInt)length;
	stream.next_in = (unsigned char*)[self bytes];
	
	retCode = inflateInit2(&stream, windowBits);
	if(retCode != Z_OK) {
		NSLog(@"%s: inflateInit2() failed with error %i", __FUNCTION__, retCode);
		return nil;
	}
	
	result = [NSMutableData dataWithCapacity:(length * 4)];
	do {
		stream.avail_out = kMemoryChunkSize;
		stream.next_out = output;
		retCode = inflate(&stream, Z_NO_FLUSH);
		if ((retCode != Z_OK) && (retCode != Z_STREAM_END)) {
			NSLog(@"%s: inflate() failed with error %i", __FUNCTION__, retCode);
			inflateEnd(&stream);
			return nil;
		}
		gotBack = kMemoryChunkSize - stream.avail_out;
		if(gotBack > 0)
		[result appendBytes:output length:gotBack];
	} while (retCode == Z_OK);
	inflateEnd(&stream);
	
	if((stream.avail_in != 0) || (retCode != Z_STREAM_END)) {
		NSLog(@"%s: Internal error during inflate()", __FUNCTION__);
		return nil;
	}
	
	return result;
}

- (id) initWithGZipFile:(NSString*)path
{
	const char*		string = [path UTF8String];
	BOOL			success = NO;
	gzFile			file;
	int				result;
	size_t			length;
	char*			buffer;
	
	file = gzopen(string, "r");
	if(file != NULL) {
		length = kFileChunkSize;
		buffer = malloc(length);
		while(1) {
			result = gzread(file, buffer + length - kFileChunkSize, kFileChunkSize);
			if(result < 0)
			break;
			if(result < kFileChunkSize) {
				length -= kFileChunkSize - result;
				buffer = realloc(buffer, length);
				break;
			}
			length += kFileChunkSize;
			buffer = realloc(buffer, length);
		}
		
		if(result >= 0) {
			if((self = [self initWithBytesNoCopy:buffer length:length freeWhenDone:YES]))
			success = YES;
			else
			free(buffer);
		}
		else
		free(buffer);
		
		gzclose(file);
	}
	
	if(success == NO) {
		[self release];
		return nil;
	}
	
	return self;
}

- (BOOL) writeToGZipFile:(NSString*)path
{
	const char*		string = [path UTF8String];
	BOOL			success = NO;
	gzFile			file;
	
	file = gzopen(string, "w9f"); //Stategy is f, h or R - 9 is Z_BEST_COMPRESSION
	if(file == NULL)
	return NO;
	
	if(gzwrite(file, [self bytes], [self length]) == [self length])
	success = YES;
	
	gzclose(file);
	
	if(success == NO)
	unlink(string);
	
	return success;
}

@end
