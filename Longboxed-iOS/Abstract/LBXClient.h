//
//  LBXClient.h
//  Longboxed-iOS
//
//  Created by johnrhickey on 6/29/14.
//  Copyright (c) 2014 Longboxed. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface LBXClient : NSObject

- (void)fetchThisWeeksComicsWithCompletion:(void (^)(id,NSError*))completion;

@end
