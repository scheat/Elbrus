//
//  RadikoPlayerViewController.m
//  RadikoPlayer
//
//  Created by 石田 一博 on 10/03/19.
//  Copyright Apple Inc 2010. All rights reserved.
//

#import "RDRadikoPlayerViewController.h"
#import "RDRadikoAreaInformation.h"
#import "RDRadikoProgramGuide.h"
#import "RDRadikoStationTableViewCell.h"


static NSString * const kRadikoStationTableViewCellIdentifier = @"StationCell";



@interface RDRadikoPlayerViewController (CreateViews)

- (void)loadPlayingInfoView;
- (void)loadLineupInfoView;
- (void)loadSpinner;
- (void)showSpinner:(BOOL)show;

@end


@interface RDRadikoPlayerViewController (GuideDownload)

- (void)guide:(RDRadikoProgramGuide *)guide didParseLineup:(RDRadikoLineup *)parsedLineup;

@end


@implementation RDRadikoPlayerViewController

@synthesize spinner = mSpinner;

- (id)initWithNibName:(NSString *)nibName bundle:(NSBundle *)nibBundle
{
	if (self = [super initWithNibName:nibName bundle:nibBundle])
	{
		// 地域コード、放送局データ取得の処理を実行ループに登録
		mAreaInformation = [[RDRadikoAreaInformation alloc] init];
		
		mLineups = [[NSMutableArray alloc] initWithCapacity:0];
	}
	return self;
}


- (void)loadView
{
	[super loadView];
	
	[self loadPlayingInfoView];
	[self loadLineupInfoView];
	
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

- (void)viewWillAppear:(BOOL)animated
{
	NSURL *url = [NSURL URLWithString:@"http://radiko.jp/epg/epgapi.php?area_id=JP13&mode=now"];
	mProgramGuide = [[RDRadikoProgramGuide alloc] initWithURL:url];
	mProgramGuide.delegate = self;
}


- (void)viewDidAppear:(BOOL)animated
{
	[self showSpinner:NO];
	
//	// 地域コード、放送局データ取得の処理を実行ループに登録
//	mAreaInformation = [[RDRadikoAreaInformation alloc] init];
//	
	[mProgramGuide start];
}


- (void)didReceiveMemoryWarning
{
	// Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
	
	// Release any cached data, images, etc that aren't in use.
}


- (void)viewDidUnload
{
	// Release any retained subviews of the main view.
	// e.g. self.mOutlet = nil;
}


- (void)dealloc
{
    [super dealloc];
}


#pragma mark UITableViewDataSource method

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
	return 1;
}


- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
	NSLog(@"station count: %d", [mAreaInformation.stations count]);
	return [mAreaInformation.stations count];
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
	RDRadikoStationTableViewCell *cell = 
	(RDRadikoStationTableViewCell *)[tableView dequeueReusableCellWithIdentifier:kRadikoStationTableViewCellIdentifier];
	if (nil == cell)
	{
		cell = [[RDRadikoStationTableViewCell alloc] initWithStyle:UITableViewCellStyleDefault
												   reuseIdentifier:kRadikoStationTableViewCellIdentifier];
	}
	
	RDRadikoStation *station = [mAreaInformation.stations objectAtIndex:indexPath.row];
	if (indexPath.row < [mLineups count])
	{
		RDRadikoLineup *lineup = [mLineups objectAtIndex:indexPath.row];
		NSLog(@"station id: %@, lineup id: %@", station.stationID, lineup.stationID);
		if ([lineup.stationID isEqualToString:station.stationID])
		{
			RDRadikoProgram *program = [lineup.programs objectAtIndex:0];
			cell.date = lineup.date;
			cell.title = program.title;
			cell.performer = program.performer;
		}
	}
	NSURL *url = [NSURL URLWithString:station.logoLarge];
	NSURLRequest *request = [[NSURLRequest alloc] initWithURL:url];
	NSURLResponse *response = nil;
	NSData *data = [NSURLConnection sendSynchronousRequest:request returningResponse:&response error:nil];
	cell.logo = [UIImage imageWithData:data];
	
	return cell;
}

@end


@implementation RDRadikoPlayerViewController (CreateViews)

- (void)loadPlayingInfoView
{
	UIView *playingView = [[[UIView alloc] init] autorelease];
	playingView.frame = CGRectMake(0.0, 0.0, 320.0, 123.0);
	playingView.backgroundColor = [UIColor lightGrayColor];
	
	mPlayerView = playingView;
	
	[self.view addSubview:playingView];
}


- (void)loadLineupInfoView
{
	UITableView *stationView = [[[UITableView alloc] init] autorelease];
	stationView.frame = CGRectMake(0.0, 123.0, 320.0, 288.0);
	stationView.delegate = self;
	stationView.dataSource = self;
	stationView.rowHeight = 72.0;
	stationView.separatorStyle = UITableViewCellSeparatorStyleNone;
	
	mLineupView = stationView;
	
	[self.view addSubview:stationView];
}


- (void)loadSpinner
{
	UIActivityIndicatorView *spinner = nil;
	
	// オブジェクト生成
	spinner = [[[UIActivityIndicatorView alloc] 
				initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray] autorelease];
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

- (void)guide:(RDRadikoProgramGuide *)guide didParseLineup:(RDRadikoLineup *)parsedLineup
{
	[mLineups addObject:parsedLineup];
	
	[mLineupView reloadData];
}

@end