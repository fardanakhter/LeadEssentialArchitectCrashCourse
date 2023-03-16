//
// Copyright © 2021 Essential Developer. All rights reserved.
//

import UIKit

protocol ItemService {
    func loadItems(completion: @escaping (Result<[ItemViewModel], Error>) -> Void)
}

class ListViewController: UITableViewController {
    
    var items = [ItemViewModel]()
    var service: ItemService?
	var retryCount = 0
	var maxRetryCount = 0
	var shouldRetry = false
	
	var longDateStyle = false
	
	var fromReceivedTransfersScreen = false
	var fromSentTransfersScreen = false
	var fromCardsScreen = false
	var fromFriendsScreen = false
	
	override func viewDidLoad() {
		super.viewDidLoad()
		
		refreshControl = UIRefreshControl()
		refreshControl?.addTarget(self, action: #selector(refresh), for: .valueChanged)
		
		if fromFriendsScreen {
			shouldRetry = true
			maxRetryCount = 2
			
			title = "Friends"
			
			navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(addFriend))
			
		} else if fromCardsScreen {
			shouldRetry = false
			
			title = "Cards"
			
			navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(addCard))
			
		} else if fromSentTransfersScreen {
			shouldRetry = true
			maxRetryCount = 1
			longDateStyle = true

			navigationItem.title = "Sent"
			navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Send", style: .done, target: self, action: #selector(sendMoney))

		} else if fromReceivedTransfersScreen {
			shouldRetry = true
			maxRetryCount = 1
			longDateStyle = false
			
			navigationItem.title = "Received"
			navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Request", style: .done, target: self, action: #selector(requestMoney))
		}
	}
	
	override func viewWillAppear(_ animated: Bool) {
		super.viewWillAppear(animated)
		
		if tableView.numberOfRows(inSection: 0) == 0 {
			refresh()
		}
	}
	
	@objc private func refresh() {
		refreshControl?.beginRefreshing()
		if fromFriendsScreen {
            service?.loadItems { [weak self] result in
                self?.handleAPIResult(result)
			}
            
		} else if fromCardsScreen {
			
            CardAPI.shared.loadCards { [weak self] result in
				DispatchQueue.mainAsyncIfNeeded {
                    self?.handleAPIResult(result.map({ cards in
                        cards.map { card in
                            ItemViewModel(card, selection: { [weak self] in
                                self?.select(card)
                            })
                        }
                    }))
				}
			}
            
		} else if fromSentTransfersScreen || fromReceivedTransfersScreen {
			
            TransfersAPI.shared.loadTransfers { [weak self, longDateStyle, fromSentTransfersScreen] result in
				DispatchQueue.mainAsyncIfNeeded {
                    self?.handleAPIResult(result
                        .map({ transfers in
                            transfers
                                .filter { transfer in
                                    fromSentTransfersScreen ? transfer.isSender : !transfer.isSender
                                }
                                .map { transfer in
                                    ItemViewModel(transfer, longDateStyle: longDateStyle, selection: { [weak self] in
                                        self?.select(transfer)
                                    })
                                }
                        }))
				}
			}
		} else {
			fatalError("unknown context")
		}
	}
	
	private func handleAPIResult(_ result: Result<[ItemViewModel], Error>) {
		switch result {
		case let .success(items):

			self.retryCount = 0
			self.items = items
			self.refreshControl?.endRefreshing()
			self.tableView.reloadData()
			
		case let .failure(error):
			if shouldRetry && retryCount < maxRetryCount {
				retryCount += 1
				
				refresh()
				return
			}
			
			retryCount = 0
			
			if fromFriendsScreen && User.shared?.isPremium == true {
				(UIApplication.shared.connectedScenes.first?.delegate as! SceneDelegate).cache.loadFriends { [weak self] result in
					DispatchQueue.mainAsyncIfNeeded {
						switch result {
						case let .success(items):
                            
                            self?.items = items.map({ friend in
                                ItemViewModel(friend, selection: { [weak self] in
                                    self?.select(friend)
                                })
                            })
                            
							self?.tableView.reloadData()
							
						case let .failure(error):
                            self?.showErrorAlert(error)
						}
						self?.refreshControl?.endRefreshing()
					}
				}
			} else {
                self.showErrorAlert(error)
				self.refreshControl?.endRefreshing()
			}
		}
	}
    
	override func numberOfSections(in tableView: UITableView) -> Int {
		1
	}
	
	override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
		items.count
	}
	
	override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
		let item = items[indexPath.row]
		let cell = tableView.dequeueReusableCell(withIdentifier: "ItemCell") ?? UITableViewCell(style: .subtitle, reuseIdentifier: "ItemCell")
		cell.configure(item, longDateStyle: longDateStyle)
		return cell
	}
	
	override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
		let item = items[indexPath.row]
        item.selection()
	}
}

extension UIViewController {
    func showErrorAlert(_ error: Error) {
        let alert = UIAlertController(title: "Error", message: error.localizedDescription, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Ok", style: .default))
        showDetailViewController(alert, sender: presenterVC)
    }
}

// MARK: - UIViewController + Friend
extension UIViewController {
    func select(_ friend: Friend) {
        let vc = FriendDetailsViewController()
        vc.friend = friend
        show(vc, sender: self)
    }
    
    @objc func addFriend() {
        show(AddFriendViewController(), sender: self)
    }
}

// MARK: - UIViewController + Card
extension UIViewController {
    func select(_ card: Card) {
        let vc = CardDetailsViewController()
        vc.card = card
        show(vc, sender: self)
    }
    
    @objc func addCard() {
        show(AddCardViewController(), sender: self)
    }
}
 
// MARK: - UIViewController + Transfer
extension UIViewController {
    func select(_ transfer: Transfer) {
        let vc = TransferDetailsViewController()
        vc.transfer = transfer
        show(vc, sender: self)
    }
    
    @objc func sendMoney() {
        show(SendMoneyViewController(), sender: self)
    }
    
    @objc func requestMoney() {
        show(RequestMoneyViewController(), sender: self)
    }
}

struct ItemViewModel {
    let titleText: String
    let detailText: String
    let selection: () -> Void
}

// MARK: - ItemViewModel + Friend
extension ItemViewModel {
    init(_ friend: Friend, selection: @escaping () -> Void) {
        self.titleText = friend.name
        self.detailText = friend.phone
        self.selection = selection
    }
}

// MARK: - ItemViewModel + Card
extension ItemViewModel {
    init(_ card: Card, selection: @escaping () -> Void) {
        self.titleText = card.number
        self.detailText = card.holder
        self.selection = selection
    }
}

// MARK: - ItemViewModel + Transfer
extension ItemViewModel {
    init(_ transfer: Transfer, longDateStyle: Bool, selection: @escaping () -> Void) {
        let numberFormatter = Formatters.number
        numberFormatter.numberStyle = .currency
        numberFormatter.currencyCode = transfer.currencyCode
        
        let amount = numberFormatter.string(from: transfer.amount as NSNumber)!
        self.titleText = "\(amount) • \(transfer.description)"
        
        let dateFormatter = Formatters.date
        if longDateStyle {
            dateFormatter.dateStyle = .long
            dateFormatter.timeStyle = .short
            self.detailText = "Sent to: \(transfer.recipient) on \(dateFormatter.string(from: transfer.date))"
        } else {
            dateFormatter.dateStyle = .short
            dateFormatter.timeStyle = .short
            self.detailText = "Received from: \(transfer.sender) on \(dateFormatter.string(from: transfer.date))"
        }
        
        self.selection = selection
    }
}

extension UITableViewCell {
	func configure(_ vm: ItemViewModel, longDateStyle: Bool) {
        textLabel?.text = vm.titleText
        detailTextLabel?.text = vm.detailText
	}
}
