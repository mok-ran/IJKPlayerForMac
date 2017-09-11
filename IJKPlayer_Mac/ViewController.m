//
//  ViewController.m
//  IJKPlayer_Mac
//
//  Created by mini on 2017/6/2.
//  Copyright © 2017年 mini. All rights reserved.
//

#import "ViewController.h"
#import "IJKFFMoviePlayerController.h"
#import "Masonry.h"
#import "BackgroundView.h"
#import "ListenMouseView.h"
#import "MouseButton.h"
#import "PlayerControlBar.h"
#import "PlayerTitleBar.h"
#import "CrossAssistTool.h"
#include <Carbon/Carbon.h>
#import "KeepWake.h"
#import "EventSendManager.h"
#import "OpenNetworkWindowCtl.h"

#define MAIN_SIZE [NSScreen mainScreen].frame.size
#define VISIBLE_SIZE [NSScreen mainScreen].visibleFrame.size
#define DEFAULT_SIZE_WIDTH  1024
#define DEFAULT_SIZE NSMakeSize(1024, 576)
#define MIN_SIZE NSMakeSize(480, 270)

#define FASTWORD_STEP_DEFAULT 5.0f
#define VOLUME_STEP_DEFAULT 0.05f


@interface ViewController()<NSWindowDelegate>

@property (nonatomic,strong)IJKFFMoviePlayerController *player;

@property (weak) IBOutlet NSButton *openFileBtn;
@property (weak) IBOutlet BackgroundView *backgroundV;
@property (weak) IBOutlet ListenMouseView *listenMouseV;

@property (nonatomic,strong)PlayerControlBar *playCtl;
@property (nonatomic,strong)PlayerTitleBar *playTitleBar;
@property (atomic,assign)BOOL isWindowBtnHidden;


@property (atomic,assign)CGFloat fastwordStep;
@property (atomic,assign)CGFloat volumeStep;
@property (atomic,assign)BOOL isFullScreen;
@property (atomic,assign)BOOL isCoverOpen;

@property (nonatomic,strong)OpenNetworkWindowCtl *networkWC;

@end

@implementation ViewController

- (void)dealloc{
    [self.view removeObserver:self forKeyPath:@"window"];
    [[NSNotificationCenter defaultCenter]removeObserver:self];
    
}

- (void)viewDidLoad {
    [super viewDidLoad];

    [self createUI];
    
    
}

#pragma mark --- setter and getter 

- (OpenNetworkWindowCtl *)networkWC{
    if(!_networkWC){
        _networkWC = [[OpenNetworkWindowCtl alloc]initWithWindowNibName:@"OpenNetworkWindowCtl"];
    }
    return _networkWC;
}

#pragma mark --- load

- (void)loadEventSendManager{
    
    EventSendManager *manager = [EventSendManager shareManager];
    @weakify(self);
    manager.openFileBlock = ^(NSMenuItem *item) {
        @strongify(self);if(!self)return;
        [self openFileClick:nil];
    };
    
    manager.openNetworkBlock = ^(NSMenuItem *item) {
        @strongify(self);if(!self)return;
        [self openNetworkWindowCtl];
    };
    
    
}

- (void)loadPlayCtlBar{
    
    self.playCtl = [[PlayerControlBar alloc]initWithNibName:@"PlayerControlBar" bundle:nil];
    [self.view addSubview:self.playCtl.view];
    CGFloat w = 54.f;
    [self.playCtl.view mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(self.view);
        make.bottom.equalTo(self.view);
        make.height.mas_equalTo(w);
        make.right.equalTo(self.view);
    }];
    self.playCtl.view.hidden = YES;
    
    
    @weakify(self);
    
    self.playCtl.playOrPauseBlock = ^{
        @strongify(self);if(!self)return;
        if(!self.player)return;
        [self changePlayerStat];
        [self showMediaBar];
    };
    
    self.playCtl.readMediaInfoBlock = ^IJKFFMoviePlayerController *{
        @strongify(self);if(!self)return nil;
        return self.player;
    };
    
    self.playCtl.progressChangedBlock = ^void(CGFloat progress) {
        @strongify(self);if(!self)return;
        if(!self.player)return;
        self.player.currentPlaybackTime = progress * self.player.duration;
        return;
    };
    
    self.playCtl.stopBlock = ^{
        @strongify(self);if(!self)return;
        [self closePlayer];
        [self mediaEnd];
    };
    
    self.playCtl.volumeChangedBlock = ^void(CGFloat progress) {
        @strongify(self);if(!self)return;
        if(!self.player)return;
        self.player.playbackVolume = progress;
    };
    
    self.playCtl.playRateChangedBlock = ^(CGFloat playRate) {
        @strongify(self);if(!self)return;
        if(!self.player)return;
        self.player.zzPlaybackRate = playRate;
    };

    
}

- (void)loadPlayTitleBar{
    
    self.playTitleBar = [[PlayerTitleBar alloc]initWithNibName:@"PlayerTitleBar" bundle:nil];
    [self.view addSubview:self.playTitleBar.view];
    CGFloat w = 20.0f;
    [self.playTitleBar.view mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(self.view);
        make.top.equalTo(self.view);
        make.height.mas_equalTo(w);
        make.right.equalTo(self.view);
    }];
    self.playTitleBar.view.hidden = YES;
    
    @weakify(self);
    
    self.playTitleBar.closeWindowBlock = ^{
        @strongify(self);if(!self)return;
        [self.view.window close];
    };
    
    self.playTitleBar.minWindowBlock = ^{
        @strongify(self);if(!self)return;
        [self.view.window miniaturize:nil];
    };
    
    self.playTitleBar.zoomWindowBlock = ^{
        @strongify(self);if(!self)return;
        [self.view.window toggleFullScreen:nil];
    };
    
}

- (void)loadListenViewEvent{
    
    @weakify(self);
    self.listenMouseV.dragFileBlock = ^(NSString *filename) {
        @strongify(self);if(!self)return;
        [self openPlayer:filename];
    };
    
    self.listenMouseV.showBarBlock = ^{
        @strongify(self);if(!self)return;
        if(self.player){
            [self showMediaBar];
        }
    };
    
    self.listenMouseV.setMediaProgressBlock = ^{
        @strongify(self);if(!self)return;
        [self.playCtl setMediaProgress];
    };
    
    self.listenMouseV.hideBarBlock = ^{
        @strongify(self);if(!self)return;
        [self hideMediaBar];
    };
    
    self.listenMouseV.keyDownBlock = ^(short keyCode) {
        @strongify(self);if(!self)return;
        [self listenedKeyDownEvent:keyCode];
    };
    
    
    
}



- (void)createUI{
    
    self.isWindowBtnHidden = NO;
    self.fastwordStep = FASTWORD_STEP_DEFAULT;
    self.volumeStep = VOLUME_STEP_DEFAULT;
    
    [self.view addObserver:self forKeyPath:@"window" options:NSKeyValueObservingOptionNew context:nil];
    self.view.wantsLayer = YES;
    self.view.layer.backgroundColor = [NSColor blackColor].CGColor;
    
    NSClickGestureRecognizer *click = [[NSClickGestureRecognizer alloc]initWithTarget:self action:@selector(doubleClick:)];
    click.numberOfClicksRequired = 2;
    [self.view addGestureRecognizer:click];// 事件放到 ListenMouseView 中无反应... 估计是和 mouseDown 冲突了
    
    
    [self loadPlayTitleBar];
    [self loadPlayCtlBar];
    [self loadListenViewEvent];
    [self loadEventSendManager];
    
    @weakify(self);
    

    
    
    [[NSNotificationCenter defaultCenter]addObserverForName:IJKMPMoviePlayerPlaybackDidFinishNotification object:nil queue:[NSOperationQueue mainQueue] usingBlock:^(NSNotification * _Nonnull note) {
        @strongify(self);if(!self)return;
        if(self.isCoverOpen)return;
        [self closePlayer];
        [self mediaEnd];
        
    }];
    
    [[NSNotificationCenter defaultCenter]addObserverForName:IJKMPMovieNaturalSizeAvailableNotification object:nil queue:[NSOperationQueue mainQueue] usingBlock:^(NSNotification * _Nonnull note) {
        @strongify(self);if(!self)return;
        if(self.player){
            [self.view.window setContentSize:NSMakeSize(self.player.naturalSize.width, self.player.naturalSize.height)];
            [self.view.window center];
            if(self.player.realtime){
                [self.playCtl hidePlayRateCtl];
                self.playCtl.realtime = YES;
            }
        }
    }];

    
    [self mediaEnd];
    
    

}

#pragma mark -- action

- (void)showWindowButton{
    
    if(!self.view.window)return;
    if(!self.isWindowBtnHidden)return;
    self.isWindowBtnHidden = NO;
    
    NSButton *closeBtn = [self.view.window standardWindowButton:NSWindowCloseButton];
    [closeBtn setEnabled:YES];
    closeBtn.hidden = NO;
    NSButton *minButton = [self.view.window standardWindowButton:NSWindowMiniaturizeButton];
    [minButton setEnabled:YES];
    minButton.hidden = NO;
    NSButton *fullButton = [self.view.window standardWindowButton:NSWindowFullScreenButton];
    [fullButton setEnabled:YES];
    fullButton.hidden = NO;
    NSButton *zoomButton = [self.view.window standardWindowButton:NSWindowZoomButton];
    [zoomButton setEnabled:YES];
    zoomButton.hidden = NO;
    
    
}

- (void)hideWindowButton{
    
    if(!self.view.window)return;
    if(self.isWindowBtnHidden)return;
    self.isWindowBtnHidden = YES;
    
    NSButton *closeBtn = [self.view.window standardWindowButton:NSWindowCloseButton];
    [closeBtn setEnabled:NO];
    closeBtn.hidden = YES;
    NSButton *minButton = [self.view.window standardWindowButton:NSWindowMiniaturizeButton];
    [minButton setEnabled:NO];
    minButton.hidden = YES;
    NSButton *fullButton = [self.view.window standardWindowButton:NSWindowFullScreenButton];
    [fullButton setEnabled:NO];
    fullButton.hidden = YES;
    NSButton *zoomButton = [self.view.window standardWindowButton:NSWindowZoomButton];
    [zoomButton setEnabled:NO];
    zoomButton.hidden = YES;
    
}


- (void)settingWindow{
    
    if(self.view.window == nil)return;
    self.view.window.delegate = self;
    [self.view.window setContentSize:DEFAULT_SIZE];
    
    if ([NSWindow instancesRespondToSelector:@selector(setTitleVisibility:)]) {
        self.view.window.titleVisibility = NSWindowTitleHidden; //隐藏标题,不在文档里,哈.
        self.view.window.titlebarAppearsTransparent = YES; //标题栏透明,也是文档没有的玩意
        self.view.window.styleMask |= NSFullSizeContentViewWindowMask; //全尺寸
    }
    self.view.window.backgroundColor = [NSColor blackColor];
    if(self.player){
        [self hideWindowButton];
    }else{
        [self showWindowButton];
    }

    
}

- (void)showMediaBar{
    
    [self.playCtl showBar];
    [self.playTitleBar showBar];
    
}

- (void)hideMediaBar{
    
    [self.playCtl hideBar];
    [self.playTitleBar hideBar];
}

- (void)changePlayerStat{
    
    BOOL ret = NO;
    if(self.player.isPlaying){
        [self.player pause];
        ret = NO;
    }else{
        [self.player play];
        ret = YES;
    }
    
    [self.playCtl changePlayOrPauseImage:ret];
    
    
}

- (void)listenedKeyDownEvent:(short)keyCode{
    
    if(!self.player)return;
    
    switch (keyCode) {
        case kVK_LeftArrow:
        {
            if(!self.player.realtime){
                self.player.currentPlaybackTime -= self.fastwordStep;
            }
            [self showMediaBar];
        }
            break;
        case kVK_RightArrow:
        {
            if(!self.player.realtime){
                self.player.currentPlaybackTime += self.fastwordStep;
            }
            [self showMediaBar];
        }
            break;
        case kVK_Space:
        {
            if(!self.player.realtime){
                [self changePlayerStat];
            }
        }
            break;
        case kVK_UpArrow:
        {
            [self.playCtl changeVolumeValue:self.player.playbackVolume + self.volumeStep];
        }
            break;
        case kVK_DownArrow:
        {
            [self.playCtl changeVolumeValue:self.player.playbackVolume - self.volumeStep];
        }
            break;
            
        default:
            break;
    }
    
    
}

- (void)doubleClick:(NSClickGestureRecognizer *)sender{
    if(!self.player)return;
    [self.view.window toggleFullScreen:nil];
}

- (void)openNetworkWindowCtl{
    

    [self.networkWC showWindow:nil];
    [self.networkWC.window center];
    @weakify(self);
    self.networkWC.openBlock = ^(NSString *urlString){
        @strongify(self);if(!self)return;
        [self openPlayer:urlString];
        [self.networkWC close];
        
    };
    
    self.networkWC.cancelBlock = ^{
        @strongify(self);if(!self)return;
        [self.networkWC close];
    };

}


#pragma mark ---

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSKeyValueChangeKey,id> *)change context:(void *)context{
    
    if([keyPath isEqualToString:@"window"]){
         [self settingWindow];
    }
}



- (NSSize)getSuitableSize:(NSSize)frameSize{

    NSSize suitSize = frameSize;
    
    CGFloat originW = _player.monitor.width;
    CGFloat originH = _player.monitor.height;
    if(originW && originH){
        
        BOOL scaleByW = frameSize.width / frameSize.height >= originW / originH;
        
        if(!scaleByW){
            suitSize.width = frameSize.width;
            suitSize.height = suitSize.width * originH / originW;
        }else{
            suitSize.height = frameSize.height;
            suitSize.width = suitSize.height * originW / originH;
        }
    }
    
    
    return suitSize;
}

- (void)viewDidLayout{
    [super viewDidLayout];
    [self resizePlayerViewSize];
}

#pragma mark -- window delegate

- (void)windowWillClose:(NSNotification *)notification{
    
    [NSApp terminate:nil];
}



- (void)windowWillExitFullScreen:(NSNotification *)notification{
    self.isFullScreen = NO;
    if(self.player){
        [self hideWindowButton];
    }

}
- (void)windowWillEnterFullScreen:(NSNotification *)notification{
    self.isFullScreen = YES;
    if(self.player){
        [self showWindowButton];
    }
}


#pragma action

- (IBAction)openFileClick:(NSButton *)sender {
    
    NSOpenPanel *panel = [NSOpenPanel openPanel];
    [panel setMessage:@""];
    [panel setPrompt:@"Open"];
    [panel setCanChooseDirectories:NO];
    [panel setCanCreateDirectories:NO];
    [panel setCanChooseFiles:YES];
    NSInteger result = [panel runModal];
    if (result == NSFileHandlingPanelOKButton)
    {
        [self openPlayer:[[panel URL] path]];
    }
}


#pragma ---

- (void)resizePlayerViewSize{
    
    NSSize size = [self getSuitableSize:self.view.frame.size];
    [_player.view mas_updateConstraints:^(MASConstraintMaker *make) {
        make.center.equalTo(self.view);
        make.size.mas_equalTo(size);
    }];
    
}

- (void)closePlayer{
    
    if(self.player){
        [self.player shutdown];
        [self.player.view removeFromSuperview];
        self.player = nil;
    }
    
}

- (void)openPlayer:(NSString *)filepath{
    
    if(filepath.length <= 0){
        return;
    }
    
    if(self.player){
        self.isCoverOpen = YES;
    }else{
        self.isCoverOpen = NO;
    }
    [self closePlayer];

    
    IJKFFOptions *options = [[IJKFFOptions alloc] init];
    [options setPlayerOptionIntValue:60     forKey:@"max-fps"];
    [options setPlayerOptionIntValue:1      forKey:@"framedrop"];
    [options setPlayerOptionIntValue:5      forKey:@"video-pictq-size"];
    [options setPlayerOptionIntValue:1      forKey:@"videotoolbox"];
    [options setPlayerOptionIntValue:4096   forKey:@"videotoolbox-max-frame-width"];
    
    [options setFormatOptionIntValue:1                  forKey:@"auto_convert"];
    [options setFormatOptionIntValue:1                  forKey:@"reconnect"];
    [options setFormatOptionIntValue:30 * 1000 * 1000   forKey:@"timeout"];
    [options setFormatOptionValue:@"ijkplayer"          forKey:@"user-agent"];
    
    options.showHudView   = NO;
    
    _player = [[IJKFFMoviePlayerController alloc]initWithContentURLString:filepath withOptions:options];
    if(!_player){
        return;
    }
    [self.playCtl showPlayRateCtl];
    self.playCtl.realtime = NO;
    _player.view.wantsLayer = YES;
    _player.view.layer.backgroundColor = [NSColor blackColor].CGColor;
    _player.view.layerContentsPlacement = NSViewLayerContentsPlacementScaleProportionallyToFit;
    [_player.view setFrame:self.view.bounds];
    [self.view addSubview:_player.view];
    [self resizePlayerViewSize];
    [_player prepareToPlay];
    [_player play];
    
    [IJKFFMoviePlayerController setLogLevel:k_IJK_LOG_SILENT];

    [self mediaBegin:filepath];

    

    
    
}


#pragma mark  --- media begin



- (void)mediaBegin:(NSString *)filepath{
    
    [KeepWake shareManager].keepWake = YES;
    self.backgroundV.hidden = YES;
    [self hideWindowButton];
    [[NSNotificationCenter defaultCenter]postNotificationName:MediaPlayerBegin object:nil userInfo:@{MediaPlayerFilenameKey:filepath.lastPathComponent,MediaPlayerVolumeKey:@(self.player.playbackVolume)}];
    
}

- (void)mediaEnd{
    
    [KeepWake shareManager].keepWake = NO;
    self.backgroundV.hidden = NO;
    [self.view.window setContentSize:DEFAULT_SIZE];
    [self showWindowButton];
    [[NSNotificationCenter defaultCenter]postNotificationName:MediaPlayerEnd object:nil];
    
    if(self.isFullScreen){
        [self.view.window toggleFullScreen:nil];
        [self.view.window center];
    }
}

@end
