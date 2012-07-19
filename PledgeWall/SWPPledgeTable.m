//
//  SWPPledgeTable.m
//  StopWatch+
//
//  Created by Andrew L. Johnson on 6/16/12.
//  Copyright (c) 2012 TrailBehind, Inc. All rights reserved.
//

#import "SWPPurchaseController.h"
#import "SWPPledgeTable.h"
#import "SWPPledgeWall.h"
#import "SavingDictionary.h"
#import <StoreKit/StoreKit.h>
#import <Parse/Parse.h>
#import <QuartzCore/QuartzCore.h>

#define TOP_TITLE @"Pledges"

#define WHY_PLEDGE_TITLE @"Why pledge?"
#define WHY_PLEDGE__MESSAGE  @"* this app is ad-free and cost-free\n* supporters get access to an exclusive color pack\n"

#define AFTER_PURCHASE_TITLE @"Thanks for Pledging"
#define AFTER_PURCHASE_MESSAGE @"You can now find your message on the wall. You can pledge many times if you really dig StopWatch!"

#define RESTORE_PURCHASES_TITLE @"Restore Purchases"
#define RESTORE_PURCHASES_MESSAGE @"If you have previously pledged and deleted the app, touching this button will make the app remember you pledged."

#define NOT_AVAILABLE_TITLE @"Not Available"
#define NOT_AVAILABLE_MESSAGE @"Purchases are not available right now. Please try again in a moment, or when you get a better internet connection."

#define TABLE_FOOTER_MESSAGE @"Obscenity is prohibited. Messages are moderated."

#define PLEDGE_PROMPT_MESSAGE @"Enter your pledge message."
#define CANCEL_WORD @"Cancel"
#define RESTORE_WORD @"Restore"
#define OK_WORD @"OK"


@implementation SWPPledgeTable
@synthesize pledgeWall, pledgeProducts, pledgeField, buyRow;


- (void)dealloc {
  [pledgeWall release];
  [pledgeField release];
  [pledgeProducts release];
	[super dealloc];
}


#pragma mark - View Initialization Methods

- (CGRect) tableHeaderContainerFrame {
  return  CGRectMake(0, 0, self.view.frame.size.width-PADDING*2, 105);
}


- (CGRect) tableHeaderFrame {
  return  CGRectMake(PADDING, PADDING, [self tableHeaderContainerFrame].size.width-PADDING*2, 100);
}


- (NSString*)tableHeaderTitle {
  return WHY_PLEDGE_TITLE;
}


- (NSString*)tableHeaderDescription {
  return WHY_PLEDGE__MESSAGE;
}


- (UILabel*) labelWithFrame:(CGRect)frame {
  UILabel *label = [[[UILabel alloc]initWithFrame:frame]autorelease];
  label.autoresizingMask = UIViewAutoresizingFlexibleWidth;
  label.backgroundColor = [UIColor clearColor];
  label.shadowColor = [UIColor whiteColor];
  label.numberOfLines = 0;
  return label;
}


- (UIView*) tableHeaderBackground {
  CGRect containerFrame = [self tableHeaderContainerFrame];
  UIView *container = [[[UIView alloc]initWithFrame:containerFrame]autorelease];
  container.autoresizingMask = UIViewAutoresizingFlexibleWidth;

  CGRect headerFrame = [self tableHeaderFrame];
  UIView *headerView = [[[UIView alloc]initWithFrame:headerFrame]autorelease];
  headerView.autoresizingMask = UIViewAutoresizingFlexibleWidth;
  headerView.layer.cornerRadius = 4;
  headerView.layer.borderWidth = 1;
  headerView.layer.borderColor = TRANSPARENT_WHITE_CG;
  headerView.backgroundColor = TRANSPARENT_BLACK;
  [container addSubview:headerView];
  
  self.tableView.tableHeaderView = container;
  
  return headerView;
}


- (void) addTableHeader {
  UIView *headerView = [self tableHeaderBackground];

  CGRect titleLabelFrame = CGRectMake(PADDING, PADDING, 
                                      headerView.frame.size.width-PADDING*2, 22);
  UILabel *titleLabel = [self labelWithFrame:titleLabelFrame];
  titleLabel.text = [self tableHeaderTitle];
  titleLabel.font = [UIFont fontWithName:BOLD_FONT size:20];
  [headerView addSubview:titleLabel];
  
  
  if ([self tableHeaderDescription]) {
    CGRect descriptionLabelFrame = CGRectMake(PADDING, titleLabelFrame.size.height+18, 
                                              headerView.frame.size.width-PADDING*2, 55);
    UILabel *descriptionLabel = [self labelWithFrame:descriptionLabelFrame];
    descriptionLabel.text = [self tableHeaderDescription];
    descriptionLabel.font = [UIFont fontWithName:NORMAL_FONT size:15];
    [headerView addSubview:descriptionLabel];    
  }

}


- (void) addTableFooter {
  CGRect footerLabelFrame = CGRectMake(PADDING, 0, self.view.frame.size.width-PADDING*2, 12);
  UILabel *footerLabel = [self labelWithFrame:footerLabelFrame];
  footerLabel.text = TABLE_FOOTER_MESSAGE;
  footerLabel.font = [UIFont fontWithName:NORMAL_FONT size:12];
  footerLabel.textAlignment = UITextAlignmentCenter;
  self.tableView.tableFooterView = footerLabel;
}


- (void) viewDidLoad {
  [super viewDidLoad];
  self.title = TOP_TITLE;  
  [self addTableHeader];  
  [self addTableFooter];
  NSSortDescriptor *sortDescriptor;
  sortDescriptor = [[[NSSortDescriptor alloc] initWithKey:@"price"
                                                ascending:YES] autorelease];
  NSArray *sortDescriptors = [NSArray arrayWithObject:sortDescriptor];
  self.pledgeProducts = (NSMutableArray*)[pledgeProducts sortedArrayUsingDescriptors:sortDescriptors];
  [self.tableView reloadData];
  
  if (![[SWPPurchaseController settings] objectForKey:PW_PURCHASED_KEY]) {
    self.navigationItem.rightBarButtonItem = [[[UIBarButtonItem alloc]initWithTitle:RESTORE_WORD style:UIBarButtonItemStyleBordered target:self action:@selector(restorePurchases)]autorelease];
  }
}


#pragma mark - Button Action Methods

#define RESTORE_TAG 987
- (void)alertView:(UIAlertView *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex {
  if (actionSheet.tag == RESTORE_TAG) {
    if (buttonIndex == 0) return;
    [[SKPaymentQueue defaultQueue] restoreCompletedTransactions];
    return;
  }
  if (!pledgeField.text || [pledgeField.text isEqual:@""]) {
    [self buyProduct:buyRow];
    return;
  }
  SKProduct *selectedProduct = [self.pledgeProducts objectAtIndex:buyRow];
  SKPayment *payment = [SKPayment paymentWithProduct:selectedProduct];
  [[SKPaymentQueue defaultQueue] addPayment:payment];
}


- (void) restorePurchases {
  UIAlertView *av = [[[UIAlertView alloc]initWithTitle:RESTORE_PURCHASES_TITLE 
                                               message:RESTORE_PURCHASES_MESSAGE 
                                              delegate:self 
                                     cancelButtonTitle:CANCEL_WORD 
                                     otherButtonTitles:RESTORE_WORD, nil]autorelease];
  av.tag = RESTORE_TAG;
  [av show];
}


- (void) buyButtonPressed:(UISegmentedControl*)sender {
  [self buyProduct:sender.tag];
}


- (void) buyProduct:(int)row {
  if (!self.pledgeProducts || [self.pledgeProducts count] == 0) {
    UIAlertView *av = [[[UIAlertView alloc]initWithTitle:NOT_AVAILABLE_TITLE 
                                                 message:NOT_AVAILABLE_MESSAGE 
                                                delegate:self 
                                       cancelButtonTitle:OK_WORD 
                                       otherButtonTitles: nil]autorelease];
    [av show];
    return;
  }
  UIAlertView *myAlertView = [[UIAlertView alloc] initWithTitle:PLEDGE_PROMPT_MESSAGE
                                                        message:@"this gets covered" delegate:self cancelButtonTitle:OK_WORD otherButtonTitles:nil];
  pledgeField = [[UITextField alloc] initWithFrame:CGRectMake(12.0, 45.0, 260.0, 25.0)];
  [pledgeField setBackgroundColor:[UIColor whiteColor]];
  [myAlertView addSubview:pledgeField];
  [myAlertView show];
  [pledgeField becomeFirstResponder];
  [myAlertView release];
  buyRow = row;
}


- (void) addPledge {
  PFObject *pledge = [PFObject objectWithClassName:@"Pledge"];
  [pledge setObject:[NSNumber numberWithInt:buyRow] forKey:@"level"];
  [pledge setObject:pledgeField.text forKey:@"message"];
  [pledge setObject:[NSDate date] forKey:@"createdOnDevice"];
  [pledge save];
  [pledgeField release];
  pledgeField = nil;
  UIAlertView *myAlertView = [[[UIAlertView alloc] initWithTitle:AFTER_PURCHASE_TITLE
                                                         message:AFTER_PURCHASE_MESSAGE 
                                                        delegate:nil 
                                               cancelButtonTitle:OK_WORD 
                                               otherButtonTitles:nil]autorelease];
  [myAlertView show];
  SavingDictionary *settingsDict = [SWPPurchaseController settings];
  [settingsDict setObject:[NSNumber numberWithBool:YES] forKey:PW_PURCHASED_KEY];
  [self.pledgeWall setPledges:nil];
  [self.pledgeWall setPledgeCount:FLAGGED_FOR_REFRESH];
  [self.navigationController popViewControllerAnimated:YES];
}


#pragma mark - Table view methods

// Customize the appearance of table view cells.
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
  static NSString *CellID = @"Cell";
  UITableViewCell *cell = (UITableViewCell*)[tableView dequeueReusableCellWithIdentifier:CellID];
  if (cell == nil) {
    cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:CellID] autorelease];
    cell.selectionStyle = UITableViewCellSelectionStyleNone;
  }
  SKProduct *p = [self.pledgeProducts objectAtIndex:indexPath.row];
  cell.textLabel.text = p.localizedTitle;
  cell.textLabel.backgroundColor = [UIColor clearColor];
  cell.detailTextLabel.backgroundColor = [UIColor clearColor];
  cell.detailTextLabel.textColor = [UIColor blackColor];
  cell.detailTextLabel.text = p.localizedDescription;
  cell.detailTextLabel.numberOfLines = 0;
  NSString *priceString = [NSString stringWithFormat:@"%@", p.price];
  
  UISegmentedControl *buyButton = [[[UISegmentedControl alloc]initWithItems:[NSArray arrayWithObject:priceString]]autorelease];
  buyButton.segmentedControlStyle = UISegmentedControlStyleBar;
  buyButton.momentary = YES;
  buyButton.tag = indexPath.row;
  [buyButton addTarget:self 
                action:@selector(buyButtonPressed:) 
      forControlEvents:UIControlEventValueChanged];
  cell.accessoryView = buyButton;
  if (indexPath.row == BRONZE_INDEX) {
    cell.backgroundColor = BRONZE_COLOR;   
    buyButton.tintColor = BRONZE_COLOR;
  } else if (indexPath.row == SILVER_INDEX) {
    cell.backgroundColor = SILVER_COLOR;    
    buyButton.tintColor = [UIColor grayColor];
  } else {
    buyButton.tintColor = DARK_GOLD_COLOR;
    cell.backgroundColor = GOLD_COLOR;      
  }
  return cell;
}


- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
}


- (CGFloat)tableView:(UITableView *)aTableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {  
	return 90.0;  
}


- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
  return 1;
}


- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
  return [pledgeProducts count];
}


#pragma mark - Autorotation methods

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {  
  return YES;
} 

@end
