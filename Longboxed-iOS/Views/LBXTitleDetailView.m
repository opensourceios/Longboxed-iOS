//
//  LBXTitleDetailView.m
//  Longboxed-iOS
//
//  Created by johnrhickey on 8/10/14.
//  Copyright (c) 2014 Longboxed. All rights reserved.
//

#import "LBXTitleDetailView.h"

@implementation LBXTitleDetailView

- (id)init {
    NSArray *subviewArray = [[NSBundle mainBundle] loadNibNamed:@"LBXTitleDetailView" owner:self options:nil];
    id mainView = [subviewArray objectAtIndex:0];
    
    return mainView;
}

@end
