EMWebImagePicker
==========

An iOS Image picker for URL based images

## Requirements
* Xcode 5 or higher
* Apple LLVM compiler
* iOS 7.0 or higher
* ARC

## Installation

### Cocoapods

To install via Cocoapods, add the following line to your Podfile.

``
pod 'EMWebImagePicker'
``

### Manual Installation

All you need to do is drop 'EMWebImagePicker' files into your project.

## Example Usage

Create an array of either NSURL's or NSStrings. 

```objective-c
    NSArray *urls = @[@"http://i.imgur.com/H1dxJEU.jpg",
                      @"http://i.imgur.com/cdktaUB.jpg",
                      @"http://i.imgur.com/TuaPd.jpg",
                      @"http://i.imgur.com/MdLiE.jpg",
                      [NSURL URLWithString:@"http://i.imgur.com/wgdDq.jpg"],
                      [NSURL URLWithString:@"http://i.imgur.com/yQdM1dk.jpg"],
                      [NSURL URLWithString:@"http://i.imgur.com/dP46jRF.jpg"],
                      [NSURL URLWithString:@"http://i.imgur.com/idcfv.jpg"]];
```

Then create an instance of the EMWebImagePickerViewController and initialise using either blocks or assigning a delegate to recieve the callbacks from the selection process.

```objective-c
- (void)viewDidLoad {
    [super viewDidLoad];
    EMWebImagePickerViewController *webImagePicker = [[EMWebImagePickerViewController alloc] initWithURLs:self.urls];
    webImagePicker.delegate = self;
}

#pragma mark - EMWebImagePickerViewControllerDelegate Methods

- (void)webImagePicker:(EMWebImagePickerViewController *)picker didChooseIndicies:(NSArray *)selectedIndicies {
    // Celebrate.
    [picker dismissViewControllerAnimated:YES completion:nil];
}

- (void)webImagePickerDidCancel:(EMWebImagePickerViewController *)picker {
    // Cancelled.
    [picker dismissViewControllerAnimated:YES completion:nil];
}

```

```objective-c
    EMWebImagePickerViewController *webImagePicker = [[EMWebImagePickerViewController alloc] initWithURLs:self.urls completed:^(EMWebImagePickerViewController *picker, NSArray *selectedIndicies) {
        [picker dismissViewControllerAnimated:YES completion:nil];
        // Do something to celebrate the completion.
    } cancelled:^(EMWebImagePickerViewController *picker) {
        [picker dismissViewControllerAnimated:YES completion:nil];
    }];
```

Set the type of picker you wish to use and present the view controller modally.

```objective-c
    webImagePicker.type = EMWebImagePickerTypeSingle
    webImagePicker.type = EMWebImagePickerTypeMultiple;
    webImagePicker.type = EMWebImagePickerTypeMultipleDeselect;
    [self presentViewController:webImagePicker animated:YES completion:nil];
```

The callbacks recieve an array of NSNumber containing the indexs of the selected items from the original array of URL's created.

For more information, please see the example to see a simple use case.
