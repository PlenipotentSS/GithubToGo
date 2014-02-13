//
//  SSFolderVC.m
//  GithubToGo
//
//  Created by Stevenson on 2/13/14.
//  Copyright (c) 2014 The 2 Handed Consortium. All rights reserved.
//

#import "SSFolderVC.h"
#import <RATreeView/RATreeView.h>
#import "YSGithubNetworkController.h"

@interface SSFolderVC () <YSGitHubControllerDelegate>
@property (weak, nonatomic) IBOutlet RATreeView *RATreeView;
@property (nonatomic) NSMutableArray *files;

@end

@implementation SSFolderVC

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view.
}

-(void) setDetailItem:(NSString *)detailItem
{
    [[YSGithubNetworkController sharedNetworkController] getTreeForRepo:(Repo*)detailItem];
    [[YSGithubNetworkController sharedNetworkController] setDelegate:self];
}

-(void)didGetContents: (NSArray *) JSONDict;
{
    for (
    NSString *type = [JSONDict objectForKey:@"type"];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
