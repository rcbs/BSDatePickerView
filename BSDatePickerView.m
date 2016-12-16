
/*-------------------------------------------------------------------
 Project name: vHealth
 Class name: BSDatePickerView.m
 Class description:
 Class description goes here.
 
 Author: Balasubramanian C
 Copyright © 2016 Cognizant. All rights reserved.
 -------------------------------------------------------------------*/

#import "BSDatePickerView.h"

#define SELECTED_CELL_FONT [UIFont boldSystemFontOfSize:23.0]
#define BAR_SEL_ORIGIN_Y PICKER_HEIGHT/2.0-VALUE_HEIGHT/2.0

//Editable macros
#define TEXT_COLOR [UIColor colorWithWhite:0.5 alpha:1.0]
#define SELECTED_TEXT_COLOR [UIColor whiteColor]
#define LINE_COLOR [UIColor colorWithWhite:0.80 alpha:1.0]
#define SAVE_AREA_COLOR [UIColor colorWithWhite:0.95 alpha:1.0]
#define BAR_SEL_COLOR [UIColor colorWithRed:17.0f/255.0f green:135.0f/255.0f blue:189.0f/255.0f alpha:0.9]

// Date Formatter
#define YEAR_ONLY_FORMAT @"yyyy"
#define MONTH_ONLY_FORMAT @"MMMM"
#define DATE_ONLY_FORMAT @"d"
#define MONTH_DATE_YEAR_FORMAT @"MMMM d, yyyy"


//Editable
float VALUE_HEIGHT = 40.0;
float SV_MONTHS_WIDTH = 110.0;
float SV_DATES_WIDTH = 60.0;
float SV_YEAR_WIDTH = 80.0;

//Editable values
float PICKER_HEIGHT = 300.0;
NSString *FONT_NAME = @"HelveticaNeue";

//Custom scrollView
@interface BSPickerScrollView ()

@property (nonatomic, strong) NSArray *arrValues;
@property (nonatomic, strong) UIFont *cellFont;
@property (nonatomic, assign, getter = isScrolling) BOOL scrolling;

@end

@implementation BSPickerScrollView


/*-------------------------------------------------------------------
 Method name: initWithFrame
 Method description:
 Method description goes here.
 
 Change logs:
 -------------------------------------------------------------------*/
- (id)initWithFrame:(CGRect)frame andValues:(NSArray *)arrayValues
      withTextAlign:(NSTextAlignment)align andTextSize:(CGFloat)txtSize {
    
    if(self = [super initWithFrame:frame]) {
        [self setShowsVerticalScrollIndicator:NO];
        [self setBackgroundColor:[UIColor clearColor]];
        [self setSeparatorStyle:UITableViewCellSeparatorStyleNone];
        [self setContentInset:UIEdgeInsetsMake(BAR_SEL_ORIGIN_Y, 0.0, BAR_SEL_ORIGIN_Y, 0.0)];
        
        _cellFont = [UIFont fontWithName:FONT_NAME size:txtSize];
        
        if(arrayValues)
            _arrValues = [arrayValues copy];
    }
    return self;
}

/*-------------------------------------------------------------------
 Method name: dehighlightLastCell
 Method description:
 Method description goes here.
 
 Change logs:
 -------------------------------------------------------------------*/
- (void)dehighlightLastCell {
    
    NSArray *paths = [NSArray arrayWithObjects:[NSIndexPath indexPathForRow:_tagLastSelected inSection:0], nil];
    [self setTagLastSelected:-1];
    [self beginUpdates];
    [self reloadRowsAtIndexPaths:paths withRowAnimation:UITableViewRowAnimationNone];
    [self endUpdates];
}

/*-------------------------------------------------------------------
 Method name: highlightCellWithIndexPathRow
 Method description:
 Method description goes here.
 
 Change logs:
 -------------------------------------------------------------------*/
- (void)highlightCellWithIndexPathRow:(NSUInteger)indexPathRow {
    [self setTagLastSelected:indexPathRow];
    NSArray *paths = [NSArray arrayWithObjects:[NSIndexPath indexPathForRow:_tagLastSelected inSection:0], nil];
    [self beginUpdates];
    [self reloadRowsAtIndexPaths:paths withRowAnimation:UITableViewRowAnimationNone];
    [self endUpdates];
}

@end


@interface BSDatePickerView ()

// This will hold all the months in the array
@property (nonatomic, strong) NSArray *arrMonths;

// This will hold all the dates in the array
@property (nonatomic, strong) NSArray *arrDates;

// This will hold all the years in the array
@property (nonatomic, strong) NSArray *arrYear;

// This is the table view for months
@property (nonatomic, strong) BSPickerScrollView *svMonths;

// This is the table view for dates
@property (nonatomic, strong) BSPickerScrollView *svDates;

// This is the table view for years
@property (nonatomic, strong) BSPickerScrollView *svYear;

// This keeps the selected month's index
@property NSUInteger monthSelectedIndex;

// This keeps the selected date's index
@property NSUInteger dateSelectedIndex;

// This keeps the selected year's index
@property NSUInteger yearSelectedIndex;


- (void)initialize;
- (void)buildControl;
- (void)centerCellWithIndexPathRow:(NSUInteger)indexPathRow forScrollView:(BSPickerScrollView *)scrollView;
- (void)centerCellWithIndexPathRowFromLoadDates:(NSUInteger)indexPathRow forScrollView:(BSPickerScrollView *)scrollView;
- (void) loadDatesOfTheMonths:(NSUInteger) indexPathRow forScrollView:(BSPickerScrollView *)scrollView;
- (BOOL) isLeapYear:(int) year;
- (void)centerValueForScrollView:(BSPickerScrollView *)scrollView;
- (void)setTime:(NSDate *)currentDate;

@end



@implementation BSDatePickerView

/*-------------------------------------------------------------------
 Method name: initWithFrame
 Method description:
 Method description goes here.
 
 Change logs:
 -------------------------------------------------------------------*/
- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
        PICKER_HEIGHT = frame.size.height;
        // background view to clear
        [self setBackgroundColor:[UIColor whiteColor]];
    }
    return self;
}

/*-------------------------------------------------------------------
 Method name: drawRect
 Method description:
 Method description goes here.
 
 Change logs:
 -------------------------------------------------------------------*/
-(void)drawRect:(CGRect)rect {
    [self initialize];
    [self buildControl];
}


/*-------------------------------------------------------------------
 Method name: initialize
 Method description:
 Method description goes here.
 
 Change logs:
 -------------------------------------------------------------------*/
- (void)initialize {
    
    //Create array Moments and create the dictionary MOMENT -> TIME
    _arrMonths = @[@"January",
                   @"February",
                   @"March",
                   @"April",
                   @"May",
                   @"June",
                   @"July",
                   @"August",
                   @"September",
                   @"October",
                   @"November",
                   @"December"];
    
    //Create array Dates
    NSMutableArray *arrDates = [[NSMutableArray alloc] initWithCapacity:31];
    for(int i=1; i<=31; i++) {
        [arrDates addObject:[NSString stringWithFormat:@"%02d", i]];
    }
    _arrDates = [NSArray arrayWithArray:arrDates];
    
    //Create array Dates
    NSDate *todayDate = [NSDate date];
    
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    [formatter setDateFormat:YEAR_ONLY_FORMAT];
    NSString *year = [formatter stringFromDate:todayDate];
    
    long startDate = ([year integerValue] - 200);
    long enddate = ([year integerValue] + 200);
    
    NSMutableArray *arrYear = [[NSMutableArray alloc] initWithCapacity:400];
    for(long i=startDate; i<=enddate; i++) {
        [arrYear addObject:[NSString stringWithFormat:@"%ld", i]];
    }
    _arrYear = [NSArray arrayWithArray:arrYear];
}


/*-------------------------------------------------------------------
 Method name: buildControl
 Method description:
 Method description goes here.
 
 Change logs:
 -------------------------------------------------------------------*/
- (void)buildControl
{
    
    //Create bar selector
    UIView *barSel = [[UIView alloc] initWithFrame:CGRectMake(0.0, BAR_SEL_ORIGIN_Y, self.frame.size.width, VALUE_HEIGHT)];
    [barSel setBackgroundColor:BAR_SEL_COLOR];
    
    
    //Create the first column (months) of the picker
    _svMonths = [[BSPickerScrollView alloc] initWithFrame:CGRectMake(20.0, 0.0, SV_MONTHS_WIDTH, PICKER_HEIGHT) andValues:_arrMonths withTextAlign:NSTextAlignmentRight andTextSize:15.0];
    _svMonths.tag = 0;
    //[_svMonths setBackgroundColor:[UIColor redColor]];
    [_svMonths setDelegate:self];
    [_svMonths setDataSource:self];
    
    //Create the second column (hours) of the picker
    _svDates = [[BSPickerScrollView alloc] initWithFrame:CGRectMake(SV_MONTHS_WIDTH + 20.0, 0.0, SV_DATES_WIDTH, PICKER_HEIGHT) andValues:_arrDates withTextAlign:NSTextAlignmentCenter  andTextSize:15.0];
    _svDates.tag = 1;
    //[_svDates setBackgroundColor:[UIColor blueColor]];
    [_svDates setDelegate:self];
    [_svDates setDataSource:self];
    
    //Create the third column (minutes) of the picker
    _svYear = [[BSPickerScrollView alloc] initWithFrame:CGRectMake(_svDates.frame.origin.x+SV_DATES_WIDTH + 15.0, 0.0, SV_YEAR_WIDTH, PICKER_HEIGHT) andValues:_arrYear withTextAlign:NSTextAlignmentCenter andTextSize:15.0];
    _svYear.tag = 2;
    //[_svYear setBackgroundColor:[UIColor greenColor]];
    [_svYear setDelegate:self];
    [_svYear setDataSource:self];
    
    //Layer gradient
    CAGradientLayer *gradientLayerTop = [CAGradientLayer layer];
    gradientLayerTop.frame = CGRectMake(0.0, 0.0, self.frame.size.width, PICKER_HEIGHT/2);
    gradientLayerTop.colors = [NSArray arrayWithObjects:(id)[UIColor colorWithWhite:1.0 alpha:0.0].CGColor, (id)self.backgroundColor.CGColor, nil];
    gradientLayerTop.startPoint = CGPointMake(0.0f, 0.7f);
    gradientLayerTop.endPoint = CGPointMake(0.0f, 0.0f);
    
    CAGradientLayer *gradientLayerBottom = [CAGradientLayer layer];
    gradientLayerBottom.frame = CGRectMake(0.0, PICKER_HEIGHT/2.0, self.frame.size.width, PICKER_HEIGHT/2);
    gradientLayerBottom.colors = gradientLayerTop.colors;
    gradientLayerBottom.startPoint = CGPointMake(0.0f, 0.3f);
    gradientLayerBottom.endPoint = CGPointMake(0.0f, 1.0f);
    
    //
    //Add the bar selector
    [self addSubview:barSel];
    
    //Add scrollViews
    [self addSubview:_svMonths];
    [self addSubview:_svDates];
    [self addSubview:_svYear];
    
    //Add gradients
    [self.layer addSublayer:gradientLayerTop];
    [self.layer addSublayer:gradientLayerBottom];
    
    //Set the time to now
    [self setTime:[NSDate date]];
}



#pragma mark - Other methods

/*-------------------------------------------------------------------
 Method name: setTime
 Method description:
 Set the time automatically
 
 Change logs:
 -------------------------------------------------------------------*/
- (void)setTime:(NSDate *)currentDate {
    
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    [formatter setDateFormat:YEAR_ONLY_FORMAT];
    NSString *year = [formatter stringFromDate:currentDate];
    [formatter setDateFormat:MONTH_ONLY_FORMAT];
    NSString *month = [formatter stringFromDate:currentDate];
    [formatter setDateFormat:DATE_ONLY_FORMAT];
    NSString *day = [formatter stringFromDate:currentDate];
    
    int monthIndex = 0;
    int dayIndex = 0;
    int yearIndex = 0;
    
    for (int index = 0; index < [_arrMonths count]; index++) {
        
        NSString *monthL = [_arrMonths objectAtIndex:index];
        if ([monthL isEqualToString:month]) {
            monthIndex = index;
            break;
        }
    }
    
    for (int index = 0; index < [_arrDates count]; index++) {
        
        NSString *dayL = [_arrDates objectAtIndex:index];
        if ([dayL intValue] == [day intValue]) {
            dayIndex = index;
            break;
        }
    }
    
    for (int index = 0; index < [_arrYear count]; index++) {
        
        NSString *yearL = [_arrYear objectAtIndex:index];
        if ([year isEqualToString:yearL]) {
            yearIndex = index;
            break;
        }
    }
    
    
    //Set the tableViews
    [_svMonths dehighlightLastCell];
    [_svDates dehighlightLastCell];
    [_svYear dehighlightLastCell];
    
    //Center the other fields
    [self centerCellWithIndexPathRow:monthIndex forScrollView:_svMonths];
    [self centerCellWithIndexPathRow:dayIndex forScrollView:_svDates];
    [self centerCellWithIndexPathRow:yearIndex forScrollView:_svYear];
}


/*-------------------------------------------------------------------
 Method name: centerValueForScrollView
 Method description:
 Method description goes here.
 
 Change logs:
 -------------------------------------------------------------------*/
//Center the value in the bar selector
- (void)centerValueForScrollView:(BSPickerScrollView *)scrollView {
    
    //Takes the actual offset
    float offset = scrollView.contentOffset.y;
    
    //Removes the contentInset and calculates the prcise value to center the nearest cell
    offset += scrollView.contentInset.top;
    int mod = (int)offset%(int)VALUE_HEIGHT;
    float newValue = (mod >= VALUE_HEIGHT/2.0) ? offset+(VALUE_HEIGHT-mod) : offset-mod;
    
    //Calculates the indexPath of the cell and set it in the object as property
    NSInteger indexPathRow = (int)(newValue/VALUE_HEIGHT);
    
    //Center the cell
    [self centerCellWithIndexPathRow:indexPathRow forScrollView:scrollView];
}

/*-------------------------------------------------------------------
 Method name: isLeapYear
 Method description:
 Method description goes here.
 
 Change logs:
 -------------------------------------------------------------------*/
- (BOOL) isLeapYear:(int) year
{
    return ((year % 4 == 0) && (year % 100 != 0)) || (year % 400 == 0);
}


/*-------------------------------------------------------------------
 Method name: loadDatesOfTheMonths
 Method description:
 Method description goes here.
 
 Change logs:
 -------------------------------------------------------------------*/
- (void) loadDatesOfTheMonths:(NSUInteger) indexPathRow forScrollView:(BSPickerScrollView *)scrollView
{
    
    // check if self.monthSelectedIndex 30 days or 31 days, load accordingly
    if (scrollView == _svMonths) {
        
        switch (indexPathRow) {
            case 0:
            {
                //Create array Dates
                NSMutableArray *arrDates = [[NSMutableArray alloc] initWithCapacity:31];
                for(int i=1; i<=31; i++) {
                    [arrDates addObject:[NSString stringWithFormat:@"%02d", i]];
                }
                _arrDates = [NSArray arrayWithArray:arrDates];
                
            }
                break;
            case 1:
            {
                // FEBRUARY
                // check if selected yr is leap yr
                NSString *year = [_arrYear objectAtIndex:self.yearSelectedIndex];
                
                if ([self isLeapYear:[year intValue]]) {
                    
                    //Create array Dates
                    NSMutableArray *arrDates = [[NSMutableArray alloc] initWithCapacity:29];
                    for(int i=1; i<=29; i++) {
                        [arrDates addObject:[NSString stringWithFormat:@"%02d", i]];
                    }
                    _arrDates = [NSArray arrayWithArray:arrDates];
                    
                    if (self.dateSelectedIndex == 29 || self.dateSelectedIndex == 30) {
                        self.dateSelectedIndex = 28;
                    }
                    
                }// end if
                else{
                    
                    //Create array Dates
                    NSMutableArray *arrDates = [[NSMutableArray alloc] initWithCapacity:28];
                    for(int i=1; i<=28; i++) {
                        [arrDates addObject:[NSString stringWithFormat:@"%02d", i]];
                    }
                    _arrDates = [NSArray arrayWithArray:arrDates];
                    
                    if (self.dateSelectedIndex == 28 || self.dateSelectedIndex == 29 || self.dateSelectedIndex == 30) {
                        self.dateSelectedIndex = 27;
                    }
                }
            }
                break;
            case 2:
            {
                //Create array Dates
                NSMutableArray *arrDates = [[NSMutableArray alloc] initWithCapacity:31];
                for(int i=1; i<=31; i++) {
                    [arrDates addObject:[NSString stringWithFormat:@"%02d", i]];
                }
                _arrDates = [NSArray arrayWithArray:arrDates];
            }
                break;
            case 3:
            {
                //Create array Dates
                NSMutableArray *arrDates = [[NSMutableArray alloc] initWithCapacity:30];
                for(int i=1; i<=30; i++) {
                    [arrDates addObject:[NSString stringWithFormat:@"%02d", i]];
                }
                _arrDates = [NSArray arrayWithArray:arrDates];
                if (self.dateSelectedIndex == 30) {
                    self.dateSelectedIndex = 29;
                }
            }
                break;
            case 4:
            {
                //Create array Dates
                NSMutableArray *arrDates = [[NSMutableArray alloc] initWithCapacity:31];
                for(int i=1; i<=31; i++) {
                    [arrDates addObject:[NSString stringWithFormat:@"%02d", i]];
                }
                _arrDates = [NSArray arrayWithArray:arrDates];
            }
                break;
            case 5:
            {
                //Create array Dates
                NSMutableArray *arrDates = [[NSMutableArray alloc] initWithCapacity:30];
                for(int i=1; i<=30; i++) {
                    [arrDates addObject:[NSString stringWithFormat:@"%02d", i]];
                }
                _arrDates = [NSArray arrayWithArray:arrDates];
                
                if (self.dateSelectedIndex == 30) {
                    self.dateSelectedIndex = 29;
                }
            }
                break;
            case 6:
            {
                //Create array Dates
                NSMutableArray *arrDates = [[NSMutableArray alloc] initWithCapacity:31];
                for(int i=1; i<=31; i++) {
                    [arrDates addObject:[NSString stringWithFormat:@"%02d", i]];
                }
                _arrDates = [NSArray arrayWithArray:arrDates];
            }
                break;
            case 7:
            {
                //Create array Dates
                NSMutableArray *arrDates = [[NSMutableArray alloc] initWithCapacity:31];
                for(int i=1; i<=31; i++) {
                    [arrDates addObject:[NSString stringWithFormat:@"%02d", i]];
                }
                _arrDates = [NSArray arrayWithArray:arrDates];
            }
                break;
            case 8:
            {
                //Create array Dates
                NSMutableArray *arrDates = [[NSMutableArray alloc] initWithCapacity:30];
                for(int i=1; i<=30; i++) {
                    [arrDates addObject:[NSString stringWithFormat:@"%02d", i]];
                }
                _arrDates = [NSArray arrayWithArray:arrDates];
                
                if (self.dateSelectedIndex == 30) {
                    self.dateSelectedIndex = 29;
                }
            }
                break;
            case 9:
            {
                //Create array Dates
                NSMutableArray *arrDates = [[NSMutableArray alloc] initWithCapacity:31];
                for(int i=1; i<=31; i++) {
                    [arrDates addObject:[NSString stringWithFormat:@"%02d", i]];
                }
                _arrDates = [NSArray arrayWithArray:arrDates];
            }
                break;
            case 10:
            {
                //Create array Dates
                NSMutableArray *arrDates = [[NSMutableArray alloc] initWithCapacity:30];
                for(int i=1; i<=30; i++) {
                    [arrDates addObject:[NSString stringWithFormat:@"%02d", i]];
                }
                _arrDates = [NSArray arrayWithArray:arrDates];
                
                if (self.dateSelectedIndex == 30) {
                    self.dateSelectedIndex = 29;
                }
            }
                break;
            case 11:
            {
                //Create array Dates
                NSMutableArray *arrDates = [[NSMutableArray alloc] initWithCapacity:31];
                for(int i=1; i<=31; i++) {
                    [arrDates addObject:[NSString stringWithFormat:@"%02d", i]];
                }
                _arrDates = [NSArray arrayWithArray:arrDates];
            }
                break;
                
            default:
                break;
        }
        
        _svDates.arrValues = [NSArray arrayWithArray:_arrDates];
        [_svDates reloadData];
        [self centerCellWithIndexPathRowFromLoadDates:self.dateSelectedIndex forScrollView:_svDates];
        
    }
    else if (scrollView == _svYear)
    {
        if (indexPathRow >= [_arrYear count]) {
            return;
        }
        
        NSString *year = [_arrYear objectAtIndex:indexPathRow];
        
        if ([self isLeapYear:[year intValue]]) {
            
            if (self.monthSelectedIndex == 1)
            {
                //Create array Dates
                NSMutableArray *arrDates = [[NSMutableArray alloc] initWithCapacity:29];
                for(int i=1; i<=29; i++) {
                    [arrDates addObject:[NSString stringWithFormat:@"%02d", i]];
                }
                _arrDates = [NSArray arrayWithArray:arrDates];
                
                if (self.dateSelectedIndex == 29 || self.dateSelectedIndex == 30) {
                    self.dateSelectedIndex = 28;
                }
            }// ends if
        }// end if
        else{
            
            if (self.monthSelectedIndex == 1)
            {
                //Create array Dates
                NSMutableArray *arrDates = [[NSMutableArray alloc] initWithCapacity:28];
                for(int i=1; i<=28; i++) {
                    [arrDates addObject:[NSString stringWithFormat:@"%02d", i]];
                }
                _arrDates = [NSArray arrayWithArray:arrDates];
                
                if (self.dateSelectedIndex == 28 || self.dateSelectedIndex == 29 || self.dateSelectedIndex == 30) {
                    self.dateSelectedIndex = 27;
                }
            }// ends if
        }
        
        _svDates.arrValues = [NSArray arrayWithArray:_arrDates];
        [_svDates reloadData];
        [self centerCellWithIndexPathRowFromLoadDates:self.dateSelectedIndex forScrollView:_svDates];
        
    } // end else if
}


/*-------------------------------------------------------------------
 Method name: centerCellWithIndexPathRowFromLoadDates
 Method description:
 Method description goes here.
 
 Change logs:
 -------------------------------------------------------------------*/
- (void)centerCellWithIndexPathRowFromLoadDates:(NSUInteger)indexPathRow forScrollView:(BSPickerScrollView *)scrollView
{
    if(indexPathRow >= [scrollView.arrValues count]) {
        indexPathRow = [scrollView.arrValues count]-1;
    }
    
    float newOffset = indexPathRow*VALUE_HEIGHT;
    
    //Re-add the contentInset and set the new offset
    newOffset -= BAR_SEL_ORIGIN_Y;
    
    [CATransaction begin];
    
    [CATransaction setCompletionBlock:^{
        
        //Highlight the cell
        [scrollView highlightCellWithIndexPathRow:indexPathRow];
    }];
    
    [scrollView setContentOffset:CGPointMake(0.0, newOffset) animated:YES];
    
    [CATransaction commit];
    
    if ([_delegate respondsToSelector:@selector(selectedDate:)]) {
        
        if (scrollView == _svMonths) {
            self.monthSelectedIndex = indexPathRow;
        }else if (scrollView == _svDates){
            self.dateSelectedIndex = indexPathRow;
        }else if (scrollView == _svYear){
            self.yearSelectedIndex = indexPathRow;
        }
        
        NSString *month = [_arrMonths objectAtIndex:self.monthSelectedIndex];
        NSString *date = [_arrDates objectAtIndex:self.dateSelectedIndex];
        NSString *year = [_arrYear objectAtIndex:self.yearSelectedIndex];
        
        NSMutableString *fullDateStr = [[NSMutableString alloc] init];
        [fullDateStr appendString:[NSString stringWithFormat:@"%@ ", month]];
        [fullDateStr appendString:[NSString stringWithFormat:@"%@, ", date]];
        [fullDateStr appendString:[NSString stringWithFormat:@"%@", year]];
        
        // Convert string to date object
        NSDateFormatter *dateFormat = [[NSDateFormatter alloc] init];
        [dateFormat setDateFormat:MONTH_DATE_YEAR_FORMAT];
        NSDate *dateToReturn = [dateFormat dateFromString:fullDateStr];
        
        [_delegate selectedDate:dateToReturn];
    }
    
}


/*-------------------------------------------------------------------
 Method name: centerCellWithIndexPathRow
 Method description:
 Method description goes here.
 
 Change logs:
 -------------------------------------------------------------------*/
//Center phisically the cell
- (void)centerCellWithIndexPathRow:(NSUInteger)indexPathRow forScrollView:(BSPickerScrollView *)scrollView {
    
    [self loadDatesOfTheMonths:indexPathRow forScrollView:scrollView];
    
    if(indexPathRow >= [scrollView.arrValues count]) {
        indexPathRow = [scrollView.arrValues count]-1;
    }
    
    float newOffset = indexPathRow*VALUE_HEIGHT;
    
    //Re-add the contentInset and set the new offset
    newOffset -= BAR_SEL_ORIGIN_Y;
    
    [CATransaction begin];
    
    [CATransaction setCompletionBlock:^{
        
        //Highlight the cell
        [scrollView highlightCellWithIndexPathRow:indexPathRow];
    }];
    
    [scrollView setContentOffset:CGPointMake(0.0, newOffset) animated:YES];
    
    [CATransaction commit];
    
    if ([_delegate respondsToSelector:@selector(selectedDate:)]) {
        
        if (scrollView == _svMonths) {
            self.monthSelectedIndex = indexPathRow;
        }else if (scrollView == _svDates){
            self.dateSelectedIndex = indexPathRow;
        }else if (scrollView == _svYear){
            self.yearSelectedIndex = indexPathRow;
        }
        
        NSString *month = [_arrMonths objectAtIndex:self.monthSelectedIndex];
        NSString *date = [_arrDates objectAtIndex:self.dateSelectedIndex];
        NSString *year = [_arrYear objectAtIndex:self.yearSelectedIndex];
        
        NSMutableString *fullDateStr = [[NSMutableString alloc] init];
        [fullDateStr appendString:[NSString stringWithFormat:@"%@ ", month]];
        [fullDateStr appendString:[NSString stringWithFormat:@"%@, ", date]];
        [fullDateStr appendString:[NSString stringWithFormat:@"%@", year]];
        
        // Convert string to date object
        NSDateFormatter *dateFormat = [[NSDateFormatter alloc] init];
        [dateFormat setDateFormat:MONTH_DATE_YEAR_FORMAT];
        NSDate *dateToReturn = [dateFormat dateFromString:fullDateStr];
        
        [_delegate selectedDate:dateToReturn];
    }
}


#pragma mark - UIScrollViewDelegate

/*-------------------------------------------------------------------
 Method name: scrollViewDidEndDragging
 Method description:
 Method description goes here.
 
 Change logs:
 -------------------------------------------------------------------*/
- (void)scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate {
    if (![scrollView isDragging]) {
        [self centerValueForScrollView:(BSPickerScrollView *)scrollView];
    }
}


/*-------------------------------------------------------------------
 Method name: scrollViewDidEndDecelerating
 Method description:
 Method description goes here.
 
 Change logs:
 -------------------------------------------------------------------*/
- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView {
    [self centerValueForScrollView:(BSPickerScrollView *)scrollView];
}


/*-------------------------------------------------------------------
 Method name: scrollViewWillBeginDragging
 Method description:
 Method description goes here.
 
 Change logs:
 -------------------------------------------------------------------*/
- (void)scrollViewWillBeginDragging:(UIScrollView *)scrollView {
    
    BSPickerScrollView *sv = (BSPickerScrollView *)scrollView;
    [sv setScrolling:YES];
    [sv dehighlightLastCell];
}

#pragma - UITableViewDelegate


/*-------------------------------------------------------------------
 Method name: tableView
 Method description:
 numberOfRowsInSection
 
 Change logs:
 -------------------------------------------------------------------*/

-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    BSPickerScrollView *sv = (BSPickerScrollView *)tableView;
    return [sv.arrValues count];
}


/*-------------------------------------------------------------------
 Method name: tableView
 Method description:
 cellForRowAtIndexPath
 
 Change logs:
 -------------------------------------------------------------------*/
-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    NSString *identifier = @"reusableCell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:identifier];
    
    BSPickerScrollView *sv = (BSPickerScrollView *)tableView;
    
    if(!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:identifier];
        [cell setBackgroundColor:[UIColor clearColor]];
        [cell.textLabel setFont:sv.cellFont];
        [cell setSelectionStyle:UITableViewCellSelectionStyleNone];
    }
    
    [cell.textLabel setTextColor:(indexPath.row == sv.tagLastSelected) ? SELECTED_TEXT_COLOR : TEXT_COLOR];
    [cell.textLabel setText:sv.arrValues[indexPath.row]];
    
    return cell;
}


/*-------------------------------------------------------------------
 Method name: tableView
 Method description:
 heightForRowAtIndexPath
 
 Change logs:
 -------------------------------------------------------------------*/
-(CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return VALUE_HEIGHT;
}

@end
