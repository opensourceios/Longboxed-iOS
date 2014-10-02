//
//  LBXClient.m
//  Longboxed-iOS
//
//  Created by johnrhickey on 6/29/14.
//  Copyright (c) 2014 Longboxed. All rights reserved.
//

#import <RestKit/CoreData.h>
#import <UICKeyChainStore.h>

#import "LBXClient.h"
#import "LBXMap.h"
#import "LBXDescriptors.h"
#import "LBXEndpoints.h"
#import "LBXPullListTitle.h"

#import "NSData+Base64.h"
#import "NSString+URLQuery.h"
#import "NSString+RKAdditions.h"
#import "NSDictionary+RKAdditions.h"

@interface LBXClient()

@property (nonatomic) NSURLSession *session;

@end

@implementation LBXClient

+ (void)setAuth
{
    UICKeyChainStore *store = [UICKeyChainStore keyChainStore];
    NSString *authStr = [NSString stringWithFormat:@"%@:%@", store[@"username"], store[@"password"]];
    NSData *authData = [authStr dataUsingEncoding:NSASCIIStringEncoding];
    NSString *authValue = [NSString stringWithFormat:@"Basic %@", [authData base64EncodingWithLineLength:80]];
    [[[RKObjectManager sharedManager] HTTPClient] setDefaultHeader:@"Authorization" value:authValue];
}

- (void)GETWithRouteName:(NSString *)routeName
        objectDictParams:(NSString *)objectDictParams
         queryParameters:(NSDictionary *)parameters
             credentials:(BOOL)credentials
              completion:(void (^)(RKMappingResult*, RKObjectRequestOperation*, NSError*))completion
{
    if (credentials) {
        // Set the shared manager auth
        [LBXClient setAuth];
    }
    
    NSDictionary *endpointDict = [LBXEndpoints endpoints];
    
    NSString *path = endpointDict[routeName];
    if (objectDictParams) {
        path = [endpointDict[routeName] interpolateWithObject:objectDictParams];
    }
    
    [RKObjectManager.sharedManager getObjectsAtPath:path parameters:parameters success:^(RKObjectRequestOperation *operation, RKMappingResult *mappingResult)
    {
        if (completion) {
            completion(mappingResult, operation, nil);
        }
    } failure:^(RKObjectRequestOperation *operation, NSError *error) {
        if (completion) {
            completion(nil, operation, error);
        }
    }];
}

// Using AFNetworking for the POST and DELETE requests
// instead of over-abstracting things with RESTKIT
- (void)POSTWithRouteName:(NSString *)routeName
          queryParameters:(NSDictionary *)parameters
              credentials:(BOOL)credentials
               completion:(void (^)(NSDictionary*, AFHTTPRequestOperation*, NSError*))completion
{
    // Set up the URL route with the parameter suffix
    NSDictionary *endpointDict = [LBXEndpoints endpoints];
    
    AFHTTPClient *client = [self setupAFNetworkingRouter];
    
    // Auth
    UICKeyChainStore *store = [UICKeyChainStore keyChainStore];
    [client setAuthorizationHeaderWithUsername:store[@"username"] password:store[@"password"]];
    
    NSString *postPath = [[NSString addQueryStringToUrlString:endpointDict[routeName]
                                               withDictionary:parameters] stringByReplacingOccurrencesOfString:@":userID" withString:store[@"id"]];
    
    [client postPath:postPath
          parameters:nil
             success:^(AFHTTPRequestOperation *operation, id responseObject) {
                 
                 NSDictionary* jsonFromData = (NSDictionary*)[NSJSONSerialization JSONObjectWithData:responseObject options:NSJSONReadingMutableContainers error:nil];
                 
                 if (completion) {
                     completion(jsonFromData, operation, nil);
                 }
                 
             } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
                 if (completion) {
                     completion(nil, operation, error);
                 }
             }];

}

// Using AFNetworking for the POST and DELETE requests
// instead of over-abstracting things with RESTKIT
- (void)DELETEWithRouteName:(NSString *)routeName
          queryParameters:(NSDictionary *)parameters
              credentials:(BOOL)credentials
               completion:(void (^)(NSDictionary*, AFHTTPRequestOperation*, NSError*))completion
{
    // Set up the URL route with the parameter suffix
    NSDictionary *endpointDict = [LBXEndpoints endpoints];
    
    AFHTTPClient *client = [self setupAFNetworkingRouter];
    
    // Auth
    UICKeyChainStore *store = [UICKeyChainStore keyChainStore];
    [client setAuthorizationHeaderWithUsername:store[@"username"] password:store[@"password"]];
    
    NSString *deletePath = [[NSString addQueryStringToUrlString:endpointDict[routeName]
                                               withDictionary:parameters] stringByReplacingOccurrencesOfString:@":userID" withString:store[@"id"]];
    [client deletePath:deletePath
          parameters:nil
             success:^(AFHTTPRequestOperation *operation, id responseObject) {
                 
                 NSDictionary* jsonFromData = (NSDictionary*)[NSJSONSerialization JSONObjectWithData:responseObject options:NSJSONReadingMutableContainers error:nil];
                 
                 if (completion) {
                     completion(jsonFromData, operation, nil);
                 }
                 
             } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
                 if (completion) {
                     completion(nil, operation, error);
                 }
             }];
    
}

- (AFHTTPClient *)setupAFNetworkingRouter
{
    // Prepare the request
    AFHTTPClient *client = [AFHTTPClient clientWithBaseURL:[NSURL URLWithString:[UICKeyChainStore stringForKey:@"baseURLString"]]];
    [client setParameterEncoding:AFJSONParameterEncoding];
    [client setDefaultHeader:@"Accept" value:@"application/json"];
    
    return client;
}

// Issues
- (void)fetchIssuesCollectionWithDate:(NSDate *)date page:(NSNumber*)page completion:(void (^)(NSArray *, RKObjectRequestOperation *, NSError *))completion
{
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    [formatter setDateFormat:@"yyyy-MM-dd"];
    // For debugging
    NSDictionary *parameters = @{@"date" : [formatter stringFromDate:date], @"page" : [NSString stringWithFormat:@"%d", [page intValue]]};
    [self GETWithRouteName:@"Issues Collection" objectDictParams:nil queryParameters:parameters credentials:NO completion:^(RKMappingResult *mappingResult, RKObjectRequestOperation *response, NSError *error) {
        completion(mappingResult.array, response, error);
    }];
}

- (void)fetchThisWeeksComicsWithPage:(NSNumber *)page completion:(void (^)(NSArray*, RKObjectRequestOperation *, NSError*))completion {
    
    NSDictionary *objectDictParams;
    if (![page isEqualToNumber:@1]) {
        objectDictParams = @{@"page" : [NSString stringWithFormat:@"%d", [page intValue]]};
    }
    [self GETWithRouteName:@"Issues Collection for Current Week" objectDictParams:nil queryParameters:objectDictParams credentials:NO completion:^(RKMappingResult *mappingResult, RKObjectRequestOperation *response, NSError *error) {
        
        completion(mappingResult.array, response, error);
    }];
}

- (void)fetchNextWeeksComicsWithPage:(NSNumber *)page completion:(void (^)(NSArray*, RKObjectRequestOperation *, NSError*))completion {
    
    NSDictionary *objectDictParams;
    if (![page isEqualToNumber:@1]) {
        objectDictParams = @{@"page" : [NSString stringWithFormat:@"%d", [page intValue]]};
    }
    [self GETWithRouteName:@"Issues Collection for Next Week" objectDictParams:nil queryParameters:objectDictParams credentials:NO completion:^(RKMappingResult *mappingResult, RKObjectRequestOperation *response, NSError *error) {
        
        completion(mappingResult.array, response, error);
    }];
}

- (void)fetchIssue:(NSNumber*)issueID withCompletion:(void (^)(LBXIssue*, RKObjectRequestOperation*, NSError*))completion {

    NSString *params = [NSDictionary dictionaryWithKeysAndObjects:
                        @"issueID", issueID,
                        nil];
    
    [self GETWithRouteName:@"Issue" objectDictParams:params queryParameters:nil credentials:NO completion:^(RKMappingResult *mappingResult, RKObjectRequestOperation *response, NSError *error) {
        completion(mappingResult.firstObject, response, error);
    }];
}

- (void)fetchPopularIssuesWithCompletion:(void (^)(NSArray*, RKObjectRequestOperation*, NSError*))completion {
    [self GETWithRouteName:@"Popular Issues for Current Week" objectDictParams:nil queryParameters:nil credentials:NO completion:^(RKMappingResult *mappingResult, RKObjectRequestOperation *response, NSError *error) {
        completion(mappingResult.array, response, error);
    }];
}

// Titles
- (void)fetchTitleCollectionWithCompletion:(void (^)(NSArray*, RKObjectRequestOperation*, NSError*))completion {
    [self GETWithRouteName:@"Titles Collection" objectDictParams:nil queryParameters:nil credentials:NO completion:^(RKMappingResult *mappingResult, RKObjectRequestOperation *response, NSError *error) {
        completion(mappingResult.array, response, error);
    }];
}

- (void)fetchTitle:(NSNumber*)titleID withCompletion:(void (^)(LBXTitle*, RKObjectRequestOperation*, NSError*))completion {
    
    NSString *params = [NSDictionary dictionaryWithKeysAndObjects:
                        @"titleID", titleID,
                        nil];
    
    [self GETWithRouteName:@"Title" objectDictParams:params queryParameters:nil credentials:NO completion:^(RKMappingResult *mappingResult, RKObjectRequestOperation *response, NSError *error) {
        completion(mappingResult.firstObject, response, error);
    }];
}

- (void)fetchIssuesForTitle:(NSNumber*)titleID page:(NSNumber *)page withCompletion:(void (^)(NSArray*, RKObjectRequestOperation*, NSError*))completion {
    
    NSString *params = [NSDictionary dictionaryWithKeysAndObjects:
                        @"titleID", titleID,
                        nil];
    
    NSDictionary *objectDictParams;
    if (![page isEqualToNumber:@1]) {
        objectDictParams = @{@"page" : [NSString stringWithFormat:@"%d", [page intValue]]};
    }
    
    [self GETWithRouteName:@"Issues for Title" objectDictParams:params queryParameters:objectDictParams credentials:NO completion:^(RKMappingResult *mappingResult, RKObjectRequestOperation *response, NSError *error) {
        completion(mappingResult.array, response, error);
    }];
}

- (void)fetchIssuesForTitle:(NSNumber*)titleID page:(NSNumber *)page count:(NSNumber *)count withCompletion:(void (^)(NSArray*, RKObjectRequestOperation*, NSError*))completion {
    
    NSString *params = [NSDictionary dictionaryWithKeysAndObjects:
                        @"titleID", titleID,
                        nil];
    
    NSDictionary *objectDictParams;
    if (![page isEqualToNumber:@1]) {
        objectDictParams = @{@"page" : [NSString stringWithFormat:@"%d", [page intValue]],
                             @"count" : [NSString stringWithFormat:@"%d", [count intValue]]};
    }
    
    [self GETWithRouteName:@"Issues for Title" objectDictParams:params queryParameters:objectDictParams credentials:NO completion:^(RKMappingResult *mappingResult, RKObjectRequestOperation *response, NSError *error) {
        completion(mappingResult.array, response, error);
    }];
}

- (void)fetchAutocompleteForTitle:(NSString*)title withCompletion:(void (^)(NSArray*, RKObjectRequestOperation*, NSError*))completion {

    [self GETWithRouteName:@"Autocomplete for Title" objectDictParams:nil queryParameters:@{@"query": title} credentials:NO completion:^(RKMappingResult *mappingResult, RKObjectRequestOperation *response, NSError *error) {
        completion(mappingResult.array, response, error);
    }];
}

// Publishers
- (void)fetchPublishersWithPage:(NSNumber *)page completion:(void (^)(NSArray *, RKObjectRequestOperation*, NSError*))completion {
    
    NSDictionary *objectDictParams;
    if (![page isEqualToNumber:@1]) {
        objectDictParams = @{@"page" : [NSString stringWithFormat:@"%d", [page intValue]]};
    }
    
    [self GETWithRouteName:@"Publisher Collection" objectDictParams:nil queryParameters:objectDictParams credentials:NO completion:^(RKMappingResult *mappingResult, RKObjectRequestOperation *response, NSError *error) {
        completion(mappingResult.array, response, error);
    }];
}

- (void)fetchPublisher:(NSNumber*)publisherID withCompletion:(void (^)(LBXPublisher*, RKObjectRequestOperation*, NSError*))completion {
    
    NSString *params = [NSDictionary dictionaryWithKeysAndObjects:
                        @"publisherID", publisherID,
                        nil];
    
    [self GETWithRouteName:@"Publisher" objectDictParams:params queryParameters:nil credentials:NO completion:^(RKMappingResult *mappingResult, RKObjectRequestOperation *response, NSError *error) {
        completion(mappingResult.firstObject, response, error);
    }];
}

- (void)fetchTitlesForPublisher:(NSNumber*)publisherID page:(NSNumber *)page withCompletion:(void (^)(NSArray*, RKObjectRequestOperation*, NSError*))completion {
    
    NSString *params = [NSDictionary dictionaryWithKeysAndObjects:
                        @"publisherID", publisherID,
                        nil];
    
    NSDictionary *objectDictParams;
    if (![page isEqualToNumber:@1]) {
        objectDictParams = @{@"page" : [NSString stringWithFormat:@"%d", [page intValue]]};
    }
    
    [self GETWithRouteName:@"Titles for Publisher" objectDictParams:params queryParameters:objectDictParams credentials:NO completion:^(RKMappingResult *mappingResult, RKObjectRequestOperation *response, NSError *error) {
        completion(mappingResult.array, response, error);
    }];
}


// Users
- (void)fetchLogInWithCompletion:(void (^)(LBXUser*, RKObjectRequestOperation*, NSError*))completion {
    [self GETWithRouteName:@"Login" objectDictParams:nil queryParameters:nil credentials:YES completion:^(RKMappingResult *mappingResult, RKObjectRequestOperation *response, NSError *error) {
        
        // Store the user ID
        LBXUser *user = mappingResult.firstObject;
        UICKeyChainStore *store = [UICKeyChainStore keyChainStore];
        
        [UICKeyChainStore setString:[NSString stringWithFormat:@"%@", user.userID] forKey:@"id"];
        [store synchronize];

        completion(mappingResult.firstObject, response, error);
    }];
}

- (void)fetchPullListWithCompletion:(void (^)(NSArray*, RKObjectRequestOperation*, NSError*))completion {
    
    UICKeyChainStore *store = [UICKeyChainStore keyChainStore];
    NSString *params;
    if (store[@"id"]) {
        params = [NSDictionary dictionaryWithKeysAndObjects:
                            @"userID", store[@"id"],
                            nil];
        
    }
    
    [self GETWithRouteName:@"User Pull List" objectDictParams:params queryParameters:nil credentials:YES completion:^(RKMappingResult *mappingResult, RKObjectRequestOperation *response, NSError *error) {
        
        completion(mappingResult.array, response, error);
    }];
}

- (void)addTitleToPullList:(NSNumber*)titleID withCompletion:(void (^)(NSArray*, RKObjectRequestOperation*, NSError*))completion {

    NSDictionary *parameters = @{@"title_id" : [titleID stringValue]};
    
    [self POSTWithRouteName:@"Add Title to Pull List" queryParameters:parameters credentials:YES completion:^(NSDictionary *resultDict, AFHTTPRequestOperation *response, NSError *error) {
        
        // Refetch the pull list for Core Data Storage purposes
        [self fetchPullListWithCompletion:^(NSArray *pullListArray, RKObjectRequestOperation *resp, NSError *err) {
            completion(pullListArray, resp, err);
        }];
    }];
}

- (void)removeTitleFromPullList:(NSNumber*)titleID withCompletion:(void (^)(NSArray*, RKObjectRequestOperation*, NSError*))completion {
    
    NSDictionary *parameters = @{@"title_id" : [titleID stringValue]};
    
    [self DELETEWithRouteName:@"Add Title to Pull List" queryParameters:parameters credentials:YES completion:^(NSDictionary *resultDict, AFHTTPRequestOperation *response, NSError *error) {
        
        // Refetch the pull list for Core Data Storage purposes
        [self fetchPullListWithCompletion:^(NSArray *pullListArray, RKObjectRequestOperation *resp, NSError *err) {
            completion(pullListArray, resp, err);
        }];
    }];
}

- (void)fetchBundleResourcesWithCompletion:(void (^)(NSArray*, RKObjectRequestOperation*, NSError*))completion {

    UICKeyChainStore *store = [UICKeyChainStore keyChainStore];
    NSString *params;
    if (store[@"id"]) {
        params = [NSDictionary dictionaryWithKeysAndObjects:
                  @"userID", store[@"id"],
                  nil];
        
    }
    
    [self GETWithRouteName:@"Bundle Resources for User" objectDictParams:params queryParameters:nil credentials:YES completion:^(RKMappingResult *mappingResult, RKObjectRequestOperation *response, NSError *error) {
        completion(mappingResult.array, response, error);
    }];
}

- (void)fetchLatestBundleWithCompletion:(void (^)(NSArray*, RKObjectRequestOperation*, NSError*))completion {

    UICKeyChainStore *store = [UICKeyChainStore keyChainStore];
    NSString *params;
    if (store[@"id"]) {
        params = [NSDictionary dictionaryWithKeysAndObjects:
                  @"userID", store[@"id"],
                  nil];
        
    }
    
    [self GETWithRouteName:@"Latest Bundle" objectDictParams:params queryParameters:nil credentials:YES completion:^(RKMappingResult *mappingResult, RKObjectRequestOperation *response, NSError *error) {
        completion(mappingResult.array, response, error);
    }];
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
