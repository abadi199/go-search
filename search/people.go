package main

import (
	"time"

	"github.com/globalsign/mgo"
	"github.com/globalsign/mgo/bson"
)

// People data
type People struct {
	ID     bson.ObjectId `json:"_id" bson:"_id"`
	Name   string        `json:"name" bson:"name"`
	Point  int32         `json:"point" bson:"point"`
	Signup time.Time     `json:"signup" bson:"signup"`
}

// SearchPeople - search for people from database using the given keyword
func SearchPeople(db *mgo.Database, keyword string) ([]People, error) {
	col := db.C("people")
	var result []People
	err := col.Find(bson.M{"name": bson.RegEx{Pattern: keyword, Options: "i"}}).Limit(100).All(&result)
	return result, err
}
