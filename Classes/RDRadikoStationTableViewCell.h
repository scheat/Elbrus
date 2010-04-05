//
//  RDRadikoStationTableViewCell.h
//  RadikoPlayer
//
//  Created by 石田 一博 on 10/04/04.
//  Copyright 2010 Apple Inc. All rights reserved.
//

#import <UIKit/UIKit.h>


@interface RDRadikoStationTableViewCell : UITableViewCell
{
	UIView *mView;
	UIImageView *mLogo;
	UILabel *mDate;
	UILabel *mTitle;
	UILabel *mPerformer;
	
	NSString *mStationID;
}

@property (nonatomic, setter=setLogo) UIImage *logo;
@property (nonatomic, setter=setDate) NSString *date;
@property (nonatomic, setter=setTitle) NSString *title;
@property (nonatomic, setter=setPerformer) NSString *performer;

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier;
//- (void)setLogo:(UIImage *)logo;
//- (void)setDate:(NSString *)date;
//- (void)setTitle:(NSString *)title;
//- (void)setPerformer:(NSString *)performer;
- (void)dealloc;

@end
