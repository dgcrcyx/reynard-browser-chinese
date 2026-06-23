//
//  SearchEnginePreferencesViewController.swift
//  Reynard
//
//  Created by Minh Ton on 18/6/26.
//

import UIKit

final class SearchEnginePreferencesViewController: SettingsTableViewController, UITextFieldDelegate {
    private enum Section: CaseIterable {
        case engines
        case customTemplate
        
        var text: SettingsSectionText {
            switch self {
            case .engines:
                return SettingsSectionText(headerTitle: "搜索引擎")
            case .customTemplate:
                return SettingsSectionText()
            }
        }
    }
    
    private enum CustomTemplateRow: CaseIterable {
        case template
    }
    
    private var displayedSections: [Section] {
        return Prefs.SearchSettings.searchEngine == .custom ? Section.allCases : [.engines]
    }
    
    init() {
        super.init(style: .insetGrouped)
        title = "搜索引擎"
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        registerCells()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        tableView.reloadData()
    }
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        displayedSections.count
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        guard displayedSections.indices.contains(section) else {
            return 0
        }
        
        switch displayedSections[section] {
        case .engines:
            return SearchEngine.allCases.count
        case .customTemplate:
            return CustomTemplateRow.allCases.count
        }
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard displayedSections.indices.contains(indexPath.section) else {
            return UITableViewCell()
        }
        
        switch displayedSections[indexPath.section] {
        case .customTemplate:
            guard CustomTemplateRow.allCases.indices.contains(indexPath.row) else {
                return UITableViewCell()
            }
            switch CustomTemplateRow.allCases[indexPath.row] {
            case .template:
                guard let cell = tableView.dequeueReusableCell(withIdentifier: "CustomSearchTemplateCell", for: indexPath) as? CustomSearchTemplateCell else {
                    return UITableViewCell()
                }
                cell.textField.delegate = self
                cell.textField.placeholder = "https://example.com/search?q=%s"
                cell.textField.text = Prefs.SearchSettings.customSearchTemplate
                return cell
            }
        case .engines:
            guard SearchEngine.allCases.indices.contains(indexPath.row) else {
                return UITableViewCell()
            }
            let engine = SearchEngine.allCases[indexPath.row]
            let cell = UITableViewCell(style: .default, reuseIdentifier: nil)
            cell.textLabel?.text = engine.displayName
            cell.accessoryType = Prefs.SearchSettings.searchEngine == engine ? .checkmark : .none
            return cell
        }
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        defer { tableView.deselectRow(at: indexPath, animated: true) }
        guard displayedSections.indices.contains(indexPath.section),
              displayedSections[indexPath.section] == .engines,
              SearchEngine.allCases.indices.contains(indexPath.row) else { return }
        let selectedEngine = SearchEngine.allCases[indexPath.row]
        let wasCustom = Prefs.SearchSettings.searchEngine == .custom
        Prefs.SearchSettings.searchEngine = selectedEngine
        if wasCustom != (selectedEngine == .custom) {
            tableView.reloadData()
        } else {
            tableView.reloadSections(IndexSet(integer: indexPath.section), with: .none)
        }
        if selectedEngine == .custom {
            DispatchQueue.main.async { [weak self] in
                guard let self,
                      let section = self.displayedSections.firstIndex(of: .customTemplate),
                      let cell = self.tableView.cellForRow(at: IndexPath(row: 0, section: section)) as? CustomSearchTemplateCell else { return }
                cell.textField.becomeFirstResponder()
            }
        }
    }
    
    override func sectionText(for section: Int) -> SettingsSectionText {
        guard displayedSections.indices.contains(section) else {
            return SettingsSectionText()
        }
        
        let displayedSection = displayedSections[section]
        guard displayedSection == .customTemplate else {
            return displayedSection.text
        }
        let baseText = "输入包含 %s 的 URL，%s 将被替换为搜索词"
        guard !Prefs.SearchSettings.customSearchTemplate.isEmpty,
              SearchEngine.canSearch(using: Prefs.SearchSettings.customSearchTemplate) else {
            return SettingsSectionText(footerTitle: baseText)
        }
        return SettingsSectionText(footerTitle: "\(baseText)。当前值必须是有效的 http(s) URL。")
    }
    
    func textFieldDidEndEditing(_ textField: UITextField) {
        Prefs.SearchSettings.customSearchTemplate = textField.text ?? ""
        tableView.reloadData()
        let customQueryTemplate = Prefs.SearchSettings.customSearchTemplate
        guard !customQueryTemplate.isEmpty, !SearchEngine.canSearch(using: customQueryTemplate) else { return }
        AlertPresenter.show(
            title: "无效的搜索 URL",
            message: "请输入一个有效的 http(s) URL，其中包含 %s 来表示搜索词的位置。"
        )
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
    
    private func registerCells() {
        tableView.register(CustomSearchTemplateCell.self, forCellReuseIdentifier: "CustomSearchTemplateCell")
    }
}
