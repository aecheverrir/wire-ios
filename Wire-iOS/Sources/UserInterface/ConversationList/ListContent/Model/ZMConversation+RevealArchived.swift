
// Wire
// Copyright (C) 2019 Wire Swiss GmbH
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

extension ZMConversation {

    @discardableResult
    func revealClearedOrArchived(userSession: (ZMUserSessionInterface & ZMManagedObjectContextProvider)? = ZMUserSession.shared(),
                                 completionHandler: Completion?) -> Bool {
        var containedInOtherLists = false

        guard let userSession = userSession else { return containedInOtherLists }

        if userSession.archivedConversations.contains(self) {
            // Check if it's archived, this would mean that the archive is closed but we want to unarchive
            // and select the item
            containedInOtherLists = true
            userSession.enqueueChanges({
                self.isArchived = false
            }, completionHandler: completionHandler)
        } else if userSession.clearedConversations.contains(self) {
            containedInOtherLists = true
            userSession.enqueueChanges({
                self.revealClearedConversation()
            }, completionHandler: completionHandler)
        } else {
            completionHandler?()
        }

        return containedInOtherLists
    }
}

extension ZMManagedObjectContextProvider {
    
    ///TODO: mv to DM for new interface
    var archivedConversations: NSArray {
        return ZMConversationList.archivedConversations(inUserSession: self)
    }

    var clearedConversations: NSArray {
        return ZMConversationList.clearedConversations(inUserSession: self)
    }
}
