package controller

import (
	"context"
	"encoding/json"
	"fmt"
	"log"
	"net/http"
	"os"

	"cloud.google.com/go/compute/metadata"
	sqladmin "google.golang.org/api/sqladmin/v1beta4"
)

type instanceStatePayload struct {
	InstanceName string `json:"instanceName"`
	State        string `json:"state"`
}

func HandleInstanceState(w http.ResponseWriter, r *http.Request) {
	log.Println("function start")

	if r.Method != "POST" {
		log.Printf("received unsupported method: '%s'\nexiting...", r.Method)
		w.WriteHeader(http.StatusMethodNotAllowed)
		return
	}

	body := json.NewDecoder(r.Body)

	var requestPayload instanceStatePayload

	if err := body.Decode(&requestPayload); err != nil {
		log.Printf("failed to parse request body: %v\n", err)
		w.WriteHeader(http.StatusBadRequest)
		w.Write([]byte(fmt.Sprintf("failed to parse request body: %v\n", err)))
		return
	}

	projectID := os.Getenv("PROJECT_ID")

	if requestPayload.InstanceName == "" {
		log.Println("instanceName is required")
		w.WriteHeader(http.StatusBadRequest)
		w.Write([]byte("instanceName is required"))
		return
	}

	if requestPayload.State == "" {
		log.Println("state is required")
		w.WriteHeader(http.StatusBadRequest)
		w.Write([]byte("state is required"))
		return
	}

	if projectID == "" {
		var err error

		projectID, err = metadata.ProjectID()

		if err != nil {
			log.Printf("failed to fetch project id: %v\n", err)
			w.WriteHeader(http.StatusInternalServerError)
			w.Write([]byte(fmt.Sprintf("failed to fetch project id: %v\n", err)))
			return
		}
	}

	ctx := context.Background()
	sqlAdminService, err := sqladmin.NewService(ctx)

	if err != nil {
		log.Printf("failed to create sql admin service: %v\n", err)
		w.WriteHeader(http.StatusInternalServerError)
		w.Write([]byte(fmt.Sprintf("failed to create sql admin service: %v\n", err)))
		return
	}

	// 'ALWAYS' == turn it on
	// 'NEVER'  == turn it off
	instanceState := "ALWAYS"

	if requestPayload.State == "off" {
		instanceState = "NEVER"
	}

	log.Println("fetching instance state...")

	instanceGet := sqlAdminService.Instances.Get(projectID, requestPayload.InstanceName)

	instance, err := instanceGet.Do()

	if err != nil {
		log.Printf("failed to get cloud sql instance: %v\n", err)
		w.WriteHeader(http.StatusBadGateway)
		w.Write([]byte(fmt.Sprintf("failed to get cloud sql instance: %v\n", err)))
		return
	}

	log.Println("fetched instance state")

	instance.Settings.ActivationPolicy = instanceState

	instancePatch := sqlAdminService.Instances.Patch(projectID, requestPayload.InstanceName, instance)

	log.Println("changing instance state...")

	instancePatchResult, err := instancePatch.Do()

	if err != nil {
		log.Printf("failed to patch cloud sql instance: %v\n", err)
		w.WriteHeader(http.StatusBadGateway)
		w.Write([]byte(fmt.Sprintf("failed to patch cloud sql instance: %v\n", err)))
		return
	}

	log.Println("successfully changed instance state")

	w.WriteHeader(http.StatusOK)

	log.Printf("patch type: '%s', status: '%s'", instancePatchResult.OperationType, instancePatchResult.Status)
	w.Write([]byte(fmt.Sprintf("patch type: '%s', status: '%s'", instancePatchResult.OperationType, instancePatchResult.Status)))

	log.Println("function end")
}
