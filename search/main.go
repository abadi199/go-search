package main

import (
	"log"
	"net/http"

	"encoding/json"

	"github.com/globalsign/mgo"
	"github.com/gorilla/websocket"
)

var session *mgo.Session

func init() {
	var err error
	session, err = mgo.Dial("mongodb://search_db:27017")
	if err != nil {
		log.Println("Error connecting to database", err)
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
			log.Println("Error reading from websocket", err)
			return
		}

		result, err := SearchPeople(db, string(p))
		if err != nil {
			log.Println("Error querying database", err)
			return
		}

		json, err := json.Marshal(result)
		if err != nil {
			log.Println("Error marshaling result to json", err)
		}

		if err := conn.WriteMessage(messageType, json); err != nil {
			log.Println("Error writing to websocket", err)
			return
		}
	}
}
