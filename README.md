# Linux Battery Saver & Multi-Language GPU Benchmark Toolkit

> An open-source Bash toolkit for Linux power-saving controls, CPU/GPU benchmarking, system monitoring, and a basic outbound-connection privacy check.

[![Linux](https://img.shields.io/badge/Linux%20Mint%20%7C%20Ubuntu%20%7C%20Debian-87CF3E?logo=linux&logoColor=white)](#supported-systems)
[![Battery Saver](https://img.shields.io/badge/Battery%20Saver-Eco%20%26%20Ultra-green)](#battery-saver)
[![CUDA Benchmark](https://img.shields.io/badge/CUDA%20Benchmark-Multi--language-76B900?logo=nvidia)](#benchmarks)
[![License](https://img.shields.io/badge/License-GPL--3.0-blue?style=for-the-badge&logo=gnu)](LICENSE)

**One toolkit for Linux power controls, multi-language benchmarks, and system diagnostics.**

## Overview

This Bash toolkit combines several operations in one command-line utility:

1. **Battery saver controls** — checks battery state and can apply configurable power-saving actions at low charge, such as selecting a CPU governor, reducing backlight brightness, or blocking Bluetooth.
2. **CPU/GPU benchmarks** — generates and runs available benchmark implementations across supported language toolchains; CUDA tests require a compatible NVIDIA GPU and CUDA toolkit.
3. **Nexus SMI-style system reporting** — reads available hardware and system information from Linux interfaces and writes a JSON report.
4. **Connection checks** — inspects visible established connections and DNS resolution for selected Google-related domains. This is a basic diagnostic, not proof of surveillance or a comprehensive privacy audit.

Target users: Linux Mint, Ubuntu, and Debian users. Hardware and feature availability vary by system.

## Features

### Battery saver

- Automatic eco and ultra modes based on battery-charge thresholds.
- Attempts to preserve selected settings before applying changes and restore them later.
- May use `cpupower`, TLP, `rfkill`, and Linux sysfs backlight/governor interfaces when available.
- Some operations need elevated privileges and can affect CPU performance, display brightness, or wireless connectivity. Review the script and its actions before running it.

### Benchmarks

The toolkit includes benchmark code for Java, Rust, Python, C++, JavaScript, Go, and CUDA, subject to the source version and installed toolchains. The workload includes repeated numeric calculations and small factorial/Fibonacci checks. Results are hardware-, compiler-, runtime-, and configuration-dependent; they are not universal rankings.

CUDA benchmarking is optional and requires NVIDIA CUDA tooling plus a supported NVIDIA GPU. Missing toolchains are skipped or reported unavailable. Do not compare CPU and GPU timings as equivalent unless the workloads and measurement method are comparable.

### System information and reports

- Reads available CPU, memory, disk, kernel, battery, and GPU information from Linux system interfaces.
- Writes benchmark logs and JSON reports under `~/Documents/nexus_cuda_bench/` and SMI data under `~/Documents/nexus_smi/`.
- Hardware values may be unavailable on desktops, virtual machines, restricted environments, or unsupported drivers.

### Privacy connection check

The `breach` check looks at established connections visible to the current user, attempts DNS lookups, and optionally pings selected domains. It can miss connections and may identify ordinary Google services; **it cannot establish that a device is being spied on**.

## Supported systems

- Ubuntu
- Debian
- Linux Mint

Other Linux distributions may work, but are not guaranteed. Some commands require optional tools or privileges.

## Requirements

- Bash
- `jq` for JSON-related operations
- Optional benchmark toolchains: Java/JDK, Rust/Cargo, Python 3, C++ compiler, Node.js, Go, and NVIDIA CUDA Toolkit for CUDA tests
- Optional system tools: `lspci`, `cpupower`, `rfkill`, `xrandr`, `tlp`, `ss` or `netstat`, `getent`, `ping`, `awk`, and `df`

Install the JSON utility on Debian-based systems if it is missing:

```bash
sudo apt update
sudo apt install jq
```

## Installation

```bash
git clone https://github.com/Aissamohammedi88/Kemux-hacker-os.git
cd Kemux-hacker-os
chmod +x 'vpro smi-nexus+saver'
```

The main script currently has the filename `vpro smi-nexus+saver` (including spaces). Quote the filename when invoking it. Check the repository for updates to the canonical script name.

## Usage

```bash
# Show command help / usage as provided by the script
./'vpro smi-nexus+saver' --help

# Automatic battery handling plus the toolkit's default checks
./'vpro smi-nexus+saver' auto

# Apply the eco battery profile
./'vpro smi-nexus+saver' --battery-eco

# Run the connection/DNS diagnostic
./'vpro smi-nexus+saver' breach

# Run the benchmark mode
./'vpro smi-nexus+saver' test
```

Confirm exact options with the script’s help output; command names can change between versions. Inspect the script before using `sudo` or allowing it to alter system settings.

## Example benchmark output

Timing depends on the machine and installed toolchains. The project’s example numbers are illustrative only; run the benchmark on your own hardware and inspect its generated report. Reports are written under `~/Documents/nexus_cuda_bench/`.

## Safety notes

- Read the Bash script before running it, especially before using privileged operations.
- Battery-saving actions can reduce performance or disable Bluetooth; verify what changed and restore settings when appropriate.
- A Google-domain connection check is only a narrow diagnostic, not evidence that Google or another party is spying on a system.
- Benchmark outputs are not security attestations or standardized performance results.
- Use this toolkit only on Linux systems you own or are authorized to administer.

## License

This repository includes a [`LICENSE`](LICENSE) file identifying the project license. Review it before redistributing or incorporating the code.

## Author

Aissa Mohammedi (DGK)

---

If the toolkit is useful, star the repository and share reproducible benchmark results with hardware and toolchain details.
