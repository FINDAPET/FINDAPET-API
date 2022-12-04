import Fluent
import Vapor

func routes(_ app: Application) throws {
    app.get { req async throws in
        try await req.view.render("index")
    }
    
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
}
