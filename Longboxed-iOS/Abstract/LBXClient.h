//
//  LBXClient.h
//  Longboxed-iOS
//
//  Created by johnrhickey on 6/29/14.
//  Copyright (c) 2014 Longboxed. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <RestKit.h>

#import "LBXTitle.h"
#import "LBXIssue.h"
#import "LBXPublisher.h"
#import "LBXUser.h"

@interface LBXClient : NSObject

// Issues
- (void)fetchIssuesCollectionWithDate:(NSDate *)date page:(NSNumber *)page completion:(void (^)(NSArray*, RKObjectRequestOperation*, NSError*))completion;
- (void)fetchThisWeeksComicsWithCompletion:(void (^)(NSArray*, RKObjectRequestOperation*, NSError*))completion;
- (void)fetchIssue:(NSNumber *)issueID withCompletion:(void (^)(LBXIssue*, RKObjectRequestOperation*, NSError*))completion;
// Titles
- (void)fetchTitlesWithCompletion:(void (^)(NSArray*, RKObjectRequestOperation*, NSError*))completion;
- (void)fetchTitle:(NSNumber *)titleID withCompletion:(void (^)(LBXTitle*, RKObjectRequestOperation*, NSError*))completion;
- (void)fetchIssuesForTitle:(NSNumber *)titleID withCompletion:(void (^)(NSArray*, RKObjectRequestOperation*, NSError*))completion;
// Publishers
- (void)fetchPublishersWithCompletion:(void (^)(NSArray *, RKObjectRequestOperation*, NSError*))completion;
- (void)fetchPublisher:(NSNumber *)publisherID withCompletion:(void (^)(LBXPublisher*, RKObjectRequestOperation*, NSError*))completion;
- (void)fetchTitlesForPublisher:(NSNumber *)publisherID withCompletion:(void (^)(NSArray*, RKObjectRequestOperation*, NSError*))completion;
// Users
- (void)fetchLogInWithCompletion:(void (^)(LBXUser*, RKObjectRequestOperation*, NSError*))completion;
- (void)fetchPullListWithCompletion:(void (^)(NSArray*, RKObjectRequestOperation*, NSError*))completion;
- (void)addTitleToPullList:(NSNumber*)titleID withCompletion:(void (^)(NSArray*, AFHTTPRequestOperation*, NSError*))completion;
- (void)removeTitleFromPullList:(NSNumber*)titleID withCompletion:(void (^)(NSArray*, AFHTTPRequestOperation*, NSError*))completion;

- (void)fetchBundlesWithCompletion:(void (^)(id, NSURLResponse*, NSError*))completion;



@end
