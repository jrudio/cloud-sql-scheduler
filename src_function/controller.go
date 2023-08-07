package controller

import (
	"context"
	"log"
	"os"

	"cloud.google.com/go/compute/metadata"
	sqladmin "google.golang.org/api/sqladmin/v1beta4"
)

func HandleInstanceState() {
	log.Println("function start")

	instanceName := os.Getenv("INSTANCE_NAME")
	desiredInstanceState := os.Getenv("INSTANCE_DESIRED_STATE")
	projectID := os.Getenv("PROJECT_ID")

	if instanceName == "" {
		log.Fatalln("INSTANCE_NAME env var is required")
	}

	if desiredInstanceState == "" {
		log.Fatalln("INSTANCE_DESIRED_STATE env var is required")
	}

	if projectID == "" {
		var err error

		projectID, err = metadata.ProjectID()

		if err != nil {
			log.Printf("failed to fetch project id: %v\n", err)
			return
		}
	}

	ctx := context.Background()
	sqlAdminService, err := sqladmin.NewService(ctx)

	if err != nil {
		log.Printf("failed to create sql admin service: %v\n", err)
		return
	}

	// 'ALWAYS' == turn it on
	// 'NEVER'  == turn it off
	instanceState := "ALWAYS"

	if desiredInstanceState == "off" {
		instanceState = "NEVER"
	}

	instanceGet := sqlAdminService.Instances.Get(projectID, instanceName)

	instance, err := instanceGet.Do()

	if err != nil {
		log.Printf("failed to get cloud sql instance: %v\n", err)

		return
	}

	instance.Settings.ActivationPolicy = instanceState

	instancePatch := sqlAdminService.Instances.Patch(projectID, instanceName, instance)

	instancePatchResult, err := instancePatch.Do()

	if err != nil {
		log.Printf("failed to patch cloud sql instance: %v\n", err)

		return
	}

	log.Printf("patch type: '%s', status: '%s'", instancePatchResult.OperationType, instancePatchResult.Status)

	// instancePatch
	log.Println("function end")
}
