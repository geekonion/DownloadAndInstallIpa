//
//  DownloadManager.m
//  DemoDownload
//
//  Created by yingxin ye on 2017/5/2.
//  Copyright © 2017年 yingxin ye. All rights reserved.
//

#import "DownloadManager.h"
#import <UIKit/UIKit.h>
#import "HTTPServer.h"
#define MAX_DOWNLOAD_NUM 3 //最多下载并行数

@interface DownloadManager()

@property (nonatomic, strong) HTTPServer * httpServer;
@property (nonatomic) UIBackgroundTaskIdentifier backgroundIdentify;

@end


@implementation DownloadManager


static DownloadManager *_dataCenter = nil;
+ (DownloadManager *)manager {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _dataCenter = [[DownloadManager alloc] init];
    });
    
    return _dataCenter;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        //开始本地服务器
        [self httpServer];
        //获取之前保存的下载项 数组
        self.allItemArray = [self loadFromUnarchiver];
        self.backgroundIdentify = UIBackgroundTaskInvalid;
        self.backgroundIdentify = [[UIApplication sharedApplication] beginBackgroundTaskWithExpirationHandler:^
                                   {
                                       //当时间快结束时，该方法会被调用。
                                       NSLog(@"Background handler called. Not running background tasks anymore.");
                                       
                                       [[UIApplication sharedApplication] endBackgroundTask:self.backgroundIdentify];
                                       
                                       self.backgroundIdentify = UIBackgroundTaskInvalid;
                                   }];
        
        //当进入时，之前队列存在的下载项所有都设置 状态暂停
        for (OneDownloadItem * item in self.allItemArray) {
            if (item.downloadStatus != DownloadStatusComplete) { //未完成的，都先暂停
                item.downloadStatus = DownloadStatusPause;
            }
        }
    }
    return self;
}

// 添加任务到任务列表中
- (void)addDownloadTaskWithUrl:(NSString *)urlString plistUrl:(NSString *)plistUrl name:(NSString *)name type:(NSString *)type {
    if (!name || !urlString || !type || !plistUrl) {
        NSLog(@"-----缺少参数-----");
        return;
    }
    
    // 防止任务重复添加
    NSArray *urls = [_allItemArray valueForKey:@"urlString"];
    if ([urls containsObject:urlString]) {
        NSLog(@"任务重复");
        return;
    }
    
    OneDownloadItem * oneDownloadItem = [[OneDownloadItem alloc] initWithUrl:urlString plistUrl:plistUrl name:name type:type];
    [_allItemArray addObject:oneDownloadItem];      //先添加
    [self startDownload:oneDownloadItem];               //再下载
}

//开始下载
- (void)startDownload:(OneDownloadItem *)item {
    item.downloadStatus = DownloadStatusWaiting;
    [self updateProcessList];
}

//暂停下载
- (void)pauseDownload:(OneDownloadItem *)item {
    item.downloadStatus = DownloadStatusPause;
    [self updateProcessList];
}

//完成下载
- (void)callbackDownloadComplete:(OneDownloadItem *)item {
    dispatch_async(dispatch_get_main_queue(), ^{
        [self updateProcessList];           //进行下一个队列
        if (_completeBlock) _completeBlock(item);
    });
}

//处理队列
- (void)updateProcessList {
    //先处理所有的暂停操作
    for (OneDownloadItem * oneItem in _allItemArray) {
        if (oneItem.downloadStatus == DownloadStatusPause) {
            [oneItem pause];
        }
    }
    
    //当前下载数 小于 下载总数的 才处理
    for (OneDownloadItem * item in _allItemArray) {
        int nowDowningInt = [self nowDowningNum];
        if (nowDowningInt < MAX_DOWNLOAD_NUM) {
            if (item.downloadStatus == DownloadStatusWaiting) {
                [item start];
                nowDowningInt ++;
            }
        }
    }
}

- (int)nowDowningNum {
    int tempNow = 0;
    for (OneDownloadItem * oneItem in _allItemArray) {
        if (oneItem.downloadStatus == DownloadStatusDownloading) {
            tempNow ++;
        }
    }
    return tempNow;
}

//删除一个下载项
- (void)removeItem:(OneDownloadItem *)item {
    [self pauseDownload:item];       //先暂停
    [_allItemArray removeObject:item];   //总数组删除这个元素
    [self deleteFile:item.saveName];         //删除对应的文件
    [self saveArchiverAndUpdateUI];             //保存刷新界面
    [self updateProgress];
}

/**文件存放路径*/
- (NSString *)getFilePath:(NSString *)saveName {
    return [self.storagePath stringByAppendingPathComponent:saveName];
}

//删除沙盒文件
- (void)deleteFile:(NSString *)fileName {
    NSString * delPath = [self getFilePath:fileName];
    NSFileManager *fileManager = [NSFileManager defaultManager];
    BOOL exists = [fileManager fileExistsAtPath:delPath];
    if (!exists) {
        NSLog(@"no have file");
        return;
    } else {
        BOOL res = [fileManager removeItemAtPath:delPath error:nil];
        if (res) {
            NSLog(@"del success");
        } else {
            NSLog(@"del fail");
        }
    }
}


/**已经下载的文件长度*/
- (NSInteger)getAlreadyDownloadLength:(NSString *)saveName {
    return [[[NSFileManager defaultManager] attributesOfItemAtPath:[self getFilePath:saveName] error:nil][NSFileSize] integerValue];
}


/**文件总长度字典存放的路径*/
- (NSString *)getAllItemArrayPath {
    return [self.storagePath stringByAppendingPathComponent:@"allItemArray.data"];
}

//更新下载项的状态，并保存和更新界面
- (void)updateModel:(OneDownloadItem *)item andStatus:(DownloadStatus)downloadStatus {
    item.downloadStatus = downloadStatus;
    [self saveArchiverAndUpdateUI];
    
    dispatch_async(dispatch_get_main_queue(), ^{
        if (_progressBlock) _progressBlock(self.allItemArray);  //回调界面
    });
}

//所有下载item归档
- (void)saveArchiverAndUpdateUI {
    [NSKeyedArchiver archiveRootObject:self.allItemArray toFile:[self getAllItemArrayPath]];
}

- (void)updateProgress {
    dispatch_async(dispatch_get_main_queue(), ^{
        if (_progressBlock) _progressBlock(self.allItemArray);  //回调界面
    });
}

//反归档
- (NSMutableArray*)loadFromUnarchiver {
    NSMutableArray * decodedArray = [NSKeyedUnarchiver unarchiveObjectWithFile:[self getAllItemArrayPath]];
    if (!decodedArray) {
        decodedArray = [NSMutableArray array];
    }
    return decodedArray;
}


- (HTTPServer *)httpServer {
    if (!_httpServer) {
        _httpServer      = [HTTPServer new];
        _httpServer.type = @"_http._tcp.";
        _httpServer.port = 10001;
        _httpServer.documentRoot = self.storagePath;
        [_httpServer start:nil];
    }
    return _httpServer;
}

- (NSString *)storagePath {
    if (!_storagePath) {
        NSString *cachePath = NSSearchPathForDirectoriesInDomains(NSCachesDirectory,NSUserDomainMask,YES).firstObject;
        NSString *ipaPath = [cachePath stringByAppendingPathComponent:@"UUIPAToInstall"];
        
        NSFileManager *fileManager = [NSFileManager defaultManager];
        BOOL isDirectory = NO;
        BOOL exists = [fileManager fileExistsAtPath:ipaPath isDirectory:&isDirectory];
        if (!exists) {
            NSError *error = nil;
            [fileManager createDirectoryAtPath:ipaPath withIntermediateDirectories:YES attributes:nil error:&error];
            if (error) {
                NSLog(@"创建目录失败 %@", error);
                _storagePath = cachePath;
            } else {
                _storagePath = ipaPath;
            }
        } else {
            if (!isDirectory) {
                NSLog(@"存在同名文件，不能创建目录！！！");
                _storagePath = cachePath;
            } else {
                _storagePath = ipaPath;
            }
        }
    }
    
    return _storagePath;
}

@end
