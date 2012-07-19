//
//  SWPPledgeWall.m
//  StopWatch+
//
//  Created by Andrew L. Johnson on 6/16/12.
//  Copyright (c) 2012 TrailBehind, Inc. All rights reserved.
//

#import "SWPPledgeWall.h"
#import "SWPPledgeTable.h"
#import <Parse/Parse.h>
#import <QuartzCore/QuartzCore.h>

#define TABLE_HEADER_MESSAGE @"Messages from Stopwatch+ Users"
#define LOAD_MORE_MESSAGE @"Load more messages..."

#define SPINNER_TAG 999


@implementation SWPPledgeWall
@synthesize pledges, pledgeCount, pledgeTable;

- (void)dealloc {
  [pledges release];
  [pledgeTable release];
	[super dealloc];
}


#pragma mark - View Initialization Methods



- (void) showPledgeTable {
  [self.navigationController pushViewController:self.pledgeTable animated:YES];
}


// fetch up to PLEDGES_PER_CHUNK more pledges to show on the server 
- (void) loadMorePledges {
  PFQuery *query = [PFQuery queryWithClassName:@"Pledge"];
  [query orderByDescending:@"level"];
  [query addDescendingOrder:@"createdOnDevice"];
  query.limit = PLEDGES_PER_CHUNK;
  query.skip = [pledges count];
  [query findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error) {
    if (!error) {
      if ([objects count] < PLEDGES_PER_CHUNK) {
        self.pledgeCount = NO_PLEDGES_TO_FETCH;
      } else {        
        self.pledgeCount = PLEDGES_TO_FETCH;
      }
      self.pledges = [self.pledges arrayByAddingObjectsFromArray:objects];
      [self.tableView reloadData];
    } else {
      NSLog(@"Error: %@ %@", error, [error userInfo]);
    }
  }];  
}


// if we have never loaded pledges or we need to fresh, load pledges
- (void) viewDidAppear:(BOOL)animated {
  [super viewDidAppear:animated];
  if ([self.pledges count] == 0 || self.pledgeCount == FLAGGED_FOR_REFRESH) {    
    self.pledges = [NSMutableArray array];
    [self loadMorePledges];
    [[self.view viewWithTag:SPINNER_TAG]removeFromSuperview];
  }
}


- (CGRect) tableHeaderContainerFrame {
  return  CGRectMake(PADDING, 
                     0, 
                     self.view.frame.size.width-PADDING*2, 
                     48);
}


- (CGRect) tableHeaderFrame {
  return  CGRectMake(PADDING, 
                     PADDING, 
                     [self tableHeaderContainerFrame].size.width-PADDING*2, 
                     [self tableHeaderContainerFrame].size.height-PADDING);
}


- (NSString*)tableHeaderTitle {
  return TABLE_HEADER_MESSAGE;
}


- (NSString*)tableHeaderDescription {
  return nil;
}


- (void) addTableFooter { }


- (void) addLoadingSpinner {
  UIActivityIndicatorView *spinner = [[[UIActivityIndicatorView alloc]initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray]autorelease];
  spinner.frame = CGRectMake(self.view.frame.size.width/2-64/2, 
                             self.view.frame.size.height/3,
                             64,
                             64);
  spinner.tag = SPINNER_TAG;
  spinner.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleBottomMargin;
  [spinner startAnimating];
  [self.view addSubview:spinner];
}


- (void) viewDidLoad {
  [super viewDidLoad];  
  self.pledges = [NSMutableArray array];
  pledgeCount = 0;  
  self.navigationItem.rightBarButtonItem = [[[UIBarButtonItem alloc]initWithTitle:@"Pledge!" style:UIBarButtonItemStyleDone target:self action:@selector(showPledgeTable)]autorelease];
}


#pragma mark - Table view methods

- (UIFont*) fontForPledge:(NSDictionary*)pledge {
  if ([[pledge objectForKey:@"level"] isEqual:[NSNumber numberWithInt:SILVER_INDEX]]) {
    return [UIFont fontWithName:BOLD_FONT size:16];
  } else if ([[pledge objectForKey:@"level"] isEqual:[NSNumber numberWithInt:BRONZE_INDEX]]) {
    return [UIFont fontWithName:NORMAL_FONT size:16];
  } else {
    // gold
    return [UIFont fontWithName:BOLD_FONT size:20];    
  }
}


// looks like "Fri, 08:15 pm"
- (NSString*) formatDate:(NSDate*) date {
	static NSDateFormatter *dateFormatter = nil;
  static NSTimeInterval gmtInterval;
  if (dateFormatter == nil) {
		dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateFormat:@"EEE, hh:mm a"];
    gmtInterval = -(NSTimeInterval) [[NSTimeZone systemTimeZone] secondsFromGMT];
	}
  
  NSString *dateString = [dateFormatter stringFromDate:date];
	return dateString;
}	


// messages are ordered by level - gold/silver/bronze, and then date
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
  static NSString *CellID = @"Cell";
  UITableViewCell *cell = (UITableViewCell*)[tableView dequeueReusableCellWithIdentifier:CellID];
  if (cell == nil) {
    cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:CellID] autorelease];
  }
  
  if (indexPath.row == [pledges count]) {
    cell.selectionStyle = UITableViewCellSelectionStyleBlue;
    cell.textLabel.text = LOAD_MORE_MESSAGE;
    cell.detailTextLabel.text = nil;
    cell.textLabel.font = [UIFont fontWithName:BOLD_FONT size:22];
    return cell;
  }
  cell.selectionStyle = UITableViewCellSelectionStyleNone;

  NSDictionary *pledge = [pledges objectAtIndex:indexPath.row];
  cell.textLabel.numberOfLines = 11;
  cell.textLabel.backgroundColor = [UIColor clearColor];
  cell.textLabel.text = [pledge objectForKey:@"message"];
  cell.textLabel.font = [self fontForPledge:pledge];
  cell.detailTextLabel.backgroundColor = [UIColor clearColor];
  cell.detailTextLabel.text = [self formatDate:[pledge objectForKey:@"createdOnDevice"]];
  if ([[pledge objectForKey:@"level"]intValue] == BRONZE_INDEX) {
    cell.backgroundColor = BRONZE_COLOR;    
  } else if ([[pledge objectForKey:@"level"]intValue] == SILVER_INDEX) {
    cell.backgroundColor = SILVER_COLOR;    
  } else {
    cell.backgroundColor = GOLD_COLOR;      
  }
  return cell;
}


// fetch and load more pledges from the server if the last row is touched
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
  if (indexPath.row == [pledges count]) {
    [self loadMorePledges];
  }
}


// size the row to the heeight of the pledge
- (CGFloat)tableView:(UITableView *)aTableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {  
  if (indexPath.row == [pledges count]) {
    return 60;
  }
  CGSize maximumLabelSize = CGSizeMake(aTableView.frame.size.width,1000);
  NSDictionary *pledge = [pledges objectAtIndex:indexPath.row];

	CGSize expectedLabelSize = [[pledge objectForKey:@"message"] sizeWithFont:[self fontForPledge:pledge] 
                                        constrainedToSize:maximumLabelSize 
                                            lineBreakMode:UILineBreakModeTailTruncation]; 
	
  return expectedLabelSize.height+60;  
}


// sometimes add a "Load moree..." row
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
  if ([pledges count]==0) return 0;
  else if (pledgeCount > 0) return [pledges count] + 1;
  return [pledges count];
}

@end
