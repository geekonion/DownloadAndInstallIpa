//
//  DownloadDelegateHandler.m
//  DemoDownload
//
//  Created by yingxin ye on 2017/5/4.
//  Copyright © 2017年 yingxin ye. All rights reserved.
//

#import "DownloadDelegateHandler.h"
#import "DownloadManager.h"

@interface DownloadDelegateHandler()
@property (nonatomic, strong) NSOutputStream * stream; //下载流
@property (nonatomic, strong) OneDownloadItem * item;

@end

@implementation DownloadDelegateHandler {
    __weak DownloadManager *_downloadManager;
}

- (instancetype)initWithItem:(OneDownloadItem *)item {
    self = [super init];
    if (self) {
        self.item = item;
        _downloadManager = [DownloadManager manager];
    }
    return self;
}

//服务器响应以后调用的代理方法
- (void)URLSession:(NSURLSession *)session dataTask:(NSURLSessionDataTask *)dataTask didReceiveResponse:(NSHTTPURLResponse *)response completionHandler:(void (^)(NSURLSessionResponseDisposition))completionHandler {
    NSInteger statusCode = response.statusCode;
    if (statusCode < 200 || statusCode >= 300 ) {
        NSLog(@"下载%@失败，错误的响应：%@", dataTask.originalRequest.URL, response);
        completionHandler(NSURLSessionResponseAllow);
        return;
    }
    //接受到服务器响应
    //获取文件的全部长度
    NSLog(@"开始下载----Content-Length = %li",[response.allHeaderFields[@"Content-Length"] integerValue]);
    
    _item.totalBytesWritten = [response.allHeaderFields[@"Content-Length"] integerValue] + _item.currentBytesWritten;

    //保存当前的下载信息到沙盒
    [_downloadManager updateModel:_item andStatus:DownloadStatusDownloading];

    //打开outputStream
    [self.stream scheduleInRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
    [_stream open];
    
    //调用block设置允许进一步访问
    completionHandler(NSURLSessionResponseAllow);
}
//接收到数据后调用的代理方法
- (void)URLSession:(NSURLSession *)session dataTask:(NSURLSessionDataTask *)dataTask didReceiveData:(NSData *)data
{
    //把服务器传回的数据用stream写入沙盒中
    NSInteger len = data.length;
    [_stream write:data.bytes maxLength:len];
    _item.currentBytesWritten += len;

    float progress = 1.0 * _item.currentBytesWritten / _item.totalBytesWritten;
    _item.taskProgress = progress;

    //保存当前的下载信息到沙盒并刷新界面 回调界面现在的下载进度
    [_downloadManager updateProgress];

    NSLog(@"name: %@, progress: %.2f%%", _item.name, 100.0 * progress);
}
//任务完成后调用的代理方法
- (void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task didCompleteWithError:(NSError *)error {
    if (error) {
        //暂停
        return;
    } else {
        NSLog(@"下载完成-----没有错误");
        //保存当前的下载信息的沙盒 并回调界面完成
        [_downloadManager updateModel:_item andStatus:DownloadStatusComplete];
        //回调告诉manager完成
        [_downloadManager callbackDownloadComplete:_item];
    }

    //关闭流
    [_stream close];
    _stream = nil;
    //清空task
    [session invalidateAndCancel];
    task = nil;
    session = nil;
}


- (NSOutputStream *)stream {
    if (!_stream) {
        
        _stream = [[NSOutputStream alloc]initToFileAtPath:[[DownloadManager manager] getFilePath:_item.name] append:YES];
    }
    return _stream;
}


- (void)dealloc {
    NSLog(@"---DownloadDelegateHandler---dealloc");
}

@end
