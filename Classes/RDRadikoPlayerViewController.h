//
//  RadikoPlayerViewController.h
//  RadikoPlayer
//
//  Created by 石田 一博 on 10/03/19.
//  Copyright Apple Inc 2010. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface RDRadikoPlayerViewController : UIViewController <UITableViewDelegate>
{
	UIActivityIndicatorView *mySpinner;
}

@property (nonatomic, retain) UIActivityIndicatorView *spinner;

@end

