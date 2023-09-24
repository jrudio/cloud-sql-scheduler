## Usage

PROJECT_ID=<project-id> INSTANCE_NAME=<instance-name> INSTANCE_DESIRED_STATE=on|off ./sql_scheduler

Make sure to zip before uploading to the bucket

mkdir ../dist

zip ../dist/instance-state-controller.zip go.mod go.sum controller.go