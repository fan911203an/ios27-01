//
//  AnimHome.x — 桌面与图标动效
//  点击图标：整屏缩向该图标（真 iOS 26 zoom） + 图标液态回弹 + 文件夹柔和淡入
//
#import "iOS27Animations.h"

@interface SBIconImageView : UIView @end
@interface SBIconView : UIView
- (void)_launchFromLocation:(id)location context:(id)context;
@end
@interface SBFolderController : UIViewController @end

// 点击图标启动 App：拿到真实图标位置，整屏缩向它（iOS 26 zoom-out）
%hook SBIconView
- (void)_launchFromLocation:(id)location context:(id)context {
    [[IOS27ZoomOverlay shared] zoomOutToIconView:self];
    %orig;
}
%end

// 图标：iOS 26 大圆角（continuous squircle） + 液态回弹
%hook SBIconImageView
- (void)layoutSubviews {
    %orig;
    if (self.bounds.size.width < 20) return;

    BOOL on = IOS27Enabled() && IOS27Home();
    if (on) {
        // iOS 26 图标圆角明显大于 iOS 16（约 0.225 → 0.26，且用连续曲率）
        self.layer.cornerRadius  = self.bounds.size.width * 0.26;
        self.layer.cornerCurve   = kCACornerCurveContinuous;
        self.layer.masksToBounds = YES;
    } else {
        // 开关关闭时恢复 iOS 16 原始圆角，不留痕迹
        self.layer.cornerRadius  = self.bounds.size.width * 0.225;
        self.layer.masksToBounds = NO;
    }

    if (on) {
        static NSString *const bounced = @"ios26_iconBounced";
        if (![self.layer valueForKey:bounced]) {
            [self.layer setValue:@YES forKey:bounced];
            IOS27BounceLayer(self.layer);
        }
    }
}
%end

// 文件夹：轻微缩放 + 淡入，不使用圆角裁剪（避免白边/白影）
%hook SBFolderController
- (void)viewWillAppear:(BOOL)animated {
    %orig;
    if (!IOS27Enabled() || !IOS27Home()) return;
    self.view.alpha = 0.94;
    self.view.transform = CGAffineTransformMakeScale(0.96, 0.96);
    [UIView animateWithDuration:0.42
                          delay:0
         usingSpringWithDamping:0.9
          initialSpringVelocity:0.18
                        options:UIViewAnimationOptionCurveEaseOut | UIViewAnimationOptionBeginFromCurrentState
                     animations:^{
        self.view.transform = CGAffineTransformIdentity;
        self.view.alpha = 1.0;
    } completion:nil];
}
%end
