//
//  SWPPurchaseController.h
//  StopWatch+
//
//  Created by Andrew L. Johnson on 6/30/12.
//  Copyright (c) 2012 TrailBehind, Inc. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <StoreKit/StoreKit.h>
#import "SavingDictionary.h"

@class SWPPledgeWall;

#define PW_PURCHASED_KEY @"bowserPurchased"
@protocol SWPPurchaseDelegate <NSObject>
- (void) addPledge;

@end


@interface SWPPurchaseController : NSObject <SKProductsRequestDelegate, SKPaymentTransactionObserver> {
}

@property (nonatomic, retain) NSArray *products;
@property (nonatomic, assign) id<SWPPurchaseDelegate>delegate;
@property (nonatomic, assign) SWPPledgeWall *pledgeWall;
@property (nonatomic, assign) UINavigationController *navController;


- (id) initWithDelegate:(id)d;
- (void) pushPledgeWallAnimated:(BOOL)animated;
+ (SavingDictionary*) settings;

@end
