//
//  VoiceDetectionVC.m
//  Matlistan
//
//  Created by Leocan on 12/18/15.
//  Copyright (c) 2015 Flame Soft. All rights reserved.
//

#import "VoiceDetectionVC.h"
#import "ALToastView.h"
#import "AppDelegate.h"
#import <AVFoundation/AVFoundation.h>
#import "SCSiriWaveformView.h"

#ifdef DEBUG
    const unsigned char SpeechKitApplicationKey[] = {0xbc, 0xf4, 0xc3, 0x2a, 0xb3, 0x92, 0xd7, 0xd0, 0xe7, 0x9e, 0x7f, 0x3e, 0x79, 0xde, 0x02, 0x7f, 0x7a, 0x68, 0x30, 0xf5, 0x2e, 0x06, 0xdb, 0xeb, 0x6a, 0xcb, 0x73, 0x64, 0x38, 0x13, 0xeb, 0xf5, 0x07, 0xae, 0x1f, 0xba, 0x40, 0xf7, 0x8a, 0x28, 0x95, 0x0a, 0x66, 0x0e, 0xe8, 0x69, 0x8e, 0x63, 0xd1, 0xbe, 0x58, 0xff, 0xc4, 0x33, 0xeb, 0x2e, 0xfe, 0x5e, 0x92, 0x37, 0x72, 0x7d, 0x2c, 0x79};
#else
    const unsigned char SpeechKitApplicationKey[] = {0x01, 0x0c, 0x1c, 0x3e, 0x2d, 0x35, 0x7f, 0x06, 0xdd, 0xb2, 0xfb, 0x9d, 0xbb, 0xc3, 0x6b, 0x19, 0x8c, 0x89, 0xee, 0xbc, 0x16, 0xd6, 0x55, 0xad, 0x50, 0x90, 0xf2, 0x41, 0xac, 0x76, 0x36, 0xad, 0x82, 0x52, 0xeb, 0xaf, 0x87, 0x6a, 0xb5, 0x64, 0x1d, 0xb0, 0x02, 0xd8, 0x74, 0x6d, 0xf1, 0x00, 0xf6, 0xdf, 0xbd, 0x0c, 0xb5, 0x12, 0xb9, 0x05, 0xa2, 0xac, 0x47, 0x4e, 0x22, 0x7d, 0xfb, 0xa4};
#endif


typedef NS_ENUM(NSUInteger, SCSiriWaveformViewInputType) {
    SCSiriWaveformViewInputTypeRecorder,
    SCSiriWaveformViewInputTypePlayer
};
@interface VoiceDetectionVC ()
@property (nonatomic, strong) AVAudioRecorder *recorder;
@property (nonatomic, strong) AVAudioPlayer *player;
@property (nonatomic, weak) IBOutlet SCSiriWaveformView *waveformView;
@property (nonatomic, assign) SCSiriWaveformViewInputType selectedInputType;
@end


@implementation VoiceDetectionVC
@synthesize delegate;
@synthesize recognizer1;

- (void)viewDidLoad {
    [super viewDidLoad];
    NSLog(@"view did load");
    int n;
    if(UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone)
    {
        n=3;
    }
    else
    {
        n=5;
    }
    [self.cancelBtn setTitle:NSLocalizedString(@"Cancel",nil) forState:UIControlStateNormal];
    (theAppDelegate).voiceResult=[[NSArray alloc] init];
    theAppDelegate.voice_not_found=false;
    self.view.layer.cornerRadius=n;
    self.view.layer.masksToBounds=YES;
    self.cancelBtn.layer.cornerRadius=n;
    self.cancelBtn.layer.masksToBounds=YES;
    
#ifdef DEBUG
    [SpeechKit setupWithID:@"NMDPTRIAL_michael_consumiq_com20160212023216"
                      host:@"sslsandbox.nmdp.nuancemobility.net"
                      port:443
                    useSSL:YES
                  delegate:self];
#else
    [SpeechKit setupWithID:@"NMDPPRODUCTION_Michael_Grundberg_Matlistan_20160214055847"
                      host:@"hjw.nmdp.nuancemobility.net"
                      port:443
                    useSSL:YES
                  delegate:self];
#endif
    
    [self voiceRecognizationStart];
    [self setwaves];
    // Do any additional setup after loading the view from its nib.
}

#pragma mark- Voice Recognization
-(void)voiceRecognizationStart{
    if(YES || !recognizer1)
    {
        NSString *languageID = [[NSBundle mainBundle] preferredLocalizations].firstObject;
        NSString *language_type;
        if([languageID isEqualToString:@"en"])
        {
            language_type=@"en_US";
        }
        else {
            language_type=@"sv_SE";
        }
        
        //Done by Michael's request.
        language_type=@"sv_SE";
        
        // DLog(@"language type %@",language_type);
        // NSLog(@"delegate 2 %@",self);
        recognizer1=[[SKRecognizer alloc]initWithType:SKSearchRecognizerType
                                            detection:SKShortEndOfSpeechDetection
                                             language:language_type
                                             delegate:self];
    }
}
-(void)recognizerDidBeginRecording:(SKRecognizer *)recognizer
{
    NSLog(@"******** start called******");
}
-(void)recognizerDidFinishRecording:(SKRecognizer *)recognizer
{
    NSLog(@"******** stop called******");
}


-(void)recognizer:(SKRecognizer *)recognizer didFinishWithResults:(SKRecognition *)matchingResult
{
    if(recognizer1)
    {
        recognizer1=nil;
    }
    [[self recorder] stop];
    [[self player] stop];
    NSLog(@"Resut arr:%@",matchingResult.results);
    
    if(matchingResult.results.count>0 && matchingResult.results!=nil)
    {
        (theAppDelegate).voiceResult=[NSArray arrayWithArray:matchingResult.results];
        
        //[SpeechKit destroy];
        
        if (self.delegate && [self.delegate respondsToSelector:@selector(cancelButtonClicked:)]) {
            [self.delegate cancelButtonClicked:self];
        }
        
    }
    else{
        (theAppDelegate).voiceResult=[[NSArray alloc] init];
        (theAppDelegate).voice_not_found=true;
        // [SpeechKit destroy];
        
        [self dismissPopupViewControllerWithanimationType:MJPopupViewAnimationFade];
        if (self.delegate && [self.delegate respondsToSelector:@selector(cancelButtonClicked:)]) {
            [self.delegate cancelButtonClicked:self];
            
        }
        
    }
    
}
-(void)recognizer:(SKRecognizer *)recognizer didFinishWithError:(NSError *)error suggestion:(NSString *)suggestion
{
    
    NSLog(@"recognizer didFinishWithError %@",[error localizedDescription]);
    //recognizer1=nil;
    // [ALToastView toastInView:self.view withText:NSLocalizedString([error localizedDescription], nil)];
    
    if (self.delegate && [self.delegate respondsToSelector:@selector(cancelButtonClicked:)]) {
        //[self.delegate cancelButtonClicked:self];
    }
    // [SpeechKit destroy];
    //    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"" message:[error localizedDescription] delegate:self cancelButtonTitle:NSLocalizedString(@"Ok", nil)otherButtonTitles:nil, nil, nil];
    //    alert.tag=1;
    //    [alert show];
    
}

#pragma mak-
#pragma mark- click event
-(IBAction)cancelBtn:(id)sender
{
    /*
     [self.recorder stop];
     
     [self.recognizer1 stopRecording];
     [self.recognizer1 cancel];
     */
    //recognizer1=nil;
    //[SpeechKit destroy];
    
    if (self.delegate && [self.delegate respondsToSelector:@selector(cancelButtonClicked:)]) {
        [self.delegate cancelButtonClicked:self];
        
    }
}
-(void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    //DLog(@"viewDidDisappear");
    
    [self.recognizer1 stopRecording];
    [self.recognizer1 cancel];
    self.delegate = nil;
    //[SpeechKit destroy];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    
    // Dispose of any resources that can be recreated.
}

/*
 #pragma mark - Navigation
 
 // In a storyboard-based application, you will often want to do a little preparation before navigation
 - (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
 // Get the new view controller using [segue destinationViewController].
 // Pass the selected object to the new view controller.
 }
 */
#pragma mark -
#pragma mark SpeechKitDelegate methods

- (void) audioSessionReleased {
    //  DLog(@"audio session released");
}

- (void) destroyed {
    
}
#pragma mark- Display waves
-(void)setwaves
{
    NSDictionary *settings = @{AVSampleRateKey:          [NSNumber numberWithFloat: 44100.0],
                               AVFormatIDKey:            [NSNumber numberWithInt: kAudioFormatAppleLossless],
                               AVNumberOfChannelsKey:    [NSNumber numberWithInt: 2],
                               AVEncoderAudioQualityKey: [NSNumber numberWithInt: AVAudioQualityMin]};
    
    NSError *error;
    NSURL *url = [NSURL fileURLWithPath:@"/dev/null"];
    self.recorder = [[AVAudioRecorder alloc] initWithURL:url settings:settings error:&error];
    
    /*if(error) {
     DLog(@"Ups, could not create recorder %@", error);
     return;
     }*/
    
    self.player = [[AVAudioPlayer alloc] initWithContentsOfURL:[[NSBundle mainBundle] URLForResource:@"sample" withExtension:@"m4a"] error:&error];
    /* if(error) {
     DLog(@"Ups, could not create player %@", error);
     return;
     }*/
    
    [[AVAudioSession sharedInstance] setCategory:AVAudioSessionCategoryPlayAndRecord error:&error];
    
    /* if (error) {
     DLog(@"Error setting category: %@", [error description]);
     //        return;
     }*/
    
    CADisplayLink *displaylink = [CADisplayLink displayLinkWithTarget:self selector:@selector(updateMeters)];
    [displaylink addToRunLoop:[NSRunLoop currentRunLoop] forMode:NSRunLoopCommonModes];
    
    [self.waveformView setWaveColor:[UIColor whiteColor]];
    [self.waveformView setPrimaryWaveLineWidth:3.0f];
    [self.waveformView setSecondaryWaveLineWidth:1.0];
    
    [self setSelectedInputType:SCSiriWaveformViewInputTypeRecorder];
    
}
- (void)setSelectedInputType:(SCSiriWaveformViewInputType)selectedInputType
{
    _selectedInputType = selectedInputType;
    
    switch (selectedInputType) {
        case SCSiriWaveformViewInputTypeRecorder: {
            [self.player stop];
            
            [self.recorder prepareToRecord];
            [self.recorder setMeteringEnabled:YES];
            [self.recorder record];
            break;
        }
        case SCSiriWaveformViewInputTypePlayer: {
            [self.recorder stop];
            
            [self.player prepareToPlay];
            [self.player setMeteringEnabled:YES];
            [self.player play];
            break;
        }
    }
}


- (void)updateMeters
{
    CGFloat normalizedValue;
    switch (self.selectedInputType) {
        case SCSiriWaveformViewInputTypeRecorder: {
            [self.recorder updateMeters];
            normalizedValue = [self _normalizedPowerLevelFromDecibels:[self.recorder averagePowerForChannel:0]];
            break;
        }
        case SCSiriWaveformViewInputTypePlayer: {
            [self.player updateMeters];
            normalizedValue = [self _normalizedPowerLevelFromDecibels:[self.player averagePowerForChannel:0]];
            break;
        }
    }
    
    [self.waveformView updateWithLevel:normalizedValue];
}

#pragma mark - Private

- (CGFloat)_normalizedPowerLevelFromDecibels:(CGFloat)decibels
{
    if (decibels < -60.0f || decibels == 0.0f) {
        return 0.0f;
    }
    
    return powf((powf(10.0f, 0.05f * decibels) - powf(10.0f, 0.05f * -60.0f)) * (1.0f / (1.0f - powf(10.0f, 0.05f * -60.0f))), 1.0f / 2.0f);
}


@end
