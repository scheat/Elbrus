//
//  RadikoPlayerViewController.h
//  RadikoPlayer
//
//  Created by 石田 一博 on 10/03/19.
//  Copyright Apple Inc 2010. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "RDRadikoProgramGuide.h"


@class RDRadikoAreaInformation;

@interface RDRadikoPlayerViewController : UIViewController 
		<UITableViewDelegate, UITableViewDataSource, RDRadikoProgramGuideDelegate>
{
	UIActivityIndicatorView *mSpinner;
	UITableView *mLineupView;
	UIView *mPlayerView;
	
	RDRadikoAreaInformation *mAreaInformation;
	RDRadikoProgramGuide *mProgramGuide;
	
	NSMutableArray *mLineups;
}

@property (nonatomic, retain) UIActivityIndicatorView *spinner;

@end

