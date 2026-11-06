#import <UIKit/UIKit.h>

static NSString *apiKey = @"";
static UIView *menuView = nil;
static UIButton *captureButton = nil;
static UILabel *resultLabel = nil;
static UITextField *apiTextField = nil;

@interface OverlayManager : NSObject
+ (instancetype)sharedInstance;
- (void)setupMenu;
- (void)toggleMenu;
- (void)toggleCaptureButton:(BOOL)show;
- (void)takeScreenshotAndAnalyze;
@end

@implementation OverlayManager

+ (instancetype)sharedInstance {
    static OverlayManager *instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[OverlayManager alloc] init];
    });
    return instance;
}

- (void)setupMenu {
    UIWindow *keyWindow = [UIApplication sharedApplication].keyWindow;
    if (!keyWindow || menuView) return;

    // Root Menu Container
    menuView = [[UIView alloc] initWithFrame:CGRectMake(40, 100, 310, 380)];
    menuView.backgroundColor = [UIColor colorWithWhite:0.1 alpha:0.9];
    menuView.layer.cornerRadius = 16;
    menuView.layer.borderWidth = 1;
    menuView.layer.borderColor = [UIColor colorWithRed:0.0 green:0.8 blue:1.0 alpha:0.6].CGColor;
    menuView.hidden = YES;

    // Title Label
    UILabel *titleLabel = [[UILabel alloc] initWithFrame:CGRectMake(10, 15, 290, 25)];
    titleLabel.text = @"Gemini Assistant Menu";
    titleLabel.textColor = [UIColor whiteColor];
    titleLabel.font = [UIFont boldSystemFontOfSize:18];
    titleLabel.textAlignment = NSTextAlignmentCenter;
    [menuView addSubview:titleLabel];

    // Close Button (X)
    UIButton *closeBtn = [UIButton buttonWithType:UIButtonTypeSystem];
    closeBtn.frame = CGRectMake(270, 10, 30, 30);
    [closeBtn setTitle:@"✕" forState:UIControlStateNormal];
    [closeBtn setTitleColor:[UIColor redColor] forState:UIControlStateNormal];
    closeBtn.titleLabel.font = [UIFont boldSystemFontOfSize:18];
    [closeBtn addTarget:self action:@selector(toggleMenu) forControlEvents:UIControlEventTouchUpInside];
    [menuView addSubview:closeBtn];

    // API Key TextField
    apiTextField = [[UITextField alloc] initWithFrame:CGRectMake(20, 60, 270, 40)];
    apiTextField.placeholder = @"Nhập Gemini API Key...";
    apiTextField.backgroundColor = [UIColor colorWithWhite:0.2 alpha:1.0];
    apiTextField.textColor = [UIColor whiteColor];
    apiTextField.layer.cornerRadius = 8;
    apiTextField.leftView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 10, 40)];
    apiTextField.leftViewMode = UITextFieldViewModeAlways;
    [menuView addSubview:apiTextField];

    // Toggle Capture Button Switch
    UILabel *switchLabel = [[UILabel alloc] initWithFrame:CGRectMake(20, 120, 180, 30)];
    switchLabel.text = @"Hiển thị nút Chụp:";
    switchLabel.textColor = [UIColor whiteColor];
    [menuView addSubview:switchLabel];

    UISwitch *toggleSwitch = [[UISwitch alloc] initWithFrame:CGRectMake(215, 120, 50, 30)];
    [toggleSwitch addTarget:self action:@selector(switchToggled:) forControlEvents:UIControlEventValueChanged];
    [menuView addSubview:toggleSwitch];

    // Result Display Area
    resultLabel = [[UILabel alloc] initWithFrame:CGRectMake(20, 170, 270, 180)];
    resultLabel.text = @"Đáp án sẽ hiển thị ở đây...";
    resultLabel.textColor = [UIColor greenColor];
    resultLabel.numberOfLines = 0;
    resultLabel.font = [UIFont systemFontOfSize:14];
    resultLabel.backgroundColor = [UIColor colorWithWhite:0.0 alpha:0.5];
    resultLabel.layer.cornerRadius = 8;
    resultLabel.clipsToBounds = YES;
    [menuView addSubview:resultLabel];

    [keyWindow addSubview:menuView];

    // Floating Capture Button
    captureButton = [UIButton buttonWithType:UIButtonTypeCustom];
    captureButton.frame = CGRectMake(20, 200, 70, 70);
    captureButton.backgroundColor = [UIColor colorWithRed:0.0 green:0.6 blue:1.0 alpha:0.8];
    [captureButton setTitle:@"Chụp" forState:UIControlStateNormal];
    [captureButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    captureButton.titleLabel.font = [UIFont boldSystemFontOfSize:16];
    captureButton.layer.cornerRadius = 35;
    captureButton.layer.borderWidth = 2;
    captureButton.layer.borderColor = [UIColor whiteColor].CGColor;
    captureButton.hidden = YES;
    [captureButton addTarget:self action:@selector(takeScreenshotAndAnalyze) forControlEvents:UIControlEventTouchUpInside];

    // Make Floating Button Draggable
    UIPanGestureRecognizer *pan = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(handlePan:)];
    [captureButton addGestureRecognizer:pan];

    [keyWindow addSubview:captureButton];
}

- (void)switchToggled:(UISwitch *)sender {
    [self toggleCaptureButton:sender.isOn];
}

- (void)toggleMenu {
    if (!menuView) [self setupMenu];
    menuView.hidden = !menuView.hidden;
    if (!apiTextField.text.length && apiKey.length) {
        apiTextField.text = apiKey;
    }
}

- (void)toggleCaptureButton:(BOOL)show {
    if (!captureButton) [self setupMenu];
    captureButton.hidden = !show;
}

- (void)handlePan:(UIPanGestureRecognizer *)pan {
    CGPoint translation = [pan translationInView:pan.view.superview];
    pan.view.center = CGPointMake(pan.view.center.x + translation.x, pan.view.center.y + translation.y);
    [pan setTranslation:CGPointZero inView:pan.view.superview];
}

- (void)takeScreenshotAndAnalyze {
    apiKey = apiTextField.text;
    if (apiKey.length == 0) {
        resultLabel.text = @"Lỗi: Vui lòng nhập Gemini API Key trong Menu!";
        return;
    }

    resultLabel.text = @"Đang chụp & phân tích đáp án...";

    // Capture Screen
    UIWindow *keyWindow = [UIApplication sharedApplication].keyWindow;
    UIGraphicsBeginImageContextWithOptions(keyWindow.bounds.size, NO, [UIScreen mainScreen].scale);
    
    // Temporarily hide UI elements from screenshot
    menuView.hidden = YES;
    captureButton.hidden = YES;
    
    [keyWindow drawViewHierarchyInRect:keyWindow.bounds afterScreenUpdates:YES];
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();

    captureButton.hidden = NO;

    // Convert Image to Base64
    NSData *imageData = UIImageJPEGRepresentation(image, 0.6);
    NSString *base64String = [imageData base64EncodedStringWithOptions:0];

    // API Call to Gemini
    NSString *urlString = [NSString stringWithFormat:@"https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash:generateContent?key=%@", apiKey];
    NSURL *url = [NSURL URLWithString:urlString];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
    [request setHTTPMethod:@"POST"];
    [request setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];

    NSDictionary *jsonDict = @{
        @"contents": @[@{
            @"parts": @[
                @{@"text": @"Hãy đọc hình ảnh này và chỉ đưa ra đáp án đúng nhất một cách ngắn gọn, chính xác."},
                @{@"inline_data": @{
                    @"mime_type": @"image/jpeg",
                    @"data": base64String
                }}
            ]
        }]
    };

    NSError *error;
    NSData *postData = [NSJSONSerialization dataWithJSONObject:jsonDict options:0 error:&error];
    [request setHTTPBody:postData];

    NSURLSessionDataTask *task = [[NSURLSession.sharedSession dataTaskWithRequest:request completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
        dispatch_async(dispatch_get_main_queue(), ^{
            if (error || !data) {
                resultLabel.text = @"Lỗi kết nối tới Gemini API!";
                return;
            }
            NSDictionary *responseDict = [NSJSONSerialization JSONObjectWithData:data options:0 error:nil];
            @try {
                NSString *text = responseDict[@"candidates"][0][@"content"][@"parts"][0][@"text"];
                resultLabel.text = text ? text : @"Không tìm thấy đáp án.";
            } @catch (NSException *exception) {
                resultLabel.text = @"Lỗi đọc dữ liệu từ Gemini.";
            }
        });
    }] resume];
}

@end

// Hook Gesture into UIViewController
%hook UIViewController

- (void)viewDidLoad {
    %orig;
    
    // Tap 3 lần bằng 1 ngón tay (hoặc chạm 3 ngón) để bật Menu
    UITapGestureRecognizer *tripleTap = [[UITapGestureRecognizer alloc] initWithTarget:[OverlayManager sharedInstance] action:@selector(toggleMenu)];
    tripleTap.numberOfTapsRequired = 3;
    [self.view addGestureRecognizer:tripleTap];
}

%end
