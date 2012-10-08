//
//  PXApplication.h
//  Plexer
//
//  Created by David Owens II on 9/30/12.
//  Copyright (c) 2012 Kiad Software. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <Cocoa/Cocoa.h>

OBJC_EXPORT NSString * const PXApplicationDisplayNameKey;
OBJC_EXPORT NSString * const PXApplicationLaunchPathKey;
OBJC_EXPORT NSString * const PXApplicationInstallPathKey;
OBJC_EXPORT NSString * const PXApplicationFilesToVirtualizeKey;
OBJC_EXPORT NSString * const PXApplicationFilesToCopyKey;

OBJC_EXPORT NSString const * PXApplicationWindowBoundsKey;
OBJC_EXPORT NSString const * PXShouldVirtualizeApplicationKey;
OBJC_EXPORT NSString const * PXVirtualizedApplicationLaunchPathKey;


@interface PXApplication : NSObject<NSCoding>

+ (NSArray *)supportedApplications;

- (NSRunningApplication *)launchWithOptions:(NSDictionary *)options;

@property (readonly) NSRunningApplication *runningApplication;

@property (readonly) NSString *displayName;
@property (readonly) NSString *installPath;
@property (readonly) NSString *launchPath;
@property (readonly) NSArray *itemsToVirtualize;
@property (readonly) NSArray *itemsToCopy;

@end
