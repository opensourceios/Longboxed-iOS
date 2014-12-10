//
//  LBXUser.h
//  Longboxed-iOS
//
//  Created by johnrhickey on 7/7/14.
//  Copyright (c) 2014 Longboxed. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <RestKit/CoreData.h>

@interface LBXUser : NSManagedObject

@property (nonatomic, retain) NSString *email;
@property (nonatomic, retain) NSString *firstName;
@property (nonatomic, retain) NSNumber *userID;
@property (nonatomic, retain) NSString *lastName;
@property (nonatomic, retain) NSArray *roles;

@end
