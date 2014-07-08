//
//  LBXClient.m
//  Longboxed-iOS
//
//  Created by johnrhickey on 6/29/14.
//  Copyright (c) 2014 Longboxed. All rights reserved.
//

#import "LBXClient.h"
#import "LBXMap.h"
#import "LBXRouter.h"
#import "LBXDescriptors.h"

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

// TODO: Remove this
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


- (void)fetchWithRouteName:(NSString *)routeName object:(id)object queryParameters:(NSDictionary *)parameters credentials:(BOOL)credentials completion:(void (^)(RKMappingResult*, RKObjectRequestOperation*, NSError*))completion {
    
    // Set up the routers with NSString names and parameters
    RKRouter *APIRouter = [LBXRouter routerWithQueryParameters:parameters];

    // Set up the object mapping and response descriptors
    NSArray *responseDescriptors = [LBXDescriptors responseDescriptors];
    
    // Create the URL request with the proper routing
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
