# Mediater.Swift

This a Swift implementation of the Mediater pattern inspired by https://github.com/jbogard/MediatR

Example usage with SwiftUI


```swift
// SwiftMediaterExample.swift
@main
struct SwiftMediaterExample: App {
	var body: some Scene {
		...
	}
	init() {
		registerHandlers()
	}
	func registerHandlers() {
		Mediater.shared.registerHandler(GetAllPlayersQuery())
	}
}
```
Here is how we define a query

```swift
// GetAllPlayersQuery.swift
import MediaterSwift

class GetAllPlayersQuery: RequestProtocol {
	typealias TResponse = Array<Player>
}
```
Here is how we define the handler which in turn executes the query and returns the result
```swift
// GetAllPlayersQueryHandler.swift
import MediaterSwift
import CoreData

class GetAllPlayersQueryHandler: RequestHandlerProtocol {
	let coreDataContext: CoreDataContext.shared
	
	func handle<R>(request: R, completion: @escaping (R.TResponse) throws -> Void) throws where R : RequestProtocol {
		var result: Array<Player> = []
		
		let fetchRequest = NSFetchRequest<NSManagedObject>(entityName: "Player")
		let fetchRequestResult = try coreDataContext.container.viewContext.fetch(fetchRequest)
		
		for fetchResult in fetchRequestResults {
			let player = Player(
				fetchResult.value(forKey: "id") as! UUID,
				fetchResult.value(forKey: "name") as! String,
				fetchResult.value(forKey: "isPlaying") as! Bool
			)
			result.append(player)
		}
		try completion(result as! R.TResponse)
	}	
	
	func canHandle<R>(request: R) -> Bool where R: RequestProtocol  {
		request is GetAllPlayersQuery
	}
}
```

Now simply get the result from the query like this from anywhere in your code

```swift
var players = Mediater.shared.send(GetAllPlayersQuery())
```
