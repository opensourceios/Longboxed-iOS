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
    [UICKeyChainStore removeItemForKey:@"id"];
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
        [self.client fetchIssuesCollectionWithDate:[dateFormatter dateFromString:@"2014-07-16"]
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
        [self.client fetchThisWeeksComicsWithPage:@1 completion:^(NSArray *thisWeeksIssuesArray, RKObjectRequestOperation *response, NSError *error) {
            XCTAssertEqual(response.HTTPRequestOperation.response.statusCode, 200, @"Issues collection for current week endpoint is returning a status code %ldd", (long)response.HTTPRequestOperation.response.statusCode);
            XCTAssertNotEqual(thisWeeksIssuesArray.count, 0, @"/issues/thisweek/ JSON is returning nil");
            *done = YES;
        }];
    });
}

- (void)testIssuesCollectionForNextWeekEndpoint
{
    hxRunInMainLoop(^(BOOL *done) {
        [self.client fetchNextWeeksComicsWithPage:@1 completion:^(NSArray *nextWeeksIssuesArray, RKObjectRequestOperation *response, NSError *error) {
            XCTAssertEqual(response.HTTPRequestOperation.response.statusCode, 200, @"Issues collection for current week endpoint is returning a status code %ldd", (long)response.HTTPRequestOperation.response.statusCode);
            // Don't check this because it's possible there are no issues for next week yet
            //XCTAssertNotEqual(nextWeeksIssuesArray.count, 0, @"/issues/nextweek/ JSON is returning nil");
            *done = YES;
        }];
    });
}

- (void)testIssueEndpoint
{
    hxRunInMainLoop(^(BOOL *done) {
        [self.client fetchIssue:[NSNumber numberWithInt:400] withCompletion:^(LBXIssue *issueObject, RKObjectRequestOperation *response, NSError *error) {
            XCTAssertEqual(response.HTTPRequestOperation.response.statusCode, 200, @"Issue endpoint is returning a status code %ld", (long)response.HTTPRequestOperation.response.statusCode);
            XCTAssertNotNil(issueObject, @"Issue JSON is returning %@", issueObject);
            *done = YES;
        }];
    });
}


///////////////
// Titles Tests
///////////////
- (void)testTitleCollectionEndpoint
{
    hxRunInMainLoop(^(BOOL *done) {
        [self.client fetchTitleCollectionWithCompletion:^(NSArray *titlesArray, RKObjectRequestOperation *response, NSError *error) {
            XCTAssertEqual(response.HTTPRequestOperation.response.statusCode, 200, @"Title endpoint is returning a status code %ld", (long)response.HTTPRequestOperation.response.statusCode);
            XCTAssertNotEqual(titlesArray.count, 0, @"Titles JSON is returning nil");
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
        [self.client fetchIssuesForTitle:[NSNumber numberWithInt:103] page:@1 withCompletion:^(NSArray *titleArray, RKObjectRequestOperation *response, NSError *error) {
            XCTAssertEqual(response.HTTPRequestOperation.response.statusCode, 200, @"Issues for title endpoint is returning a status code %ld", (long)response.HTTPRequestOperation.response.statusCode);
            XCTAssertNotEqual(titleArray.count, 0, @"Issues for title JSON is returning nil");
            *done = YES;
        }];
    });
}

- (void)testAutocompleteForTitleEndpoint
{
    hxRunInMainLoop(^(BOOL *done) {
        [self.client fetchAutocompleteForTitle:@"Spider" withCompletion:^(NSArray *titleArray, RKObjectRequestOperation *response, NSError *error) {
            XCTAssertEqual(response.HTTPRequestOperation.response.statusCode, 200, @"Issues for title endpoint is returning a status code %ld", (long)response.HTTPRequestOperation.response.statusCode);
            XCTAssertNotEqual(titleArray.count, 0, @"Issues for title JSON is returning nil");
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
        [self.client fetchPublishersWithPage:@1 completion:^(NSArray *publishersArray, RKObjectRequestOperation *response, NSError *error) {
            XCTAssertEqual(response.HTTPRequestOperation.response.statusCode, 200, @"Publisher endpoint is returning a status code %ld", (long)response.HTTPRequestOperation.response.statusCode);
            XCTAssertNotEqual(publishersArray.count, 0, @"Publisher JSON is returning nil");
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
        [self.client fetchTitlesForPublisher:[NSNumber numberWithInt:4] page:@1 withCompletion:^(NSArray *publisherArray, RKObjectRequestOperation *response, NSError *error) {
            XCTAssertEqual(response.HTTPRequestOperation.response.statusCode, 200, @"Titles for publisher endpoint is returning a status code %ld", (long)response.HTTPRequestOperation.response.statusCode);
            XCTAssertNotEqual(publisherArray.count, 0, @"Publisher w/ num JSON is returning nil");
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
                XCTAssertNotEqual(pullListArray.count, 0, @"Pull list JSON is returning nil");
                *done = YES;
            }];
        }];
    });
}

- (void)testAddandRemovePullListTitleEndpoint
{
    NSNumber *titleNum = [NSNumber numberWithLong:29];

    // Add a title
    __weak typeof(self)weakSelf = self;
    
    hxRunInMainLoop(^(BOOL *done) {
        [self.client fetchLogInWithCompletion:^(LBXUser *user, RKObjectRequestOperation *response, NSError *error) {
            [weakSelf.client addTitleToPullList:titleNum withCompletion:^(NSArray *pullListArray, RKObjectRequestOperation *resp, NSError *error) {
                
                
                XCTAssertEqual(resp.HTTPRequestOperation.response.statusCode, 200, @"Add to pull list endpoint is returning a status code %ldd", (long)response.HTTPRequestOperation.response.statusCode);
                
                // Check for the title in the pull list response
                NSNumber *nilCheck;
                for (LBXTitle *title in pullListArray) {
                    if ([title.titleID isEqualToNumber:titleNum]) nilCheck = title.titleID;
                }

                XCTAssertNotNil(nilCheck, @"Title was not added to pull list");
                
                // Then remove it
                [self.client removeTitleFromPullList:titleNum withCompletion:^(NSArray *pullListArray, RKObjectRequestOperation *resp, NSError *error) {
                    
                    XCTAssertEqual(resp.HTTPRequestOperation.response.statusCode, 200, @"Add to pull list endpoint is returning a status code %ldd", (long)resp.HTTPRequestOperation.response.statusCode);
                    
                    // Check for the title in the pull list response
                    NSNumber *nilCheck;
                    for (LBXTitle *title in pullListArray) {
                        if ([title.titleID isEqualToNumber:titleNum]) nilCheck = title.titleID;
                    }
                    XCTAssertNil(nilCheck, @"Title was not removed from pull list");
                    *done = YES;
                }];
            }];
        }];
    });
}

- (void)testBundleResourcesEndpoint
{
    hxRunInMainLoop(^(BOOL *done) {
        [self.client fetchLogInWithCompletion:^(LBXUser *user, RKObjectRequestOperation *response, NSError *error) {
            [self.client fetchBundleResourcesWithCompletion:^(NSArray *pullListArray, RKObjectRequestOperation *response, NSError *error) {
                XCTAssertEqual(response.HTTPRequestOperation.response.statusCode, 200, @"Bundle resources endpoint is returning a status code %ldd", (long)response.HTTPRequestOperation.response.statusCode);
                XCTAssertNotEqual(pullListArray.count, 0, @"Bundle resources JSON is returning nil");
                *done = YES;
            }];
        }];
    });
}

- (void)testLatestBundleEndpoint
{
    hxRunInMainLoop(^(BOOL *done) {
        [self.client fetchLogInWithCompletion:^(LBXUser *user, RKObjectRequestOperation *response, NSError *error) {
            [self.client fetchLatestBundleWithCompletion:^(NSArray *pullListArray, RKObjectRequestOperation *response, NSError *error) {
                XCTAssertEqual(response.HTTPRequestOperation.response.statusCode, 200, @"Bundle resources endpoint is returning a status code %ldd", (long)response.HTTPRequestOperation.response.statusCode);
                XCTAssertNotEqual(pullListArray.count, 0, @"Bundle resources JSON is returning nil");
                *done = YES;
            }];
        }];
    });
}

@end
