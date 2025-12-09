package models

import (
	"time"

	"github.com/google/uuid"
	"gorm.io/gorm"
)

type WasteDeposit struct {
	ID           uuid.UUID `gorm:"type:uuid;primary_key" json:"id"`
	UserID       uuid.UUID `gorm:"type:uuid;not null" json:"user_id"`
	User         User      `gorm:"foreignKey:UserID" json:"user,omitempty"`
	SchoolName   string    `gorm:"not null" json:"school_name"`
	ContactName  string    `gorm:"not null" json:"contact_name"`
	ContactPhone string    `gorm:"not null" json:"contact_phone"`
	Address      string    `gorm:"not null" json:"address"`
	PickupDate   time.Time `gorm:"not null" json:"pickup_date"`
	BinCount     int       `gorm:"not null" json:"bin_count"`
	WasteType    string    `gorm:"not null" json:"waste_type"`
	PhotoProof   string    `json:"photo_proof"`
	Weight       *float64  `json:"weight"` // Weight in kg, filled by admin
	Status       string    `gorm:"default:'pending'" json:"status"` // pending, proses, completed, rejected
	CreatedAt    time.Time `json:"created_at"`
	UpdatedAt    time.Time `json:"updated_at"`
}

func (w *WasteDeposit) BeforeCreate(tx *gorm.DB) error {
	w.ID = uuid.New()
	return nil
}
