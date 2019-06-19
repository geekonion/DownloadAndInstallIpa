//
//  ViewController.m
//  DemoDownload
//
//  Created by yingxin ye on 2017/4/25.
//  Copyright © 2017年 yingxin ye. All rights reserved.
//

#import "ViewController.h"
#import "DownloadManager.h"
#import "OneDownloadItem.h"
#import "DownloadCell.h"
#import "InstallTool.h"

@interface ViewController () <UITableViewDelegate, UITableViewDataSource>
@property (nonatomic, strong) UITableView * tableView;
@property (atomic, strong) NSArray * allItemModelArr;
@end

@implementation ViewController {
    DownloadManager *_downloadManager;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    _downloadManager = [DownloadManager manager];
    self.allItemModelArr = _downloadManager.allItemArray;
    
    UIButton * downBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    downBtn.frame = CGRectMake(10, 30, 80, 30);
    [downBtn setTitle:@"安装应用" forState:UIControlStateNormal];
    downBtn.backgroundColor = [UIColor redColor];
    [downBtn addTarget:self action:@selector(downloadHanlder:) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:downBtn];
    
    UIButton * mdmBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    mdmBtn.frame = CGRectMake(100, 30, 80, 30);
    [mdmBtn setTitle:@"安装mdm" forState:UIControlStateNormal];
    mdmBtn.backgroundColor = [UIColor redColor];
    [mdmBtn addTarget:self action:@selector(installMdm:) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:mdmBtn];

    [self.view addSubview:self.tableView];
    
    //下载过程中，数据源刷新，表格刷新
    typeof(self) __weak weakSelf = self;
    _downloadManager.progressBlock = ^(NSArray *allModelArr) {
        weakSelf.allItemModelArr = allModelArr;
        [weakSelf.tableView reloadData];
    };
    
    //下载完成自动安装，可以不选择自动安装
    _downloadManager.completeBlock = ^(OneDownloadItem *item) {
        [InstallTool installItem:item];
    };
}

//下载这些地址只是测试
//把下面的下载ipa地址和plist地址都改成你们自己的地址
- (void)downloadHanlder:(UIButton*)btn {
    NSString *ipa = @"https://raw.githubusercontent.com/gaopc/installApp/master/SecMail.ipa";
    NSString *plist = @"https://raw.githubusercontent.com/gaopc/installApp/master/uusafe.plist";
    [_downloadManager addDownloadTaskWithUrl:ipa plistUrl:plist name:@"SecMail.ipa"];
}

//安装证书，
- (void)installMdm:(UIButton *)btn {
    //相同PayloadIdentifier可以覆盖，描述文件移除密码RemovalPassword字段
    //mobileconfig可以用Apple configurator 2生成，也可以根据策略动态生成
    NSString *urlStr = [NSString stringWithFormat:@"http://127.0.0.1:%d/MDM.mobileconfig", [_downloadManager listeningPort]];
    NSURL *url = [NSURL URLWithString:urlStr];
    [[UIApplication sharedApplication] openURL:url options:@{} completionHandler:nil];
}

- (UITableView *)tableView {
    if (!_tableView) {
        _tableView = [[UITableView alloc]initWithFrame:CGRectMake(0, 100, self.view.bounds.size.width, self.view.bounds.size.height-100) style:UITableViewStylePlain];
        
        _tableView.dataSource = self;
        _tableView.delegate = self;
    }
    return _tableView;
}


#pragma mark 一共有多少组
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

#pragma mark 一共有多少行
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.allItemModelArr.count;
}

#pragma mark 每个组的高度
- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    return 20;
}


#pragma mark 每个表格的高度
- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return 50;
}

#pragma mark 每个表格
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    NSString *CellIdentifier= NSStringFromClass([DownloadCell class]);
    
    DownloadCell * cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[DownloadCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
    }
    
    OneDownloadItem * data = [self.allItemModelArr objectAtIndex:indexPath.row];
    [cell updateCell:data];
    
    return cell;
}


- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        OneDownloadItem * delItem = [self.allItemModelArr objectAtIndex:indexPath.row];
        [[DownloadManager manager] removeItem:delItem];
    }
    
}

@end
