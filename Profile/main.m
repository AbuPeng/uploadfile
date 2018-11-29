//
//  main.m
//  Profile
//
//  Created by Snail on 2018/11/18.
//  Copyright © 2018 Snail. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>
#import "AFNetworking/AFNetworking.h"
#import "QiniuSDK.h"

#import "DMProgressHUD.h"

#import <AVFoundation/AVFoundation.h>
#import <PPNetWorking/PPNetWorking.h>


#define WinSize [UIScreen mainScreen].bounds.size
#define BaseColor [UIColor colorWithRed:243.0f/255.0f green:110.0f/255.0f blue:31.0f/255.0f alpha:1.0f]

//#define UrlString @"http://localhost/api"
#define UrlString @"http://media.powersenz.com/greattalk/public/api"

#define StatusBar_Height [[UIApplication sharedApplication] statusBarFrame].size.height

#define IS_NAV_NO_HEIGHT (self.navigationController.navigationBar.frame.size.height == 0.00)?YES:NO
#define NavBar_Height ((IS_NAV_NO_HEIGHT)?50:self.navigationController.navigationBar.frame.size.height)

#define TopBar_Height (StatusBar_Height + NavBar_Height)

#pragma mark - PPFileNetWorking interface
@interface PPFileNetWorking : NSObject

/**
 * 第一个参数:请求路径
 * 第二个参数:服务器规定请求目录
 * 第三个参数:服务器规定请求项目
 * 第四个参数:字典(非文件参数)向服务器传的值
 * 第五个参数:要传输的文件转换的NSData数据，二进制数据 要上传的文件参数
 * 第六个参数:服务规定的name
 * 第七个参数:定义要传输的文件名称
 * 第八个参数:文件的Type类型
 * 第九个参数:进度回调
 * 第十个参数:成功回调 responseObject响应体信息
 * 第十一个参数:失败回调
 */
- (void)uploadFileUrl:(NSString *)urlString
           controller:(NSString *)controller
               action:(NSString *)action
           parameters:(NSDictionary *)parameters
                 file:(NSData *)fileData
                 name:(NSString *)name
             fileName:(NSString *)fileName
             mimeType:(NSString *)mimeType
             progress:(void (^)(NSProgress * _Nonnull uploadProgress))pp_uploadProgress
              success:(void (^)(NSURLSessionDataTask * _Nonnull task, id _Nullable responseObject))pp_success
              failure:(void (^)(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error))pp_failure;

/**
 * 发送POST请求
 */
- (void)networkPOSTWithUrl:(NSString *)urlString
                controller:(NSString *)controller
                    action:(NSString *)action
                parameters:(NSDictionary *)parameters
                   success:(void (^)(NSURLSessionDataTask * _Nonnull task, id _Nullable responseObject))pp_success
                   failure:(void (^)(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error))pp_failure;

/**
 * PPNetWork发送POST请求
 */
- (void)PPFWnetworkPOSTWithUrl:(NSString *)urlString
                    controller:(NSString *)controller
                        action:(NSString *)action
                    parameters:(NSDictionary *)parameters
                       success:(void (^)(id responseObject))pp_success
                       failure:(void (^)(id error))pp_failure;
@end

#pragma mark - UIButton(Create) interface

@interface UIButton (Create)
+ (UIButton *)setButtonWithFrame:(CGRect)frame center:(CGPoint)point backGroundColor:(UIColor *)backgroundcolor title:(NSString *)title font:(UIFont *)font titleColor:(UIColor *)titlecolor;
@end

#pragma mark - ProfileViewController interface
@interface ProfileViewController : UIViewController

@end

#pragma mark - ImagePreviewViewController interface
@interface ImagePreviewViewController : UIViewController
- (instancetype)initWithFilePath:(NSString *)filePath;
@end


#pragma mark - PAppDelegate interface
@interface PAppDelegate : UIResponder <UIApplicationDelegate>

@property (strong, nonatomic) UIWindow *window;
@property (strong, nonatomic) ProfileViewController * pfViewController;
@end

#pragma mark - TmpListViewController interface
typedef void (^TmpListFilePressHandler)(NSString * fileString);
@interface TmpListViewController : UIViewController
@property (nonatomic, copy) TmpListFilePressHandler tmpFileHandler;

- (void)fileNameSelect:(TmpListFilePressHandler)fileNameHandler;
@end

#pragma mark - UploadViewController interface
@interface UploadViewController : UIViewController
@property(strong ,nonatomic)NSString * name;
@property(strong ,nonatomic)NSString * fileName;
@property(strong ,nonatomic)NSString * mimeType;

@property(strong ,nonatomic)NSString * bucket;

@end


#pragma mark - PAppDelegate
@implementation PAppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    // Override point for customization after application launch.
    _window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen]bounds]];
    [self makeMainViewController];
    [_window makeKeyAndVisible];
    return YES;
}

- (void)makeMainViewController{
    _pfViewController = [[ProfileViewController alloc] init];
    _pfViewController.view.frame = CGRectMake(0, 0, WinSize.width, WinSize.height);
    UINavigationController * profileVNC = [[UINavigationController alloc] initWithRootViewController:_pfViewController];
    [profileVNC.navigationBar setTitleTextAttributes:@{NSForegroundColorAttributeName : BaseColor}];
    [_window setRootViewController:profileVNC];
}

@end

#pragma mark - ProfileViewController
@interface ProfileViewController()<UITextFieldDelegate,UIPickerViewDelegate,UIPickerViewDataSource>

//UI部分
@property (strong, nonatomic)UIControl * backView;
@property (strong, nonatomic)UITextField * fileNameField;
@property (strong, nonatomic)UIPickerView * fileTypePicker;
@property (strong, nonatomic)UILabel * filemimetypeLbl;
@property (strong, nonatomic)UIButton * uploadQiniuButton;

//数据部分
@property (strong, nonatomic)NSString * fileName;//文件名称 如：123.mp3
@property (strong, nonatomic)NSString * name;//和服务器约定的名称规则，如audio、image、video
@property (strong, nonatomic)NSString * mimeType;//文件的mimetype 如 image/jpg, image/png等

@property (strong, nonatomic)NSArray * pickerArray;

@property (strong, nonatomic)UIButton * previewImageButton;
@end

@implementation ProfileViewController

- (void)initNavigation
{
    self.title = @"七牛文件上传";
    UIButton * showTmpPath = [UIButton setButtonWithFrame:CGRectMake(0, 0, 70, 40)
                                                                center:CGPointMake(40, 70)
                                                       backGroundColor:BaseColor
                                                                 title:@"Tmp路径"
                                                                  font:[UIFont fontWithName:@"Arial" size:15.0f]
                                                            titleColor:[UIColor whiteColor]
                              ];
    
    [showTmpPath addTarget:self action:@selector(showTmpPathPress) forControlEvents:UIControlEventTouchUpInside];
    UIBarButtonItem * rightBackBarButtonItem = [[UIBarButtonItem alloc] initWithCustomView:showTmpPath];
    self.navigationItem.rightBarButtonItem = rightBackBarButtonItem;
    
    UIButton * getTmpList = [UIButton setButtonWithFrame:CGRectMake(0, 0, 70, 40)
                                                               center:CGPointMake(40, 70)
                                                      backGroundColor:BaseColor
                                                                title:@"Tmp列表"
                                                                 font:[UIFont fontWithName:@"Arial" size:15.0f]
                                                           titleColor:[UIColor whiteColor]
                             ];
    
    [getTmpList addTarget:self action:@selector(tmpListVCShow) forControlEvents:UIControlEventTouchUpInside];
    UIBarButtonItem * leftBackBarButtonItem = [[UIBarButtonItem alloc] initWithCustomView:getTmpList];
    self.navigationItem.leftBarButtonItem = leftBackBarButtonItem;
}

- (void)viewDidLoad{
    [super viewDidLoad];
    
    [self.view setBackgroundColor:[UIColor whiteColor]];

    self.pickerArray = [[NSArray alloc] initWithObjects:@"图片",@"音频",@"视频",@"其他文件", nil];
    
    [self initNavigation];
    [self createView];
    
    self.name = @"image";
    self.mimeType = @"image/jpeg";
    
}

- (void)createView{
    
    //创建背景
    _backView = [[UIControl alloc] initWithFrame:CGRectMake(0, 0, WinSize.width, WinSize.height)];
    [_backView setBackgroundColor:[UIColor clearColor]];
    [_backView addTarget:self action:@selector(keyBoardHidden:) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:_backView];
    
    //创建输入框
    self.fileNameField = [[UITextField alloc] initWithFrame:CGRectMake(10, 120, WinSize.width-10, 50)];
    [self.fileNameField setFont:[UIFont systemFontOfSize:17.0f]];
    [self.fileNameField setBackgroundColor:[UIColor clearColor]];
    [self.fileNameField setReturnKeyType:UIReturnKeySend];
    [self.fileNameField setAutocapitalizationType:UITextAutocapitalizationTypeNone];
    [self.fileNameField setAutocorrectionType:UITextAutocorrectionTypeNo];
    [self.fileNameField setDelegate:self];
    [self.fileNameField setPlaceholder:@"请输入要上传的文件名称"];
    [self.fileNameField setTextColor:BaseColor];
    [self.backView addSubview:self.fileNameField];
    //创建输入框下划线
    UIView * lineView = [[UIView alloc] initWithFrame:CGRectMake(CGRectGetMinX(self.fileNameField.frame), CGRectGetMaxY(self.fileNameField.frame)+2, CGRectGetWidth(self.fileNameField.frame), 1)];
    [lineView setBackgroundColor:BaseColor];
    [self.backView addSubview:lineView];
    
    self.filemimetypeLbl = [[UILabel alloc] initWithFrame:CGRectMake(10, CGRectGetMaxY(lineView.frame)+20, WinSize.width-20, 70)];
    [self.filemimetypeLbl setFont:[UIFont fontWithName:@"Arial" size:18.0f]];
    [self.filemimetypeLbl setTextColor:BaseColor];
    [self.filemimetypeLbl setTextAlignment:NSTextAlignmentCenter];
    [self.filemimetypeLbl setBackgroundColor:[UIColor clearColor]];
    [self.filemimetypeLbl setText:@"显示所选文件的MIMEType"];
    [self.backView addSubview:self.filemimetypeLbl];
    [self.filemimetypeLbl.layer setMasksToBounds:YES];
    [self.filemimetypeLbl.layer setBorderWidth:1.0f];
    [self.filemimetypeLbl.layer setBorderColor:BaseColor.CGColor];
    [self.filemimetypeLbl.layer setCornerRadius:10.0f];
    
    //创建文件类型选择器
    self.fileTypePicker = [[UIPickerView alloc] initWithFrame:CGRectMake(10, CGRectGetMaxY(self.filemimetypeLbl.frame)+20, WinSize.width-20, 162)];
    [self.fileTypePicker setDelegate:self];
    [self.fileTypePicker setDataSource:self];
    [self.fileTypePicker setBackgroundColor:[UIColor whiteColor]];
    [self.backView addSubview:self.fileTypePicker];
    [self.fileTypePicker reloadAllComponents];//刷新UIPickerView
    [self.fileTypePicker.layer setMasksToBounds:YES];
    [self.fileTypePicker.layer setBorderWidth:1.0f];
    [self.fileTypePicker.layer setBorderColor:BaseColor.CGColor];
    [self.fileTypePicker.layer setCornerRadius:10.0f];
    
    self.uploadQiniuButton = [UIButton setButtonWithFrame:CGRectMake(0, 0, WinSize.width - 20, 50)
                                                           center:CGPointMake(WinSize.width/2, CGRectGetMaxY(self.fileTypePicker.frame)+50)
                                                  backGroundColor:[UIColor whiteColor]
                                                            title:@"Qiniu上传文件"
                                                             font:[UIFont fontWithName:@"Arial" size:20.0f]
                                                       titleColor:BaseColor];
    [self.uploadQiniuButton addTarget:self action:@selector(qiniuUploadPress:) forControlEvents:UIControlEventTouchUpInside];
    [self.backView addSubview:self.uploadQiniuButton];
    
    
    self.previewImageButton = [UIButton setButtonWithFrame:CGRectMake(0, 0, WinSize.width - 20, 50)
                                                   center:CGPointMake(WinSize.width/2, CGRectGetMaxY(self.uploadQiniuButton.frame)+50)
                                          backGroundColor:[UIColor whiteColor]
                                                    title:@"预览图片文件"
                                                     font:[UIFont fontWithName:@"Arial" size:20.0f]
                                               titleColor:BaseColor];
    [self.previewImageButton addTarget:self action:@selector(previewImageButtonPress:) forControlEvents:UIControlEventTouchUpInside];
    [self.previewImageButton setHidden:YES];
    [self.backView addSubview:self.previewImageButton];
}

- (void)previewImageButtonPress:(id)sender{
    NSString *tmpDir = NSTemporaryDirectory();
    NSString *filePath = [tmpDir stringByAppendingPathComponent:self.fileName];
    ImagePreviewViewController * imagePVC = [[ImagePreviewViewController alloc] initWithFilePath:filePath];
    [self presentViewController:imagePVC animated:YES completion:nil];
}

- (void)keyBoardHidden:(id)sender{
    [self.fileNameField resignFirstResponder];
    self.fileName = self.fileNameField.text;
}

#pragma mark - textFieldDelegate
- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
    if (textField == self.fileNameField) {
        [self keyBoardHidden:nil];
    }
    return YES;
}

#pragma mark - pickerViewDatasource

- (NSInteger)numberOfComponentsInPickerView:(UIPickerView *)pickerView
{
    return 1;
}

- (NSInteger)pickerView:(UIPickerView *)pickerView numberOfRowsInComponent:(NSInteger)component
{
    return [self.pickerArray count];
}

#pragma mark - pickerViewDelegate

- (CGFloat)pickerView:(UIPickerView *)pickerView rowHeightForComponent:(NSInteger)component
{
    return 40.0f;
}

// 自定义指定列的每行的视图，即指定列的每行的视图行为一致

- (UIView *)pickerView:(UIPickerView *)pickerView viewForRow:(NSInteger)row forComponent:(NSInteger)component reusingView:(UIView *)view{
    if (!view){
        view = [[UIView alloc] initWithFrame:CGRectMake(0, 0, WinSize.width - 20, 40)];
    }
    UILabel * pickerLbl = [[UILabel alloc]initWithFrame:CGRectMake(0, 0, WinSize.width - 40, 40)];
    [pickerLbl setCenter:CGPointMake(CGRectGetMidX(view.frame), CGRectGetMidY(view.frame))];
    [pickerLbl setTextAlignment:NSTextAlignmentCenter];
    [pickerLbl setText:[self.pickerArray objectAtIndex:row]];
    [pickerLbl setFont:[UIFont fontWithName:@"Arial" size:25.0f]];
    [pickerLbl setTextColor:BaseColor];
    [view addSubview:pickerLbl];
    
    //隐藏上下直线
    [self.fileTypePicker.subviews objectAtIndex:1].backgroundColor = BaseColor;//[UIColor clearColor];
    [self.fileTypePicker.subviews objectAtIndex:2].backgroundColor = BaseColor;//[UIColor clearColor];
    return view;
    
}

//显示的标题
- (NSString *)pickerView:(UIPickerView *)pickerView titleForRow:(NSInteger)row forComponent:(NSInteger)component{
    NSString * titleString = [self.pickerArray objectAtIndex:row];
    return titleString;
}

//被选择的行
-(void)pickerView:(UIPickerView *)pickerView didSelectRow:(NSInteger)row inComponent:(NSInteger)component{
    if ([self.filemimetypeLbl.text isEqualToString:@""] || self.filemimetypeLbl.text == nil) {
        if ([[self.pickerArray objectAtIndex:row] isEqualToString:@"图片"]) {
            self.name = @"image";
            self.mimeType = @"image/jpeg";
            [self.previewImageButton setHidden:NO];
        }
        else if([[self.pickerArray objectAtIndex:row] isEqualToString:@"音频"]){
            self.name = @"audio";
            self.mimeType = @"audio/mp3";
            [self.previewImageButton setHidden:YES];
        }
        else if([[self.pickerArray objectAtIndex:row] isEqualToString:@"视频"]){
            self.name = @"video";
            self.mimeType = @"video/mp4";
            [self.previewImageButton setHidden:YES];
        }
        else if([[self.pickerArray objectAtIndex:row] isEqualToString:@"其他文件"]){
            self.name = @"other";
            self.mimeType = @"application/octet-stream";
            [self.previewImageButton setHidden:YES];
        }
    }
}

#pragma mark - 上传事件
- (void)uploadPress:(id)sender{
    NSLog(@"点击上传");
    [self keyBoardHidden:nil];
    if (self.fileName == nil || [self.fileName isEqualToString:@""]) {
        UIAlertController * alertVC = [UIAlertController alertControllerWithTitle:@"输入文件名" message:nil preferredStyle:UIAlertControllerStyleAlert];
        UIAlertAction * actionCancel = [UIAlertAction actionWithTitle:@"确定" style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
            
        }];
        [alertVC addAction:actionCancel];
        [self presentViewController:alertVC animated:YES completion:nil];
    }
    else if ([self.name isEqualToString:@""] || self.name == nil || self.mimeType == nil || [self.mimeType isEqualToString:@""])
    {
        UIAlertController * alertVC = [UIAlertController alertControllerWithTitle:@"选择文件类型" message:nil preferredStyle:UIAlertControllerStyleAlert];
        UIAlertAction * actionCancel = [UIAlertAction actionWithTitle:@"确定" style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
            
        }];
        [alertVC addAction:actionCancel];
        [self presentViewController:alertVC animated:YES completion:nil];
    }
    else
    {
        NSString *tmpDir = NSTemporaryDirectory();
        NSString *filePath = [tmpDir stringByAppendingPathComponent:self.fileName];
        NSFileManager* fm = [NSFileManager defaultManager];
        NSData* filedata = [[NSData alloc] init];
        if ([self.name isEqualToString:@"image"]) {
            UIImage * image = [UIImage imageWithContentsOfFile:filePath];
            image = [self fixOrientation:image];
            filedata = UIImageJPEGRepresentation(image, 1.0f);
        }
        else
        {
            filedata = [fm contentsAtPath:filePath];
        }
        NSMutableDictionary * dic = [NSMutableDictionary new];
        [dic setObject:self.name forKey:@"file_type"];
        PPFileNetWorking * fileNetWorking = [[PPFileNetWorking alloc] init];
        [fileNetWorking uploadFileUrl:UrlString controller:@"profile" action:@"qiniuupload" parameters:dic file:filedata name:self.name fileName:self.fileName mimeType:self.mimeType progress:^(NSProgress * _Nonnull uploadProgress) {
            NSLog(@"%f",1.0 * uploadProgress.completedUnitCount / uploadProgress.totalUnitCount);
            
        } success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
            
            NSLog(@"上传成功.%@",responseObject);
            
        } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
            NSLog(@"上传失败.%@",error);
            
        }];
    }
}
#pragma mark - Qiniu上传事件
- (void)qiniuUploadPress:(id)sender{
    if ([self.fileName isEqualToString:@""] || self.fileName == nil) {
        
    }
    else if ([self.mimeType isEqualToString:@""] || self.mimeType == nil)
    {
        
    }
    else
    {
        NSString *tmpDir = NSTemporaryDirectory();
        NSString *filePath = [tmpDir stringByAppendingPathComponent:self.fileName];
        [self NSURLSessionGetMIMETypeWithPath:filePath mimeType:^(NSString *MIMEType) {
            self.mimeType = MIMEType;
            dispatch_async(dispatch_get_main_queue(), ^{
                NSLog(@"%@",self.fileName);
                UploadViewController * uploadVC = [[UploadViewController alloc] init];
                [uploadVC setName:self.name];
                [uploadVC setFileName:self.fileName];
                [uploadVC setMimeType:self.mimeType];
                [uploadVC setBucket:@"greattalk"];
                [self.navigationController pushViewController:uploadVC animated:YES];
            });
        }];
    }
}

- (void)NSURLSessionGetMIMETypeWithPath:(NSString *)path mimeType:(nullable void(^)(NSString * MIMEType))mimeType{
    NSURL * url = [NSURL fileURLWithPath:path];
    NSMutableURLRequest * request = [NSMutableURLRequest requestWithURL:url];
    NSURLSession * session = [NSURLSession sharedSession];
    NSURLSessionDataTask * dataTask = [session dataTaskWithRequest:request completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
        if (mimeType) {
            mimeType(response.MIMEType);
        }
    }];
    [dataTask resume];
}

/***************  图片处理,此方法解决了, (手机竖屏拍照,图片会横倒的问题)  *****************/

- (UIImage *)fixOrientation:(UIImage *)aImage {
    if (aImage.imageOrientation ==UIImageOrientationUp)
    {
        return aImage;
    }
    CGAffineTransform transform =CGAffineTransformIdentity;
    switch (aImage.imageOrientation) {
        case UIImageOrientationDown:
        case UIImageOrientationDownMirrored:
            transform = CGAffineTransformTranslate(transform, aImage.size.width, aImage.size.height);
            transform = CGAffineTransformRotate(transform,M_PI);
            break;
        case UIImageOrientationLeft:
        case UIImageOrientationLeftMirrored:
            transform = CGAffineTransformTranslate(transform, aImage.size.width,0);
            transform = CGAffineTransformRotate(transform,M_PI_2);
            break;
        case UIImageOrientationRight:
        case UIImageOrientationRightMirrored:
            transform = CGAffineTransformTranslate(transform,0, aImage.size.height);
            transform = CGAffineTransformRotate(transform, -M_PI_2);
            break;
        default:
            break;
    }
    
    switch (aImage.imageOrientation) {
        case UIImageOrientationUpMirrored:
        case UIImageOrientationDownMirrored:
            transform = CGAffineTransformTranslate(transform, aImage.size.width,0);
            transform = CGAffineTransformScale(transform, -1,1);
            break;
        case UIImageOrientationLeftMirrored:
        case UIImageOrientationRightMirrored:
            transform = CGAffineTransformTranslate(transform, aImage.size.height,0);
            transform = CGAffineTransformScale(transform, -1,1);
            break;
        default:
            break;
    }
    CGContextRef ctx = CGBitmapContextCreate(NULL,aImage.size.width,aImage.size.height,CGImageGetBitsPerComponent(aImage.CGImage),0,CGImageGetColorSpace(aImage.CGImage),CGImageGetBitmapInfo(aImage.CGImage));
    
        CGContextConcatCTM(ctx, transform);
    switch (aImage.imageOrientation) {
        case UIImageOrientationLeft:
            break;
        case UIImageOrientationLeftMirrored:
            break;
        case UIImageOrientationRight:
            break;
        case UIImageOrientationRightMirrored:
            // Grr...
            CGContextDrawImage(ctx,CGRectMake(0,0,aImage.size.height,aImage.size.width), aImage.CGImage);
            break;
        default:
            CGContextDrawImage(ctx,CGRectMake(0,0,aImage.size.width,aImage.size.height), aImage.CGImage);
            break;
    }
    // And now we just create a new UIImage from the drawing context
    CGImageRef cgimg =CGBitmapContextCreateImage(ctx);
    UIImage *img = [UIImage imageWithCGImage:cgimg];
    CGContextRelease(ctx);
    CGImageRelease(cgimg);
    return img;
}

/****************************************** Navigation Item 点击事件  **********************************************/
- (void)showTmpPathPress{
    NSLog(@"show tmp path");
    NSString *tmpDir = NSTemporaryDirectory();
    UIAlertController * alertVC = [UIAlertController alertControllerWithTitle:@"TMP路径" message:tmpDir preferredStyle:UIAlertControllerStyleAlert];
    UIAlertAction * actionCancel = [UIAlertAction actionWithTitle:@"确定" style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
        
    }];
    [alertVC addAction:actionCancel];
    [self presentViewController:alertVC animated:YES completion:nil];
}

- (void)tmpListVCShow{
    TmpListViewController * tmpListVC = [[TmpListViewController alloc] init];
    [self.navigationController pushViewController:tmpListVC animated:YES];
    [tmpListVC fileNameSelect:^(NSString *fileString) {
        NSLog(@"%@",fileString);
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.fileNameField setText:fileString];
            self.fileName = [NSString stringWithFormat:@"%@",self.fileNameField.text];
            NSString *tmpDir = NSTemporaryDirectory();
            NSString *filePath = [tmpDir stringByAppendingPathComponent:self.fileName];
            [self NSURLSessionGetMIMETypeWithPath:filePath mimeType:^(NSString *MIMEType) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    [self.filemimetypeLbl setText:MIMEType];
                    self.mimeType = MIMEType;
                    if ([MIMEType isEqualToString:@"image/jpeg"] || [MIMEType isEqualToString:@"image/png"] || [MIMEType isEqualToString:@"image/gif"]) {
                        self.name = @"image";
                        [self.fileTypePicker selectRow:0 inComponent:0 animated:YES];
                        [self.previewImageButton setHidden:NO];
                    }
                    else if ([MIMEType isEqualToString:@"audio/mpeg"]) {
                        self.name = @"audio";
                        [self.fileTypePicker selectRow:1 inComponent:0 animated:YES];
                        [self.previewImageButton setHidden:YES];
                    }
                    else if ([MIMEType isEqualToString:@"video/mp4"]) {
                        self.name = @"video";
                        [self.fileTypePicker selectRow:2 inComponent:0 animated:YES];
                        [self.previewImageButton setHidden:YES];
                    }
                    else{
                        self.name = @"other";
                        [self.fileTypePicker selectRow:3 inComponent:0 animated:YES];
                        [self.previewImageButton setHidden:YES];
                    }
                });
            }];
        });
    }];
}

- (void)getTmpAllFileAndFolder{
    NSFileManager *fileManager = [NSFileManager defaultManager];
    //在这里获取应用程序Documents文件夹里的文件及文件夹列表
    //NSArray *documentPaths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    //NSString *documentDir = [documentPaths objectAtIndex:0];
    NSString *tmpDir = NSTemporaryDirectory();
//    NSString *lesson_1Dir = [tmpDir stringByAppendingPathComponent:@"lesson_1"];

    NSString * pathDir = tmpDir;
    
    NSError *error = nil;
    NSArray *fileList = [[NSArray alloc] init];
    //fileList便是包含有该文件夹下所有文件的文件名及文件夹名的数组
    fileList = [fileManager contentsOfDirectoryAtPath:pathDir error:&error];
    //以下这段代码则可以列出给定一个文件夹里的所有子文件名
    NSMutableArray *fileArray = [[NSMutableArray alloc] init];
    //以下这段代码则可以列出给定一个文件夹里的所有子文件夹名
    NSMutableArray *folderArray = [[NSMutableArray alloc] init];
    BOOL isDir = NO;
    //在上面那段程序中获得的fileList中列出文件夹名
    for (NSString *file in fileList) {
        NSString *path = [pathDir stringByAppendingPathComponent:file];
        [fileManager fileExistsAtPath:path isDirectory:(&isDir)];
        if (isDir) {
            [folderArray addObject:file];
        }else
        {
            [fileArray addObject:file];
        }
        isDir = NO;
    }
    NSLog(@"All folders:%@ \nAll files:%@",folderArray,fileArray);
}

@end

#pragma mark - UIButton (Create)
@implementation UIButton (Create)

+ (UIButton *)setButtonWithFrame:(CGRect)frame center:(CGPoint)point backGroundColor:(UIColor *)backgroundcolor title:(NSString *)title font:(UIFont *)font titleColor:(UIColor *)titlecolor{
    UIButton * button = [UIButton buttonWithType:UIButtonTypeCustom];
    [button setFrame:frame];
    [button setCenter:point];
    [button setBackgroundColor:backgroundcolor];
    [button setTitle:title forState:UIControlStateNormal];
    [button.titleLabel setFont:font];
    [button setTitleColor:titlecolor forState:UIControlStateNormal];
    [button setTitleColor:[UIColor grayColor] forState:UIControlStateSelected];
    [button setTitleColor:[UIColor grayColor] forState:UIControlStateHighlighted];
    
    [button.layer setMasksToBounds:YES];
    [button.layer setCornerRadius:4.0f];
    [button.layer setBorderWidth:1.0f];
    [button.layer setBorderColor:BaseColor.CGColor];
    return button;
}


@end

#pragma mark - PPFileNetWorking

@interface PPFileNetWorking()
@end

@implementation PPFileNetWorking

- (instancetype)init
{
    self = [super init];
    if (self) {
        
    }
    return self;
}

- (void)networkPOSTWithUrl:(NSString *)urlString
        controller:(NSString *)controller
            action:(NSString *)action
        parameters:(NSDictionary *)parameters
           success:(void (^)(NSURLSessionDataTask * _Nonnull task, id _Nullable responseObject))pp_success
           failure:(void (^)(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error))pp_failure{
    NSString * url = [NSString stringWithFormat:@"%@/%@/%@?",urlString,controller,action];
    
    AFHTTPSessionManager *manager = [AFHTTPSessionManager manager];
    // 设置超时时间
//    [manager.requestSerializer willChangeValueForKey:@"timeoutInterval"];
//    manager.requestSerializer.timeoutInterval = 60.f;
//    [manager.requestSerializer didChangeValueForKey:@"timeoutInterval"];
    //申明请求的数据类型设置
    manager.requestSerializer=[AFHTTPRequestSerializer serializer];
    //返回数据类型设置
    manager.responseSerializer = [AFHTTPResponseSerializer serializer];
    manager.responseSerializer.acceptableContentTypes = [NSSet setWithObjects:@"text/html",@"text/plain",@"application/json",@"text/json",@"text/xml", @"text/javascript" ,nil];
    [manager POST:url parameters:parameters headers:nil constructingBodyWithBlock:^(id<AFMultipartFormData>  _Nonnull formData) {
        
    } progress:^(NSProgress * _Nonnull uploadProgress) {
        
    } success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
        if (pp_success) {
            pp_success(task,responseObject);
        }
    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
        if (pp_failure) {
            pp_failure(task,error);
        }
    }];
//    [manager POST:url parameters:parameters progress:nil success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
//        if (pp_success) {
//            pp_success(task,responseObject);
//        }
//    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
//        if (pp_failure) {
//            pp_failure(task,error);
//        }
//    }];

}

- (void)PPFWnetworkPOSTWithUrl:(NSString *)urlString
                    controller:(NSString *)controller
                        action:(NSString *)action
                    parameters:(NSDictionary *)parameters
                       success:(void (^)(id responseObject))pp_success
                       failure:(void (^)(id error))pp_failure{
    PPNetWorking * logoutNet = [[PPNetWorking alloc] init];
    [logoutNet PostRequestWithUrlNetWork:urlString Controller:controller action:action parameter:parameters resultBlock:^(id resultValue) {
        if (pp_success) {
            pp_success(resultValue);
        }
    } errorBlock:^(id errorCode) {
        if (pp_failure) {
            pp_failure(errorCode);
        }
    }];
}

- (void)uploadFileUrl:(NSString *)urlString
           controller:(NSString *)controller
               action:(NSString *)action
           parameters:(NSDictionary *)parameters
                 file:(NSData *)fileData
                 name:(NSString *)name
             fileName:(NSString *)fileName
             mimeType:(NSString *)mimeType
             progress:(void (^)(NSProgress * _Nonnull uploadProgress))pp_uploadProgress
              success:(void (^)(NSURLSessionDataTask * _Nonnull task, id _Nullable responseObject))pp_success
              failure:(void (^)(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error))pp_failure

{
    NSString * url = [NSString stringWithFormat:@"%@/%@/%@?",urlString,controller,action];
    
    //创建会话管理者
    AFHTTPSessionManager *manager = [AFHTTPSessionManager manager];
    // 添加这句代码
    manager.responseSerializer.acceptableContentTypes = [NSSet setWithObjects:@"text/plain", @"multipart/form-data", @"application/json", @"text/html", @"image/jpeg", @"image/png", @"application/octet-stream", @"text/json", nil];
    //发送post请求上传路径
    /*
     第一个参数:请求路径
     第二个参数:字典(非文件参数)
     第三个参数:constructingBodyWithBlock 处理要上传的文件数据
     第四个参数:进度回调
     第五个参数:成功回调 responseObject响应体信息
     第六个参数:失败回调
     @{@"AaB03x":@"Content-Type"}
     */
    
    [manager POST:url parameters:parameters constructingBodyWithBlock:^(id<AFMultipartFormData>  _Nonnull formData) {
        //使用formData拼接数据
        /*
         第一个参数:二进制数据 要上传的文件参数
         第二个参数:name 服务器规定的
         第三个参数:文件上传到服务器以什么名称保存
         */
        [formData appendPartWithFileData:fileData name:name fileName:fileName mimeType:mimeType];
    } progress:^(NSProgress * _Nonnull uploadProgress) {
        if (pp_uploadProgress) {
            pp_uploadProgress(uploadProgress);
        }
    } success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
        if (pp_success) {
            pp_success(task,responseObject);
        }
    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
        if (pp_failure) {
            pp_failure(task,error);
        }
    }];
}
@end


#pragma mark - TmpListViewCell

@interface TmpListViewCell : UITableViewCell

@property (strong, nonatomic) UIView * bgView;
@property (strong, nonatomic) UILabel * fileNameLbl;

- (void)setFileName:(NSString *)fileName;
@end

@implementation TmpListViewCell
@synthesize bgView;
@synthesize fileNameLbl;

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        [self setSelectionStyle:UITableViewCellSelectionStyleGray];
        self.backgroundColor = [UIColor clearColor];
        CGRect frame = self.frame;
        frame.size.width = WinSize.width;
        frame.size.height = 45;
        self.frame = frame;
        
        
        bgView = [[UIView alloc] initWithFrame:self.bounds];
        [bgView setBackgroundColor:[UIColor clearColor]];
        [self addSubview:bgView];
        
        fileNameLbl = [[UILabel alloc] initWithFrame:CGRectMake(10, 0, WinSize.width - 20, frame.size.height)];
        [fileNameLbl setFont:[UIFont fontWithName:@"Arial" size:18.0f]];
        [fileNameLbl setTextColor:BaseColor];
        [fileNameLbl setTextAlignment:NSTextAlignmentLeft];
        [fileNameLbl setNumberOfLines:0];
        [self.bgView addSubview:fileNameLbl];

        UIView * lineView = [[UIView alloc] initWithFrame:CGRectMake(0, frame.size.height, WinSize.width, 1)];
        [lineView setBackgroundColor:BaseColor];
        [self.bgView addSubview:lineView];
    }
    return self;
}

- (void)setFileName:(NSString *)fileName{
    [fileNameLbl setText:fileName];
}

@end


#pragma mark - TmpListViewController

@interface TmpListViewController()<UITableViewDelegate,UITableViewDataSource>
@property (strong, nonatomic)UITableView * fileTableView;
@property (strong, nonatomic)NSMutableArray * fileListArray;
@end

@implementation TmpListViewController
@synthesize fileTableView;

- (void)initNavigation
{
    self.title = @"选择文件";
    UIButton * refreshBtn = [UIButton setButtonWithFrame:CGRectMake(0, 0, 70, 40)
                                                                center:CGPointMake(40, 70)
                                                       backGroundColor:BaseColor
                                                                 title:@"刷新"
                                                                  font:[UIFont fontWithName:@"Arial" size:15.0f]
                                                            titleColor:[UIColor whiteColor]
                              ];
    
    [refreshBtn addTarget:self action:@selector(refreshFileList) forControlEvents:UIControlEventTouchUpInside];
    UIBarButtonItem * rightBackBarButtonItem = [[UIBarButtonItem alloc] initWithCustomView:refreshBtn];
    self.navigationItem.rightBarButtonItem = rightBackBarButtonItem;
    
    UIButton * backBtn = [UIButton setButtonWithFrame:CGRectMake(0, 0, 70, 40)
                                                               center:CGPointMake(40, 70)
                                                      backGroundColor:BaseColor
                                                                title:@"返回"
                                                                 font:[UIFont fontWithName:@"Arial" size:15.0f]
                                                           titleColor:[UIColor whiteColor]
                             ];
    
    [backBtn addTarget:self action:@selector(backButtonPress) forControlEvents:UIControlEventTouchUpInside];
    UIBarButtonItem * leftBackBarButtonItem = [[UIBarButtonItem alloc] initWithCustomView:backBtn];
    self.navigationItem.leftBarButtonItem = leftBackBarButtonItem;
}

- (void)viewDidLoad{
    [super viewDidLoad];
    
    [self.view setBackgroundColor:[UIColor whiteColor]];

    [self initNavigation];
    self.fileListArray = [[NSMutableArray alloc] init];
    
    [self createView];
}

- (void)refreshFileList{
    [self.fileListArray removeAllObjects];
    [self getFileList];
}

- (void)backButtonPress{
    [self.navigationController popViewControllerAnimated:YES];
}

- (void)createView{
    self.fileTableView = [[UITableView alloc] initWithFrame:CGRectMake(0, TopBar_Height, WinSize.width, WinSize.height - TopBar_Height) style:UITableViewStylePlain];
    [self.fileTableView setBackgroundView:nil];
    [self.fileTableView setBackgroundColor:[UIColor clearColor]];
    [self.fileTableView setDelegate:self];
    [self.fileTableView setDataSource:self];
    [self.fileTableView setSeparatorColor:[UIColor clearColor]];
    [self.fileTableView setSeparatorStyle:UITableViewCellSeparatorStyleNone];
    [self.fileTableView setShowsHorizontalScrollIndicator:NO];
    [self.fileTableView setShowsVerticalScrollIndicator:NO];
    [self.view addSubview:self.fileTableView];
    [self.fileTableView reloadData];
    
    [self getFileList];

}

#pragma mark - tableViewDelegate

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{
    return [self.fileListArray count];
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(nonnull NSIndexPath *)indexPath{
    TmpListViewCell * tmpListCell = (TmpListViewCell *)[self tableView:self.fileTableView cellForRowAtIndexPath:indexPath];
    return tmpListCell.frame.size.height;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
    static NSString * cellIdentifier = @"EditDatumCell";
    TmpListViewCell * tmpListCell = (TmpListViewCell *)[tableView dequeueReusableCellWithIdentifier:cellIdentifier];
    if (tmpListCell == nil) {
        tmpListCell = [[TmpListViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cellIdentifier];
    }
    
    [tmpListCell setFileName:[NSString stringWithFormat:@"%@",[self.fileListArray objectAtIndex:indexPath.row]]];
    
    return tmpListCell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:NO];
    
    if (self.tmpFileHandler) {
        self.tmpFileHandler([NSString stringWithFormat:@"%@",[self.fileListArray objectAtIndex:indexPath.row]]);
        [self backButtonPress];
    }
}

- (void)fileNameSelect:(TmpListFilePressHandler)fileNameHandler
{
    self.tmpFileHandler = fileNameHandler;
}

- (void)getFileList{
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSString *tmpDir = NSTemporaryDirectory();
    NSString * pathDir = tmpDir;
    NSError *error = nil;
    NSArray *fileList = [[NSArray alloc] init];
    fileList = [fileManager contentsOfDirectoryAtPath:pathDir error:&error];
    NSMutableArray *fileArray = [[NSMutableArray alloc] init];
    NSMutableArray *folderArray = [[NSMutableArray alloc] init];
    BOOL isDir = NO;
    //在上面那段程序中获得的fileList中列出文件夹名
    for (NSString *file in fileList) {
        NSString *path = [pathDir stringByAppendingPathComponent:file];
        [fileManager fileExistsAtPath:path isDirectory:(&isDir)];
        if (isDir) {
            [folderArray addObject:file];
        }else
        {
            if ([file isEqualToString:@".DS_Store"]) {
                
            }
            else
            {
                [fileArray addObject:file];
            }
        }
        isDir = NO;
    }
    
    NSArray *result = [fileArray sortedArrayUsingComparator:^NSComparisonResult(id  _Nonnull obj1, id  _Nonnull obj2){
        return [obj1 compare:obj2]; //升序
    }];
    [self.fileListArray addObjectsFromArray:result];
    [self.fileTableView reloadData];
    NSLog(@"All folders:%@ \nAll files:%@",folderArray,fileArray);
}


@end


#pragma mark - UploadViewController
@interface UploadViewController()<UITextFieldDelegate,UITextViewDelegate>
@property(strong, nonatomic)UILabel * fileNameLbl;
@property(strong, nonatomic)UILabel * mimeTypeLbl;

@property(strong, nonatomic)UISwitch * deleteSwitch;
@property(strong, nonatomic)UILabel * deleteswitchLbl;

//上传图片
@property(strong, nonatomic)UITextField * mainTypeField;
@property(strong, nonatomic)UITextView * wordsView;
@property(strong, nonatomic)UISwitch * clickSwitch;
@property(strong, nonatomic)UILabel * switchLbl;


//上传音频
@property(strong, nonatomic)UITextField * wordField;

//上传视频
@property(strong, nonatomic)UITextField * videoCategoryField;//视频类型名称，如《小猪佩奇》
@property(strong, nonatomic)UITextField * videoAlbumnameField;//视频名称,如《小猪佩奇之猪爸爸减肥》
@property(strong, nonatomic)UITextField * videoQuarterField;//视频属于第几季
@property(strong, nonatomic)UITextField * videoOrderField;//视频属于第几集
@property(strong, nonatomic)UIImageView * video_thumb_image;//视频的缩略图
@property(strong, nonatomic)NSString * thumb_image_name;//缩略图名称

@end

@implementation UploadViewController


- (void)initNavigation
{
    self.title = @"上传文件";
    NSShadow *shadow = [[NSShadow alloc] init];
    [shadow setShadowColor:[UIColor lightGrayColor]];
    [shadow setShadowOffset:CGSizeMake(0.5, 0.0)];
    NSDictionary *titleTextAttDict = [NSDictionary dictionaryWithObjectsAndKeys:BaseColor, NSForegroundColorAttributeName, [UIFont fontWithName:@"Arial" size:20.0f], NSFontAttributeName, shadow, NSShadowAttributeName, nil];
    [self.navigationController.navigationBar setTitleTextAttributes:titleTextAttDict];
    UIButton * backBtn = [UIButton setButtonWithFrame:CGRectMake(0, 0, 70, 40)
                                                               center:CGPointMake(40, 70)
                                                      backGroundColor:BaseColor
                                                                title:@"返回"
                                                                 font:[UIFont fontWithName:@"Arial" size:15.0f]
                                                           titleColor:[UIColor whiteColor]
                             ];
    
    [backBtn addTarget:self action:@selector(backButtonPress:) forControlEvents:UIControlEventTouchUpInside];
    UIBarButtonItem * leftBackBarButtonItem = [[UIBarButtonItem alloc] initWithCustomView:backBtn];
    self.navigationItem.leftBarButtonItem = leftBackBarButtonItem;
    
    UIButton * uploadBtn = [UIButton setButtonWithFrame:CGRectMake(0, 0, 70, 40)
                                               center:CGPointMake(40, 70)
                                      backGroundColor:BaseColor
                                                title:@"上传"
                                                 font:[UIFont fontWithName:@"Arial" size:15.0f]
                                           titleColor:[UIColor whiteColor]
                          ];
    
    [uploadBtn addTarget:self action:@selector(upLoadPress:) forControlEvents:UIControlEventTouchUpInside];
    UIBarButtonItem * rightBackBarButtonItem = [[UIBarButtonItem alloc] initWithCustomView:uploadBtn];
    self.navigationItem.rightBarButtonItem = rightBackBarButtonItem;
}


- (void)viewDidLoad
{
    [super viewDidLoad];
    
    [self.view setBackgroundColor:[UIColor whiteColor]];
    
    [self initNavigation];
    [self createView];
}

- (void)backButtonPress:(id)sender{
    if ([self.name isEqualToString:@"video"]) {
        [self deleteFileWithName:self.thumb_image_name];
    }
    [self.navigationController popViewControllerAnimated:YES];
}

- (void)createView{
    
    self.fileNameLbl = [[UILabel alloc] initWithFrame:CGRectMake(10, TopBar_Height + 10, WinSize.width - 20, 50)];
    [self.fileNameLbl setFont:[UIFont fontWithName:@"Arial" size:18.0f]];
    [self.fileNameLbl setTextColor:BaseColor];
    [self.fileNameLbl setTextAlignment:NSTextAlignmentCenter];
    [self.fileNameLbl setNumberOfLines:0];
    [self.fileNameLbl setBackgroundColor:[UIColor clearColor]];
    [self.view addSubview:self.fileNameLbl];
    [self.fileNameLbl.layer setMasksToBounds:YES];
    [self.fileNameLbl.layer setBorderColor:BaseColor.CGColor];
    [self.fileNameLbl.layer setBorderWidth:1.0f];
    [self.fileNameLbl.layer setCornerRadius:10.0f];
    [self.fileNameLbl setText:self.fileName];

    self.mimeTypeLbl = [[UILabel alloc] initWithFrame:CGRectMake(10, CGRectGetMaxY(self.fileNameLbl.frame)+20, WinSize.width - 20, 50)];
    [self.mimeTypeLbl setFont:[UIFont fontWithName:@"Arial" size:18.0f]];
    [self.mimeTypeLbl setTextColor:BaseColor];
    [self.mimeTypeLbl setTextAlignment:NSTextAlignmentCenter];
    [self.mimeTypeLbl setNumberOfLines:0];
    [self.mimeTypeLbl setBackgroundColor:[UIColor clearColor]];
    [self.view addSubview:self.mimeTypeLbl];
    [self.mimeTypeLbl.layer setMasksToBounds:YES];
    [self.mimeTypeLbl.layer setBorderColor:BaseColor.CGColor];
    [self.mimeTypeLbl.layer setBorderWidth:1.0f];
    [self.mimeTypeLbl.layer setCornerRadius:10.0f];
    [self.mimeTypeLbl setText:self.mimeType];

    self.deleteSwitch = [[UISwitch alloc] initWithFrame:CGRectMake(10, CGRectGetMaxY(self.mimeTypeLbl.frame)+20, 120, 50)];
    [self.deleteSwitch setOn:YES];
    [self.deleteSwitch setOnTintColor:BaseColor];
    [self.deleteSwitch addTarget:self action:@selector(deleteSwitchPress:) forControlEvents:UIControlEventValueChanged];
    [self.view addSubview:self.deleteSwitch];
    
    self.deleteswitchLbl = [[UILabel alloc] initWithFrame:CGRectMake(CGRectGetMaxX(self.deleteSwitch.frame)+20, 0, WinSize.width -CGRectGetMaxX(self.clickSwitch.frame) - 30 , 50)];
    [self.deleteswitchLbl setFont:[UIFont fontWithName:@"Arial" size:18.0f]];
    [self.deleteswitchLbl setTextColor:BaseColor];
    [self.deleteswitchLbl setTextAlignment:NSTextAlignmentLeft];
    [self.deleteswitchLbl setText:@"上传成功后删除文件"];
    [self.view addSubview:self.deleteswitchLbl];
    [self.deleteswitchLbl setCenter:CGPointMake(CGRectGetMidX(self.deleteswitchLbl.frame), CGRectGetMidY(self.deleteSwitch.frame))];
    
    if ([self.name isEqualToString:@"image"]) {
        [self createUploadPicView];
    }
    else if([self.name isEqualToString:@"audio"]) {
        [self createUploadAudioView];
    }
    else if([self.name isEqualToString:@"video"]) {
        self.bucket = @"greattalkvideo";
        [self createUploadVideoView];
    }
    else if([self.name isEqualToString:@"other"]) {

    }
}

- (void)deleteSwitchPress:(id)sender{
    if (self.deleteSwitch.isOn == YES) {
        [self.deleteswitchLbl setText:@"上传成功后删除文件"];
    }
    else
    {
        [self.deleteswitchLbl setText:@"上传成功后不删除文件"];
    }
}

- (void)createUploadPicView{
    self.mainTypeField = [[UITextField alloc] initWithFrame:CGRectMake(10, CGRectGetMaxY(self.deleteswitchLbl.frame)+20, WinSize.width - 20, 50)];
    [self.mainTypeField setTextColor:BaseColor];
    [self.mainTypeField setTextAlignment:NSTextAlignmentLeft];
    [self.mainTypeField setFont:[UIFont fontWithName:@"Arial" size:18.0f]];
    [self.mainTypeField setBackgroundColor:[UIColor clearColor]];
    [self.mainTypeField setDelegate:self];
    [self.mainTypeField setPlaceholder:@"输入文件归属类型"];
    [self.mainTypeField.layer setMasksToBounds:YES];
    [self.mainTypeField.layer setBorderColor:BaseColor.CGColor];
    [self.mainTypeField.layer setBorderWidth:1.0f];
    [self.mainTypeField.layer setCornerRadius:10.0f];
    [self.mainTypeField setAutocapitalizationType:UITextAutocapitalizationTypeNone];
    [self.view addSubview:self.mainTypeField];
    
    self.wordsView = [[UITextView alloc] initWithFrame:CGRectMake(10, CGRectGetMaxY(self.mainTypeField.frame)+20, WinSize.width - 20, 150)];
    [self.wordsView setTextColor:BaseColor];
    [self.wordsView setDelegate:self];
    [self.wordsView setFont:[UIFont fontWithName:@"Arial" size:18.0f]];
    [self.wordsView setTextAlignment:NSTextAlignmentLeft];
    [self.wordsView setBackgroundColor:[UIColor clearColor]];
    [self.view addSubview:self.wordsView];
    [self.wordsView.layer setMasksToBounds:YES];
    [self.wordsView.layer setBorderColor:BaseColor.CGColor];
    [self.wordsView.layer setBorderWidth:1.0f];
    [self.wordsView.layer setCornerRadius:10.0f];
    [self.wordsView setAutocapitalizationType:UITextAutocapitalizationTypeNone];
    
    self.clickSwitch = [[UISwitch alloc] initWithFrame:CGRectMake(10, CGRectGetMaxY(self.wordsView.frame)+20, 120, 50)];
    [self.clickSwitch setOn:NO];
    [self.clickSwitch setOnTintColor:BaseColor];
    [self.clickSwitch addTarget:self action:@selector(canClickPress:) forControlEvents:UIControlEventValueChanged];
    [self.view addSubview:self.clickSwitch];
    
    self.switchLbl = [[UILabel alloc] initWithFrame:CGRectMake(CGRectGetMaxX(self.clickSwitch.frame)+20, 0, WinSize.width -CGRectGetMaxX(self.clickSwitch.frame) - 30 , 50)];
    [self.switchLbl setFont:[UIFont fontWithName:@"Arial" size:18.0f]];
    [self.switchLbl setTextColor:BaseColor];
    [self.switchLbl setTextAlignment:NSTextAlignmentLeft];
    [self.switchLbl setText:@"图片不可点击"];
    [self.view addSubview:self.switchLbl];
    [self.switchLbl setCenter:CGPointMake(CGRectGetMidX(self.switchLbl.frame), CGRectGetMidY(self.clickSwitch.frame))];
    
    UIView * cancelView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, WinSize.width, 45)];
    [cancelView setBackgroundColor:[UIColor clearColor]];
    [cancelView.layer setMasksToBounds:YES];
    [cancelView.layer setBorderColor:BaseColor.CGColor];
    [cancelView.layer setBorderWidth:1.0f];
    [cancelView.layer setCornerRadius:10.0f];
    
    UIButton * cancelBtn = [UIButton setButtonWithFrame:CGRectMake(0, 0, 70, 40)
                                               center:CGPointMake(WinSize.width - 40, 45/2)
                                      backGroundColor:BaseColor
                                                title:@"取消"
                                                 font:[UIFont fontWithName:@"Arial" size:15.0f]
                                           titleColor:[UIColor whiteColor]
                          ];
    [cancelBtn addTarget:self action:@selector(cancelButtonPress:) forControlEvents:UIControlEventTouchUpInside];
    [cancelView addSubview:cancelBtn];
    self.wordsView.inputAccessoryView = cancelView;
    
    UIButton * previewImageButton = [UIButton setButtonWithFrame:CGRectMake(0, 0, WinSize.width - 20, 50)
                                                    center:CGPointMake(WinSize.width/2, CGRectGetMaxY(self.clickSwitch.frame)+50)
                                           backGroundColor:[UIColor whiteColor]
                                                     title:@"预览图片文件"
                                                      font:[UIFont fontWithName:@"Arial" size:20.0f]
                                                titleColor:BaseColor];
    [previewImageButton addTarget:self action:@selector(previewImageButtonPress:) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:previewImageButton];
}

- (void)previewImageButtonPress:(id)sender{
    NSString *tmpDir = NSTemporaryDirectory();
    NSString *filePath = [tmpDir stringByAppendingPathComponent:self.fileName];
    ImagePreviewViewController * imagePVC = [[ImagePreviewViewController alloc] initWithFilePath:filePath];
    [self presentViewController:imagePVC animated:YES completion:nil];
}

- (void)canClickPress:(id)sender{
    if (self.clickSwitch.isOn == YES) {
        [self.switchLbl setText:@"图片可点击"];
    }
    else
    {
        [self.switchLbl setText:@"图片不可点击"];
    }
}

- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event
{
    [self.wordsView resignFirstResponder];
    [self.wordField resignFirstResponder];
    [self.mainTypeField resignFirstResponder];
    
    [self.videoCategoryField resignFirstResponder];
    [self.videoAlbumnameField resignFirstResponder];
    [self.videoOrderField resignFirstResponder];
    [self.videoQuarterField resignFirstResponder];
}

- (void)textViewDidBeginEditing:(UITextView *)textView
{
    [UIView animateWithDuration:0.3 animations:^{
        CGRect frame = self.view.frame;
        frame.origin.y = frame.origin.y - 70;
        self.view.frame = frame;
    }];
}

- (void)textViewDidEndEditing:(UITextView *)textView
{
    [UIView animateWithDuration:0.3 animations:^{
        CGRect frame = self.view.frame;
        frame.origin.y = frame.origin.y + 70;
        self.view.frame = frame;
    } completion:^(BOOL finished) {
        
    }];
}

- (BOOL)textView:(UITextView *)textView shouldChangeTextInRange:(NSRange)range replacementText:(NSString *)text{
    if ([text isEqualToString:@"\n"]){ //判断输入的字是否是回车，即按下return
        //在这里做你响应return键的代码
        NSString * textViewString = [NSString stringWithFormat:@"%@#",textView.text];
        textView.text = textViewString;
        return NO; //这里返回NO，就代表return键值失效，即页面上按下return，不会出现换行，如果为yes，则输入页面会换行
    }
    
    return YES;
}

- (void)cancelButtonPress:(id)sender{
    [self.wordsView resignFirstResponder];
}

- (void)createUploadAudioView{
    self.wordField = [[UITextField alloc] initWithFrame:CGRectMake(10, CGRectGetMaxY(self.deleteswitchLbl.frame)+20, WinSize.width - 20, 50)];
    [self.wordField setTextColor:BaseColor];
    [self.wordField setTextAlignment:NSTextAlignmentLeft];
    [self.wordField setFont:[UIFont fontWithName:@"Arial" size:18.0f]];
    [self.wordField setBackgroundColor:[UIColor clearColor]];
    [self.wordField setDelegate:self];
    [self.wordField setAutocapitalizationType:UITextAutocapitalizationTypeNone];
    [self.wordField setPlaceholder:@"输入文件对应单词"];
    [self.wordField.layer setMasksToBounds:YES];
    [self.wordField.layer setBorderColor:BaseColor.CGColor];
    [self.wordField.layer setBorderWidth:1.0f];
    [self.wordField.layer setCornerRadius:10.0f];
    [self.view addSubview:self.wordField];
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField{
    if (textField == self.wordField) {
        [self.wordField resignFirstResponder];
    }
    return YES;
}

- (void)createUploadVideoView{
//    videoCategoryField;//视频类型名称，如《小猪佩奇》
//    videoAlbumnameField;//视频名称,如《小猪佩奇之猪爸爸减肥》
//    videoQuarterField;//视频属于第几季
//    videoOrderField
    
    self.videoCategoryField = [[UITextField alloc] initWithFrame:CGRectMake(10, CGRectGetMaxY(self.deleteswitchLbl.frame)+20, WinSize.width - 20, 50)];
    [self.videoCategoryField setTextColor:BaseColor];
    [self.videoCategoryField setTextAlignment:NSTextAlignmentLeft];
    [self.videoCategoryField setFont:[UIFont fontWithName:@"Arial" size:18.0f]];
    [self.videoCategoryField setBackgroundColor:[UIColor clearColor]];
    [self.videoCategoryField setDelegate:self];
    [self.videoCategoryField setPlaceholder:@"输入视频总名称，如：《小猪佩奇》"];
    [self.videoCategoryField.layer setMasksToBounds:YES];
    [self.videoCategoryField.layer setBorderColor:BaseColor.CGColor];
    [self.videoCategoryField.layer setBorderWidth:1.0f];
    [self.videoCategoryField.layer setCornerRadius:10.0f];
    [self.videoCategoryField setAutocapitalizationType:UITextAutocapitalizationTypeNone];
    [self.view addSubview:self.videoCategoryField];
    
    self.videoAlbumnameField = [[UITextField alloc] initWithFrame:CGRectMake(10, CGRectGetMaxY(self.videoCategoryField.frame)+20, WinSize.width - 20, 50)];
    [self.videoAlbumnameField setTextColor:BaseColor];
    [self.videoAlbumnameField setTextAlignment:NSTextAlignmentLeft];
    [self.videoAlbumnameField setFont:[UIFont fontWithName:@"Arial" size:18.0f]];
    [self.videoAlbumnameField setBackgroundColor:[UIColor clearColor]];
    [self.videoAlbumnameField setDelegate:self];
    [self.videoAlbumnameField setPlaceholder:@"视频名称，如：《小猪佩奇之猪爸爸减肥》"];
    [self.videoAlbumnameField.layer setMasksToBounds:YES];
    [self.videoAlbumnameField.layer setBorderColor:BaseColor.CGColor];
    [self.videoAlbumnameField.layer setBorderWidth:1.0f];
    [self.videoAlbumnameField.layer setCornerRadius:10.0f];
    [self.videoAlbumnameField setAutocapitalizationType:UITextAutocapitalizationTypeNone];
    [self.view addSubview:self.videoAlbumnameField];
    
    self.videoQuarterField = [[UITextField alloc] initWithFrame:CGRectMake(10, CGRectGetMaxY(self.videoAlbumnameField.frame)+20, WinSize.width - 20, 50)];
    [self.videoQuarterField setTextColor:BaseColor];
    [self.videoQuarterField setTextAlignment:NSTextAlignmentLeft];
    [self.videoQuarterField setFont:[UIFont fontWithName:@"Arial" size:18.0f]];
    [self.videoQuarterField setBackgroundColor:[UIColor clearColor]];
    [self.videoQuarterField setDelegate:self];
    [self.videoQuarterField setPlaceholder:@"视频属于第几季"];
    [self.videoQuarterField.layer setMasksToBounds:YES];
    [self.videoQuarterField.layer setBorderColor:BaseColor.CGColor];
    [self.videoQuarterField.layer setBorderWidth:1.0f];
    [self.videoQuarterField.layer setCornerRadius:10.0f];
    [self.videoQuarterField setAutocapitalizationType:UITextAutocapitalizationTypeNone];
    [self.view addSubview:self.videoQuarterField];
    
    self.videoOrderField = [[UITextField alloc] initWithFrame:CGRectMake(10, CGRectGetMaxY(self.videoQuarterField.frame)+20, WinSize.width - 20, 50)];
    [self.videoOrderField setTextColor:BaseColor];
    [self.videoOrderField setTextAlignment:NSTextAlignmentLeft];
    [self.videoOrderField setFont:[UIFont fontWithName:@"Arial" size:18.0f]];
    [self.videoOrderField setBackgroundColor:[UIColor clearColor]];
    [self.videoOrderField setDelegate:self];
    [self.videoOrderField setPlaceholder:@"视频是第几集"];
    [self.videoOrderField.layer setMasksToBounds:YES];
    [self.videoOrderField.layer setBorderColor:BaseColor.CGColor];
    [self.videoOrderField.layer setBorderWidth:1.0f];
    [self.videoOrderField.layer setCornerRadius:10.0f];
    [self.videoOrderField setAutocapitalizationType:UITextAutocapitalizationTypeNone];
    [self.view addSubview:self.videoOrderField];
    
    self.video_thumb_image = [[UIImageView alloc] initWithFrame:CGRectMake(10, CGRectGetMaxY(self.videoOrderField.frame)+20, WinSize.width-20, 220)];
    [self.video_thumb_image setContentMode:UIViewContentModeScaleAspectFill];
    [self.video_thumb_image setClipsToBounds:YES];
    NSString *tmpDir = NSTemporaryDirectory();
    NSString *filePath = [tmpDir stringByAppendingPathComponent:self.fileName];
    UIImage * thumb_image = [self getScreenShotImageFromVideoPath:filePath];
    [self.video_thumb_image setImage:thumb_image];
    [self.view addSubview:self.video_thumb_image];
    
    self.thumb_image_name = [NSString stringWithFormat:@"%@.jpeg",[[filePath lastPathComponent] stringByDeletingPathExtension]];
    NSLog(@"%@",self.thumb_image_name);
    [self saveImage:thumb_image imageName:self.thumb_image_name];
}


- (void)saveImage:(UIImage *)image imageName:(NSString *)imageName {
    NSString *tmpDir = NSTemporaryDirectory();
    NSString *filePath = [tmpDir stringByAppendingPathComponent:
                          [NSString stringWithFormat:@"%@", imageName]];  // 保存文件的名称
    BOOL result =[UIImageJPEGRepresentation(image, 1.0f) writeToFile:filePath atomically:YES]; // 保存成功会返回YES
    if (result == YES) {
        NSLog(@"保存成功");
    }
    else
    {
        NSLog(@"保存失败");
    }
}

/**
 *  获取视频的缩略图方法
 *
 *  @param filePath 视频的本地路径
 *
 *  @return 视频截图
 */
- (UIImage *)getScreenShotImageFromVideoPath:(NSString *)filePath{
    
    UIImage *shotImage;
    //视频路径URL
    NSURL *fileURL = [NSURL fileURLWithPath:filePath];
    
    AVURLAsset *asset = [[AVURLAsset alloc] initWithURL:fileURL options:nil];
    
    AVAssetImageGenerator *gen = [[AVAssetImageGenerator alloc] initWithAsset:asset];
    
    gen.appliesPreferredTrackTransform = YES;
    
    CMTime time = CMTimeMakeWithSeconds(0.0, 600);
    
    NSError *error = nil;
    
    CMTime actualTime;
    
    CGImageRef image = [gen copyCGImageAtTime:time actualTime:&actualTime error:&error];
    
    shotImage = [[UIImage alloc] initWithCGImage:image];
    
    CGImageRelease(image);

    return shotImage;
}

- (void)textFieldDidBeginEditing:(UITextField *)textField
{
    if (textField == self.videoAlbumnameField) {
        [UIView animateWithDuration:0.3 animations:^{
            CGRect frame = self.view.frame;
            frame.origin.y = frame.origin.y - 70;
            self.view.frame = frame;
        }];
    }
    if (textField == self.videoQuarterField) {
        [UIView animateWithDuration:0.3 animations:^{
            CGRect frame = self.view.frame;
            frame.origin.y = frame.origin.y - 100;
            self.view.frame = frame;
        }];
    }
    if (textField == self.videoOrderField) {
        [UIView animateWithDuration:0.3 animations:^{
            CGRect frame = self.view.frame;
            frame.origin.y = frame.origin.y - 120;
            self.view.frame = frame;
        }];
    }
}

- (void)textFieldDidEndEditing:(UITextField *)textField
{
    if (textField == self.videoAlbumnameField) {
        [UIView animateWithDuration:0.3 animations:^{
            CGRect frame = self.view.frame;
            frame.origin.y = frame.origin.y + 70;
            self.view.frame = frame;
        } completion:^(BOOL finished) {
            
        }];
    }
    if (textField == self.videoQuarterField) {
        [UIView animateWithDuration:0.3 animations:^{
            CGRect frame = self.view.frame;
            frame.origin.y = frame.origin.y + 100;
            self.view.frame = frame;
        }];
    }
    if (textField == self.videoOrderField) {
        [UIView animateWithDuration:0.3 animations:^{
            CGRect frame = self.view.frame;
            frame.origin.y = frame.origin.y + 120;
            self.view.frame = frame;
        }];
    }
}

- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string{
    if (textField == self.videoQuarterField) {
        return [self validateNumber:string];
    }
    if (textField == self.videoOrderField) {
        return [self validateNumber:string];
    }
    return YES;
}

/**
 * 判断textField输入数字
 */
- (BOOL)validateNumber:(NSString*)number {
    BOOL res = YES;
    NSCharacterSet* tmpSet = [NSCharacterSet characterSetWithCharactersInString:@"0123456789"];
    int i = 0;
    while (i < number.length) {
        NSString * string = [number substringWithRange:NSMakeRange(i, 1)];
        NSRange range = [string rangeOfCharacterFromSet:tmpSet];
        if (range.length == 0) {
            res = NO;
            break;
        }
        i++;
    }
    return res;
}

- (void)upLoadPress:(id)sender{
    [self qiniuUploadPress:nil];
}
/**
 * 上传图片时需要的数据
 * maintype 文件归属类型，比如，属于字母A学习的
 * words 对应的单词，当有多个单词是，以#分开 如，apple#part#bate
 * fname 对应的文件名
 * filebucket 文件所在存储空间
 */
/**
 * 上传音频时需要的数据
 * word 对应的单词
 * fname 对应的文件名
 * filebucket 文件所在存储空间
 */
/**
 * category 视频的名称类别，比如《小猪佩奇》、《海绵宝宝》
 * albumname 视频对应的名称，比如《猪爸爸减肥》
 * quarter 视频属于第几季
 * order 视频属于第几集
 * fname 对应的文件名
 * filebucket 文件所在存储空间
 * mimetype 文件扩展类型
 * length  视频时长
 */
#pragma mark - Qiniu上传事件
- (void)qiniuUploadPress:(id)sender{
    if ([self.name isEqualToString:@"image"]) {
        if ([self.mainTypeField.text isEqualToString:@""] || self.mainTypeField.text == nil) {
            UIAlertController * alertC = [UIAlertController alertControllerWithTitle:@"请输入文件归属类型" message:nil preferredStyle:UIAlertControllerStyleAlert];
            UIAlertAction * alertA = [UIAlertAction actionWithTitle:@"确定" style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
                
            }];
            [alertC addAction:alertA];
            [self presentViewController:alertC animated:YES completion:nil];
        }
        if ([self.wordsView.text isEqualToString:@""] || self.wordsView.text == nil) {
            UIAlertController * alertC = [UIAlertController alertControllerWithTitle:@"请输入文件对应单词" message:nil preferredStyle:UIAlertControllerStyleAlert];
            UIAlertAction * alertA = [UIAlertAction actionWithTitle:@"确定" style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
                
            }];
            [alertC addAction:alertA];
            [self presentViewController:alertC animated:YES completion:nil];
        }
    }
    else if([self.name isEqualToString:@"audio"]) {
        if ([self.wordField.text isEqualToString:@""] || self.wordField.text == nil) {
            UIAlertController * alertC = [UIAlertController alertControllerWithTitle:@"请输入文件对应单词" message:nil preferredStyle:UIAlertControllerStyleAlert];
            UIAlertAction * alertA = [UIAlertAction actionWithTitle:@"确定" style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
                
            }];
            [alertC addAction:alertA];
            [self presentViewController:alertC animated:YES completion:nil];
        }
    }
    else if([self.name isEqualToString:@"video"]) {
        if ([self.videoCategoryField.text isEqualToString:@""] || self.videoCategoryField.text == nil) {
            UIAlertController * alertC = [UIAlertController alertControllerWithTitle:@"请输入视频总名称" message:nil preferredStyle:UIAlertControllerStyleAlert];
            UIAlertAction * alertA = [UIAlertAction actionWithTitle:@"确定" style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
                
            }];
            [alertC addAction:alertA];
            [self presentViewController:alertC animated:YES completion:nil];
        }
        if ([self.videoAlbumnameField.text isEqualToString:@""] || self.videoAlbumnameField.text == nil) {
            UIAlertController * alertC = [UIAlertController alertControllerWithTitle:@"请输入视频名称" message:nil preferredStyle:UIAlertControllerStyleAlert];
            UIAlertAction * alertA = [UIAlertAction actionWithTitle:@"确定" style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
                
            }];
            [alertC addAction:alertA];
            [self presentViewController:alertC animated:YES completion:nil];
        }
        if ([self.videoQuarterField.text isEqualToString:@""] || self.videoQuarterField.text == nil) {
            UIAlertController * alertC = [UIAlertController alertControllerWithTitle:@"请输入视频是第几季" message:nil preferredStyle:UIAlertControllerStyleAlert];
            UIAlertAction * alertA = [UIAlertAction actionWithTitle:@"确定" style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
                
            }];
            [alertC addAction:alertA];
            [self presentViewController:alertC animated:YES completion:nil];
        }
        if ([self.videoOrderField.text isEqualToString:@""] || self.videoOrderField.text == nil) {
            UIAlertController * alertC = [UIAlertController alertControllerWithTitle:@"请输入视频第几集" message:nil preferredStyle:UIAlertControllerStyleAlert];
            UIAlertAction * alertA = [UIAlertAction actionWithTitle:@"确定" style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
                
            }];
            [alertC addAction:alertA];
            [self presentViewController:alertC animated:YES completion:nil];
        }
    }
    else if([self.name isEqualToString:@"other"]) {
        
    }
    
    [self showProgressLoadingTypeCircle:@"获取上传信息！"];
    PPFileNetWorking * netWork = [[PPFileNetWorking alloc] init];
    NSMutableDictionary * dic = [[NSMutableDictionary alloc] init];
    [dic setObject:self.name forKey:@"file_type"];
    
    [netWork PPFWnetworkPOSTWithUrl:UrlString controller:@"profile" action:@"getuptoken" parameters:dic success:^(id responseObject) {
        if ([[responseObject objectForKey:@"is_success"] intValue] == 1) {
            NSDictionary * resultData = [responseObject objectForKey:@"data"];
            NSLog(@"%@",resultData);
            
            dispatch_async(dispatch_get_main_queue(), ^{
                [self dismissProgress];
                [self showProgressStatusSuccess:@"获取成功" completion:^{
                   [self uploadFileToQinniuWithUpToken:[NSString stringWithFormat:@"%@",[resultData objectForKey:@"up_token"]]];
                }];
            });
        }
        else
        {
            dispatch_async(dispatch_get_main_queue(), ^{
                [self dismissProgress];
                [self showProgressStatusFail:@"获取失败"];
            });
        }
    } failure:^(id error) {
        NSLog(@"%@",error);
        dispatch_async(dispatch_get_main_queue(), ^{
            [self dismissProgress];
            [self showProgressStatusFail:@"获取失败"];
        });
    }];
//    [netWork networkPOSTWithUrl:UrlString controller:@"profile" action:@"getuptoken" parameters:dic success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
//        NSDictionary * result = [NSJSONSerialization JSONObjectWithData:responseObject options:NSJSONReadingMutableContainers error:nil];
//        NSLog(@"%@",result);
//        NSDictionary * resultData = [result objectForKey:@"data"];
//        [self dismissProgress];
//        [self showProgressStatusSuccess:@"获取成功"];
//        dispatch_async(dispatch_get_main_queue(), ^{
//            [self uploadFileToQinniuWithUpToken:[NSString stringWithFormat:@"%@",[resultData objectForKey:@"up_token"]]];
//        });
//    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
//        NSLog(@"%@",error);
//        [self dismissProgress];
//        [self showProgressStatusFail:@"获取失败"];
//    }];
}

- (NSDictionary *)getVideoInfoWithSourcePath:(NSString *)path{
    AVURLAsset * asset = [AVURLAsset assetWithURL:[NSURL fileURLWithPath:path]];
    CMTime   time = [asset duration];
    int seconds = ceil(time.value/time.timescale);
    NSInteger   fileSize = [[NSFileManager defaultManager] attributesOfItemAtPath:path error:nil].fileSize;
    return @{@"size" : @(fileSize),
             @"duration" : @(seconds)};
}

- (void)uploadFileToQinniuWithUpToken:(NSString *)qiniu_token{
    [self showProgressTypeSector:@"上传文件..."];
    //华南
    QNConfiguration *config = [QNConfiguration build:^(QNConfigurationBuilder *builder) {
        builder.zone = [QNFixedZone zone2];
    }];
    //重用uploadManager。一般地，只需要创建一个uploadManager对象
    NSString * token = qiniu_token;//从服务端SDK获取
    NSString * key = self.fileName;
    NSString *tmpDir = NSTemporaryDirectory();
    NSString *filePath = [tmpDir stringByAppendingPathComponent:self.fileName];
    
    
    
    [self NSURLSessionGetMIMETypeWithPath:filePath mimeType:^(NSString *MIMEType) {
        self.mimeType = MIMEType;
    }];

    NSMutableDictionary * paramsDic = [NSMutableDictionary new];
    if ([self.name isEqualToString:@"image"]) {
        [paramsDic setObject:self.mainTypeField.text forKey:@"x:maintype"];
        [paramsDic setObject:self.wordsView.text forKey:@"x:words"];
        [paramsDic setObject:self.fileName forKey:@"fname"];
        [paramsDic setObject:self.bucket forKey:@"x:filebucket"];
        [paramsDic setObject:self.mimeType forKey:@"x:mimeType"];
        if (self.clickSwitch.isOn == YES) {
            [paramsDic setObject:@"1" forKey:@"x:click"];
        }
        else
        {
            [paramsDic setObject:@"00" forKey:@"x:click"];
        }
    }
    else if([self.name isEqualToString:@"audio"]) {
        [paramsDic setObject:self.wordField.text forKey:@"x:word"];
        [paramsDic setObject:self.fileName forKey:@"fname"];
        [paramsDic setObject:self.bucket forKey:@"x:filebucket"];
        [paramsDic setObject:self.mimeType forKey:@"x:mimeType"];
    }
    else if([self.name isEqualToString:@"video"]) {
        [paramsDic setObject:self.fileName forKey:@"fname"];
        [paramsDic setObject:self.videoCategoryField.text forKey:@"x:category"];
        [paramsDic setObject:self.videoAlbumnameField.text forKey:@"x:albumname"];
        [paramsDic setObject:self.videoQuarterField.text forKey:@"x:quarter"];
        [paramsDic setObject:self.videoOrderField.text forKey:@"x:order"];
        [paramsDic setObject:self.bucket forKey:@"x:filebucket"];
        [paramsDic setObject:self.mimeType forKey:@"x:mimeType"];
        [paramsDic setObject:[NSString stringWithFormat:@"%@",[[self getVideoInfoWithSourcePath:filePath] objectForKey:@"duration"]] forKey:@"x:length"];

    }
    else if([self.name isEqualToString:@"other"]) {
        
    }
    
    NSLog(@"params ----- %@",paramsDic);

    QNUploadManager *upManager = [[QNUploadManager alloc] initWithConfiguration:config];

    QNUploadOption *opt = [[QNUploadOption alloc] initWithMime:self.mimeType progressHandler:^(NSString *key, float percent) {
        NSLog(@"percent ----- %f",percent);
        [self changeProgress:percent];
    } params:paramsDic checkCrc:YES cancellationSignal:nil];
    
    [upManager putFile:filePath key:key token:token complete:^(QNResponseInfo *info, NSString *key, NSDictionary *resp) {
        if(info.ok)
        {
            NSLog(@"请求成功");
            [self dismissProgress];
            [self showProgressStatusSuccess:@"上传成功" completion:nil];
            if (self.deleteSwitch.isOn == YES) {
                [self deleteFileWithPath:filePath];
            }
        }
        else{
            NSLog(@"失败");
            [self showProgressStatusSuccess:@"上传失败" completion:nil];
            //如果失败，这里可以把info信息上报自己的服务器，便于后面分析上传错误原因
        }
        NSLog(@"info ===== %@", info);
        NSLog(@"resp ===== %@", resp);
    } option:opt];
}

- (BOOL)deleteFileWithPath:(NSString *)path{
    NSFileManager *fileManage = [NSFileManager defaultManager];
    if ([fileManage fileExistsAtPath:path]) {
        // 删除
        BOOL isSuccess = [fileManage removeItemAtPath:path error:nil];
        return isSuccess ? YES : NO;
//        NSLog(@"%@",isSuccess ? @"删除成功" : @"删除失败");
    }else{
        return NO;
    }
}

- (void)NSURLSessionGetMIMETypeWithPath:(NSString *)path mimeType:(nullable void(^)(NSString * MIMEType))mimeType{
    NSURL * url = [NSURL fileURLWithPath:path];
    NSMutableURLRequest * request = [NSMutableURLRequest requestWithURL:url];
    NSURLSession * session = [NSURLSession sharedSession];
    NSURLSessionDataTask * dataTask = [session dataTaskWithRequest:request completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
        if (mimeType) {
            mimeType(response.MIMEType);
        }
    }];
    [dataTask resume];
}

- (void)videoThumbUpload{
    [self showProgressLoadingTypeCircle:@"获取上传信息！"];
    PPFileNetWorking * netWork = [[PPFileNetWorking alloc] init];
    NSMutableDictionary * dic = [[NSMutableDictionary alloc] init];
    [dic setObject:self.name forKey:@"file_type"];
    
    [netWork PPFWnetworkPOSTWithUrl:UrlString controller:@"profile" action:@"getuptoken" parameters:dic success:^(id responseObject) {
        if ([[responseObject objectForKey:@"is_success"] intValue] == 1) {
            NSDictionary * resultData = [responseObject objectForKey:@"data"];
            NSLog(@"%@",resultData);
            
            dispatch_async(dispatch_get_main_queue(), ^{
                [self dismissProgress];
                [self showProgressStatusSuccess:@"获取成功" completion:^{
                    [self uploadFileToQinniuWithUpToken:[NSString stringWithFormat:@"%@",[resultData objectForKey:@"up_token"]]];
                }];
            });
        }
        else
        {
            dispatch_async(dispatch_get_main_queue(), ^{
                [self dismissProgress];
                [self showProgressStatusFail:@"获取失败"];
            });
        }
    } failure:^(id error) {
        NSLog(@"%@",error);
        dispatch_async(dispatch_get_main_queue(), ^{
            [self dismissProgress];
            [self showProgressStatusFail:@"获取失败"];
        });
    }];
}

- (void)uploadVideoThumb:(NSString *)thumbPath ToQinniuWithUpToken:(NSString *)qiniu_token{
    [self showProgressTypeSector:@"上传文件..."];
    //华南
    QNConfiguration *config = [QNConfiguration build:^(QNConfigurationBuilder *builder) {
        builder.zone = [QNFixedZone zone2];
    }];
    //重用uploadManager。一般地，只需要创建一个uploadManager对象
    NSString * token = qiniu_token;//从服务端SDK获取
    NSString * key = thumbPath;
    NSString *tmpDir = NSTemporaryDirectory();
    NSString *filePath = [tmpDir stringByAppendingPathComponent:self.fileName];
    
    
    
    [self NSURLSessionGetMIMETypeWithPath:filePath mimeType:^(NSString *MIMEType) {
        self.mimeType = MIMEType;
    }];
    
    NSMutableDictionary * paramsDic = [NSMutableDictionary new];
    if ([self.name isEqualToString:@"image"]) {
        [paramsDic setObject:self.mainTypeField.text forKey:@"x:maintype"];
        [paramsDic setObject:self.wordsView.text forKey:@"x:words"];
        [paramsDic setObject:self.fileName forKey:@"fname"];
        [paramsDic setObject:self.bucket forKey:@"x:filebucket"];
        [paramsDic setObject:self.mimeType forKey:@"x:mimeType"];
        if (self.clickSwitch.isOn == YES) {
            [paramsDic setObject:@"1" forKey:@"x:click"];
        }
        else
        {
            [paramsDic setObject:@"00" forKey:@"x:click"];
        }
    }
    else if([self.name isEqualToString:@"audio"]) {
        [paramsDic setObject:self.wordField.text forKey:@"x:word"];
        [paramsDic setObject:self.fileName forKey:@"fname"];
        [paramsDic setObject:self.bucket forKey:@"x:filebucket"];
        [paramsDic setObject:self.mimeType forKey:@"x:mimeType"];
    }
    else if([self.name isEqualToString:@"video"]) {
        [paramsDic setObject:self.fileName forKey:@"fname"];
        [paramsDic setObject:self.videoCategoryField.text forKey:@"x:category"];
        [paramsDic setObject:self.videoAlbumnameField.text forKey:@"x:albumname"];
        [paramsDic setObject:self.videoQuarterField.text forKey:@"x:quarter"];
        [paramsDic setObject:self.videoOrderField.text forKey:@"x:order"];
        [paramsDic setObject:self.bucket forKey:@"x:filebucket"];
        [paramsDic setObject:self.mimeType forKey:@"x:mimeType"];
        [paramsDic setObject:[NSString stringWithFormat:@"%@",[[self getVideoInfoWithSourcePath:filePath] objectForKey:@"duration"]] forKey:@"x:length"];
        
    }
    else if([self.name isEqualToString:@"other"]) {
        
    }
    
    NSLog(@"params ----- %@",paramsDic);
    
    QNUploadManager *upManager = [[QNUploadManager alloc] initWithConfiguration:config];
    
    QNUploadOption *opt = [[QNUploadOption alloc] initWithMime:self.mimeType progressHandler:^(NSString *key, float percent) {
        NSLog(@"percent ----- %f",percent);
        [self changeProgress:percent];
    } params:paramsDic checkCrc:YES cancellationSignal:nil];
    
    [upManager putFile:filePath key:key token:token complete:^(QNResponseInfo *info, NSString *key, NSDictionary *resp) {
        if(info.ok)
        {
            NSLog(@"请求成功");
            [self dismissProgress];
            [self showProgressStatusSuccess:@"上传成功" completion:nil];
            if (self.deleteSwitch.isOn == YES) {
                [self deleteFileWithPath:filePath];
            }
        }
        else{
            NSLog(@"失败");
            [self showProgressStatusSuccess:@"上传失败" completion:nil];
            //如果失败，这里可以把info信息上报自己的服务器，便于后面分析上传错误原因
        }
        NSLog(@"info ===== %@", info);
        NSLog(@"resp ===== %@", resp);
    } option:opt];
}

- (BOOL)deleteFileWithName:(NSString *)name{
    NSString *tmpDir = NSTemporaryDirectory();
    NSString *filePath = [tmpDir stringByAppendingPathComponent:name];
    NSFileManager *fileManage = [NSFileManager defaultManager];
    if ([fileManage fileExistsAtPath:filePath]) {
        // 删除
        BOOL isSuccess = [fileManage removeItemAtPath:filePath error:nil];
        return isSuccess ? YES : NO;
        //        NSLog(@"%@",isSuccess ? @"删除成功" : @"删除失败");
    }else{
        return NO;
    }
}

#pragma mark - Show HUD
- (void)showProgressLoadingTypeCircle:(NSString *)text {
    
    DMProgressHUD *hud = [DMProgressHUD showHUDAddedTo:self.view animation:DMProgressHUDAnimationIncrement maskType:DMProgressHUDMaskTypeClear];
    hud.mode = DMProgressHUDModeLoading;
    hud.loadingType = DMProgressHUDLoadingTypeCircle;
    hud.style = DMProgressHUDStyleLight;
    hud.text = text;
    hud.tag = 2222;
}

- (void)showProgressTypeSector:(NSString *)text {
    
    DMProgressHUD *hud = [DMProgressHUD showHUDAddedTo:self.view animation:DMProgressHUDAnimationIncrement maskType:DMProgressHUDMaskTypeClear];
    hud.mode = DMProgressHUDModeProgress;
    hud.progressType = DMProgressHUDProgressTypeSector;
    hud.style = DMProgressHUDStyleLight;
    hud.text = text;
    hud.tag = 2222;
}

- (void)showProgressStatusSuccess:(NSString *)text completion:(void(^)(void))completion{
    DMProgressHUD *hud = [DMProgressHUD showHUDAddedTo:self.view animation:DMProgressHUDAnimationIncrement maskType:DMProgressHUDMaskTypeClear];
    hud.mode = DMProgressHUDModeStatus;
    hud.statusType = DMProgressHUDStatusTypeSuccess;
    hud.style = DMProgressHUDStyleLight;
    hud.text = text;
    
    [hud dismissAfter:1.0 completion:^{
        if (completion) {
            completion();
        }
    }];
}

- (void)showProgressStatusFail:(NSString *)text {
    
    DMProgressHUD *hud = [DMProgressHUD showHUDAddedTo:self.view animation:DMProgressHUDAnimationIncrement maskType:DMProgressHUDMaskTypeClear];
    hud.mode = DMProgressHUDModeStatus;
    hud.statusType = DMProgressHUDStatusTypeFail;
    hud.style = DMProgressHUDStyleLight;
    hud.text = text;
    
    [hud dismissAfter:1.0 completion:^{
    }];
}

- (void)dismissProgress{
    DMProgressHUD *hud = (DMProgressHUD *)[self.view viewWithTag:2222];
    [hud dismiss];
}

- (void)changeProgress:(float)progress {
    dispatch_async(dispatch_get_main_queue(), ^{
        //refresh progress-value on main thread
        DMProgressHUD *hud = [DMProgressHUD progressHUDForView:self.view];
        hud.progress = progress;
    });
}

@end


#pragma mark - ImagePreviewViewController
@interface ImagePreviewViewController()<UIViewControllerTransitioningDelegate>
@property (nonatomic, strong)UIView * bgView;
@property (nonatomic, strong)NSString * imagePath;
@property (nonatomic, strong)UIImageView * previewimageView;

@end

@implementation ImagePreviewViewController

- (void)configureController
{
    self.providesPresentationContextTransitionStyle = YES;
    self.definesPresentationContext = YES;
    self.modalTransitionStyle = UIModalTransitionStyleCrossDissolve;
    self.modalPresentationStyle = UIModalPresentationCustom;
    self.transitioningDelegate = self;
}

- (instancetype)initWithFilePath:(NSString *)filePath
{
    if (self = [super init]) {
        [self configureController];
        self.imagePath = filePath;
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.view.frame = CGRectMake(0, 0, WinSize.width, WinSize.height);
    [self.view setBackgroundColor:[UIColor clearColor]];
    self.modalPresentationStyle = UIModalPresentationOverCurrentContext;

    self.bgView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, WinSize.width, WinSize.height)];
    [self.bgView setBackgroundColor:[UIColor blackColor]];
    [self.bgView setAlpha:0.5f];
    [self.view addSubview:self.bgView];
    
    NSData * imageData = [NSData dataWithContentsOfFile:self.imagePath];
    self.previewimageView = [[UIImageView alloc] initWithImage:[UIImage imageWithData:imageData]];
    [self.previewimageView setFrame:CGRectMake(0, 0, 300, 425)];
    [self.previewimageView setCenter:CGPointMake(WinSize.width/2, WinSize.height/2)];
    [self.previewimageView setBackgroundColor:[UIColor clearColor]];
    [self.view addSubview:self.previewimageView];
    
    UIControl * backControl = [[UIControl alloc] initWithFrame:CGRectMake(0, 0, WinSize.width, WinSize.height)];
    [backControl addTarget:self action:@selector(backPress) forControlEvents:UIControlEventTouchUpInside];
    [backControl setBackgroundColor:[UIColor clearColor]];
    [self.view addSubview:backControl];
}

- (void)backPress{
    [self dismissViewControllerAnimated:YES completion:nil];
}

@end

#pragma mark - main
int main(int argc, char * argv[]) {
    @autoreleasepool {
        return UIApplicationMain(argc, argv, nil, NSStringFromClass([PAppDelegate class]));
    }
}
