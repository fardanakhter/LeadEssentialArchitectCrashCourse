//	
// Copyright © 2021 Essential Developer. All rights reserved.
//

import UIKit

class MainTabBarController: UITabBarController {
	
    var friendsCache: FriendsCache!
    
    convenience init(friendsCache: FriendsCache) {
		self.init(nibName: nil, bundle: nil)
        self.friendsCache = friendsCache
        self.setupViewController()
	}

	private func setupViewController() {
		viewControllers = [
			makeNav(for: makeFriendsList(), title: "Friends", icon: "person.2.fill"),
			makeTransfersList(),
			makeNav(for: makeCardsList(), title: "Cards", icon: "creditcard.fill")
		]
	}
	
	private func makeNav(for vc: UIViewController, title: String, icon: String) -> UIViewController {
		vc.navigationItem.largeTitleDisplayMode = .always
		
		let nav = UINavigationController(rootViewController: vc)
		nav.tabBarItem.image = UIImage(
			systemName: icon,
			withConfiguration: UIImage.SymbolConfiguration(scale: .large)
		)
		nav.tabBarItem.title = title
		nav.navigationBar.prefersLargeTitles = true
		return nav
	}
	
	private func makeTransfersList() -> UIViewController {
		let sent = makeSentTransfersList()
		sent.navigationItem.title = "Sent"
		sent.navigationItem.largeTitleDisplayMode = .always
		
		let received = makeReceivedTransfersList()
		received.navigationItem.title = "Received"
		received.navigationItem.largeTitleDisplayMode = .always
		
		let vc = SegmentNavigationViewController(first: sent, second: received)
		vc.tabBarItem.image = UIImage(
			systemName: "arrow.left.arrow.right",
			withConfiguration: UIImage.SymbolConfiguration(scale: .large)
		)
		vc.title = "Transfers"
		vc.navigationBar.prefersLargeTitles = true
		return vc
	}
	
	private func makeFriendsList() -> ListViewController {
		let vc = ListViewController()
		vc.fromFriendsScreen = true
        vc.service = FriendsAPIItemServiceAdaptor(api: FriendsAPI.shared,
                                                  cache: User.shared?.isPremium == true ? friendsCache : NullFriendsCache(),
                                                  select: { [weak vc] friend in vc?.select(friend) })
		return vc
	}
	
	private func makeSentTransfersList() -> ListViewController {
		let vc = ListViewController()
		vc.fromSentTransfersScreen = true
        vc.service = TransfersAPIItemServiceAdaptor(api: TransfersAPI.shared,
                                                    longDateStyle: true,
                                                    fromSentTransfersScreen: true,
                                                    select: { [weak vc] transfer in vc?.select(transfer) })
		return vc
	}
	
	private func makeReceivedTransfersList() -> ListViewController {
		let vc = ListViewController()
		vc.fromReceivedTransfersScreen = true
        vc.service = TransfersAPIItemServiceAdaptor(api: TransfersAPI.shared,
                                                    longDateStyle: false,
                                                    fromSentTransfersScreen: false,
                                                    select: { [weak vc] transfer in vc?.select(transfer) })
		return vc
	}
	
	private func makeCardsList() -> ListViewController {
		let vc = ListViewController()
		vc.fromCardsScreen = true
        vc.service = CardsAPIItemServiceAdaptor(api: CardAPI.shared,
                                                select: { [weak vc] card in vc?.select(card) })
		return vc
	}
	
}

class NullFriendsCache: FriendsCache {
    override func save(_ newFriends: [Friend]) {
        // do nothing
    }
}
