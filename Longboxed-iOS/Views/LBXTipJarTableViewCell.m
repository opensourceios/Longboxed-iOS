//
//  LBXTipJarTableViewCell.m
//  
//
//  Created by johnrhickey on 12/17/14.
//
//

#import "LBXTipJarTableViewCell.h"
#import <StoreKit/StoreKit.h>
#import "LBXLogging.h"
#import <SVProgressHUD.h>
#import "LBXControllerServices.h"

@interface LBXTipJarTableViewCell () <SKProductsRequestDelegate, SKPaymentTransactionObserver>

@property (nonatomic, weak) IBOutlet UIButton *smallTipButton;
@property (nonatomic, weak) IBOutlet UIButton *mediumTipButton;
@property (nonatomic, weak) IBOutlet UIButton *largeTipButton;

@end

@implementation LBXTipJarTableViewCell

- (void)awakeFromNib {
    // Initialization code
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

# pragma mark In-App Purchase

- (void)productsRequest:(SKProductsRequest *)request didReceiveResponse:(SKProductsResponse *)response {
    SKProduct *validProduct = nil;
    NSUInteger count = [response.products count];
    if(count > 0){
        validProduct = [response.products objectAtIndex:0];
        [LBXLogging logMessage:[NSString stringWithFormat:@"Triggered in app purchase of $%@", validProduct.price]];
        [self purchase:validProduct];
    }
    else if(!validProduct){
        [SVProgressHUD dismiss];
        [LBXControllerServices showAlertWithTitle:@"Unable to Connect to Apple Servers" andMessage:@"Longboxed is unable to retrieve the in-app purchases from iTunes. Please try again later."];
    }
}

- (IBAction)purchase:(SKProduct *)product{
    SKPayment *payment = [SKPayment paymentWithProduct:product];
    [[SKPaymentQueue defaultQueue] addTransactionObserver:self];
    [[SKPaymentQueue defaultQueue] addPayment:payment];
}

- (void)paymentQueue:(SKPaymentQueue *)queue updatedTransactions:(NSArray *)transactions{
    for(SKPaymentTransaction *transaction in transactions){
        switch (transaction.transactionState){
            case SKPaymentTransactionStatePurchasing: [LBXLogging logMessage:@"Purchasing..."];
                //called when the user is in the process of purchasing, do not add any of your own code here.
                break;
            case SKPaymentTransactionStatePurchased:
                [SVProgressHUD dismiss];
                //this is called when the user has successfully purchased the package (Cha-Ching!)
                [[SKPaymentQueue defaultQueue] finishTransaction:transaction];
                [LBXLogging logMessage:@"In-app purchase made!"];
                break;
            case SKPaymentTransactionStateRestored:
                [SVProgressHUD dismiss];
                [LBXLogging logMessage:@"Restored in app purchase"];
                [[SKPaymentQueue defaultQueue] finishTransaction:transaction];
                break;
            case SKPaymentTransactionStateFailed:
                [SVProgressHUD dismiss];
                if(transaction.error.code != SKErrorPaymentCancelled){
                    [LBXLogging logMessage:@"Failed/cancelled in app purchase"];
                }
                [[SKPaymentQueue defaultQueue] finishTransaction:transaction];
                break;
            case SKPaymentTransactionStateDeferred:
                [SVProgressHUD dismiss];
                [LBXLogging logMessage:@"Deferred payment via Ask to Buy"];
                break;
        }
    }
}

- (IBAction)sendTip:(id)sender
{
    if([SKPaymentQueue canMakePayments]) {
        // Load in app purchase identifiers from json file
        NSMutableDictionary *identifierDict = [NSMutableDictionary new];
        NSString *path = [[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent:@"InAppPurchase.json"];
        if ([[NSFileManager defaultManager] fileExistsAtPath:path]) {
            identifierDict = [NSJSONSerialization JSONObjectWithData:[NSData dataWithContentsOfFile:path]
                                                             options:kNilOptions
                                                               error:nil];
        }
        
        NSString *identifierString = [NSString new];
        
        UIButton *button = (UIButton *)sender;
        switch ([button tag]) {
            case 0:
                identifierString = identifierDict[@"Small Tip"];
                break;
            case 1:
                identifierString = identifierDict[@"Medium Tip"];
                break;
            case 2:
                identifierString = identifierDict[@"Large Tip"];
                break;
        }
        
        [SVProgressHUD showWithStatus:@"Tip In Progress"];
        SKProductsRequest *productsRequest = [[SKProductsRequest alloc] initWithProductIdentifiers:[NSSet setWithObject:identifierString]];
        productsRequest.delegate = self;
        [productsRequest start];
    }
    else{
        [SVProgressHUD dismiss];
        [LBXControllerServices showAlertWithTitle:@"Unable to Purchase" andMessage:@"You are unable to perform in-app purchases. This is likely due to parental controls."];
    }
}

@end
