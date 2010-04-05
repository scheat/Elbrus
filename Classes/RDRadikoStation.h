//
//  RDRadikoStation.h
//  RadikoPlayer
//
//  Created by 石田 一博 on 10/04/04.
//  Copyright 2010 Apple Inc. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface RDRadikoStation : NSObject
{
	// id
	NSString *mStationID;
	// name
	NSString *mName;
	// href
	NSString *mLink;
	// logo_xsmall
	NSString *mLogoXSmall;
	// logo_small
	NSString *mLogoSmall;
	// logo_medium
	NSString *mLogoMedium;
	// logo_large
	NSString *mLogoLarge;
	// feed
	NSString *mFeed;
	// banner
	NSString *mBanner;
}

@property (nonatomic, retain) NSString *stationID;
@property (nonatomic, retain) NSString *name;
@property (nonatomic, retain) NSString *link;
@property (nonatomic, retain) NSString *logoXSmall;
@property (nonatomic, retain) NSString *logoSmall;
@property (nonatomic, retain) NSString *logoMedium;
@property (nonatomic, retain) NSString *logoLarge;
@property (nonatomic, retain) NSString *feed;
@property (nonatomic, retain) NSString *banner;

- (id)init;
- (void)dealloc;

@end
