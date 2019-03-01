// # vibration-tracking-app
// To design an IOS APP that can leverage existing sensors equipped on a smart phone to track vibration statistics of a   road/street while driving, walking or riding a bike.
// Data and statistics (e.g., distributions) are expected to be shown on a map and the route with appropriate visualization techniques, for example, in the form of color scale.
// Open-source map API, such as Google Map or OpenStreet Map, can be used.


// 获取加速度数据

import <CoreMotion/CoreMotion.h>

@property(strong,nonatomic)CMMotionManager *Manager;

self.Manager = [[CMMotionManager alloc]init];

    NSOperationQueue *queque = [[NSOperationQueue alloc]init];

    if (self.Manager.accelerometerActive) {

        //设置CMMotionManager 的加速度更新频率为0.1s

        self.Manager.accelerometerUpdateInterval = 0.1;

        //使用代码块开始获取加速度数据

        [self.Manager startAccelerometerUpdatesToQueue:queque withHandler:^(CMAccelerometerData * _Nullable accelerometerData, NSError * _Nullable error) {

            if(error){

                [self.Manager stopAccelerometerUpdates];

                NSLog(@"获取加速度数据错误%@",error);

            }else{

                    //分别获取系统x y z 加速度数据

                NSLog(@"x-----------%lf",accelerometerData.acceleration.x);

                NSLog(@"y-----------%lf",accelerometerData.acceleration.y);

                NSLog(@"x-----------%lf",accelerometerData.acceleration.z);

            }

        }];

    }else{

        NSLog(@"你的设备不支持加速度数据");

    }
    
    
    
    
    //连续获取加速度数据
    static const NSTimeInterval accelerometerMin = 0.01;
- (void)startUpdatesWithSliderValue:(int)sliderValue {
    // Determine the update interval.
    NSTimeInterval delta = 0.005;
    NSTimeInterval updateInterval = accelerometerMin + delta * sliderValue;
    // Create a CMMotionManager object.
    CMMotionManager *mManager = [(APLAppDelegate *)
            [[UIApplication sharedApplication] delegate] sharedManager];
    APLAccelerometerGraphViewController * __weak weakSelf = self;
    // Check whether the accelerometer is available.
    if ([mManager isAccelerometerAvailable] == YES) {
        // Assign the update interval to the motion manager.
        [mManager setAccelerometerUpdateInterval:updateInterval];
        [mManager startAccelerometerUpdatesToQueue:[NSOperationQueue mainQueue]
               withHandler:^(CMAccelerometerData *accelerometerData, NSError *error) {
        [weakSelf.graphView addX:accelerometerData.acceleration.x 
                  y:accelerometerData.acceleration.y 
                  z:accelerometerData.acceleration.z];
        [weakSelf setLabelValueX:accelerometerData.acceleration.x 
                  y:accelerometerData.acceleration.y 
                  z:accelerometerData.acceleration.z];
      }];
   }
   self.updateIntervalLabel.text = [NSString stringWithFormat:@"%f", updateInterval];
}
- (void)stopUpdates {
   CMMotionManager *mManager = [(APLAppDelegate *)
            [[UIApplication sharedApplication] delegate] sharedManager];
   if ([mManager isAccelerometerActive] == YES) {
      [mManager stopAccelerometerUpdates];
   }
}
    
    
