//
//  LBXClient.m
//  Longboxed-iOS
//
//  Created by johnrhickey on 6/29/14.
//  Copyright (c) 2014 Longboxed. All rights reserved.
//

#import "LBXClient.h"
#import "NSData+Base64.h"

#import <UICKeyChainStore.h>

@interface LBXClient()

@property (nonatomic) NSURLSession *session;

@end

@implementation LBXClient

- (instancetype)init {
    if (self = [super init]) {
        _session = [NSURLSession sessionWithConfiguration:[NSURLSessionConfiguration defaultSessionConfiguration]];
    }
    return self;
}

- (void)fetch:(NSString *)location withCredentials:(BOOL)credentials completion:(void (^)(id, NSURLResponse*, NSError*))completion {
    [self.class setNetworkActivityIndicatorVisible:YES];
    
    NSString *urlString = [NSString stringWithFormat:@"http://www.longboxed.com/api/v1/%@",location];
    
    NSURL *url = [NSURL URLWithString:urlString];
    
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
    
    // Auth if necessary
    if (credentials) {
        UICKeyChainStore *store = [UICKeyChainStore keyChainStore];
        NSString *authStr = [NSString stringWithFormat:@"%@:%@", store[@"username"], store[@"password"]];
        NSData *authData = [authStr dataUsingEncoding:NSASCIIStringEncoding];
        NSString *authValue = [NSString stringWithFormat:@"Basic %@", [authData base64EncodingWithLineLength:80]];
        [request setValue:authValue forHTTPHeaderField:@"Authorization"];
    }
    
    NSURLSessionDataTask *task = [self.session dataTaskWithRequest:request completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
        [self.class setNetworkActivityIndicatorVisible:NO];
        
        if (error) {
            NSLog(@"%@",error);
            
            if (completion) {
                completion(nil, response, error);
            }
        }
        else {
            NSError *error2 = nil;
            id json = [NSJSONSerialization JSONObjectWithData:data options:kNilOptions error:&error];
            
            if (error2) {
                NSLog(@"%@",error2);
            }
            if (completion) {
                completion(json, response, error2);
            }
        }
    }];
    [task resume];
}


//- (void)fetchWithMapping:(RKObjectMapping *)mapping andPathPattern(NSString *)pathPattern
//{
//    
//}


- (RKObjectMapping *)getTitleMapping
{
    RKObjectMapping* titleMapping = [RKObjectMapping mappingForClass:[LBXTitle class]];
    [titleMapping addAttributeMappingsFromDictionary:@{ @"id": @"titleID",
                                                        @"name": @"name"
                                                        }];
    return titleMapping;
}

- (RKObjectMapping *)getPublisherMapping
{
    RKObjectMapping* publisherMapping = [RKObjectMapping mappingForClass:[LBXPublisher class]];
    [publisherMapping addAttributeMappingsFromDictionary:@{ @"id": @"publisherID",
                                                            @"issue_count": @"issueCount",
                                                            @"name": @"name",
                                                            @"title_count": @"titleCount"
                                                            }];
    return publisherMapping;
}

- (RKObjectMapping *)getIssueMapping
{
    RKObjectMapping* issueMapping = [RKObjectMapping mappingForClass:[LBXIssue class]];
    [issueMapping addAttributeMappingsFromDictionary:@{ @"complete_title": @"completeTitle",
                                                        @"cover_image": @"coverImage",
                                                        @"description": @"issueDescription",
                                                        @"diamond_id": @"diamondID",
                                                        @"id": @"longboxedID",
                                                        @"issue_number": @"issueNumber",
                                                        @"price": @"price",
                                                        @"release_date": @"releaseDate"
                                                        }];
    
    RKObjectMapping *publisherMapping = [self getPublisherMapping];
    RKObjectMapping *titleMapping = [self getTitleMapping];
    
    [issueMapping addPropertyMapping:[RKRelationshipMapping relationshipMappingFromKeyPath:@"publisher"
                                                                                 toKeyPath:@"publisher"
                                                                               withMapping:publisherMapping]];
    
    [issueMapping addPropertyMapping:[RKRelationshipMapping relationshipMappingFromKeyPath:@"title"
                                                                                 toKeyPath:@"title"
                                                                               withMapping:titleMapping]];
    
    
    return issueMapping;
}

- (void)setupRouter
{
    NSString *urlString = @"http://www.longboxed.com";
    RKObjectManager *newManager = [RKObjectManager managerWithBaseURL:[NSURL URLWithString:urlString]];
    [RKObjectManager setSharedManager:newManager];
    
    // Class Routing
    [[RKObjectManager sharedManager].router.routeSet addRoute:[RKRoute routeWithClass:[LBXIssue class] pathPattern:@"/api/v1/issues/:longboxedID" method:RKRequestMethodGET]];
    
    [[RKObjectManager sharedManager].router.routeSet addRoute:[RKRoute routeWithClass:[LBXPublisher class] pathPattern:@"/api/v1/publishers/publisherID" method:RKRequestMethodGET]];

//    [manager.router.routeSet addRoute:[RKRoute routeWithName:@"Issue" pathPattern:@"/api/v1/issues/:issue" method:RKRequestMethodGET]];
    
//    // Relationship Routing
//    [manager.router.routeSet addRoute:[RKRoute routeWithRelationshipName:@"amenities" objectClass:[GGAirport class] pathPattern:@"/airports/:airportID/amenities.json" method:RKRequestMethodGET]];
    
//    // Named Routes
//    [manager.router.routeSet addRoute:[RKRoute routeWithName:@"thumbs_down_review" resourcePathPattern:@"/reviews/:reviewID/thumbs_down" method:RKRequestMethodPOST]];
}


- (void)fetchWithURLString:(NSString *)urlString andCredentials:(BOOL)credentials completion:(void (^)(RKMappingResult*, RKObjectRequestOperation*, NSError*))completion {
    
    
    RKObjectMapping *issueMapping = [self getIssueMapping];
    

    RKResponseDescriptor *thisWeekResponseDescriptor = [RKResponseDescriptor responseDescriptorWithMapping:issueMapping
                                                                                            method:RKRequestMethodAny
                                                                                       pathPattern:@"/api/v1/issues/thisweek/"
                                                                                           keyPath:@"issues"
                                                                                       statusCodes:RKStatusCodeIndexSetForClass(RKStatusCodeClassSuccessful)];
    
    RKResponseDescriptor *issueResponseDescriptor = [RKResponseDescriptor responseDescriptorWithMapping:issueMapping
                                                                                            method:RKRequestMethodAny
                                                                                       pathPattern:@"/api/v1/issues/:longboxedID"
                                                                                           keyPath:nil
                                                                                       statusCodes:RKStatusCodeIndexSetForClass(RKStatusCodeClassSuccessful)];
    
    [self setupRouter];
    
    NSURL *URL = [NSURL URLWithString:[NSString stringWithFormat:@"http://www.longboxed.com/api/v1/%@", urlString]];
    NSMutableURLRequest *request = [NSURLRequest requestWithURL:URL];
    
    // Auth
    if (credentials) {
        UICKeyChainStore *store = [UICKeyChainStore keyChainStore];
        NSString *authStr = [NSString stringWithFormat:@"%@:%@", store[@"username"], store[@"password"]];
        NSData *authData = [authStr dataUsingEncoding:NSASCIIStringEncoding];
        NSString *authValue = [NSString stringWithFormat:@"Basic %@", [authData base64EncodingWithLineLength:80]];
        [request setValue:authValue forHTTPHeaderField:@"Authorization"];
    }
    
    RKObjectRequestOperation *objectRequestOperation = [[RKObjectRequestOperation alloc] initWithRequest:request responseDescriptors:@[ thisWeekResponseDescriptor, issueResponseDescriptor ]];
    [objectRequestOperation setCompletionBlockWithSuccess:^(RKObjectRequestOperation *operation, RKMappingResult *mappingResult) {
        if (completion) {
            completion(mappingResult, operation, nil);
        }
    } failure:^(RKObjectRequestOperation *operation, NSError *error) {
        RKLogError(@"Operation failed with error: %@", error);
        if (completion) {
            completion(nil, operation, error);
        }
    }];
    
    [objectRequestOperation start];
}

- (void)fetchThisWeeksComicsWithCompletion:(void (^)(NSArray*, RKObjectRequestOperation*, NSError*))completion {
    [self fetchWithURLString:@"issues/thisweek/" andCredentials:NO completion:^(RKMappingResult *mappingResult, RKObjectRequestOperation *response, NSError *error) {
        NSArray *thisWeeksIssuesArray = mappingResult.array;
        completion(thisWeeksIssuesArray, response, error);
    }];
}

- (void)fetchLogInWithCompletion:(void (^)(id, NSURLResponse*, NSError*))completion {
    [self fetch:@"users/login" withCredentials:YES completion:completion];
}

- (void)fetchPullListWithCompletion:(void (^)(id, NSURLResponse*, NSError*))completion {
    [self fetch:[NSString stringWithFormat:@"users/%@/pull_list/", [UICKeyChainStore keyChainStore][@"id"]] withCredentials:YES completion:completion];
}

- (void)fetchBundlesWithCompletion:(void (^)(id, NSURLResponse*, NSError*))completion {
    [self fetch:[NSString stringWithFormat:@"users/%@/bundles/", [UICKeyChainStore keyChainStore][@"id"]] withCredentials:YES completion:completion];
}

- (void)fetchIssuesWithDate:(NSString *)date withCompletion:(void (^)(id, NSURLResponse*, NSError*))completion {
    [self fetch:[NSString stringWithFormat:@"issues/?date=%@", date] withCredentials:NO completion:completion];
}

- (void)fetchIssue:(int)issue withCompletion:(void (^)(LBXIssue*, RKObjectRequestOperation*, NSError*))completion {
    [self fetchWithURLString:[NSString stringWithFormat:@"issues/%i", issue] andCredentials:NO completion:^(RKMappingResult *mappingResult, RKObjectRequestOperation *response, NSError *error) {
        completion(mappingResult.firstObject, response, error);
    }];
}

- (void)fetchTitlesWithCompletion:(void (^)(id, NSURLResponse*, NSError*))completion {
    [self fetch:@"titles/" withCredentials:NO completion:completion];
}

- (void)fetchTitle:(int)title withCompletion:(void (^)(id, NSURLResponse*, NSError*))completion {
    [self fetch:[NSString stringWithFormat:@"titles/%i", title] withCredentials:NO completion:completion];
}

- (void)fetchPublishersWithCompletion:(void (^)(id, NSURLResponse*, NSError*))completion {
    [self fetch:@"publishers/" withCredentials:NO completion:completion];
}

- (void)fetchPublisher:(int)publisher withCompletion:(void (^)(id, NSURLResponse*, NSError*))completion {
    [self fetch:[NSString stringWithFormat:@"publishers/%i", publisher] withCredentials:NO completion:completion];
}


// http://oleb.net/blog/2009/09/managing-the-network-activity-indicator/
+ (void)setNetworkActivityIndicatorVisible:(BOOL)setVisible {
    static NSUInteger kNetworkIndicatorCount = 0;
    
    if (setVisible) {
        kNetworkIndicatorCount++;
    }
    else {
        kNetworkIndicatorCount--;
    }
    
    // The assertion helps to find programmer errors in activity indicator management.
    // Since a negative NumberOfCallsToSetVisible is not a fatal error,
    // it should probably be removed from production code.
    NSAssert(kNetworkIndicatorCount >= 0, @"Network Activity Indicator was asked to hide more often than shown");
    
    // Display the indicator as long as our static counter is > 0.
    dispatch_async(dispatch_get_main_queue(), ^{
        [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:(kNetworkIndicatorCount > 0)];
    });
}

@end
