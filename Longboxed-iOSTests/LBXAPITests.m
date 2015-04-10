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
#import "LBXEndpoints.h"
#import "LBXBundle.h"
#import <JRHUtilities/NSDate+DateUtilities.h>

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

    _client = [LBXClient new];
    
    store = [UICKeyChainStore keyChainStore];
    [UICKeyChainStore setString:@"johnrhickey+test@gmail.com" forKey:@"username"];
    [UICKeyChainStore setString:@"test1234" forKey:@"password"];
    [UICKeyChainStore setString:[[LBXEndpoints stagingURL] absoluteString] forKey:@"baseURLString"];
}

- (void)tearDown
{
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
    [UICKeyChainStore removeItemForKey:@"username"];
    [UICKeyChainStore removeItemForKey:@"password"];
    [UICKeyChainStore removeItemForKey:@"id"];
    [UICKeyChainStore removeItemForKey:@"baseURLString"];
}

// Tests the accuracy of the date calculations
- (void)testWednesdayRetrival
{
    // Both this week and next week arrays should for 9 days, starting on a Sunday
    int day = 4;
    NSMutableArray *thisWednesdayArray = [NSMutableArray new];
    NSMutableArray *nextWednesdayArray = [NSMutableArray new];
    for (int i = 0; i < 9; i++) {
        NSCalendar *calendar = [[NSCalendar alloc] initWithCalendarIdentifier:NSCalendarIdentifierGregorian];
        NSDateComponents *components = [[NSDateComponents alloc] init];
        [components setYear:2015];
        [components setMonth:01];
        [components setDay:day];
        [calendar dateFromComponents:components];
        NSDate *date = [calendar dateFromComponents:components];
        [thisWednesdayArray addObject:[NSDate thisWednesdayOfDate:date]];
        [nextWednesdayArray addObject:[NSDate nextWednesdayOfDate:date]];
        day++;
    }
    
    // First element in array should be one week, middle should be another week, and last element should be another
    int count = 0;
    for (NSDate *date in thisWednesdayArray) {
        if (count == 0) {
            XCTAssertNotEqual(date, thisWednesdayArray[1]);
        }
        else if (count == thisWednesdayArray.count - 2) {
            XCTAssertEqual(date, thisWednesdayArray[count - 2]);
        }
        else if (count == thisWednesdayArray.count - 1) {
            XCTAssertNotEqual(date, thisWednesdayArray[thisWednesdayArray.count - 2]);
        }
        else {
            XCTAssertEqual(date, thisWednesdayArray[count + 1]);
        }
        count++;
    }
    
    // First element in array should be one week, middle should be another week, and last element should be another
    count = 0;
    for (NSDate *date in nextWednesdayArray) {
        if (count == 0) {
            XCTAssertNotEqual(date, nextWednesdayArray[1]);
        }
        else if (count == nextWednesdayArray.count - 2) {
            XCTAssertEqual(date, nextWednesdayArray[count - 2]);
        }
        else if (count == nextWednesdayArray.count - 1) {
            XCTAssertNotEqual(date, nextWednesdayArray[nextWednesdayArray.count - 2]);
        }
        else {
            XCTAssertEqual(date, nextWednesdayArray[count + 1]);
        }
        count++;
    }
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
            XCTAssertNotEqual(nextWeeksIssuesArray.count, 0, @"/issues/nextweek/ JSON is returning nil");
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

- (void)testPopularIssuesEndpoint
{
    hxRunInMainLoop(^(BOOL *done) {
        [self.client fetchPopularIssuesWithCompletion:^(NSArray *popularIssuesArray, RKObjectRequestOperation *response, NSError *error) {
            XCTAssertEqual(response.HTTPRequestOperation.response.statusCode, 200, @"Issues collection for current week endpoint is returning a status code %ldd", (long)response.HTTPRequestOperation.response.statusCode);
            // Don't check this because it's possible there are no issues for next week yet
            XCTAssertNotEqual(popularIssuesArray.count, 0, @"/issues/popular/ JSON is returning nil");
            *done = YES;
        }];
    });
}

- (void)testPopularIssuesWithDateEndpoint
{
    hxRunInMainLoop(^(BOOL *done) {
        NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
        [dateFormatter setDateFormat:@"yyyy-MM-dd"];
        [self.client fetchPopularIssuesWithDate:[dateFormatter dateFromString:@"2015-02-04"] completion:^(NSArray *popularIssuesArray, RKObjectRequestOperation *response, NSError *error) {
            XCTAssertEqual(response.HTTPRequestOperation.response.statusCode, 200, @"Issues collection for current week endpoint is returning a status code %ldd", (long)response.HTTPRequestOperation.response.statusCode);
            // Don't check this because it's possible there are no issues for next week yet
            XCTAssertNotEqual(popularIssuesArray.count, 0, @"/issues/popular/?date=2015-02-04 JSON is returning nil");
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
        [self.client fetchTitle:[NSNumber numberWithInt:2] withCompletion:^(LBXTitle *titleObject, RKObjectRequestOperation *response, NSError *error) {
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
- (void)testSignUpAndDeleteEndpoints
{
    NSString *testUsername = @"johnrhickey+testSignup@gmail.com";
    NSString *testPassword = @"test1234";
    
    [[RKObjectManager sharedManager] setHTTPClient:[AFHTTPClient clientWithBaseURL:[LBXEndpoints stagingURL]]];
    hxRunInMainLoop(^(BOOL *done) {
        [self.client registerWithEmail:testUsername password:testPassword passwordConfirm:testPassword withCompletion:^(NSDictionary *responseDict, AFHTTPRequestOperation *response, NSError *error) {
            if (error) {
                for (NSString *error in [responseDict allKeys]) {
                    XCTFail(@"%@", responseDict[error]);
                     *done = YES;
                }

            }
            else {
                XCTAssertEqual(response.response.statusCode, 200, @"Sign up endpoint is returning a status code %ldd", (long)response.response.statusCode);
                
                
                store = [UICKeyChainStore keyChainStore];
                [UICKeyChainStore setString:testUsername forKey:@"username"];
                [UICKeyChainStore setString:testPassword forKey:@"password"];
                [UICKeyChainStore setString:@"1" forKey:@"id"];
                
                // Delete Stuff
                [[RKObjectManager sharedManager] setHTTPClient:[AFHTTPClient clientWithBaseURL:[LBXEndpoints stagingURL]]];
                [self.client deleteAccountWithCompletion:^(NSDictionary *responseDict, AFHTTPRequestOperation *response, NSError *error) {
                    
                    // Set the keychain user credentials back
                    store = [UICKeyChainStore keyChainStore];
                    [UICKeyChainStore setString:@"johnrhickey+test@gmail.com" forKey:@"username"];
                    [UICKeyChainStore setString:@"test1234" forKey:@"password"];
                    [UICKeyChainStore setString:@"NO" forKey:@"isLoggedIn"];
                    
                    if (error) {
                        for (NSString *error in [responseDict allKeys]) {
                            XCTFail(@"%@", responseDict[error]);
                        }
                    }
                    else {
                        XCTAssertEqual(response.response.statusCode, 200, @"Delete endpoint is returning a status code %ldd", (long)response.response.statusCode);
                    }
                    *done = YES;
                }];
            }
        }];
    });
}

- (void)testLogInEndpoint
{
    hxRunInMainLoop(^(BOOL *done) {
        [self.client fetchLogInWithCompletion:^(LBXUser *user, RKObjectRequestOperation *response, NSError *error) {
            XCTAssertNotNil(user.roles);
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

- (void)testAddandRemovePullListTitleEndpoints
{
    NSNumber *titleNum = @6;

    // Add a title
    __weak typeof(self)weakSelf = self;
    
    hxRunInMainLoop(^(BOOL *done) {
        [self.client fetchLogInWithCompletion:^(LBXUser *user, RKObjectRequestOperation *response, NSError *error) {
            [weakSelf.client addTitleToPullList:titleNum withCompletion:^(NSArray *pullListArray, AFHTTPRequestOperation *resp, NSError *error) {
                
                XCTAssertEqual(resp.response.statusCode, 200, @"Add to pull list endpoint is returning a status code %ldd", (long)resp.response.statusCode);
                
                // Check for the title in the pull list response
                NSNumber *nilCheck;
                for (LBXTitle *title in pullListArray) {
                    if ([title.titleID isEqualToNumber:titleNum]) nilCheck = title.titleID;
                }
                
                // Then remove it
                [self.client removeTitleFromPullList:titleNum withCompletion:^(NSArray *pullListArray, AFHTTPRequestOperation *resp, NSError *error) {
                    
                    XCTAssertEqual(resp.response.statusCode, 200, @"Remove from pull list endpoint is returning a status code %ldd", (long)resp.response.statusCode);
                    
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
            [self.client fetchBundleResourcesWithPage:@1 completion:^(NSArray *pullListArray, RKObjectRequestOperation *response, NSError *error) {
                XCTAssertEqual(response.HTTPRequestOperation.response.statusCode, 200, @"Bundle resources endpoint is returning a status code %ld", (long)response.HTTPRequestOperation.response.statusCode);
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
            [self.client fetchLatestBundleWithCompletion:^(LBXBundle *bundle, RKObjectRequestOperation *response, NSError *error) {
                XCTAssertEqual(response.HTTPRequestOperation.response.statusCode, 200, @"Bundle resources endpoint is returning a status code %ld", (long)response.HTTPRequestOperation.response.statusCode);
                XCTAssertNotEqual(bundle.issues.count, 0, @"Bundle resources JSON is returning nil");
                *done = YES;
            }];
        }];
    });
}

- (void)testBundleResourcesWithDate
{
    hxRunInMainLoop(^(BOOL *done) {
        [self.client fetchLogInWithCompletion:^(LBXUser *user, RKObjectRequestOperation *response, NSError *error) {
            NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
            [dateFormatter setDateFormat:@"yyyy-MM-dd"];
            
            [self.client fetchBundleResourcesWithDate:[dateFormatter dateFromString:@"2015-02-04"]
                                                 page:@1
                                                count:@1
                                           completion:^(NSArray *bundleIssuesArray, RKObjectRequestOperation *response, NSError *error) {
                                               
                XCTAssertEqual(response.HTTPRequestOperation.response.statusCode, 200, @"Bundle resources endpoint is returning a status code %ld", (long)response.HTTPRequestOperation.response.statusCode);
                XCTAssertNotEqual(bundleIssuesArray.count, 0, @"Bundle resources JSON is returning nil");
                *done = YES;
            }];
        }];
    });
}

@end
