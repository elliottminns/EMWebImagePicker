//
//  EMWebImagePickerViewController.h
//  Example
//
//  Created by Elliott Minns on 20/02/2014.
//  Copyright (c) 2014 Elliott Minns. All rights reserved.
//

#import <UIKit/UIKit.h>

@class EMWebImagePickerViewController;

typedef void (^EMWebImagePickerSelectedBlock)(EMWebImagePickerViewController *picker, NSArray *selectedIndicies);
typedef void (^EMPickerBlock)(EMWebImagePickerViewController *picker);
typedef void (^EMWebImagePickerArrayBlock)(NSArray *array);
typedef void (^EMWebImagePickerErrorBlock)(NSError *error);

typedef NS_ENUM(NSInteger, EMWebImagePickerType) {
    EMWebImagePickerTypeSingle,
    EMWebImagePickerTypeMultiple,
    EMWebImagePickerTypeMultipleDeselect
};

@protocol EMWebImagePickerViewControllerDelegate <NSObject>
- (void)webImagePicker:(EMWebImagePickerViewController *)picker didChooseIndicies:(NSArray *)selectedIndicies;
- (void)webImagePickerDidCancel:(EMWebImagePickerViewController *)picker;
- (BOOL)webImagePickerCanRecieveMoreContent:(EMWebImagePickerViewController *)picker;
@optional
- (NSArray *)webImagePickerRequestImagesForNextPage:(EMWebImagePickerViewController *)picker;
- (void)webImagePickerRequestImagesForNextPage:(EMWebImagePickerViewController *)picker
                                   withSuccess:(EMWebImagePickerArrayBlock)success
                                       failure:(EMWebImagePickerErrorBlock)failure;
@end

@interface EMWebImagePickerViewController : UIViewController

- (id)initWithURLs:(NSArray *)urls;
- (id)initWithURLs:(NSArray *)urls
         completed:(EMWebImagePickerSelectedBlock)completed
         cancelled:(EMPickerBlock)cancelled;

@property (nonatomic, weak) id<EMWebImagePickerViewControllerDelegate> delegate;
@property (nonatomic, assign) EMWebImagePickerType type;
@property (nonatomic, assign) BOOL pagingEnabled;
@property (nonatomic, strong) NSArray *previousSelectedUrls;

@end
