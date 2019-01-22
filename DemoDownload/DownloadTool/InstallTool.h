//
//  InstallTool.h
//  DemoDownload
//
//  Created by xuyanjun on 2019/1/22.
//  Copyright © 2019 yingxin ye. All rights reserved.
//

#import <Foundation/Foundation.h>
@class OneDownloadItem;
NS_ASSUME_NONNULL_BEGIN

@interface InstallTool : NSObject
+ (void)installItem:(OneDownloadItem *)item;
@end

NS_ASSUME_NONNULL_END
