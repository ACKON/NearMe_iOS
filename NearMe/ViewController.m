//
//  ViewController.m
//  NearMe
//
//  Created by Hayden on 2014. 10. 29..
//  Copyright (c) 2014년 OliveStory. All rights reserved.
//

#import "ViewController.h"
#import <Ackon/Ackon.h>
@interface ViewController ()<ACKAckonManagerDelegate>
@property (nonatomic, strong) ACKAckon *ackon;
@property (nonatomic, strong) ACKAckonManager *ackonManager;
@property (nonatomic, strong) NSMutableSet *ackons;
@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.ackons = [NSMutableSet new];

    //_ackonManager 를 초기화 할때 Ackon 서버 도메인과 serviceIdentifer값을 넣어 초기화 해줍니다.
    //서드파티서버를 따로 구성하지 않았을 경우 initWithServiceIdentifier: 로 초기화 해줍니다.
    _ackonManager = [[ACKAckonManager alloc] initWithServerURL:[NSURL URLWithString:@"http://cms.ackon.co.kr/"] serviceIdentifier:@"SBA14100002"];
    self.ackonManager.delegate = self;
    //유저의 위치정보 수집 동의 후 서버에 유저 등록을 합니다.
    //유저등록은 최초에만 필수 이며 초기화 이후 필요하지 않습니다.
    [self.ackonManager requestEnabled:^(BOOL success, NSError *error) {
        if(success){
            [self.ackonManager allAckonWithCompletionBlock:^(NSError *error, NSArray *result) {
                [self.ackonManager startRanging];//Ranging을 시작합니다.
            }];
            
        }else{//실패시 알림
            [[[UIAlertView alloc] initWithTitle:@"실패" message:error.description delegate:nil cancelButtonTitle:@"확인" otherButtonTitles:nil] show];
        }
    }];
    NSTimer *timer = [NSTimer scheduledTimerWithTimeInterval:1 target:self selector:@selector(checkNearAckon:) userInfo:nil repeats:YES];
    [timer fire];
}
- (void)checkNearAckon:(id)sender{
    ACKAckon *nearAckon = nil;
    for(ACKAckon *ackon in self.ackons){
        if(ackon.proximity == CLProximityUnknown){//거리를 알수 없을경우 accuracy가 -1로 나와요
            continue;
        }
        if(nearAckon==nil){
            nearAckon = ackon;
        }else{
            if(nearAckon.accuracy > ackon.accuracy){//거리 비교
                nearAckon = ackon;
            }
        }
    }
    NSIndexSet *targetIndexSet = [NSIndexSet indexSetWithIndexesInRange:NSMakeRange(0, 2)];
    if(self.ackon!=nearAckon){//데이터 변환시 에니메이션 시작
        [self.tableView beginUpdates];
        if(nearAckon==nil){//비콘이 잡힌게 없을시 삭제 에니메이션
            [self.tableView deleteSections:targetIndexSet withRowAnimation:UITableViewRowAnimationFade];
        }else if(self.ackon==nil){//기존이 없다면 추가 에니메이션
            [self.tableView insertSections:targetIndexSet withRowAnimation:UITableViewRowAnimationFade];
        }else{//대체시 리로드에니메이션
            [self.tableView reloadSections:targetIndexSet withRowAnimation:UITableViewRowAnimationFade];
        }
        self.ackon = nearAckon;
        [self.tableView endUpdates];
        
        //바뀌었다는걸 좀 육안으로 확실히 알수 있도록 배경색 에니메이션
        [UIView animateWithDuration:0.3f animations:^{
            self.view.backgroundColor = [UIColor lightGrayColor];
        } completion:^(BOOL finished) {
            if(finished){
                [UIView animateWithDuration:0.3f animations:^{
                    self.view.backgroundColor = [UIColor whiteColor];
                } completion:^(BOOL finished) {
                    nil;
                }];
            }
        }];
    }
    //수신됬던 비콘들을 비웁니다.
    [self.ackons removeAllObjects];
}
#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return self.ackon?2:0;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if(section==0){
        return 4;
    }else if(section==1){
        return self.ackon.actions.allKeys.count;
    }
    return 0;
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"Cell" forIndexPath:indexPath];
    cell.textLabel.text = nil;
    cell.detailTextLabel.text = nil;
    if(indexPath.section==0){
        if(indexPath.row==0){
            cell.textLabel.text = @"Name";
            cell.detailTextLabel.text = self.ackon.name;
        }else if(indexPath.row==1){
            cell.textLabel.text = @"UUID";
            cell.detailTextLabel.text = self.ackon.proximityUUID.UUIDString;
        }else if(indexPath.row==2){
            cell.textLabel.text = @"Major";
            cell.detailTextLabel.text = [self.ackon.major stringValue];
        }else if(indexPath.row==3){
            cell.textLabel.text = @"Minor";
            cell.detailTextLabel.text = [self.ackon.minor stringValue];
        }
    }else if(indexPath.section==1){
        cell.textLabel.text = self.ackon.actions.allKeys[indexPath.row];
        cell.detailTextLabel.text = self.ackon.actions[cell.textLabel.text];
    }
    
    return cell;
}
- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section{
    if(section==0){
        return @"Infomation";
    }else if(section==1){
        return @"Actions";
    }
    return nil;
}
#pragma mark UIAckonManagerDelegate
- (void)ackonManager:(ACKAckonManager *)manager didRangeAckons:(NSArray *)ackons{
    //수신된 비콘을  ackons에 차곡차곡 쌓습니다
    [self.ackons addObjectsFromArray:ackons];
}
@end
