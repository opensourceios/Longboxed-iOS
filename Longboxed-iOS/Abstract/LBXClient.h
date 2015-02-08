//
//  LBXClient.h
//  Longboxed-iOS
//
//  Created by johnrhickey on 6/29/14.
//  Copyright (c) 2014 Longboxed. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <RestKit.h>
#import <RestKit/CoreData.h>

#import "LBXTitle.h"
#import "LBXIssue.h"
#import "LBXPublisher.h"
#import "LBXUser.h"
#import "LBXBundle.h"

@interface LBXClient : NSObject

+ (void)setAuth;

// Issues
- (void)fetchIssuesCollectionWithDate:(NSDate *)date page:(NSNumber *)page completion:(void (^)(NSArray*, RKObjectRequestOperation*, NSError*))completion;
- (void)fetchThisWeeksComicsWithPage:(NSNumber *)page completion:(void (^)(NSArray*, RKObjectRequestOperation *, NSError*))completion;
- (void)fetchNextWeeksComicsWithPage:(NSNumber *)page completion:(void (^)(NSArray*, RKObjectRequestOperation *, NSError*))completion;
- (void)fetchIssue:(NSNumber *)issueID withCompletion:(void (^)(LBXIssue*, RKObjectRequestOperation*, NSError*))completion;
- (void)fetchPopularIssuesWithCompletion:(void (^)(NSArray*, RKObjectRequestOperation*, NSError*))completion;
- (void)fetchPopularIssuesWithDate:(NSDate *)date completion:(void (^)(NSArray*, RKObjectRequestOperation*, NSError*))completion;

// Titles
- (void)fetchTitleCollectionWithCompletion:(void (^)(NSArray*, RKObjectRequestOperation*, NSError*))completion;
- (void)fetchTitle:(NSNumber *)titleID withCompletion:(void (^)(LBXTitle*, RKObjectRequestOperation*, NSError*))completion;
- (void)fetchIssuesForTitle:(NSNumber *)titleID page:(NSNumber *)page withCompletion:(void (^)(NSArray*, RKObjectRequestOperation*, NSError*))completion;
- (void)fetchIssuesForTitle:(NSNumber *)titleID page:(NSNumber *)page count:(NSNumber *)count withCompletion:(void (^)(NSArray*, RKObjectRequestOperation*, NSError*))completion;
- (void)fetchAutocompleteForTitle:(NSString*)title withCompletion:(void (^)(NSArray*, RKObjectRequestOperation*, NSError*))completion;

// Publishers
- (void)fetchPublishersWithPage:(NSNumber *)page completion:(void (^)(NSArray *, RKObjectRequestOperation*, NSError*))completion;
- (void)fetchPublisher:(NSNumber *)publisherID withCompletion:(void (^)(LBXPublisher*, RKObjectRequestOperation*, NSError*))completion;
- (void)fetchTitlesForPublisher:(NSNumber*)publisherID page:(NSNumber *)page withCompletion:(void (^)(NSArray*, RKObjectRequestOperation*, NSError*))completion;

// Users
- (void)registerWithEmail:(NSString*)email password:(NSString *)password passwordConfirm:(NSString *)passwordConfirm withCompletion:(void (^)(NSDictionary*, AFHTTPRequestOperation*, NSError*))completion;
- (void)deleteAccountWithCompletion:(void (^)(NSDictionary*, AFHTTPRequestOperation*, NSError*))completion;
- (void)fetchLogInWithCompletion:(void (^)(LBXUser*, RKObjectRequestOperation*, NSError*))completion;
- (void)fetchPullListWithCompletion:(void (^)(NSArray*, RKObjectRequestOperation*, NSError*))completion;
- (void)addTitleToPullList:(NSNumber*)titleID withCompletion:(void (^)(NSArray*, AFHTTPRequestOperation*, NSError*))completion;
- (void)removeTitleFromPullList:(NSNumber*)titleID withCompletion:(void (^)(NSArray*, AFHTTPRequestOperation*, NSError*))completion;
- (void)fetchBundleResourcesWithPage:(NSNumber *)page completion:(void (^)(NSArray*, RKObjectRequestOperation*, NSError*))completion;
- (void)fetchLatestBundleWithCompletion:(void (^)(LBXBundle*, RKObjectRequestOperation*, NSError*))completion;
- (void)fetchBundleResourcesWithDate:(NSDate *)date page:(NSNumber*)page count:(NSNumber *)count completion:(void (^)(NSArray *, RKObjectRequestOperation *, NSError *))completion;



@end
