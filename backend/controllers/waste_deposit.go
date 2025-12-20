package controllers

import (
	"backend-api/config"
	"backend-api/models"
	"fmt"
	"net/http"
	"os"
	"path/filepath"
	"strings"
	"time"

	"github.com/gin-gonic/gin"
	"github.com/google/uuid"
)

type WasteDepositInput struct {
	SchoolName   string `json:"school_name" binding:"required"`
	ContactName  string `json:"contact_name" binding:"required"`
	ContactPhone string `json:"contact_phone" binding:"required"`
	Address      string `json:"address" binding:"required"`
	PickupDate   string `json:"pickup_date" binding:"required"`
	BinCount     int    `json:"bin_count" binding:"required"`
	WasteType    string `json:"waste_type" binding:"required"`
}

// CreateWasteDeposit creates a new waste deposit submission with photo
func CreateWasteDeposit(c *gin.Context) {
	userID, exists := c.Get("user_id")
	if !exists {
		c.JSON(http.StatusUnauthorized, gin.H{"error": "Unauthorized"})
		return
	}

	// Get form fields
	schoolName := c.PostForm("school_name")
	contactName := c.PostForm("contact_name")
	contactPhone := c.PostForm("contact_phone")
	address := c.PostForm("address")
	pickupDateStr := c.PostForm("pickup_date")
	binCountStr := c.PostForm("bin_count")
	wasteType := c.PostForm("waste_type")

	// Validate required fields
	if schoolName == "" || contactName == "" || contactPhone == "" || address == "" || pickupDateStr == "" || binCountStr == "" || wasteType == "" {
		c.JSON(http.StatusBadRequest, gin.H{"error": "All fields are required"})
		return
	}

	// Parse pickup date
	pickupDate, err := time.Parse("02/01/2006", pickupDateStr)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid date format. Use DD/MM/YYYY"})
		return
	}

	// Parse bin count
	var binCount int
	if _, err := fmt.Sscanf(binCountStr, "%d", &binCount); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid bin_count"})
		return
	}

	deposit := models.WasteDeposit{
		UserID:       userID.(uuid.UUID),
		SchoolName:   schoolName,
		ContactName:  contactName,
		ContactPhone: contactPhone,
		Address:      address,
		PickupDate:   pickupDate,
		BinCount:     binCount,
		WasteType:    wasteType,
		Status:       "pending",
	}

	// Handle photo upload
	file, err := c.FormFile("photo")
	if err == nil && file != nil {
		// Create uploads directory if not exists
		uploadDir := "uploads/deposits"
		if err := os.MkdirAll(uploadDir, 0755); err != nil {
			c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to create upload directory"})
			return
		}

		// Generate unique filename
		ext := filepath.Ext(file.Filename)
		filename := uuid.New().String() + "_" + time.Now().Format("20060102150405") + ext
		filePath := filepath.Join(uploadDir, filename)

		// Save file
		if err := c.SaveUploadedFile(file, filePath); err != nil {
			c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to save file"})
			return
		}

		// Use forward slashes for URL compatibility
		deposit.PhotoProof = "/" + strings.ReplaceAll(filePath, "\\", "/")
	}

	if err := config.DB.Create(&deposit).Error; err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to create deposit"})
		return
	}

	// Create notification for the user
	title := "Penyetoran Berhasil"
	message := fmt.Sprintf("Penyetoran %s %d tong berhasil dibuat dan menunggu konfirmasi", deposit.WasteType, deposit.BinCount)
	CreateNotification(deposit.UserID, &deposit.ID, title, message, "deposit_update")

	c.JSON(http.StatusCreated, gin.H{
		"message": "Waste deposit created successfully",
		"deposit": deposit,
	})
}

// GetMyDeposits returns all deposits for the authenticated user
func GetMyDeposits(c *gin.Context) {
	userID, exists := c.Get("user_id")
	if !exists {
		c.JSON(http.StatusUnauthorized, gin.H{"error": "Unauthorized"})
		return
	}

	var deposits []models.WasteDeposit
	if err := config.DB.Where("user_id = ?", userID.(uuid.UUID)).Order("created_at DESC").Find(&deposits).Error; err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to fetch deposits"})
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"deposits": deposits,
	})
}

// GetDepositByID returns a single deposit by ID
func GetDepositByID(c *gin.Context) {
	depositID := c.Param("id")
	userID, exists := c.Get("user_id")
	if !exists {
		c.JSON(http.StatusUnauthorized, gin.H{"error": "Unauthorized"})
		return
	}

	var deposit models.WasteDeposit
	if err := config.DB.Where("id = ? AND user_id = ?", depositID, userID.(uuid.UUID)).First(&deposit).Error; err != nil {
		c.JSON(http.StatusNotFound, gin.H{"error": "Deposit not found"})
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"deposit": deposit,
	})
}

// GetAllDeposits returns all deposits (admin only)
func GetAllDeposits(c *gin.Context) {
	var deposits []models.WasteDeposit
	if err := config.DB.Preload("User").Order("created_at DESC").Find(&deposits).Error; err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to fetch deposits"})
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"deposits": deposits,
	})
}

// UpdateDepositStatus updates the status and/or weight of a deposit (admin only)
func UpdateDepositStatus(c *gin.Context) {
	depositID := c.Param("id")

	// Get admin user ID from context
	adminUserID, exists := c.Get("user_id")
	if !exists {
		c.JSON(http.StatusUnauthorized, gin.H{"error": "Unauthorized"})
		return
	}

	var input struct {
		Status string   `json:"status"`
		Weight *float64 `json:"weight"`
	}
	if err := c.ShouldBindJSON(&input); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	// Validate status if provided
	if input.Status != "" {
		validStatuses := []string{"pending", "proses", "completed", "rejected"}
		isValid := false
		for _, s := range validStatuses {
			if input.Status == s {
				isValid = true
				break
			}
		}
		if !isValid {
			c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid status. Must be: pending, proses, completed, or rejected"})
			return
		}
	}

	var deposit models.WasteDeposit
	if err := config.DB.Where("id = ?", depositID).First(&deposit).Error; err != nil {
		c.JSON(http.StatusNotFound, gin.H{"error": "Deposit not found"})
		return
	}

	oldStatus := deposit.Status
	
	// Update status if provided
	if input.Status != "" && input.Status != oldStatus {
		deposit.Status = input.Status
		
		// Set picker info when status changes to "proses"
		if input.Status == "proses" {
			adminID := adminUserID.(uuid.UUID)
			deposit.PickerID = &adminID
			var adminUser models.User
			if err := config.DB.Where("id = ?", adminID).First(&adminUser).Error; err == nil {
				deposit.PickerName = adminUser.Name
			}
		}
		
		// Create notification for status change
		var title, message string
		switch input.Status {
		case "proses":
			title = "Penyetoran Sedang Diproses"
			message = fmt.Sprintf("Sampah %s %d tong sedang dalam proses penjemputan oleh %s", deposit.WasteType, deposit.BinCount, deposit.PickerName)
		case "completed":
			title = "Penyaluran Berhasil"
			message = fmt.Sprintf("Sampah %s %d tong telah selesai diproses", deposit.WasteType, deposit.BinCount)
		case "rejected":
			title = "Penyetoran Ditolak"
			message = fmt.Sprintf("Sampah %s %d tong tidak dapat diproses", deposit.WasteType, deposit.BinCount)
		}
		
		if title != "" {
			CreateNotification(deposit.UserID, &deposit.ID, title, message, "deposit_update")
		}
	}
	
	// Update weight if provided
	if input.Weight != nil {
		deposit.Weight = input.Weight
		
		// Create notification for weight update
		title := "Berat Sampah Dikonfirmasi"
		message := fmt.Sprintf("Berat sampah Anda telah dikonfirmasi: %.1f Kg", *input.Weight)
		CreateNotification(deposit.UserID, &deposit.ID, title, message, "deposit_update")
	}

	if err := config.DB.Save(&deposit).Error; err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to update deposit"})
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"message": "Deposit updated successfully",
		"deposit": deposit,
	})
}

// UploadDepositPhoto uploads a photo for a deposit
func UploadDepositPhoto(c *gin.Context) {
	depositID := c.Param("id")
	
	userID, exists := c.Get("user_id")
	if !exists {
		c.JSON(http.StatusUnauthorized, gin.H{"error": "Unauthorized"})
		return
	}

	// Get deposit
	var deposit models.WasteDeposit
	if err := config.DB.Where("id = ? AND user_id = ?", depositID, userID.(uuid.UUID)).First(&deposit).Error; err != nil {
		c.JSON(http.StatusNotFound, gin.H{"error": "Deposit not found"})
		return
	}

	// Get uploaded file
	file, err := c.FormFile("photo")
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "No file uploaded"})
		return
	}

	// Create uploads directory if not exists
	uploadDir := "uploads/deposits"
	if err := os.MkdirAll(uploadDir, 0755); err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to create upload directory"})
		return
	}

	// Generate unique filename
	ext := filepath.Ext(file.Filename)
	filename := deposit.ID.String() + "_" + time.Now().Format("20060102150405") + ext
	filePath := filepath.Join(uploadDir, filename)

	// Save file
	if err := c.SaveUploadedFile(file, filePath); err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to save file"})
		return
	}

	// Update deposit with photo path
	deposit.PhotoProof = "/" + filePath
	if err := config.DB.Save(&deposit).Error; err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to update deposit"})
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"message":    "Photo uploaded successfully",
		"photo_path": deposit.PhotoProof,
	})
}
