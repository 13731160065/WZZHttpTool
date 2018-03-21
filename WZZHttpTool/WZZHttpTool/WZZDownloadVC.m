//
//  WZZDownloadVC.m
//  WZZHttpTool
//
//  Created by 王泽众 on 2018/2/23.
//  Copyright © 2018年 wzz. All rights reserved.
//

#import "WZZDownloadVC.h"
#import "WZZHttpTool.h"

@interface WZZDownloadVC ()<UITableViewDelegate, UITableViewDataSource>
{
    NSMutableArray * dataArr;
}
@property (weak, nonatomic) IBOutlet UITableView *mainTableView;

@end

@implementation WZZDownloadVC

- (void)viewDidLoad {
    [super viewDidLoad];

    [self loadData];
}

- (void)loadData {
    dataArr = [NSMutableArray array];
    [dataArr addObject:[NSMutableDictionary dictionaryWithDictionary:@{
                                                                       @"idx":@"0",
                                                                       @"name":@"MAC版安卓模拟器",
                                                                       @"url":@"http://m5.pc6.com/cjh5/BlueStacks.dmg",
                                                                       }]];
    [dataArr addObject:[NSMutableDictionary dictionaryWithDictionary:@{
                                                                       @"idx":@"1",
                                                                       @"name":@"战网",
                                                                       @"url":@"http://sw.bos.baidu.com/sw-search-sp/software/fbc434593833a/Battle.net_Setup_CN2.3.2.4716.exe",
                                                                       }]];
    [dataArr addObject:[NSMutableDictionary dictionaryWithDictionary:@{
                                                                       @"idx":@"2",
                                                                       @"name":@"AFNetworking",
                                                                       @"url":@"https://github.com/AFNetworking/AFNetworking/archive/master.zip",
                                                                       }]];
    [dataArr addObject:[NSMutableDictionary dictionaryWithDictionary:@{
                                                                       @"idx":@"3",
                                                                       @"name":@"FFMpeg",
                                                                       @"url":@"https://github.com/FFmpeg/FFmpeg/archive/master.zip",
                                                                       }]];
    [dataArr addObject:[NSMutableDictionary dictionaryWithDictionary:@{
                                                                       @"idx":@"4",
                                                                       @"name":@"opencv",
                                                                       @"url":@"https://github.com/opencv/opencv/archive/master.zip",
                                                                       }]];
    [dataArr addObject:[NSMutableDictionary dictionaryWithDictionary:@{
                                                                       @"idx":@"5",
                                                                       @"name":@"一个mp3",
                                                                       @"url":@"http://hao.1015600.com/upload/ring/000/994/64580a81318e0f69a1b03d4085e3a59b.mp3",
                                                                       }]];

    //设置映射
    NSArray * tmpModelArr = [WZZHttpTool shareInstance].downloadModelDic.allKeys;
    for (int i = 0; i < tmpModelArr.count; i++) {
        NSString * key = tmpModelArr[i];
        WZZDownloadTaskModel * model = [WZZHttpTool shareInstance].downloadModelDic[key];
        if (model.tmpId) {
            NSMutableDictionary * dic = dataArr[model.tmpId.integerValue];
            dic[@"tid"] = model.taskId;
        }
    }
    [_mainTableView reloadData];
    [self loopGetProgress];
}

//循环加载进度
- (void)loopGetProgress {
    [[_mainTableView visibleCells] enumerateObjectsUsingBlock:^(__kindof UITableViewCell * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        NSIndexPath * indexPath = [_mainTableView indexPathForCell:obj];
        NSDictionary * dic = dataArr[indexPath.row];
        WZZDownloadTaskModel * model = [WZZHttpTool shareInstance].downloadModelDic[dic[@"tid"]];
        
        //标题
        [obj.textLabel setNumberOfLines:3];
        NSString * name = dic[@"name"];
        NSString * state = @"";
        switch (model.state) {
            case WZZHttpTool_Download_State_Stop:
            {
                state = @"停止";
            }
                break;
            case WZZHttpTool_Download_State_Pause:
            {
                state = @"暂停";
            }
                break;
            case WZZHttpTool_Download_State_Failed:
            {
                state = @"下载失败";
            }
                break;
            case WZZHttpTool_Download_State_Loading:
            {
                state = @"下载中";
            }
                break;
            case WZZHttpTool_Download_State_Success:
            {
                state = @"下载成功";
            }
                break;
            case WZZHttpTool_Download_State_None:
            {
                state = @"未下载";
            }
                break;
            default:
                break;
        }
        [obj.textLabel setText:[NSString stringWithFormat:@"%@(%@)", name, state]];
        
        //副标题
        if (dic[@"tid"]) {
            [obj.detailTextLabel setText:[NSString stringWithFormat:@"%@/%@ %.1lf%%", model.currentByte, model.totalByte, model.progress.doubleValue*100]];
        } else {
            [obj.detailTextLabel setText:nil];
        }
        
        [obj.detailTextLabel setAdjustsFontSizeToFitWidth:YES];
    }];
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.2f * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [self loopGetProgress];
    });
}

- (IBAction)backClick:(id)sender {
    [self dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark - tablview
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return dataArr.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell * cell = [tableView dequeueReusableCellWithIdentifier:@"cell"];
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:@"cell"];
    }
    
    [cell.textLabel setNumberOfLines:3];
    NSDictionary * dic = dataArr[indexPath.row];
    NSString * name = dic[@"name"];
    [cell.textLabel setText:name];
    
    if (dic[@"tid"]) {
        WZZDownloadTaskModel * model = [WZZHttpTool shareInstance].downloadModelDic[dic[@"tid"]];
        [cell.detailTextLabel setText:[NSString stringWithFormat:@"%@/%@>>%.1lf%%", model.currentByte, model.totalByte, model.progress.doubleValue*100]];
    } else {
        [cell.detailTextLabel setText:nil];
    }
    [cell.detailTextLabel setAdjustsFontSizeToFitWidth:YES];
    
    return cell;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return 65;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    NSMutableDictionary * dic = dataArr[indexPath.row];
    if (dic[@"tid"]) {
        //继续或暂停
        WZZDownloadTaskModel * model = [WZZHttpTool shareInstance].downloadModelDic[dic[@"tid"]];
        model.tmpId = @(indexPath.row).stringValue;
        switch (model.state) {
            case WZZHttpTool_Download_State_Failed:
            {
                //失败，重新下载
                [WZZHttpTool downloadWithUrl:model.url];
            }
                break;
            case WZZHttpTool_Download_State_Loading:
            {
                //下载中，暂停
                [model pause];
            }
                break;
            case WZZHttpTool_Download_State_Pause:
            {
                //暂停，开始
                [model resume];
            }
                break;
            case WZZHttpTool_Download_State_Stop:
            {
                //停止，继续
                [WZZHttpTool resumeDownloadWithTaskId:model.taskId];
            }
                break;
            case WZZHttpTool_Download_State_Success:
            {
                //下完了，不操作
            }
                break;
            case WZZHttpTool_Download_State_None:
            {
                //未下载
                [WZZHttpTool downloadWithUrl:model.url];
            }
                break;
            default:
                break;
        }
    } else {
        //还没任务，下载
        WZZDownloadTaskModel * model = [WZZHttpTool downloadWithUrl:dic[@"url"]];
        __weak WZZDownloadTaskModel * am = model;
        dic[@"tid"] = model.taskId;
        model.tmpId = @(indexPath.row).stringValue;
        model.downloadCompleteBlock = ^(NSURL *location, NSError *error) {
            NSLog(@"%@", location?location:error);
            if (!error) {
                //本地推送
                UILocalNotification *localNotification = [[UILocalNotification alloc] init];
                localNotification.alertBody = [NSString stringWithFormat:@"“%@”下载完成", dic[@"name"]];
                dispatch_async(dispatch_get_main_queue(), ^{
                    [[UIApplication sharedApplication] presentLocalNotificationNow:localNotification];
                });
                
                NSError * e;
                [[NSFileManager defaultManager] moveItemAtURL:location toURL:[NSURL fileURLWithPath:[NSString stringWithFormat:@"%@/Documents/%@.%@", NSHomeDirectory(), am.taskId, [[am.url componentsSeparatedByString:@"."] lastObject]]] error:&e];
                NSLog(@"fff%@", e);
            }
        };
    }
//    [tableView reloadData];
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    NSMutableDictionary * dic = dataArr[indexPath.row];
    if (dic[@"tid"]) {
        return YES;
    } else {
        return NO;
    }
}

- (NSString *)tableView:(UITableView *)tableView titleForDeleteConfirmationButtonForRowAtIndexPath:(NSIndexPath *)indexPath {
    return @"停止下载";
}

- (void)tableView:(UITableView *)tableView
commitEditingStyle:(UITableViewCellEditingStyle)editingStyle
forRowAtIndexPath:(NSIndexPath *)indexPath {
    NSMutableDictionary * dic = dataArr[indexPath.row];
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        [WZZHttpTool cancelDownloadWithTaskId:dic[@"tid"]];
        dic[@"tid"] = nil;
//        [tableView reloadData];
    }
}

@end
