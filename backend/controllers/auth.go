package controllers

import (
	"backend-api/config"
	"backend-api/models"
	"backend-api/utils"
	"fmt"
	"net/http"
	"os"
	"path/filepath"

	"github.com/gin-gonic/gin"
	"github.com/google/uuid"
)

type RegisterInput struct {
	Name       string `json:"name" binding:"required"`
	Email      string `json:"email" binding:"required,email"`
	Password   string `json:"password" binding:"required,min=6"`
	SchoolName string `json:"school_name"`
}

type LoginInput struct {
	Email    string `json:"email" binding:"required,email"`
	Password string `json:"password" binding:"required"`
}

func Register(c *gin.Context) {
	var input RegisterInput
	if err := c.ShouldBindJSON(&input); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	var existingUser models.User
	if err := config.DB.Where("email = ?", input.Email).First(&existingUser).Error; err == nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Email already exists"})
		return
	}

	hashedPassword, err := utils.HashPassword(input.Password)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to hash password"})
		return
	}

	user := models.User{
		Name:       input.Name,
		Email:      input.Email,
		Password:   hashedPassword,
		SchoolName: input.SchoolName,
	}

	if err := config.DB.Create(&user).Error; err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to create user"})
		return
	}

	// Generate token and log user in directly
	token, err := utils.GenerateToken(user.ID, user.Email)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to generate token"})
		return
	}

	c.JSON(http.StatusCreated, gin.H{
		"message": "registration successful",
		"token":   token,
	})
}

func Login(c *gin.Context) {
	var input LoginInput
	if err := c.ShouldBindJSON(&input); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	var user models.User
	if err := config.DB.Where("email = ?", input.Email).First(&user).Error; err != nil {
		c.JSON(http.StatusUnauthorized, gin.H{"error": "Invalid email or password"})
		return
	}

	// Check if user registered via Google (no password)
	if user.Password == "" {
		c.JSON(http.StatusBadRequest, gin.H{"error": "This account was created with Google. Please use 'Sign in with Google' button"})
		return
	}

	if !utils.CheckPassword(input.Password, user.Password) {
		c.JSON(http.StatusUnauthorized, gin.H{"error": "Invalid email or password"})
		return
	}

	token, err := utils.GenerateToken(user.ID, user.Email)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to generate token"})
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"message": "login success",
		"token":   token,
	})
}

func GetMe(c *gin.Context) {
	userID, exists := c.Get("user_id")
	if !exists {
		c.JSON(http.StatusUnauthorized, gin.H{"error": "Unauthorized"})
		return
	}

	var user models.User
	if err := config.DB.Where("id = ?", userID.(uuid.UUID)).First(&user).Error; err != nil {
		c.JSON(http.StatusNotFound, gin.H{"error": "User not found"})
		return
	}

	// Log user role for debugging
	println("GetMe - User Email:", user.Email, "Role:", user.Role)

	c.JSON(http.StatusOK, gin.H{
		"user": gin.H{
			"id":           user.ID,
			"name":         user.Name,
			"email":        user.Email,
			"role":         user.Role,
			"picture":      user.Picture,
			"school_name": user.SchoolName,
		},
	})
}

func UpdateProfile(c *gin.Context) {
	userID, exists := c.Get("user_id")
	if !exists {
		c.JSON(http.StatusUnauthorized, gin.H{"error": "Unauthorized"})
		return
	}

	var user models.User
	if err := config.DB.Where("id = ?", userID.(uuid.UUID)).First(&user).Error; err != nil {
		c.JSON(http.StatusNotFound, gin.H{"error": "User not found"})
		return
	}

	// Update name if provided
	if name := c.PostForm("name"); name != "" {
		user.Name = name
	}

	// Update school_name if provided
	if schoolName := c.PostForm("school_name"); schoolName != "" {
		user.SchoolName = schoolName
	}

	// Handle picture upload
	file, err := c.FormFile("picture")
	if err == nil {
		// Create uploads directory if not exists
		uploadDir := "uploads/profiles"
		if err := os.MkdirAll(uploadDir, 0755); err != nil {
			c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to create upload directory"})
			return
		}

		// Generate unique filename
		ext := filepath.Ext(file.Filename)
		filename := fmt.Sprintf("%s%s", uuid.New().String(), ext)
		filePath := filepath.Join(uploadDir, filename)

		// Save file
		if err := c.SaveUploadedFile(file, filePath); err != nil {
			c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to save picture"})
			return
		}

		user.Picture = "/" + filePath
	}

	// Save changes
	if err := config.DB.Save(&user).Error; err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to update profile"})
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"message": "Profile updated successfully",
		"user": gin.H{
			"id":           user.ID,
			"name":         user.Name,
			"email":        user.Email,
			"role":         user.Role,
			"picture":      user.Picture,
			"school_name": user.SchoolName,
		},
	})
}
