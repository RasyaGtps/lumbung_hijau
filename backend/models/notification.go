package models

import (
	"time"

	"github.com/google/uuid"
	"gorm.io/gorm"
)

type Notification struct {
	ID        uuid.UUID `gorm:"type:uuid;primary_key" json:"id"`
	UserID    uuid.UUID `gorm:"type:uuid;not null" json:"user_id"`
	User      User      `gorm:"foreignKey:UserID" json:"-"`
	DepositID *uuid.UUID `gorm:"type:uuid" json:"deposit_id,omitempty"`
	Title     string    `gorm:"not null" json:"title"`
	Message   string    `gorm:"not null" json:"message"`
	Type      string    `gorm:"default:'deposit_update'" json:"type"`
	IsRead    bool      `gorm:"default:false" json:"is_read"`
	CreatedAt time.Time `json:"created_at"`
}

func (n *Notification) BeforeCreate(tx *gorm.DB) error {
	n.ID = uuid.New()
	// Set timezone to Jakarta (WIB/UTC+7)
	loc, _ := time.LoadLocation("Asia/Jakarta")
	n.CreatedAt = time.Now().In(loc)
	return nil
}
