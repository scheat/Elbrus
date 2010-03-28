//
//  RadikoPlayerViewController.m
//  RadikoPlayer
//
//  Created by 石田 一博 on 10/03/19.
//  Copyright Apple Inc 2010. All rights reserved.
//

#import "RDRadikoPlayerViewController.h"


static const NSString * const kRadikoURL = @"http://radiko.jp/";
static NSString * const kRadikoStationParam = @"station";


@interface RDRadikoPlayerViewController (CreateViews)

- (void)loadPlayingInfoView;
- (void)loadStationInfoView;
- (void)loadSpinner;
- (void)showSpinner:(BOOL)show;

@end


@interface RDRadikoPlayerViewController (GuideDownload)

@end


@implementation RDRadikoPlayerViewController

@synthesize spinner = mySpinner;

/*
// The designated initializer. Override to perform setup that is required before the view is loaded.
- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    if (self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil]) {
        // Custom initialization
    }
    return self;
}
*/

- (void)loadView
{
	[super loadView];
	
	[self loadPlayingInfoView];
	[self loadStationInfoView];
	
	[self loadSpinner];
}


/*
// Implement viewDidLoad to do additional setup after loading the view, typically from a nib.
- (void)viewDidLoad {
    [super viewDidLoad];
}
*/


/*
// Override to allow orientations other than the default portrait orientation.
- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    // Return YES for supported orientations
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}
*/


- (void)viewDidAppear:(BOOL)animated
{
	[self showSpinner:YES];
	
	// 地域コード、放送局データ取得の処理を実行ループに登録
	NSString *stationXML = [self downloadStationInfo];
	NSLog(@"station information: %@", stationXML);
	// 
}


- (void)didReceiveMemoryWarning {
	// Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
	
	// Release any cached data, images, etc that aren't in use.
}


- (void)viewDidUnload {
	// Release any retained subviews of the main view.
	// e.g. self.myOutlet = nil;
}


- (void)dealloc {
    [super dealloc];
}

@end


@implementation RDRadikoPlayerViewController (CreateViews)

- (void)loadPlayingInfoView
{
	UIView *playingView = [[[UIView alloc] init] autorelease];
	playingView.frame = CGRectMake(0.0, 0.0, 320.0, 128.0);
	playingView.backgroundColor = [UIColor lightGrayColor];
	
	[self.view addSubview:playingView];
}


- (void)loadStationInfoView
{
	UITableView *stationView = [[[UITableView alloc] init] autorelease];
	stationView.frame = CGRectMake(0.0, 128.0, 320.0, 288.0);
	stationView.delegate = self;
	stationView.rowHeight = 72.0;
	
	[self.view addSubview:stationView];
}


- (void)loadSpinner
{
	UIActivityIndicatorView *spinner = nil;
	
	// オブジェクト生成
	spinner = [[[UIActivityIndicatorView alloc] 
				initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhite] autorelease];
	// フレームの設定
	spinner.frame = [UIScreen mainScreen].bounds;
	// スピナーの位置を中心に設定
	spinner.contentMode = UIViewContentModeCenter;
	// アニメーションストップ時に非表示になるよう設定
	spinner.hidesWhenStopped = YES;
	// ビューに表示
	[self.view addSubview:spinner];
	// オーナーシップを保持
	self.spinner = spinner;
}


- (void)showSpinner:(BOOL)show
{
	if (show)
	{
		[self.spinner startAnimating];
		self.spinner.alpha = 1.0;
	}
	else
	{
		[self.spinner stopAnimating];
		self.spinner.alpha = 0.0;
	}
}

@end



@implementation RDRadikoPlayerViewController (GuideDownload)

- (NSString *)downloadStationInfo
{
	// Note:
	//   Safari on Mac OS Xからのリクエスト
	//     GET /station/ HTTP/1.1
	//     Host: radiko.jp
	//     Pragma: no-cache
	//     Accept: application/xml, text/xml, */*
	//     Cache-Control: no-cache
	//     Referer: http://radiko.jp/
	//     Expires: Thu, 01 Jan 1970 00:00:00 GMT
	//     X-Requested-With: XMLHttpRequest
	//     Accept-Language: ja-jp
	//     Accept-Encoding: gzip, deflate
	//     Connection: keep-alive
	
	NSString *URLString = [kRadikoURL stringByAppendingString:kRadikoStationParam];
	NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL:[[NSURL alloc] initWithString:URLString]];
	[request addValue:@"no-cache" forHTTPHeaderField:@"Pragma"];
	[request addValue:@"application/xml, text/xml, */*" forHTTPHeaderField:@"Accept"];
	[request addValue:@"no-cache" forHTTPHeaderField:@"Cache-Control"];
	[request addValue:@"ja-jp" forHTTPHeaderField:@"Accept-Language"];
	[request addValue:@"gzip, deflate" forHTTPHeaderField:@"Accept-Encoding"];
	[request addValue:@"keep-alive" forHTTPHeaderField:@"Connection"];
	
	NSURLResponse *response = nil;
	NSData *data = [NSURLConnection sendSynchronousRequest:request returningResponse:&response error:nil];
	
	return [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
}

@end