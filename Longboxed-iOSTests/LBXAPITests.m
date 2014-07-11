//
//  LBXAPITests.m
//  Longboxed-iOS
//
//  Created by johnrhickey on 7/1/14.
//  Copyright (c) 2014 Longboxed. All rights reserved.
//

#import <XCTest/XCTest.h>
#import <UICKeyChainStore.h>

#import "LBXClient.h"
#import "LBXIssue.h"

@interface LBXAPITests : XCTestCase

@property (nonatomic) LBXClient *client;

@end

@implementation LBXAPITests

UICKeyChainStore *store;

// For running asychronous tests
static inline void hxRunInMainLoop(void(^block)(BOOL *done)) {
    __block BOOL done = NO;
    block(&done);
    while (!done) {
        [[NSRunLoop mainRunLoop] runUntilDate:
         [NSDate dateWithTimeIntervalSinceNow:.1]];
    }
}

- (void)setUp
{
    [super setUp];
    // Put setup code here. This method is called before the invocation of each test method in the class.

    _client = [[LBXClient alloc] init];
    
    store = [UICKeyChainStore keyChainStore];
    [UICKeyChainStore setString:@"johnrhickey+test@gmail.com" forKey:@"username"];
    [UICKeyChainStore setString:@"test1234" forKey:@"password"];
    [store synchronize]; // Write to keychain.
}

- (void)tearDown
{
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
    [UICKeyChainStore removeItemForKey:@"username"];
    [UICKeyChainStore removeItemForKey:@"password"];
    [store synchronize]; // Write to keychain.
}

///////////////
// Issues Tests
///////////////

- (void)testIssuesCollectionEndpoint
{
    hxRunInMainLoop(^(BOOL *done) {
        NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
        [dateFormatter setDateFormat:@"yyyy-MM-dd"];
        [self.client fetchIssuesCollectionWithDate:[dateFormatter dateFromString:@"2014-06-25"]
                                              page:[NSNumber numberWithInt:1]
                                        completion:^(NSArray *issuesArray, RKObjectRequestOperation *response, NSError *error) {
            XCTAssertEqual(response.HTTPRequestOperation.response.statusCode, 200, @"Issues with date endpoint is returning a status code %ldd", (long)response.HTTPRequestOperation.response.statusCode);
            XCTAssertNotNil(issuesArray, @"Issues with date JSON is returning nil");
            *done = YES;
        }];
    });
}

- (void)testIssuesCollectionForCurrentWeekEndpoint
{
    hxRunInMainLoop(^(BOOL *done) {
        [self.client fetchThisWeeksComicsWithCompletion:^(NSArray *thisWeeksIssuesArray, RKObjectRequestOperation *response, NSError *error) {
            XCTAssertEqual(response.HTTPRequestOperation.response.statusCode, 200, @"Issues collection for current week endpoint is returning a status code %ldd", (long)response.HTTPRequestOperation.response.statusCode);
            XCTAssertNotNil(thisWeeksIssuesArray, @"/issues/thisweek/ JSON is returning nil");
            *done = YES;
        }];
    });
}

- (void)testIssueEndpoint
{
    hxRunInMainLoop(^(BOOL *done) {
        [self.client fetchIssue:[NSNumber numberWithInt:20] withCompletion:^(LBXIssue *issueObject, RKObjectRequestOperation *response, NSError *error) {
            XCTAssertEqual(response.HTTPRequestOperation.response.statusCode, 200, @"Issue endpoint is returning a status code %ld", (long)response.HTTPRequestOperation.response.statusCode);
            XCTAssertNotNil(issueObject, @"Issue JSON is returning %@", issueObject);
            NSLog(@"%@", issueObject);
            *done = YES;
        }];
    });
}


///////////////
// Titles Tests
///////////////
- (void)testTitleEndpoint
{
    hxRunInMainLoop(^(BOOL *done) {
        [self.client fetchTitlesWithCompletion:^(NSArray *titlesArray, RKObjectRequestOperation *response, NSError *error) {
            XCTAssertEqual(response.HTTPRequestOperation.response.statusCode, 200, @"Title endpoint is returning a status code %ld", (long)response.HTTPRequestOperation.response.statusCode);
            XCTAssertNotNil(titlesArray, @"Titles JSON is returning nil");
            *done = YES;
        }];
    });
}


- (void)testTitlesWithNumberEndpoint
{
    hxRunInMainLoop(^(BOOL *done) {
        [self.client fetchTitle:[NSNumber numberWithInt:70] withCompletion:^(LBXTitle *titleObject, RKObjectRequestOperation *response, NSError *error) {
            XCTAssertEqual(response.HTTPRequestOperation.response.statusCode, 200, @"Titles w/ num endpoint is returning a status code %ld", (long)response.HTTPRequestOperation.response.statusCode);
            XCTAssertNotNil(titleObject, @"Title with number JSON is returning nil");
            *done = YES;
        }];
    });
}

- (void)testIssuesForTitleEndpoint
{
    hxRunInMainLoop(^(BOOL *done) {
        [self.client fetchIssuesForTitle:[NSNumber numberWithInt:70] withCompletion:^(NSArray *titleArray, RKObjectRequestOperation *response, NSError *error) {
            XCTAssertEqual(response.HTTPRequestOperation.response.statusCode, 200, @"Issues for title endpoint is returning a status code %ld", (long)response.HTTPRequestOperation.response.statusCode);
            XCTAssertNotNil(titleArray, @"Issues for title JSON is returning nil");
            *done = YES;
        }];
    });
}


//////////////////
// Publisher Tests
//////////////////

- (void)testPublisherEndpoint
{
    hxRunInMainLoop(^(BOOL *done) {
        [self.client fetchPublishersWithCompletion:^(NSArray *publishersArray, RKObjectRequestOperation *response, NSError *error) {
            XCTAssertEqual(response.HTTPRequestOperation.response.statusCode, 200, @"Publisher endpoint is returning a status code %ld", (long)response.HTTPRequestOperation.response.statusCode);
            XCTAssertNotNil(publishersArray, @"Publisher JSON is returning nil");
            *done = YES;
        }];
    });
}

- (void)testPublisherWithNumberEndpoint
{
    hxRunInMainLoop(^(BOOL *done) {
        [self.client fetchPublisher:[NSNumber numberWithInt:4] withCompletion:^(LBXPublisher *publisher, RKObjectRequestOperation *response, NSError *error) {
            XCTAssertEqual(response.HTTPRequestOperation.response.statusCode, 200, @"Publisher w/ num endpoint is returning a status code %ld", (long)response.HTTPRequestOperation.response.statusCode);
            XCTAssertNotNil(publisher, @"Publisher w/ num JSON is returning nil");
            *done = YES;
        }];
    });
}

- (void)testTitlesForPublisherEndpoint
{
    hxRunInMainLoop(^(BOOL *done) {
        [self.client fetchTitlesForPublisher:[NSNumber numberWithInt:4] withCompletion:^(NSArray *publisherArray, RKObjectRequestOperation *response, NSError *error) {
            XCTAssertEqual(response.HTTPRequestOperation.response.statusCode, 200, @"Titles for publisher endpoint is returning a status code %ld", (long)response.HTTPRequestOperation.response.statusCode);
            XCTAssertNotNil(publisherArray, @"Publisher w/ num JSON is returning nil");
            *done = YES;
        }];
    });
}

// Users

- (void)testLogInEndpoint
{
    hxRunInMainLoop(^(BOOL *done) {
        [self.client fetchLogInWithCompletion:^(LBXUser *user, RKObjectRequestOperation *response, NSError *error) {
            XCTAssertEqual(response.HTTPRequestOperation.response.statusCode, 200, @"Log In endpoint is returning a status code %ldd", (long)response.HTTPRequestOperation.response.statusCode);
            XCTAssertNotNil(user.email, @"Log in JSON is returning %@", user);
            *done = YES;
        }];
    });
}

- (void)testPullListEndpoint
{
    hxRunInMainLoop(^(BOOL *done) {
        [self.client fetchLogInWithCompletion:^(LBXUser *user, RKObjectRequestOperation *response, NSError *error) {
            [self.client fetchPullListWithCompletion:^(NSArray *pullListArray, RKObjectRequestOperation *response, NSError *error) {
                XCTAssertEqual(response.HTTPRequestOperation.response.statusCode, 200, @"Pull list endpoint is returning a status code %ldd", (long)response.HTTPRequestOperation.response.statusCode);
                XCTAssertNotNil(pullListArray, @"Pull list JSON is returning nil");
                *done = YES;
            }];
        }];
    });
}

- (void)testAddTitleToPullListEndpoint
{
    hxRunInMainLoop(^(BOOL *done) {
        [self.client fetchLogInWithCompletion:^(LBXUser *user, RKObjectRequestOperation *response, NSError *error) {
            [self.client addTitleToPullList:[NSNumber numberWithInt:1] withCompletion:^(NSArray *pullListArray, RKObjectRequestOperation *response, NSError *error) {
                XCTAssertEqual(response.HTTPRequestOperation.response.statusCode, 200, @"Att to pull list endpoint is returning a status code %ldd", (long)response.HTTPRequestOperation.response.statusCode);
                NSNumber *nilCheck;
                for (LBXTitle *title in pullListArray) {
                    if (title.titleID == [NSNumber numberWithInt:1]) nilCheck = title.titleID;
                }
                XCTAssertNotNil(nilCheck, @"Title was not added to pull list");
                *done = YES;
            }];
        }];
    });
}

- (void)testRemoveTitleFromPullListEndpoint
{
    hxRunInMainLoop(^(BOOL *done) {
        [self.client fetchLogInWithCompletion:^(LBXUser *user, RKObjectRequestOperation *response, NSError *error) {
            [self.client addTitleToPullList:[NSNumber numberWithInt:1]  withCompletion:^(NSArray *pullListArray, RKObjectRequestOperation *response, NSError *error) {
                XCTAssertEqual(response.HTTPRequestOperation.response.statusCode, 200, @"Att to pull list endpoint is returning a status code %ldd", (long)response.HTTPRequestOperation.response.statusCode);
                XCTAssertNotNil(pullListArray, @"Add to pull list JSON is returning nil");
                *done = YES;
            }];
        }];
    });
}


/// TODO: Add popular/date?= test

- (void)testBundlesEndpoint
{
    hxRunInMainLoop(^(BOOL *done) {
        [self.client fetchLogInWithCompletion:^(id json, RKObjectRequestOperation *response, NSError *error) {
            [UICKeyChainStore setString:[NSString stringWithFormat:@"%@",json[@"user"][@"id"]] forKey:@"id"];
            [store synchronize];
            [self.client fetchBundlesWithCompletion:^(id json, NSURLResponse *response, NSError *error) {
                NSHTTPURLResponse* httpResponse = (NSHTTPURLResponse*)response;
                int responseStatusCode = (int)[httpResponse statusCode];
                XCTAssertEqual(responseStatusCode, 200, @"Bundles endpoint is returning a status code %d", responseStatusCode);
                XCTAssertNotNil(json[@"bundles"], @"Bundles JSON is returning %@", json);
                *done = YES;
            }];
        }];
    });
}





@end
