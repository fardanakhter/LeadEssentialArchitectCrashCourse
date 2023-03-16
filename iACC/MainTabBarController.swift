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
        vc.title = "Friends"
        vc.navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .add, target: vc, action: #selector(addFriend))
        
        let isPremium = User.shared?.isPremium == true
        
        let service = FriendsAPIItemServiceAdaptor(api: FriendsAPI.shared,
                                                  cache: isPremium ? friendsCache : NullFriendsCache(),
                                                   select: { [weak vc] friend in vc?.select(friend) }).retry(2)
        
        let cache = FriendsCacheItemServiceAdaptor(cache: friendsCache,
                                                   select: { [weak vc] friend  in vc?.select(friend) })
        
        
        vc.service = isPremium ? service.fallback(cache) : service
        
		return vc
	}
	
	private func makeSentTransfersList() -> ListViewController {
		let vc = ListViewController()
        vc.longDateStyle = true
        vc.navigationItem.title = "Sent"
        vc.navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Send", style: .done, target: vc, action: #selector(sendMoney))
        let service = TransfersAPIItemServiceAdaptor(api: TransfersAPI.shared,
                                                    longDateStyle: true,
                                                    fromSentTransfersScreen: true,
                                                    select: { [weak vc] transfer in vc?.select(transfer) })
        vc.service = service.retry(1)
        
		return vc
	}
	
	private func makeReceivedTransfersList() -> ListViewController {
		let vc = ListViewController()
        vc.longDateStyle = false
        vc.navigationItem.title = "Received"
        vc.navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Request", style: .done, target: vc, action: #selector(requestMoney))
        let service = TransfersAPIItemServiceAdaptor(api: TransfersAPI.shared,
                                                    longDateStyle: false,
                                                    fromSentTransfersScreen: false,
                                                    select: { [weak vc] transfer in vc?.select(transfer) })
        vc.service = service.retry(1)
        
		return vc
	}
	
	private func makeCardsList() -> ListViewController {
		let vc = ListViewController()
        vc.title = "Cards"
        vc.navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .add, target: vc, action: #selector(addCard))
        let service = CardsAPIItemServiceAdaptor(api: CardAPI.shared,
                                                select: { [weak vc] card in vc?.select(card) })
        vc.service = service
        
		return vc
	}
	
}
