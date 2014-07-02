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

- (void)testPullListEndpoint
{
    hxRunInMainLoop(^(BOOL *done) {
        [self.client fetchLogInWithCompletion:^(id json, NSURLResponse *response, NSError *error) {
            [UICKeyChainStore setString:[NSString stringWithFormat:@"%@",json[@"id"]] forKey:@"id"];
            [store synchronize];
            [self.client fetchPullListWithCompletion:^(id json, NSURLResponse *response, NSError *error) {
                NSHTTPURLResponse* httpResponse = (NSHTTPURLResponse*)response;
                int responseStatusCode = [httpResponse statusCode];
                XCTAssertEqual(responseStatusCode, 200, @"Pull list endpoint is returning a status code %d", responseStatusCode);
                XCTAssertNotNil(json[@"pull_list"], @"Pull list JSON is returning %@", json);
                *done = YES;
            }];
        }];
    });
}

- (void)testBundlesEndpoint
{
    hxRunInMainLoop(^(BOOL *done) {
        [self.client fetchLogInWithCompletion:^(id json, NSURLResponse *response, NSError *error) {
            [UICKeyChainStore setString:[NSString stringWithFormat:@"%@",json[@"id"]] forKey:@"id"];
            [store synchronize];
            [self.client fetchBundlesWithCompletion:^(id json, NSURLResponse *response, NSError *error) {
                NSHTTPURLResponse* httpResponse = (NSHTTPURLResponse*)response;
                int responseStatusCode = [httpResponse statusCode];
                XCTAssertEqual(responseStatusCode, 200, @"Bundles endpoint is returning a status code %d", responseStatusCode);
                XCTAssertNotNil(json[@"bundles"], @"Bundles JSON is returning %@", json);
                *done = YES;
            }];
        }];
    });
}

- (void)testLogInEndpoint
{
    hxRunInMainLoop(^(BOOL *done) {
        [self.client fetchLogInWithCompletion:^(id json, NSURLResponse *response, NSError *error) {
            NSHTTPURLResponse* httpResponse = (NSHTTPURLResponse*)response;
            int responseStatusCode = [httpResponse statusCode];
            XCTAssertEqual(responseStatusCode, 200, @"Log In endpoint is returning a status code %d", responseStatusCode);
            XCTAssertNotNil(json[@"id"], @"Log in JSON is returning %@", json);
            *done = YES;
        }];
    });
}

- (void)testThisWeekEndpoint
{
    hxRunInMainLoop(^(BOOL *done) {
       [self.client fetchThisWeeksComicsWithCompletion:^(id json, NSURLResponse *response, NSError *error) {
           NSHTTPURLResponse* httpResponse = (NSHTTPURLResponse*)response;
            int responseStatusCode = [httpResponse statusCode];
            XCTAssertEqual(responseStatusCode, 200, @"This Week endpoint is returning a status code %d", responseStatusCode);
            XCTAssertNotNil(json[@"date"], @"This week JSON is returning %@", json);
            *done = YES;
        }];
    });
}

- (void)testIssuesWithDateEndpoint
{
    hxRunInMainLoop(^(BOOL *done) {
        [self.client fetchIssuesWithDate:@"2014-06-25" withCompletion:^(id json, NSURLResponse *response, NSError *error) {
            NSHTTPURLResponse* httpResponse = (NSHTTPURLResponse*)response;
            int responseStatusCode = [httpResponse statusCode];
            XCTAssertEqual(responseStatusCode, 200, @"Issues with date endpoint is returning a status code %d", responseStatusCode);
            XCTAssertNotNil(json[@"date"], @"Issues with date JSON is returning %@", json);
            *done = YES;
        }];
    });
}

- (void)testIssueEndpoint
{
    hxRunInMainLoop(^(BOOL *done) {
        [self.client fetchIssue:70 withCompletion:^(id json, NSURLResponse *response, NSError *error) {
            NSHTTPURLResponse* httpResponse = (NSHTTPURLResponse*)response;
            int responseStatusCode = [httpResponse statusCode];
            XCTAssertEqual(responseStatusCode, 200, @"Issue endpoint is returning a status code %d", responseStatusCode);
            XCTAssertNotNil(json[@"complete_title"], @"Pull list JSON is returning %@", json);
            *done = YES;
        }];
    });
}

- (void)testTitleEndpoint
{
    hxRunInMainLoop(^(BOOL *done) {
        [self.client fetchTitle:70 withCompletion:^(id json, NSURLResponse *response, NSError *error) {
            NSHTTPURLResponse* httpResponse = (NSHTTPURLResponse*)response;
            int responseStatusCode = [httpResponse statusCode];
            XCTAssertEqual(responseStatusCode, 200, @"Title endpoint is returning a status code %d", responseStatusCode);
            XCTAssertNotNil(json[@"id"], @"Title JSON is returning %@", json);
            *done = YES;
        }];
    });
}

- (void)testTitlesWithNumberEndpoint
{
    hxRunInMainLoop(^(BOOL *done) {
        [self.client fetchTitlesWithCompletion:^(id json, NSURLResponse *response, NSError *error) {
            NSHTTPURLResponse* httpResponse = (NSHTTPURLResponse*)response;
            int responseStatusCode = [httpResponse statusCode];
            XCTAssertEqual(responseStatusCode, 200, @"Titles w/ num endpoint is returning a status code %d", responseStatusCode);
            XCTAssertNotNil(json[@"count"], @"Titles w/ num JSON is returning %@", json);
            *done = YES;
        }];
    });
}

- (void)testPublisherEndpoint
{
    hxRunInMainLoop(^(BOOL *done) {
        [self.client fetchPublishersWithCompletion:^(id json, NSURLResponse *response, NSError *error) {
            NSHTTPURLResponse* httpResponse = (NSHTTPURLResponse*)response;
            int responseStatusCode = [httpResponse statusCode];
            XCTAssertEqual(responseStatusCode, 200, @"Publisher endpoint is returning a status code %d", responseStatusCode);
            XCTAssertNotNil(json[@"publishers"], @"Publisher JSON is returning %@", json);
            *done = YES;
        }];
    });
}

- (void)testPublisherWithNumberEndpoint
{
    hxRunInMainLoop(^(BOOL *done) {
        [self.client fetchPublisher:4 withCompletion:^(id json, NSURLResponse *response, NSError *error) {
            NSHTTPURLResponse* httpResponse = (NSHTTPURLResponse*)response;
            int responseStatusCode = [httpResponse statusCode];
            XCTAssertEqual(responseStatusCode, 200, @"Publisher w/ num endpoint is returning a status code %d", responseStatusCode);
            XCTAssertNotNil(json[@"id"], @"Publisher w/ num JSON is returning %@", json);
            *done = YES;
        }];
    });
}

@end
