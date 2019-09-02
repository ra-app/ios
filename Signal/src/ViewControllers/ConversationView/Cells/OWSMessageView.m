//
//  Copyright (c) 2019 Open Whisper Systems. All rights reserved.
//

#import "OWSMessageView.h"
#import "Signal-Swift.h"

NS_ASSUME_NONNULL_BEGIN

@implementation OWSMessageView

- (void)configureViews
{
    OWSAbstractMethod();
}

- (void)loadContent
{
    OWSAbstractMethod();
}

- (void)unloadContent
{
    OWSAbstractMethod();
}

- (void)prepareForReuse
{
    OWSAbstractMethod();
}

- (CGSize)measureSize
{
    OWSAbstractMethod();

    return CGSizeZero;
}

+ (UIFont *)senderNameFont
{
    return UIFont.ows_dynamicTypeSubheadlineFont.ows_mediumWeight;
}

+ (NSDictionary *)senderNamePrimaryAttributes
{
    return @{
        NSFontAttributeName : self.senderNameFont,
        NSForegroundColorAttributeName : ConversationStyle.bubbleTextColorIncoming,
    };
}

+ (NSDictionary *)senderNameSecondaryAttributes
{
    return @{
        NSFontAttributeName : self.senderNameFont.ows_italic,
        NSForegroundColorAttributeName : ConversationStyle.bubbleTextColorIncoming,
    };
}

#pragma mark - Gestures

- (OWSMessageGestureLocation)gestureLocationForLocation:(CGPoint)locationInMessageBubble
{
    OWSAbstractMethod();

    return OWSMessageGestureLocation_Default;
}

- (void)addGestureHandlers
{
    UITapGestureRecognizer *tap =
        [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleTapGesture:)];
    [self addGestureRecognizer:tap];

    UIPanGestureRecognizer *pan = [[UIPanGestureRecognizer alloc] initWithTarget:self
                                                                          action:@selector(handlePanGesture:)];
    [self addGestureRecognizer:pan];
    [tap requireGestureRecognizerToFail:pan];
}

- (void)handleTapGesture:(UITapGestureRecognizer *)sender
{
    OWSAbstractMethod();
}

- (BOOL)handlePanGesture:(UIPanGestureRecognizer *)sender
{
    OWSAbstractMethod();
    return NO;
}

@end

NS_ASSUME_NONNULL_END
