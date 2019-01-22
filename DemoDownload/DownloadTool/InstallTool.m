//
//  InstallTool.m
//  DemoDownload
//
//  Created by xuyanjun on 2019/1/22.
//  Copyright © 2019 yingxin ye. All rights reserved.
//

#import "InstallTool.h"
#import "OneDownloadItem.h"
#import <UIKit/UIKit.h>

@implementation InstallTool

+ (void)installItem:(OneDownloadItem *)item {
    NSString * plistStr = [NSString stringWithFormat:@"itms-services://?action=download-manifest&url=%@", item.plistUrl];
    [[UIApplication sharedApplication] openURL:[NSURL URLWithString:plistStr]];
    NSLog(@"安装plistStr======%@",plistStr);
}

@end
