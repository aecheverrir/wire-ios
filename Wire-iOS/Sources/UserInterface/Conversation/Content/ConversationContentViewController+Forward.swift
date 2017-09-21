//
// Wire
// Copyright (C) 2016 Wire Swiss GmbH
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

import Foundation
import WireSyncEngine
import Cartography


extension ZMConversation: ShareDestination {
    
    public var avatarView: UIView? {
        let avatarView = ConversationAvatarView()
        avatarView.conversation = self
        return avatarView
    }
    
}

extension Array where Element == ZMConversation {

    // Should be called inside ZMUserSession.shared().performChanges block
    func forEachNonEphemeral(_ block: (ZMConversation) -> Void) {
        forEach {
            let timeout = $0.destructionTimeout
            $0.updateMessageDestructionTimeout(timeout: .none)
            block($0)
            $0.updateMessageDestructionTimeout(timeout: timeout)
        }
    }
}

func forward(_ message: ZMMessage, to: [AnyObject]) {

    let conversations = to as! [ZMConversation]
    
    if message.isText {
        let fetchLinkPreview = !Settings.shared().disableLinkPreviews
        ZMUserSession.shared()?.performChanges {
            conversations.forEachNonEphemeral { _ = $0.appendMessage(withText: message.textMessageData!.messageText, fetchLinkPreview: fetchLinkPreview) }
        }
    }
    else if message.isImage {
        ZMUserSession.shared()?.performChanges {
            conversations.forEachNonEphemeral { _ = $0.appendMessage(withImageData: message.imageMessageData!.imageData) }
        }
    }
    else if message.isVideo || message.isAudio || message.isFile {
        let url  = message.fileMessageData!.fileURL!
        FileMetaDataGenerator.metadataForFileAtURL(url, UTI: url.UTI(), name: url.lastPathComponent) { fileMetadata in
            ZMUserSession.shared()?.performChanges {
                conversations.forEachNonEphemeral { _ = $0.appendMessage(with: fileMetadata) }
            }
        }
    }
    else if message.isLocation {
        let locationData = LocationData.locationData(withLatitude: message.locationMessageData!.latitude, longitude: message.locationMessageData!.longitude, name: message.locationMessageData!.name, zoomLevel: message.locationMessageData!.zoomLevel)
        ZMUserSession.shared()?.performChanges {
            conversations.forEachNonEphemeral { _ = $0.appendMessage(with: locationData) }
        }
    }
    else {
        fatal("Cannot forward \(message)")
    }
}

extension ZMMessage: Shareable {
    
    public func share<ZMConversation>(to: [ZMConversation]) {
        forward(self, to: to as [AnyObject])
    }
    
    public typealias I = ZMConversation
    
    public func previewView() -> UIView? {
        let cell: ConversationCell
        
        if isText {
            let textMessageCell = TextMessageCell(style: .default, reuseIdentifier: "")
            textMessageCell.smallLinkAttachments = true
            textMessageCell.contentLayoutMargins = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
            textMessageCell.linkAttachmentContainer.layoutMargins = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)            
            textMessageCell.messageTextView.backgroundColor = ColorScheme.default().color(withName: ColorSchemeColorBackground)
            textMessageCell.messageTextView.layer.cornerRadius = 4
            textMessageCell.messageTextView.layer.masksToBounds = true
            textMessageCell.messageTextView.textContainerInset = UIEdgeInsets(top: 8, left: 8, bottom: 10, right: 8)
            textMessageCell.messageTextView.textContainer.lineBreakMode = .byTruncatingTail
            textMessageCell.messageTextView.textContainer.maximumNumberOfLines = 2
            cell = textMessageCell
        }
        else if isImage {
            let imageMessageCell = ImageMessageCell(style: .default, reuseIdentifier: "")
            imageMessageCell.contentLayoutMargins = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
            imageMessageCell.autoStretchVertically = false
            imageMessageCell.defaultLayoutMargins = .zero
            cell = imageMessageCell
        }
        else if isVideo {
            cell = VideoMessageCell(style: .default, reuseIdentifier: "")
            cell.contentLayoutMargins = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
        }
        else if isAudio {
            cell = AudioMessageCell(style: .default, reuseIdentifier: "")
            cell.contentLayoutMargins = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
        }
        else if isLocation {
            let locationCell = LocationMessageCell(style: .default, reuseIdentifier: "")
            locationCell.contentLayoutMargins = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
            locationCell.containerHeightConstraint.constant = 160
            cell = locationCell
        }
        else if isFile {
            cell = FileTransferCell(style: .default, reuseIdentifier: "")
            cell.contentLayoutMargins = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
        }
        else {
            fatal("Cannot create preview for \(self)")
        }
        
        let layoutProperties = ConversationCellLayoutProperties()
        layoutProperties.showSender       = false
        layoutProperties.showUnreadMarker = false
        layoutProperties.showBurstTimestamp = false
        layoutProperties.topPadding       = 0
        layoutProperties.alwaysShowDeliveryState = false
        
        cell.configure(for: self, layoutProperties: layoutProperties)
        
        constrain(cell, cell.contentView) { cell, contentView in
            contentView.edges == cell.edges
        }

        cell.toolboxView.removeFromSuperview()
        cell.likeButton.isHidden = true
        cell.isUserInteractionEnabled = false
        cell.setSelected(false, animated: false)
        
        return cell
    }
    
    public func getHeight(for previewView: UIView?) -> CGFloat {
        
        guard let previewView = previewView as? ConversationCell else { return 0.0 }
        
        let standardHeight : CGFloat = 200.0
        let screenHeightCompact = (UIScreen.main.bounds.height <= 568)
        var height : CGFloat = 0.0
        
        if let previewView = previewView as? ImageMessageCell {
            if let imageHeight = previewView.fullImageView.image?.size.height, imageHeight < standardHeight {
                height = imageHeight
            } else {
                height = standardHeight
            }
        } else if let previewView = previewView as? VideoMessageCell {
            height = previewView.videoViewHeight
        } else {
            height = previewView.messageContentView.systemLayoutSizeFitting(UILayoutFittingCompressedSize).height
        }
        
        return min((screenHeightCompact ? 160 : standardHeight), height)
    }
    
}

extension ZMConversationList {
    func shareableConversations(excluding: ZMConversation? = nil) -> [ZMConversation] {
        return self.map { $0 as! ZMConversation }.filter { (conversation: ZMConversation) -> (Bool) in
            return (conversation.conversationType == .oneOnOne || conversation.conversationType == .group) &&
                conversation.isSelfAnActiveMember &&
                conversation != excluding
        }
    }
}

extension ConversationContentViewController: UIAdaptivePresentationControllerDelegate {
    @objc public func showForwardFor(message: ZMConversationMessage, fromCell: ConversationCell?) {
        if let window = self.view.window {
            window.endEditing(true)
        }
        
        let conversations = ZMConversationList.conversationsIncludingArchived(inUserSession: ZMUserSession.shared()!).shareableConversations(excluding: message.conversation!)

        let shareViewController = ShareViewController<ZMConversation, ZMMessage>(
            shareable: message as! ZMMessage,
            destinations: conversations,
            showPreview: traitCollection.horizontalSizeClass != .regular
        )

        let keyboardAvoiding = KeyboardAvoidingViewController(viewController: shareViewController)
        
        keyboardAvoiding.preferredContentSize = CGSize(width: 320, height: 568)
        keyboardAvoiding.modalPresentationStyle = .popover
        
        if let popoverPresentationController = keyboardAvoiding.popoverPresentationController {
            if let cell = fromCell {
                popoverPresentationController.sourceRect = cell.selectionRect
                popoverPresentationController.sourceView = cell.selectionView
            }
            popoverPresentationController.backgroundColor = UIColor(white: 0, alpha: 0.5)
            popoverPresentationController.permittedArrowDirections = [.up, .down]
        }
        
        keyboardAvoiding.presentationController?.delegate = self
        
        shareViewController.onDismiss = { (shareController: ShareViewController<ZMConversation, ZMMessage>, _) -> () in
            shareController.presentingViewController?.dismiss(animated: true) {
                UIApplication.shared.wr_updateStatusBarForCurrentControllerAnimated(true)
            }
        }
        UIApplication.shared.keyWindow?.rootViewController?.present(keyboardAvoiding, animated: true) {
            UIApplication.shared.wr_updateStatusBarForCurrentControllerAnimated(true)
        }
    }
    
    public func adaptivePresentationStyle(for controller: UIPresentationController, traitCollection: UITraitCollection) -> UIModalPresentationStyle {
        return traitCollection.horizontalSizeClass == .regular ? .popover : .overFullScreen
    }
}

extension ConversationContentViewController {
    func scroll(to messageToShow: ZMConversationMessage, completion: ((ConversationCell)->())? = .none) {
        guard messageToShow.conversation == self.conversation else {
            fatal("Message from the wrong conversation")
        }
        
        let indexInConversation: Int = self.conversation.messages.index(of: messageToShow)
        if !self.messageWindow.messages.contains(messageToShow) {
        
            let oldestMessageIndexInMessageWindow = self.conversation.messages.index(of: self.messageWindow.messages.firstObject!)
            let newestMessageIndexInMessageWindow = self.conversation.messages.index(of: self.messageWindow.messages.lastObject!)

            if oldestMessageIndexInMessageWindow > indexInConversation {
                self.messageWindow.moveUp(byMessages: UInt(oldestMessageIndexInMessageWindow - indexInConversation))
            }
            else {
                self.messageWindow.moveDown(byMessages: UInt(indexInConversation - newestMessageIndexInMessageWindow))
            }
        }

        let indexToShow = self.messageWindow.messages.index(of: messageToShow)

        if indexToShow == NSNotFound {
            self.expectedMessageToShow = messageToShow
            self.onMessageShown = completion
        }
        else {
            self.scroll(toIndex: indexToShow, completion: completion)
        }
    }
    
    func scroll(toIndex indexToShow: Int, completion: ((ConversationCell)->())? = .none) {
        let cellIndexPath = IndexPath(row: indexToShow, section: 0)
        self.tableView.scrollToRow(at: cellIndexPath, at: .middle, animated: false)
        
        delay(0.1) {
            completion?(self.tableView.cellForRow(at: cellIndexPath) as! ConversationCell)
        }
    }
}
