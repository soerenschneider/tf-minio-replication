pre-commit-init:
	pre-commit install

pre-commit-update:
	pre-commit autoupdate

.PHONY:tests
tests:
	go test ./...
