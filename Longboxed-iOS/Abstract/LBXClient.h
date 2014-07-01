//
//  LBXClient.h
//  Longboxed-iOS
//
//  Created by johnrhickey on 6/29/14.
//  Copyright (c) 2014 Longboxed. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface LBXClient : NSObject

- (void)fetchThisWeeksComicsWithCompletion:(void (^)(id, NSURLResponse*, NSError*))completion;
- (void)fetchLogInWithCompletion:(void (^)(id, NSURLResponse*, NSError*))completion;
- (void)fetchPullListWithCompletion:(void (^)(id, NSURLResponse*, NSError*))completion;
- (void)fetchBundlesWithCompletion:(void (^)(id, NSURLResponse*, NSError*))completion;
- (void)fetchIssuesWithDate:(NSString *)date withCompletion:(void (^)(id, NSURLResponse*, NSError*))completion;
- (void)fetchIssue:(int)issue withCompletion:(void (^)(id, NSURLResponse*, NSError*))completion;
- (void)fetchTitle:(int)title withCompletion:(void (^)(id, NSURLResponse*, NSError*))completion;
- (void)fetchTitlesWithCompletion:(void (^)(id, NSURLResponse*, NSError*))completion;
- (void)fetchPublishersWithCompletion:(void (^)(id, NSURLResponse*, NSError*))completion;
- (void)fetchPublisher:(int)publisher withCompletion:(void (^)(id, NSURLResponse*, NSError*))completion;

@end
