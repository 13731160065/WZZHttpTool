//
//  WZZHttpTool.m
//  WZZHttpTool
//
//  Created by 王泽众 on 2017/5/20.
//  Copyright © 2017年 wzz. All rights reserved.
//

#import "WZZHttpTool.h"

#define WZZHTTPTOOLBOUNDARY @"${wzzhttptoolboundary}"

static WZZHttpTool * tool;

@interface WZZHttpTool ()<NSURLSessionDelegate>
{
    NSURLSession * session;
}

@end

@implementation WZZHttpTool

//MARK:单例
+ (instancetype)shareInstance {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        tool = [[WZZHttpTool alloc] init];
        tool.bodyType = WZZHttpToolBodyType_default;
    });
    return tool;
}

//MARK:通用普通请求
+ (void)requestWithMethod:(NSString *)method
                      url:(NSString *)url
               httpHeader:(NSDictionary *)headerDic
                 httpBody:(NSDictionary *)bodyDic
                 bodyType:(WZZHttpToolBodyType)bodyType
             successBlock:(void (^)(id))successBlock
              failedBlock:(void (^)(NSError *))failedBlock {
    [self requestWithMethod:method url:url httpHeader:headerDic httpBody:bodyDic bodyType:bodyType fromFile:nil successBlock:successBlock failedBlock:failedBlock];
}

//MARK:POST请求带上传文件
+ (void)requestWithMethod:(NSString *)method
                      url:(NSString *)url
               httpHeader:(NSDictionary *)headerDic
                 httpBody:(NSDictionary *)bodyDic
                 bodyType:(WZZHttpToolBodyType)bodyType
                 fromFile:(id)formFile
             successBlock:(void (^)(id))successBlock
              failedBlock:(void (^)(NSError *))failedBlock {
    //链接
    NSMutableURLRequest * req = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:url]];
    
    //请求方法
    if (method) {
        req.HTTPMethod = method;
    }
    
    //判断请求体
    if (bodyType == WZZHttpToolBodyType_textPlain) {
        //请求体
        if (bodyDic) {
            NSArray * arr = bodyDic.allKeys;
            NSMutableArray * bodyArr = [NSMutableArray array];
            for (int i = 0; i < arr.count; i++) {
                NSString * key = arr[i];
                NSString * value = bodyDic[key];
                [bodyArr addObject:[NSString stringWithFormat:@"%@=%@", key, value]];
            }
            NSString * bodyStr = [bodyArr componentsJoinedByString:@"&"];
            req.HTTPBody = [bodyStr dataUsingEncoding:NSUTF8StringEncoding];
        }
        
        //请求头
        if (headerDic) {
            req.allHTTPHeaderFields = headerDic;
        }
    } else if (bodyType == WZZHttpToolBodyType_jsonData) {
        //请求体
        if (bodyDic) {
            NSError * err;
            req.HTTPBody = [NSJSONSerialization dataWithJSONObject:bodyDic options:0 error:&err];
            if (err) {
                if (failedBlock) {
                    failedBlock(err);
                }
                return;
            }
        }
        
        //请求头
        NSMutableDictionary * hDic = [NSMutableDictionary dictionaryWithDictionary:@{@"Content-Type":@"application/json"}];
        if (headerDic) {
            [hDic addEntriesFromDictionary:headerDic];
        }
        req.allHTTPHeaderFields = hDic;
    }
    
    //判断是否表单提交
    if (formFile) {
        //表单头标志
        NSArray * formDataArr = formFile;
        if (formDataArr.count) {
            //添加multipart请求头
            NSMutableDictionary * hDic = [NSMutableDictionary dictionaryWithDictionary:headerDic];
            hDic[@"Content-Type"] = [NSString stringWithFormat:@"multipart/form-data boundary=%@", WZZHTTPTOOLBOUNDARY];
            req.allHTTPHeaderFields = hDic;
        }
        
        //body数据
        NSMutableData * mutiData = [NSMutableData data];
        //表单普通数据字符串
        NSMutableString * bodyStr = [NSMutableString stringWithString:@""];
        
        //表单中普通参数
        NSArray * bodyKeyArr = [bodyDic allKeys];
        for (int i = 0; i < bodyKeyArr.count; i++) {
            NSString * key = bodyKeyArr[i];
            NSString * value = bodyDic[key];
            [bodyStr appendFormat:
             @"--%@\r\n"
             "Content-Disposition: form-data; name=\"%@\"\r\n"
             "\r\n"
             "%@\r\n"
             , WZZHTTPTOOLBOUNDARY, key, value];
        }
        NSData * normalData = [bodyStr dataUsingEncoding:NSUTF8StringEncoding];
        [mutiData appendData:normalData];
        
        //表单中文件
        for (int i = 0; i < formDataArr.count; i++) {
            NSMutableString * headerStr = [NSMutableString string];
            NSDictionary * dic = formDataArr[i];
            NSData * data = dic[@"data"];
            NSURL * url = dic[@"url"];
            NSString * name = dic[@"name"];
            NSString * key = dic[@"key"];
            NSString * type = dic[@"type"];
            
            //文件字符串
            NSString * file = nil;
            //数据
            if (data) {
                file = [[NSString alloc] initWithData:data encoding:NSASCIIStringEncoding];
            }
            //url
            if (url) {
                file = url.absoluteString;
            }
            
            //拼接头部数据
            [headerStr appendFormat:
             @"--%@\r\n"
             "Content-Disposition: form-data; name=\"%@\"; filename=\"%@\"\r\n"
             "Content-Type: %@\r\n"
             "\r\n"
             , WZZHTTPTOOLBOUNDARY, key, name, type];//file
            
            //拼接头部数据
            [mutiData appendData:[headerStr dataUsingEncoding:NSUTF8StringEncoding]];
            //拼接上传数据
            [mutiData appendData:data];
            //拼接尾部换行
            [mutiData appendData:[@"\r\n" dataUsingEncoding:NSUTF8StringEncoding]];
            
        }
        
        //最后拼接结尾
        if (bodyDic.count || formDataArr.count) {
            NSString * endStr = [NSString stringWithFormat:@"--%@--", WZZHTTPTOOLBOUNDARY];
            [mutiData appendData:[endStr dataUsingEncoding:NSUTF8StringEncoding]];
        }
        
        //请求体
        req.HTTPBody = mutiData;
    }
    
    //请求会话
    NSURLSession *session = [NSURLSession sessionWithConfiguration:[NSURLSessionConfiguration defaultSessionConfiguration]
                                                          delegate:[self shareInstance]
                                                     delegateQueue:[NSOperationQueue mainQueue]];
    //请求任务
    NSURLSessionDataTask *dataTask = [session dataTaskWithRequest:req completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
        NSError * err2;
        if (error) {
            if (failedBlock) {
                failedBlock(error);
            }
        } else {
            id responseObj = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableContainers error:&err2];
            if (err2) {
                if (failedBlock) {
                    failedBlock(err2);
                }
            } else {
                if (successBlock) {
                    successBlock(responseObj);
                }
            }
        }
    }];
    
    //执行任务
    [dataTask resume];
}

//MARK:GET请求
+ (void)GET:(NSString *)url
successBlock:(void(^)(id httpResponse))successBlock
failedBlock:(void(^)(NSError * httpError))failedBlock {
    [self requestWithMethod:@"GET" url:url httpHeader:nil httpBody:nil bodyType:[WZZHttpTool shareInstance].bodyType successBlock:^(id httpResponse) {
        if (successBlock) {
            successBlock(httpResponse);
        }
    } failedBlock:^(NSError *httpError) {
        if (failedBlock) {
            failedBlock(httpError);
        }
    }];
}

//MARK:POST请求
+ (void)POST:(NSString *)url
    httpBody:(NSDictionary *)bodyDic
successBlock:(void(^)(id httpResponse))successBlock
 failedBlock:(void(^)(NSError * httpError))failedBlock {
    [self requestWithMethod:@"POST" url:url httpHeader:nil httpBody:bodyDic bodyType:[WZZHttpTool shareInstance].bodyType successBlock:^(id httpResponse) {
        if (successBlock) {
            successBlock(httpResponse);
        }
    } failedBlock:^(NSError *httpError) {
        if (failedBlock) {
            failedBlock(httpError);
        }
    }];
}

//MARK:POST请求带文件
+ (void)POST:(NSString *)url
 addFormData:(void(^)(WZZPOSTFormData *))formDataBlock
    httpBody:(NSDictionary *)bodyDic
successBlock:(void(^)(id httpResponse))successBlock
 failedBlock:(void(^)(NSError * httpError))failedBlock {
    //创建请求头
    NSMutableDictionary * headerDic = [NSMutableDictionary dictionary];
    
    //表单数据
    WZZPOSTFormData * data = [[WZZPOSTFormData alloc] init];
    if (formDataBlock) {
        formDataBlock(data);
    }
    NSArray * formDataArr = data.formDataArray;
    
    [self requestWithMethod:@"POST" url:url httpHeader:headerDic httpBody:bodyDic bodyType:[WZZHttpTool shareInstance].bodyType fromFile:formDataArr successBlock:^(id httpResponse) {
        if (successBlock) {
            successBlock(httpResponse);
        }
    } failedBlock:^(NSError *httpError) {
        if (failedBlock) {
            failedBlock(httpError);
        }
    }];
}

//MARK:PUT请求
+ (void)PUT:(NSString *)url
   httpBody:(NSDictionary *)bodyDic
successBlock:(void(^)(id httpResponse))successBlock
failedBlock:(void(^)(NSError * httpError))failedBlock {
    [self requestWithMethod:@"PUT" url:url httpHeader:nil httpBody:bodyDic bodyType:[WZZHttpTool shareInstance].bodyType successBlock:^(id httpResponse) {
        if (successBlock) {
            successBlock(httpResponse);
        }
    } failedBlock:^(NSError *httpError) {
        if (failedBlock) {
            failedBlock(httpError);
        }
    }];
}

//MARK:DELETE请求
+ (void)DELETE:(NSString *)url
      httpBody:(NSDictionary *)bodyDic
  successBlock:(void(^)(id httpResponse))successBlock
   failedBlock:(void(^)(NSError * httpError))failedBlock {
    [self requestWithMethod:@"DELETE" url:url httpHeader:nil httpBody:bodyDic bodyType:[WZZHttpTool shareInstance].bodyType successBlock:^(id httpResponse) {
        if (successBlock) {
            successBlock(httpResponse);
        }
    } failedBlock:^(NSError *httpError) {
        if (failedBlock) {
            failedBlock(httpError);
        }
    }];
}

#pragma mark - 工具
//MARK:json字符串转对象
+ (id)jsonToObject:(NSString *)jsonString {
    if (jsonString == nil) {
        return nil;
    }
    NSData *jsonData = [jsonString dataUsingEncoding:NSUTF8StringEncoding];
    NSError *err;
    id object = [NSJSONSerialization JSONObjectWithData:jsonData options:NSJSONReadingMutableContainers error:&err];
    if(err) {
        NSLog(@"json解析失败：%@",err);
        return nil;
    }
    return object;
}

//MARK:对象转json字符串
+ (NSString *)objectToJson:(id)object {
    if (object == nil) {
        return nil;
    }
    NSError * err = nil;
    NSData * data = [NSJSONSerialization dataWithJSONObject:object options:0 error:&err];
    if(err) {
        NSLog(@"json解析失败：%@",err);
        return nil;
    }
    return [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
}

#pragma mark - NSURLSessionDataDelegate
//只要请求的地址是HTTPS的, 就会调用这个代理方法
//challenge:质询
//NSURLAuthenticationMethodServerTrust:服务器信任
//MARK:https代理
- (void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task didReceiveChallenge:(NSURLAuthenticationChallenge *)challenge completionHandler:(void (^)(NSURLSessionAuthChallengeDisposition, NSURLCredential * _Nullable))completionHandler
{
    if (![challenge.protectionSpace.authenticationMethod isEqualToString:@"NSURLAuthenticationMethodServerTrust"]) return;
    /*
     NSURLSessionAuthChallengeUseCredential 使用证书
     NSURLSessionAuthChallengePerformDefaultHandling  忽略证书 默认的做法
     NSURLSessionAuthChallengeCancelAuthenticationChallenge 取消请求,忽略证书
     NSURLSessionAuthChallengeRejectProtectionSpace 拒绝,忽略证书
     */
    
    NSURLCredential *credential = [NSURLCredential credentialForTrust:challenge.protectionSpace.serverTrust];
    
    completionHandler(NSURLSessionAuthChallengeUseCredential,credential);
}

@end

#pragma mark - 表单数据
@interface WZZPOSTFormData ()
{
    NSMutableArray * _dataArr;
}

@end

@implementation WZZPOSTFormData

- (instancetype)init
{
    self = [super init];
    if (self) {
        _dataArr = [NSMutableArray array];
        _formDataArray = [NSArray arrayWithArray:_dataArr];
    }
    return self;
}

#pragma mark - 添加表单数据
- (void)addData:(NSData *)data
            key:(NSString *)key
           type:(WZZHttpTool_FormDataType)type {
    NSString * typeName = nil;
    NSString * fileName = nil;
    switch (type) {
        case WZZHttpTool_FormDataType_ImageJPG:
        {
            typeName = @"image/jpeg";
            fileName = @"fileName.jpg";
        }
            break;
        case WZZHttpTool_FormDataType_ImagePNG:
        {
            typeName = @"image/png";
            fileName = @"fileName.png";
        }
            break;
            
        default:
        {
            //如果是其他类型，直接return
            return;
        }
            break;
    }
    [self addData:data key:key fileName:fileName type:typeName];
}

- (void)addUrl:(NSURL *)url
           key:(NSString *)key
          type:(WZZHttpTool_FormDataType)type {
    NSString * typeName = nil;
    NSString * fileName = nil;
    switch (type) {
        case WZZHttpTool_FormDataType_ImageJPG:
        {
            typeName = @"image/jpeg";
            fileName = @"fileName.jpg";
        }
            break;
        case WZZHttpTool_FormDataType_ImagePNG:
        {
            typeName = @"image/png";
            fileName = @"fileName.png";
        }
            break;
            
        default:
        {
            //如果是其他类型，直接return
            return;
        }
            break;
    }
    [self addUrl:url key:key fileName:fileName type:typeName];
}

- (void)addData:(NSData *)data
            key:(NSString *)key
       fileName:(NSString *)fileName
           type:(NSString *)type {
    //数据为空
    if (!data.length) {
        NSLog(@"wzzhttptool:formdata数据为空");
        return;
    }
    
    //键格式有问题
    if (!key || ![key isKindOfClass:[NSString class]] || [key isEqualToString:@""]) {
        NSLog(@"wzzhttptool:键格式有问题");
        return;
    }
    
    //文件名格式有问题
    if (!fileName || ![fileName isKindOfClass:[NSString class]] || [fileName isEqualToString:@""]) {
        NSLog(@"wzzhttptool:文件名格式有问题");
        return;
    }
    
    //文件类型格式有问题
    if (!type || ![type isKindOfClass:[NSString class]] || [type isEqualToString:@""]) {
        NSLog(@"wzzhttptool:文件类型格式有问题");
        return;
    }
    
    //添加数据
    [_dataArr addObject:@{
                              @"data":data,
                              @"name":fileName,
                              @"type":type,
                              @"key":key
                              }];
    _formDataArray = [NSArray arrayWithArray:_dataArr];
}

- (void)addUrl:(NSURL *)url
           key:(NSString *)key
      fileName:(NSString *)fileName
          type:(NSString *)type {
    //数据为空
    if (!url.absoluteString.length) {
        NSLog(@"wzzhttptool:formurl为空");
        return;
    }
    
    //键格式有问题
    if (!key || ![key isKindOfClass:[NSString class]] || [key isEqualToString:@""]) {
        NSLog(@"wzzhttptool:键格式有问题");
        return;
    }
    
    //文件名格式有问题
    if (!fileName || ![fileName isKindOfClass:[NSString class]] || [fileName isEqualToString:@""]) {
        NSLog(@"wzzhttptool:文件名格式有问题");
        return;
    }
    
    //文件类型格式有问题
    if (!type || ![type isKindOfClass:[NSString class]] || [type isEqualToString:@""]) {
        NSLog(@"wzzhttptool:文件类型格式有问题");
        return;
    }
    
    //添加数据
    [_dataArr addObject:@{
                              @"url":url,
                              @"name":fileName,
                              @"type":type,
                              @"key":key
                              }];
    _formDataArray = [NSArray arrayWithArray:_dataArr];
}

@end
