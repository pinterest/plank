.PHONY: update-linters update-owners update-test-engine

all:

update-linters:
	cd .. && git subtree pull --prefix=.arcanist/linters --squash https://github.com/pinterest/arcanist-linters.git master

update-owners:
	cd .. && git subtree pull --prefix=.arcanist/owners --squash https://github.com/pinterest/arcanist-owners.git master

update-test-engine:
	cd .. && git subtree pull --prefix=.arcanist/arc-xcode-test-engine --squash https://github.com/google/arc-xcode-test-engine.git master
