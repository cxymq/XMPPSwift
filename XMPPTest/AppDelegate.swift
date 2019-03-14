//
//  AppDelegate.swift
//  XMPPTest
//
//  Created by Qi Wang on 2019/3/5.
//  Copyright © 2019 Qi Wang. All rights reserved.
//

import UIKit

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?


    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.
        
        //开启通知
        let settings = UIUserNotificationSettings(types: [.alert, .badge, .sound],
                                                  categories: nil)
        application.registerUserNotificationSettings(settings)
        
        let loginVC = LoginViewController()
        
        self.window = UIWindow(frame: UIScreen.main.bounds)
        self.window?.rootViewController = loginVC
        
        self.window?.makeKeyAndVisible()
        
        
        return true
    }

    func applicationWillResignActive(_ application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and invalidate graphics rendering callbacks. Games should use this method to pause the game.
    }

    func applicationDidEnterBackground(_ application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
        
        //虽然定义了后台获取的最短时间，但iOS会自行以它认定的最佳时间来唤醒程序，这个我们无法控制
        //UIApplicationBackgroundFetchIntervalMinimum 尽可能频繁的调用我们的Fetch方法
        application.setMinimumBackgroundFetchInterval(UIApplication.backgroundFetchIntervalMinimum)
        
        let status = XmppManager.instance.xmppStream.isConnected()
        print("applicationDidEnterBackground状态\(status)")
    }

    func applicationWillEnterForeground(_ application: UIApplication) {
        // Called as part of the transition from the background to the active state; here you can undo many of the changes made on entering the background.
        let status = XmppManager.instance.xmppStream.isConnected()
        print("applicationWillEnterForeground状态\(status)")
    }

    func applicationDidBecomeActive(_ application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
        let status = XmppManager.instance.xmppStream.isConnected()
        print("applicationDidBecomeActive状态\(status)")
    }

    func applicationWillTerminate(_ application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    }


}

