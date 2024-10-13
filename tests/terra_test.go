package test

import (
	"bytes"
	"context"
	"encoding/json"
	"errors"
	"fmt"
	"io"
	"net/http"
	"strings"
	"testing"
	"time"

	"github.com/gruntwork-io/terratest/modules/docker"
	"github.com/gruntwork-io/terratest/modules/retry"
	"github.com/gruntwork-io/terratest/modules/terraform"
	"github.com/minio/minio-go/v7"
	"github.com/minio/minio-go/v7/pkg/credentials"
	"github.com/stretchr/testify/assert"
)

const (
	minioReplicationSourceUrl = "http://localhost:9000"
	minioReplicationTargetUrl = "http://localhost:9002"
	vaultUrl                  = "http://localhost:8200"
	minioAdminUser            = "minioadmin"
	minioAdminPass            = "minioadmin"
	bucketName                = "replicated-bucket"
	filePath                  = "test/hello"
	fileContent               = "world"
	vaultToken                = "test"
)

var vaultSecretPath = "secret/data/env/dev/minio-replication/serviceaccount/test"

func TestTerragrunt(t *testing.T) {
	workDir := "../envs/dev"
	dockerOpts := &docker.Options{
		WorkingDir: workDir,
		EnvVars: map[string]string{
			"COMPOSE_FILE": "docker-compose.yaml",
		},
	}

	defer docker.RunDockerCompose(t, dockerOpts, "down")
	docker.RunDockerCompose(t, dockerOpts, "up", "-d")

	waitForVault(t)
	waitForMinio(t, minioReplicationSourceUrl)
	waitForMinio(t, minioReplicationTargetUrl)

	terraformOptions := terraform.WithDefaultRetryableErrors(t, &terraform.Options{
		TerraformDir:    workDir,
		TerraformBinary: "terragrunt",
		EnvVars: map[string]string{
			"TF_ENCRYPTION": `key_provider "pbkdf2" "mykey" {passphrase = "somekeynotverysecure"}`,
		},
	})

	defer terraform.Destroy(t, terraformOptions)
	terraform.Apply(t, terraformOptions)

	secret, err := readVaultSecret(vaultUrl, vaultToken, vaultSecretPath)
	assert.NoErrorf(t, err, "Could not read vault secret")
	assert.Contains(t, secret, "AWS_ACCESS_KEY_ID")
	assert.Contains(t, secret, "AWS_SECRET_ACCESS_KEY")

	err = putObjectSourceBucket(strings.Replace(minioReplicationSourceUrl, "http://", "", 1), secret["AWS_ACCESS_KEY_ID"].(string), secret["AWS_SECRET_ACCESS_KEY"].(string), bucketName)
	assert.NoErrorf(t, err, "Could not write to source bucket")

	time.Sleep(500 * time.Millisecond)

	read, err := readObjectTargetBucket(strings.Replace(minioReplicationTargetUrl, "http://", "", 1), minioAdminUser, minioAdminPass, bucketName)
	assert.NoErrorf(t, err, "Could not read from target bucket")

	assert.Equal(t, read, "world")
}

func readVaultSecret(vaultAddr, token, secretPath string) (map[string]interface{}, error) {
	url := fmt.Sprintf("%s/v1/%s", vaultAddr, secretPath)

	req, err := http.NewRequest("GET", url, nil)
	if err != nil {
		return nil, fmt.Errorf("failed to create request: %v", err)
	}

	req.Header.Set("X-Vault-Token", token)
	client := &http.Client{
		Timeout: 1 * time.Second,
	}
	resp, err := client.Do(req)
	if err != nil {
		return nil, fmt.Errorf("failed to send request: %v", err)
	}
	defer resp.Body.Close()

	if resp.StatusCode != http.StatusOK {
		return nil, fmt.Errorf("unexpected response status: %s", resp.Status)
	}
	body, err := io.ReadAll(resp.Body)
	if err != nil {
		return nil, fmt.Errorf("failed to read response body: %v", err)
	}

	var responseData map[string]interface{}
	if err := json.Unmarshal(body, &responseData); err != nil {
		return nil, fmt.Errorf("failed to parse JSON response: %v", err)
	}

	data, ok := responseData["data"].(map[string]interface{})
	if !ok {
		return nil, fmt.Errorf("unexpected response structure")
	}

	secretData, ok := data["data"].(map[string]interface{})
	if !ok {
		return nil, fmt.Errorf("unexpected secret data structure")
	}

	return secretData, nil
}

func putObjectSourceBucket(endpoint, accessKey, secretKey, bucketName string) error {
	minioClient, err := minio.New(endpoint, &minio.Options{
		Creds:  credentials.NewStaticV4(accessKey, secretKey, ""),
		Secure: false, // Set to true if using HTTPS
	})
	if err != nil {
		return fmt.Errorf("failed to initialize MinIO client: %v", err)
	}

	// Content to upload
	content := []byte(fileContent)

	// Create a bytes.Reader to send the content
	reader := bytes.NewReader(content)

	// Upload the content directly to MinIO
	_, err = minioClient.PutObject(context.Background(), bucketName, filePath, reader, int64(reader.Len()), minio.PutObjectOptions{})
	if err != nil {
		return err
	}

	fmt.Println("File uploaded successfully!")
	return nil
}

func readObjectTargetBucket(endpoint, accessKey, secretKey, bucketName string) (string, error) {
	minioClient, err := minio.New(endpoint, &minio.Options{
		Creds:  credentials.NewStaticV4(accessKey, secretKey, ""),
		Secure: false, // Set to true if using HTTPS
	})
	if err != nil {
		return "", fmt.Errorf("failed to initialize MinIO client: %v", err)
	}

	obj, err := minioClient.GetObject(context.Background(), bucketName, filePath, minio.GetObjectOptions{})
	if err != nil {
		return "", fmt.Errorf("error getting object: %w", err)
	}
	defer obj.Close()

	// Read the content
	data, err := io.ReadAll(obj)
	if err != nil {
		return "", fmt.Errorf("error reading object: %w", err)
	}

	return string(data), nil
}

func checkBucket(endpoint, accessKey, secretKey, bucketName string) error {
	// Initialize the MinIO client
	minioClient, err := minio.New(endpoint, &minio.Options{
		Creds:  credentials.NewStaticV4(accessKey, secretKey, ""),
		Secure: false, // Set to true if using HTTPS
	})
	if err != nil {
		return fmt.Errorf("failed to initialize MinIO client: %v", err)
	}

	//minioClient.ListObjects(context.Background(), bucketName, minio.ListObjectsOptions{})
	exists, err := minioClient.BucketExists(context.Background(), bucketName)
	if err != nil {
		return fmt.Errorf("failed to check if bucket exists: %v", err)
	}

	if !exists {
		return errors.New("bucket does not exist")
	}

	return nil
}

func waitForVault(t *testing.T) {
	retry.DoWithRetry(t, "Waiting for vault service", 100, 1*time.Second, func() (string, error) {
		resp, err := http.Get(vaultUrl + "/ui/")
		if err != nil {
			return "", err
		}
		defer resp.Body.Close()

		if resp.StatusCode != 200 {
			return "", fmt.Errorf("expected HTTP status 200 but got %d", resp.StatusCode)
		}

		return "Service is available", nil
	})
}

func waitForMinio(t *testing.T, minioUrl string) {
	retry.DoWithRetry(t, "Waiting for minio service", 100, 1*time.Second, func() (string, error) {
		resp, err := http.Get(minioUrl + "/minio/health/live")
		if err != nil {
			return "", err
		}
		defer resp.Body.Close()

		if resp.StatusCode != 200 {
			return "", fmt.Errorf("expected HTTP status 200 but got %d", resp.StatusCode)
		}

		return "Service is available", nil
	})
}
