//
//  TweaksCollectionsListViewController.swift
//  SwiftTweaks
//
//  Created by Bryan Clark on 11/9/15.
//  Copyright © 2015 Khan Academy. All rights reserved.
//

import UIKit

internal protocol TweaksCollectionsListViewControllerDelegate {
	func tweaksCollectionsListViewControllerDidTapDismissButton(_ tweaksCollectionsListViewController: TweaksCollectionsListViewController)
	func tweaksCollectionsListViewController(_ tweaksCollectionsListViewController: TweaksCollectionsListViewController, didSelectTweakCollection: TweakCollection)
	func tweaksCollectionsListViewController(_ tweaksCollectionsListViewController: TweaksCollectionsListViewController, didSelectFolder title: String, collections: [TweakCollection])
	func tweaksCollectionsListViewControllerDidTapShareButton(_ tweaksCollectionsListViewController: TweaksCollectionsListViewController, shareButton: UIBarButtonItem)
}

/// Displays a list of TweakCollections, and folders of them, in a table.
///
/// The root list shows the whole store, with the Reset All and Export buttons; a folder's list shows only that folder's collections.
internal final class TweaksCollectionsListViewController: UIViewController {
	private let tableView: UITableView

	fileprivate let tweakStore: TweakStore
	fileprivate let delegate: TweaksCollectionsListViewControllerDelegate
	fileprivate let entries: [TweakListEntry]
	private let isFolder: Bool


	// MARK: Init

	internal init(tweakStore: TweakStore, delegate: TweaksCollectionsListViewControllerDelegate) {
		self.tweakStore = tweakStore
		self.delegate = delegate
		self.entries = tweakStore.rootListEntries
		self.isFolder = false

		self.tableView = UITableView(frame: CGRect.zero, style: .plain)

		super.init(nibName: nil, bundle: nil)
	}

	internal init(folderTitle: String, collections: [TweakCollection], tweakStore: TweakStore, delegate: TweaksCollectionsListViewControllerDelegate) {
		self.tweakStore = tweakStore
		self.delegate = delegate
		self.entries = collections.map(TweakListEntry.collection)
		self.isFolder = true

		self.tableView = UITableView(frame: CGRect.zero, style: .plain)

		super.init(nibName: nil, bundle: nil)

		self.title = folderTitle
	}

	required init?(coder aDecoder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}


	// MARK: View Lifecycle

	override func viewDidLoad() {
		super.viewDidLoad()

		tableView.frame = view.bounds
		tableView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
		tableView.register(TweakCollectionCell.self, forCellReuseIdentifier: TweaksCollectionsListViewController.TweakCollectionCellIdentifier)
		tableView.delegate = self
		tableView.dataSource = self
		view.addSubview(tableView)

		toolbarItems = [
			UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil),
			UIBarButtonItem(title: "Dismiss", style: .done, target: self, action: #selector(self.dismissButtonTapped))
		]

		// A folder is pushed, so its left bar button is the back button; resetting and exporting stay on the root list.
		guard !isFolder else { return }

		let resetButton = UIBarButtonItem(title: "Reset All", style: .plain, target: self, action: #selector(self.resetStore))
		resetButton.tintColor = AppTheme.Colors.controlDestructive
		navigationItem.rightBarButtonItem = resetButton

		let exportButton = UIBarButtonItem(title: "Export", style: .plain, target: self, action: #selector(self.actionButtonTapped))
		exportButton.tintColor = AppTheme.Colors.controlTinted
		navigationItem.leftBarButtonItem = exportButton
	}

	override func viewWillAppear(_ animated: Bool) {
		super.viewDidAppear(animated)

		if let selectedIndexPath = tableView.indexPathForSelectedRow {
			tableView.deselectRow(at: selectedIndexPath, animated: true)
		}
	}

	// MARK: Events

	@objc private func resetStore(_ sender: UIBarButtonItem) {
		let confirmationAlert = UIAlertController(title: nil, message: "Reset all tweaks to their default values?", preferredStyle: .actionSheet)
		confirmationAlert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
		confirmationAlert.addAction(UIAlertAction(title: "Reset All Tweaks", style: .destructive, handler: { _ in self.tweakStore.reset() }))
		confirmationAlert.popoverPresentationController?.barButtonItem = sender
		present(confirmationAlert, animated: true, completion: nil)
	}

	@objc private func dismissButtonTapped() {
		delegate.tweaksCollectionsListViewControllerDidTapDismissButton(self)
	}

	@objc private func actionButtonTapped(_ sender: UIBarButtonItem) {
		delegate.tweaksCollectionsListViewControllerDidTapShareButton(self, shareButton: sender)
	}

	fileprivate static let TweakCollectionCellIdentifier = "TweakCollectionCellIdentifier"
	private class TweakCollectionCell: UITableViewCell {
		override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
			super.init(style: UITableViewCell.CellStyle.value1, reuseIdentifier: reuseIdentifier)
			accessoryType = .disclosureIndicator

			let touchHighlightView = UIView()
			touchHighlightView.backgroundColor = AppTheme.Colors.tableCellTouchHighlight
			self.selectedBackgroundView = touchHighlightView
		}

		required init?(coder aDecoder: NSCoder) {
		    fatalError("init(coder:) has not been implemented")
		}
	}
}

extension TweaksCollectionsListViewController: UITableViewDataSource {
	func numberOfSections(in tableView: UITableView) -> Int {
		return 1
	}

	func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
		return entries.count
	}

	func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
		let cell = tableView.dequeueReusableCell(withIdentifier: TweaksCollectionsListViewController.TweakCollectionCellIdentifier, for: indexPath)
		let entry = entries[indexPath.row]
		cell.textLabel!.text = entry.title
		cell.detailTextLabel!.text = "\(entry.numberOfTweaks)"
		// Every row of the root list is a folder of sorts, so every one gets the icon; inside a folder, none do.
		cell.imageView?.image = isFolder ? nil : UIImage(systemName: "folder")
		return cell
	}
}

extension TweaksCollectionsListViewController: UITableViewDelegate {
	func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
		switch entries[indexPath.row] {
		case let .collection(collection):
			delegate.tweaksCollectionsListViewController(self, didSelectTweakCollection: collection)
		case let .folder(title, collections):
			delegate.tweaksCollectionsListViewController(self, didSelectFolder: title, collections: collections)
		}
	}
}
