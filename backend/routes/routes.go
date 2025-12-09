package routes

import (
	"backend-api/controllers"
	"backend-api/middlewares"

	"github.com/gin-gonic/gin"
)

func SetupRoutes(r *gin.Engine) {
	r.POST("/register", controllers.Register)
	r.POST("/login", controllers.Login)

	// Serve uploaded files
	r.Static("/uploads", "./uploads")

	protected := r.Group("/")
	protected.Use(middlewares.AuthMiddleware())
	{
		protected.GET("/me", controllers.GetMe)
		protected.PUT("/profile", controllers.UpdateProfile)
		
		// Waste Deposit routes
		protected.POST("/deposits", controllers.CreateWasteDeposit)
		protected.GET("/deposits", controllers.GetMyDeposits)
		protected.GET("/deposits/:id", controllers.GetDepositByID)
		protected.POST("/deposits/:id/photo", controllers.UploadDepositPhoto)
		
		// Notification routes
		protected.GET("/notifications", controllers.GetMyNotifications)
		protected.GET("/notifications/unread-count", controllers.GetUnreadNotificationCount)
		protected.PUT("/notifications/:id/read", controllers.MarkNotificationAsRead)
		protected.PUT("/notifications/read-all", controllers.MarkAllNotificationsAsRead)
		
		// Admin routes
		protected.GET("/admin/deposits", controllers.GetAllDeposits)
		protected.PUT("/admin/deposits/:id/status", controllers.UpdateDepositStatus)
		
		// Chat routes
		protected.GET("/chat/list", controllers.GetChatList)
		protected.GET("/chat/unread-count", controllers.GetUnreadCount)
		protected.GET("/chat/:user_id/messages", controllers.GetMessages)
		protected.POST("/chat/:user_id/messages", controllers.SendMessage)
	}
}
