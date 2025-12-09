package models

import (
	"time"

	"github.com/google/uuid"
	"gorm.io/gorm"
)

type ChatMessage struct {
	ID         uuid.UUID `gorm:"type:uuid;primary_key" json:"id"`
	SenderID   uuid.UUID `gorm:"type:uuid;not null" json:"sender_id"`
	ReceiverID uuid.UUID `gorm:"type:uuid;not null" json:"receiver_id"`
	Sender     User      `gorm:"foreignKey:SenderID" json:"sender,omitempty"`
	Receiver   User      `gorm:"foreignKey:ReceiverID" json:"receiver,omitempty"`
	Message    string    `gorm:"not null" json:"message"`
	IsRead     bool      `gorm:"default:false" json:"is_read"`
	CreatedAt  time.Time `json:"created_at"`
}

func (m *ChatMessage) BeforeCreate(tx *gorm.DB) error {
	m.ID = uuid.New()
	return nil
}
