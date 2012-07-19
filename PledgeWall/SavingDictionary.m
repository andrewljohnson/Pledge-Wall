//
//  SavingDictionary.m
//  TrailTracker
//
//  Created by Anna Hentzel on 3/11/11.
//  Copyright 2011 TrailBehind, Inc. All rights reserved.
//

#import "SavingDictionary.h"


@implementation SavingDictionary
@synthesize filePath, dict;

- (id) initWithPath:(NSString*) path {
  if (![[NSFileManager defaultManager] fileExistsAtPath:path]) {
    dict = [[NSMutableDictionary alloc] init]; 
  } else {
    dict = [[NSMutableDictionary alloc] initWithContentsOfFile:path];
  }
  self.filePath = path;
  return self;
}


+ (void) checkDirectory:(NSString*) filePath {
  
  if(![[NSFileManager defaultManager] fileExistsAtPath:filePath isDirectory:nil]) {
    if(![[NSFileManager defaultManager] createDirectoryAtPath:filePath withIntermediateDirectories:YES attributes:nil error:nil])
      NSLog(@"Error: Create folder failed");
  } 
  
}


NSString* privateDocumentsDirectory() {
  static NSString* dir = nil;
  if (!dir) {
    
    NSArray *paths = NSSearchPathForDirectoriesInDomains (NSLibraryDirectory, NSUserDomainMask, YES);
    dir = [[[paths objectAtIndex:0] stringByAppendingString:@"/Private Documents"] retain];	
    [SavingDictionary checkDirectory:dir];
    
  }
  return dir;
}


- (id) initWithClass:(Class) c {
  NSString *path = [privateDocumentsDirectory() stringByAppendingPathComponent:NSStringFromClass(c)];
  return [self initWithPath:path];
}


- (id) objectForKey:(id)aKey {
  if (aKey) {
    return [dict objectForKey:aKey];    
  }
  return nil;
}


- (void) setObject:(id)anObject forKey:(id)aKey {
  if (anObject && aKey) {
    [dict setObject:anObject forKey:aKey];
    [dict writeToFile:filePath atomically:YES];
  }
}


- (void) removeObjectForKey:(id)aKey {
  if (aKey) {
    [dict removeObjectForKey:aKey];
    [dict writeToFile:filePath atomically:YES];    
  }
}


- (void) clearDictionary {
  [[NSFileManager defaultManager] removeItemAtPath:filePath error:nil];
  [dict release];
  dict = [[NSMutableDictionary alloc] init];
}


- (NSArray *)allKeys {
  return [dict allKeys];
}


- (NSArray *)allValues {
  return [dict allValues];
}


- (void) dealloc {
  [filePath release];
  [dict release];
  [super dealloc];
}


- (NSString*)description {
  return [NSString stringWithFormat:@"%@", dict];
}
  
@end
