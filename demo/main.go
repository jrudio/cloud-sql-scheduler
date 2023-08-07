package main

import (
	"fmt"
	"net/http"

	controller "github.com/jrudio/cloud-sql-scheduler/src_function"
)

func main() {
	fmt.Println("listening for connections...")

	http.HandleFunc("/", controller.HandleInstanceState)

	http.ListenAndServe(":8080", nil)
}
