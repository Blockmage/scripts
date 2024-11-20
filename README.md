# Scripts

A collection of utility scripts and configurations with a focus on modularity and reusability. This
repository serves as both a toolkit and a template for organizing multi-language script collections.

## Repository Structure

```text
.
├── init.sh          # Core initialization script
├── init.d/          # Shared utility functions
├── sh/              # Shell scripts and modules
├── configs/         # Configuration files
└── {py,ts,...}/     # Future language-specific directories
```

### Core Components

#### Initialization System ([`init.sh`] and [`init.d/`])

The repository uses a modular initialization system:

- [`init.sh`] serves as the primary entry point and must be sourced first.
- [`init.d/`] contains shared utility functions that are automatically sourced by [`init.sh`].
- Environment files (`*.env`) are automatically discovered and sourced.

#### Script Organization

Each language-specific directory follows a consistent pattern:

- Top-level files serve as entry points.
- Matching subdirectories contain individual functions and components.
- Components can (generally) be used independently or as part of their parent script.

For example:

```text
sh/
├── task_script.sh        # Entry point
└── task_script/          # Component directory
    ├── function1.sh
    └── function2.sh
```

### Current Implementations

- Shell utilities in `sh/`.
- Common, reusable project configuration files (linters, Git, etc.) in `configs/`.

### Usage

1. Source the initialization script:

   ```bash
   source init.sh
   ```

2. Use individual scripts or functions as needed:

   ```bash
   # Use a complete script
   ./sh/task_script.sh

   # Or source and use individual functions
   source sh/task_script/function1.sh
   ```

## Planned Additions

- Python package/module directory (`py/`).
- TypeScript/JavaScript directory (`ts/`).
- Additional language support as needed.

## License

Copyright 2024 [Alchemyst0x], [Blockmage Ltd], and Contributors.

Licensed under the [Apache License, Version 2.0].

---

[Alchemyst0x]: https://github.com/Alchemyst0x
[Blockmage Ltd]: https://github.com/Blockmage
[`init.sh`]: /init.sh
[`init.d/`]: /init.d/
[Apache License, Version 2.0]: /license.txt
