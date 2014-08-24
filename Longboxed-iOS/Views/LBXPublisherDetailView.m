//
//  LBXPublisherDetailView.m
//  Longboxed-iOS
//
//  Created by johnrhickey on 8/23/14.
//  Copyright (c) 2014 Longboxed. All rights reserved.
//

#import "LBXPublisherDetailView.h"

@implementation LBXPublisherDetailView

- (id)init {
    NSArray *subviewArray = [[NSBundle mainBundle] loadNibNamed:@"LBXPublisherDetailView" owner:self options:nil];
    id mainView = [subviewArray objectAtIndex:0];
    
    return mainView;
}

@end
