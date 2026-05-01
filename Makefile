SWIFTFORMAT := .nest/bin/swiftformat
SWIFTLINT := .nest/bin/swiftlint

.PHONY: nest hooks setup format lint format-lint test build release check

nest:
	./scripts/nest.sh bootstrap nestfile.yaml

hooks:
	./scripts/setup-hooks.sh

setup: nest hooks

format:
	@test -f "$(SWIFTFORMAT)" || (echo "Run: make setup" && exit 1)
	"$(SWIFTFORMAT)" --config .swiftformat .

lint:
	@test -f "$(SWIFTLINT)" || (echo "Run: make setup" && exit 1)
	"$(SWIFTLINT)" lint --config .swiftlint.yml --strict

format-lint: format lint

test:
	swift test

build:
	swift build

release:
	swift build -c release

check: format lint test
