//
//  LBXPullList.m
//  Longboxed-iOS
//
//  Created by johnrhickey on 8/3/14.
//  Copyright (c) 2014 Longboxed. All rights reserved.
//

#import "LBXPullListTitle.h"
#import "LBXBundle.h"
#import "NSDate+DateUtilities.h"
#import "LBXServices.h"
#import "LBXLogging.h"

@implementation LBXPullListTitle

@dynamic titleID;
@dynamic issueCount;
@dynamic name;
@dynamic publisher;
@dynamic subscribers;
@dynamic latestIssue;

#pragma mark Instance Methods

+ (void)createWithTitleID:(NSNumber *)titleID withContext:(NSManagedObjectContext *)context {
    dispatch_async(dispatch_get_main_queue(), ^{
        LBXTitle *title = [LBXTitle MR_findFirstByAttribute:@"titleID" withValue:titleID];
        [self createWithTitle:title withContext:context];
    });
}

+ (void)createWithTitle:(LBXTitle *)title withContext:(NSManagedObjectContext *)context {
    dispatch_async(dispatch_get_main_queue(), ^{
        LBXPullListTitle *pTitle = [LBXPullListTitle MR_createEntityInContext:context];
        pTitle.titleID = title.titleID;
        pTitle.issueCount = title.issueCount;
        pTitle.name = title.name;
        pTitle.publisher = title.publisher;
        pTitle.subscribers = title.subscribers;
        pTitle.latestIssue = title.latestIssue;
        
        // Remove the title from the latest bundle
        LBXBundle *bundle = [LBXBundle MR_findFirstWithPredicate:[LBXServices thisWeekPredicateWithParentCheck:NO] inContext:context];
        [context MR_saveWithBlockAndWait:^(NSManagedObjectContext *context) {
            [LBXLogging logMessage:[NSString stringWithFormat:@"Add - Previous Issues Count : %lu", (unsigned long)bundle.issues.count]];
            if (bundle) {
                if (pTitle.latestIssue.isBeingReleasedThisWeek) {
                    NSMutableSet *mutableSet = [NSMutableSet setWithSet:bundle.issues];
                    [mutableSet addObject:pTitle.latestIssue];
                    bundle.issues = mutableSet;
                }
            }
            
            [LBXLogging logMessage:[NSString stringWithFormat:@"Add - Saving bundle with Issues Count : %lu", (unsigned long)bundle.issues.count]];
        }];
        
        bundle = [LBXBundle MR_findFirstWithPredicate:[LBXServices thisWeekPredicateWithParentCheck:NO] inContext:context];
        [LBXLogging logMessage:[NSString stringWithFormat:@"Add - After Save Bundle Issues Count: %lu", (unsigned long)bundle.issues.count]];
    });
}

+ (void)deleteTitleID:(NSNumber *)titleID fromDataStoreWithContext:(NSManagedObjectContext *)context {
    dispatch_async(dispatch_get_main_queue(), ^{
        NSPredicate *predicate = [NSPredicate predicateWithFormat:@"(titleID == %@)", titleID];
        NSArray *titles = [LBXPullListTitle MR_findAllWithPredicate:predicate inContext:context];
        for (LBXPullListTitle *title in titles) {
            [title deleteFromDataStoreWithContext:context];
        }
    });
}

#pragma mark Class Methods

- (NSString *)description
{
    return [NSString stringWithFormat:@"Title: %@\nID: %@\nPublisher: %@\nSubscribers: %@\nIssue Count: %@", self.name, self.titleID, self.publisher.name, self.subscribers, self.issueCount];
}

- (void)deleteFromDataStoreWithContext:(NSManagedObjectContext *)context {
    dispatch_async(dispatch_get_main_queue(), ^{
        LBXPullListTitle *title = [LBXPullListTitle MR_findFirstByAttribute:@"titleID" withValue:self.titleID inContext:context];
        [context MR_saveWithBlockAndWait:^(NSManagedObjectContext *context) {
            [title MR_deleteEntity];
        }];
        
        // Remove the title from the this weeks' bundle
        LBXBundle *bundle = [LBXBundle MR_findFirstWithPredicate:[LBXServices thisWeekPredicateWithParentCheck:NO] inContext:context];
        
        [LBXLogging logMessage:[NSString stringWithFormat:@"Delete - Previous Issues Count : %lu", (unsigned long)bundle.issues.count]];
        [context MR_saveWithBlockAndWait:^(NSManagedObjectContext *context) {
            if (bundle) {
                //LBXBundle *latestBundle = bundleArray.firstObject;
                NSMutableSet *mutableSet = [NSMutableSet setWithSet:bundle.issues];
                for (LBXIssue *issue in bundle.issues) {
                    if ([issue.title.titleID isEqualToNumber:self.titleID]) {
                        [mutableSet removeObject:issue];
                    }
                }
                bundle.issues = mutableSet;
            }
            
            [LBXLogging logMessage:[NSString stringWithFormat:@"Delete - Saving bundle with Issues Count : %lu", (unsigned long)bundle.issues.count]];
        }];
        
        [LBXLogging logMessage:[NSString stringWithFormat:@"Delete - After Save Bundle Issues Count: %lu", (unsigned long)[LBXBundle MR_findFirstWithPredicate:[LBXServices thisWeekPredicateWithParentCheck:NO] inContext:context].issues.count]];
    });
}

@end
