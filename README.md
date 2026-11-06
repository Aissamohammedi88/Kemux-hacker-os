<div align="center">
  <h1>🖥️ KEMUS OS v4</h1>
  <p><strong>The True Virtual Environment. Not a simulation.</strong></p>
  <p><em>Developed in 2 hours. Already functional. Running in your browser.</em></p>
  
  [![Debian](https://img.shields.io/badge/Base-Debian_Light-A80030?style=for-the-badge&logo=debian&logoColor=white)](#)
  [![Web-Native](https://img.shields.io/badge/Web--Native-Yes-00ff9d?style=for-the-badge)](#)
  [![Virtual](https://img.shields.io/badge/Environment-Real_Virtual-red?style=for-the-badge)](#)
  [![License](https://img.shields.io/badge/License-MIT-blue?style=for-the-badge)](#)
</div>
---
## 🧬 Overview
**Kemus** is not a web-based simulation of an operating system. It is a **real virtual environment** running inside your browser (Mozilla Firefox). 

Built on a **lightweight Debian base**, Kemus provides a full workstation environment where you can run workflows, execute commands, and manage files exactly as you would on your physical machine. The difference? It's completely isolated,ultra-lightweight, and requires zero installation.

**The Kemus Philosophy:** *If it doesn't work in a real environment, it's not a real OS.*
---

## 🚀 Key Features

### 1. Real Virtual Environment (Not a Simulation)
Kemus uses a real virtualized backend. When you run a command, it doesn't fake the output. It executes in a real Debian environment, reading real files, running real processes, and managing real system resources.

### 2. Ultra-Lightweight Custom Packages
I built the entire package ecosystem from scratch in **2 hours**. It contains only the essential, ultra-lightweight packages needed to run workflows. No bloat, no unnecessary dependencies. Just pure performance.

### 3. Systemic Languages Included
Kemus comes pre-configured with **systemic programming languages** that are rarely found in standard environments. This includes:
- **Gecko**: TS ergonomics + low-level control (traits, generics, inline ASM).
- **Myrddin**: Strong-typed C alternative (generics, type inference, closures).
- **Minz**: Retro Z80/6502/Game Boy with modern syntax.
- **Sespoul**: GOTO-less portable, COBOL-ish, fine runtime control.
- **CoreX**: Python-syntax + C++ transpile.

### 4. Workflow Studio
Built-in workflow runner. You can write YAML workflows (like GitHub Actions) and execute them directly in the Kemus environment. The terminal shows the real-time output of your builds, scripts, and commands.

### 5. Web-Native Interface
The entire OS runs in a browser tab. The UI is a native web interface, with a terminal, file manager, text editor, and workflow studio. All accessible via `http://127.0.0.1:3922`.
---
## 🛠️ Architecture

```mermaid
graph TD
    A[Web Browser] -->|HTTP/WebSocket| B[Kemus Backend]
    B --> C[Debian Light Virtual Environment]
    C --> D[Terminal / File Manager / Workflow Studio]
    D --> E[Systemic Languages: Gecko, Myrddin, Minz, Sespoul, CoreX]
    style B fill:#00ff9d,color:#000
    style C fill:#A80030,color:#fff
    style E fill:#00d4ff,color:#000
linux-battery-saver-cuda-gpu-benchmark-toolkit+smi not nvdia driver = nexus driver smi open source
Open-source Linux battery saver + CUDA GPU benchmark. Optimizes power, tests Java Rust Python C++ JS Go CUDA. For Ubuntu, Mint, Debian.
# Linux Battery Saver & CUDA GPU Benchmark Toolkit
