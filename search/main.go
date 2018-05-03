package main

import (
	"fmt"
	"log"
	"net/http"

	"github.com/globalsign/mgo"
	"github.com/globalsign/mgo/bson"
	"github.com/gorilla/websocket"
)

var session *mgo.Session

func init() {
	var err error
	session, err = mgo.Dial("mongodb://search_db:27017")
	if err != nil {
		fmt.Printf("Error initializing mongodb connection: %v\n", err)
	}
}

func main() {
	http.HandleFunc("/", handler)
	log.Fatal(http.ListenAndServe(":8080", nil))
}

var upgrader = websocket.Upgrader{
	ReadBufferSize:  1024,
	WriteBufferSize: 1024,
	CheckOrigin:     checkOrigin,
}

func checkOrigin(r *http.Request) bool {
	return true
}

func handler(w http.ResponseWriter, r *http.Request) {
	db := session.DB("go-search")
	conn, err := upgrader.Upgrade(w, r, nil)
	if err != nil {
		log.Println(err)
		return
	}

	for {
		messageType, p, err := conn.ReadMessage()
		if err != nil {
			log.Println(err)
			return
		}

		insertMessage(db, Message{bson.NewObjectId(), string(p)})

		if err := conn.WriteMessage(messageType, p); err != nil {
			log.Println(err)
			return
		}
	}
}

type Message struct {
	ID    bson.ObjectId `json:"_id" bson:"_id"`
	Value string        `json:"value" bson:"value"`
}

func insertMessage(db *mgo.Database, msg Message) {
	fmt.Printf("Inserting %v to db\n", msg.Value)
	col := db.C("message")
	err := col.Insert(msg)
	if err != nil {
		fmt.Println(err.Error())
	}
}
