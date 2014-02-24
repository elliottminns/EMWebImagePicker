//
//  EMWebImagePickerViewController.m
//  Example
//
//  Created by Elliott Minns on 20/02/2014.
//  Copyright (c) 2014 Elliott Minns. All rights reserved.
//

#import "EMWebImagePickerViewController.h"
#import "UIImageView+WebCache.h"
#import "EMWebImageModel.h"
#import "DACircularProgressView.h"


NS_ENUM(NSInteger, kCellTag) {
    CellTagImageView = 5,
    CellTagTickImageView = 6
};

@interface EMWebImagePickerViewController () <UICollectionViewDataSource,
UICollectionViewDelegate, UICollectionViewDelegateFlowLayout, UIScrollViewDelegate>
// Views
@property (nonatomic, strong) UINavigationBar *navigationBar;
@property (nonatomic, strong) UICollectionView *collectionView;

// Data
@property (nonatomic, strong) NSMutableArray *images;

// Blocks
@property (nonatomic, copy) EMWebImagePickerSelectedBlock completedBlock;
@property (nonatomic, copy) EMPickerBlock cancelledBlock;

// Single Selection.
@property (nonatomic, strong) EMWebImageModel *selectedModel;

// Multiple Selection.
@property (nonatomic, strong) NSMutableArray *selectedImages;
@property (nonatomic, strong) NSMutableArray *selectedURLs;

// Scrolling.
@property (nonatomic, assign) BOOL userDragging;
@property (nonatomic, assign) BOOL noMorePaging;

// Pagination.
@property (nonatomic, strong) UIActivityIndicatorView *activityIndicator;

@end

static NSString *const identifier = @"EMWebImageCollectionCell";

@implementation EMWebImagePickerViewController

- (id)initWithURLs:(NSArray *)urls {
    return [self initWithURLs:urls completed:nil cancelled:nil];
}

- (id)initWithURLs:(NSArray *)urls
         completed:(EMWebImagePickerSelectedBlock)completed
         cancelled:(EMPickerBlock)cancelled {
    self = [super init];
    if (self) {
        self.images = [[NSMutableArray alloc] initWithArray:[self cleanArray:urls]];
        
        self.completedBlock = completed;
        self.cancelledBlock = cancelled;
        
        self.selectedImages = [[NSMutableArray alloc] init];
        self.selectedURLs   = [[NSMutableArray alloc] init];

    }
    
    return self;
}

- (NSArray *)cleanArray:(NSArray *)urlArray {
    NSMutableArray *cleanArray = [[NSMutableArray alloc] init];
    
    for (id obj in urlArray) {
        EMWebImageModel *model = [[EMWebImageModel alloc] init];
        model.selected = (self.type == EMWebImagePickerTypeMultipleDeselect);
        if ([obj isKindOfClass:[NSString class]]) {
            NSURL *url = [NSURL URLWithString:obj];
            model.url = url;
        } else if ([obj isKindOfClass:[NSURL class]]) {
            model.url = obj;
        }
        
        if (model.url) {
            [cleanArray addObject:model];
        }
    }
    return cleanArray;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    UICollectionViewFlowLayout *layout = [[UICollectionViewFlowLayout alloc] init];
    self.collectionView = [[UICollectionView alloc] initWithFrame:CGRectZero collectionViewLayout:layout];
    self.collectionView.delegate = self;
    self.collectionView.dataSource = self;
    [self.collectionView registerClass:[UICollectionViewCell class] forCellWithReuseIdentifier:identifier];
    self.collectionView.backgroundColor = [UIColor clearColor];
    self.collectionView.bouncesZoom = YES;
    self.collectionView.scrollEnabled = YES;
    self.collectionView.alwaysBounceVertical = YES;
    self.collectionView.bounces = YES;
    BOOL allows = (self.type != EMWebImagePickerTypeSingle);
    self.collectionView.allowsMultipleSelection = allows;
    
    self.view.backgroundColor = [UIColor blackColor];

    if (self.type == EMWebImagePickerTypeMultipleDeselect) {
        for (NSInteger i = 0; i < self.images.count; i++) {
            NSIndexPath *indexPath = [NSIndexPath indexPathForRow:i inSection:0];
            [self.collectionView selectItemAtIndexPath:indexPath animated:NO scrollPosition:UICollectionViewScrollPositionNone];
        }
    }
    
    [self.view addSubview:self.collectionView];
    
    self.navigationBar = [[UINavigationBar alloc] init];
    [self.view addSubview:self.navigationBar];
    UINavigationItem *titleItem = [[UINavigationItem alloc] initWithTitle:@"Select Image"];
    [self.navigationBar pushNavigationItem:titleItem animated:NO];
    
    UIBarButtonItem *doneButton = [[UIBarButtonItem alloc] initWithTitle:@"Done" style:UIBarButtonItemStylePlain target:self action:@selector(doneButtonPressed:)];
    titleItem.rightBarButtonItem = doneButton;
    
    UIBarButtonItem *cancelButton = [[UIBarButtonItem alloc] initWithTitle:@"Cancel" style:UIBarButtonItemStylePlain target:self action:@selector(cancelButtonPressed:)];
    titleItem.leftBarButtonItem = cancelButton;
    
    [self.view setNeedsUpdateConstraints];
    [self.view updateConstraintsIfNeeded];
    
    if (self.pagingEnabled) {
        self.activityIndicator = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhite];
        [self.activityIndicator sizeToFit];
        [self.view addSubview:self.activityIndicator];
    }
}

- (void)setType:(EMWebImagePickerType)type {
    _type = type;
    
    UINavigationItem *titleItem = self.navigationBar.items.firstObject;
    titleItem.title = (type == EMWebImagePickerTypeSingle) ? @"Select Image" : @"Select Images";
    
    self.collectionView.allowsMultipleSelection = (type != EMWebImagePickerTypeSingle);
    
    if (type == EMWebImagePickerTypeMultipleDeselect) {
        for (EMWebImageModel *model in self.images) {
            model.selected = YES;
        }
    }
}

- (void)updateViewConstraints {
    [super updateViewConstraints];
    NSDictionary *views = NSDictionaryOfVariableBindings(_collectionView, _navigationBar);
    
    self.navigationBar.translatesAutoresizingMaskIntoConstraints = NO;
    
    [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-0-[_navigationBar(64)]" options:0 metrics:nil views:views]];
    [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|-0-[_navigationBar]-0-|" options:0 metrics:nil views:views]];
    
    self.collectionView.translatesAutoresizingMaskIntoConstraints = NO;
    [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|-0-[_collectionView]-0-|"
                                                                      options:0
                                                                      metrics:nil
                                                                        views:views]];
    [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-0-[_collectionView]-0-|"
                                                                      options:0
                                                                      metrics:nil
                                                                        views:views]];
    
    CGFloat bottomInset = self.pagingEnabled ? 55 : 5;
    self.collectionView.contentInset = UIEdgeInsetsMake(69, 5, bottomInset, 5);
    self.collectionView.scrollIndicatorInsets = UIEdgeInsetsMake(64, 0, 0, 0);
    
    if (self.pagingEnabled) {
        CGPoint activityCenter = CGPointMake(self.view.frame.size.width / 2, self.view.frame.size.height - 25);
        self.activityIndicator.center = activityCenter;
        self.activityIndicator.hidesWhenStopped = YES;
    }
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

#pragma mark - Actions

- (NSArray *)getSelectedIndicies {
    NSMutableArray *array = [[NSMutableArray alloc] init];
    
    int index = 0;
    for (EMWebImageModel *model in self.images) {
        if (model.selected) {
            [array addObject:@(index)];
        }
        index++;
    }
    
    return array;
}

- (void)doneButtonPressed:(id)sender {
    
    if (self.delegate && [self.delegate respondsToSelector:@selector(webImagePicker:didChooseIndicies:)]) {
        [self.delegate webImagePicker:self didChooseIndicies:[self getSelectedIndicies]];
    }
    
    if (self.completedBlock) {
        self.completedBlock(self, [self getSelectedIndicies]);
    }
}

- (void)cancelButtonPressed:(id)sender {
    if (self.delegate && [self.delegate respondsToSelector:@selector(webImagePickerDidCancel:)]) {
        [self.delegate webImagePickerDidCancel:self];
    }
    
    if (self.cancelledBlock) {
        self.cancelledBlock(self);
    }
}

#pragma mark - UICollectionViewDataSource Methods

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    return self.images.count;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    UICollectionViewCell *cell = nil;
    cell = [collectionView dequeueReusableCellWithReuseIdentifier:identifier forIndexPath:indexPath];
    
    if (!cell) {
        cell = [[UICollectionViewCell alloc] init];
    }
    if (![cell.contentView viewWithTag:CellTagImageView]) {
        DACircularProgressView *progress = [[DACircularProgressView alloc] initWithFrame:CGRectZero];//CGRectMake(0, 0, 50, 50)];
        progress.thicknessRatio = 0.2;
        progress.tag = 7;
        
        UIImageView *image = [[UIImageView alloc] init];
        image.tag = CellTagImageView;
        [cell.contentView addSubview:image];

        image.contentMode = UIViewContentModeScaleAspectFill;
        image.clipsToBounds = YES;
        
        UIImageView *tickImage = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"EMWebImagePickerChecked"]];
        tickImage.hidden = YES;
        tickImage.tag = CellTagTickImageView;
        [cell.contentView addSubview:tickImage];
        cell.clipsToBounds = YES;
        
        UIView *superview = cell.contentView;
        NSDictionary *views = NSDictionaryOfVariableBindings(superview, image, tickImage, progress);
        
        [cell.contentView addSubview:progress];
        
        image.translatesAutoresizingMaskIntoConstraints = NO;
        [cell.contentView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|-0-[image]-0-|" options:0 metrics:nil views:views]];
        [cell.contentView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-0-[image]-0-|" options:0 metrics:nil views:views]];
        
        tickImage.translatesAutoresizingMaskIntoConstraints = NO;
        [cell.contentView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:[tickImage]-0-|" options:0 metrics:nil views:views]];
        [cell.contentView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-0-[tickImage]" options:0 metrics:nil views:views]];
        
        progress.translatesAutoresizingMaskIntoConstraints = NO;
        [cell.contentView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:[superview]-(<=1)-[progress(25)]"
                                                                                 options:NSLayoutFormatAlignAllCenterY
                                                                                 metrics:nil
                                                                                   views:views]];
        [cell.contentView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:[superview]-(<=1)-[progress(25)]"
                                                                                 options:NSLayoutFormatAlignAllCenterX
                                                                                 metrics:nil
                                                                                   views:views]];
    }
    
    EMWebImageModel *object = self.images[indexPath.row];
    
    if (object.selected) {
        [collectionView selectItemAtIndexPath:indexPath animated:NO scrollPosition:UICollectionViewScrollPositionNone];
    }
    
    NSURL *imageUrl = object.url;
    UIImageView *imageView = (UIImageView *)[cell.contentView viewWithTag:CellTagImageView];
    imageView.alpha = 0.0f;
    __weak UIImageView *wImageView = imageView;
    
    DACircularProgressView *progress = (DACircularProgressView *)[cell.contentView viewWithTag:7];
    progress.hidden = NO;
    progress.progress = 0;
    
    [imageView setImageWithURL:imageUrl placeholderImage:nil options:0 progress:^(NSInteger receivedSize, NSInteger expectedSize) {
        ((DACircularProgressView *)[wImageView.superview viewWithTag:7]).progress = (CGFloat)receivedSize / (CGFloat)expectedSize;
    } completed:^(UIImage *image, NSError *error, SDImageCacheType cacheType) {
        wImageView.alpha = 1.0f;
        progress.hidden = YES;
    }];
    
    UIImageView *tickImage = (UIImageView *)[cell.contentView viewWithTag:CellTagTickImageView];
    if (object.selected) {
        tickImage.hidden = NO;
    } else {
        tickImage.hidden = YES;
    }
    
    return cell;
}

- (void)contentAtBottom {
    
    BOOL canRecieve = NO;
    if (self.delegate && [self.delegate respondsToSelector:@selector(webImagePickerCanRecieveMoreContent:)]) {
        canRecieve = [self.delegate webImagePickerCanRecieveMoreContent:self];
    }
    if (canRecieve) {
        self.activityIndicator.hidden = NO;
        [self.activityIndicator startAnimating];
        
        if (self.delegate && [self.delegate respondsToSelector:@selector(webImagePickerRequestImagesForNextPage:)]) {
            NSArray *urls = [self cleanArray:[self.delegate webImagePickerRequestImagesForNextPage:self]];
            [self.images addObjectsFromArray:urls];
            [self.activityIndicator stopAnimating];
            [self.collectionView reloadData];
        } else if (self.delegate && [self.delegate respondsToSelector:@selector(webImagePickerRequestImagesForNextPage:withSuccess:failure:)]) {
            [self.delegate webImagePickerRequestImagesForNextPage:self withSuccess:^(NSArray *array) {
                [self.images addObjectsFromArray:[self cleanArray:array]];
                [self.activityIndicator stopAnimating];
                [self.collectionView reloadData];
            } failure:^(NSError *error) {
                NSLog(@"EMWebImageViewController Error");
            }];
        }
    }
}

#pragma mark - UICollectionViewDelegateFlowLayout

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath {
    return CGSizeMake(100, 100);
}

- (CGFloat)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout minimumLineSpacingForSectionAtIndex:(NSInteger)section {
    return 5;
}

- (CGFloat)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout minimumInteritemSpacingForSectionAtIndex:(NSInteger)section {
    return 5;
}

#pragma mark - UICollectionViewDelegate Methods

- (BOOL)collectionView:(UICollectionView *)collectionView shouldSelectItemAtIndexPath:(NSIndexPath *)indexPath {    
    EMWebImageModel *model = self.images[indexPath.row];
    if (model.selected) {
        return NO;
    }
    
    return YES;
}

- (BOOL)collectionView:(UICollectionView *)collectionView shouldDeselectItemAtIndexPath:(NSIndexPath *)indexPath {
    EMWebImageModel *model = self.images[indexPath.row];
    return model.selected;
}

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    UICollectionViewCell *cell = [collectionView cellForItemAtIndexPath:indexPath];
    
    if (!cell.isSelected) {
        [collectionView deselectItemAtIndexPath:indexPath animated:YES];
    } else {
        UIImageView *tickImage = (UIImageView *)[cell.contentView viewWithTag:CellTagTickImageView];
        tickImage.hidden = NO;
    }
    
    EMWebImageModel *model = self.images[indexPath.row];
    model.selected = YES;
    
    if (self.type == EMWebImagePickerTypeSingle) {
        self.selectedModel = model;
    }
}

- (void)collectionView:(UICollectionView *)collectionView didDeselectItemAtIndexPath:(NSIndexPath *)indexPath {
    UICollectionViewCell *cell = [collectionView cellForItemAtIndexPath:indexPath];
    
    UIImageView *tickImage = (UIImageView *)[cell.contentView viewWithTag:CellTagTickImageView];
    tickImage.hidden = YES;
    
    EMWebImageModel *model = self.images[indexPath.row];
    model.selected = NO;
    
    if (self.type == EMWebImagePickerTypeMultiple) {
        UIImageView *imageView = (UIImageView *)[cell.contentView viewWithTag:CellTagImageView];
        [self.selectedImages removeObject:imageView.image];
        NSURL *url = model.url;
        NSString *string = url.absoluteString;
        [self.selectedURLs removeObject:string];
    }
    
    if (self.type == EMWebImagePickerTypeSingle) {
        self.selectedModel.selected = NO;
        [self.collectionView reloadItemsAtIndexPaths:@[indexPath]];
    }
}

#pragma mark - UIScrollViewDelegate Methods

- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
    if (self.userDragging && self.pagingEnabled) {
        // Check if we are at the bottom.
        CGFloat bottom = scrollView.contentSize.height - [UIScreen mainScreen].bounds.size.height;
        if (scrollView.contentOffset.y >= bottom) {
            if (!self.activityIndicator.isAnimating) {
                [self contentAtBottom];
            }
        }
    }
}

- (void)scrollViewWillBeginDragging:(UIScrollView *)scrollView {
    self.userDragging = YES;
}

- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView {
    self.userDragging = NO;
}

- (void)scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate {
    self.userDragging = decelerate;
}

#pragma mark - Status Bar

- (UIStatusBarStyle)preferredStatusBarStyle {
    return UIStatusBarStyleDefault;
}

@end
