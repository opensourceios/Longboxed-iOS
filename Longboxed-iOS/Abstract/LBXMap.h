//
//  LBXMapper.h
//  Longboxed-iOS
//
//  Created by johnrhickey on 7/8/14.
//  Copyright (c) 2014 Longboxed. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <RestKit.h>

@interface LBXMap : NSObject

- (RKObjectMapping *)bundleMapping;
- (RKObjectMapping *)userMapping;
- (RKObjectMapping *)titleMapping;
- (RKObjectMapping *)publisherMapping;
- (RKObjectMapping *)issueMapping;


@end
