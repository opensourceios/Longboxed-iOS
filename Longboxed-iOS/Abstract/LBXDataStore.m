//
//  LBXDataStore.m
//  Longboxed-iOS
//
//  Created by johnrhickey on 6/29/14.
//  Copyright (c) 2014 Longboxed. All rights reserved.
//

#import "LBXDataStore.h"
#import "LBXClient.h"

NSString * const kWCDataStoreArchivedMatchesKey = @"kWCDataStoreArchivedMatchesKey";

@interface LBXDataStore ()

@property (nonatomic) LBXClient *client;

@end

@implementation LBXDataStore

+ (instancetype)sharedStore {
    static id _sharedStore = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _sharedStore = [[self alloc] init];
    });
    return _sharedStore;
}

- (instancetype)init {
    if (self = [super init]) {
        _client = [[LBXClient alloc] init];
        
        [self restorePersistedProperties];
        
        // immediately get the latest match information
        [self fetchThisWeeksComics:nil];
    }
    return self;
}

- (void)restorePersistedProperties {
    _comics = [self unarchivedObjectWithKey:kWCDataStoreArchivedMatchesKey];
}

- (void)prepareForTermination {
    [self archiveObject:self.comics key:kWCDataStoreArchivedMatchesKey];
    
    [[NSUserDefaults standardUserDefaults] synchronize];
}

- (void)fetchThisWeeksComics:(void (^)(NSArray*,NSError*))completion
{
    [self.client fetchThisWeeksComicsWithCompletion:^(id json, NSError *error) {
        NSMutableArray *comics = [[NSMutableArray alloc] initWithArray:json[@"issues"]];
        self.comics = comics;
        
        if (completion) {
            completion(comics, error);
        }
    }];
}

- (void)fetchLogin:(void (^)(NSArray*,NSError*))completion
{
    [self.client fetchLogInWithCompletion:^(id json, NSError *error) {
        //NSLog(@"%@", json);
        //NSMutableArray *comics = [[NSMutableArray alloc] initWithArray:json[@"issues"]];
        //self.comics = comics;
        
//        if (completion) {
//            completion(comics, error);
//        }
    }];
}

- (void)fetchPullList:(void (^)(NSArray*,NSError*))completion
{
    [self.client fetchPullListWithCompletion:^(id json, NSError *error) {
        NSMutableArray *comics = [[NSMutableArray alloc] initWithArray:json[@"pull_list"]];
        self.comics = comics;
        
        if (completion) {
            completion(comics, error);
        }
    }];
}


- (id)unarchivedObjectWithKey:(NSString *)key {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSData *data = [defaults objectForKey:key];
    id object;
    
    if ([data length]) {
        object = [NSKeyedUnarchiver unarchiveObjectWithData:data];
    }
    
    return object;
}

// NOTE: [NSUserDefaults synchronize] is not called in this method
- (void)archiveObject:(id)object key:(NSString *)key {
    NSAssert([object conformsToProtocol:@protocol(NSCoding)], @"Object %@ does not conform to NSCoding",object);
    
    NSData *data = [NSKeyedArchiver archivedDataWithRootObject:object];
    
    if ([data length]) {
        NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
        [defaults setObject:data forKey:key];
    }
}


@end
