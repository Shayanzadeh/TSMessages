//
//  TSMessageView.m
//  Felix Krause
//
//  Created by Felix Krause on 24.08.12.
//  Copyright (c) 2012 Felix Krause. All rights reserved.
//

#import "TSMessage.h"
#import "TSMessageView.h"
#import "TSMessage+Private.h"
#import "UIColor+HexString.h"
#import "TSMessageView+Private.h"

#define TSMessageViewPaddingX 15.0
#define TSMessageViewPaddingY 5.0
#define TSMessageViewHeight 64.0 // status bar + navigation bar

static const CGFloat kTSDistanceBetweenTitleAndSubtitle = 0.0;

@interface TSMessageView ()
@property (nonatomic) NSDictionary *config;
@property (nonatomic) UILabel *titleLabel;
@property (nonatomic) UILabel *contentLabel;
@property (nonatomic) UIImageView *iconImageView;
@property (nonatomic) UIButton *button;
@property (nonatomic) UIActivityIndicatorView *activityIndicatorView;
@property (nonatomic) UITapGestureRecognizer *tapRecognizer;
@property (nonatomic) UISwipeGestureRecognizer *swipeRecognizer;
@property (nonatomic, copy) TSMessageCallback buttonCallback;
@property (nonatomic, getter=isMessageFullyDisplayed) BOOL messageFullyDisplayed;
@end

@implementation TSMessageView

- (id)initWithTitle:(NSString *)title subtitle:(NSString *)subtitle image:(UIImage *)image type:(TSMessageType)type
{
    if ((self = [super init]))
    {
        self.userDismissEnabled = type == TSMessageTypeProgress ? NO : YES;
        self.duration = type == TSMessageTypeProgress ? TSMessageDurationEndless : TSMessageDurationAutomatic;
        self.position = TSMessagePositionTop;
        
        [self setupConfigForType:type];
        [self setupBackgroundView];
        [self setupTitle:title];
        [self setupSubtitle:subtitle];
        [self setupImage:image];
        if (type == TSMessageTypeProgress) [self setUpActivityIndicator];
        [self setupAutoresizing];
        [self setupGestureRecognizers];
    }
    
    return self;
}

#pragma mark - Setup helpers

- (void)setupConfigForType:(TSMessageType)type
{
    NSString *config;
    
    switch (type)
    {
        case TSMessageTypeError: config = @"error"; break;
        case TSMessageTypeSuccess: config = @"success"; break;
        case TSMessageTypeWarning: config = @"warning"; break;
        case TSMessageTypeProgress: config = @"progress"; break;
            
        default: config = @"message"; break;
    }
    
    self.config = [TSMessage design][config];
}

- (void)setupBackgroundView
{
    self.backgroundBlurView = [[UIView alloc] init];
    self.backgroundBlurView.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    self.backgroundBlurView.backgroundColor = [UIColor colorWithHexString:self.config[@"backgroundColor"]];
    
    [self addSubview:self.backgroundBlurView];
}

- (void)setupAutoresizing
{
    self.autoresizingMask = (self.position == TSMessagePositionTop) ?
        (UIViewAutoresizingFlexibleWidth) :
        (UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleBottomMargin);
}

- (void)setupTitle:(NSString *)title
{
    UIColor *fontColor = [UIColor colorWithHexString:self.config[@"textColor"]];
    CGFloat fontSize = [self.config[@"titleFontSize"] floatValue];
    NSString *fontName = self.config[@"titleFontName"];
    
    self.titleLabel = [[UILabel alloc] init];
    self.titleLabel.numberOfLines = 0;
    self.titleLabel.lineBreakMode = NSLineBreakByTruncatingTail;
    self.titleLabel.adjustsFontSizeToFitWidth = YES;
    self.titleLabel.shadowOffset = CGSizeMake([self.config[@"shadowOffsetX"] floatValue], [self.config[@"shadowOffsetY"] floatValue]);
    self.titleLabel.shadowColor = [UIColor colorWithHexString:self.config[@"shadowColor"]];
    self.titleLabel.backgroundColor = [UIColor clearColor];
    self.titleLabel.textColor = fontColor;
    self.titleLabel.text = title;
    self.titleLabel.font = fontName ?
        [UIFont fontWithName:fontName size:fontSize] :
        [UIFont boldSystemFontOfSize:fontSize];
    
    [self addSubview:self.titleLabel];
}

- (void)setupSubtitle:(NSString *)subtitle
{
    if (!subtitle.length) return;
    
    UIColor *contentTextColor = [UIColor colorWithHexString:self.config[@"contentTextColor"]];
    UIColor *fontColor = [UIColor colorWithHexString:self.config[@"textColor"]];
    CGFloat fontSize = [self.config[@"contentFontSize"] floatValue];
    NSString *fontName = self.config[@"contentFontName"];
    
    if (!contentTextColor) contentTextColor = fontColor;
    
    self.contentLabel = [[UILabel alloc] init];
    self.contentLabel.numberOfLines = 0;
    self.contentLabel.lineBreakMode = NSLineBreakByTruncatingTail;
//    self.contentLabel.adjustsFontSizeToFitWidth = YES;
    self.contentLabel.shadowOffset = CGSizeMake([self.config[@"shadowOffsetX"] floatValue], [self.config[@"shadowOffsetY"] floatValue]);
    self.contentLabel.shadowColor = [UIColor colorWithHexString:self.config[@"shadowColor"]];
    self.contentLabel.backgroundColor = [UIColor clearColor];
    self.contentLabel.textColor = contentTextColor;
    self.contentLabel.text = subtitle;
    self.contentLabel.font = fontName ?
        [UIFont fontWithName:fontName size:fontSize] :
        [UIFont systemFontOfSize:fontSize];
    
    [self addSubview:self.contentLabel];
}

- (void)setupImage:(UIImage *)image
{
    if (!image && self.config[@"imageName"] != [NSNull null] && [self.config[@"imageName"] length]) image = [UIImage imageNamed:self.config[@"imageName"]];
    
    self.iconImageView = [[UIImageView alloc] initWithImage:image];
    self.iconImageView.frame = CGRectMake(TSMessageViewPaddingX, round((TSMessageViewHeight-image.size.height)/2) , image.size.width, image.size.height);
    
    [self addSubview:self.iconImageView];
}

- (void)setupGestureRecognizers
{
    self.tapRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleViewTap:)];
    self.tapRecognizer.delegate = self;
    [self addGestureRecognizer:self.tapRecognizer];
    
    self.swipeRecognizer = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(handleViewSwipe:)];
    self.swipeRecognizer.direction = (self.position == TSMessagePositionTop ? UISwipeGestureRecognizerDirectionUp : UISwipeGestureRecognizerDirectionDown);
    [self addGestureRecognizer:self.swipeRecognizer];
}

- (void)setUpActivityIndicator
{
    self.activityIndicatorView = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhite];
    self.activityIndicatorView.color = [UIColor colorWithHexString:self.config[@"textColor"]];
    self.activityIndicatorView.transform = CGAffineTransformMakeScale(0.5, 0.5);
    self.activityIndicatorView.frame = CGRectMake(TSMessageViewPaddingX, (20 - self.activityIndicatorView.frame.size.height) / 2, self.activityIndicatorView.frame.size.width, self.activityIndicatorView.frame.size.height);
    [self.activityIndicatorView startAnimating];
    
    [self addSubview:self.activityIndicatorView];
}

#pragma mark - Message view attributes and actions

- (void)setButtonWithTitle:(NSString *)title callback:(TSMessageCallback)callback
{
    self.buttonCallback = callback;
    
    UIImage *buttonBackgroundImage = [[UIImage imageNamed:self.config[@"buttonBackgroundImageName"]] resizableImageWithCapInsets:UIEdgeInsetsMake(15.0, 12.0, 15.0, 11.0)];
    UIColor *buttonTitleShadowColor = [UIColor colorWithHexString:self.config[@"buttonTitleShadowColor"]];
    UIColor *buttonTitleTextColor = [UIColor colorWithHexString:self.config[@"buttonTitleTextColor"]];
    UIColor *fontColor = [UIColor colorWithHexString:self.config[@"textColor"]];
    NSString *fontName = self.config[@"titleFontName"];
    
    if (!buttonBackgroundImage) buttonBackgroundImage = [[UIImage imageNamed:self.config[@"MessageButtonBackground"]] resizableImageWithCapInsets:UIEdgeInsetsMake(15.0, 12.0, 15.0, 11.0)];
    if (!buttonTitleShadowColor) buttonTitleShadowColor = [UIColor colorWithHexString:self.config[@"shadowColor"]];
    if (!buttonTitleTextColor) buttonTitleTextColor = fontColor;
    
    self.button = [UIButton buttonWithType:UIButtonTypeCustom];
    self.button.contentEdgeInsets = UIEdgeInsetsMake(0, 5, 0, 5);
    self.button.titleLabel.font = fontName ? [UIFont fontWithName:fontName size:14] : [UIFont boldSystemFontOfSize:14];
    self.button.titleLabel.shadowOffset = CGSizeMake([self.config[@"buttonTitleShadowOffsetX"] floatValue], [self.config[@"buttonTitleShadowOffsetY"] floatValue]);
    
    [self.button setTitle:title forState:UIControlStateNormal];
    [self.button setBackgroundImage:buttonBackgroundImage forState:UIControlStateNormal];
    [self.button setTitleShadowColor:buttonTitleShadowColor forState:UIControlStateNormal];
    [self.button setTitleColor:buttonTitleTextColor forState:UIControlStateNormal];
    [self.button addTarget:self action:@selector(handleButtonTap:) forControlEvents:UIControlEventTouchUpInside];
    [self.button sizeToFit];
    
    self.button.frame = CGRectMake(self.viewController.view.bounds.size.width - TSMessageViewPaddingX - self.button.frame.size.width, 0, self.button.frame.size.width, 31);
    
    [self addSubview:self.button];
}

- (void)displayOrEnqueue {
    [TSMessage displayOrEnqueueMessage:self];
}

- (void)displayPermanently {
    [TSMessage displayPermanentMessage:self];
}

#pragma mark - View handling

- (void)didMoveToWindow
{
    [super didMoveToWindow];
    
    if (self.duration == TSMessageDurationEndless && self.superview && !self.window)
    {
        [self dismiss];
    }
}

- (void)layoutSubviews
{
    [super layoutSubviews];
    
    CGFloat screenWidth = self.viewController.view.bounds.size.width;
    CGFloat textSpaceRight = self.button.frame.size.width + TSMessageViewPaddingX;
    CGFloat textSpaceLeft = TSMessageViewPaddingX;
    CGFloat messageHeight;
    
    self.contentLabel.textAlignment = NSTextAlignmentLeft;

    // status bar style
    if (self.activityIndicatorView)
    {
        messageHeight = 20.0;
        
        self.titleLabel.frame = CGRectMake(self.activityIndicatorView.frame.origin.x + self.activityIndicatorView.frame.size.width + 5,
                                           1,
                                           screenWidth - self.activityIndicatorView.frame.origin.x - self.activityIndicatorView.frame.size.width - TSMessageViewPaddingX - 5,
                                           messageHeight - 1);
        [self sizeToFitIfAppropriate:self.titleLabel];
        
        // vertically center title
        self.titleLabel.center = CGPointMake(self.titleLabel.center.x, messageHeight / 2);
        
        // horizontally center activity indicator & title
        CGFloat centerOffset = (screenWidth - self.titleLabel.frame.origin.x - self.titleLabel.frame.size.width - TSMessageViewPaddingX) / 2;
        self.activityIndicatorView.frame = CGRectOffset(self.activityIndicatorView.frame, centerOffset, 0);
        self.titleLabel.frame = CGRectOffset(self.titleLabel.frame, centerOffset, 0);
    }
    // navigation bar style
    else
    {
        messageHeight = TSMessageViewHeight;

        // there's no icon
        if (!self.iconImageView.image)
        {
            self.titleLabel.frame = CGRectMake(TSMessageViewPaddingX, TSMessageViewPaddingY, screenWidth-(TSMessageViewPaddingX*2), messageHeight-(TSMessageViewPaddingY*2));
            [self sizeToFitIfAppropriate:self.titleLabel];
            
            // there's no subtitle
            if (!self.subtitle)
            {
                // horizontally & vertically center title
                self.titleLabel.center = CGPointMake(screenWidth / 2, messageHeight / 2);
            }
            else
            {
                self.contentLabel.frame = CGRectMake(TSMessageViewPaddingX,
                                                     self.titleLabel.frame.origin.y + self.titleLabel.frame.size.height + kTSDistanceBetweenTitleAndSubtitle,
                                                     screenWidth-(TSMessageViewPaddingX*2),
                                                     messageHeight - kTSDistanceBetweenTitleAndSubtitle - self.titleLabel.frame.origin.y - self.titleLabel.frame.size.height - TSMessageViewPaddingY);
                [self sizeToFitIfAppropriate:self.contentLabel];
                self.contentLabel.textAlignment = NSTextAlignmentCenter;
            
                // horizontally center title & subtitle
                self.contentLabel.center = CGPointMake(screenWidth / 2, self.contentLabel.center.y);
                self.titleLabel.center = CGPointMake(screenWidth / 2, self.titleLabel.center.y);
                
                // vertically center title & subtitle
                CGFloat centerOffset = (messageHeight - (self.contentLabel.frame.origin.y + self.contentLabel.frame.size.height + TSMessageViewPaddingY)) / 2;
                self.titleLabel.frame = CGRectOffset(self.titleLabel.frame, 0, centerOffset);
                self.contentLabel.frame = CGRectOffset(self.contentLabel.frame, 0, centerOffset);
            }
        }
        // there's an icon
        else
        {
            textSpaceLeft += self.iconImageView.image.size.width + self.iconImageView.frame.origin.x;

            self.titleLabel.frame = CGRectMake(textSpaceLeft, TSMessageViewPaddingY, screenWidth - textSpaceLeft - textSpaceRight - self.titleLabel.frame.size.width, messageHeight - (TSMessageViewPaddingY * 2));
            [self sizeToFitIfAppropriate:self.titleLabel];

            if (!self.subtitle)
            {
                // vertically center title
                self.titleLabel.center = CGPointMake(self.titleLabel.center.x, messageHeight / 2);
            }
            else
            {
                self.contentLabel.frame = CGRectMake(textSpaceLeft,
                                                     self.titleLabel.frame.origin.y + self.titleLabel.frame.size.height + kTSDistanceBetweenTitleAndSubtitle,
                                                     screenWidth - textSpaceLeft - textSpaceRight - self.contentLabel.frame.size.width,
                                                     messageHeight - kTSDistanceBetweenTitleAndSubtitle - self.titleLabel.frame.origin.y - self.titleLabel.frame.size.height - TSMessageViewPaddingY);
                [self sizeToFitIfAppropriate:self.contentLabel];

                // vertically center title & subtitle
                CGFloat centerOffset = (messageHeight - (self.contentLabel.frame.origin.y + self.contentLabel.frame.size.height + TSMessageViewPaddingY)) / 2;
                self.titleLabel.frame = CGRectOffset(self.titleLabel.frame, 0, centerOffset);
                self.contentLabel.frame = CGRectOffset(self.contentLabel.frame, 0, centerOffset);
            }
        }
    }
    
    self.frame = CGRectMake(0, 0, screenWidth, messageHeight);
    
//    // button
//    if (self.button)
//    {
//        self.button.center = CGPointMake([self.button center].x, round(currentHeight / 2.0));
//    
//        self.button.frame = CGRectMake(self.frame.size.width - textSpaceRight,
//                                       round((self.frame.size.height / 2.0) - self.button.frame.size.height / 2.0),
//                                       self.button.frame.size.width,
//                                       self.button.frame.size.height);
//    }
    
    CGRect backgroundFrame = CGRectMake(0, 0, screenWidth, messageHeight);
    
    // increase frame of background view because of the spring animation
    if (self.position == TSMessagePositionTop)
        backgroundFrame = UIEdgeInsetsInsetRect(backgroundFrame, UIEdgeInsetsMake(-30.f, 0.f, 0.f, 0.f));
    else
        backgroundFrame = UIEdgeInsetsInsetRect(backgroundFrame, UIEdgeInsetsMake(0.f, 0.f, -30.f, 0.f));
    
    self.backgroundBlurView.frame = backgroundFrame;
}

- (void)prepareForDisplay
{
    [self setNeedsLayout];
    [self layoutIfNeeded];
    
    CGFloat actualHeight = self.frame.size.height;
    CGFloat topPosition = -actualHeight;
    
    if (self.position == TSMessagePositionBottom)
    {
        topPosition = self.viewController.view.bounds.size.height;
    }
    
    self.frame = CGRectMake(0, topPosition, self.viewController.view.bounds.size.width, actualHeight);
}

- (CGPoint)centerForDisplay
{
    CGFloat y;
    CGFloat heightOffset = CGRectGetHeight(self.frame) / 2;
    
    if (self.position == TSMessagePositionTop)
        y = heightOffset;
    else
        y = self.viewController.view.bounds.size.height - heightOffset;
    
    CGPoint center = CGPointMake(self.center.x, y);
    
    return center;
}

#pragma mark - Actions

- (void)handleButtonTap:(id) sender
{
    if (self.buttonCallback)
    {
        self.buttonCallback(self);
    }
}

- (void)handleViewTap:(UITapGestureRecognizer *)tapRecognizer
{
    if (tapRecognizer.state != UIGestureRecognizerStateRecognized) return;
    
    if (self.isUserDismissEnabled)
    {
        [self dismiss];
    }
    
    if (self.tapCallback)
    {
        self.tapCallback(self);
    }
}

- (void)handleViewSwipe:(UISwipeGestureRecognizer *)swipeRecognizer
{
    if (swipeRecognizer.state != UIGestureRecognizerStateRecognized) return;
    
    if (self.isUserDismissEnabled)
    {
        [self dismiss];
    }
    
    if (self.swipeCallback)
    {
        self.swipeCallback(self);
    }
}

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldReceiveTouch:(UITouch *)touch
{
    return !([touch.view isKindOfClass:[UIControl class]]);
}

- (void)dismiss
{
    if (self == [TSMessage sharedMessage].currentMessage)
    {
        [[TSMessage sharedMessage] performSelectorOnMainThread:@selector(dismissCurrentMessage) withObject:nil waitUntilDone:NO];
    }
    else
    {
        [[TSMessage sharedMessage] performSelectorOnMainThread:@selector(dismissMessage:) withObject:self waitUntilDone:NO];
    }
}

- (void)setPosition:(TSMessagePosition)position {
    _position = position;
    
    self.swipeRecognizer.direction = (self.position == TSMessagePositionTop ? UISwipeGestureRecognizerDirectionUp : UISwipeGestureRecognizerDirectionDown);
}

#pragma mark - Private

- (NSString *)title
{
    return self.titleLabel.text;
}

- (NSString *)subtitle
{
    return self.contentLabel.text;
}

/** Only performs a sizeToFit if the new size is not bigger than the current frame size */
- (void)sizeToFitIfAppropriate:(UIView *)view
{
    CGSize proposedSize = [view sizeThatFits:view.frame.size];
    if (proposedSize.height <= view.frame.size.height && proposedSize.width <= view.frame.size.width)
    {
        [view sizeToFit];
    }
}

@end
