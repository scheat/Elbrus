//
//  RDRadikoLineup.h
//  RadikoPlayer
//
//  Created by 石田 一博 on 10/03/29.
//  Copyright 2010 Apple Inc. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface RDRadikoLineup : NSObject
{
	NSString *mStationID;
	NSString *mName;
	NSString *mDate;
	NSMutableArray *mPrograms;
}

@property (nonatomic, retain) NSString *stationID;
@property (nonatomic, retain) NSString *name;
@property (nonatomic, retain) NSString *date;
@property (nonatomic, retain) NSMutableArray *programs;

- (id)init;
- (void)dealloc;

@end
