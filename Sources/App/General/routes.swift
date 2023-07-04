import Fluent
import Vapor

func routes(_ app: Application) throws {
    
//    MARK: - Main HTML Screen
    app.get { req async throws in
        try await req.view.render("index")
    }
    
//    MARK: - Privacy Police Screen
    app.get("privacy", "policy", ":languageCode") { req async throws in
        var code = req.parameters.get("languageCode") ?? .init()
        
        if code != "ru" {
            code = "en"
        }
        
        return try await req.view.render("privacy_policy_\(code)")
    }
    
//    MARK: - Sever Status
    app.get("is", "work") { _ -> Bool in isServerWorkin }
    app.put("set", "work") { req throws -> HTTPStatus in
        guard try req.auth.require(User.self).isAdmin else {
            throw Abort(.badRequest)
        }
        
        isServerWorkin.toggle()
        
        return .ok
    }
    
//    MARK: - Subscription Status
    app.get("is", "subscription", "working") { _ -> Bool in isSubscriptionWorking }
    app.put("set", "subscription", "working") { req throws -> HTTPStatus in
        guard try req.auth.require(User.self).isAdmin else {
            throw Abort(.badRequest)
        }
        
        isSubscriptionWorking.toggle()
        
        return .ok
    }
    
//    MARK: - Register All Routes
    try app.register(collection: UserController())
    try app.register(collection: UserTokenController())
    try app.register(collection: DealController())
    try app.register(collection: OfferController())
    try app.register(collection: AdController())
    try app.register(collection: ChatRoomController())
    try app.register(collection: MessageController())
    try app.register(collection: NotificationController())
    try app.register(collection: ComplaintController())
    try app.register(collection: NotificationScreenController())
    try app.register(collection: CurrencyController())
    try app.register(collection: DealModeController())
    try app.register(collection: PetBreedController())
    try app.register(collection: PetClassController())
    try app.register(collection: PetTypeController())
    try app.register(collection: SearchTitleController())
    try app.register(collection: TitleSubscriptionController())
    try app.register(collection: SubscriptionController())
    try app.register(collection: DeviceTokenController())
}
