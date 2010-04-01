//
//  RadikoPlayerViewController.h
//  RadikoPlayer
//
//  Created by 石田 一博 on 10/03/19.
//  Copyright Apple Inc 2010. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "RDRadikoProgramGuide.h"


@interface RDRadikoPlayerViewController : UIViewController <UITableViewDelegate, RDRadikoProgramGuideDelegate>
{
	UIActivityIndicatorView *mSpinner;
	
	RDRadikoProgramGuide *mProgramGuide;
}

@property (nonatomic, retain) UIActivityIndicatorView *spinner;

@end

