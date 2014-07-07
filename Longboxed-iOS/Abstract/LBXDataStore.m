//
//  LBXDataStore.m
//  Longboxed-iOS
//
//  Created by johnrhickey on 6/29/14.
//  Copyright (c) 2014 Longboxed. All rights reserved.
//

#import "LBXDataStore.h"
#import "LBXClient.h"

NSString* const kWCDataStoreArchivedMatchesKey = @"kWCDataStoreArchivedMatchesKey";

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
    _pullListComicsArray = [self unarchivedObjectWithKey:kWCDataStoreArchivedMatchesKey];
}

- (void)prepareForTermination {
    [self archiveObject:self.pullListComicsArray key:kWCDataStoreArchivedMatchesKey];
    
    [[NSUserDefaults standardUserDefaults] synchronize];
}

- (void)fetchThisWeeksComics:(void (^)(NSArray*,NSError*))completion {
//    [self.client fetchThisWeeksComicsWithCompletion:^(id json, NSURLResponse *response, NSError *error) {
//        NSMutableArray *thisWeeksComics = [[NSMutableArray alloc] initWithArray:json[@"issues"]];
//        
//        if (completion) {
//            completion(thisWeeksComics, error);
//        }
//    }];
}

- (void)fetchLoginStatusCode:(void (^)(int,NSError*))completion {
    [self.client fetchLogInWithCompletion:^(id json, NSURLResponse *response, NSError *error) {
        NSHTTPURLResponse* httpResponse = (NSHTTPURLResponse*)response;
        int responseStatusCode = (int)[httpResponse statusCode];
        
        if (completion) {
            completion(responseStatusCode, error);
        }
    }];
}

- (void)fetchPullList:(void (^)(NSArray*,NSError*))completion {
    [self.client fetchPullListWithCompletion:^(id json, NSURLResponse *response, NSError *error) {
        NSMutableArray *pullListComics = [[NSMutableArray alloc] initWithArray:json[@"pull_list"]];
        if (completion) {
            completion(pullListComics, error);
        }
    }];
}

- (void)fetchBundles:(void (^)(NSArray*,NSError*))completion {
    [self.client fetchBundlesWithCompletion:^(id json, NSURLResponse *response, NSError *error) {
        NSMutableArray *pullListComics = [[NSMutableArray alloc] initWithArray:json[@"bundles"][0][@"issues"]];
        if (completion) {
            completion(pullListComics, error);
        }
    }];
}

- (void)fetchIssue:(int)issue completion:(void (^)(NSDictionary*,NSError*))completion {
//    [self.client fetchIssue:issue withCompletion:^(id json, NSURLResponse *response, NSError *error) {
//        if (completion) {
//            completion(json, error);
//        }
//    }];
}

- (void)fetchTitle:(int)title completion:(void (^)(NSDictionary*,NSError*))completion {
    [self.client fetchTitle:title withCompletion:^(id json, NSURLResponse *response, NSError *error) {
        if (completion) {
            completion(json, error);
        }
    }];
}

- (void)fetchIssuesWithDate:(NSString *)date completion:(void (^)(NSDictionary*,NSError*))completion {
    [self.client fetchIssuesWithDate:date withCompletion:^(id json, NSURLResponse *response, NSError *error) {
        if (completion) {
            completion(json, error);
        }
    }];
}

- (void)fetchTitle:(void (^)(NSDictionary*,NSError*))completion {
    [self.client fetchTitlesWithCompletion:^(id json, NSURLResponse *response, NSError *error) {
        if (completion) {
            completion(json, error);
        }
    }];
}

- (void)fetchpublisher:(int)publisher completion:(void (^)(NSDictionary*,NSError*))completion {
    [self.client fetchPublisher:publisher withCompletion:^(id json, NSURLResponse *response, NSError *error) {
        if (completion) {
            completion(json, error);
        }
    }];
}

- (void)fetchPublishers:(void (^)(NSDictionary*,NSError*))completion {
    [self.client fetchPublishersWithCompletion:^(id json, NSURLResponse *response, NSError *error) {
        if (completion) {
            completion(json, error);
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
