//
//  ContentPermissionPresentation.swift
//  Reynard
//
//  Created by Minh Ton on 16/6/26.
//

import GeckoView
import Foundation

extension ContentPermission {
    var alertTitle: String? {
        let host = Self.permissionHost(from: uri)
        switch permission {
        case .geolocation:
            return "允许 \(host) 使用你的位置信息吗？"
        case .desktopNotification:
            return "允许 \(host) 发送通知吗？"
        case .persistentStorage:
            return "允许 \(host) 在持久化存储中保存数据吗？"
        case .mediaKeySystemAccess:
            return "允许 \(host) 播放受 DRM 保护的内容吗？"
        case .storageAccess:
            return "允许 \(Self.permissionHost(from: thirdPartyOrigin)) 在 \(host) 上使用它的 Cookie 吗？"
        case .localDeviceAccess:
            return "允许 \(host) 访问此设备上的其他应用和服务吗？"
        case .localNetworkAccess:
            return "允许 \(host) 访问你本地网络中连接设备上的应用和服务吗？"
        case .deviceSensors:
            return "允许 \(host) 使用运动和方向传感器吗？"
        case .camera,
                .microphone,
                .webxr,
                .autoplay,
                .tracking,
            nil:
            return nil
        }
    }
    
    var alertMessage: String? {
        switch permission {
        case .storageAccess:
            return "如果不清楚 \(Self.permissionHost(from: thirdPartyOrigin)) 为什么需要这些数据，你可能想要阻止访问。"
        case .camera,
                .microphone,
                .geolocation,
                .desktopNotification,
                .persistentStorage,
                .webxr,
                .autoplay,
                .mediaKeySystemAccess,
                .tracking,
                .localDeviceAccess,
                .localNetworkAccess,
                .deviceSensors,
            nil:
            return nil
        }
    }
    
    static func mediaAlertTitle(uri: String, videoRequested: Bool, audioRequested: Bool) -> String {
        let host = permissionHost(from: uri)
        switch (videoRequested, audioRequested) {
        case (true, true):
            return "允许 \(host) 使用你的相机和麦克风吗？"
        case (true, false):
            return "允许 \(host) 使用你的相机吗？"
        case (false, true):
            return "允许 \(host) 使用你的麦克风吗？"
        case (false, false):
            return "允许 \(host) 使用你的相机和麦克风吗？"
        }
    }
}
