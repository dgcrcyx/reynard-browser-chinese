//
//  GeneralSettingsSection.swift
//  Reynard
//
//  Created by Minh Ton on 18/6/26.
//

import UIKit

struct GeneralSettingsSection {
    enum Row: CaseIterable {
        case addons
        case browsing
        case search
        case appearance
        case compatibility
    }
    
    var rowCount: Int {
        return Row.allCases.count
    }
    
    func cell(at index: Int) -> UITableViewCell {
        guard Row.allCases.indices.contains(index) else {
            return UITableViewCell()
        }
        
        switch Row.allCases[index] {
        case .addons:
            return SettingsViewUtils.disclosureCell(title: "扩展插件")
        case .browsing:
            return SettingsViewUtils.disclosureCell(title: "浏览设置")
        case .search:
            return SettingsViewUtils.disclosureCell(title: "搜索引擎")
        case .appearance:
            return SettingsViewUtils.disclosureCell(title: "外观主题")
        case .compatibility:
            return SettingsViewUtils.disclosureCell(title: "兼容性")
        }
    }
    
    func selectRow(at index: Int, from viewController: UIViewController) {
        guard Row.allCases.indices.contains(index) else {
            return
        }
        
        let destination: UIViewController
        switch Row.allCases[index] {
        case .addons:
            destination = AddonsPreferencesViewController()
        case .browsing:
            destination = BrowsingPreferencesViewController()
        case .search:
            destination = SearchPreferencesViewController()
        case .appearance:
            destination = AppearancePreferencesViewController()
        case .compatibility:
            destination = CompatibilityPreferencesViewController()
        }
        viewController.navigationController?.pushViewController(destination, animated: true)
    }
}
