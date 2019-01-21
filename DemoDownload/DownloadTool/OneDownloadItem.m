//
//  OneDownloadItem.m
//  DemoDownload
//
//  Created by yingxin ye on 2017/5/2.
//  Copyright © 2017年 yingxin ye. All rights reserved.
//

#import "OneDownloadItem.h"
#import <UIKit/UIKit.h>
#import "DownloadManager.h"
#import "MJExtension.h"
#import "DownloadDelegateHandler.h"


@interface OneDownloadItem() {
    NSURLSession * _session;
    NSURLSessionDataTask * _task;
    NSMutableURLRequest * _mutableRequest;
    __weak DownloadManager *_downloadManager;
}

@end

@implementation OneDownloadItem

MJCodingImplementation

- (OneDownloadItem * )initWithUrl:(NSString *)url plistUrl:(NSString *)plistUrl gameName:(NSString *)gameName gameId:(NSString *)gameId type:(NSString *)type {
    if (self = [super init]) {
        _downloadManager = [DownloadManager manager];
        self.gameName = gameName;
        self.gameId = gameId;
        self.type = type;
        self.urlString = url;
        self.plistUrl = plistUrl;
        self.taskProgress = 0.0f;
        self.isFinish = NO;
        self.currentBytesWritten = 0;
        self.totalBytesWritten = 0;
        self.taskDate = [NSDate date];
        self.taskSpeed = @"0kb/s";
        self.taskSize = @"0M";
        self.saveName = [NSString stringWithFormat:@"%@.%@", self.gameId, self.type];
    }
    
    return self;
}


- (void)creatTask {
    //获取已下载的文件大小
    NSInteger alreadyDownloadLength = [_downloadManager getAlreadyDownloadLength:self.saveName];
    
    DownloadDelegateHandler * delegateHandler = [[DownloadDelegateHandler alloc] initWithItem:self];
    _session = [NSURLSession sessionWithConfiguration:[NSURLSessionConfiguration defaultSessionConfiguration] delegate:delegateHandler delegateQueue:nil];
    
    //这里是已经下载的小于总文件大小执行继续下载操作
    //创建mutableRequest对象
    _mutableRequest = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:self.urlString]];
    //设置request的请求头 Range:bytes=xxx-xxx
    [_mutableRequest setValue:[NSString stringWithFormat:@"bytes=%ld-",(long)alreadyDownloadLength] forHTTPHeaderField:@"Range"];
    _task = [_session dataTaskWithRequest:_mutableRequest];
}


- (void)start {
    NSError *error = nil;
    //获取已下载的文件大小
    NSInteger downloadedLen = [_downloadManager getAlreadyDownloadLength:self.saveName];
    
    //说明已经下载完毕
    if (downloadedLen && downloadedLen == self.totalBytesWritten) {
        //回调
        NSLog(@"finish");
        [_downloadManager updateModel:self andStatus:DownloadStatusComplete];
        return;
    }
    //如果已经存在的文件比目标大说明下载文件错误执行删除文件重新下载
    else if (self.totalBytesWritten < downloadedLen) {
        [[NSFileManager defaultManager] removeItemAtPath:[_downloadManager getFilePath:self.saveName] error:&error];
        if (!error) {
            downloadedLen = 0;
        } else {
            NSLog(@"创建任务失败请重新开始");
            //删除文件
            return;
        }
    }
    
    [_downloadManager updateModel:self andStatus:DownloadStatusDownloading];
    if (!_task) [self creatTask];
    [_task resume];
}

- (void)pause {
    [_task cancel];
    [_session invalidateAndCancel];
    _session = nil;
    _task = nil;
    [_downloadManager updateModel:self andStatus:DownloadStatusPause];
}


- (void)dealloc {
    NSLog(@"---OneDownloadItem---dealloc");
}


@end
