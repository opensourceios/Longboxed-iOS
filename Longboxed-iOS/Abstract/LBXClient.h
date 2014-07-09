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
- (void)fetchIssuesCollectionWithDate:(NSDate *)date page:(int)page completion:(void (^)(NSArray*, RKObjectRequestOperation*, NSError*))completion;
- (void)fetchThisWeeksComicsWithCompletion:(void (^)(NSArray*, RKObjectRequestOperation*, NSError*))completion;
- (void)fetchIssueWithCompletion:(void (^)(LBXIssue*, RKObjectRequestOperation*, NSError*))completion;
- (void)fetchLogInWithCompletion:(void (^)(LBXUser*, RKObjectRequestOperation*, NSError*))completion;
- (void)fetchPullListWithCompletion:(void (^)(id, NSURLResponse*, NSError*))completion;
- (void)fetchBundlesWithCompletion:(void (^)(id, NSURLResponse*, NSError*))completion;
- (void)fetchIssuesWithDate:(NSString *)date withCompletion:(void (^)(id, NSURLResponse*, NSError*))completion;
- (void)fetchIssue:(int)issue withCompletion:(void (^)(LBXIssue*, RKObjectRequestOperation*, NSError*))completion;
- (void)fetchTitle:(int)title withCompletion:(void (^)(id, NSURLResponse*, NSError*))completion;
- (void)fetchTitlesWithCompletion:(void (^)(id, NSURLResponse*, NSError*))completion;
- (void)fetchPublishersWithCompletion:(void (^)(id, NSURLResponse*, NSError*))completion;
- (void)fetchPublisher:(int)publisher withCompletion:(void (^)(id, NSURLResponse*, NSError*))completion;

@end
