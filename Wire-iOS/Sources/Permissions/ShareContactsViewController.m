// 
// Wire
// Copyright (C) 2016 Wire Swiss GmbH
// 
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
// 
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
// GNU General Public License for more details.
// 
// You should have received a copy of the GNU General Public License
// along with this program. If not, see http://www.gnu.org/licenses/.
// 


#import "ShareContactsViewController.h"
#import "ShareContactsViewController+Internal.h"

#import "PermissionDeniedViewController.h"
#import "Button.h"
#import "Wire-Swift.h"


@implementation ShareContactsViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    UIBlurEffect *blurEffect = [UIBlurEffect effectWithStyle:UIBlurEffectStyleDark];
    self.backgroundBlurView = [[UIVisualEffectView alloc] initWithEffect:blurEffect];
    [self.view addSubview:self.backgroundBlurView];
    self.backgroundBlurView.hidden = self.backgroundBlurDisabled;
    
    self.shareContactsContainerView = [[UIView alloc] init];
    [self.view addSubview:self.shareContactsContainerView];
    
    [self createHeroLabel];
    [self createNotNowButton];
    [self createShareContactsButton];
    [self createAddressBookAccessDeniedViewController];
    [self createConstraints];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(applicationDidBecomeActive:) name:UIApplicationDidBecomeActiveNotification object:nil];
    
    if ([[AddressBookHelper sharedHelper] isAddressBookAccessDisabled]) {
        [self displayContactsAccessDeniedMessageAnimated:NO];
    }
}

- (void)createHeroLabel
{
    self.heroLabel = [[UILabel alloc] init];
    self.heroLabel.font = UIFont.largeSemiboldFont;
    self.heroLabel.textColor = [UIColor wr_colorFromColorScheme:ColorSchemeColorTextForeground variant:ColorSchemeVariantDark];
    self.heroLabel.attributedText = [self attributedHeroText];
    self.heroLabel.numberOfLines = 0;
    
    [self.shareContactsContainerView addSubview:self.heroLabel];
}

- (NSAttributedString *)attributedHeroText
{
    NSString *title = NSLocalizedString(@"registration.share_contacts.hero.title", nil);
    NSString *paragraph = NSLocalizedString(@"registration.share_contacts.hero.paragraph", nil);
    
    NSString * text = [@[title, paragraph] componentsJoinedByString:@"\u2029"];
    
    NSMutableParagraphStyle *paragraphStyle = [[NSParagraphStyle defaultParagraphStyle] mutableCopy];
    paragraphStyle.paragraphSpacing = 10;
    
    NSMutableAttributedString *attributedText = [[NSMutableAttributedString alloc] initWithString:text attributes:@{ NSParagraphStyleAttributeName : paragraphStyle }];
    [attributedText addAttributes:@{ NSForegroundColorAttributeName : [UIColor wr_colorFromColorScheme:ColorSchemeColorTextForeground variant:ColorSchemeVariantDark],
                                     NSFontAttributeName : UIFont.largeThinFont }
                            range:[text rangeOfString:paragraph]];
    
    return [[NSAttributedString alloc] initWithAttributedString:attributedText];
}

- (void)createShareContactsButton
{
    self.shareContactsButton = [Button buttonWithStyle:self.monochromeStyle ? ButtonStyleFullMonochrome : ButtonStyleFull];
    [self.shareContactsButton setTitle:[NSLocalizedString(@"registration.share_contacts.find_friends_button.title", nil) uppercasedWithCurrentLocale] forState:UIControlStateNormal];
    [self.shareContactsButton addTarget:self action:@selector(shareContacts:) forControlEvents:UIControlEventTouchUpInside];
    
    [self.shareContactsContainerView addSubview:self.shareContactsButton];
}

- (void)createNotNowButton
{
    self.notNowButton = [UIButton buttonWithType:UIButtonTypeCustom];
    self.notNowButton.titleLabel.font = UIFont.smallLightFont;
    [self.notNowButton setTitleColor:[UIColor wr_colorFromColorScheme:ColorSchemeColorButtonFaded variant:ColorSchemeVariantDark] forState:UIControlStateNormal];
    [self.notNowButton setTitleColor:[[UIColor wr_colorFromColorScheme:ColorSchemeColorButtonFaded variant:ColorSchemeVariantDark] colorWithAlphaComponent:0.2] forState:UIControlStateHighlighted];
    [self.notNowButton setTitle:[NSLocalizedString(@"registration.share_contacts.skip_button.title", nil) uppercasedWithCurrentLocale] forState:UIControlStateNormal];
    [self.notNowButton addTarget:self action:@selector(shareContactsLater:) forControlEvents:UIControlEventTouchUpInside];
    self.notNowButton.hidden = self.notNowButtonHidden;
    
    [self.shareContactsContainerView addSubview:self.notNowButton];
}

- (void)createAddressBookAccessDeniedViewController
{
    self.addressBookAccessDeniedViewController = [PermissionDeniedViewController addressBookAccessDeniedViewControllerWithMonochromeStyle:self.monochromeStyle];
    self.addressBookAccessDeniedViewController.delegate = self;
    self.addressBookAccessDeniedViewController.backgroundBlurDisabled = self.backgroundBlurDisabled;
    
    [self addChildViewController:self.addressBookAccessDeniedViewController];
    [self.view addSubview:self.addressBookAccessDeniedViewController.view];
    [self.addressBookAccessDeniedViewController didMoveToParentViewController:self];
    self.addressBookAccessDeniedViewController.view.hidden = YES;
}

- (void)setBackgroundBlurDisabled:(BOOL)backgroundBlurDisabled
{
    _backgroundBlurDisabled = backgroundBlurDisabled;
    self.backgroundBlurView.hidden = self.backgroundBlurDisabled;
}

- (void)setNotNowButtonHidden:(BOOL)notNowButtonHidden
{
    _notNowButtonHidden = notNowButtonHidden;
    self.notNowButton.hidden = self.notNowButtonHidden;
}

#pragma mark - Actions

- (void)shareContacts:(id)sender
{
    [AddressBookHelper.sharedHelper requestPermissions:^(BOOL success) {
        if (success) {
            [[AddressBookHelper sharedHelper] startRemoteSearchWithCheckingIfEnoughTimeSinceLast:self.uploadAddressBookImmediately];
            [self.delegate shareContactsViewControllerDidFinish:self];
        } else {
            [self displayContactsAccessDeniedMessageAnimated:YES];
        }
    }];
}

- (void)shareContactsLater:(id)sender
{
    [AddressBookHelper sharedHelper].addressBookSearchWasPostponed = YES;
    [self.delegate shareContactsViewControllerDidSkip:self];
}


#pragma mark - PermissionDeniedViewControllerDelegate

- (void)continueWithoutPermission:(PermissionDeniedViewController *)viewController
{
    [AddressBookHelper sharedHelper].addressBookSearchWasPostponed = YES;
    [self.delegate shareContactsViewControllerDidSkip:self];
}

#pragma mark - UIApplication notifications

- (void)applicationDidBecomeActive:(NSNotification *)notification
{
    if ([[AddressBookHelper sharedHelper] isAddressBookAccessGranted]) {
        [[AddressBookHelper sharedHelper] startRemoteSearchWithCheckingIfEnoughTimeSinceLast:YES];
        [self.delegate shareContactsViewControllerDidFinish:self];
    }
}

@end
