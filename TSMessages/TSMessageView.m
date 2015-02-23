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

@interface TSMessageView ()

@property (nonatomic, strong) NSDictionary *config;
@property (nonatomic, strong) UILabel *titleLabel;
@property (nonatomic, strong) UILabel *contentLabel;
@property (nonatomic, strong) UIImageView *iconImageView;
@property (nonatomic, strong) UIButton *button;
@property (nonatomic, strong) UIActivityIndicatorView *activityIndicatorView;
@property (nonatomic, strong) UITapGestureRecognizer *tapRecognizer;
@property (nonatomic, strong) UISwipeGestureRecognizer *swipeRecognizer;
@property (nonatomic, copy) TSMessageCallback buttonCallback;
@property (nonatomic, assign, getter=isMessageFullyDisplayed) BOOL messageFullyDisplayed;
@property (nonatomic, assign) TSMessageViewType messageViewType;

@end

@implementation TSMessageView

- (instancetype)initWithTitle:(NSString *)title subtitle:(NSString *)subtitle image:(UIImage *)image type:(TSMessageType)type
{
    self = [super init];
    
    if (self)
    {
        self.userDismissEnabled = type == TSMessageTypeProgress ? NO : YES;
        self.duration = type == TSMessageTypeProgress ? TSMessageDurationEndless : TSMessageDurationAutomatic;
        self.position = TSMessagePositionTop;
        
        [self setupConfigForType:type];
        
        if (image || (self.config[@"imageName"] != [NSNull null] && [self.config[@"imageName"] length]))
        {
            if (title.length)
            {
                self.messageViewType =  subtitle.length ? TSMessageViewTypeImageTitleSubtitle : TSMessageViewTypeImageTitle;
            }
            else
            {
                self.messageViewType = TSMessageViewTypeImageSubtitle;
            }
        }
        else
        {
            if (title.length)
            {
                self.messageViewType = subtitle.length ? TSMessageViewTypeTitleSubtitle : TSMessageViewTypeTitle;
            }
            else
            {
                self.messageViewType = TSMessageViewTypeSubtitle;
            }
        }
        
        [self setupBackgroundView];
        [self setupImage:image];
        [self setupTitle:title];
        [self setupSubtitle:subtitle];
        if (type == TSMessageTypeProgress) [self setUpActivityIndicator];
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
    self.backgroundView = [UIView new];
    self.backgroundView.translatesAutoresizingMaskIntoConstraints = NO;
    self.backgroundView.backgroundColor = [UIColor colorWithHexString:self.config[@"backgroundColor"]];
    
    [self addSubview:self.backgroundView];
    
    [self addConstraint:[NSLayoutConstraint constraintWithItem:self.backgroundView
                                                     attribute:NSLayoutAttributeLeading
                                                     relatedBy:NSLayoutRelationEqual
                                                        toItem:self
                                                     attribute:NSLayoutAttributeLeft
                                                    multiplier:1.0
                                                      constant:0.0]];
    
    [self addConstraint:[NSLayoutConstraint constraintWithItem:self.backgroundView
                                                     attribute:NSLayoutAttributeTrailing
                                                     relatedBy:NSLayoutRelationEqual
                                                        toItem:self
                                                     attribute:NSLayoutAttributeRight
                                                    multiplier:1.0
                                                      constant:0.0]];
    
    [self addConstraint:[NSLayoutConstraint constraintWithItem:self.backgroundView
                                                     attribute:NSLayoutAttributeTop
                                                     relatedBy:NSLayoutRelationEqual
                                                        toItem:self
                                                     attribute:NSLayoutAttributeTop
                                                    multiplier:1.0
                                                      constant:0.0]];
    
    [self addConstraint:[NSLayoutConstraint constraintWithItem:self.backgroundView
                                                     attribute:NSLayoutAttributeBottom
                                                     relatedBy:NSLayoutRelationEqual
                                                        toItem:self
                                                     attribute:NSLayoutAttributeBottom
                                                    multiplier:1.0
                                                      constant:0.0]];
}

- (void)setupTitle:(NSString *)title
{
    if (self.messageViewType == TSMessageViewTypeSubtitle || self.messageViewType == TSMessageViewTypeTitle) return;
    
    UIColor *fontColor = [UIColor colorWithHexString:self.config[@"textColor"]];
    CGFloat fontSize = [self.config[@"titleFontSize"] floatValue];
    NSString *fontName = self.config[@"titleFontName"];
    
    self.titleLabel = [UILabel new];
    self.titleLabel.numberOfLines = 1;
    self.titleLabel.lineBreakMode = NSLineBreakByTruncatingTail;
    self.titleLabel.adjustsFontSizeToFitWidth = YES;
    self.titleLabel.shadowOffset = CGSizeMake([self.config[@"shadowOffsetX"] floatValue], [self.config[@"shadowOffsetY"] floatValue]);
    self.titleLabel.shadowColor = [UIColor colorWithHexString:self.config[@"shadowColor"]];
    self.titleLabel.backgroundColor = [UIColor clearColor];
    self.titleLabel.textColor = fontColor;
    self.titleLabel.text = title;
    self.titleLabel.translatesAutoresizingMaskIntoConstraints = NO;
    self.titleLabel.font = fontName ?
        [UIFont fontWithName:fontName size:fontSize] :
        [UIFont boldSystemFontOfSize:fontSize];
    
    [self addSubview:self.titleLabel];
    
    switch (self.messageViewType)
    {
        case TSMessageViewTypeImageTitle:
            [self addConstraint:[NSLayoutConstraint constraintWithItem:self.titleLabel
                                                             attribute:NSLayoutAttributeBottom
                                                             relatedBy:NSLayoutRelationEqual
                                                                toItem:self
                                                             attribute:NSLayoutAttributeBottom
                                                            multiplier:1.0
                                                              constant:-10.0]];
        case TSMessageViewTypeImageTitleSubtitle:
            [self addConstraint:[NSLayoutConstraint constraintWithItem:self.titleLabel
                                                             attribute:NSLayoutAttributeTop
                                                             relatedBy:NSLayoutRelationEqual
                                                                toItem:self
                                                             attribute:NSLayoutAttributeTop
                                                            multiplier:1.0
                                                              constant:10.0]];
            
            [self addConstraint:[NSLayoutConstraint constraintWithItem:self.titleLabel
                                                             attribute:NSLayoutAttributeLeading
                                                             relatedBy:NSLayoutRelationEqual
                                                                toItem:self.iconImageView
                                                             attribute:NSLayoutAttributeRight
                                                            multiplier:1.0
                                                              constant:10.0]];
            
            [self addConstraint:[NSLayoutConstraint constraintWithItem:self.titleLabel
                                                             attribute:NSLayoutAttributeTrailing
                                                             relatedBy:NSLayoutRelationEqual
                                                                toItem:self
                                                             attribute:NSLayoutAttributeRight
                                                            multiplier:1.0
                                                              constant:-10.0]];
            
            self.titleLabel.textAlignment = NSTextAlignmentLeft;
            break;
        case TSMessageViewTypeTitle:
            [self addConstraint:[NSLayoutConstraint constraintWithItem:self.titleLabel
                                                             attribute:NSLayoutAttributeBottom
                                                             relatedBy:NSLayoutRelationEqual
                                                                toItem:self
                                                             attribute:NSLayoutAttributeBottom
                                                            multiplier:1.0
                                                              constant:-10.0]];
        case TSMessageViewTypeTitleSubtitle:
            [self addConstraint:[NSLayoutConstraint constraintWithItem:self.titleLabel
                                                             attribute:NSLayoutAttributeTop
                                                             relatedBy:NSLayoutRelationEqual
                                                                toItem:self
                                                             attribute:NSLayoutAttributeTop
                                                            multiplier:1.0
                                                              constant:10.0]];
            
            [self addConstraint:[NSLayoutConstraint constraintWithItem:self.titleLabel
                                                             attribute:NSLayoutAttributeLeading
                                                             relatedBy:NSLayoutRelationEqual
                                                                toItem:self
                                                             attribute:NSLayoutAttributeLeft
                                                            multiplier:1.0
                                                              constant:10.0]];
            
            [self addConstraint:[NSLayoutConstraint constraintWithItem:self.titleLabel
                                                             attribute:NSLayoutAttributeTrailing
                                                             relatedBy:NSLayoutRelationEqual
                                                                toItem:self
                                                             attribute:NSLayoutAttributeRight
                                                            multiplier:1.0
                                                              constant:-10.0]];
            
            self.titleLabel.textAlignment = NSTextAlignmentCenter;
            break;
        default:
            break;
    }
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
    self.contentLabel.numberOfLines = 2;
    self.contentLabel.lineBreakMode = NSLineBreakByTruncatingTail;
//    self.contentLabel.adjustsFontSizeToFitWidth = YES;
    self.contentLabel.shadowOffset = CGSizeMake([self.config[@"shadowOffsetX"] floatValue], [self.config[@"shadowOffsetY"] floatValue]);
    self.contentLabel.shadowColor = [UIColor colorWithHexString:self.config[@"shadowColor"]];
    self.contentLabel.backgroundColor = [UIColor clearColor];
    self.contentLabel.textColor = contentTextColor;
    self.contentLabel.text = subtitle;
    self.contentLabel.translatesAutoresizingMaskIntoConstraints = NO;
    self.contentLabel.font = fontName ?
        [UIFont fontWithName:fontName size:fontSize] :
        [UIFont systemFontOfSize:fontSize];
    
    [self addSubview:self.contentLabel];
    
    switch (self.messageViewType)
    {
        case TSMessageViewTypeImageTitleSubtitle:
        case TSMessageViewTypeImageSubtitle:
            [self addConstraint:[NSLayoutConstraint constraintWithItem:self.contentLabel
                                                             attribute:NSLayoutAttributeBottom
                                                             relatedBy:NSLayoutRelationEqual
                                                                toItem:self
                                                             attribute:NSLayoutAttributeBottom
                                                            multiplier:1.0
                                                              constant:-10.0]];
            
            [self addConstraint:[NSLayoutConstraint constraintWithItem:self.contentLabel
                                                             attribute:NSLayoutAttributeLeading
                                                             relatedBy:NSLayoutRelationEqual
                                                                toItem:self.iconImageView
                                                             attribute:NSLayoutAttributeRight
                                                            multiplier:1.0
                                                              constant:10.0]];
            
            [self addConstraint:[NSLayoutConstraint constraintWithItem:self.contentLabel
                                                             attribute:NSLayoutAttributeRight
                                                             relatedBy:NSLayoutRelationEqual
                                                                toItem:self
                                                             attribute:NSLayoutAttributeRight
                                                            multiplier:1.0
                                                              constant:-10.0]];
            
            self.contentLabel.textAlignment = NSTextAlignmentLeft;
            break;
        case TSMessageViewTypeSubtitle:
        case TSMessageViewTypeTitleSubtitle:
            [self addConstraint:[NSLayoutConstraint constraintWithItem:self.contentLabel
                                                             attribute:NSLayoutAttributeLeading
                                                             relatedBy:NSLayoutRelationEqual
                                                                toItem:self
                                                             attribute:NSLayoutAttributeLeft
                                                            multiplier:1.0
                                                              constant:10.0]];
            
            [self addConstraint:[NSLayoutConstraint constraintWithItem:self.contentLabel
                                                             attribute:NSLayoutAttributeTrailing
                                                             relatedBy:NSLayoutRelationEqual
                                                                toItem:self
                                                             attribute:NSLayoutAttributeRight
                                                            multiplier:1.0
                                                              constant:-10.0]];
            
            [self addConstraint:[NSLayoutConstraint constraintWithItem:self.contentLabel
                                                             attribute:NSLayoutAttributeBottom
                                                             relatedBy:NSLayoutRelationEqual
                                                                toItem:self
                                                             attribute:NSLayoutAttributeBottom
                                                            multiplier:1.0
                                                              constant:-10.0]];
            
            self.contentLabel.textAlignment = NSTextAlignmentCenter;
            break;
        default:
            break;
    }
    
    if (self.messageViewType == TSMessageViewTypeImageTitleSubtitle || self.messageViewType == TSMessageViewTypeTitleSubtitle)
    {
        [self addConstraint:[NSLayoutConstraint constraintWithItem:self.contentLabel
                                                         attribute:NSLayoutAttributeTop
                                                         relatedBy:NSLayoutRelationEqual
                                                            toItem:self.titleLabel
                                                         attribute:NSLayoutAttributeBottom
                                                        multiplier:1.0
                                                          constant:4.0]];
    }
    else if (self.messageViewType == TSMessageViewTypeImageSubtitle || self.messageViewType == TSMessageViewTypeSubtitle)
    {
        [self addConstraint:[NSLayoutConstraint constraintWithItem:self.contentLabel
                                                         attribute:NSLayoutAttributeTop
                                                         relatedBy:NSLayoutRelationEqual
                                                            toItem:self
                                                         attribute:NSLayoutAttributeTop
                                                        multiplier:1.0
                                                          constant:10.0]];
    }
}

- (void)setupImage:(UIImage *)image
{
    switch (self.messageViewType)
    {
        case TSMessageViewTypeSubtitle:
        case TSMessageViewTypeTitle:
        case TSMessageViewTypeTitleSubtitle:
            return;
        default:
            break;
    }
    
    if (!image) image = [UIImage imageNamed:self.config[@"imageName"]];
    self.iconImageView = [[UIImageView alloc] initWithImage:image];
    self.iconImageView.translatesAutoresizingMaskIntoConstraints = NO;
    [self addSubview:self.iconImageView];
    
    [self addConstraint:[NSLayoutConstraint constraintWithItem:self.iconImageView
                                                     attribute:NSLayoutAttributeWidth
                                                     relatedBy:NSLayoutRelationEqual
                                                        toItem:nil
                                                     attribute:NSLayoutAttributeNotAnAttribute
                                                    multiplier:1.0
                                                      constant:44.0]];
    
    [self addConstraint:[NSLayoutConstraint constraintWithItem:self.iconImageView
                                                     attribute:NSLayoutAttributeHeight
                                                     relatedBy:NSLayoutRelationEqual
                                                        toItem:nil
                                                     attribute:NSLayoutAttributeNotAnAttribute
                                                    multiplier:1.0
                                                      constant:44.0]];
    
    [self addConstraint:[NSLayoutConstraint constraintWithItem:self.iconImageView
                                                     attribute:NSLayoutAttributeLeading
                                                     relatedBy:NSLayoutRelationEqual
                                                        toItem:self
                                                     attribute:NSLayoutAttributeLeft
                                                    multiplier:1.0
                                                      constant:10.0]];
    
    [self addConstraint:[NSLayoutConstraint constraintWithItem:self.iconImageView
                                                     attribute:NSLayoutAttributeTop
                                                     relatedBy:NSLayoutRelationEqual
                                                        toItem:self
                                                     attribute:NSLayoutAttributeTop
                                                    multiplier:1.0
                                                      constant:10.0]];
    
    [self addConstraint:[NSLayoutConstraint constraintWithItem:self.iconImageView
                                                     attribute:NSLayoutAttributeBottom
                                                     relatedBy:NSLayoutRelationEqual
                                                        toItem:self
                                                     attribute:NSLayoutAttributeBottom
                                                    multiplier:1.0
                                                      constant:-10.0]];
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

- (void)displayOrEnqueue
{
    [TSMessage displayOrEnqueueMessage:self];
}

- (void)displayPermanently
{
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
    
    NSLog(@"%@", NSStringFromCGSize(proposedSize));
}

@end
