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

#define WinSize [UIScreen mainScreen].bounds.size
#define BaseColor [UIColor colorWithRed:243.0f/255.0f green:110.0f/255.0f blue:31.0f/255.0f alpha:1.0f]
#define UrlString @"http://localhost/api"

#define StatusBar_Height [[UIApplication sharedApplication] statusBarFrame].size.height
#define NavBar_Height self.navigationController.navigationBar.frame.size.height

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

@end

#pragma mark - ProfileViewController interface
@interface ProfileViewController : UIViewController

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
    [_window setRootViewController:profileVNC];
}

@end

#pragma mark - ProfileViewController
@interface ProfileViewController()<UITextFieldDelegate,UIPickerViewDelegate,UIPickerViewDataSource>

//UI部分
@property (strong, nonatomic)UIControl * backView;
@property (strong, nonatomic)UITextField * fileNameField;
@property (strong, nonatomic)UIPickerView * fileTypePicker;
@property (strong, nonatomic)UIButton * uploadButton;

//数据部分
@property (strong, nonatomic)NSString * fileName;//文件名称 如：123.mp3
@property (strong, nonatomic)NSString * name;//和服务器约定的名称规则，如audio、image、video
@property (strong, nonatomic)NSString * mimeType;//文件的mimetype 如 image/jpg, image/png等

@property (strong, nonatomic)NSArray * pickerArray;
@end

@implementation ProfileViewController

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

- (instancetype)init
{
    self = [super init];
    if (self) {
        [self.view setBackgroundColor:[UIColor whiteColor]];
    }
    return self;
}

- (void)initNavigation
{
    UIButton * showTmpPath = [ProfileViewController setButtonWithFrame:CGRectMake(0, 0, 70, 40)
                                                                center:CGPointMake(40, 70)
                                                       backGroundColor:BaseColor
                                                                 title:@"Tmp路径"
                                                                  font:[UIFont fontWithName:@"Arial" size:15.0f]
                                                            titleColor:[UIColor whiteColor]
                              ];
    
    [showTmpPath addTarget:self action:@selector(showTmpPathPress) forControlEvents:UIControlEventTouchUpInside];
    UIBarButtonItem * rightBackBarButtonItem = [[UIBarButtonItem alloc] initWithCustomView:showTmpPath];
    self.navigationItem.rightBarButtonItem = rightBackBarButtonItem;
    
    UIButton * getTmpList = [ProfileViewController setButtonWithFrame:CGRectMake(0, 0, 70, 40)
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
    
    self.pickerArray = [[NSArray alloc] initWithObjects:@"图片",@"音频",@"视频", nil];
    
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
    
    //创建文件类型选择器
    self.fileTypePicker = [[UIPickerView alloc] initWithFrame:CGRectMake(10, CGRectGetMaxY(lineView.frame)+20, WinSize.width-20, 162)];
    [self.fileTypePicker setDelegate:self];
    [self.fileTypePicker setDataSource:self];
    [self.fileTypePicker setBackgroundColor:[UIColor whiteColor]];
    [self.backView addSubview:self.fileTypePicker];
    [self.fileTypePicker reloadAllComponents];//刷新UIPickerView
    [self.fileTypePicker.layer setMasksToBounds:YES];
    [self.fileTypePicker.layer setBorderWidth:1.0f];
    [self.fileTypePicker.layer setBorderColor:BaseColor.CGColor];
    [self.fileTypePicker.layer setCornerRadius:10.0f];

    self.uploadButton = [ProfileViewController setButtonWithFrame:CGRectMake(0, 0, WinSize.width - 20, 50)
                                                           center:CGPointMake(WinSize.width/2, CGRectGetMaxY(self.fileTypePicker.frame)+50)
                                                  backGroundColor:[UIColor whiteColor]
                                                            title:@"上传文件"
                                                             font:[UIFont fontWithName:@"Arial" size:20.0f]
                                                       titleColor:BaseColor];
    [self.uploadButton addTarget:self action:@selector(uploadPress:) forControlEvents:UIControlEventTouchUpInside];
    [self.backView addSubview:self.uploadButton];
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
    if ([[self.pickerArray objectAtIndex:row] isEqualToString:@"图片"]) {
        self.name = @"image";
        self.mimeType = @"image/jpeg";
    }
    else if([[self.pickerArray objectAtIndex:row] isEqualToString:@"音频"]){
        self.name = @"audio";
        self.mimeType = @"audio/mp3";
    }
    else if([[self.pickerArray objectAtIndex:row] isEqualToString:@"视频"]){
        self.name = @"video";
        self.mimeType = @"application/octet-stream";
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

- (instancetype)init
{
    if (self = [super init]) {
        [self.view setBackgroundColor:[UIColor whiteColor]];
    }
    return self;
}

- (void)initNavigation
{
    UIButton * refreshBtn = [ProfileViewController setButtonWithFrame:CGRectMake(0, 0, 70, 40)
                                                                center:CGPointMake(40, 70)
                                                       backGroundColor:BaseColor
                                                                 title:@"刷新"
                                                                  font:[UIFont fontWithName:@"Arial" size:15.0f]
                                                            titleColor:[UIColor whiteColor]
                              ];
    
    [refreshBtn addTarget:self action:@selector(refreshFileList) forControlEvents:UIControlEventTouchUpInside];
    UIBarButtonItem * rightBackBarButtonItem = [[UIBarButtonItem alloc] initWithCustomView:refreshBtn];
    self.navigationItem.rightBarButtonItem = rightBackBarButtonItem;
    
    UIButton * backBtn = [ProfileViewController setButtonWithFrame:CGRectMake(0, 0, 70, 40)
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
    [self initNavigation];
    self.fileListArray = [[NSMutableArray alloc] init];
    
    [self createView];
}

- (void)refreshFileList{
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
            [fileArray addObject:file];
        }
        isDir = NO;
    }
    [self.fileListArray addObjectsFromArray:fileArray];
    [self.fileTableView reloadData];
    NSLog(@"All folders:%@ \nAll files:%@",folderArray,fileArray);
}


@end

#pragma mark - main
int main(int argc, char * argv[]) {
    @autoreleasepool {
        return UIApplicationMain(argc, argv, nil, NSStringFromClass([PAppDelegate class]));
    }
}
