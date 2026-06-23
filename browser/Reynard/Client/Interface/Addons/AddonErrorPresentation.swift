//
//  AddonErrorPresentation.swift
//  Reynard
//
//  Created by Minh Ton on 24/5/26.
//

import Foundation

public struct AddonErrorPresentation {
    public let statusText: String?
    public let alertMessage: String
    public let isUserCancelled: Bool
}

public struct AddonErrorPresenter {
    public static func updateRequiresPermissions(_ error: Error) -> Bool {
        return normalizeCode(installErrorDetails(from: error).code) == "ERROR_POSTPONED"
    }
    
    public static func installErrorPresentation(
        for error: Error,
        addonName: String?
    ) -> AddonErrorPresentation {
        let details = installErrorDetails(from: error)
        return presentation(
            code: details.code,
            addonName: addonName,
            isInstallation: true,
            cancelledByUser: details.cancelledByUser
        )
    }
    
    public static func updateErrorPresentation(
        for error: Error,
        addonName: String?
    ) -> AddonErrorPresentation {
        let details = installErrorDetails(from: error)
        return presentation(
            code: details.code,
            addonName: addonName,
            isInstallation: false,
            cancelledByUser: details.cancelledByUser
        )
    }
    
    private static func installErrorDetails(from error: Error) -> (code: String?, cancelledByUser: Bool) {
        guard let value = Mirror(reflecting: error).descendant("value") as? [String: Any?] else {
            return (nil, false)
        }
        
        let installError: String?
        if let number = value["installError"] as? NSNumber {
            installError = number.stringValue
        } else if let number = value["code"] as? NSNumber {
            installError = number.stringValue
        } else if let string = value["installError"] as? String {
            installError = string
        } else if let string = value["code"] as? String {
            installError = string
        } else {
            installError = nil
        }
        
        let cancelledByUser: Bool
        if let value = value["cancelledByUser"] as? NSNumber {
            cancelledByUser = value.boolValue
        } else if let value = value["cancelledByUser"] as? Bool {
            cancelledByUser = value
        } else {
            cancelledByUser = false
        }
        
        return (installError, cancelledByUser)
    }
    
    private static func presentation(
        code: String?,
        addonName: String?,
        isInstallation: Bool,
        cancelledByUser: Bool = false
    ) -> AddonErrorPresentation {
        let trimmedAddonName = addonName?.trimmingCharacters(in: .whitespacesAndNewlines)
        let resolvedAddonName: String
        if let trimmedAddonName, !trimmedAddonName.isEmpty {
            resolvedAddonName = trimmedAddonName
        } else {
            resolvedAddonName = "此扩展"
        }
        let normalizedCode = normalizeCode(code)
        
        if cancelledByUser || normalizedCode == "ERROR_USER_CANCELED" || normalizedCode == "ERROR_ABORTED" {
            return AddonErrorPresentation(
                statusText: nil,
                alertMessage: isInstallation ? defaultInstallMessage(for: trimmedAddonName) : "更新扩展失败。",
                isUserCancelled: true
            )
        }
        
        switch normalizedCode {
        case "ERROR_BLOCKLISTED":
            return AddonErrorPresentation(
                statusText: "已阻止",
                alertMessage: "\(resolvedAddonName) 违反了 Mozilla 的政策，无法在 Reynard 上安装。",
                isUserCancelled: false
            )
        case "ERROR_SOFT_BLOCKED":
            return AddonErrorPresentation(
                statusText: "受限",
                alertMessage: "\(resolvedAddonName) 受到限制，无法在 Reynard 上安装。",
                isUserCancelled: false
            )
        case "ERROR_NETWORK_FAILURE":
            return AddonErrorPresentation(
                statusText: "网络错误",
                alertMessage: "由于连接失败，无法下载此扩展。",
                isUserCancelled: false
            )
        case "ERROR_CORRUPT_FILE":
            return AddonErrorPresentation(
                statusText: "文件损坏",
                alertMessage: "此扩展似乎已损坏，无法安装。",
                isUserCancelled: false
            )
        case "ERROR_SIGNEDSTATE_REQUIRED":
            return AddonErrorPresentation(
                statusText: "未验证",
                alertMessage: "此扩展未经验证，无法安装。",
                isUserCancelled: false
            )
        case "ERROR_INCOMPATIBLE":
            return AddonErrorPresentation(
                statusText: "不兼容",
                alertMessage: "\(resolvedAddonName) 与此版本的 Reynard 不兼容，无法安装。",
                isUserCancelled: false
            )
        case "ERROR_ADMIN_INSTALL_ONLY":
            return AddonErrorPresentation(
                statusText: "仅管理员",
                alertMessage: "\(resolvedAddonName) 只能由使用企业策略的组织安装，而此平台不支持企业策略，因此无法安装。",
                isUserCancelled: false
            )
        default:
            return AddonErrorPresentation(
                statusText: isInstallation ? "错误" : "更新失败",
                alertMessage: isInstallation ? defaultInstallMessage(for: trimmedAddonName) : "更新扩展失败。",
                isUserCancelled: false
            )
        }
    }
    
    private static func defaultInstallMessage(for addonName: String?) -> String {
        if let addonName, !addonName.isEmpty {
            return "安装 \(addonName) 失败。"
        }
        return "安装此扩展失败。"
    }
    
    private static func normalizeCode(_ code: String?) -> String? {
        guard let code = code?.trimmingCharacters(in: .whitespacesAndNewlines), !code.isEmpty else {
            return nil
        }
        
        switch code {
        case "-1", "ERROR_NETWORK_FAILURE":
            return "ERROR_NETWORK_FAILURE"
        case "-3", "ERROR_CORRUPT_FILE":
            return "ERROR_CORRUPT_FILE"
        case "-5", "ERROR_SIGNEDSTATE_REQUIRED":
            return "ERROR_SIGNEDSTATE_REQUIRED"
        case "-10", "ERROR_BLOCKLISTED":
            return "ERROR_BLOCKLISTED"
        case "-11", "ERROR_INCOMPATIBLE":
            return "ERROR_INCOMPATIBLE"
        case "-13", "ERROR_ADMIN_INSTALL_ONLY":
            return "ERROR_ADMIN_INSTALL_ONLY"
        case "-14", "ERROR_SOFT_BLOCKED":
            return "ERROR_SOFT_BLOCKED"
        case "-12", "ERROR_POSTPONED":
            return "ERROR_POSTPONED"
        case "-100", "ERROR_USER_CANCELED", "ERROR_USER_CANCELLED":
            return "ERROR_USER_CANCELED"
        default:
            return code
        }
    }
}
