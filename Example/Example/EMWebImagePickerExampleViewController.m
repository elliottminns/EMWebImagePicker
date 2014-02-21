//
//  EMViewController.m
//  Example
//
//  Created by Elliott Minns on 20/02/2014.
//  Copyright (c) 2014 Elliott Minns. All rights reserved.
//

#import "EMWebImagePickerExampleViewController.h"
#import "EMWebImagePickerViewController.h"
#import "UIImageView+WebCache.h"

@interface EMWebImagePickerExampleViewController () <EMWebImagePickerViewControllerDelegate>
@property (nonatomic, strong) NSArray *urls;
@property (nonatomic, weak) IBOutlet UIImageView *imageView;
@property (nonatomic, strong) NSTimer *photoSliderTimer;
@property (nonatomic, strong) NSMutableArray *imageURLs;
@end

@implementation EMWebImagePickerExampleViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    // Initialise the URLS to be used for the image picker, can use NSString or NSURL.
    NSArray *urls = @[@"http://i.imgur.com/H1dxJEU.jpg",
                      @"http://i.imgur.com/cdktaUB.jpg",
                      @"http://i.imgur.com/TuaPd.jpg",
                      @"http://i.imgur.com/MdLiE.jpg",
                      [NSURL URLWithString:@"http://i.imgur.com/wgdDq.jpg"],
                      [NSURL URLWithString:@"http://i.imgur.com/yQdM1dk.jpg"],
                      [NSURL URLWithString:@"http://i.imgur.com/dP46jRF.jpg"],
                      [NSURL URLWithString:@"http://i.imgur.com/idcfv.jpg"],
                      @"http://i.imgur.com/8y8xra6.jpg",
                      @"http://i.imgur.com/cXeEaEH.jpg",
                      @"http://i.imgur.com/I6fIc0Y.jpg",
                      @"http://i.imgur.com/ChFs49Y.jpg",
                      @"http://i.imgur.com/HgoBQvm.jpg",
                      @"http://i.imgur.com/98DxGFf.jpg",
                      @"http://i.imgur.com/9oJrOC5.jpg",
                      @"http://i.imgur.com/udiHH0a.jpg",
                      @"http://i.imgur.com/ZXChOmq.png",
                      @"http://i.imgur.com/YbBBCZE.jpg",
                      @"http://i.imgur.com/MXrgvC1.jpg",
                      @"http://i.imgur.com/lOBWo9x.jpg",
                      @"http://i.imgur.com/iCncTJG.jpg",
                      @"http://i.imgur.com/prk9O8U.jpg",
                      @"http://i.imgur.com/70XCO1j.jpg"];
    
    self.urls = urls;
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    [self.photoSliderTimer invalidate];
    self.photoSliderTimer = nil;
}

#pragma mark - Actions

- (void)getUrlsFromSelected:(NSArray *)selected {
    self.imageURLs = [[NSMutableArray alloc] init];
    for (NSNumber *index in selected) {
        [self.imageURLs addObject:[self.urls objectAtIndex:[index integerValue]]];
    }
}

- (IBAction)chooseSinglePhotoButtonTapped:(id)sender {
    EMWebImagePickerViewController *webImagePicker = [[EMWebImagePickerViewController alloc] initWithURLs:self.urls];
    webImagePicker.delegate = self;
    [self presentViewController:webImagePicker animated:YES completion:nil];
}

- (IBAction)chooseMultiplePhotoButtonTapped:(id)sender {
    EMWebImagePickerViewController *webImagePicker = [[EMWebImagePickerViewController alloc] initWithURLs:self.urls completed:^(EMWebImagePickerViewController *picker, NSArray *selectedIndicies) {
        [self.photoSliderTimer invalidate];
        self.photoSliderTimer = nil;
        [picker dismissViewControllerAnimated:YES completion:nil];

        [self getUrlsFromSelected:selectedIndicies];
        
        self.photoSliderTimer = [NSTimer scheduledTimerWithTimeInterval:4.0 target:self selector:@selector(changePhoto) userInfo:nil repeats:YES];
        [self changePhoto];
    } cancelled:^(EMWebImagePickerViewController *picker) {
        [self.photoSliderTimer invalidate];
        self.photoSliderTimer = nil;
        [picker dismissViewControllerAnimated:YES completion:nil];
    }];
    
    webImagePicker.type = EMWebImagePickerTypeMultiple;
    [self presentViewController:webImagePicker animated:YES completion:nil];
}

- (IBAction)deselectMultiplePhotoButtonTapped:(id)sender {
    EMWebImagePickerViewController *webImagePicker = [[EMWebImagePickerViewController alloc] initWithURLs:self.urls];
    webImagePicker.type = EMWebImagePickerTypeMultipleDeselect;
    webImagePicker.delegate = self;
    [self presentViewController:webImagePicker animated:YES completion:nil];
}

#pragma mark - Timer Methods

- (void)changePhoto {
    static int count = 0;
    
    [UIView transitionWithView:self.imageView
                      duration:1.5f
                       options:UIViewAnimationOptionTransitionCrossDissolve
                    animations:^{
                        if (count >= self.imageURLs.count) {
                            count = 0;
                        }
                        [self.imageView setImageWithURL:self.imageURLs[count]];
                    } completion:nil];
    count++;
}

#pragma mark - EMWebImagePickerViewControllerDelegate Methods

- (void)webImagePicker:(EMWebImagePickerViewController *)picker didChooseIndicies:(NSArray *)selectedIndicies {
    [self.photoSliderTimer invalidate];
    self.photoSliderTimer = nil;
    [self getUrlsFromSelected:selectedIndicies];
    if (picker.type == EMWebImagePickerTypeSingle) {
        [picker dismissViewControllerAnimated:YES completion:nil];
        [self.imageView setImageWithURL:self.imageURLs.firstObject];
    } else {
        [picker dismissViewControllerAnimated:YES completion:nil];
        self.photoSliderTimer = [NSTimer scheduledTimerWithTimeInterval:4.0 target:self selector:@selector(changePhoto) userInfo:nil repeats:YES];
    }
}

- (void)webImagePickerDidCancel:(EMWebImagePickerViewController *)picker {
    [picker dismissViewControllerAnimated:YES completion:nil];
}

@end
