////
////  UnityEmbededSwift.swift
////  PlayCardAR
////
////  Created by NgocHTN6 on 24/11/2022.
//
//import Foundation
//import UnityFramework
//class UnityEmbeddedSwift: UIResponder, UIApplicationDelegate {
//
//    // The structure for Unity messages
//    private struct UnityMessage {
//        let objectName: String?
//        let methodName: String?
//        let messageBody: String?
//    }
//
//    private var cachedMessages = [UnityMessage]() // Array of cached messages
//    static let shared = UnityEmbeddedSwift()
//
//    private let dataBundleId: String = "com.unity3d.framework"
//    private let frameworkPath: String = "/Frameworks/UnityFramework.framework"
//
//    private var ufw : UnityFramework?
//    private var hostMainWindow : UIWindow?
//
//    private var isInitialized: Bool {
//        ufw?.appController() != nil
//    }
//
//    func show() {
//        if isInitialized {
//            showWindow()
//        } else {
//            initWindow()
//        }
//    }
//
//    func setHostMainWindow(_ hostMainWindow: UIWindow?) {
//        self.hostMainWindow = hostMainWindow
//    }
//
//    private func initWindow() {
//        if isInitialized {
//            showWindow()
//            return
//        }
//
//        guard let ufw = loadUnityFramework() else {
//            print("ERROR: Was not able to load Unity")
//            return unloadWindow()
//        }
//
//        self.ufw = ufw
//        ufw.setDataBundleId(dataBundleId)
//        ufw.register(self)
//        ufw.runEmbedded(
//            withArgc: CommandLine.argc,
//            argv: CommandLine.unsafeArgv,
//            appLaunchOpts: nil
//        )
//
//        sendCachedMessages() // Added this line
//    }
//
//    private func showWindow() {
//        if isInitialized {
//            ufw?.showUnityWindow()
//            sendCachedMessages() // Added this line
//        }
//    }
//
//    private func unloadWindow() {
//        if isInitialized {
//            cachedMessages.removeAll() // Added this line
//            ufw?.unloadApplication()
//        }
//    }
//
//    private func loadUnityFramework() -> UnityFramework? {
//        let bundlePath: String = Bundle.main.bundlePath + frameworkPath
//
//        let bundle = Bundle(path: bundlePath)
//        if bundle?.isLoaded == false {
//            bundle?.load()
//        }
//
//        let ufw = bundle?.principalClass?.getInstance()
//        if ufw?.appController() == nil {
//            let machineHeader = UnsafeMutablePointer<MachHeader>.allocate(capacity: 1)
//            machineHeader.pointee = _mh_execute_header
//
//            ufw?.setExecuteHeader(machineHeader)
//        }
//        return ufw
//    }
//
//    // Main method for sending a message to Unity
//    func sendMessage(
//        _ objectName: String,
//        methodName: String,
//        message: String
//    ) {
//        let msg: UnityMessage = UnityMessage(
//            objectName: objectName,
//            methodName: methodName,
//            messageBody: message
//        )
//
//        // Send the message right away if Unity is initialized, else cache it
//        if isInitialized {
//            ufw?.sendMessageToGO(
//                withName: msg.objectName,
//                functionName: msg.methodName,
//                message: msg.messageBody
//            )
//        } else {
//            cachedMessages.append(msg)
//        }
//    }
//
//    // Send all previously cached messages, if any
//    private func sendCachedMessages() {
//        if cachedMessages.count >= 0 && isInitialized {
//            for msg in cachedMessages {
//                ufw?.sendMessageToGO(
//                    withName: msg.objectName,
//                    functionName: msg.methodName,
//                    message: msg.messageBody
//                )
//            }
//
//            cachedMessages.removeAll()
//        }
//    }
//}
//
//extension UnityEmbeddedSwift: UnityFrameworkListener {
//
//    func unityDidUnload(_ notification: Notification!) {
//        ufw?.unregisterFrameworkListener(self)
//        ufw = nil
//        hostMainWindow?.makeKeyAndVisible()
//    }
//}
//
////class UnityEmbeddedSwift: UIResponder, UIApplicationDelegate, UnityFrameworkListener {
////
////    private struct UnityMessage {
////        let objectName: String?
////        let methodName: String?
////        let messageBody: String?
////    }
////
////    private static var instance: UnityEmbeddedSwift!
////    private var unityFrameWork: UnityFramework!
////    private static var hostMainWindow: UIWindow! // Window to return to when exiting Unity window
////    private static var launchOpts: [UIApplication.LaunchOptionsKey: Any]?
////
////    private static var cachedMessages = [UnityMessage]()
////
////    // MARK: - Static functions (that can be called from other scripts)
////
////    static func getUnityRootViewController() -> UIViewController! {
////        return instance.unityFrameWork.appController()?.rootViewController
////    }
////
////    static func getUnityView() -> UIView! {
////        return instance.unityFrameWork.appController()?.rootViewController?.view
////    }
////
////    static func unityWindow() -> UIWindow? {
////        return instance.unityFrameWork.appController().window
////    }
////
////    static func setHostMainWindow(_ hostMainWindow: UIWindow?) {
////        UnityEmbeddedSwift.hostMainWindow = hostMainWindow
////        let value = UIInterfaceOrientation.landscapeLeft.rawValue
////        UIDevice.current.setValue(value, forKey: "orientation")
////    }
////
////    static func setLaunchinOptions(_ launchingOptions: [UIApplication.LaunchOptionsKey: Any]?) {
////        UnityEmbeddedSwift.launchOpts = launchingOptions
////    }
////
////    static func showUnity() {
////        if UnityEmbeddedSwift.instance == nil || UnityEmbeddedSwift.instance.unityIsInitialized() == false {
////            UnityEmbeddedSwift().initUnityWindow()
////        } else {
////            UnityEmbeddedSwift.instance.showUnityWindow()
////        }
////    }
////
////    static func hideUnity() {
////        UnityEmbeddedSwift.instance?.hideUnityWindow()
////    }
////
////    static func pauseUnity() {
////        UnityEmbeddedSwift.instance?.pauseUnityWindow()
////    }
////
////    static func unpauseUnity() {
////        UnityEmbeddedSwift.instance?.unpauseUnityWindow()
////    }
////
////    static func unloadUnity() {
////        UnityEmbeddedSwift.instance?.unloadUnityWindow()
////    }
////
////    static func sendUnityMessage(_ objectName: String, methodName: String, message: String) {
////        let msg: UnityMessage = UnityMessage(objectName: objectName, methodName: methodName, messageBody: message)
////
////        // Send the message right away if Unity is initialized, else cache it
////        if UnityEmbeddedSwift.instance != nil && UnityEmbeddedSwift.instance.unityIsInitialized() {
////            UnityEmbeddedSwift.instance.unityFrameWork.sendMessageToGO(withName: msg.objectName,
////                                                            functionName: msg.methodName,
////                                                            message: msg.messageBody)
////        } else {
////            UnityEmbeddedSwift.cachedMessages.append(msg)
////        }
////    }
////
////    // MARK: Callback from UnityFrameworkListener
////
////    func unityDidUnload(_ notification: Notification!) {
////        unityFrameWork.unregisterFrameworkListener(self)
////        unityFrameWork = nil
////        UnityEmbeddedSwift.hostMainWindow?.makeKeyAndVisible()
////    }
////
////    // MARK: - Private functions (called within the class)
////
////    private func unityIsInitialized() -> Bool {
////        return unityFrameWork != nil && (unityFrameWork.appController() != nil)
////    }
////
////    private func initUnityWindow() {
////        if unityIsInitialized() {
////            showUnityWindow()
////            return
////        }
////
////        unityFrameWork = unityFrameworkLoad()!
////        unityFrameWork.setDataBundleId("com.unity3d.framework")
////        unityFrameWork.register(self)
////        //        NSClassFromString("FrameworkLibAPI")?.registerAPIforNativeCalls(self)
////
////        unityFrameWork.runEmbedded(withArgc: CommandLine.argc,
////                        argv: CommandLine.unsafeArgv,
////                        appLaunchOpts: UnityEmbeddedSwift.launchOpts)
////
////        sendUnityMessageToGameObject()
////
////        UnityEmbeddedSwift.instance = self
////    }
////
////    private func showUnityWindow() {
////        if unityIsInitialized() {
////            unityFrameWork.showUnityWindow()
////            sendUnityMessageToGameObject()
////        }
////    }
////
////    private func hideUnityWindow() {
////        if UnityEmbeddedSwift.hostMainWindow == nil {
////            print("WARNING: hostMainWindow is nil! Cannot switch from Unity window to previous window")
////        } else {
////            UnityEmbeddedSwift.hostMainWindow?.makeKeyAndVisible()
////        }
////    }
////
////    private func pauseUnityWindow() {
////        unityFrameWork.pause(true)
////    }
////
////    private func unpauseUnityWindow() {
////        unityFrameWork.pause(false)
////    }
////
////    private func unloadUnityWindow() {
////        if unityIsInitialized() {
////            UnityEmbeddedSwift.cachedMessages.removeAll()
////            unityFrameWork.unloadApplication()
////        }
////    }
////
////    private func sendUnityMessageToGameObject() {
////        if UnityEmbeddedSwift.cachedMessages.count >= 0 && unityIsInitialized() {
////            for msg in UnityEmbeddedSwift.cachedMessages {
////                unityFrameWork.sendMessageToGO(withName: msg.objectName,
////                                               functionName: msg.methodName,
////                                               message: msg.messageBody)
////            }
////            UnityEmbeddedSwift.cachedMessages.removeAll()
////        }
////    }
////
////    private func unityFrameworkLoad() -> UnityFramework? {
////        let bundlePath: String = Bundle.main.bundlePath + "/Frameworks/UnityFramework.framework"
////
////        let bundle = Bundle(path: bundlePath )
////        if bundle?.isLoaded == false {
////            bundle?.load()
////        }
////
////        let ufw = bundle?.principalClass?.getInstance()
////        if ufw?.appController() == nil {
////            // unity is not initialized
////            //            ufw?.executeHeader = &mh_execute_header
////
////            let machineHeader = UnsafeMutablePointer<MachHeader>.allocate(capacity: 1)
////            machineHeader.pointee = _mh_execute_header
////
////            ufw!.setExecuteHeader(machineHeader)
////        }
////        return ufw
////    }
////}
//
