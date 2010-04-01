//
//  RadikoPlayerAppDelegate.h
//  RadikoPlayer
//
//  Created by 石田 一博 on 10/03/19.
//  Copyright Apple Inc 2010. All rights reserved.
//

#import <UIKit/UIKit.h>


@interface RDRadikoPlayerAppDelegate : NSObject <UIApplicationDelegate>
{
    UIWindow *mWindow;
	UITabBarController *mTabController;
}

@property (nonatomic, retain) UIWindow *window;
@property (nonatomic, retain) UITabBarController *tabController;

@end

