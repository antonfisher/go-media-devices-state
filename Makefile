.PHONY: all build run lint clean help

run:
	@echo "Running demo..."
	go run -a cmd/demo.go

lint:
	@echo "Running lint (go vet and fmt)..."
	go vet ./...
	go fmt ./...

help:
	@echo "Available commands:"
	@echo "  make run    - Run the demo (go run -a cmd/demo.go)"
	@echo "  make lint   - Run go vet and go fmt"
