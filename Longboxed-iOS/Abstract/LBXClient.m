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
#import "LBXBundle.h"

#import "NSData+Base64.h"
#import "NSString+URLQuery.h"
#import "NSArray+LBXArrayUtilities.h"
#import "LBXAppDelegate.h"

#import <JRHUtilities/NSDictionary+DictionaryUtilities.h>
#import <JRHUtilities/NSDate+DateUtilities.h>
#import "LBXControllerServices.h"
#import "LBXLogging.h"

@interface LBXClient()

@property (nonatomic) NSURLSession *session;
@property (nonatomic) NSNumber *titleIDBeingAdded;

@end

@implementation LBXClient

+ (void)setAuth
{
    UICKeyChainStore *store = [UICKeyChainStore keyChainStore];
    NSString *authStr = [NSString stringWithFormat:@"%@:%@", store[@"username"], store[@"password"]];
    NSData *authData = [authStr dataUsingEncoding:NSASCIIStringEncoding];
    NSString *authValue = [NSString stringWithFormat:@"Basic %@", [authData base64EncodingWithLineLength:0]];
    [[[RKObjectManager sharedManager] HTTPClient] setDefaultHeader:@"Authorization" value:authValue];
}

- (void)GETWithRouteName:(NSString *)routeName
        HTTPHeaderParams:(NSDictionary *)HTTPHeaderParams
         queryParameters:(NSDictionary *)parameters
             credentials:(BOOL)credentials
              completion:(void (^)(RKMappingResult*, RKObjectRequestOperation*, NSError*))completion
{
    [(LBXAppDelegate *)[[UIApplication sharedApplication] delegate] setNetworkActivityIndicatorVisible:YES];
    if (credentials) {
        // Set the shared manager auth
        [LBXClient setAuth];
    }
    
    NSDictionary *endpointDict = [LBXEndpoints endpoints];
    
    NSString *path = endpointDict[routeName];
    if (HTTPHeaderParams.allKeys.count) {
        RKPathMatcher *matcher = [RKPathMatcher pathMatcherWithPattern:endpointDict[routeName]];
        path = [matcher pathFromObject:HTTPHeaderParams addingEscapes:YES interpolatedParameters:nil];
    }
    
    [RKObjectManager.sharedManager getObjectsAtPath:path parameters:parameters success:^(RKObjectRequestOperation *operation, RKMappingResult *mappingResult)
    {
        [(LBXAppDelegate *)[[UIApplication sharedApplication] delegate] setNetworkActivityIndicatorVisible:NO];
        if (completion) {
            completion(mappingResult, operation, nil);
        }
    } failure:^(RKObjectRequestOperation *operation, NSError *error) {
        if (completion) {
            [(LBXAppDelegate *)[[UIApplication sharedApplication] delegate] setAPIErrorMessageVisible:YES withError:error];
            completion(nil, operation, error);
        }
    }];
}

// Using AFNetworking for the POST and DELETE requests
// instead of over-abstracting things with RESTKIT
- (void)POSTWithRouteName:(NSString *)routeName
         HTTPHeaderParams:(NSDictionary *)HTTPHeaderParams
           queryParameters:(NSDictionary *)parameters
              credentials:(BOOL)credentials
               completion:(void (^)(NSDictionary*, AFHTTPRequestOperation*, NSError*))completion
{
    [(LBXAppDelegate *)[[UIApplication sharedApplication] delegate] setNetworkActivityIndicatorVisible:YES];
    // Set up the URL route with the parameter suffix
    NSDictionary *endpointDict = [LBXEndpoints endpoints];
    
    AFHTTPClient *client = [self setupAFNetworkingRouter];
    
    NSString *postPath = endpointDict[routeName];
    
    // Auth
    if (credentials) {
        UICKeyChainStore *store = [UICKeyChainStore keyChainStore];
        [client setAuthorizationHeaderWithUsername:store[@"username"] password:store[@"password"]];
        postPath = [[NSString addQueryStringToUrlString:endpointDict[routeName]
                                                   withDictionary:HTTPHeaderParams] stringByReplacingOccurrencesOfString:@":userID" withString:store[@"id"]];
    }
 
    [client postPath:postPath
          parameters:parameters
             success:^(AFHTTPRequestOperation *operation, id responseObject) {
                 [(LBXAppDelegate *)[[UIApplication sharedApplication] delegate] setNetworkActivityIndicatorVisible:NO];
                 [(LBXAppDelegate *)[[UIApplication sharedApplication] delegate] setNetworkActivityIndicatorVisible:NO];
                 // Make sure the response object is not nil before serializing it
                 NSDictionary* jsonFromData = (responseObject) ? (NSDictionary*)[NSJSONSerialization JSONObjectWithData:responseObject options:NSJSONReadingMutableContainers error:nil] : nil;
                 if (completion) {
                     completion(jsonFromData, operation, nil);
                 }
                 
             } failure:^( AFHTTPRequestOperation *operation, NSError *error) {
                 [(LBXAppDelegate *)[[UIApplication sharedApplication] delegate] setNetworkActivityIndicatorVisible:NO];
                 [(LBXAppDelegate *)[[UIApplication sharedApplication] delegate] setAPIErrorMessageVisible:YES withError:error];
                 completion(nil, operation, error);
             }];

}

// Using AFNetworking for the POST and DELETE requests
// instead of over-abstracting things with RESTKIT
- (void)DELETEWithRouteName:(NSString *)routeName
           HTTPHeaderParams:(NSDictionary *)HTTPHeaderParams
            queryParameters:(NSDictionary *)parameters
                credentials:(BOOL)credentials
                 completion:(void (^)(NSDictionary*, AFHTTPRequestOperation*, NSError*))completion
{
    [(LBXAppDelegate *)[[UIApplication sharedApplication] delegate] setNetworkActivityIndicatorVisible:YES];
    // Set up the URL route with the parameter suffix
    NSDictionary *endpointDict = [LBXEndpoints endpoints];
    
    AFHTTPClient *client = [self setupAFNetworkingRouter];
    
    // Auth
    UICKeyChainStore *store = [UICKeyChainStore keyChainStore];
    [client setAuthorizationHeaderWithUsername:store[@"username"] password:store[@"password"]];
    
    NSString *deletePath = endpointDict[routeName];
    if (HTTPHeaderParams) {
        deletePath = [[NSString addQueryStringToUrlString:endpointDict[routeName]
                                           withDictionary:HTTPHeaderParams] stringByReplacingOccurrencesOfString:@":userID"
                                                                                                withString:store[@"id"]];
    }
    [client deletePath:deletePath
          parameters:parameters
             success:^(AFHTTPRequestOperation *operation, id responseObject) {
                 [(LBXAppDelegate *)[[UIApplication sharedApplication] delegate] setNetworkActivityIndicatorVisible:NO];
                 NSDictionary* jsonFromData = (NSDictionary*)[NSJSONSerialization JSONObjectWithData:responseObject options:NSJSONReadingMutableContainers error:nil];
                 
                 if (completion) {
                     completion(jsonFromData, operation, nil);
                 }
                 
             } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
                 [(LBXAppDelegate *)[[UIApplication sharedApplication] delegate] setNetworkActivityIndicatorVisible:NO];
                 [(LBXAppDelegate *)[[UIApplication sharedApplication] delegate] setAPIErrorMessageVisible:YES withError:error];
                 if (completion) {
                     completion(nil, operation, error);
                 }
             }];
    
}

- (AFHTTPClient *)setupAFNetworkingRouter
{
    // Prepare the request
    AFHTTPClient *client = [AFHTTPClient clientWithBaseURL:[NSURL URLWithString:[UICKeyChainStore stringForKey:@"baseURLString"]]];
    client.parameterEncoding = AFJSONParameterEncoding;
    
    // For the self signed production SSL cert
    if ([[UICKeyChainStore stringForKey:@"baseURLString"] isEqualToString:[[LBXEndpoints productionURL] absoluteString]]) {
        client.allowsInvalidSSLCertificate = NO;
    }
    else client.allowsInvalidSSLCertificate = YES;
    
    [client setDefaultHeader:@"Accept" value:@"application/json"];
    
    return client;
}

// Issues
- (void)fetchIssuesCollectionWithDate:(NSDate *)date page:(NSNumber*)page completion:(void (^)(NSArray *, RKObjectRequestOperation *, NSError *))completion
{
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    [formatter setDateFormat:@"yyyy-MM-dd"];
    
    [LBXLogging logMessage:[NSString stringWithFormat:@"Fetching issues collection with date %@", date]];
    
    // For debugging
    NSDictionary *parameters = @{@"date" : [formatter stringFromDate:date], @"page" : [NSString stringWithFormat:@"%d", [page intValue]]};
    [self GETWithRouteName:@"Issues Collection" HTTPHeaderParams:nil queryParameters:parameters credentials:NO completion:^(RKMappingResult *mappingResult, RKObjectRequestOperation *response, NSError *error) {
        
        if (!error) {
            [LBXLogging logMessage:[NSString stringWithFormat:@"Finished fetching issues collection with date %@", date]];
            for (LBXIssue *issue in mappingResult.array) {
                [self saveAlternateIssuesWithIssue:issue];
            }
        }
        
        completion(mappingResult.array, response, error);
    }];
}

- (void)fetchThisWeeksComicsWithPage:(NSNumber *)page completion:(void (^)(NSArray*, RKObjectRequestOperation *, NSError*))completion {
    
    NSDictionary *objectDictParams;
    if (![page isEqualToNumber:@1]) {
        objectDictParams = @{@"page" : [NSString stringWithFormat:@"%d", [page intValue]]};
    }
    [LBXLogging logMessage:[NSString stringWithFormat:@"Fetching this weeks comics with page %@", page]];
    [self GETWithRouteName:@"Issues Collection for Current Week" HTTPHeaderParams:nil queryParameters:objectDictParams credentials:NO completion:^(RKMappingResult *mappingResult, RKObjectRequestOperation *response, NSError *error) {
        
        if (!error) {
            [LBXLogging logMessage:[NSString stringWithFormat:@"Finished fetching this weeks comics with page %@", page]];
            for (LBXIssue *issue in mappingResult.array) {
                [self saveAlternateIssuesWithIssue:issue];
            }
        }
        
        completion(mappingResult.array, response, error);
    }];
}

- (void)fetchNextWeeksComicsWithPage:(NSNumber *)page completion:(void (^)(NSArray*, RKObjectRequestOperation *, NSError*))completion {
    
    NSDictionary *objectDictParams;
    if (![page isEqualToNumber:@1]) {
        objectDictParams = @{@"page" : [NSString stringWithFormat:@"%d", [page intValue]]};
    }
    [LBXLogging logMessage:[NSString stringWithFormat:@"Fetching next weeks comics with page %@", page]];
    [self GETWithRouteName:@"Issues Collection for Next Week" HTTPHeaderParams:nil queryParameters:objectDictParams credentials:NO completion:^(RKMappingResult *mappingResult, RKObjectRequestOperation *response, NSError *error) {
        
        if (!error) {
            [LBXLogging logMessage:[NSString stringWithFormat:@"Finished fetching next weeks comics with page %@", page]];
            for (LBXIssue *issue in mappingResult.array) {
                [self saveAlternateIssuesWithIssue:issue];
            }
        }
        completion(mappingResult.array, response, error);
    }];
}

- (void)fetchIssue:(NSNumber*)issueID withCompletion:(void (^)(LBXIssue*, RKObjectRequestOperation*, NSError*))completion {
    
    NSDictionary *params;
    if (issueID) {
        params = @{@"issueID" : issueID};
    }
    
    [LBXLogging logMessage:[NSString stringWithFormat:@"Fetching issue %@", issueID]];
    [self GETWithRouteName:@"Issue" HTTPHeaderParams:params queryParameters:nil credentials:NO completion:^(RKMappingResult *mappingResult, RKObjectRequestOperation *response, NSError *error) {
        
        if (!error) [self saveAlternateIssuesWithIssue:mappingResult.firstObject];
        [LBXLogging logMessage:[NSString stringWithFormat:@"Finished fetching issue %@", issueID]];
        completion(mappingResult.firstObject, response, error);
    }];
}

- (void)fetchPopularIssuesWithCompletion:(void (^)(NSArray*, RKObjectRequestOperation*, NSError*))completion {
    [LBXLogging logMessage:[NSString stringWithFormat:@"Fetching popular issues"]];
    [self GETWithRouteName:@"Popular Issues for Current Week" HTTPHeaderParams:nil queryParameters:nil credentials:NO completion:^(RKMappingResult *mappingResult, RKObjectRequestOperation *response, NSError *error) {
        
        if (!error) {
            [LBXLogging logMessage:[NSString stringWithFormat:@"Finished fetching popular issues"]];
            for (LBXIssue *issue in mappingResult.array) {
                [self saveAlternateIssuesWithIssue:issue];
            }
        }
        
        completion(mappingResult.array, response, error);
    }];
}

- (void)fetchPopularIssuesWithDate:(NSDate *)date completion:(void (^)(NSArray*, RKObjectRequestOperation*, NSError*))completion {
    [LBXLogging logMessage:[NSString stringWithFormat:@"Fetching popular issues with date: %@", date]];
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    [formatter setDateFormat:@"yyyy-MM-dd"];
    // For debugging
    NSDictionary *parameters = @{@"date" : [formatter stringFromDate:date]};
    
    [self GETWithRouteName:@"Popular Issues for Current Week" HTTPHeaderParams:nil queryParameters:parameters credentials:NO completion:^(RKMappingResult *mappingResult, RKObjectRequestOperation *response, NSError *error) {
        
        if (!error) {
            [LBXLogging logMessage:[NSString stringWithFormat:@"Finished fetching popular issues with date: %@", date]];
            for (LBXIssue *issue in mappingResult.array) {
                [self saveAlternateIssuesWithIssue:issue];
            }
        }
        
        completion(mappingResult.array, response, error);
    }];
}


// Titles
- (void)fetchTitleCollectionWithCompletion:(void (^)(NSArray*, RKObjectRequestOperation*, NSError*))completion {
    [LBXLogging logMessage:[NSString stringWithFormat:@"Fetching title collection"]];
    [self GETWithRouteName:@"Titles Collection" HTTPHeaderParams:nil queryParameters:nil credentials:NO completion:^(RKMappingResult *mappingResult, RKObjectRequestOperation *response, NSError *error) {
        
        if (!error) {
            [LBXLogging logMessage:[NSString stringWithFormat:@"Finished fetching title collection"]];
            for (LBXTitle *title in mappingResult.array) {
                [self saveAlternateIssuesWithIssue:title.latestIssue];
            }
        }
        
        completion(mappingResult.array, response, error);
    }];
}

- (void)fetchTitle:(NSNumber*)titleID withCompletion:(void (^)(LBXTitle*, RKObjectRequestOperation*, NSError*))completion {
    
    NSDictionary *params;
    if (titleID) {
        params = @{@"titleID" : titleID};
    }
    
    [LBXLogging logMessage:[NSString stringWithFormat:@"Fetching title: %@", titleID]];
    [self GETWithRouteName:@"Title" HTTPHeaderParams:params queryParameters:nil credentials:NO completion:^(RKMappingResult *mappingResult, RKObjectRequestOperation *response, NSError *error) {
        
        if (!error) {
            [LBXLogging logMessage:[NSString stringWithFormat:@"Finished fetching title: %@", titleID]];
            [self saveAlternateIssuesWithIssue:((LBXTitle *)mappingResult.firstObject).latestIssue];
        }
        
        completion(mappingResult.firstObject, response, error);
    }];
}

- (void)fetchIssuesForTitle:(NSNumber*)titleID page:(NSNumber *)page withCompletion:(void (^)(NSArray*, RKObjectRequestOperation*, NSError*))completion {
    
    NSDictionary *headerParams;
    if (titleID) {
        headerParams = @{@"titleID" : titleID};
    }
    
    NSDictionary *objectDictParams;
    if (![page isEqualToNumber:@1]) {
        objectDictParams = @{@"page" : [NSString stringWithFormat:@"%d", [page intValue]]};
    }
    [LBXLogging logMessage:[NSString stringWithFormat:@"Fetching issues for title: %@ page: %@", titleID, page]];
    
    [self GETWithRouteName:@"Issues for Title" HTTPHeaderParams:headerParams queryParameters:objectDictParams credentials:NO completion:^(RKMappingResult *mappingResult, RKObjectRequestOperation *response, NSError *error) {
        
        if (!error) {
            [LBXLogging logMessage:[NSString stringWithFormat:@"Finished fetching issues for title: %@ page: %@", titleID, page]];
            for (LBXIssue *issue in mappingResult.array) {
                [self saveAlternateIssuesWithIssue:issue];
            }
        }
        
        completion(mappingResult.array, response, error);
    }];
}

- (void)fetchIssuesForTitle:(NSNumber*)titleID page:(NSNumber *)page count:(NSNumber *)count withCompletion:(void (^)(NSArray*, RKObjectRequestOperation*, NSError*))completion {
    
    NSDictionary *headerParams;
    if (titleID) {
        headerParams = @{@"titleID" : titleID};
    }
    
    NSDictionary *objectDictParams;
    if (![page isEqualToNumber:@1]) {
        objectDictParams = @{@"page" : [NSString stringWithFormat:@"%d", [page intValue]],
                             @"count" : [NSString stringWithFormat:@"%d", [count intValue]]};
    }
    [LBXLogging logMessage:[NSString stringWithFormat:@"Fetching issues for title: %@ page: %@ count: %@", titleID, page, count]];
    
    [self GETWithRouteName:@"Issues for Title" HTTPHeaderParams:headerParams queryParameters:objectDictParams credentials:NO completion:^(RKMappingResult *mappingResult, RKObjectRequestOperation *response, NSError *error) {
        
        if (!error) {
            [LBXLogging logMessage:[NSString stringWithFormat:@"Finished fetching issues for title: %@ page: %@ count: %@", titleID, page, count]];
            for (LBXIssue *issue in mappingResult.array) {
                [self saveAlternateIssuesWithIssue:issue];
            }
        }
        
        completion(mappingResult.array, response, error);
    }];
}

- (void)fetchAutocompleteForTitle:(NSString*)title withCompletion:(void (^)(NSArray*, RKObjectRequestOperation*, NSError*))completion {

    [LBXLogging logMessage:[NSString stringWithFormat:@"Fetching autocomplete for title: %@", title]];
    [self GETWithRouteName:@"Autocomplete for Title" HTTPHeaderParams:nil queryParameters:@{@"query": title} credentials:NO completion:^(RKMappingResult *mappingResult, RKObjectRequestOperation *response, NSError *error) {
        
        if (!error) {
            [LBXLogging logMessage:[NSString stringWithFormat:@"Finished fetching autocomplete for title: %@", title]];
            for (LBXTitle *title in mappingResult.array) {
                [self saveAlternateIssuesWithIssue:title.latestIssue];
            }
        }
        
        completion(mappingResult.array, response, error);
    }];
}

// Publishers
- (void)fetchPublishersWithPage:(NSNumber *)page completion:(void (^)(NSArray *, RKObjectRequestOperation*, NSError*))completion {
    
    NSDictionary *objectDictParams;
    objectDictParams = @{@"page" : [NSString stringWithFormat:@"%d", [page intValue]]};
    [LBXLogging logMessage:@"Fetching publishers"];
    [self GETWithRouteName:@"Publisher Collection" HTTPHeaderParams:nil queryParameters:objectDictParams credentials:NO completion:^(RKMappingResult *mappingResult, RKObjectRequestOperation *response, NSError *error) {
        [LBXLogging logMessage:@"Finished fetching publishers"];
        completion(mappingResult.array, response, error);
    }];
}

- (void)fetchPublisher:(NSNumber*)publisherID withCompletion:(void (^)(LBXPublisher*, RKObjectRequestOperation*, NSError*))completion {
    
    NSDictionary *params;
    if (publisherID) {
        params = @{@"publisherID" : publisherID};
    }
    
    [LBXLogging logMessage:[NSString stringWithFormat:@"Fetching publisher: %@", publisherID]];
    
    [self GETWithRouteName:@"Publisher" HTTPHeaderParams:params queryParameters:nil credentials:NO completion:^(RKMappingResult *mappingResult, RKObjectRequestOperation *response, NSError *error) {
        [LBXLogging logMessage:[NSString stringWithFormat:@"Finished fetching publisher: %@", publisherID]];
        completion(mappingResult.firstObject, response, error);
    }];
}

- (void)fetchTitlesForPublisher:(NSNumber*)publisherID page:(NSNumber *)page withCompletion:(void (^)(NSArray*, RKObjectRequestOperation*, NSError*))completion {
    
    NSDictionary *params;
    if (publisherID) {
        params = @{@"publisherID" : publisherID};
    }
    
    NSDictionary *objectDictParams;
    if (![page isEqualToNumber:@1]) {
        objectDictParams = @{@"page" : [NSString stringWithFormat:@"%d", [page intValue]]};
    }
    
    [LBXLogging logMessage:[NSString stringWithFormat:@"Fetching titles for publisher: %@", publisherID]];
    
    [self GETWithRouteName:@"Titles for Publisher" HTTPHeaderParams:params queryParameters:objectDictParams credentials:NO completion:^(RKMappingResult *mappingResult, RKObjectRequestOperation *response, NSError *error) {
        
        if (!error) {
            [LBXLogging logMessage:[NSString stringWithFormat:@"Finished fetching titles for publisher: %@", publisherID]];
            for (LBXTitle *title in mappingResult.array) {
                [self saveAlternateIssuesWithIssue:title.latestIssue];
            }
        }
        completion(mappingResult.array, response, error);
    }];
}


// Users
- (void)registerWithEmail:(NSString*)email password:(NSString *)password passwordConfirm:(NSString *)passwordConfirm withCompletion:(void (^)(NSDictionary*, AFHTTPRequestOperation*, NSError*))completion {
    
    NSDictionary *parameters = @{@"email" : email, @"password" : password, @"password_confirm" : passwordConfirm};
    [LBXLogging logMessage:[NSString stringWithFormat:@"Registering email: %@", email]];
    [self POSTWithRouteName:@"Register" HTTPHeaderParams:nil queryParameters:parameters credentials:NO completion:^(NSDictionary *resultDict, AFHTTPRequestOperation *response, NSError *error) {
        if (error) {
            [LBXLogging logMessage:[NSString stringWithFormat:@"Finished registering email: %@", email]];
            NSString *errorJSONString = error.userInfo[@"NSLocalizedRecoverySuggestion"];
            NSData *data = [errorJSONString dataUsingEncoding:NSUTF8StringEncoding];
            NSDictionary *jsonDict = [NSJSONSerialization JSONObjectWithData:data options:0 error:&error];
            resultDict = jsonDict[@"errors"];
        }
        completion(resultDict, response, error);
    }];
}

- (void)deleteAccountWithCompletion:(void (^)(NSDictionary*, AFHTTPRequestOperation*, NSError*))completion {
    
    if (![LBXControllerServices isLoggedIn]) completion(nil, nil, nil);
    else {
        [LBXLogging logMessage:@"Deleting account"];
        [self DELETEWithRouteName:@"Delete Account" HTTPHeaderParams:nil queryParameters:nil credentials:YES completion:^(NSDictionary *resultDict, AFHTTPRequestOperation *response, NSError *error) {
            [LBXLogging logMessage:@"Finished deleting account"];
            completion(resultDict, response, error);
        }];
    }
}


- (void)fetchLogInWithCompletion:(void (^)(LBXUser*, RKObjectRequestOperation*, NSError*))completion {
    [LBXLogging logMessage:@"Logging in"];
    [self GETWithRouteName:@"Login" HTTPHeaderParams:nil queryParameters:nil credentials:YES completion:^(RKMappingResult *mappingResult, RKObjectRequestOperation *response, NSError *error) {
        [LBXLogging logMessage:@"Finished logging in"];
        // Store the user ID
        LBXUser *user = mappingResult.firstObject;
        [UICKeyChainStore setString:[NSString stringWithFormat:@"%@", user.userID] forKey:@"id"];

        completion(mappingResult.firstObject, response, error);
    }];
}

- (void)fetchPullListWithCompletion:(void (^)(NSArray*, RKObjectRequestOperation*, NSError*))completion {
    if (![LBXControllerServices isLoggedIn]) completion(nil, nil, nil);
    else {
        UICKeyChainStore *store = [UICKeyChainStore keyChainStore];
        NSDictionary *headerParams;
        if (store[@"id"]) {
            headerParams = @{@"userID" : store[@"id"]};
            
        }
        
        [LBXLogging logMessage:@"Fetching pull list"];
        
        [self GETWithRouteName:@"User Pull List" HTTPHeaderParams:headerParams queryParameters:nil credentials:YES completion:^(RKMappingResult *mappingResult, RKObjectRequestOperation *response, NSError *error) {
            
            if (!error) {
                [LBXLogging logMessage:@"Finished fetching pull list"];
                // Delete any items that may have been removed from
                // the pull list
                NSArray *objects = [LBXPullListTitle MR_findAll];
                for (NSManagedObject *managedObject in objects) {
                    if (![mappingResult.array containsObject:managedObject] && (_titleIDBeingAdded != ((LBXPullListTitle *)managedObject).titleID)) {
                        [[NSManagedObjectContext MR_defaultContext] deleteObject:managedObject];
                    }
                }
                
                for (LBXTitle *title in mappingResult.array) {
                    [self saveAlternateIssuesWithIssue:title.latestIssue];
                }
            }
            
            completion(mappingResult.array, response, error);
        }];
    }
}

- (void)addTitleToPullList:(NSNumber*)titleID withCompletion:(void (^)(NSArray*, AFHTTPRequestOperation*, NSError*))completion {
    
    if (![LBXControllerServices isLoggedIn]) completion(nil, nil, nil);
    else {
        [LBXLogging logMessage:[NSString stringWithFormat:@"Adding title to pull list: %@", titleID]];
        _titleIDBeingAdded = titleID;
        [LBXLogging logMessage:[NSString stringWithFormat:@"Adding title:\n %@", titleID]];
        NSDictionary *headerParams = @{@"title_id" : [titleID stringValue]};
        
        [self POSTWithRouteName:@"Add Title to Pull List" HTTPHeaderParams:headerParams queryParameters:nil credentials:YES completion:^(NSDictionary *resultDict, AFHTTPRequestOperation *response, NSError *error) {
            
            [LBXLogging logMessage:[NSString stringWithFormat:@"Added title to pull list: %@", titleID]];
            NSArray *pullListArray = [NSArray sortedArray:[LBXPullListTitle MR_findAllSortedBy:@"name" ascending:YES] basedOffObjectProperty:@"name"];
            _titleIDBeingAdded = nil;
            [LBXLogging logMessage:[NSString stringWithFormat:@"Added title:\n %@", titleID]];
            completion(pullListArray, response, error);
        }];
    }
}

- (void)removeTitleFromPullList:(NSNumber*)titleID withCompletion:(void (^)(NSArray*, AFHTTPRequestOperation*, NSError*))completion {
    if (![LBXControllerServices isLoggedIn]) completion(nil, nil, nil);
    else {
        [LBXLogging logMessage:[NSString stringWithFormat:@"Removing title from pull list: %@", titleID]];
        NSDictionary *headerParams = @{@"title_id" : [titleID stringValue]};
        // Remove the title from Core Data first
        __block NSPredicate *predicate = [NSPredicate predicateWithFormat: @"titleID == %@", titleID];
        dispatch_async(dispatch_get_main_queue(), ^{
            [LBXPullListTitle MR_deleteAllMatchingPredicate:predicate];
        });
        [[NSManagedObjectContext MR_defaultContext] MR_saveToPersistentStoreWithCompletion:^(BOOL success, NSError *error) {
            [self DELETEWithRouteName:@"Add Title to Pull List" HTTPHeaderParams:headerParams queryParameters:nil credentials:YES completion:^(NSDictionary *resultDict, AFHTTPRequestOperation *response, NSError *error) {
                
                if (!error) {
                    [LBXLogging logMessage:[NSString stringWithFormat:@"Removed title from pull list:\n %@", titleID]];
                    // Remove the title from the latest bundle
                    NSArray *bundleArray = [LBXBundle MR_findAllSortedBy:@"bundleID" ascending:NO];
                    if (bundleArray.count) {
                        LBXBundle *bundle = bundleArray[0];
                        dispatch_async(dispatch_get_main_queue(), ^{
                            predicate = [NSPredicate predicateWithFormat:@"bundleID == %@", bundle.bundleID];
                            dispatch_async(dispatch_get_main_queue(), ^{
                                [LBXBundle MR_deleteAllMatchingPredicate:predicate];
                            });
                            [[NSManagedObjectContext MR_defaultContext] MR_saveToPersistentStoreAndWait];
                        });
                    }
                }
                NSArray *pullListArray = [NSArray sortedArray:[LBXPullListTitle MR_findAllSortedBy:@"name" ascending:YES] basedOffObjectProperty:@"name"];
                completion(pullListArray, response, error);
            }];
        }];
    }

}


- (void)fetchBundleResourcesWithPage:(NSNumber *)page completion:(void (^)(NSArray*, RKObjectRequestOperation*, NSError*))completion {

    if (![LBXControllerServices isLoggedIn]) completion(nil, nil, nil);
    else {
        UICKeyChainStore *store = [UICKeyChainStore keyChainStore];
        NSDictionary *headerParams;
        if (store[@"id"]) {
            headerParams = @{@"userID" : store[@"id"]};
        }
        
        NSDictionary *objectDictParams;
        if (![page isEqualToNumber:@1]) {
            objectDictParams = @{@"page" : [NSString stringWithFormat:@"%d", [page intValue]]};
        }
        
        [LBXLogging logMessage:[NSString stringWithFormat:@"Fetching bundle resources with page: %@", page]];
        
        [self GETWithRouteName:@"Bundle Resources for User" HTTPHeaderParams:headerParams queryParameters:objectDictParams credentials:YES completion:^(RKMappingResult *mappingResult, RKObjectRequestOperation *response, NSError *error) {
            
            if (!error) {
                [LBXLogging logMessage:[NSString stringWithFormat:@"Finished fetching bundle resources with page: %@", page]];
                for (LBXBundle *bundle in mappingResult.array) {
                    if (bundle.bundleID) { // Weird bug where sometimes returned array bundles have null id's
                        for (LBXIssue *issue in bundle.issues) {
                            LBXPullListTitle *title = [LBXPullListTitle MR_findFirstByAttribute:@"titleID" withValue:issue.title.titleID];
                            if (title) [self saveAlternateIssuesWithIssue:issue];
                        }
                    }
                    else {
                        [self fetchBundleResourcesWithDate:[NSDate thisWednesdayOfDate:[NSDate localDate]] page:@1 count:@1 completion:^(NSArray *bundleArray, RKObjectRequestOperation *response, NSError *error) {
                            completion(mappingResult.array, response, error);
                        }];
                    }
                }
            }
            
            completion(mappingResult.array, response, error);
        }];
    }
}

- (void)fetchBundleResourcesWithDate:(NSDate *)date page:(NSNumber*)page count:(NSNumber *)count completion:(void (^)(NSArray *, RKObjectRequestOperation *, NSError *))completion
{
    if (![LBXControllerServices isLoggedIn]) completion(nil, nil, nil);
    else {
        UICKeyChainStore *store = [UICKeyChainStore keyChainStore];
        NSDictionary *headerParams;
        if (store[@"id"]) {
            headerParams = @{@"userID" : store[@"id"]};
        }
        
        NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
        [formatter setDateFormat:@"yyyy-MM-dd"];
        
        [LBXLogging logMessage:[NSString stringWithFormat:@"Fetching bundle resources with date: %@ page: %@ count:%@", date, page, count]];
        
        // For debugging
        NSDictionary *parameters = @{@"date" : [formatter stringFromDate:date],
                                     @"page" : [NSString stringWithFormat:@"%d", [page intValue]],
                                     @"count" : [NSString stringWithFormat:@"%d", [count intValue]]};
        
        [self GETWithRouteName:@"Bundle Resources for User" HTTPHeaderParams:headerParams queryParameters:parameters credentials:YES completion:^(RKMappingResult *mappingResult, RKObjectRequestOperation *response, NSError *error) {
            
            if (!error) {
                [LBXLogging logMessage:[NSString stringWithFormat:@"Finished fetching bundle resources with date: %@ page: %@ count:%@", date, page, count]];
                for (LBXBundle *bundle in mappingResult.array) {
                    if (bundle.bundleID) { // Weird bug where sometimes returned array bundles have null id's
                        for (LBXIssue *issue in bundle.issues) {
                            LBXPullListTitle *title = [LBXPullListTitle MR_findFirstByAttribute:@"titleID" withValue:issue.title.titleID];
                            if (title) [self saveAlternateIssuesWithIssue:issue];
                        }
                    }
                    else {
                        [self fetchBundleResourcesWithDate:[NSDate thisWednesdayOfDate:[NSDate localDate]] page:@1 count:@1 completion:^(NSArray *bundleArray, RKObjectRequestOperation *response, NSError *error) {
                            [LBXControllerServices setupLocalPushNotificationsWithBundleArray:mappingResult.array];
                            completion(mappingResult.array, response, error);
                        }];
                    }
                }
            }
            [LBXControllerServices setupLocalPushNotificationsWithBundleArray:mappingResult.array];
            completion(mappingResult.array, response, error);
        }];
    }
}

- (void)fetchLatestBundleWithCompletion:(void (^)(LBXBundle*, RKObjectRequestOperation*, NSError*))completion {

    if (![LBXControllerServices isLoggedIn]) completion(nil, nil, nil);
    else {
        UICKeyChainStore *store = [UICKeyChainStore keyChainStore];
        NSDictionary *headerParams;
        if (store[@"id"]) {
            headerParams = @{@"userID" : store[@"id"]};
        }
        [LBXLogging logMessage:[NSString stringWithFormat:@"Fetching latest bundle"]];
        
        [self GETWithRouteName:@"Latest Bundle" HTTPHeaderParams:headerParams queryParameters:nil credentials:YES completion:^(RKMappingResult *mappingResult, RKObjectRequestOperation *response, NSError *error) {
            
            LBXBundle *bundle = (((LBXBundle *)mappingResult.array[0]).bundleID) ? ((LBXBundle *)mappingResult.array[0]) : nil;
            if (!error) {
                [LBXLogging logMessage:[NSString stringWithFormat:@"Finished fetching latest bundle"]];
                if (bundle.bundleID) { // Weird bug where sometimes returned bundles have null id's
                    for (LBXIssue *issue in bundle.issues) {
                        [self saveAlternateIssuesWithIssue:issue];
                    }
                    completion(bundle, response, error);
                }
                else {
                    [self fetchBundleResourcesWithDate:[NSDate thisWednesdayOfDate:[NSDate localDate]] page:@1 count:@1 completion:^(NSArray *bundleArray, RKObjectRequestOperation *response, NSError *error) {
                        if (bundleArray.count) {
                            completion(bundleArray[0], response, error);
                        }
                        else completion(nil, response, error);
                    }];
                }
            }
            else completion(bundle, response, error);
            
        }];
    }
}

#pragma mark Private Methods

- (void)saveAlternateIssuesWithIssue:(LBXIssue *)issue {
    // Save all the alternate issues
    for (NSDictionary *alternateIssueDict in issue.alternates) {
        // Create the alternate issue in the datastore if it's not there already
        LBXIssue *foundIssue = [LBXIssue MR_findFirstByAttribute:@"completeTitle" withValue:alternateIssueDict[@"complete_title"]];
        if (!foundIssue) {
            LBXIssue *alternateIssue = [LBXIssue MR_createEntity];
            alternateIssue.completeTitle = alternateIssueDict[@"complete_title"];
            alternateIssue.issueID = alternateIssueDict[@"id"];
            alternateIssue.isParent = alternateIssueDict[@"is_parent"];
            alternateIssue.title = issue.title;
            alternateIssue.issueNumber = issue.issueNumber;
            alternateIssue.publisher = issue.publisher;
            alternateIssue.releaseDate = issue.releaseDate;
            [[NSManagedObjectContext MR_defaultContext] MR_saveToPersistentStoreAndWait];
        }
    }
}

@end
