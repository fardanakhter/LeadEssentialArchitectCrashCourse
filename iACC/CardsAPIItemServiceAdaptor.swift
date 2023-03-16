//	
// Copyright © 2023 Essential Developer. All rights reserved.
//

import Foundation

struct CardsAPIItemServiceAdaptor: ItemService {
    
    let api: CardAPI
    let select: (Card) -> Void
    
    func loadItems(completion: @escaping (Result<[ItemViewModel], Error>) -> Void) {
        
        api.loadCards { result in
            DispatchQueue.mainAsyncIfNeeded {
                completion(result.map({ cards in
                    cards.map { card in
                        ItemViewModel(card, selection: {
                            self.select(card)
                        })
                    }
                }))
            }
        }
    }
}
