//
//  SiteSettingsUtils.swift
//  Reynard
//
//  Created by Minh Ton on 17/6/26.
//

import AVFoundation
import CoreLocation
import GeckoView
import UIKit

enum SiteSettingsUtils {
    static func isCameraPermissionDisabled() -> Bool {
        let status = AVCaptureDevice.authorizationStatus(for: .video)
        return status == .restricted || status == .denied
    }
    
    static func isMicrophonePermissionDisabled() -> Bool {
        let status = AVCaptureDevice.authorizationStatus(for: .audio)
        return status == .restricted || status == .denied
    }
    
    static func isLocationPermissionDisabled() -> Bool {
        let status = CLLocationManager.authorizationStatus()
        return status == .restricted || status == .denied
    }
    
    static func isSystemDisabled(_ permission: SitePermission) -> Bool {
        switch permission {
        case .camera:
            return isCameraPermissionDisabled()
        case .microphone:
            return isMicrophonePermissionDisabled()
        case .location:
            return isLocationPermissionDisabled()
        default:
            return false
        }
    }
    
    static func disabledPermissionNames() -> [String] {
        var permissions: [String] = []
        
        if isCameraPermissionDisabled() {
            permissions.append("相机")
        }
        if isMicrophonePermissionDisabled() {
            permissions.append("麦克风")
        }
        if isLocationPermissionDisabled() {
            permissions.append("位置")
        }
        
        return permissions
    }
    
    static func disabledPermissionMessage() -> String {
        let names = disabledPermissionNames()
        let permissionList = formattedPermissionList(names)
        
        if names.count == 1 {
            return "\(permissionList) 当前已对 Reynard 禁用。请打开设置应用以启用此权限。"
        }
        
        return "\(permissionList) 当前已对 Reynard 禁用。请打开设置应用以启用这些权限。"
    }
    
    // MARK: - Permission Actions
    
    static func actionTitles(for permission: SitePermission) -> [String] {
        [.allowed, .askToAllow, .blocked].map {
            actionTitle(for: $0, permission: permission)
        }
    }
    
    static func actionTitle(for action: SitePermissionAction, permission: SitePermission) -> String {
        switch permission {
        case .autoplay:
            switch action {
            case .allowed:
                return "允许音频和视频"
            case .askToAllow:
                return "仅阻止音频"
            case .blocked:
                return "阻止音频和视频"
            }
        default:
            switch action {
            case .allowed:
                return "允许"
            case .askToAllow:
                return "询问"
            case .blocked:
                return "拒绝"
            }
        }
    }
    
    static func defaultAction(for permission: SitePermission) -> SitePermissionAction {
        if isSystemDisabled(permission) {
            return .blocked
        }
        
        switch permission {
        case .autoplay:
            return Prefs.SitePermissionSettings.defaultAutoplayPermission
        case .camera:
            return Prefs.SitePermissionSettings.defaultCameraPermission
        case .microphone:
            return Prefs.SitePermissionSettings.defaultMicrophonePermission
        case .location:
            return Prefs.SitePermissionSettings.defaultLocationPermission
        case .persistentStorage:
            return Prefs.SitePermissionSettings.defaultPersistentStoragePermission
        case .crossOriginStorageAccess:
            return Prefs.SitePermissionSettings.defaultCrossOriginStorageAccessPermission
        case .localDeviceAccess:
            return Prefs.SitePermissionSettings.defaultLocalDeviceAccessPermission
        case .localNetworkAccess:
            return Prefs.SitePermissionSettings.defaultLocalNetworkAccessPermission
        case .notification:
            return .askToAllow
        case .mediaKeySystemAccess:
            return .askToAllow
        }
    }
    
    static func setDefaultAction(_ action: SitePermissionAction, for permission: SitePermission) {
        switch permission {
        case .autoplay:
            Prefs.SitePermissionSettings.defaultAutoplayPermission = action
        case .camera:
            Prefs.SitePermissionSettings.defaultCameraPermission = action
        case .microphone:
            Prefs.SitePermissionSettings.defaultMicrophonePermission = action
        case .location:
            Prefs.SitePermissionSettings.defaultLocationPermission = action
        case .persistentStorage:
            Prefs.SitePermissionSettings.defaultPersistentStoragePermission = action
        case .crossOriginStorageAccess:
            Prefs.SitePermissionSettings.defaultCrossOriginStorageAccessPermission = action
        case .localDeviceAccess:
            Prefs.SitePermissionSettings.defaultLocalDeviceAccessPermission = action
        case .localNetworkAccess:
            Prefs.SitePermissionSettings.defaultLocalNetworkAccessPermission = action
        case .notification:
            return
        case .mediaKeySystemAccess:
            return
        }
    }
    
    // MARK: - Gecko Permissions
    
    static func geckoKey(for permission: SitePermission) -> String {
        switch permission {
        case .location:
            return "geo"
        default:
            return permission.rawValue
        }
    }
    
    static func clearGeckoPermission(for permission: SitePermission, host: String) {
        let key = geckoKey(for: permission)
        let origins = permissionOrigins(for: host)
        
        for origin in origins {
            PermissionDelegate.removePermission(
                uri: origin,
                permissionKey: key,
                privateMode: false
            )
        }
        
        Task {
            for origin in origins {
                let permissions = (try? await PermissionDelegate.permissions(
                    for: origin,
                    privateMode: false
                )) ?? []
                
                for resolvedPermission in permissions {
                    guard SitePermission(contentPermission: resolvedPermission) == permission else {
                        continue
                    }
                    
                    PermissionDelegate.removePermission(resolvedPermission)
                }
            }
        }
    }
    
    private static func permissionOrigins(for host: String) -> [String] {
        guard let host = URLUtils.normalizedHost(host) else {
            return []
        }
        
        return ["http://\(host)", "https://\(host)"]
    }
    
    // MARK: - UI Helpers
    
    static func openAppSettings() {
        guard let url = URL(string: UIApplication.openSettingsURLString) else {
            return
        }
        
        UIApplication.shared.open(url, options: [:], completionHandler: nil)
    }
    
    static func makeDismissButton(target: Any?, action: Selector) -> UIBarButtonItem {
        let button: UIBarButtonItem
        if #available(iOS 26.0, *) {
            button = UIBarButtonItem(barButtonSystemItem: .cancel, target: target, action: action)
            button.tintColor = .label
        } else {
            button = UIBarButtonItem(barButtonSystemItem: .done, target: target, action: action)
        }
        return button
    }
    
    private static func formattedPermissionList(_ names: [String]) -> String {
        if names.isEmpty {
            return ""
        }
        
        if names.count == 1 {
            return names[0]
        }
        
        if names.count == 2 {
            return "\(names[0])和\(names[1])"
        }
        
        let head = names.dropLast().joined(separator: "、")
        let tail = names[names.count - 1]
        return "\(head)和\(tail)"
    }
}
