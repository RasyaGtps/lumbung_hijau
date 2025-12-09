package models

import (
	"time"

	"github.com/google/uuid"
	"gorm.io/gorm"
)

type User struct {
	ID         uuid.UUID `gorm:"type:uuid;primary_key" json:"id"`
	Name       string    `gorm:"not null" json:"name"`
	Email      string    `gorm:"unique;not null" json:"email"`
	Password   string    `gorm:"not null" json:"-"`
	Picture    string    `json:"picture"`
	SchoolName string    `json:"school_name"`
	Role       string    `gorm:"default:'user'" json:"role"`
	CreatedAt  time.Time `json:"created_at"`
	UpdatedAt  time.Time `json:"updated_at"`
}

func (u *User) BeforeCreate(tx *gorm.DB) error {
	u.ID = uuid.New()
	return nil
}
