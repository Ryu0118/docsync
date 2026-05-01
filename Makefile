SWIFTFORMAT := .nest/bin/swiftformat
SWIFTLINT := .nest/bin/swiftlint
SWIFT_LINTER := .nest/bin/my-swift-linter

.PHONY: nest hooks setup format lint ast-lint format-lint test build release check

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

ast-lint:
	@test -f "$(SWIFT_LINTER)" || (echo "Run: make setup" && exit 1)
	"$(SWIFT_LINTER)" --config .swift-ast-lint.yml ./Sources ./Tests

format-lint: format lint

test:
	swift test

build:
	swift build

release:
	swift build -c release

check: format lint ast-lint test
