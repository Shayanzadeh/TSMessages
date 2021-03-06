//
//  TSMessageView.h
//  Felix Krause
//
//  Created by Felix Krause on 24.08.12.
//  Copyright (c) 2012 Felix Krause. All rights reserved.
//

#import "TSMessage.h"
#import <UIKit/UIKit.h>

@interface TSMessageView : UIView <UIGestureRecognizerDelegate>

/** The view controller this message is displayed in */
@property (nonatomic, weak) UIViewController *viewController;

/** The duration of the displayed message. If it is 0.0, it will automatically be calculated */
@property (nonatomic, assign) CGFloat duration;

/** Use it's frame to find height of displayed message */
@property (nonatomic) UIView *backgroundView;

/** The position of the message (top or bottom) */
@property (nonatomic, assign) TSMessagePosition position;

/** The callback that should be invoked, when the user taps the message */
@property (nonatomic, copy) TSMessageCallback tapCallback;

/** The callback that should be invoked, when the user swipes the message */
@property (nonatomic, copy) TSMessageCallback swipeCallback;

/** Define whether or not the message can be dismissed by the user by tapping and swipping */
@property (nonatomic, assign, getter=isUserDismissEnabled) BOOL userDismissEnabled;

- (instancetype)initWithTitle:(NSString *)title subtitle:(NSString *)subtitle image:(UIImage *)image type:(TSMessageType)type;

/** Dismisses this message view */
- (void)dismiss;

/** Adds a button with a callback that gets invoked when the button is tapped */
- (void)setButtonWithTitle:(NSString *)title callback:(TSMessageCallback)callback;

/** Displays or enqueues the message view. */
- (void)displayOrEnqueue;

/** Displays the message permanently. */
- (void)displayPermanently;

/** Is the message currently fully displayed? Is set as soon as the message is really fully visible */
- (BOOL)isMessageFullyDisplayed;
@end
