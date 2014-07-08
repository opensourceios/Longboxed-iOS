//
//  LBXDashboardViewController.m
//  Longboxed-iOS
//
//  Created by johnrhickey on 7/1/14.
//  Copyright (c) 2014 Longboxed. All rights reserved.
//

#import "LBXHomeViewController.h"
#import "LBXNavigationViewController.h"
#import "LBXDataStore.h"
#import "LBXThisWeeksComics.h"
#import "LBXBundleOld.h"
#import "EasyTableView.h"

#import <UIImageView+AFNetworking.h>
#import <TWMessageBarManager.h>
#import <UICKeyChainStore.h>

#define TABLECELL_WIDTH				180

#define LABEL_TAG					100
#define IMAGE_TAG					101
#define TITLE_FONT_SIZE				16

@interface LBXHomeViewController ()<EasyTableViewDelegate>

@property (nonatomic) LBXThisWeeksComics *thisWeeksComics;
@property (nonatomic) LBXBundleOld *bundle;
@property (nonatomic) EasyTableView *easyTableView;
@property (nonatomic, strong) IBOutlet UILabel *bundleCountLabel;

@end

@implementation LBXHomeViewController

LBXNavigationViewController *navigationController;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
        self.navigationItem.titleView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"longboxed_full"]];
        
        LBXNavigationViewController *navController = [LBXNavigationViewController new];
        [navController addPaperButtonToViewController:self];
        
        self.view.backgroundColor = [UIColor whiteColor];
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    _bundleCountLabel.text = @"";
    [self refresh];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    self.navigationItem.titleView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"longboxed_full"]];
}

- (void)viewWillLayoutSubviews
{
    [super viewWillLayoutSubviews];
    navigationController = (LBXNavigationViewController *)self.navigationController;
    [navigationController.menu setNeedsLayout];
}


- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark Private Methods

- (void)refresh
{
    [[LBXDataStore sharedStore] fetchThisWeeksComics:^(NSArray *response, NSError *error) {
        _thisWeeksComics = [[LBXThisWeeksComics alloc] initThisWeeksComicsWithIssues:response];
        dispatch_async(dispatch_get_main_queue(), ^{
            [self setupEasyTableViewWithNumCells:_thisWeeksComics.longboxedIDs.count];
        });
    }];
    
    if ([UICKeyChainStore keyChainStore][@"id"]) {
        [[LBXDataStore sharedStore] fetchBundles:^(NSArray *response, NSError *error) {
            _bundle = [[LBXBundleOld alloc] initBundle:response];
            dispatch_async(dispatch_get_main_queue(), ^{
                _bundleCountLabel.text = [NSString stringWithFormat:@"%lu", (unsigned long)_bundle.longboxedIDs.count];
            });
        }];
    }
    else _bundleCountLabel.text = @"0";
}

#pragma mark EasyTableView Initialization

- (void)setupEasyTableViewWithNumCells:(NSUInteger)count {
	CGRect frameRect = CGRectMake(0, (self.view.frame.size.height + self.navigationController.navigationBar.frame.size.height)/2, self.view.bounds.size.width, (self.view.frame.size.height - self.navigationController.navigationBar.frame.size.height-44)/2);
	EasyTableView *view	= [[EasyTableView alloc] initWithFrame:frameRect numberOfColumns:count ofWidth:180];

	self.easyTableView	= view;
	
	self.easyTableView.delegate						= self;
	self.easyTableView.tableView.backgroundColor	= [UIColor clearColor];
	self.easyTableView.tableView.separatorColor		= [UIColor clearColor];
	self.easyTableView.cellBackgroundColor			= [UIColor clearColor];
	self.easyTableView.autoresizingMask				= UIViewAutoresizingFlexibleBottomMargin | UIViewAutoresizingFlexibleWidth;
	[self.view addSubview:self.easyTableView];
}

#pragma mark - EasyTableViewDelegate

- (UIView *)easyTableView:(EasyTableView *)easyTableView viewForRect:(CGRect)rect {
	// Create a container view for an EasyTableView cell
	UIView *container = [[UIView alloc] initWithFrame:rect];;
	
	// Setup an image view to display an image
	UIImageView *imageView	= [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, rect.size.width-20, rect.size.height)];
	imageView.tag			= IMAGE_TAG;
	imageView.contentMode	= UIViewContentModeScaleAspectFill;
	
	[container addSubview:imageView];
	
	return container;
}

// Second delegate populates the views with data from a data source

- (void)easyTableView:(EasyTableView *)easyTableView setDataForView:(UIView *)view forIndexPath:(NSIndexPath *)indexPath {
	
	// Set the image for the given index
	__weak UIImageView *comicImageView = (UIImageView *)[view viewWithTag:IMAGE_TAG];
    CGRect contentViewBound = comicImageView.bounds;
    
    // If an image exists, fetch it. Else use the generated UIImage
    if ([_thisWeeksComics.coverImages objectAtIndex:indexPath.row] != (id)[NSNull null]) {
        
        NSString *urlString = [_thisWeeksComics.coverImages objectAtIndex:indexPath.row];
        
        // Show the network activity icon
        [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:YES];
        
        // Get the image from the URL and set it
        [comicImageView setImageWithURLRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:urlString]] placeholderImage:[UIImage imageNamed:@"black"] success:^(NSURLRequest *request, NSHTTPURLResponse *response, UIImage *image) {
            
            // Hide the network activity icon
            [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];
            
            if (request) {
                
                // Hide the network activity icon
                [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];
                
                [UIView transitionWithView:comicImageView
                                  duration:0.5f
                                   options:UIViewAnimationOptionTransitionCrossDissolve
                                animations:^{[comicImageView setImage:image];}
                                completion:NULL];
                
                comicImageView.contentMode = UIViewContentModeScaleAspectFit;
            }
            else {
                comicImageView.image = image;
            }
            
        } failure:^(NSURLRequest *request, NSHTTPURLResponse *response, NSError *error) {
            
            // Hide the network activity icon
            [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];
            
            // Don't show the error for NSURLErrorDomain -999 because that's just a cancelled image request due to scrolling
            if ([error.localizedDescription rangeOfString:@"NSURLErrorDomain error -999"].location == NSNotFound) {
                [[TWMessageBarManager sharedInstance] showMessageWithTitle:@"Network Error"
                                                               description:@"Check your network connection."
                                                                      type:TWMessageBarMessageTypeError];
            }
        }];
        
        CGRect imageViewFrame = comicImageView.frame;
        // change x position
        imageViewFrame.origin.y = contentViewBound.size.height - imageViewFrame.size.height;
        // assign the new frame
        comicImageView.frame = imageViewFrame;
        comicImageView.contentMode = UIViewContentModeScaleAspectFill;
    }
    
    else {
        UIImage *defaultImage = [UIImage imageNamed:@"black"];
        comicImageView.image = defaultImage;
        
    }

}

@end
