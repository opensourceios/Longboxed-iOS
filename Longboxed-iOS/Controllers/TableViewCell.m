//
//  TableViewCell.m
//  Pulse
//
//  Created by Bushra on 7/11/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "TableViewCell.h"
#import "ActualTableViewCell.h"

@implementation TableViewCell
@synthesize horizontalTableView;
@synthesize contentArray;

float imageWidth;

- (void)awakeFromNib {
    // Initialization code
    self.horizontalTableView.frame = CGRectMake(self.horizontalTableView.frame.origin.x, self.horizontalTableView.frame.origin.y, 0, self.horizontalTableView.frame.size.height);
    self.horizontalTableView.rowHeight = 200;
}

- (NSString *) reuseIdentifier {
    return @"Cell";
}
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    // Return the number of sections.
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return 4;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *CellIdentifier = @"ActualTableViewCell";
    ActualTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
	if(!cell)
    {
        NSArray *nib = [[NSBundle mainBundle] loadNibNamed:@"ActualTableViewCell"
													 owner:self options:nil];
		for (id oneObject in nib) if ([oneObject isKindOfClass:[ActualTableViewCell class]])
			cell = (ActualTableViewCell *)oneObject;
    }
    dispatch_queue_t concurrentQueue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
    
    dispatch_async(concurrentQueue, ^{        
        UIImage *image = nil;        
        image = [UIImage imageNamed:[[contentArray objectAtIndex:indexPath.row] objectForKey:@"ImageName"]];
        
        dispatch_async(dispatch_get_main_queue(), ^{
            [cell.tileImg setImage:image]; 
        });
        imageWidth = cell.tileImg.frame.size.height;
    }); 
    [cell.titleName setText:[[contentArray objectAtIndex:indexPath.row] objectForKey:@"ImageName"]];
    CGAffineTransform rotate= CGAffineTransformMakeRotation(M_PI_2);
    cell.transform=rotate;
    return cell;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    return imageWidth;
}

- (void) tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{
    NSLog(@"values: %@",[contentArray objectAtIndex:indexPath.row]);  
//    self.detailObj=[[DetailViewController alloc] initWithNibName:@"DetailViewController" bundle:nil];
    
}



@end
