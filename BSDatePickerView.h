/*-------------------------------------------------------------------
 Project name: vHealth
 Class name: BSDatePickerView.h
 Class description:
 Class description goes here.
 
 Author: Balasubramanian C
 Copyright © 2016 Cognizant. All rights reserved.
 -------------------------------------------------------------------*/

#import <UIKit/UIKit.h>

@protocol BSDatePickerViewDelegate <NSObject>

-(void)selectedDate:(NSDate *)pickerDate;

@end


@interface BSPickerScrollView : UITableView

@property NSInteger tagLastSelected;

-(void)dehighlightLastCell;
-(void)highlightCellWithIndexPathRow:(NSInteger)indexPathRow;

@end

@interface BSDatePickerView : UIView <UIScrollViewDelegate, UITableViewDataSource, UITableViewDelegate>


@property(nonatomic, assign) id<BSDatePickerViewDelegate> delegate;
@end
