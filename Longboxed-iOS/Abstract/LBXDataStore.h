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

@property (nonatomic, strong) NSArray *comics;

- (void)fetchThisWeeksComics:(void (^)(NSArray*,NSError*))completion;

- (void)prepareForTermination;

@end
