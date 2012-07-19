//
//  SWPPurchaseController.m
//  StopWatch+
//
//  Created by Andrew L. Johnson on 6/30/12.
//  Copyright (c) 2012 TrailBehind, Inc. All rights reserved.
//

#import "SWPPurchaseController.h"
#import "SWPPledgeWall.h"
#import "SWPPledgeTable.h"
#import "SavingDictionary.h"
#import <StoreKit/StoreKit.h>
#import <Parse/Parse.h>

#define PARSE_APP_ID @""
#define PARSE_CLIENT_KEY @""

#define LAUNCHES_KEY @"LAUNCHES"
#define PLEDGE_PRODUCT_LIST [NSSet setWithObjects: @"com.trailbehind.pw.bronze", @"com.trailbehind.pw.silver", @"com.trailbehind.pw.gold", nil]

#define PLEDGE_NOW_MESSAGE @"The app is totally ad and cost free. You can support us by leaving a message on the Pledge Wall."
#define PLEDGE_NOW_TITLE @"Pledge Today"


@implementation SWPPurchaseController
@synthesize products, delegate, pledgeWall, navController;

- (void)dealloc {  
  self.delegate = nil;
  [navController release];
  [pledgeWall release];
  [products release];
  [super dealloc];
}


- (void) promptToBuy {
  SavingDictionary *settingsDict = [[[SavingDictionary alloc]initWithClass:[SWPPurchaseController class]]autorelease];
  // search for PW_PURCHASED_KEY and all reference here
  if ([settingsDict objectForKey:PW_PURCHASED_KEY]) {
    return;
  }
  UIAlertView *av = [[[UIAlertView alloc]initWithTitle:PLEDGE_NOW_TITLE 
                                               message:PLEDGE_NOW_MESSAGE 
                                              delegate:self 
                                     cancelButtonTitle:@"OK" 
                                     otherButtonTitles:nil]autorelease];
  [av show];
}


- (SWPPledgeWall*) pledgeWall {
  if (pledgeWall) {
    return pledgeWall;
  }
  self.pledgeWall = [[[SWPPledgeWall alloc]initWithStyle:UITableViewStyleGrouped] autorelease];
  SWPPledgeTable *pledgeTable = [[[SWPPledgeTable alloc]initWithStyle:UITableViewStyleGrouped] autorelease];
  pledgeTable.pledgeProducts = self.products;  
  pledgeTable.pledgeWall = pledgeWall; 
  pledgeWall.pledgeTable = pledgeTable;
  return pledgeWall;
}


- (void) pushPledgeWallAnimated:(BOOL)animated {
  [self.navController pushViewController:self.pledgeWall animated:YES];  
}


- (void) alertView:(UIAlertView *)alert clickedButtonAtIndex:(NSInteger)buttonIndex {    
  [self pushPledgeWallAnimated:YES];
}


#define BUG_ME_DAYS_DEFAULT 10
// prompt the user to pledge, control time between prompts via Parse dashboard
- (void) comeOnPromptMeMaybe {
  [Parse setApplicationId:PARSE_APP_ID
                clientKey:PARSE_CLIENT_KEY];
  SavingDictionary *settingsDict = [[[SavingDictionary alloc]initWithClass:[SWPPurchaseController class]]autorelease];
  int launches = [[settingsDict objectForKey:LAUNCHES_KEY]intValue];
  if (launches <=0) {
    launches = 1;
  } else {
    launches++;
  }
  PFQuery *query = [PFQuery queryWithClassName:@"NumberOfLoads"];
  [query findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error) {
    int bugMeDays = BUG_ME_DAYS_DEFAULT;
    if (!error) {
      bugMeDays = [[[objects objectAtIndex:0]objectForKey:@"loads"]intValue];
    } else {
      NSLog(@"Error: %@ %@", error, [error userInfo]);
    }
    if (launches < bugMeDays) {
      [settingsDict setObject:[NSNumber numberWithInt:launches] forKey:LAUNCHES_KEY];        
    } else {
      [settingsDict setObject:[NSNumber numberWithInt:0] forKey:LAUNCHES_KEY];
      [self promptToBuy];
    }
  }];  
}


# pragma mark - SKProduct delegate methods

- (void)productsRequest:(SKProductsRequest *)request didReceiveResponse:(SKProductsResponse *)response {
  NSArray *myProducts = response.products;
  self.products = myProducts;
}


- (void) fetchProducts {
  SKProductsRequest *request = [[SKProductsRequest alloc] initWithProductIdentifiers:
                                PLEDGE_PRODUCT_LIST];
  request.delegate = self;
  [request start];
  [[SKPaymentQueue defaultQueue] addTransactionObserver:self];
}


- (void)paymentQueue:(SKPaymentQueue *)queue updatedTransactions:(NSArray *)transactions {
  for (SKPaymentTransaction *transaction in transactions) {
    switch (transaction.transactionState) {
      case SKPaymentTransactionStatePurchased:
        [self completeTransaction:transaction];
        break;
      case SKPaymentTransactionStateFailed:
        [self failedTransaction:transaction];
        break;
      case SKPaymentTransactionStateRestored:
        [self restoreTransaction:transaction];
      default:
        break;
    }
  }
}


- (void) completeTransaction: (SKPaymentTransaction *)transaction {
  SavingDictionary *settingsDict = [[[SavingDictionary alloc]initWithClass:[SWPPurchaseController class]]autorelease];
  [settingsDict setObject:@"YES" forKey:PW_PURCHASED_KEY];
  [[SKPaymentQueue defaultQueue] finishTransaction: transaction];
  [delegate addPledge];
}


// unused function now
- (void) restoreTransaction: (SKPaymentTransaction *)transaction {
  SavingDictionary *settingsDict = [[[SavingDictionary alloc]initWithClass:[SWPPurchaseController class]]autorelease];
  [settingsDict setObject:@"YES" forKey:PW_PURCHASED_KEY];
  [delegate addPledge];
}



// unused function now
- (void) failedTransaction: (SKPaymentTransaction *)transaction {
  // if (transaction.error.code != SKErrorPaymentCancelled) {
  // Optionally, display an error here.
  // }
}


+ (SavingDictionary*) settings {
  return [[[SavingDictionary alloc]initWithClass:[SWPPurchaseController class]]autorelease];
}


- (id) initWithDelegate:(id)d {
  if (self = [super init]) {
    self.delegate = d;
    [self fetchProducts];
    [self comeOnPromptMeMaybe];    
  }
  return self;
}


@end
