# SandboxToys2 for AutoHotkey v2

**Version:** 3.0.0.0 (Refactored)

A modernized and refactored version of the original SandboxToys script by r0lZ, updated by blap and others, now fully compatible with AutoHotkey v2 and modern Sandboxie-Plus versions.

## Overview

SandboxToys2 is a powerful utility designed to enhance the experience of using [Sandboxie-Plus](https://github.com/sandboxie-plus/Sandboxie). It provides a convenient menu-driven interface to manage your sandboxes, launch applications, and access a suite of advanced tools for monitoring and analysis.

This version has been completely refactored into a class-based, modular architecture, making it more robust and maintainable, while retaining and enhancing all the features of the original.

## Core Features

- **Dynamic Program Menus:** Automatically generates menus for each of your sandboxes, showing the sandboxed Start Menu, Desktop, and QuickLaunch items.
- **Advanced Tools:** A comprehensive set of tools for each sandbox, including:
  - File and Registry explorers.
  - File and Registry "Watchers" to track changes.
  - An Autostart program lister.
  - Sandbox termination and deletion tools.
- **Modifier Keys:** Use `Ctrl+Click` on menu items to create a sandboxed shortcut on your real desktop, and `Shift+Click` to open the item's location in Explorer.
- **User Tools:** A customizable menu where you can add your own shortcuts to frequently used tools.
- **Portable Sandbox Creator:** A new, powerful feature to trace an application's file and registry dependencies and copy them into a sandbox, making the application more portable.

## Usage

### Running the Script

- **GUI Mode:** Simply run `SandboxToys2.ahk` (or the compiled `.exe`). The main menu will appear at your mouse cursor. Make a selection, and the script will perform the action and exit.
- **Tray Mode:** Launch the script with the `/tray` command-line argument to keep it running in the system tray for quick access.
  ```
  SandboxToys2.ahk /tray
  ```
- **Single Box Mode:** Use the `/box:boxname` argument to restrict the menu to a single sandbox. This can be combined with `/tray`.
  ```
  SandboxToys2.ahk /box:DefaultBox /tray
  ```

### Creating Shortcuts via Command Line

You can create a sandboxed shortcut to any file or program by passing its path as an argument.

```
SandboxToys2.ahk "C:\Path\To\MyProgram.exe"
```

If you have multiple sandboxes, a menu will appear asking you to choose the target sandbox. You can also specify it directly:

```
SandboxToys2.ahk /box:MyGamingBox "C:\Games\MyGame.exe"
```

A great way to use this is to create a shortcut to `SandboxToys2.ahk` in your `SendTo` folder (`shell:sendto`). You can then right-click any file, select "Send to", and choose SandboxToys2 to create a sandboxed shortcut for it.

## Feature Details

### Main Menu

For each sandbox, a sub-menu is created containing:
- **Start Menu, Desktop, QuickLaunch:** These menus mirror the contents of the respective folders inside the sandbox, allowing you to launch sandboxed applications directly.
- **Explore:** Tools for exploring the sandbox's file system.
- **Registry:** Tools for exploring the sandbox's registry hive.
- **Tools:** A collection of management and analysis utilities.

### Tools Menu

- **New Sandboxed Shortcut:** Opens a file dialog to select any program on your system and create a sandboxed shortcut for it on your desktop.
- **Portable Sandbox Creator:** (See below for details)
- **Watch Files and Registry Changes:** Takes a "snapshot" of the current state of the sandbox. You can then run programs, make changes, and when you're done, it will show you a list of all files and registry keys that were added or modified.
- **Command Prompt (Sandboxed/Unsandboxed):** Opens a command prompt either inside the sandbox or on the host system, pre-set to the sandbox's root directory.
- **Programs and Features:** Launches the "Add/Remove Programs" applet sandboxed.
- **Terminate/Delete:** Forcefully terminates all programs in the sandbox or deletes its contents.

### Portable Sandbox Creator

This new, advanced tool helps make sandboxed applications more portable by identifying their dependencies.

**Prerequisite:** You must have **Process Monitor (`ProcMon.exe`)** from Microsoft Sysinternals available on your system (either in the same folder as SandboxToys2 or in your system's PATH).

**How it works:**
1.  **Launch:** Select "Portable Sandbox Creator" from the Tools menu.
2.  **Configure:** In the new window, select the `.exe` file you want to trace, the target sandbox, and the tracing mode (Files, Registry, or Both).
3.  **Trace:** Click "Start Tracing". The tool will launch your program in the sandbox while ProcMon records all its activity in the background.
4.  **Use the App:** Use your application normally. Open different features and dialogs to ensure all dependencies are triggered and read.
5.  **Analyze:** When you close your application, the tool will automatically analyze the ProcMon log.
6.  **Copy:** It will then copy all the external files and registry keys that your application *read* from your host system into the sandbox.

The result is a more self-contained sandbox that is less dependent on your specific machine's configuration and can be more easily moved to other computers.

### Options Menu

- **Icon Size:** Control the size of icons in the main menus and sub-menus.
- **Seperated Menus:** Choose whether to merge the "All Users" and "Current User" Start Menus/Desktops or show them as separate sub-menus.
- **Include Box Names:** Toggles whether the sandbox name (e.g., `[#DefaultBox]`) is prepended to shortcuts created by the script.
