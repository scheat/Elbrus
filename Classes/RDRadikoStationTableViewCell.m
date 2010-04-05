//
//  RDRadikoStationTableViewCell.m
//  RadikoPlayer
//
//  Created by 石田 一博 on 10/04/04.
//  Copyright 2010 Apple Inc. All rights reserved.
//

#import <QuartzCore/QuartzCore.h>

#import "RDRadikoStationTableViewCell.h"


@implementation RDRadikoStationTableViewCell

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
	if (self = [super initWithStyle:style reuseIdentifier:reuseIdentifier])
	{
		mView = [[UIView alloc] init];
		mView.frame = CGRectMake(5.0, 4.0, 310.0, 68.0);
		mView.backgroundColor = [UIColor grayColor];
		mView.layer.cornerRadius = 7.0;
		mView.layer.masksToBounds = YES;
		
		mLogo = [[UIImageView alloc] init];
		mLogo.frame = CGRectMake(0.0, 0.0, 100.0, 68.0);
		mLogo.backgroundColor = [UIColor lightGrayColor];
		[mView addSubview:mLogo];
		
		mDate = [[UILabel alloc] init];
		mDate.frame = CGRectMake(110.0, 2.0, 190.0, 16.0);
		mDate.font = [UIFont systemFontOfSize:13.0];
		mDate.backgroundColor = [UIColor clearColor];
		[mView addSubview:mDate];
		mTitle = [[UILabel alloc] init];
		mTitle.frame = CGRectMake(110.0, 18.0, 190.0, 16.0);
		mTitle.font = [UIFont systemFontOfSize:13.0];
		mTitle.backgroundColor = [UIColor clearColor];
		[mView addSubview:mTitle];
		mPerformer = [[UILabel alloc] init];
		mPerformer.frame = CGRectMake(110.0, 34.0, 190.0, 16.0);
		mPerformer.font = [UIFont systemFontOfSize:13.0];
		mPerformer.backgroundColor = [UIColor clearColor];
		[mView addSubview:mPerformer];
		
		self.selectionStyle = UITableViewCellSelectionStyleNone;
	}
	return self;
}


- (void)layoutSubviews
{
	[super layoutSubviews];
	
	[self addSubview:mView];
}


- (void)setSelected:(BOOL)selected animated:(BOOL)animated
{
	[super setSelected:selected animated:animated];

	// Configure the view for the selected state
}


- (void)setLogo:(UIImage *)logo
{
	mLogo.image = logo;
}


- (void)setDate:(NSString *)date
{
	mDate.text = date;
}


- (void)setTitle:(NSString *)title
{
	mTitle.text = title;
}


- (void)setPerformer:(NSString *)performer
{
	mPerformer.text = performer;
}


- (void)dealloc
{
	[mLogo release];
	[mDate release];
	[mTitle release];
	[mPerformer release];
	
	[super dealloc];
}


@end
