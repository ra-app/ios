//
//  Copyright (c) 2019 Open Whisper Systems. All rights reserved.
//

#import "CountryCodeViewController.h"
#import "OWSSearchBar.h"
#import "PhoneNumberUtil.h"
#import "Theme.h"
#import "UIColor+OWS.h"
#import "UIFont+OWS.h"
#import "UIView+OWS.h"
#import <SignalServiceKit/NSString+SSK.h>

NS_ASSUME_NONNULL_BEGIN

@interface CountryCodeViewController () <OWSTableViewControllerDelegate, UISearchBarDelegate>

@property (nonatomic, readonly) UISearchBar *searchBar;
@property (nonatomic) UITextField *tfSearch;
@property (nonatomic) UIView *viewSearchBaseView;

@property (nonatomic) NSArray<NSString *> *countryCodes;

@end

#pragma mark -

@implementation CountryCodeViewController

- (void)loadView
{
    [super loadView];

    self.shouldUseTheme = NO;
    self.interfaceOrientationMask = UIInterfaceOrientationMaskAllButUpsideDown;

    self.view.backgroundColor = [UIColor whiteColor];
    self.title = NSLocalizedString(@"COUNTRYCODE_SELECT_TITLE", @"");

    self.countryCodes = [PhoneNumberUtil countryCodesForSearchTerm:nil];

//    if (!self.isPresentedInNavigationController) {
//        self.navigationItem.leftBarButtonItem =
//            [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemStop
//                                                          target:self
//                                                          action:@selector(dismissWasPressed:)];
//    }

    [self createViews];
}

- (void)createViews
{
    // Search
    
    UIView *viewSearchBaseView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width - 40, 35)];
    
    viewSearchBaseView.layer.cornerRadius = 19.0f;
    viewSearchBaseView.backgroundColor = [UIColor whiteColor];
    
    
    self.tfSearch = [[UITextField alloc] initWithFrame:CGRectMake(50, 5, 270, 25)];
    self.tfSearch.backgroundColor = [UIColor clearColor];
    self.tfSearch.placeholder = @"Name oder Nummer suchen";
    [self.tfSearch addTarget:self
                      action:@selector(textFieldDidChange:)
            forControlEvents:UIControlEventEditingChanged];
    
    [viewSearchBaseView addSubview:self.tfSearch];
    UIButton *btnCancel = [UIButton buttonWithType:UIButtonTypeCustom];
    [btnCancel setImage:[UIImage imageNamed:@"quoted-message-cancel.png"] forState:UIControlStateNormal];
    btnCancel.frame = CGRectMake(5, 3, 30, 30);
    [btnCancel addTarget:self action:@selector(dismissWasPressed:) forControlEvents:UIControlEventTouchUpInside];
    [viewSearchBaseView addSubview:btnCancel];
    
    
    self.navigationItem.titleView = viewSearchBaseView;
    
    //    UISearchBar *searchBar = [OWSSearchBar new];
    //    _searchBar = searchBar;
    //    searchBar.delegate = self;
    //    searchBar.placeholder = NSLocalizedString(@"SEARCH_BYNAMEORNUMBER_PLACEHOLDER_TEXT", @"");
    //    [searchBar sizeToFit];
    //
    //    self.tableView.tableHeaderView = searchBar;
    
    [self updateTableContents];
    
}

#pragma mark - Table Contents

- (void)updateTableContents
{
    OWSTableContents *contents = [OWSTableContents new];

    __weak CountryCodeViewController *weakSelf = self;
    OWSTableSection *section = [OWSTableSection new];

    for (NSString *countryCode in self.countryCodes) {
        OWSAssertDebug(countryCode.length > 0);
        OWSAssertDebug([PhoneNumberUtil countryNameFromCountryCode:countryCode].length > 0);
        OWSAssertDebug([PhoneNumberUtil callingCodeFromCountryCode:countryCode].length > 0);
        OWSAssertDebug(![[PhoneNumberUtil callingCodeFromCountryCode:countryCode] isEqualToString:@"+0"]);

        [section addItem:[OWSTableItem
                             itemWithCustomCellBlock:^{
                                 UITableViewCell *cell = [OWSTableItem newCell];
                                 [OWSTableItem configureCell:cell];
                                 cell.textLabel.text = [PhoneNumberUtil countryNameFromCountryCode:countryCode];

                                 UILabel *countryCodeLabel = [UILabel new];
                                 countryCodeLabel.text = [PhoneNumberUtil callingCodeFromCountryCode:countryCode];
                                 countryCodeLabel.font = [UIFont ows_regularFontWithSize:16.f];
                                 countryCodeLabel.textColor = Theme.secondaryColor;
                                 [countryCodeLabel sizeToFit];
                                 cell.accessoryView = countryCodeLabel;

                                 return cell;
                             }
                             actionBlock:^{
                                 [weakSelf countryCodeWasSelected:countryCode];
                             }]];
    }

    [contents addSection:section];

    self.contents = contents;
}

- (void)countryCodeWasSelected:(NSString *)countryCode
{
    OWSAssertDebug(countryCode.length > 0);

    NSString *callingCodeSelected = [PhoneNumberUtil callingCodeFromCountryCode:countryCode];
    NSString *countryNameSelected = [PhoneNumberUtil countryNameFromCountryCode:countryCode];
    NSString *countryCodeSelected = countryCode;
    [self.countryCodeDelegate countryCodeViewController:self
                                   didSelectCountryCode:countryCodeSelected
                                            countryName:countryNameSelected
                                            callingCode:callingCodeSelected];
    [self.searchBar resignFirstResponder];
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)dismissWasPressed:(id)sender
{
    [self dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark - UISearchBarDelegate

-(void) textFieldDidChange:(UITextField *) sender {
    [self searchTextDidChange];
}

- (void)searchBar:(UISearchBar *)searchBar textDidChange:(NSString *)searchText
{
    [self searchTextDidChange];
}

- (void)searchBarSearchButtonClicked:(UISearchBar *)searchBar
{
    [self searchTextDidChange];
}

- (void)searchBarCancelButtonClicked:(UISearchBar *)searchBar
{
    [self searchTextDidChange];
}

- (void)searchBarResultsListButtonClicked:(UISearchBar *)searchBar
{
    [self searchTextDidChange];
}

- (void)searchBar:(UISearchBar *)searchBar selectedScopeButtonIndexDidChange:(NSInteger)selectedScope
{
    [self searchTextDidChange];
}

- (void)searchTextDidChange
{
    //NSString *searchText = [self.searchBar.text ows_stripped];
    NSString *searchText = [self.tfSearch.text ows_stripped];
    self.countryCodes = [PhoneNumberUtil countryCodesForSearchTerm:searchText];

    [self updateTableContents];
}

#pragma mark - OWSTableViewControllerDelegate

- (void)tableViewWillBeginDragging
{
    [self.searchBar resignFirstResponder];
}

#pragma mark - Orientation

- (UIInterfaceOrientationMask)supportedInterfaceOrientations
{
    return self.interfaceOrientationMask;
}

@end

NS_ASSUME_NONNULL_END
