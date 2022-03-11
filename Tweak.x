@interface MTAAlarmTableViewController : UITableViewController
- (void)showAlarmDeadline;
- (void)handleAlarmDeadline;
@end

@interface MTUIDateLabel : UIView
@end

@interface MTUIDigitalClockLabel : MTUIDateLabel
@end

// Alarm vars
static UILabel *label;
static long hour;
static long minute;
static NSTimer *timer;
static bool should_show_remain_time = false;
static NSMutableArray *orig_alrams_title;
static NSTimeInterval delay_s = 0;

%hook MTAlarmDataSource
	-(id)addAlarm:(id)arg1{
		delay_s = 0.5;
		orig_alrams_title = [[NSMutableArray alloc] init];
		return %orig;
	}
	-(id)removeAlarm:(id)arg1{
		delay_s = 0.5;
		orig_alrams_title = [[NSMutableArray alloc] init];
		return %orig;
	}
%end

%hook MTAAlarmTableViewController

	- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section{
	
		UIView *view = (UIView *)%orig;
				
		[view setUserInteractionEnabled:YES];
		CGFloat width = self.view.frame.size.width;
	
		UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(width-250, -8, 180, 50)];
		[label setFont:[UIFont systemFontOfSize:18 weight:UIFontWeightLight]];
		[label setText:@"Show remaining time:"];
		
		UISwitch *mySwitch = [[UISwitch alloc] initWithFrame:CGRectMake(width-70, 0, 50, 50)];
		[mySwitch addTarget:self action:@selector(valueChanged:) forControlEvents:UIControlEventValueChanged];
		if(should_show_remain_time){
			[mySwitch setOn:YES];
		}

		[view addSubview:label];
		[view addSubview:mySwitch];
		
		if(section == 0){
			return %orig;
		}

		return view;
	}
	%new -(void) valueChanged:(UISwitch *)mySwitch{
		should_show_remain_time = mySwitch.isOn? true:false;
	}
	- (void)viewDidAppear:(BOOL)animated{
		%orig;
		[self showAlarmDeadline];
				
		if(!timer){
			timer = [NSTimer scheduledTimerWithTimeInterval:1 target:self selector:@selector(handleAlarmDeadline) userInfo:nil repeats:YES];
		}
	}
	- (id)contentScrollView{
		[self handleAlarmDeadline];
		return %orig;
	}
	%new - (void)handleAlarmDeadline{
		dispatch_time_t delay = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delay_s * NSEC_PER_SEC));
		dispatch_after(delay, dispatch_get_main_queue(), ^(void){
			[self showAlarmDeadline];
			delay_s = 0;
		});
	}
	%new - (void)showAlarmDeadline{
		if(orig_alrams_title.count < 1) {
			for(UITableViewCell *cell in self.tableView.subviews){
				if([NSStringFromClass([cell class]) isEqualToString:@"MTAAlarmTableViewCell"]){
					for(UILabel *lbl in cell.subviews.firstObject.subviews){
						if([lbl isKindOfClass:[UILabel class]]){
							if(!orig_alrams_title){
								orig_alrams_title = [[NSMutableArray alloc] init];
							}
							if(!lbl.text) continue;
							[orig_alrams_title addObject:lbl.text];	
						}
					}
				}
			}
		}

		int internal_iteration = 0;
		for(UITableViewCell *cell in self.tableView.subviews){
			if([NSStringFromClass([cell class]) isEqualToString:@"MTAAlarmTableViewCell"]){
										
				// Get alarm label
				for(UILabel *lbl in cell.subviews.firstObject.subviews){
					if([lbl isKindOfClass:[UILabel class]]){
						label = lbl;
						internal_iteration += 1;
					}
				}
								
				// Get alarm time
				for(MTUIDigitalClockLabel *time in cell.subviews.firstObject.subviews){
					if([NSStringFromClass([time class]) isEqualToString:@"MTUIDigitalClockLabel"]){
						MTUIDigitalClockLabel *timeLabel = (MTUIDigitalClockLabel*)time;
						hour = [[timeLabel valueForKey:@"hour"] intValue];
						minute = [[timeLabel valueForKey:@"minute"] intValue];
					}
				}
				
				// Get alarm date
				NSDateComponents *alarmDateComponent = [[NSCalendar currentCalendar] components:NSCalendarUnitDay | NSCalendarUnitHour | NSCalendarUnitMinute | NSCalendarUnitSecond fromDate:[NSDate date]];
				[alarmDateComponent setHour:hour];
				[alarmDateComponent setMinute:minute];
				[alarmDateComponent setSecond:0];
				NSDate *alarmDate = [[NSCalendar currentCalendar] dateFromComponents:alarmDateComponent];
				
				// Get now date
				NSDateComponents *now = [[NSCalendar currentCalendar] components:NSCalendarUnitDay | NSCalendarUnitHour | NSCalendarUnitMinute | NSCalendarUnitSecond fromDate:[NSDate date]];
				NSDate *nowDate = [[NSCalendar currentCalendar] dateFromComponents:now];
					
				// Get diff
				NSDateComponents *result = [[NSCalendar currentCalendar] components:NSCalendarUnitDay | NSCalendarUnitHour | NSCalendarUnitMinute | NSCalendarUnitSecond fromDate:nowDate toDate:alarmDate options:0];
				if([result hour] < 0 || [result minute] < 0){ // if alarm time already passed for that day
					[alarmDateComponent setDay:[alarmDateComponent day] + 1];
					alarmDate = [[NSCalendar currentCalendar] dateFromComponents:alarmDateComponent];
					result = [[NSCalendar currentCalendar] components:NSCalendarUnitDay | NSCalendarUnitHour | NSCalendarUnitMinute | NSCalendarUnitSecond fromDate:nowDate toDate:alarmDate options:0];
				}
				
				// change alarm label
				if(!should_show_remain_time){
					if(orig_alrams_title.count > 1){
						if(orig_alrams_title.count < internal_iteration) return;
						[label setText:[orig_alrams_title objectAtIndex:internal_iteration-1]];
					}
				}else{
					[label setText:[NSString stringWithFormat:@"Alarm in %ld hours and %ld min and %ld sec", [result hour], [result minute], [result second]]];	
				}
			}
		}
	}
%end