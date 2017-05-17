//
//  VideoHandleUtils.h
//  TaQu
//
//  Created by Soldier on 2017/4/19.
//  Copyright © 2017年 Shaojie Hong. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>

@interface VideoHandleUtils : NSObject

+ (BOOL)isMOVVideo:(NSString *)videoPath;

//转换成MP4文件
- (void)changeMovToMp4:(NSURL *)mediaURL
            targetPath:(NSString *)targetPath
             dataBlock:(void (^)(UIImage *movieImage))handler;

//获取视频封面
- (void)movieToImageHandler:(NSURL *)url
                    handler:(void (^)(UIImage *movieImage))handler;

/**
 *  mov格式转mp4格式
 *  sourceUrl 原始文件NSUrl
 *  resultPath 输出文件路径 NSString documents路径 Appending file name
 *  方向纠正
 */
- (void)movFileTransformToMP4WithSourceUrl:(NSURL *)sourceUrl
                                outputPath:(NSString *)outputPath
                                completion:(void(^)(NSString *mp4FilePath, NSString *errorMsg))comepleteBlock;

- (void)removeLocalVideoFile:(NSString *)filePath;

+ (NSString *)getMP4FilePath:(NSString *)fileName;

+ (NSString *)getMP4FileName;

- (void)removeFile:(NSURL *)url;

/**
 * 获取视频方向(角度)
 */
+ (NSUInteger)degressFromVideoFileWithAsset:(AVAsset *)asset;

+ (void)requestCameraPermission:(void (^)(BOOL granted))completionBlock;

+ (void)requestMicrophonePermission:(void (^)(BOOL granted))completionBlock;

+ (BOOL)isFrontCameraAvailable;

+ (BOOL)isRearCameraAvailable;

+ (BOOL)isAVCaptureDeviceAuthorization;


@end
