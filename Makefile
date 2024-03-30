# Default target
all: install

# Install target
install:
	@echo "Copying mackup2 to /usr/local/bin..."
	@sudo cp mackup2.sh /usr/local/bin/mackup2
	@sudo chmod +x /usr/local/bin/mackup2
	@echo "Copying mackup2-watchdog to /usr/local/bin..."
	@sudo cp mackup2-watchdog.sh /usr/local/bin/mackup2-watchdog
	@sudo chmod +x /usr/local/bin/mackup2-watchdog
	@echo "Installation complete."

.PHONY: all install
