package controllers

import (
	"backend-api/config"
	"backend-api/models"
	"net/http"

	"github.com/gin-gonic/gin"
	"github.com/google/uuid"
)

// GetMyNotifications returns all notifications for the authenticated user
func GetMyNotifications(c *gin.Context) {
	userID, exists := c.Get("user_id")
	if !exists {
		c.JSON(http.StatusUnauthorized, gin.H{"error": "Unauthorized"})
		return
	}

	var notifications []models.Notification
	if err := config.DB.Where("user_id = ?", userID.(uuid.UUID)).Order("created_at DESC").Find(&notifications).Error; err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to fetch notifications"})
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"notifications": notifications,
	})
}

// MarkNotificationAsRead marks a notification as read
func MarkNotificationAsRead(c *gin.Context) {
	notifID := c.Param("id")
	userID, exists := c.Get("user_id")
	if !exists {
		c.JSON(http.StatusUnauthorized, gin.H{"error": "Unauthorized"})
		return
	}

	var notification models.Notification
	if err := config.DB.Where("id = ? AND user_id = ?", notifID, userID.(uuid.UUID)).First(&notification).Error; err != nil {
		c.JSON(http.StatusNotFound, gin.H{"error": "Notification not found"})
		return
	}

	notification.IsRead = true
	if err := config.DB.Save(&notification).Error; err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to update notification"})
		return
	}

	c.JSON(http.StatusOK, gin.H{"message": "Notification marked as read"})
}

// MarkAllNotificationsAsRead marks all notifications as read for a user
func MarkAllNotificationsAsRead(c *gin.Context) {
	userID, exists := c.Get("user_id")
	if !exists {
		c.JSON(http.StatusUnauthorized, gin.H{"error": "Unauthorized"})
		return
	}

	if err := config.DB.Model(&models.Notification{}).Where("user_id = ?", userID.(uuid.UUID)).Update("is_read", true).Error; err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to update notifications"})
		return
	}

	c.JSON(http.StatusOK, gin.H{"message": "All notifications marked as read"})
}

// GetUnreadNotificationCount returns count of unread notifications
func GetUnreadNotificationCount(c *gin.Context) {
	userID, exists := c.Get("user_id")
	if !exists {
		c.JSON(http.StatusUnauthorized, gin.H{"error": "Unauthorized"})
		return
	}

	var count int64
	config.DB.Model(&models.Notification{}).Where("user_id = ? AND is_read = ?", userID.(uuid.UUID), false).Count(&count)

	c.JSON(http.StatusOK, gin.H{"unread_count": count})
}

// Helper function to create notification
func CreateNotification(userID uuid.UUID, depositID *uuid.UUID, title, message, notifType string) error {
	notification := models.Notification{
		UserID:    userID,
		DepositID: depositID,
		Title:     title,
		Message:   message,
		Type:      notifType,
		IsRead:    false,
	}
	return config.DB.Create(&notification).Error
}
