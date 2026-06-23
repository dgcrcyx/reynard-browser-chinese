//
//  AddressBarMenu.swift
//  Reynard
//
//  Created by Minh Ton on 28/4/26.
//

import UIKit

enum AddressBarMenu {
    private struct Identifier {
        static let addressBarMenu = UIMenu.Identifier("com.minh-ton.Reynard.AddressBarMenu")
        static let manageAddonsMenu = UIMenu.Identifier("com.minh-ton.Reynard.AddressBarMenu.ManageAddons")
    }
    
    struct AddonItem {
        let menuItem: AddonMenuItem
        let image: UIImage?
    }
    
    static func makeMenu(
        selectedURL: String?,
        usesDesktopWebsite: Bool?,
        addonItems: [AddonItem],
        onAddonSelected: @escaping (AddonMenuItem) -> Void,
        onChangeWebsiteMode: @escaping () -> Void,
        onWebsiteSettings: @escaping () -> Void,
        onBookmark: @escaping (Bool) -> Void
    ) -> UIMenu {
        var tabActions: [UIMenuElement] = []
        
        let url = selectedURL.flatMap(URL.init(string:))
        if let url,
           url.host != nil {
            let title = BookmarkStore.shared.bookmark(savedFor: url) == nil ? "添加书签" : "编辑书签"
            tabActions.append(UIAction(title: title, image: UIImage(named: "reynard.book")) { _ in
                onBookmark(false)
            })
            
            if !BookmarkStore.shared.isSavedInFavorites(url) {
                tabActions.append(UIAction(title: "添加到收藏", image: UIImage(named: "reynard.star")) { _ in
                    onBookmark(true)
                })
            }
        }
        
        let addonsChildren: [UIMenuElement]
        if addonItems.isEmpty {
            addonsChildren = [
                UIAction(
                    title: "没有扩展",
                    image: UIImage(named: "reynard.puzzlepiece.extension"),
                    attributes: .disabled
                ) { _ in }
            ]
        } else {
            addonsChildren = addonItems.map { item in
                UIAction(title: item.menuItem.title, image: item.image) { _ in
                    onAddonSelected(item.menuItem)
                }
            }
        }
        
        var pageActions: [UIMenuElement] = [
            UIMenu(
                title: "管理扩展",
                image: UIImage(named: "reynard.puzzlepiece.extension"),
                identifier: Identifier.manageAddonsMenu,
                children: addonsChildren
            )
        ]
        
        if let isDesktop = usesDesktopWebsite {
            let title = isDesktop ? "请求移动版网站" : "请求桌面版网站"
            let imageName = isDesktop ? "reynard.smartphone" : "reynard.desktopcomputer"
            pageActions.append(UIAction(title: title, image: UIImage(named: imageName)) { _ in
                onChangeWebsiteMode()
            })
        }
        
        var settingsActions: [UIMenuElement] = []
        if url?.host != nil {
            settingsActions.append(UIAction(title: "网站设置", image: UIImage(named: "reynard.gear")) { _ in
                onWebsiteSettings()
            })
        }
        
        let children = tabActions + [UIMenu(options: .displayInline, children: pageActions)] + [UIMenu(options: .displayInline, children: settingsActions)]
        
        return UIMenu(title: "", image: nil, identifier: Identifier.addressBarMenu, options: [], children: children)
    }
}
