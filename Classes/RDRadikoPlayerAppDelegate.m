//
//  RadikoPlayerAppDelegate.m
//  RadikoPlayer
//
//  Created by 石田 一博 on 10/03/19.
//  Copyright Apple Inc 2010. All rights reserved.
//

#import "RDRadikoPlayerAppDelegate.h"
#import "RDRadikoPlayerViewController.h"
#import "RDRadikoProgramViewController.h"
#import "RDRadikoSettingViewController.h"


@implementation RDRadikoPlayerAppDelegate

@synthesize window = myWindow;
@synthesize tabController = myTabController;


- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
	// メインウィンドウの生成
	myWindow = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
	
	// タブバーコントローラの生成
	myTabController = [[UITabBarController alloc] initWithNibName:nil bundle:nil];
	
	// タブ切り替えを行うビューコントローラの生成と設定
	RDRadikoPlayerViewController *playerViewController = nil;
	playerViewController = [[[RDRadikoPlayerViewController alloc] initWithNibName:nil bundle:nil] autorelease];
	RDRadikoProgramViewController *programViewController = nil;
	programViewController = [[[RDRadikoProgramViewController alloc] initWithNibName:nil bundle:nil] autorelease];
	RDRadikoSettingViewController *settingViewController = nil;
	settingViewController = [[[RDRadikoSettingViewController alloc] initWithNibName:nil bundle:nil] autorelease];
	
	myTabController.viewControllers = [NSArray arrayWithObjects:playerViewController, 
																programViewController, 
																settingViewController, nil];
	
	// メインウィンドウにタブバーコントローラのビューをセットし表示
	[myWindow addSubview:myTabController.view];
	[myWindow makeKeyAndVisible];
	
	return YES;
}


- (void)dealloc
{
	[myTabController release];
	[myWindow release];
	[super dealloc];
}


@end
