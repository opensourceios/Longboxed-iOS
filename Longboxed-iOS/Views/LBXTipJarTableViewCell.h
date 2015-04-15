//
//  LBXTipJarTableViewCell.h
//  
//
//  Created by johnrhickey on 12/17/14.
//
//

#import <UIKit/UIKit.h>

@interface LBXTipJarTableViewCell : UITableViewCell

@property (nonatomic, strong) IBOutlet UILabel *tipLabel;
@property (nonatomic, weak) IBOutlet UIButton *smallTipButton;
@property (nonatomic, weak) IBOutlet UIButton *mediumTipButton;
@property (nonatomic, weak) IBOutlet UIButton *largeTipButton;

@end
