//
//  ViewController.m
//  WZZHttpTool
//
//  Created by 王泽众 on 2017/5/20.
//  Copyright © 2017年 wzz. All rights reserved.
//

#import "ViewController.h"
#import "WZZHttpTool.h"
#import "WZZDownloadVC.h"

static ViewController * selfVC;
static UIAlertController * alt;

NSString * replaceUnicode(NSString * unicodeStr) {
    
    NSString *tempStr1 = [unicodeStr stringByReplacingOccurrencesOfString:@"\\u" withString:@"\\U"];
    NSString *tempStr2 = [tempStr1 stringByReplacingOccurrencesOfString:@"\"" withString:@"\\\""];
    NSString *tempStr3 = [[@"\"" stringByAppendingString:tempStr2] stringByAppendingString:@"\""];
    NSData *tempData = [tempStr3 dataUsingEncoding:NSUTF8StringEncoding];
    NSString * returnStr = [NSPropertyListSerialization propertyListWithData:tempData options:NSPropertyListImmutable format:nil error:nil];
    return [returnStr stringByReplacingOccurrencesOfString:@"\\r\\n" withString:@"\n"];
}

void showMessage(id msg) {
    [alt dismissViewControllerAnimated:YES completion:^{
        NSString * str = [NSString stringWithFormat:@"%@", msg];
        str = replaceUnicode(str);
        UIAlertController * ac = [UIAlertController alertControllerWithTitle:nil message:str preferredStyle:UIAlertControllerStyleAlert];
        [ac addAction:[UIAlertAction actionWithTitle:@"确定" style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
            
        }]];
        [selfVC presentViewController:ac animated:YES completion:nil];
    }];
}

@interface ViewController ()<UITableViewDelegate, UITableViewDataSource>
{
    UITableView * mainTableView;
    NSMutableArray * dataArr;
    void(^_loginNetBlock)();
}
@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    [self creatUI];
    [self loadData];
}

- (void)creatUI {
    selfVC = self;
    mainTableView = [[UITableView alloc] initWithFrame:self.view.bounds style:UITableViewStylePlain];
    [self.view addSubview:mainTableView];
    [mainTableView setTableFooterView:[[UIView alloc] init]];
    [mainTableView setDelegate:self];
    [mainTableView setDataSource:self];
    [mainTableView registerClass:[UITableViewCell class] forCellReuseIdentifier:@"cell"];
}

- (void)loadData {
    void(^aBlock)();
    dataArr = [NSMutableArray array];
    
    //get请求测试
    aBlock = ^{
        [WZZHttpTool GET:@"https://api.wdquan.cn/comment/auto?section=1"
             successBlock:^(id httpResponse) {
                 showMessage(httpResponse);
             }
              failedBlock:^(NSError *httpError) {
                  showMessage(httpError);
              }];
    };
    [dataArr addObject:@{
                         @"name":@"get请求测试",
                         @"block":aBlock
                         }];
    
    //post请求测试
    aBlock = ^{
        [WZZHttpTool POST:@"https://api.wdquan.cn/tokens"
                 httpBody:@{
                            @"username":@"13731160065",
                            @"grantType":@"phone",
                            @"password":@"111111"
                            }
            successBlock:^(id httpResponse) {
                showMessage(httpResponse);
            }
             failedBlock:^(NSError *httpError) {
                 showMessage(httpError);
             }];
    };
    [dataArr addObject:@{
                         @"name":@"舞蹈圈登录",
                         @"block":aBlock
                         }];
    
    //生活没烦恼登录
    aBlock = ^{
        [WZZHttpTool POST:@"http://mfn.jiankuai.cn/appc/login"
                 httpBody:@{
                            @"phone":@"13731160065",
                            @"password":@"111111"
                            }
             successBlock:^(id httpResponse) {
                 showMessage(httpResponse);
             }
              failedBlock:^(NSError *httpError) {
                  showMessage(httpError);
              }];
    };
    [dataArr addObject:@{
                         @"name":@"生活没烦恼登录",
                         @"block":aBlock
                         }];
    
    //智慧停车登录
    aBlock = ^{
        [WZZHttpTool POST:@"http://www.vehnest.com/zhihuitingche/applogin"
                 httpBody:@{
                            @"tel":@"13731160065",
                            @"password":@"111111"
                            }
             successBlock:^(id httpResponse) {
                 showMessage(httpResponse);
             }
              failedBlock:^(NSError *httpError) {
                  showMessage(httpError);
              }];
    };
    [dataArr addObject:@{
                         @"name":@"智慧停车登录",
                         @"block":aBlock
                         }];
    
    //测试php POST接口
    aBlock = ^{
        [WZZHttpTool POST:@"http://110.240.123.244:38080/phpApi/helloGet.php"
                 httpBody:@{
                            @"arg1":@"aaa",
                            @"arg2":@"bbb"
                            }
             successBlock:^(id httpResponse) {
                 showMessage(httpResponse);
             }
              failedBlock:^(NSError *httpError) {
                  showMessage(httpError);
              }];
    };
    [dataArr addObject:@{
                         @"name":@"测试php POST接口",
                         @"block":aBlock
                         }];
    
    //测试上传图片php POST接口
    aBlock = ^{
        [WZZHttpTool POST:@"http://47.94.91.101/Documents/upload.php"
              addFormData:^(WZZPOSTFormData * formData) {
                  UIImage * image = [UIImage imageNamed:@"imggg.jpg"];
                  NSData * data = UIImageJPEGRepresentation(image, 1.0f);
                  [formData addData:data key:@"file1" type:WZZHttpTool_FormDataType_ImageJPG];
              }
                 httpBody:@{
                            @"abc":@"aaa",
                            @"arg1":@"bbb"
                            }
             successBlock:^(id httpResponse) {
                 showMessage(httpResponse);
             }
              failedBlock:^(NSError *httpError) {
                  showMessage(httpError);
              }];
    };
    [dataArr addObject:@{
                         @"name":@"测试上传图片php",
                         @"block":aBlock
                         }];
    
    
    aBlock = ^{
        WZZDownloadVC * vc = [[WZZDownloadVC alloc] init];
        [self presentViewController:vc animated:YES completion:nil];
    };
    [dataArr addObject:@{
                         @"name":@"多任务下载",
                         @"block":aBlock,
                         @"hud":@(NO)
                         }];
    
    [mainTableView reloadData];
}

#pragma mark - tableview代理
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return dataArr.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell * cell = [tableView dequeueReusableCellWithIdentifier:@"cell"];
    
    [cell.textLabel setText:dataArr[indexPath.row][@"name"]];
    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    void(^aBlock)();
    aBlock = dataArr[indexPath.row][@"block"];
    if ([dataArr[indexPath.row][@"hud"] integerValue]) {
        alt = [UIAlertController alertControllerWithTitle:@"请稍等" message:nil preferredStyle:UIAlertControllerStyleAlert];
        [self presentViewController:alt animated:YES completion:^{
            aBlock();
        }];
    } else {
        aBlock();
    }
}

@end
