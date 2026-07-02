# ugga_bash_config

*A modular framework for clean, maintainable and extensible Bash configurations.*

---

## Overview

`ugga_bash_config` is **not** a collection of aliases or personal dotfiles.

It is a small framework that provides the infrastructure for building modular Bash configurations. Its job is to initialize your shell in a predictable way, load configuration modules, and provide extension points for additional functionality.

The core itself intentionally contains very little logic. Features such as history management, aliases, shell functions, completions or Git integration are implemented as independent modules.

This separation keeps the configuration easy to understand, maintain and extend.

---

## Features

* Modular architecture
* Clearly defined initialization order
* System-wide configuration support
* Per-user configuration support
* Automatic loading of custom modules
* Simple hook system for shell events
* Flexible PATH management
* Configurable prompt
* No duplicated PATH entries
* Optional recursive PATH loading
* Minimal core with no unnecessary dependencies

---

## Design Goals

`ugga_bash_config` follows a few simple principles.

* **Modular**

  * Every feature should live in its own module.

* **Predictable**

  * The loading order is fixed and documented.

* **Extensible**

  * New functionality can be added without modifying the core.

* **System-friendly**

  * Supports both global and per-user configuration.

* **Minimal**

  * The core only provides infrastructure.
  * Feature implementations belong into modules.

---

# Directory Layout

## Global configuration

```text
/usr/lib/ugga_bash_config/
├── core.sh
├── path
├── prompt.sh
└── custom.d/
    ├── aliases.sh
    ├── completion.sh
    └── ...
```

## User configuration

```text
~/.ubc/
├── path
├── prompt.sh
└── custom.d/
    ├── aliases.sh
    ├── history.sh
    └── ...
```

Every file is optional.

---

# Installation

Install the framework somewhere accessible for all users.

The default location is

```text
/usr/lib/ugga_bash_config/
```

To enable the framework, source `core.sh` from your Bash startup file.

For all users:

```bash
# /etc/bashrc

source /usr/lib/ugga_bash_config/core.sh
```

Or for a single user:

```bash
# ~/.bashrc

source /usr/lib/ugga_bash_config/core.sh
```

Nothing else is required.

---

# Initialization Order

The initialization sequence is intentionally deterministic.

## 1. PATH

The following files are processed:

```text
~/.ubc/path
/usr/lib/ugga_bash_config/path
```

Features:

* one directory per line
* comments allowed
* empty lines ignored
* environment variables are expanded
* duplicate entries are removed
* non-existing directories are ignored
* only absolute paths are accepted

Recursive loading is supported:

```text
/opt/scripts/*
```

This adds the directory and all of its subdirectories.

---

## 2. Interactive Shell Check

Non-interactive shells stop here.

Interactive shells continue with the remaining initialization.

---

## 3. Hook System

The core provides two hook types.

### Pre-exec hook

Executed immediately before a command runs.

```bash
add_to_preexec my_function
```

### Prompt hook

Executed before the shell prompt is displayed.

```bash
add_to_prompt_command my_function
```

Multiple modules may register hooks without overwriting each other.

---

## 4. Custom Modules

The following directories are loaded automatically.

```text
/usr/lib/ugga_bash_config/custom.d/
~/.ubc/custom.d/
```

Every `.sh` file inside these directories is sourced automatically.

Typical modules include:

* aliases
* shell functions
* history
* bash-completion
* terminal title
* Git helpers
* environment variables

Global modules are loaded first.

User modules are loaded afterwards.

---

## 5. Prompt

Prompt selection follows a simple rule.

If

```text
~/.ubc/prompt.sh
```

exists, it is used.

Otherwise

```text
/usr/lib/ugga_bash_config/prompt.sh
```

is used.

If neither exists, a simple fallback prompt is used.

---

# Writing Modules

Creating your own module is straightforward.

Example:

```bash
my_prompt_hook() {
    echo "Prompt hook executed."
}

add_to_prompt_command my_prompt_hook
```

Save the file as

```text
~/.ubc/custom.d/example.sh
```

It will automatically be loaded the next time Bash starts.

---

# Philosophy

The framework deliberately separates infrastructure from functionality.

`core.sh` is responsible only for

* initialization
* loading modules
* managing hooks
* configuring PATH
* selecting a prompt

Actual features belong into independent modules.

This keeps the core small, readable and easy to maintain while allowing users to build highly customized Bash environments.

