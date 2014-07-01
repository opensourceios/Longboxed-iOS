//
//  LBXDataStore.h
//  Longboxed-iOS
//
//  Created by johnrhickey on 6/29/14.
//  Copyright (c) 2014 Longboxed. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface LBXDataStore : NSObject

+ (instancetype)sharedStore;

@property (nonatomic, strong) NSArray *pullListComicsArray;
@property (nonatomic, strong) NSArray *thisWeekComicsArray;

- (void)fetchThisWeeksComics:(void (^)(NSArray*,NSError*))completion;
- (void)fetchLoginStatusCode:(void (^)(int,NSError*))completion;
- (void)fetchPullList:(void (^)(NSArray*,NSError*))completion;
- (void)fetchBundles:(void (^)(NSArray*,NSError*))completion;
- (void)fetchIssuesWithDate:(NSString *)date completion:(void (^)(NSDictionary*,NSError*))completion;
- (void)fetchIssue:(int)issue completion:(void (^)(NSDictionary*,NSError*))completion;
- (void)fetchTitle:(int)title completion:(void (^)(NSDictionary*,NSError*))completion;
- (void)fetchTitle:(void (^)(NSDictionary*,NSError*))completion;
- (void)fetchpublisher:(int)publisher completion:(void (^)(NSDictionary*,NSError*))completion;
- (void)fetchPublishers:(void (^)(NSDictionary*,NSError*))completion;

- (void)prepareForTermination;

@end
