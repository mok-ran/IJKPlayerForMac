//
//  OpenNetworkWindowCtl.m
//  IJKPlayer_Mac
//
//  Created by mini on 2017/9/11.
//  Copyright © 2017年 mini. All rights reserved.
//

#import "OpenNetworkWindowCtl.h"

@interface OpenNetworkWindowCtl ()<NSTextFieldDelegate>
@property (weak) IBOutlet NSTextField *urlLabel;
@property (weak) IBOutlet NSTextField *urlTextField;
@property (weak) IBOutlet NSButton *openButton;
@property (weak) IBOutlet NSButton *cancelButton;


@property (nonatomic,copy)NSString *lastUrlString;
@end

@implementation OpenNetworkWindowCtl

- (void)windowDidLoad {
    [super windowDidLoad];
    
    // Implement this method to handle any initialization after your window controller's window has been loaded from its nib file.
    [self create];
}

- (void)showWindow:(id)sender{
    [super showWindow:sender];
    if(self.lastUrlString.length){
        self.urlTextField.placeholderString = self.lastUrlString;
    }
}

- (void)dealloc{
    [[NSNotificationCenter defaultCenter]removeObserver:self];
}

- (void)create{
    
    [self.window setTitle:@"Open Network"];
    
    NSButton *closeBtn = [self.window standardWindowButton:NSWindowCloseButton];
    [closeBtn setEnabled:NO];
    closeBtn.hidden = YES;
    NSButton *minButton = [self.window standardWindowButton:NSWindowMiniaturizeButton];
    [minButton setEnabled:NO];
    minButton.hidden = YES;
    NSButton *fullButton = [self.window standardWindowButton:NSWindowFullScreenButton];
    [fullButton setEnabled:NO];
    fullButton.hidden = YES;
    NSButton *zoomButton = [self.window standardWindowButton:NSWindowZoomButton];
    [zoomButton setEnabled:NO];
    zoomButton.hidden = YES;
    
    self.urlTextField.delegate = self;
    self.openButton.enabled = NO;
    
    [self.window setMaxSize:NSMakeSize(480, 150)];
    [self.window setMinSize:NSMakeSize(480, 150)];
    [[NSNotificationCenter defaultCenter]addObserver:self selector:@selector(textDidChange:) name:NSTextDidChangeNotification object:nil];
}


#pragma mark -- action
- (IBAction)openClick:(NSButton *)sender {
    if(self.openBlock){
        NSString *value = self.urlTextField.stringValue.length ? self.urlTextField.stringValue : self.urlTextField.placeholderString;
        self.openBlock(value);
        self.lastUrlString = value;
    }
    
}
- (IBAction)cancelClick:(NSButton *)sender {
    if(self.cancelBlock){
        self.cancelBlock();
    }
}

#pragma mark -- NSTextFieldDelegate

- (void)textDidChange:(NSNotification *)notification{
    if(self.urlTextField.stringValue.length || self.urlTextField.placeholderString.length){
        self.openButton.enabled = YES;
    }else{
        self.openButton.enabled = NO;
    }
}


@end
