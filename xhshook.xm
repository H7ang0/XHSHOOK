// 主要水印视图
%hook XYPHWatermarkView
- (void)setHidden:(BOOL)hidden {
    %orig(YES);
}
- (void)layoutSubviews {
    %orig;
    self.hidden = YES;
}
%end

// 图片水印层
%hook XYPHImageWatermarkView
- (void)setHidden:(BOOL)hidden {
    %orig(YES);
}
%end

// 实况照片水印
%hook XYPHLivePhotoWatermarkView
- (void)setHidden:(BOOL)hidden {
    %orig(YES);
}
%end

// 视频水印
%hook XYPHVideoWatermarkView
- (void)setHidden:(BOOL)hidden {
    %orig(YES);
}
%end

// 分享菜单控制器
%hook XYPHShareViewController

- (void)viewDidLoad {
    %orig;
    
    UIButton *downloadButton = [UIButton buttonWithType:UIButtonTypeSystem];
    [downloadButton setTitle:@"下载原图/视频" forState:UIControlStateNormal];
    downloadButton.frame = CGRectMake(0, 0, 120, 44);
    [downloadButton addTarget:self action:@selector(handleDownload:) forControlEvents:UIControlEventTouchUpInside];
    
    [self.view addSubview:downloadButton];
    downloadButton.center = CGPointMake(self.view.center.x, self.view.bounds.size.height - 100);
}

%new
- (void)handleDownload:(UIButton *)sender {
    id currentNote = [self valueForKey:@"note"];
    NSString *mediaURL = [currentNote valueForKey:@"mediaURL"];
    
    if (mediaURL) {
        NSURLSession *session = [NSURLSession sharedSession];
        NSURL *url = [NSURL URLWithString:mediaURL];
        NSURLSessionDownloadTask *task = [session downloadTaskWithURL:url completionHandler:^(NSURL *location, NSURLResponse *response, NSError *error) {
            if (!error) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    if ([mediaURL hasSuffix:@".mp4"]) {
                        [[PHPhotoLibrary sharedPhotoLibrary] performChanges:^{
                            [PHAssetChangeRequest creationRequestForAssetFromVideoAtFileURL:location];
                        } completionHandler:^(BOOL success, NSError *error) {
                            if (success) {
                                [self showDownloadSuccess];
                            }
                        }];
                    } else {
                        UIImage *image = [UIImage imageWithData:[NSData dataWithContentsOfURL:location]];
                        UIImageWriteToSavedPhotosAlbum(image, self, @selector(image:didFinishSavingWithError:contextInfo:), nil);
                    }
                });
            }
        }];
        [task resume];
    }
}

%new
- (void)showDownloadSuccess {
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"下载成功" message:@"媒体文件已保存到相册" preferredStyle:UIAlertControllerStyleAlert];
    [alert addAction:[UIAlertAction actionWithTitle:@"确定" style:UIAlertActionStyleDefault handler:nil]];
    [self presentViewController:alert animated:YES completion:nil];
}

%new
- (void)image:(UIImage *)image didFinishSavingWithError:(NSError *)error contextInfo:(void *)contextInfo {
    if (!error) {
        [self showDownloadSuccess];
    }
}
%end

// 媒体浏览控制器
%hook XYPHMediaBrowserViewController

- (void)viewDidLoad {
    %orig;
    
    UILongPressGestureRecognizer *longPress = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(handleLongPress:)];
    [self.view addGestureRecognizer:longPress];
}

%new
- (void)handleLongPress:(UILongPressGestureRecognizer *)gesture {
    if (gesture.state == UIGestureRecognizerStateBegan) {
        id currentMedia = [self valueForKey:@"currentMedia"];
        NSString *mediaURL = [currentMedia valueForKey:@"url"];
        
        if (mediaURL) {
            NSURLSession *session = [NSURLSession sharedSession];
            NSURL *url = [NSURL URLWithString:mediaURL];
            NSURLSessionDownloadTask *task = [session downloadTaskWithURL:url completionHandler:^(NSURL *location, NSURLResponse *response, NSError *error) {
                if (!error) {
                    dispatch_async(dispatch_get_main_queue(), ^{
                        if ([mediaURL hasSuffix:@".mp4"]) {
                            [[PHPhotoLibrary sharedPhotoLibrary] performChanges:^{
                                [PHAssetChangeRequest creationRequestForAssetFromVideoAtFileURL:location];
                            } completionHandler:nil];
                        } else {
                            UIImage *image = [UIImage imageWithData:[NSData dataWithContentsOfURL:location]];
                            UIImageWriteToSavedPhotosAlbum(image, nil, nil, nil);
                        }
                    });
                }
            }];
            [task resume];
        }
    }
}
%end
