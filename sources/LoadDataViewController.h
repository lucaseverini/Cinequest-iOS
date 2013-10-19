//
//  LoadDataViewController.h
//  CineQuest
//
//  Created by Loc Phan on 10/8/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <sqlite3.h>

#define FILMSBYTIME		@"http://mobile.cinequest.org/mobileCQ.php?type=schedules&filmtitles&iphone"
#define FILMSBYTITLE	@"http://mobile.cinequest.org/mobileCQ.php?type=films&iphone"
#define NEWS			@"http://mobile.cinequest.org/mobileCQ.php?type=xml&name=ihome"
//#define EVENTS			@"http://mobile.cinequest.org/mobileCQ.php?type=xml&name=ievents&iphone"
#define FORUMS			@"http://mobile.cinequest.org/mobileCQ.php?type=xml&name=iforums&iphone"
#define DVDs			@"http://mobile.cinequest.org/mobileCQ.php?type=dvds&distribution=none&iphone"

#define DETAILFORFILMID @"http://mobile.cinequest.org/mobileCQ.php?type=film&iphone&id="
#define DETAILFORDVDID	@"http://mobile.cinequest.org/mobileCQ.php?type=dvd&iphone&id="
#define DETAILFORPrgId	@"http://mobile.cinequest.org/mobileCQ.php?type=program_item&iphone&id="
#define DETAILFORITEM	@"http://mobile.cinequest.org/mobileCQ.php?type=xml&name=items&iphone&id="

#define MODE			@"http://mobile.cinequest.org/mobileCQ.php?type=mode"


@interface LoadDataViewController : UIViewController <UIActionSheetDelegate, NSXMLParserDelegate>
{
	IBOutlet UIActivityIndicatorView *activity;
	IBOutlet UILabel *statusLabel;
	
	BOOL offSeason;
	sqlite3 *database;
	
}

@property (nonatomic, strong) UIActivityIndicatorView *activity;
@property (nonatomic, strong) UILabel *statusLabel;

- (BOOL) checkNetWorkAndLoadData;




@end
