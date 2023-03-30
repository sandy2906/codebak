//
//  WeixinManager.m
//  DianShangApp
//
//  Created by kangnaonao on 2019/11/13.
//  Copyright © 2019 Facebook. All rights reserved.
//
#import <UIKit/UIKit.h>
#import "WeixinManager.h"
#import "HWCircleView.h"
#import "SVProgressHUD.h"
NSTimer *timer;
 HWCircleView *circleView;

#define APP_ID @"wxa06c5441d3f73bfb"

RCTPromiseResolveBlock resolveBlock = nil;

@implementation WeixinManager
RCT_EXPORT_MODULE();

- (instancetype)init
{
  self = [super init];
  if (self) {
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleWXPay:) name:@"WXPay" object:nil];
  }
  return self;
}

- (void)dealloc
{
  [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)handleWXPay:(NSNotification *)aNotification
{
  NSString * errCode =  [aNotification userInfo][@"errCode"];
  resolveBlock(@{@"errCode": errCode});
}

RCT_EXPORT_METHOD(registerApp){
  [WXApi registerApp:APP_ID
       universalLink:@"https://demo.xt-kp.com/"];//向微信注册
}

RCT_EXPORT_METHOD(pay:(NSDictionary *)order
                  resolver:(RCTPromiseResolveBlock)resolve
                  rejecter:(RCTPromiseRejectBlock)reject)
{
  resolveBlock = resolve;
  //调起微信支付
  PayReq *req = [[PayReq alloc] init];
  req.partnerId = [order objectForKey:@"partnerId"];
  req.prepayId = [order objectForKey:@"prepayId"];
  req.nonceStr = [order objectForKey:@"nonceStr"];
  req.timeStamp = [[order objectForKey:@"timeStamp"] intValue];
  req.package = @"Sign=WXPay";
  req.sign = [order objectForKey:@"sign"];
  [WXApi sendReq:req completion:nil];
}

RCT_REMAP_METHOD(isSupported, // 判断是否支持调用微信SDK
                 resolver:(RCTPromiseResolveBlock)resolve
                 rejecter:(RCTPromiseRejectBlock)reject){
  dispatch_sync(dispatch_get_main_queue(), ^{
    if (![WXApi isWXAppInstalled])
    {
          resolve(@NO);
    }
    else{
          resolve(@YES);
    }
  });
}

RCT_EXPORT_METHOD(miniProgramShare:(NSDictionary *)order)
{
  NSString *urlStr = [order objectForKey:@"imageUrl"];
  NSURL * url = [NSURL URLWithString:urlStr];
  NSData *syData = [NSData dataWithContentsOfURL:url];
  
  if (syData) {
    WXMiniProgramObject *object = [WXMiniProgramObject object];
    object.webpageUrl = @"http://www.qq.com";
    object.userName = [order objectForKey:@"userName"];
    object.path = [order objectForKey:@"path"];
    object.hdImageData = syData;//需将图片下载下来
    object.miniProgramType = 0;// 正式版:0，测试版:1，体验版:2
    
    WXMediaMessage *message = [WXMediaMessage message];
    message.title = [order objectForKey:@"title"];
    message.description = [order objectForKey:@"title"];
    message.thumbData = nil;  //兼容旧版本节点的图片，小于32KB，新版本优先
    //使用WXMiniProgramObject的hdImageData属性
    message.mediaObject = object;
    
    SendMessageToWXReq *req = [[SendMessageToWXReq alloc] init];
    req.bText = NO;
    req.message = message;
    req.scene = WXSceneSession;  //目前只支持会话
    [WXApi sendReq:req completion:nil];
  }
}

RCT_EXPORT_METHOD(shareToWechat:(NSString *)pdfurl type:(NSString *)pdfname)
{
  //文件数据
  [SVProgressHUD setDefaultStyle:SVProgressHUDStyleDark];
  [SVProgressHUD showWithStatus:@"正在下载体检报告..."];
  WXFileObject *fileObj = [WXFileObject object];
  NSData *data = [NSData dataWithContentsOfURL:[NSURL URLWithString:pdfurl]];
  NSFileManager *fileManage = [NSFileManager defaultManager];
  NSString *tmp = [NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) lastObject];
  tmp =[tmp stringByAppendingPathComponent:pdfname];
  BOOL isSuccess = [fileManage createFileAtPath:tmp contents:data attributes:nil];
  NSString *filePath = tmp;
  fileObj.fileData = [NSData dataWithContentsOfFile:filePath];
  [SVProgressHUD dismiss];
  //多媒体消息
  fileObj.fileExtension = @"pdf";
  WXMediaMessage *wxMediaMessage = [WXMediaMessage message];
  wxMediaMessage.title = [pdfname stringByAppendingString: @".pdf"];
  wxMediaMessage.description = @"描述";
  [wxMediaMessage setThumbImage:[UIImage imageNamed:@"80.png"]];
  wxMediaMessage.mediaObject = fileObj;
  wxMediaMessage.messageExt = @"pdf";
  //发送消息
  SendMessageToWXReq *req = [[SendMessageToWXReq alloc] init];
  req.message = wxMediaMessage;
  req.bText = NO;
  req.scene = WXSceneSession;
  [WXApi sendReq:req completion:nil];
}


//        NSURL *relativeToURL = [NSURL URLWithString:m.url ];//必须先下载，否则无法查看文件内容


//RCT_EXPORT_METHOD(shareToWechat:(NSString *)base64 type:(NSString *)type)
//{
//  NSData *imageData = [[NSData alloc] initWithBase64EncodedString:base64 options:NSDataBase64DecodingIgnoreUnknownCharacters];
//  UIImage *image = [UIImage imageWithData:imageData];
//  imageData = UIImageJPEGRepresentation(image, 1.0f);
//
//  WXImageObject *imageObject = [WXImageObject object];
//  imageObject.imageData = imageData;
//
//  WXMediaMessage *message = [WXMediaMessage message];
////  NSString *filePath = [[NSBundle mainBundle] pathForResource:@"res5"
////                                                       ofType:@"jpg"];
////  message.thumbData = [NSData dataWithContentsOfFile:filePath];
//  message.mediaObject = imageObject;
//
//  SendMessageToWXReq *req = [[SendMessageToWXReq alloc] init];
//  req.bText = NO;
//  req.message = message;
//  req.scene = [type isEqualToString:@"1"]?WXSceneSession:WXSceneTimeline;
//  [WXApi sendReq:req completion:nil];
//}


+ (BOOL)requiresMainQueueSetup
{

  return YES;

}
@end
