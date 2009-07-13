//
//  KSApplicationsDataSource.m
//  Plexer
//
//  Created by David Owens II on 7/7/09.
//  Copyright 2009 Kiad Software. All rights reserved.
//

#import "KSApplicationsDataSource.h"
#import "KSConfiguration.h"


@implementation KSApplicationsDataSource


-(NSInteger)numberOfRowsInTableView:(NSTableView*)aTableView {
    if ([configurationController configurationSelected] == NO)
        return 0;
    
    NSString* configurationName = [[configurationController configurationsPopUp] titleOfSelectedItem];
    KSConfiguration* config = [[userSettings configurations] valueForKey:configurationName];
    
    return [[config applications] count];
    
    return 0;
}

-(id)tableView:(NSTableView*)aTableView objectValueForTableColumn:(NSTableColumn*)aTableColumn row:(NSInteger)rowIndex {
    NSString* configurationName = [[configurationController configurationsPopUp] titleOfSelectedItem];
    KSConfiguration* config = [[userSettings configurations] valueForKey:configurationName];
    NSArray* applications = [config applications];
    
    if ([[aTableColumn identifier] isEqualToString:@"position"] == YES)
        return [NSString stringWithFormat:@"%d", (rowIndex + 1)];
    else if ([[aTableColumn identifier] isEqualToString:@"title"] == YES) {
        NSLog(@"Returning friendly name for '@'", [applications objectAtIndex:rowIndex]);
        NSString* str = [[applications objectAtIndex:rowIndex] stringByDeletingPathExtension];            
        return  [[str pathComponents] lastObject];
    }
    else if ([[aTableColumn identifier] isEqualToString:@"path"] == YES)
        return [applications objectAtIndex:rowIndex];
    
    return nil;
}

@end
