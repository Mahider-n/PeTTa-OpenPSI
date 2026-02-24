# Minecraft OpenPsi Agent

An embodied cognitive agent for Minecraft, powered by OpenPsi and MeTTa.

## Overview

This use-case connects OpenPsi's cognitive architecture to Minecraft via Vereya, enabling an agent whose behavior **emerges from internal needs** (hunger, safety, curiosity) rather than scripted logic.


## Requirements

- **Minecraft Java Edition** (Version 1.21).
- **Fabric Loader** (Version 1.21).
- **Python 3**.

- **Vereya requires fabric loader and fabric api to installed. Please see instructions**

    - https://fabricmc.net/use/installer/
    - https://www.curseforge.com/minecraft/mc-mods/fabric-api

---

## 1. Install Minecraft Mod

1. Install **Fabric Loader 1.21**.
2. Go to your Minecraft `mods` folder.
3. Add these two files:
   - `fabric-api-[version]+1.21.jar`
   - `vereya-fabric-[version].jar`

## 2. Install Python Library

Open your Linux (WSL) terminal and run:

```bash
pip install git+https://github.com/trueagi-io/minecraft-demo.git
```

## 3. Configure IP Address

In Linux terminal, find your IP:

```bash
ip route show default | awk '{print $3}'
```

(Copy this IP. Example: 172.19.176.1)

1. Find `clientIp='...'`. Change it to your IP.

## How to Run

1. Start Minecraft game with Fabric Loader on your PC.
2. In your Linux (WSL) terminal, run the script you want, e.g.:

    ```bash
    python3 use-cases/minecraft/vereya-api-test.py
    ```
3. The agent will connect to Minecraft and start acting.