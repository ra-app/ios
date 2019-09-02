//
//  Copyright (c) 2019 Open Whisper Systems. All rights reserved.
//

#import "ConversationInputTextView.h"
#import "Signal-Swift.h"
#import <SignalServiceKit/NSString+SSK.h>

NS_ASSUME_NONNULL_BEGIN

@interface ConversationInputTextView () <UITextViewDelegate>

@property (nonatomic) UILabel *placeholderView;
@property (nonatomic) NSArray<NSLayoutConstraint *> *placeholderConstraints;

@end

#pragma mark -

@implementation ConversationInputTextView

- (instancetype)init
{
    self = [super init];
    if (self) {
        [self setTranslatesAutoresizingMaskIntoConstraints:NO];

        self.delegate = self;
        self.backgroundColor = nil;

        self.scrollIndicatorInsets = UIEdgeInsetsMake(4, 4, 4, 4);

        self.scrollEnabled = YES;
        self.scrollsToTop = NO;
        self.userInteractionEnabled = YES;

        self.font = [UIFont ows_dynamicTypeBodyFont];
        self.textColor = Theme.primaryColor;
        self.textAlignment = NSTextAlignmentNatural;

        self.contentMode = UIViewContentModeRedraw;
        self.dataDetectorTypes = UIDataDetectorTypeNone;

        self.text = nil;

        self.placeholderView = [UILabel new];
        self.placeholderView.text = NSLocalizedString(@"new_message", @"");
        self.placeholderView.textColor = Theme.placeholderColor;
        self.placeholderView.userInteractionEnabled = NO;
        [self addSubview:self.placeholderView];

        // We need to do these steps _after_ placeholderView is configured.
        self.font = [UIFont ows_dynamicTypeBodyFont];
        CGFloat hMarginLeading = 12.f;
        CGFloat hMarginTrailing = 24.f;
        self.textContainerInset = UIEdgeInsetsMake(7.f,
            CurrentAppContext().isRTL ? hMarginTrailing : hMarginLeading,
            7.f,
            CurrentAppContext().isRTL ? hMarginLeading : hMarginTrailing);
        self.textContainer.lineFragmentPadding = 0;
        self.contentInset = UIEdgeInsetsZero;

        [self ensurePlaceholderConstraints];
        [self updatePlaceholderVisibility];
    }

    return self;
}

#pragma mark -

- (void)setFont:(UIFont *_Nullable)font
{
    [super setFont:font];

    self.placeholderView.font = font;
}

- (void)setContentOffset:(CGPoint)contentOffset animated:(BOOL)isAnimated
{
    // When creating new lines, contentOffset is animated, but because because
    // we are simultaneously resizing the text view, this can cause the
    // text in the textview to be "too high" in the text view.
    // Solution is to disable animation for setting content offset.
    [super setContentOffset:contentOffset animated:NO];
}

- (void)setContentInset:(UIEdgeInsets)contentInset
{
    [super setContentInset:contentInset];

    [self ensurePlaceholderConstraints];
}

- (void)setTextContainerInset:(UIEdgeInsets)textContainerInset
{
    [super setTextContainerInset:textContainerInset];

    [self ensurePlaceholderConstraints];
}

- (void)ensurePlaceholderConstraints
{
    OWSAssertDebug(self.placeholderView);

    if (self.placeholderConstraints) {
        [NSLayoutConstraint deactivateConstraints:self.placeholderConstraints];
    }

    // We align the location of our placeholder with the text content of
    // this view.  The only safe way to do that is by measuring the
    // beginning position.
    UITextRange *beginningTextRange =
        [self textRangeFromPosition:self.beginningOfDocument toPosition:self.beginningOfDocument];
    CGRect beginningTextRect = [self firstRectForRange:beginningTextRange];

    CGFloat topInset = beginningTextRect.origin.y;
    CGFloat leadingInset = beginningTextRect.origin.x;

    self.placeholderConstraints = @[
        [self.placeholderView autoMatchDimension:ALDimensionWidth
                                     toDimension:ALDimensionWidth
                                          ofView:self
                                      withOffset:-leadingInset],
        [self.placeholderView autoPinEdgeToSuperviewEdge:ALEdgeTrailing],
        [self.placeholderView autoPinEdgeToSuperviewEdge:ALEdgeLeading withInset:leadingInset],
        [self.placeholderView autoPinEdgeToSuperviewEdge:ALEdgeTop withInset:topInset],
    ];
}

- (void)updatePlaceholderVisibility
{
    self.placeholderView.hidden = self.text.length > 0;
}

- (void)setText:(NSString *_Nullable)text
{
    [super setText:text];

    [self updatePlaceholderVisibility];
}

- (BOOL)canBecomeFirstResponder
{
    return YES;
}

- (BOOL)becomeFirstResponder
{
    BOOL result = [super becomeFirstResponder];

    if (result) {
        [self.textViewToolbarDelegate textViewDidBecomeFirstResponder:self];
    }

    return result;
}

- (BOOL)pasteboardHasPossibleAttachment
{
    // We don't want to load/convert images more than once so we
    // only do a cursory validation pass at this time.
    return ([SignalAttachment pasteboardHasPossibleAttachment] && ![SignalAttachment pasteboardHasText]);
}

- (BOOL)canPerformAction:(SEL)action withSender:(nullable id)sender
{
    if (action == @selector(paste:)) {
        if ([self pasteboardHasPossibleAttachment]) {
            return YES;
        }
    }
    return [super canPerformAction:action withSender:sender];
}

- (void)paste:(nullable id)sender
{
    if ([self pasteboardHasPossibleAttachment]) {
        SignalAttachment *attachment = [SignalAttachment attachmentFromPasteboard];
        // Note: attachment might be nil or have an error at this point; that's fine.
        [self.inputTextViewDelegate didPasteAttachment:attachment];
        return;
    }

    [super paste:sender];
}

- (NSString *)trimmedText
{
    return [self.text ows_stripped];
}

#pragma mark - UITextViewDelegate

- (void)textViewDidChange:(UITextView *)textView
{
    OWSAssertDebug(self.inputTextViewDelegate);
    OWSAssertDebug(self.textViewToolbarDelegate);

    [self updatePlaceholderVisibility];

    [self.inputTextViewDelegate textViewDidChange:self];
    [self.textViewToolbarDelegate textViewDidChange:self];
}

- (void)textViewDidChangeSelection:(UITextView *)textView
{
    [self.textViewToolbarDelegate textViewDidChangeSelection:self];
}

#pragma mark - Key Commands

- (nullable NSArray<UIKeyCommand *> *)keyCommands
{
    // We're permissive about what modifier key we accept for the "send message" hotkey.
    // We accept command-return, option-return.
    //
    // We don't support control-return because it doesn't work.
    //
    // We don't support shift-return because it is often used for "newline" in other
    // messaging apps.
    return @[
        [self keyCommandWithInput:@"\r"
                    modifierFlags:UIKeyModifierCommand
                           action:@selector(modifiedReturnPressed:)
             discoverabilityTitle:@"Send Message"],
        // "Alternate" is option.
        [self keyCommandWithInput:@"\r"
                    modifierFlags:UIKeyModifierAlternate
                           action:@selector(modifiedReturnPressed:)
             discoverabilityTitle:@"Send Message"],
    ];
}

- (UIKeyCommand *)keyCommandWithInput:(NSString *)input
                        modifierFlags:(UIKeyModifierFlags)modifierFlags
                               action:(SEL)action
                 discoverabilityTitle:(NSString *)discoverabilityTitle
{
    return [UIKeyCommand keyCommandWithInput:input
                               modifierFlags:modifierFlags
                                      action:action
                        discoverabilityTitle:discoverabilityTitle];
}

- (void)modifiedReturnPressed:(UIKeyCommand *)sender
{
    OWSLogInfo(@"modifiedReturnPressed: %@", sender.input);
    [self.inputTextViewDelegate inputTextViewSendMessagePressed];
}

@end

NS_ASSUME_NONNULL_END
