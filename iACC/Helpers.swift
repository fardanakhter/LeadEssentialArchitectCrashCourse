//	
// Copyright © 2021 Essential Developer. All rights reserved.
//

import UIKit

enum Formatters {
	static var date = DateFormatter()
	static var number = NumberFormatter()
}

extension UIViewController {
	var presenterVC: UIViewController {
		parent?.presenterVC ?? parent ?? self
	}
}

extension DispatchQueue {
	static func mainAsyncIfNeeded(execute work: @escaping () -> Void) {
		if Thread.isMainThread {
			work()
		} else {
			main.async(execute: work)
		}
	}
}

extension ItemService {
    func fallback(_ fallback: ItemService) -> ItemService {
        ItemServiceWithFallback(primary: self, fallback: fallback)
    }
    
    func retry(_ times: UInt) -> ItemService {
        var service: ItemService = self
        for _ in 0..<times {
            service = service.fallback(self)
        }
        return service
    }
}


