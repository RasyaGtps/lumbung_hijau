package controllers

import (
	"backend-api/config"
	"backend-api/models"
	"net/http"
	"time"

	"github.com/gin-gonic/gin"
	"github.com/google/uuid"
)

var jakartaLoc, _ = time.LoadLocation("Asia/Jakarta")

func GetChatList(c *gin.Context) {
	userID, exists := c.Get("user_id")
	if !exists {
		c.JSON(http.StatusUnauthorized, gin.H{"error": "Unauthorized"})
		return
	}

	currentUserID := userID.(uuid.UUID)

	// Get current user to check role
	var currentUser models.User
	config.DB.Where("id = ?", currentUserID).First(&currentUser)

	type ChatUser struct {
		UserID      uuid.UUID `json:"user_id"`
		UserName    string    `json:"user_name"`
		SchoolName  string    `json:"school_name"`
		LastMessage string    `json:"last_message"`
		LastTime    string    `json:"last_time"`
		UnreadCount int64     `json:"unread_count"`
	}

	var chatUsers []ChatUser

	if currentUser.Role == "admin" {
		// Admin: get all users who have messages with admin
		var userIDs []uuid.UUID
		config.DB.Model(&models.ChatMessage{}).
			Where("sender_id = ? OR receiver_id = ?", currentUserID, currentUserID).
			Select("DISTINCT CASE WHEN sender_id = ? THEN receiver_id ELSE sender_id END", currentUserID).
			Pluck("user_id", &userIDs)

		for _, uid := range userIDs {
			var user models.User
			config.DB.Where("id = ?", uid).First(&user)

			var lastMsg models.ChatMessage
			config.DB.Where("(sender_id = ? AND receiver_id = ?) OR (sender_id = ? AND receiver_id = ?)",
				currentUserID, uid, uid, currentUserID).
				Order("created_at DESC").First(&lastMsg)

			var unreadCount int64
			config.DB.Model(&models.ChatMessage{}).
				Where("sender_id = ? AND receiver_id = ? AND is_read = ?", uid, currentUserID, false).
				Count(&unreadCount)

			chatUsers = append(chatUsers, ChatUser{
				UserID:      uid,
				UserName:    user.Name,
				SchoolName:  user.SchoolName,
				LastMessage: lastMsg.Message,
				LastTime:    lastMsg.CreatedAt.In(jakartaLoc).Format("2006-01-02T15:04:05+07:00"),
				UnreadCount: unreadCount,
			})
		}
	} else {
		// User: check if has any messages with admin
		var adminUsers []models.User
		config.DB.Where("role = ?", "admin").Find(&adminUsers)

		for _, admin := range adminUsers {
			var msgCount int64
			config.DB.Model(&models.ChatMessage{}).
				Where("(sender_id = ? AND receiver_id = ?) OR (sender_id = ? AND receiver_id = ?)",
					currentUserID, admin.ID, admin.ID, currentUserID).
				Count(&msgCount)

			if msgCount > 0 {
				var lastMsg models.ChatMessage
				config.DB.Where("(sender_id = ? AND receiver_id = ?) OR (sender_id = ? AND receiver_id = ?)",
					currentUserID, admin.ID, admin.ID, currentUserID).
					Order("created_at DESC").First(&lastMsg)

				var unreadCount int64
				config.DB.Model(&models.ChatMessage{}).
					Where("sender_id = ? AND receiver_id = ? AND is_read = ?", admin.ID, currentUserID, false).
					Count(&unreadCount)

				chatUsers = append(chatUsers, ChatUser{
					UserID:      admin.ID,
					UserName:    "Admin",
					SchoolName:  "",
					LastMessage: lastMsg.Message,
					LastTime:    lastMsg.CreatedAt.In(jakartaLoc).Format("2006-01-02T15:04:05+07:00"),
					UnreadCount: unreadCount,
				})
			}
		}
	}

	c.JSON(http.StatusOK, gin.H{"chats": chatUsers})
}

// GetMessages returns messages between current user and another user
func GetMessages(c *gin.Context) {
	userID, exists := c.Get("user_id")
	if !exists {
		c.JSON(http.StatusUnauthorized, gin.H{"error": "Unauthorized"})
		return
	}

	otherUserID := c.Param("user_id")
	otherUUID, err := uuid.Parse(otherUserID)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid user_id"})
		return
	}

	currentUserID := userID.(uuid.UUID)

	var messages []models.ChatMessage
	config.DB.Where("(sender_id = ? AND receiver_id = ?) OR (sender_id = ? AND receiver_id = ?)",
		currentUserID, otherUUID, otherUUID, currentUserID).
		Preload("Sender").
		Order("created_at ASC").
		Find(&messages)

	// Mark messages as read
	config.DB.Model(&models.ChatMessage{}).
		Where("sender_id = ? AND receiver_id = ? AND is_read = ?", otherUUID, currentUserID, false).
		Update("is_read", true)

	// Get other user info
	var otherUser models.User
	config.DB.Where("id = ?", otherUUID).First(&otherUser)

	c.JSON(http.StatusOK, gin.H{"messages": messages, "user": otherUser})
}

// GetUnreadCount returns total unread messages for current user
func GetUnreadCount(c *gin.Context) {
	userID, exists := c.Get("user_id")
	if !exists {
		c.JSON(http.StatusUnauthorized, gin.H{"error": "Unauthorized"})
		return
	}

	currentUserID := userID.(uuid.UUID)

	var unreadCount int64
	config.DB.Model(&models.ChatMessage{}).
		Where("receiver_id = ? AND is_read = ?", currentUserID, false).
		Count(&unreadCount)

	c.JSON(http.StatusOK, gin.H{"unread_count": unreadCount})
}

// SendMessage sends a message to another user
func SendMessage(c *gin.Context) {
	userID, exists := c.Get("user_id")
	if !exists {
		c.JSON(http.StatusUnauthorized, gin.H{"error": "Unauthorized"})
		return
	}

	receiverID := c.Param("user_id")
	receiverUUID, err := uuid.Parse(receiverID)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid user_id"})
		return
	}

	var input struct {
		Message string `json:"message" binding:"required"`
	}
	if err := c.ShouldBindJSON(&input); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	message := models.ChatMessage{
		SenderID:   userID.(uuid.UUID),
		ReceiverID: receiverUUID,
		Message:    input.Message,
	}

	if err := config.DB.Create(&message).Error; err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to send message"})
		return
	}

	config.DB.Preload("Sender").First(&message, message.ID)

	c.JSON(http.StatusCreated, gin.H{"message": message})
}
