//
// Wire
// Copyright (C) 2018 Wire Swiss GmbH
//
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with this program. If not, see http://www.gnu.org/licenses/.
//

import UIKit
import WireUtilities

/**
 * A generic view that displays conversation contents.
 */

protocol ConversationMessageCell {
    /// The object that contains the configuration of the view.
    associatedtype Configuration

    /// Whether the cell is selected.
    var isSelected: Bool { get set }

    /// The view to highlight when the cell is selected.
    var selectionView: UIView? { get }

    /// The frame to highlight when the cell is selected.
    var selectionRect: CGRect { get }
    
    /// Top inset for ephemeral timer relative to the cell content
    var ephemeralTimerTopInset: CGFloat { get }

    /**
     * Configures the cell with the specified configuration object.
     * - parameter object: The view model for the cell.
     * - parameter animated: True if the view should animate the changes
     */

    func configure(with object: Configuration, animated: Bool)
    
    /// Called before the cell will be displayed on the screen.
    func willDisplay()
    
    /// Called after the cell as been moved off screen.
    func didEndDisplaying()
}

extension ConversationMessageCell {

    var selectionView: UIView? {
        return nil
    }

    var selectionRect: CGRect {
        return selectionView?.bounds ?? .zero
    }
    
    var ephemeralTimerTopInset: CGFloat {
        return 8
    }
    
    func willDisplay() {
        // to be overriden
    }
    
    func didEndDisplaying() {
        // to be overriden
    }

}

/**
 * An object that prepares the contents of a conversation cell before
 * it is displayed.
 *
 * The role of this object is to provide a `configuration` view model for
 * the view type it declares as the contents of the cell.
 */

protocol ConversationMessageCellDescription: class {
    /// The view that will be displayed for the cell.
    associatedtype View: ConversationMessageCell & UIView
    
    /// The top margin is used to configure the spacing between cells. This property will
    /// get updated by the ConversationMessageSectionController if necessary so any
    /// default value is just a recommendation.
    var topMargin: Float { get set }
    
    /// Whether the view occupies the entire width of the cell.
    var isFullWidth: Bool { get }

    /// Whether the cell supports actions.
    var supportsActions: Bool { get }
    
    /// Whether the cell should display an ephemeral timer in the margin given it's an ephemeral message
    var showEphemeralTimer: Bool { get set }

    /// Whether the cell contains content that can be highlighted.
    var containsHighlightableContent: Bool { get }

    /// The message that is displayed.
    var message: ZMConversationMessage? { get set }

    /// The delegate for the cell.
    var delegate: ConversationCellDelegate? { get set }

    /// The action controller that handles the menu item.
    var actionController: ConversationCellActionController? { get set }

    /// The configuration object that will be used to populate the cell.
    var configuration: View.Configuration { get }

    func register(in tableView: UITableView)
    func makeCell(for tableView: UITableView, at indexPath: IndexPath) -> UITableViewCell
    func willDisplayCell()
    func didEndDisplayingCell()
}

// MARK: - Table View Dequeuing

extension ConversationMessageCellDescription {
    
    func willDisplayCell() {
        _ = message?.startSelfDestructionIfNeeded()
    }
    
    func didEndDisplayingCell() {
        
    }

    func register(in tableView: UITableView) {
        tableView.register(cell: type(of: self))
    }

    func makeCell(for tableView: UITableView, at indexPath: IndexPath) -> UITableViewCell {
        return tableView.dequeueConversationCell(with: self, for: indexPath)
    }
    
    func configureCell(_ cell: UITableViewCell, animated: Bool = false) {
        guard let adapterCell = cell as? ConversationMessageCellTableViewAdapter<Self> else { return }
        
        adapterCell.cellView.configure(with: self.configuration, animated: animated)
    }
    
}

/**
 * A type erased box containing a conversation message cell description.
 */

@objc class AnyConversationMessageCellDescription: NSObject {
    private let cellGenerator: (UITableView, IndexPath) -> UITableViewCell
    private let registrationBlock: (UITableView) -> Void
    private let configureBlock: (UITableViewCell, Bool) -> Void
    private let baseTypeGetter: () -> AnyClass

    private let _delegate: AnyMutableProperty<ConversationCellDelegate?>
    private let _message: AnyMutableProperty<ZMConversationMessage?>
    private let _actionController: AnyMutableProperty<ConversationCellActionController?>
    private let _topMargin: AnyMutableProperty<Float>
    private let _containsHighlightableContent: AnyConstantProperty<Bool>
    private let _showEphemeralTimer: AnyMutableProperty<Bool>

    init<T: ConversationMessageCellDescription>(_ description: T) {
        registrationBlock = { tableView in
            description.register(in: tableView)
        }
        
        configureBlock = { cell, animated in
            description.configureCell(cell, animated: animated)
        }

        cellGenerator = { tableView, indexPath in
            return description.makeCell(for: tableView, at: indexPath)
        }

        baseTypeGetter = {
            return T.self
        }
        
        _delegate = AnyMutableProperty(description, keyPath: \.delegate)
        _message = AnyMutableProperty(description, keyPath: \.message)
        _actionController = AnyMutableProperty(description, keyPath: \.actionController)
        _topMargin = AnyMutableProperty(description, keyPath: \.topMargin)
        _containsHighlightableContent = AnyConstantProperty(description, keyPath: \.containsHighlightableContent)
        _showEphemeralTimer = AnyMutableProperty(description, keyPath: \.showEphemeralTimer)
    }

    @objc var baseType: AnyClass {
        return baseTypeGetter()
    }

    @objc var delegate: ConversationCellDelegate? {
        get { return _delegate.getter() }
        set { _delegate.setter(newValue) }
    }

    @objc var message: ZMConversationMessage? {
        get { return _message.getter() }
        set { _message.setter(newValue) }
    }

    @objc var actionController: ConversationCellActionController? {
        get { return _actionController.getter() }
        set { _actionController.setter(newValue) }
    }
    
    @objc var topMargin: Float {
        get { return _topMargin.getter() }
        set { _topMargin.setter(newValue) }
    }

    @objc var containsHighlightableContent: Bool {
        return _containsHighlightableContent.getter()
    }
    
    @objc var showEphemeralTimer: Bool {
        get { return _showEphemeralTimer.getter() }
        set { _showEphemeralTimer.setter(newValue) }
    }
        
    func configure(cell: UITableViewCell, animated: Bool = false) {
        configureBlock(cell, animated)
    }

    @objc(registerInTableView:)
    func register(in tableView: UITableView) {
        registrationBlock(tableView)
    }

    func makeCell(for tableView: UITableView, at indexPath: IndexPath) -> UITableViewCell {
        return cellGenerator(tableView, indexPath)
    }

}
