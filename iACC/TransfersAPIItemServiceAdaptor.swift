//	
// Copyright © 2023 Essential Developer. All rights reserved.
//

import Foundation

struct TransfersAPIItemServiceAdaptor: ItemService {
    
    let api: TransfersAPI
    let longDateStyle: Bool
    let fromSentTransfersScreen: Bool
    let select: (Transfer) -> Void
    
    func loadItems(completion: @escaping (Result<[ItemViewModel], Error>) -> Void) {
        
        api.loadTransfers { [longDateStyle, fromSentTransfersScreen] result in
            
            DispatchQueue.mainAsyncIfNeeded {
            
                completion(result
                    .map({ transfers in
                        transfers
                            .filter { transfer in
                                fromSentTransfersScreen ? transfer.isSender : !transfer.isSender
                            }
                            .map { transfer in
                                ItemViewModel(transfer, longDateStyle: longDateStyle, selection: {
                                    self.select(transfer)
                                })
                            }
                    }))
            }
        }
    }
}
