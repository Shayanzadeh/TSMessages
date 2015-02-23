//
//  TSMessageView+Private.h
//  Felix Krause
//
//  Created by Felix Krause on 24.08.12.
//  Copyright (c) 2012 Felix Krause. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "TSMessageView.h"

typedef NS_ENUM(NSUInteger, TSMessageViewType)
{
    TSMessageViewTypeImageTitleSubtitle,
    TSMessageViewTypeImageTitle,
    TSMessageViewTypeImageSubtitle,
    TSMessageViewTypeTitleSubtitle,
    TSMessageViewTypeTitle,
    TSMessageViewTypeSubtitle,
};

@interface TSMessageView (Private)

@property (nonatomic, strong, readonly) NSString *title;
@property (nonatomic, strong, readonly) NSString *subtitle;
@property (nonatomic, assign, readonly) CGPoint centerForDisplay;
@property (nonatomic, assign, getter=isMessageFullyDisplayed) BOOL messageFullyDisplayed;

@end
