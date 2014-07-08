//
//  LBXClient.m
//  Longboxed-iOS
//
//  Created by johnrhickey on 6/29/14.
//  Copyright (c) 2014 Longboxed. All rights reserved.
//

#import "LBXClient.h"
#import "NSData+Base64.h"
#import "NSString+URLQuery.h"

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

- (RKObjectMapping *)getUserMapping
{
    RKObjectMapping* userMapping = [RKObjectMapping mappingForClass:[LBXUser class]];
    [userMapping addAttributeMappingsFromDictionary:@{ @"email": @"email",
                                                       @"first_name": @"firstName",
                                                       @"id": @"userID",
                                                       @"last_name": @"lastName",
                                                       @"roles": @"roles"
                                                    }];
    return userMapping;
}

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
                                                        @"id": @"issueID",
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

// Routing
- (RKRouter *)setupRouterWithQueryParameters:(NSDictionary *)parameters
{
    NSString *urlString = @"http://www.longboxed.com";
    RKRouter *router = [[RKRouter alloc] initWithBaseURL:[NSURL URLWithString:urlString]];

    // Issues
    [router.routeSet addRoute:[RKRoute routeWithName:@"Issues Collection"
                                         pathPattern:[NSString addQueryStringToUrlString:@"/api/v1/issues/" withDictionary:parameters]
                                              method:RKRequestMethodGET]]; // Required parameter is ?date=2014-06-25
    
    [router.routeSet addRoute:[RKRoute routeWithName:@"Issues Collection for Current Week"
                                         pathPattern:@"/api/v1/issues/thisweek/"
                                              method:RKRequestMethodGET]];
    
    [router.routeSet addRoute:[RKRoute routeWithName:@"Issue"
                                         pathPattern:@"/api/v1/issues/:issueID"
                                              method:RKRequestMethodGET]];
    
    // Titles
    [router.routeSet addRoute:[RKRoute routeWithName:@"Titles Collection"
                                         pathPattern:[NSString addQueryStringToUrlString:@"/api/v1/titles/" withDictionary:parameters]
                                              method:RKRequestMethodGET]]; // Optional parameter is ?page=2
    
    [router.routeSet addRoute:[RKRoute routeWithName:@"Title"
                                         pathPattern:@"/api/v1/titles/:titleID"
                                              method:RKRequestMethodGET]];
    
    [router.routeSet addRoute:[RKRoute routeWithName:@"Issues for Title"
                                         pathPattern:[NSString addQueryStringToUrlString:@"/api/v1/titles/:titleID/issues/" withDictionary:parameters]
                                              method:RKRequestMethodGET]]; // Optional parameter is ?page=2
    
    [router.routeSet addRoute:[RKRoute routeWithName:@"Autocomplete for Titles"
                                         pathPattern:@"/api/v1/titles/autocomplete/"
                                              method:RKRequestMethodGET]]; // Required parameter is ?search=spider
    
    // Publishers
    [router.routeSet addRoute:[RKRoute routeWithName:@"Publisher Collection"
                                         pathPattern:@"/api/v1/publishers/"
                                              method:RKRequestMethodGET]];
    
    [router.routeSet addRoute:[RKRoute routeWithName:@"Publisher"
                                         pathPattern:@"/api/v1/publishers/:publisherID"
                                              method:RKRequestMethodGET]];
    
    [router.routeSet addRoute:[RKRoute routeWithName:@"Titles for Publisher"
                                         pathPattern:[NSString addQueryStringToUrlString:@"/api/v1/:publisherID/titles/" withDictionary:parameters]
                                              method:RKRequestMethodGET]]; // Optional parameter is ?page=2
    
    // Users
    [router.routeSet addRoute:[RKRoute routeWithName:@"Login"
                                         pathPattern:@"/api/v1/users/login"
                                              method:RKRequestMethodGET]];
    
    [router.routeSet addRoute:[RKRoute routeWithName:@"User Pull List"
                                         pathPattern:@"/api/v1/users/pull_list/"
                                              method:RKRequestMethodGET]];
    
    [router.routeSet addRoute:[RKRoute routeWithName:@"Add Title to Pull List"
                                         pathPattern:[NSString addQueryStringToUrlString:@"/api/v1/users/:userID/pull_list/" withDictionary:parameters]
                                              method:RKRequestMethodPOST]]; // Required parameter is ?title_id=20
    
    [router.routeSet addRoute:[RKRoute routeWithName:@"Remove Title from Pull List"
                                         pathPattern:[NSString addQueryStringToUrlString:@"/api/v1/users/:userID/pull_list/" withDictionary:parameters]
                                              method:RKRequestMethodDELETE]]; // Required parameter is ?title_id=20
    
    [router.routeSet addRoute:[RKRoute routeWithName:@"Bundle Resources for User"
                                         pathPattern:@"/api/v1/users/id/bundles/"
                                              method:RKRequestMethodGET]];
    
    [router.routeSet addRoute:[RKRoute routeWithName:@"Latest Bundle"
                                         pathPattern:@"/api/v1/users/id/bundles/latest"
                                              method:RKRequestMethodGET]];
    
    return router;
}

- (NSArray *)responseDescriptors
{
    RKObjectMapping *issueMapping = [self getIssueMapping];
    RKObjectMapping *userMapping = [self getUserMapping];
    
    
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
    return @[thisWeekResponseDescriptor, issueResponseDescriptor];
}


- (void)fetchWithRouteName:(NSString *)routeName object:(id)object queryParameters:(NSDictionary *)parameters credentials:(BOOL)credentials completion:(void (^)(RKMappingResult*, RKObjectRequestOperation*, NSError*))completion {
    
    

    // Set up the object mapping and response descriptors
    NSArray *responseDescriptors = [self responseDescriptors];
    
    // Set up the routers with NSString names and parameters
    RKRouter *APIRouter = [self setupRouterWithQueryParameters:parameters];
    
    NSMutableURLRequest *request = [NSURLRequest requestWithURL:[APIRouter URLForRouteNamed:routeName method:nil object:object]];
    
    // Auth
    if (credentials) {
        UICKeyChainStore *store = [UICKeyChainStore keyChainStore];
        NSString *authStr = [NSString stringWithFormat:@"%@:%@", store[@"username"], store[@"password"]];
        NSData *authData = [authStr dataUsingEncoding:NSASCIIStringEncoding];
        NSString *authValue = [NSString stringWithFormat:@"Basic %@", [authData base64EncodingWithLineLength:80]];
        [request setValue:authValue forHTTPHeaderField:@"Authorization"];
    }
    
    RKObjectRequestOperation *objectRequestOperation = [[RKObjectRequestOperation alloc] initWithRequest:request responseDescriptors:responseDescriptors];
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
    [self fetchWithRouteName:@"Issues Collection for Current Week" object:nil queryParameters:nil credentials:NO completion:^(RKMappingResult *mappingResult, RKObjectRequestOperation *response, NSError *error) {
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

- (void)fetchIssue:(int)issueID withCompletion:(void (^)(LBXIssue*, RKObjectRequestOperation*, NSError*))completion {
    // Create an LBXIssue object for the payload
    LBXIssue *requestIssue = [LBXIssue new];
    requestIssue.issueID = [NSNumber numberWithInt:issueID];
    
    [self fetchWithRouteName:@"Issue" object:requestIssue queryParameters:nil credentials:NO completion:^(RKMappingResult *mappingResult, RKObjectRequestOperation *response, NSError *error) {
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
