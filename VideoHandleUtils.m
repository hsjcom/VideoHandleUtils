//
//  VideoHandleUtils.m
//  TaQu
//
//  Created by Soldier on 2017/4/19.
//  Copyright © 2017年 Shaojie Hong. All rights reserved.
//

#import "VideoHandleUtils.h"

#define degreesToRadians(x) (M_PI * x / 180.0)
#define radiansToDegrees(x) (180.0 * x / M_PI)

@implementation VideoHandleUtils

+ (BOOL)isMOVVideo:(NSString *)videoPath {
    NSRange range = [videoPath rangeOfString:@"trim."];//匹配得到的下标
    if (range.length == 0) {
        return NO;
    }
    NSString *content = [videoPath substringFromIndex:range.location + 5];
    //视频的后缀
    NSRange rangeSuffix = [content rangeOfString:@"."];
    if (rangeSuffix.length == 0) {
        return NO;
    }
    NSString *suffixName = [content substringFromIndex:rangeSuffix.location + 1];
    //如果视频是mov格式的则转为MP4的
    if ([suffixName isEqualToString:@"MOV"] || [suffixName isEqualToString:@"mov"]) {
        return YES;
    }
    return NO;
}

- (void)changeMovToMp4:(NSURL *)mediaURL
            targetPath:(NSString *)targetPath
             dataBlock:(void (^)(UIImage *movieImage))handler {
    AVAsset *video = [AVAsset assetWithURL:mediaURL];
    AVAssetExportSession *exportSession = [AVAssetExportSession exportSessionWithAsset:video presetName:AVAssetExportPresetMediumQuality];
    exportSession.shouldOptimizeForNetworkUse = YES;
    exportSession.outputFileType = AVFileTypeMPEG4;
    
    NSString *videoPath = [targetPath stringByAppendingPathComponent:targetPath];
    exportSession.outputURL = [NSURL fileURLWithPath:videoPath];
    [exportSession exportAsynchronouslyWithCompletionHandler:^{
        NSURL *url = [NSURL fileURLWithPath:videoPath];
        [self movieToImageHandler:url handler:handler];
    }];
}

//获取视频第一帧的图片
- (void)movieToImageHandler:(NSURL *)url
                    handler:(void (^)(UIImage *movieImage))handler {
//    NSURL *url = [NSURL fileURLWithPath:path];
    AVURLAsset *asset = [[AVURLAsset alloc] initWithURL:url options:nil];
    AVAssetImageGenerator *generator = [[AVAssetImageGenerator alloc] initWithAsset:asset];
    generator.appliesPreferredTrackTransform = TRUE;
    CMTime thumbTime = CMTimeMakeWithSeconds(0, 60);
    generator.apertureMode = AVAssetImageGeneratorApertureModeEncodedPixels;
    AVAssetImageGeneratorCompletionHandler generatorHandler =
    ^(CMTime requestedTime, CGImageRef im, CMTime actualTime, AVAssetImageGeneratorResult result, NSError *error){
        if (result == AVAssetImageGeneratorSucceeded) {
            UIImage *thumbImg = [UIImage imageWithCGImage:im];
            if (handler) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    handler(thumbImg);
                });
            }
        } else {
            if (handler) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    handler(nil);
                });
            }
        }
    };
    [generator generateCGImagesAsynchronouslyForTimes:
    [NSArray arrayWithObject:[NSValue valueWithCMTime:thumbTime]] completionHandler:generatorHandler];
}

/**
 *  mov格式转mp4格式
 *  sourceUrl 原始文件NSUrl
 *  resultPath 输出文件路径 NSString documents路径 Appending file name
 *  方向纠正
 */
- (void)movFileTransformToMP4WithSourceUrl:(NSURL *)sourceUrl
                                outputPath:(NSString *)outputPath
                                completion:(void(^)(NSString *mp4FilePath, NSString *errorMsg))comepleteBlock {
    AVURLAsset *asset = [AVURLAsset URLAssetWithURL:sourceUrl options:nil];
    
    AVMutableComposition *composition;
    AVMutableVideoComposition *videoComposition;
    AVMutableVideoCompositionInstruction *instruction;
    
    AVMutableVideoCompositionLayerInstruction *layerInstruction = nil;
    CGAffineTransform t1;
    CGAffineTransform t2;
    
    AVAssetTrack *assetVideoTrack = nil;
    AVAssetTrack *assetAudioTrack = nil;
    // Check if the asset contains video and audio tracks
    if ([[asset tracksWithMediaType:AVMediaTypeVideo] count] != 0) {
        assetVideoTrack = [[asset tracksWithMediaType:AVMediaTypeVideo] objectAtIndex:0];
    }
    if ([[asset tracksWithMediaType:AVMediaTypeAudio] count] != 0) {
        assetAudioTrack = [[asset tracksWithMediaType:AVMediaTypeAudio] objectAtIndex:0];
    }
    CMTime insertionPoint = kCMTimeInvalid;
    NSError *error = nil;
    
    //composition
    composition = [AVMutableComposition composition];
    if (assetVideoTrack != nil) {
        AVMutableCompositionTrack *compositionVideoTrack = [composition addMutableTrackWithMediaType:AVMediaTypeVideo preferredTrackID:kCMPersistentTrackID_Invalid];
        [compositionVideoTrack insertTimeRange:CMTimeRangeMake(kCMTimeZero, [asset duration]) ofTrack:assetVideoTrack atTime:insertionPoint error:&error];
    }
    if (assetAudioTrack != nil) {
        AVMutableCompositionTrack *compositionAudioTrack = [composition addMutableTrackWithMediaType:AVMediaTypeAudio preferredTrackID:kCMPersistentTrackID_Invalid];
        [compositionAudioTrack insertTimeRange:CMTimeRangeMake(kCMTimeZero, [asset duration]) ofTrack:assetAudioTrack atTime:insertionPoint error:&error];
    }
    
    //方向校正
    float width = assetVideoTrack.naturalSize.width;
    float height = assetVideoTrack.naturalSize.height;
    float toDiagonal = sqrt(width * width + height * height);
    float toDiagonalAngle = radiansToDegrees(acosf(width / toDiagonal));
    float toDiagonalAngle2 = 90 - radiansToDegrees(acosf(width/toDiagonal));
    
    float toDiagonalAngleComple;
    float toDiagonalAngleComple2;
    float finalHeight;
    float finalWidth;
    
    NSInteger degrees = [self.class degressFromVideoFileWithAsset:asset];
    
    if(degrees >= 0 && degrees <= 90){
        toDiagonalAngleComple = toDiagonalAngle + degrees;
        toDiagonalAngleComple2 = toDiagonalAngle2 + degrees;
        
        finalHeight = ABS(toDiagonal * sinf(degreesToRadians(toDiagonalAngleComple)));
        finalWidth = ABS(toDiagonal * sinf(degreesToRadians(toDiagonalAngleComple2)));
        
        t1 = CGAffineTransformMakeTranslation(height * sinf(degreesToRadians(degrees)), 0.0);
    }
    else if(degrees > 90 && degrees <= 180){
        
        float degrees2 = degrees - 90;
        
        toDiagonalAngleComple = toDiagonalAngle + degrees2;
        toDiagonalAngleComple2 = toDiagonalAngle2 + degrees2;
        
        finalHeight = ABS(toDiagonal * sinf(degreesToRadians(toDiagonalAngleComple2)));
        finalWidth = ABS(toDiagonal * sinf(degreesToRadians(toDiagonalAngleComple)));
        
        t1 = CGAffineTransformMakeTranslation(width * sinf(degreesToRadians(degrees2)) + height * cosf(degreesToRadians(degrees2)), height * sinf(degreesToRadians(degrees2)));
    }
    else if(degrees >= -90 && degrees < 0){
        
        float degrees2 = degrees - 90;
        float degreesabs = ABS(degrees);
        
        toDiagonalAngleComple = toDiagonalAngle + degrees2;
        toDiagonalAngleComple2 = toDiagonalAngle2 + degrees2;
        
        finalHeight = ABS(toDiagonal * sinf(degreesToRadians(toDiagonalAngleComple2)));
        finalWidth = ABS(toDiagonal * sinf(degreesToRadians(toDiagonalAngleComple)));
        
        t1 = CGAffineTransformMakeTranslation(0, width * sinf(degreesToRadians(degreesabs)));
        
    }
    else if(degrees >= -180 && degrees < -90){
        
        float degreesabs = ABS(degrees);
        float degreesplus = degreesabs - 90;
        
        toDiagonalAngleComple = toDiagonalAngle + degrees;
        toDiagonalAngleComple2 = toDiagonalAngle2 + degrees;
        
        finalHeight = ABS(toDiagonal * sinf(degreesToRadians(toDiagonalAngleComple)));
        finalWidth = ABS(toDiagonal * sinf(degreesToRadians(toDiagonalAngleComple2)));
        
        t1 = CGAffineTransformMakeTranslation(width * sinf(degreesToRadians(degreesplus)), height * sinf(degreesToRadians(degreesplus)) + width * cosf(degreesToRadians(degreesplus)));
    }
    
    t2 = CGAffineTransformRotate(t1, degreesToRadians(degrees));
    
    //videoComposition
    videoComposition = [AVMutableVideoComposition videoComposition];
    videoComposition.renderSize = CGSizeMake(finalWidth, finalHeight);
    videoComposition.frameDuration = CMTimeMake(1, 30); // 根据实际情况获取，帧率很好获取，写个方法就OK
    
    instruction = [AVMutableVideoCompositionInstruction videoCompositionInstruction];
    
    instruction.timeRange = CMTimeRangeMake(kCMTimeZero, [composition duration]);
    
    layerInstruction = [AVMutableVideoCompositionLayerInstruction videoCompositionLayerInstructionWithAssetTrack:[composition.tracks objectAtIndex:0]];
    [layerInstruction setTransform:t2 atTime:kCMTimeZero];
    
    instruction.layerInstructions = [NSArray arrayWithObject:layerInstruction];
    videoComposition.instructions = [NSArray arrayWithObject:instruction];

    //exportSession
//    NSLog(@"origin: mp4 file size:%lf MB", [NSData dataWithContentsOfURL:sourceUrl].length/1024.f/1024.f);
    NSString *presetName = AVAssetExportPresetMediumQuality;
    NSArray *compatiblePresets = [AVAssetExportSession exportPresetsCompatibleWithAsset:composition];
    if ([compatiblePresets containsObject:AVAssetExportPreset960x540]) {
        presetName = AVAssetExportPreset960x540; //16 : 9
    }
    
    AVAssetExportSession *exportSession = [[AVAssetExportSession alloc] initWithAsset:composition presetName:presetName] ;
    exportSession.outputURL = [NSURL fileURLWithPath:outputPath];
    exportSession.outputFileType = AVFileTypeMPEG4;
    exportSession.videoComposition = videoComposition;
    exportSession.shouldOptimizeForNetworkUse = YES;
    exportSession.timeRange = CMTimeRangeMake(kCMTimeZero, asset.duration);
    
    [exportSession exportAsynchronouslyWithCompletionHandler:^(void) {
//     dispatch_async(dispatch_get_main_queue(), ^{
//
//     });
        
        switch (exportSession.status) {
            case AVAssetExportSessionStatusCompleted:{
                NSUInteger length = [NSData dataWithContentsOfURL:exportSession.outputURL].length /1024.f / 1024.f;
                NSString *errorMsg = nil;
                if (length > 15) {
                    errorMsg = @"视频过大，无法发送哦";
                }
//                NSLog(@"after mp4 file size:%lu MB", (unsigned long)length);
                comepleteBlock(outputPath, errorMsg);
                
                }
                break;
                    
            case AVAssetExportSessionStatusUnknown:
                    
                break;
                    
            case AVAssetExportSessionStatusWaiting:
                    
                break;
                    
            case AVAssetExportSessionStatusExporting:
                    
                break;
                    
            case AVAssetExportSessionStatusFailed:
                    
                break;
                    
            case AVAssetExportSessionStatusCancelled:
                    
                break;
            }
    }];
}

- (void)removeLocalVideoFile:(NSString *)filePath {
    if (![StringUtil isEmpty:filePath]) {
        NSString *path = filePath;
        path = [path stringByReplacingOccurrencesOfString:@"file://" withString:@""];
        if ([[NSFileManager defaultManager] fileExistsAtPath:path]) {
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                NSError *error;
                [[NSFileManager defaultManager] removeItemAtPath:path error:&error];
                if (error) {
//                    NSLog(@"file remove error: %@", error);
                }
            });
        }
    }
}

+ (NSString *)getMP4FilePath:(NSString *)fileName {
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *path = [paths objectAtIndex:0];
    
    NSString *filePath = [NSString stringWithFormat:@"%@.mp4", fileName];
    return [path stringByAppendingPathComponent:filePath];
}

+ (NSString *)getMP4FileName {
    NSInteger random = arc4random();
    random = random < 0 ? -random : random;
    NSString *fileName = [NSString stringWithFormat:@"taqu_ios_post_video_%ld_%.0f", (long)random, [[NSDate date] timeIntervalSince1970]];
    return fileName;
}

- (void)removeFile:(NSURL *)url {
    if (!url) {
        return;
    }
    NSString *filePath = [NSString stringWithFormat:@"%@", url];
    if (![StringUtil isEmpty:filePath]) {
        NSString *path = filePath;
        path = [path stringByReplacingOccurrencesOfString:@"file://" withString:@""];
        if ([[NSFileManager defaultManager] fileExistsAtPath:path]) {
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                NSError *error;
                [[NSFileManager defaultManager] removeItemAtPath:path error:&error];
                if (error) {
//                    NSLog(@"file remove error: %@", error);
                }
            });
        }
    }
}

/*
 * 解决录像保存角度问题
 * 有问题，微信录制的视频只有声音？
 */
- (AVMutableVideoComposition *)getVideoComposition:(AVAsset *)asset {
    NSArray *tracks = [asset tracksWithMediaType:AVMediaTypeVideo];
    if (tracks.count <= 0) {
        return nil;
    }
    AVAssetTrack *videoTrack = [tracks objectAtIndex:0];
    AVMutableComposition *composition = [AVMutableComposition composition];
    AVMutableVideoComposition *videoComposition = [AVMutableVideoComposition videoComposition];
    CGSize videoSize = videoTrack.naturalSize;
    NSUInteger degress = [self.class degressFromVideoFileWithAsset:asset];
    if(degress == 90 || degress == 270) {
//        NSLog(@"video is portrait ");
        videoSize = CGSizeMake(videoSize.height, videoSize.width);
    }
    composition.naturalSize = videoSize;
    videoComposition.renderSize = videoSize;
    // videoComposition.renderSize = videoTrack.naturalSize; //
    videoComposition.frameDuration = CMTimeMakeWithSeconds(1 / videoTrack.nominalFrameRate, 600);
    
    AVMutableCompositionTrack *compositionVideoTrack;
    compositionVideoTrack = [composition addMutableTrackWithMediaType:AVMediaTypeVideo preferredTrackID:kCMPersistentTrackID_Invalid];
    [compositionVideoTrack insertTimeRange:CMTimeRangeMake(kCMTimeZero, asset.duration) ofTrack:videoTrack atTime:kCMTimeZero error:nil];
    AVMutableVideoCompositionLayerInstruction *layerInst;
    layerInst = [AVMutableVideoCompositionLayerInstruction videoCompositionLayerInstructionWithAssetTrack:videoTrack];
    [layerInst setTransform:videoTrack.preferredTransform atTime:kCMTimeZero];
    AVMutableVideoCompositionInstruction *inst = [AVMutableVideoCompositionInstruction videoCompositionInstruction];
    inst.timeRange = CMTimeRangeMake(kCMTimeZero, asset.duration);
    inst.layerInstructions = [NSArray arrayWithObject:layerInst];
    videoComposition.instructions = [NSArray arrayWithObject:inst];
    return videoComposition;
}

/**
 * 获取视频方向(角度)
 */
+ (NSUInteger)degressFromVideoFileWithAsset:(AVAsset *)asset{
    NSUInteger degress = 0;
//    AVAsset *asset = [AVAsset assetWithURL:url];
    NSArray *tracks = [asset tracksWithMediaType:AVMediaTypeVideo];
    if([tracks count] > 0) {
        AVAssetTrack *videoTrack = [tracks objectAtIndex:0];
        CGAffineTransform t = videoTrack.preferredTransform;
        
        degress = atan2(t.b, t.a) * 180 / M_PI;
    }
    return degress;
}

+ (void)requestCameraPermission:(void (^)(BOOL granted))completionBlock {
    if ([AVCaptureDevice respondsToSelector:@selector(requestAccessForMediaType: completionHandler:)]) {
        [AVCaptureDevice requestAccessForMediaType:AVMediaTypeVideo completionHandler:^(BOOL granted) {
            dispatch_async(dispatch_get_main_queue(), ^{
                if(completionBlock) {
                    completionBlock(granted);
                }
            });
        }];
    } else {
        completionBlock(YES);
    }
}

+ (void)requestMicrophonePermission:(void (^)(BOOL granted))completionBlock {
    if([[AVAudioSession sharedInstance] respondsToSelector:@selector(requestRecordPermission:)]) {
        [[AVAudioSession sharedInstance] requestRecordPermission:^(BOOL granted) {
            // return to main thread
            dispatch_async(dispatch_get_main_queue(), ^{
                if(completionBlock) {
                    completionBlock(granted);
                }
            });
        }];
    }
}

+ (BOOL)isFrontCameraAvailable {
    return [UIImagePickerController isCameraDeviceAvailable:UIImagePickerControllerCameraDeviceFront];
}

+ (BOOL)isRearCameraAvailable {
    return [UIImagePickerController isCameraDeviceAvailable:UIImagePickerControllerCameraDeviceRear];
}

+ (BOOL)isAVCaptureDeviceAuthorization {
    AVAuthorizationStatus authStatus = [AVCaptureDevice authorizationStatusForMediaType:AVMediaTypeVideo];
    if (authStatus == AVAuthorizationStatusRestricted || authStatus == AVAuthorizationStatusDenied) {
        return NO;
    } else {
        return YES;
    }
}

@end
