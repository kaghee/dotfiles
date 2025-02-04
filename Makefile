DOTFILES_DIR := $(shell dirname $(realpath $(firstword $(MAKEFILE_LIST))))
OS := $(shell bin/is-supported bin/is-macos macos linux)
HOMEBREW_PREFIX := $(shell bin/is-supported bin/is-macos $(shell bin/is-supported bin/is-arm64 /opt/homebrew /usr/local) /home/linuxbrew/.linuxbrew)
export N_PREFIX = $(HOME)/.n
PATH := $(HOMEBREW_PREFIX)/bin:$(DOTFILES_DIR)/bin:$(N_PREFIX)/bin:$(PATH)
SHELL := env PATH=$(PATH) /bin/bash
SHELLS := /private/etc/shells
BIN := $(HOMEBREW_PREFIX)/bin
MY_SHELL := zsh
export XDG_CONFIG_HOME = $(HOME)/.config
export STOW_DIR = $(DOTFILES_DIR)
export ACCEPT_EULA=Y

# Motivation for adding this was iTerm2 profiles. iTerm2 does have a symlink to AppSupport
# from under .config/iterm2 but stow can't handle symlinks in the target directory.
# Related issue: https://github.com/aspiers/stow/issues/11
export APP_SUPPORT_HOME = "${HOME}/Library/Application\ Support"

.PHONY: test

all: $(OS)

macos: sudo core-macos packages link duti

linux: core-linux link

core-macos: brew ${MY_SHELL} git npm python

core-linux:
	apt-get update
	apt-get upgrade -y
	apt-get dist-upgrade -f

stow-macos: brew
	is-executable stow || brew install stow

stow-linux: core-linux
	is-executable stow || apt-get -y install stow

sudo:
ifndef GITHUB_ACTION
	sudo -v
	while true; do sudo -n true; sleep 60; kill -0 "$$" || exit; done 2>/dev/null &
endif

packages: brew-packages cask-apps node-packages rust-packages

link-linux:
	@echo "Nothing Linux-specific to link."

link-macos:
	stow -t "$(APP_SUPPORT_HOME)" appsupport

link-common:
	for FILE in $$(\ls -A runcom); do if [ -f $(HOME)/$$FILE -a ! -h $(HOME)/$$FILE ]; then \
		mv -v $(HOME)/$$FILE{,.bak}; fi; done
	mkdir -p "$(XDG_CONFIG_HOME)"
	stow -t "$(HOME)" runcom
	stow -t "$(XDG_CONFIG_HOME)" config
	mkdir -p $(HOME)/.local/runtime
	chmod 700 $(HOME)/.local/runtime

link: stow-$(OS) link-common link-${OS}

unlink-linux:
	@echo "Nothing Linux-specific to unlink."

unlink-macos:
	stow -t "$(APP_SUPPORT_HOME)" appsupport

unlink-common:
	stow --delete -t "$(HOME)" runcom
	stow --delete -t "$(XDG_CONFIG_HOME)" config
	for FILE in $$(\ls -A runcom); do if [ -f $(HOME)/$$FILE.bak ]; then \
		mv -v $(HOME)/$$FILE.bak $(HOME)/$${FILE%%.bak}; fi; done

unlink:  stow-$(OS) unlink-common unlink-${OS}

brew:
	is-executable brew || curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install.sh | bash

bash: brew
ifdef GITHUB_ACTION
	if ! grep -q bash $(SHELLS); then \
		brew install bash bash-completion@2 pcre && \
		sudo append $(shell which bash) $(SHELLS) && \
		sudo chsh -s $(shell which bash); \
	fi
else
	if ! grep -q bash $(SHELLS); then \
		brew install bash bash-completion@2 pcre && \
		sudo append $(shell which bash) $(SHELLS) && \
		chsh -s $(shell which bash); \
	fi
endif

zsh: brew
ifdef GITHUB_ACTION
	if ! grep -q zsh $(SHELLS); then \
		brew install zsh && \
		sudo append $(shell which zsh) $(SHELLS) && \
		sudo chsh -s $(shell which zsh); \
	fi
else
	if ! grep -q zsh $(SHELLS); then \
		brew install zsh && \
		sudo append $(shell which zsh) $(SHELLS) && \
		chsh -s $(shell which zsh); \
	fi
endif

git: brew
	brew install git git-extras

python: brew
	is-executable pyenv || brew install pyenv
	pyenv install 3

npm: brew-packages
	n install lts

brew-packages: brew
	brew bundle --file=$(DOTFILES_DIR)/install/Brewfile || true

cask-apps: brew
	brew bundle --file=$(DOTFILES_DIR)/install/Caskfile || true

vscode-extensions: cask-apps
	for EXT in $$(cat install/Codefile); do code --install-extension $$EXT; done

node-packages: npm
	$(N_PREFIX)/bin/npm install --force --location global $(shell cat install/npmfile)

rust-packages: brew-packages
	cargo install $(shell cat install/Rustfile)

duti:
	duti -v $(DOTFILES_DIR)/install/duti

test:
	bats test
