
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

enum SectionIndex: Int, CaseIterable { ///TODO: with items as associated value, all has no items
    ///for incoming requests
    case contactRequests = 0

     ///for self pending requests / conversations
    case conversations = 2

    /// one on one conversations
    case contactsConversations = 1

    ///TODO: one more group convo

    ///TODO:
//    case customFolder(folder: FolderType)

    var uIntValue: UInt {
        return UInt(rawValue)
    }
}
