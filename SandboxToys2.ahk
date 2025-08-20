A_Persistent := true
A_SingleInstance := "Off"

; Represents a single Sandboxie box and its associated properties.
class Sandbox
{
    __New(name, fileRootPath, keyRootPath, dropAdminRights, enabled, neverDelete, useFileImage, useRamDisk)
    {
        this.name := name
        this.FileRootPath := fileRootPath
        this.KeyRootPath := keyRootPath
        this.DropAdminRights := dropAdminRights
        this.Enabled := enabled
        this.NeverDelete := neverDelete
        this.UseFileImage := useFileImage
        this.UseRamDisk := useRamDisk

        this.bpath := StrReplace(expandEnvVars(this.FileRootPath), "`%SANDBOX`%", this.name)
        this.bkey := StrReplace(expandEnvVars(this.KeyRootPath), "`%SANDBOX`%", this.name)

        local bkeyrootpathR := StrReplace(this.KeyRootPath, A_UserName, "`%USER`%")
        local regspos := InStr(bkeyrootpathR, "\", , 0)
        local regepos := InStr(bkeyrootpathR, "%")
        this.RegStr_ := SubStr(bkeyrootpathR, regspos + 1, regepos - regspos - 2)

        this.exist := DirExist(this.bpath) && FileExist(this.bpath . "\RegHive")
    }
}

; Holds global variables, constants, and application-wide state.
; Initializes critical paths and settings on startup.
class Globals
{
    static version := "3.0.0.0"
    static nameNoExt, title, shell32, imageres, cmdRes, explorerImg, explorerRes
    static explorer, explorerE, explorerER, explorerERArg, explorerArg, explorerArgE, explorerArgER
    static regeditImg, regeditRes, SID, SESSION, sbdir, start, SbieCtrl, SbieMngr, SbieAgent
    static SbieAgentResMain, SbieAgentResMainId, SbieAgentResMainText, SbieAgentResFull, SbieAgentResFullId, SbieAgentResEmpty, SbieAgentResEmptyId
    static ini, sandboxes_path, sandboxes_array, username

    static init()
    {
        try {
        SplitPath(A_ScriptName, , , , &this.nameNoExt)
        this.title := "SandboxToys v" . this.version . " by r0lZ updated by blap"
        if (this.nameNoExt != "SandboxToys")
            this.title .= " (" . this.nameNoExt . ")"

        this.shell32  := A_WinDir . "\system32\shell32.dll"
        this.imageres := A_WinDir . "\system32\imageres.dll"
        this.cmdRes   := A_WinDir . "\system32\cmd.exe"
        this.username := A_UserName

        this.explorerImg := A_WinDir . "\system32\explorer.exe"
        if (!FileExist(this.explorerImg))
            this.explorerImg := A_WinDir . "\explorer.exe"

        this.explorerRes := A_WinDir . "\system32\explorer.exe"
        if (!FileExist(this.explorerRes))
            this.explorerRes := A_WinDir . "\explorer.exe"

        this.explorer    := this.explorerImg . " /e,::{20D04FE0-3AEA-1069-A2D8-08002B30309D}"
        this.explorerE   := this.explorerImg . " /e"
        this.explorerER  := this.explorerImg . " /e /root"
        this.explorerERArg := this.explorerImg . " /e /root,::{20D04FE0-3AEA-1069-A2D8-08002B30309D}"
        this.explorerArg   := ",::{20D04FE0-3AEA-1069-A2D8-08002B30309D}"
        this.explorerArgE  := "/e,::{20D04FE0-3AEA-1069-A2D8-08002B30309D}"
        this.explorerArgER := "/e /root,::{20D04FE0-3AEA-1069-A2D8-08002B30309D}"

        this.regeditImg := A_WinDir . "\system32\regedit.exe"
        if (!FileExist(this.regeditImg))
            this.regeditImg := A_WinDir . "\regedit.exe"

        this.regeditRes := A_WinDir . "\system32\regedit.exe"
        if (!FileExist(this.regeditRes))
            this.regeditRes := A_WinDir . "\regedit.exe"

        Loop Reg, "HKEY_CURRENT_USER\Software\Microsoft\Protected Storage System Provider", "K"
        {
            if (A_LoopRegType == "KEY")
            {
                this.SID := A_LoopRegName
                break
            }
        }
        this.SESSION := RegRead("HKEY_CURRENT_USER\Volatile Environment", "SESSION", 0)
        if (this.SESSION == "" || this.SESSION == "Console")
            this.SESSION := 0

        local imagepath := RegRead("HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\services\SbieSvc", "ImagePath")
        imagepath := Trim(imagepath, A_Quotes)
        SplitPath(imagepath, , &this.sbdir)
        this.start     := this.sbdir . "\Start.exe"
        this.SbieCtrl  := this.sbdir . "\SbieCtrl.exe"
        this.SbieMngr  := this.sbdir . "\SandMan.exe"
        this.SbieAgent := this.SbieMngr
        if (!FileExist(this.SbieAgent))
        {
            this.SbieAgent := this.sbdir . "\SbieCtrl.exe"
            if (!FileExist(this.SbieAgent))
            {
                MsgBox(16, this.title, "Can't find Sandboxie installation folder. Sorry.")
                ExitApp
            }
        }

        if (this.SbieAgent == this.SbieCtrl)
        {
            this.SbieAgentResMain     := this.SbieAgent
            this.SbieAgentResMainId   := 1
            this.SbieAgentResMainText := "Sandboxie Control"
            this.SbieAgentResFull     := this.SbieCtrl
            this.SbieAgentResFullId   := 3
            this.SbieAgentResEmpty    := this.SbieCtrl
            this.SbieAgentResEmptyId  := 10
            if (A_IsCompiled)
            {
                this.SbieAgentResMain     := this.SbieCtrl
                this.SbieAgentResMainId   := 1
                this.SbieAgentResMainText := "Sandboxie Control"
                this.SbieAgentResFull     := this.SbieCtrl
                this.SbieAgentResFullId   := 3
                this.SbieAgentResEmpty    := this.SbieCtrl
                this.SbieAgentResEmptyId  := 10
            }
        }
        else
        {
            this.SbieAgentResMain     := this.SbieAgent
            this.SbieAgentResMainId   := 1
            this.SbieAgentResMainText := "Sandboxie-Plus Manager"
            this.SbieAgentResFull     := "Resources\IconFull.ico"
            this.SbieAgentResFullId   := 1
            this.SbieAgentResEmpty    := "Resources\IconEmpty.ico"
            this.SbieAgentResEmptyId  := 1
            if (A_IsCompiled)
            {
                this.SbieAgentResMain     := this.SbieMngr
                this.SbieAgentResMainId   := 1
                this.SbieAgentResMainText := "Sandboxie-Plus Manager"
                this.SbieAgentResFull     := A_ScriptFullPath
                this.SbieAgentResFullId   := 6
                this.SbieAgentResEmpty    := A_ScriptFullPath
                this.SbieAgentResEmptyId  := 7
            }
        }

        local IniPathO := RegRead("HKLM\SYSTEM\CurrentControlSet\Services\SbieDrv", "IniPath") ; check custom config location in registry
        local IniPath  := IniPathO
        this.ini      := ""
        if ((IniPath != "") && (SubStr(IniPath, 1, 4) == "\??\") && (SubStr(IniPath, 8) != "") && (FileExist(SubStr(IniPath, 5))))
        {
            IniPath := SubStr(IniPath, 5)
            this.ini     := IniPath
        }
        else
        {
            IniPath := ""
            this.ini     := this.sbdir . "\Sandboxie.ini"
            if (!FileExist(this.ini))
            {
                this.ini := A_WinDir . "\Sandboxie.ini"
                if (!FileExist(this.ini))
                {
                    MsgBox(16, this.title, "Can't find Sandboxie.ini.")
                    ExitApp
                }
            }
        }
        this.sandboxes_path := IniRead(this.ini, "GlobalSettings", "FileRootPath", A_WinDir . "\Sandbox\`%USER`%\`%SANDBOX`%")
        this.sandboxes_path := expandEnvVars(this.sandboxes_path)
        this.sandboxes_array := this.getSandboxesArray(this.ini)
        }
        catch e
        {
            MsgBox("A critical error occurred during script initialization: `n" . e.Message, "SandboxToys Error", 16)
            ExitApp()
        }
    }

    static getSandboxByName(name)
    {
        for _, sandbox in this.sandboxes_array
        {
            if (sandbox.name == name)
                return sandbox
        }
        return ""
    }

    static getSandboxesArray(ini)
    {
        local sandboxes_array := []
        local sandboxes_path := IniRead(ini, "GlobalSettings", "FileRootPath", A_WinDir . "\Sandbox\`%USER`%\`%SANDBOX`%")
        local sandboxeskey_path := IniRead(ini, "GlobalSettings", "KeyRootPath", "\REGISTRY\USER\Sandbox_`%USER`%_`%SANDBOX`%")

        local old_encoding := A_FileEncoding
        FileEncoding("UTF-16")

        local sections := ""
        try sections := FileRead(ini)
        local boxes := []
        for _, section in StrSplit(sections, "`n")
        {
            if (RegExMatch(section, "\[([^\]]+)\]", &m) && m[1] != "GlobalSettings" && !InStr(m[1], "UserSettings_") && !InStr(m[1], "Template"))
            {
                boxes.Push(m[1])
            }
        }
        boxes.Sort("CL")
        FileEncoding(old_encoding)

        for _, boxName in boxes
        {
            local bfilerootpath := IniRead(ini, boxName, "FileRootPath", sandboxes_path)
            local bkeyrootpath := IniRead(ini, boxName, "KeyRootPath", sandboxeskey_path)

            local dropAdminRights := IniRead(ini, boxName, "DropAdminRights", "n") == "y"
            local enabled := IniRead(ini, boxName, "Enabled", "y") == "y"
            local neverDelete := IniRead(ini, boxName, "NeverDelete", "n") == "y"
            local useFileImage := IniRead(ini, boxName, "UseFileImage", "n") == "y"
            local useRamDisk := IniRead(ini, boxName, "UseRamDisk", "n") == "y"

            sandboxes_array.Push(Sandbox(boxName, bfilerootpath, bkeyrootpath, dropAdminRights, enabled, neverDelete, useFileImage, useRamDisk))
        }
        return sandboxes_array
    }
}

; Manages user-configurable settings stored in the script's INI file.
class Settings
{
    static sbtini, regconfig, ignorelist, usertoolsdir
    static smalliconsize, largeiconsize, seperatedstartmenus, includeboxnames, listemptyitems
    static trayiconfile, trayiconnumber, sbcommandpromptdir

    static load()
    {
        this.smalliconsize       := 16
        this.largeiconsize       := 32
        this.seperatedstartmenus := 0
        this.includeboxnames     := 1
        this.listemptyitems      := 0
        this.trayiconfile        := ""
        this.trayiconnumber      := 1
        this.sbcommandpromptdir  := A_UserProfile

        local inidir := A_ScriptDir
        this.sbtini       := inidir . "\" . Globals.nameNoExt . ".ini"
        this.regconfig    := inidir . "\" . Globals.nameNoExt . "_RegConfig.cfg"
        this.ignorelist   := inidir . "\" . Globals.nameNoExt . "_Ignore_"
        this.usertoolsdir := inidir . "\" . Globals.nameNoExt . "_UserTools"

        if (!FileExist(this.sbtini))
        {
            inidir := A_AppData . "\SandboxToys2"
            this.sbtini       := inidir . "\" . Globals.nameNoExt . ".ini"
            this.regconfig    := inidir . "\" . Globals.nameNoExt . "_RegConfig.cfg"
            this.ignorelist   := inidir . "\" . Globals.nameNoExt . "_Ignore_"
            this.usertoolsdir := inidir . "\" . Globals.nameNoExt . "_UserTools"
            if (!DirExist(inidir))
                DirCreate(inidir)
        }

        if (!DirExist(this.usertoolsdir))
            DirCreate(this.usertoolsdir)

        if (FileExist(this.sbtini))
        {
            try {
                this.largeiconsize       := IniRead(this.sbtini, "AutoConfig", "LargeIconSize", this.largeiconsize)
                this.smalliconsize       := IniRead(this.sbtini, "AutoConfig", "SmallIconSize", this.smalliconsize)
                this.seperatedstartmenus := IniRead(this.sbtini, "AutoConfig", "SeperatedStartMenus", this.seperatedstartmenus)
                this.includeboxnames     := IniRead(this.sbtini, "AutoConfig", "IncludeBoxNames", this.includeboxnames)
                this.listemptyitems      := IniRead(this.sbtini, "AutoConfig", "ListEmptyItems", this.listemptyitems)
                this.trayiconfile        := IniRead(this.sbtini, "UserConfig", "TrayIconFile", this.trayiconfile)
                this.trayiconnumber      := IniRead(this.sbtini, "UserConfig", "TrayIconNumber", this.trayiconnumber)
                this.sbcommandpromptdir  := IniRead(this.sbtini, "UserConfig", "SandboxedCommandPromptDir", this.sbcommandpromptdir)
            }
            catch {
                MsgBox("Error reading settings from " . this.sbtini . ". Using default values.", Globals.title, 48)
            }
        }
        else
        {
            this.save()
        }

        if (this.trayiconfile == "ERROR")
            this.trayiconfile := ""

        if (!A_IsCompiled && this.trayiconfile == "")
        {
            local tmp := A_ScriptDir . "\SandboxToys2.ico"
            if (FileExist(tmp))
                this.trayiconfile := tmp
            tmp := A_ScriptDir . "\" . Globals.nameNoExt . ".ico"
            if (FileExist(tmp))
                this.trayiconfile := tmp
        }
    }

    static save()
    {
        IniWrite(this.largeiconsize, this.sbtini, "AutoConfig", "LargeIconSize")
        IniWrite(this.smalliconsize, this.sbtini, "AutoConfig", "SmallIconSize")
        IniWrite(this.seperatedstartmenus, this.sbtini, "AutoConfig", "SeperatedStartMenus")
        IniWrite(this.includeboxnames, this.sbtini, "AutoConfig", "IncludeBoxNames")
        IniWrite(this.listemptyitems, this.sbtini, "AutoConfig", "ListEmptyItems")
        IniWrite(this.trayiconfile, this.sbtini, "UserConfig", "TrayIconFile")
        IniWrite(this.trayiconnumber, this.sbtini, "UserConfig", "TrayIconNumber")
        IniWrite(this.sbcommandpromptdir, this.sbtini, "UserConfig", "SandboxedCommandPromptDir")
    }
}

; Manages the creation and event handling for the script's GUI windows,
; primarily the ListView for displaying files, registry keys, and autostart programs.
class GuiManager
{
    ; Creates and displays a generic ListView GUI for showing files or registry keys.
    ; It dynamically builds the menus and event handlers for the window.
    static ListGUI(title, box, type, data)
    {
        local fileMenu := Menu()
        local editMenu := Menu()
        local lvMenuBar := Menu()
        local popupMenu := Menu()

        MyListViewHandler(ctrl, gui_event, event_info, *)
        {
            if (gui_event == "RightClick")
            {
                popupMenu.Show()
            }
            else if (gui_event == "DoubleClick")
            {
                LV_GetText(item, event_info)
                if (type == "files")
                    Run(item)
                else
                    MsgBox("Double-clicking registry keys is not supported.")
            }
        }

        CloseListGui(*)
        {
            IgnoreManager.SaveNewIgnoredItems(type)
            Gui, ListGui:Destroy
        }

        ToggleAllCheckmarks(*)
        {
            local total := LV_GetCount()
            local checked_count := 0
            Loop total {
                if LV_GetNext(A_Index - 1, "C")
                    checked_count++
            }

            local action := (checked_count == total) ? "-Check" : "+Check"
            Loop total
                LV_Modify(A_Index, action)
        }

        ToggleSelected(*)
        {
            local row := 0
            while row := LV_GetNext(row, "S")
                LV_Modify(row, "ToggleCheck")
        }

        ToggleCurrent(*)
        {
            local focused_row := LV_GetNext(0, "F")
            if (focused_row)
                LV_Modify(focused_row, "ToggleCheck")
        }

        LVIgnoreEntry(mode)
        {
            local row := LV_GetNext(0, "F")
            if (!row) return

            local relativePath, name
            LV_GetText(&relativePath, row, 5) ; The hidden relative path column

            if (mode == "files" || mode == "values") {
                LV_GetText(&name, row, (mode == "files" ? 2 : 4))
                IgnoreManager.AddIgnoreItem(mode, relativePath . "\" . name)
            } else { ; dirs or keys
                IgnoreManager.AddIgnoreItem(mode, relativePath)
            }

            LV_Delete(row)
        }

        numOfCheckedFiles()
        {
            local num := 0, row := 0
            while row := LV_GetNext(row, "Checked")
                num++
            return num
        }

        FilesSaveTo(*)
        {
            if (numOfCheckedFiles() == 0) {
                SoundBeep()
                return
            }

            try {
                static DefaultFolder := A_Desktop
                local dirname := FileSelect("D", DefaultFolder, "Copy checkmarked files to folder...")
                if (dirname == "") return
                DefaultFolder := dirname

                local row := 0
                while row := LV_GetNext(row, "Checked")
                {
                    LV_GetText(filePath, row, 1)
                    FileCopy(filePath, dirname . "\" . SubStr(filePath, InStr(filePath, "\",,0)+1), true)
                }
            }
            catch e
            {
                MsgBox("An error occurred while copying files: `n" . e.Message, Globals.title, 16)
            }
        }

        CurrentFileRun(*)
        {
            local row := LV_GetNext(0, "F")
            if (!row) return
            LV_GetText(filePath, row, 1)
            executeShortcut(box, filePath)
        }

        HideSelected(*)
        {
            local row := 0, Srows := []
            while row := LV_GetNext(row, "S")
                Srows.Push(row)

            Loop Srows.Length
                LV_Delete(Srows[Srows.Length - A_Index + 1])
        }

        CurrentFileSaveTo(*)
        {
            local row := LV_GetNext(0, "F")
            if (!row) return

            LV_GetText(&filePath, row, 1)
            LV_GetText(&fileName, row, 2)
            static DefaultFolder := A_Desktop
            local filename := FileSelect("S16", DefaultFolder . "\" . fileName, "Copy file to...")
            if (filename == "") return

            FileCopy(filePath, filename, true)
            SplitPath(filename, , &DefaultFolder)
        }

        OpenContainer(sandboxed)
        {
            local row := LV_GetNext(0, "F")
            if (!row) return

            LV_GetText(&filePath, row, 1)
            SplitPath(filePath, , &dir)
            if (sandboxed)
                Run(Globals.start . " /box:" . box . " """ . dir . """")
            else
                Run(dir)
        }

        RegistrySaveAsReg(*)
        {
            if (numOfCheckedFiles() == 0) { SoundBeep(); return }
            try {
                static DefaultFolder := A_Desktop
                local filename := FileSelect("S16", DefaultFolder . "\box " . box . ".reg", "Save checkmarked as REG file", "*.reg")
                if (filename == "") return
                SplitPath(filename, , &DefaultFolder)

                local run_pid := InitializeBox(box)
                if (run_pid == 0) throw Error("Failed to initialize sandbox for registry export.")

                local out := "REGEDIT4`n"
                local row := 0
                while row := LV_GetNext(row, "Checked")
                {
                    LV_GetText(&key, row, 1)
                    LV_GetText(&type, row, 2)
                    LV_GetText(&valName, row, 4)
                    LV_GetText(&valData, row, 5)

                    if (A_Index == 1)
                        out .= "`n[" . key . "]`n"

                    if valName == "@"
                        out .= "@="
                    else
                        out .= """" . valName . """="

                    if type == "REG_SZ"
                        out .= """" . valData . """`n"
                    else if type == "REG_DWORD"
                        out .= "dword:" . dec2hex(valData, 8) . "`n"
                    ; TODO: Add other REG types
                }
                ReleaseBox(run_pid)
                FileDelete(filename)
                FileAppend(out, filename)
            }
            catch e
            {
                MsgBox("An error occurred while saving the REG file: `n" . e.Message, Globals.title, 16)
            }
        }

        CurrentCopyToClipboard(*)
        {
            local row := LV_GetNext(0, "F")
            if (!row) return
            LV_GetText(&key, row, 1)
            A_Clipboard := key
        }

        CurrentOpenRegEdit(*)
        {
            local row := LV_GetNext(0, "F")
            if (!row) return
            LV_GetText(&key, row, 1)

            local run_pid := InitializeBox(box)
            try RegWrite(key, "REG_SZ", "HKEY_CURRENT_USER\Software\Microsoft\Windows\CurrentVersion\Applets\Regedit", "LastKey")
            RunWait(Globals.regeditImg)
            ReleaseBox(run_pid)
        }

        FilesToStartMenuOrDesktop(where)
        {
            if (numOfCheckedFiles() == 0) { SoundBeep(); return }
            local row := 0
            while row := LV_GetNext(row, "Checked")
                CurrentFileToStartMenuOrDesktop(row, where)
        }

        CurrentFileToStartMenuOrDesktop(row, where)
        {
            if (!row) row := LV_GetNext(0, "F")
            if (!row) return

            LV_GetText(&filePath, row, 1)
            SplitPath(filePath, &fileName, &dir)
            SplitPath(fileName, &fileNameNoExt)

            local sandbox := getSandboxByName(box)
            local shortcutPath := (where == "startmenu") ? sandbox.bpath . "\user\current\AppData\Roaming\Microsoft\Windows\Start Menu" : sandbox.bpath . "\user\current\Desktop"
            local shortcutFile := shortcutPath . "\" . fileNameNoExt . ".lnk"

            try DirCreate(shortcutPath)
            FileCreateShortcut(filePath, shortcutFile, dir, "", "Shortcut created by SandboxToys2")
        }

        FilesShortcut(*)
        {
            if (numOfCheckedFiles() == 0) { SoundBeep(); return }
            local row := 0
            while row := LV_GetNext(row, "Checked")
                CurrentFileShortcut(row)
        }

        CurrentFileShortcut(row)
        {
            if (!row) row := LV_GetNext(0, "F")
            if (!row) return
            LV_GetText(&filePath, row, 1)
            createDesktopShortcutFromLnk(box, filePath, "", 1) ; Simplified icon logic
        }

        SaveAsText(*)
        {
            if (numOfCheckedFiles() == 0) { SoundBeep(); return }
            local defaultfilename := (type == "files") ? "Files in sandbox " . box . ".txt" : "Registry of sandbox " . box . ".txt"
            local filename := FileSelect("S16", A_Desktop . "\" . defaultfilename, "Save Checkmarked as CSV Text", "Text files (*.txt)")
            if (filename == "") return

            local csv_data := ""
            local row := 0
            while row := LV_GetNext(row, "Checked")
            {
                local line := ""
                Loop LV_GetCount("Column")
                {
                    LV_GetText(&col_text, row, A_Index)
                    line .= """" . col_text . ""","
                }
                csv_data .= RTrim(line, ",") . "`r`n"
            }
            FileDelete(filename)
            FileAppend(csv_data, filename)
        }

        if (type == "files")
        {
            fileMenu.Add("&Copy Checkmarked Files To...", FilesSaveTo)
            fileMenu.Add("Save Checkmarked Entries as CSV &Text", SaveAsText)
            fileMenu.Add()
            fileMenu.Add("Add Shortcuts to Checkmarked Files to Sandboxed Start &Menu", FilesToStartMenuOrDesktop.Bind("startmenu"))
            fileMenu.Add("Add Shortcuts to Checkmarked Files to Sandboxed &Desktop", FilesToStartMenuOrDesktop.Bind("desktop"))
            fileMenu.Add("Create Sandboxed &Shortcuts to Checkmarked Files on your Real Desktop", FilesShortcut)
            editMenu.Add("Add Selected &Files to Ignore List", LVIgnoreEntry.Bind("files"))
            editMenu.Add("Add Selected &Dirs to Ignore List", LVIgnoreEntry.Bind("dirs"))

            popupMenu.Add("Copy To...", CurrentFileSaveTo)
            popupMenu.Add("Open in Sandbox", CurrentFileRun)
            popupMenu.Add()
            popupMenu.Add("Add File to Ignore List", LVIgnoreEntry.Bind("files"))
            popupMenu.Add("Add Folder to Ignore List", LVIgnoreEntry.Bind("dirs"))
        }
        else ; type == "reg"
        {
            fileMenu.Add("Save Checkmarked entries as &REG file", (*) => MsgBox("Not implemented"))
            editMenu.Add("Add Selected &Values to Ignore List", LVIgnoreEntry.Bind("values"))
            editMenu.Add("Add Selected &Keys to Ignore List", LVIgnoreEntry.Bind("keys"))

            popupMenu.Add("Copy Key to Clipboard", (*) => MsgBox("Not implemented"))
            popupMenu.Add("Toggle Checkmark", ToggleCurrent)
            popupMenu.Add()
            popupMenu.Add("Add Value to Ignore List", LVIgnoreEntry.Bind("values"))
            popupMenu.Add("Add Key to Ignore List", LVIgnoreEntry.Bind("keys"))
        }

        editMenu.Add("&Clear All Checkmarks", GuiManager.ClearAllCheckmarks.Bind(MyListView))
        editMenu.Add("&Toggle All Checkmarks", ToggleAllCheckmarks)
        editMenu.Add("Toggle &Selected Checkmarks", ToggleSelected)
        editMenu.Add()
        editMenu.Add("&Hide Selected Entries", (*) => MsgBox("Not implemented"))

        lvMenuBar.Add("&File", fileMenu)
        lvMenuBar.Add("&Edit", editMenu)

        Gui, ListGui:New, +Resize, % Globals.title . " - " . title . " - " . box
        Gui, ListGui:Font, "s10", "Verdana"
        Gui, ListGui:SetMenu(lvMenuBar)
        Gui, ListGui:Add, "ListView", "w780 h500 vMyListView gMyListViewHandler", ["Path", "Type", "Size", "Modified", "RelativePath"]
        LV_ModifyCol(5, 0) ; Hidden column
        LV_ModifyCol(1, 400)
        LV_ModifyCol(2, 70)
        LV_ModifyCol(3, 70, "Integer")
        LV_ModifyCol(4, 140)

        if (type == "files")
        {
            for _, item in data
            {
                LV_Add("", item.path, item.type, item.size, item.modified, item.relativePath)
            }
        }
        else if (type == "reg")
        {
            for _, item in data
            {
                LV_Add("", item.key, item.type, item.size, item.modified, item.relativePath)
            }
        }

        Gui, ListGui:Add, Button, gExportListGui x10 y510 w100, Export List
        Gui, ListGui:Add, Button, gCloseListGui x120 y510 w100, Close
        Gui, ListGui:Show
        return

    MyListViewHandler(ctrl, gui_event, event_info)
    {
        static popupMenu := "" ; This will be set by ListGUI
        if (gui_event == "RightClick")
        {
            popupMenu.Show()
        }
        else if (gui_event == "DoubleClick")
        {
            LV_GetText(item, event_info)
            if (GuiManager.ListGUI.type == "files") ; Need to access type...
                Run(item)
            else
                MsgBox("Double-clicking registry keys is not supported.")
        }
        return
    }

    ExportListGui:
        ; ... export logic ...
        MsgBox("Export not implemented yet.")
        return

    CloseListGui:
    ListGui_Close:
        Gui, ListGui:Destroy
        return
    }

    static ClearAllCheckmarks(ctrl)
    {
        Loop ctrl.GetCount()
            ctrl.Modify(A_Index, "-Check")
    }

    static ShowAutostartsList(box, autostartList)
    {
        Gui, AutostartGui:New, +Resize, % Globals.title . " - Autostart Programs - " . box
        Gui, AutostartGui:Font, s10, Verdana
        Gui, AutostartGui:Add, ListView, w780 h500 vMyAutostartListView gMyAutostartListView Checked, Program|Command|Location
        LV_ModifyCol(1, 200)
        LV_ModifyCol(2, 400)
        LV_ModifyCol(3, 150)

        for item in autostartList
        {
            local options := item.ticked ? "Check" : ""
            LV_Add(options, item.name, item.command, item.location)
        }

        Gui, AutostartGui:Add, Button, gCloseAutostartGui x10 y510 w100, Close
        Gui, AutostartGui:Show
        return

    MyAutostartListView:
        ; Placeholder for event handling
        return

    CloseAutostartGui:
    AutostartGui_Close:
        Gui, AutostartGui:Destroy
        return
    }
}

; Manages the automation of Process Monitor (ProcMon.exe) for tracing application dependencies.
class ProcMonManager
{
    static procmon_path := ""

    static CheckExists()
    {
        if (this.procmon_path != "" && FileExist(this.procmon_path))
            return true

        if FileExist(A_ScriptDir . "\ProcMon.exe") {
            this.procmon_path := A_ScriptDir . "\ProcMon.exe"
            return true
        }

        local stdout := ""
        if (RunWait(A_ComSpec . " /c where ProcMon.exe",, "Hide", &stdout) == 0)
        {
            this.procmon_path := Trim(stdout)
            if FileExist(this.procmon_path)
                return true
        }

        this.procmon_path := ""
        MsgBox("ProcMon.exe not found. Please place it in the script's directory or in your system's PATH.", Globals.title, 16)
        return false
    }

    static StartCapture(pml_file)
    {
        try {
            local args := "/Quiet /AcceptEula /BackingFile """ . pml_file . """"
            Run(this.procmon_path . " " . args)
            Sleep(2000) ; Give ProcMon time to start capturing
        } catch e {
            throw Error("Failed to start ProcMon: " . e.Message)
        }
    }

    static StopCapture(pml_file, csv_file)
    {
        try {
            RunWait(this.procmon_path . " /Terminate")
            Sleep(1000)

            local args := "/Quiet /OpenLog """ . pml_file . """ /SaveAs """ . csv_file . """"
            RunWait(this.procmon_path . " " . args)
        } catch e {
            throw Error("Failed to stop ProcMon or convert log: " . e.Message)
        }
    }
}

; Parses a CSV log file generated by ProcMon to find file and registry dependencies.
ParseProcMonLog(csv_file, process_name, sandbox_path)
{
    local filePaths := Map()
    local regPaths := Map()
    local result := Map("files", [], "reg", [])

    Loop Read, csv_file
    {
        if (A_Index <= 5) ; Skip ProcMon CSV header
            continue

        try {
            local row := StrSplit(A_LoopReadLine, ",",, 7)
            if row.Length < 6
                continue

            local procName := Trim(row[2], '"')
            local operation := Trim(row[4], '"')
            local path := Trim(row[5], '"')
            local res := Trim(row[6], '"')

            if (procName != process_name || res != "SUCCESS" || InStr(path, sandbox_path))
                continue

            if (operation == "CreateFile")
            {
                if (!filePaths.Has(path) && FileExist(path) && !InStr(FileExist(path), "D"))
                {
                    result.files.Push(path)
                    filePaths.Set(path, true)
                }
            }
            else if (operation == "RegOpenKey")
            {
                if (!regPaths.Has(path))
                {
                    result.reg.Push(path)
                    regPaths.Set(path, true)
                }
            }
        }
    }
    return result
}

; Copies a list of files from the host system into their correct virtualized
; locations within a specified sandbox.
CopyFilesToSandbox(boxName, fileList)
{
    local sandbox := Globals.getSandboxByName(boxName)
    if (!IsObject(sandbox))
        throw Error("Invalid sandbox name provided to CopyFilesToSandbox.")

    for _, sourcePath in fileList
    {
        try {
            local destPath := stdPathToBoxPath(boxName, sourcePath)
            SplitPath(destPath, , &destDir)
            DirCreate(destDir)
            FileCopy(sourcePath, destPath, true)
        }
        catch e
        {
            MsgBox("Failed to copy " . sourcePath . ".`nError: " . e.Message, Globals.title, 16)
        }
    }
}

; Exports a list of registry keys from the host system into a .reg file
; and then imports that file into the specified sandbox.
CopyRegistryKeysToSandbox(boxName, regKeyList)
{
    local tempRegFile := A_Temp . "\sbt_reg_import.reg"
    try FileDelete(tempRegFile)
    FileAppend("REGEDIT4`n`n", tempRegFile)

    for _, keyPath in regKeyList
    {
        local fullKeyPath := StrReplace(keyPath, "HKLM", "HKEY_LOCAL_MACHINE")
        fullKeyPath := StrReplace(fullKeyPath, "HKCU", "HKEY_CURRENT_USER")
        fullKeyPath := StrReplace(fullKeyPath, "HKCR", "HKEY_CLASSES_ROOT")
        fullKeyPath := StrReplace(fullKeyPath, "HKU", "HKEY_USERS")

        local tempAppendFile := A_Temp . "\sbt_reg_append.reg"
        try {
            RunWait(A_ComSpec . " /c reg export """ . fullKeyPath . """ """ . tempAppendFile . """ /y", , "Hide")
            if FileExist(tempAppendFile)
            {
                local content := FileRead(tempAppendFile)
                content := SubStr(content, InStr(content, "[HKEY_"))
                FileAppend("`n" . content, tempRegFile)
                FileDelete(tempAppendFile)
            }
        }
    }

    try {
        local importCmd := Globals.start . " /box:" . boxName . " regedit.exe /s """ . tempRegFile . """"
        RunWait(importCmd)
    }
    catch e {
        MsgBox("Failed to import registry keys into sandbox: `n" . e.Message, Globals.title, 16)
    }

    try FileDelete(tempRegFile)
}

; Encapsulates all logic related to creating and managing file shortcuts.
class ShortcutManager
{
    static writeUnsandboxedShortcutFileToDesktop(target, name, dir, args, description, iconFile, iconNum, runState)
    {
        local linkFile := A_Desktop . "\" . name . ".lnk"
        if (FileExist(linkFile))
        {
            local result := MsgBox("Shortcut '" . name . "' already exists on your desktop!`n`nOverwrite it?", Globals.title, "4|IconQuestion")
            if (result == "No")
                return
        }
        FileCreateShortcut(target, linkFile, dir, args, description, iconFile, , iconNum, runState)
    }

    static writeSandboxedShortcutFileToDesktop(target, name, dir, args, description, iconFile, iconNum, runState, box)
    {
        if (Settings.includeboxnames)
        {
            if (box == "__ask__")
                name := "[#ask box] " . name
            else
                name := "[#" . box . "] " . name
        }
        else
            name := "[#] " . name

        local linkFile := A_Desktop . "\" . name . ".lnk"

        if (FileExist(linkFile))
        {
            local result := MsgBox("Shortcut '" . name . "' already exists on your desktop!`n`nOverwrite it?", Globals.title, "4|IconQuestion")
            if (result == "No")
                return
        }

        FileCreateShortcut(target, linkFile, dir, args, description, iconFile, , iconNum, runState)
    }

    static createDesktopShortcutFromLnk(box, shortcut, iconfile, iconnum)
    {
        local outTarget, outDir, outArgs, outDescription, outRunState, outNameNoExt, outExtension, file

        SplitPath(shortcut, &outNameNoExt, &outDir, &outExtension)

        if (box == "") {
            if (outExtension == "lnk") {
                local dest := A_Desktop . "\" . outNameNoExt . ".lnk"
                FileCopy(shortcut, dest, true)
            } else {
                this.writeUnsandboxedShortcutFileToDesktop(shortcut, outNameNoExt, outDir, "", "SandboxToys User Tool", "", "", 1)
            }
            return
        }

        if (outExtension == "lnk") {
            local sc := FileGetShortcut(shortcut)
            outTarget := sc.Target
            outDir := sc.Dir
            outArgs := sc.Args
            outDescription := sc.Desc
            outRunState := sc.RunState
            outArgs := "/box:" . box . " """ . outTarget . """ " . outArgs
            if (!outDir)
                outDir := boxPathToStdPath(box, outTarget)
            outDir := stdPathToBoxPath(box, outDir)
            outDescription := "Run '" . outNameNoExt . "' in sandbox " . box . ".`n" . outDescription
        } else {
            file := boxPathToStdPath(box, shortcut)
            outTarget := Globals.start
            outArgs := "/box:" . box . " """ . file . """"
            SplitPath(file, , &outDir)
            outDescription := "Run '" . outNameNoExt . "' in sandbox " . box . "."
            outRunState := 1
        }

        local iconNumToUse := iconnum == 0 ? 1 : iconnum
        this.writeSandboxedShortcutFileToDesktop(outTarget, outNameNoExt, outDir, outArgs, outDescription, iconfile, iconNumToUse, outRunState, box)
    }

    static NewShortcut(box, file)
    {
        SplitPath(file, , &dir, &extension, &label)
        if (!FileExist(dir))
            dir := stdPathToBoxPath(box, dir)

        local iconfile, iconnum
        if (extension == "exe")
        {
            iconfile := file
            iconnum := 1
        }
        else
        {
            ; Simplified icon logic for now. A full port is a future task.
            iconfile := Globals.shell32
            iconnum := 2
        }

        local tip := (box == "__ask__") ? "Launch '" . label . "' in any sandbox" : "Launch '" . label . "' in sandbox " . box
        this.writeSandboxedShortcutFileToDesktop(Globals.start, label, dir, "/box:" . box . " """ . file . """", tip, iconfile, iconnum, 1, box)
    }
}
ListAutostartsMenuHandler(ItemName, ItemPos, MyMenu)
{
    local box := getBoxFromMenu()
    if (box == "") return

    local autostarts := ListAutostarts(box)
    if (autostarts.Length > 0)
        GuiManager.ShowAutostartsList(box, autostarts)
    else
        MsgBox("No autostart programs found in the registry of box '" . box . "'.", Globals.title, "64|IconInfo")
}

; Responsible for building the entire dynamic menu structure of the application.
; It scans sandbox folders and creates the main menu and all sub-menus.
class MenuManager
{
    __New()
    {
        this.menuCommands := Map()
        this.menuIcons := Map()
        this.menus := Map()
        this.mainMenu := Menu()
        this.menus["ST2MainMenu"] := this.mainMenu
        this.menunum := 0
    }

    getFilenames(directory, includeFolders)
    {
        local files := []
        Loop Files, directory . "\*", includeFolders ? "D" : ""
        {
            if (InStr(A_LoopFileAttrib, "H") || InStr(A_LoopFileAttrib, "S"))
                continue

            if (FileGetTime(A_LoopFileLongPath, "C") == "19860523174702")
                continue

            local label := A_LoopFileIsDir ? A_LoopFileName : A_LoopFileName.SubString(1, InStr(A_LoopFileName, ".",, -1) -1)
            files.Push(label . ":" . A_LoopFileLongPath)
        }
        files.Sort("CL")
        return files
    }

    addCmdsToMenu(box, menuObj, fileslist)
    {
        for _, entry in fileslist
        {
            if (entry == "") continue
            local parts := StrSplit(entry, ":",, 2)
            local label := parts[1]
            local exefile := parts[2]

            if (this.menuCommands.Has(menuObj.Name . "," . label))
                label .= " (2)"

            local handler := (box == "") ? RunUserToolMenuHandler : this.RunProgramMenuHandler.Bind(this)
            menuObj.Add(label, handler)
            setIconFromSandboxedShortcut(box, exefile, menuObj, label, Settings.smalliconsize)
            this.menuCommands.Set(menuObj.Name . "," . label, exefile)
        }
        return fileslist.Length
    }

    buildProgramsMenu1(box, menuname, bpath)
    {
        local thismenuname := this.menunum > 0 ? menuname . "_" . this.menunum : menuname
        this.menus[box . "_" . thismenuname] := Menu()

        local numfiles := 0
        local menufiles := this.getFilenames(bpath, false)
        if (menufiles.Length > 0) {
            numfiles := this.addCmdsToMenu(box, this.menus[box . "_" . thismenuname], menufiles)
        }

        local menudirs := this.getFilenames(bpath, true)
        if (menudirs.Length > 0) {
            if (numfiles > 0) this.menus[box . "_" . thismenuname].Add()
            for _, entry in menudirs
            {
                local parts := StrSplit(entry, ":",, 2)
                local label := parts[1]
                local dir := parts[2]
                this.menunum++
                local newmenuname := this.buildProgramsMenu1(box, menuname, dir)
                if (newmenuname != "") {
                    this.menus[box . "_" . thismenuname].Add(label, this.menus[box . "_" . newmenuname])
                    setMenuIcon(this.menus[box . "_" . thismenuname], label, Globals.shell32, 4, Settings.smalliconsize)
                    numfiles++
                }
            }
        }
        return numfiles ? thismenuname : ""
    }

    buildProgramsMenu2(box, menuname, path1, path2)
    {
        local thismenuname := this.menunum > 0 ? menuname . "_" . this.menunum : menuname
        this.menus[box . "_" . thismenuname] := Menu()

        local numfiles := 0
        local menufiles1 := this.getFilenames(path1, false)
        local menufiles2 := this.getFilenames(path2, false)
        local combinedFiles := menufiles1
        combinedFiles.Push(menufiles2*)
        combinedFiles.Sort("CL")

        if (combinedFiles.Length > 0) {
            numfiles := this.addCmdsToMenu(box, this.menus[box . "_" . thismenuname], combinedFiles)
        }

        local menudirs1 := this.getFilenames(path1, true)
        local menudirs2 := this.getFilenames(path2, true)
        local combinedDirs := menudirs1
        combinedDirs.Push(menudirs2*)
        combinedDirs.Sort("CL")

        if (combinedDirs.Length > 0) {
            if (numfiles > 0) this.menus[box . "_" . thismenuname].Add()
            // Simplified logic for merging directories. A full port of the v1 logic is very complex.
            // This version will create duplicate entries if a folder exists in both paths.
            for _, entry in combinedDirs
            {
                local parts := StrSplit(entry, ":",, 2)
                local label := parts[1]
                local dir := parts[2]
                this.menunum++
                local newmenuname := this.buildProgramsMenu1(box, menuname, dir)
                if (newmenuname != "") {
                    this.menus[box . "_" . thismenuname].Add(label, this.menus[box . "_" . newmenuname])
                    setMenuIcon(this.menus[box . "_" . thismenuname], label, Globals.shell32, 4, Settings.smalliconsize)
                    numfiles++
                }
            }
        }
        return numfiles ? thismenuname : ""
    }

    RunProgramMenuHandler(ItemName, ItemPos, MenuName)
    {
        local box := getBoxFromMenu()
        local shortcut := this.menuCommands.Get(MenuName . "," . ItemName)

        if (shortcut == "")
            return

        if GetKeyState("Control", "P") {
            ; TODO: Get icon info from a menuIcons map. For now, pass empty.
            ShortcutManager.createDesktopShortcutFromLnk(box, shortcut, "", "")
        } else if GetKeyState("Shift", "P") {
            SplitPath(shortcut, , &dir)
            Run(Globals.start . " /box:" . box . " """ . dir . """")
        } else {
            executeShortcut(box, shortcut)
        }
    }

    SetupMenuMenuHandler1(*)
    {
        Settings.largeiconsize := Settings.largeiconsize > 16 ? 16 : 32
        this.menus["SBMenuSetup"].ToggleCheck("Large main-menu and box icons?")
        Settings.save()
    }

    SetupMenuMenuHandler2(*)
    {
        Settings.smalliconsize := Settings.smalliconsize > 16 ? 16 : 32
        this.menus["SBMenuSetup"].ToggleCheck("Large sub-menu icons?")
        Settings.save()
    }

    SetupMenuMenuHandler3(*)
    {
        Settings.seperatedstartmenus := !Settings.seperatedstartmenus
        this.menus["SBMenuSetup"].ToggleCheck("Seperated All Users menus?")
        Settings.save()
    }

    SetupMenuMenuHandler4(*)
    {
        Settings.includeboxnames := !Settings.includeboxnames
        this.menus["SBMenuSetup"].ToggleCheck("Include [#BoxName] in shortcut names?")
        Settings.save()
    }

    SetupMenuMenuHandler5(*)
    {
        Settings.listemptyitems := !Settings.listemptyitems
        this.menus["SBMenuSetup"].ToggleCheck("List empty folders and keys?")
        Settings.save()
    }

    BuildMainMenu(traymode, singleboxmode, singlebox)
    {
        ; This is the main method for constructing the entire menu structure.
        ; It iterates through all available sandboxes and builds a nested menu
        ; for each one, including Start Menu, Desktop, and Tools sub-menus.
        local box, boxpath, boxexist, dropadminrights, benabled, boxlabel
        local public, added_menus, public_dir, idx, tmp1, topicons, numtopicons, files1, menunum, numicons, m, files2

        if (traymode)
        {
            Globals.sandboxes_array := getSandboxesArray(Globals.ini)
        }

        this.menus["ST2MainMenu"] := Menu()
        this.menus["ST2MainMenu"].Name := "ST2MainMenu"

        local numboxes := Globals.sandboxes_array.Length
        if (numboxes == 1)
        {
            singleboxmode := 1
            for _, sandbox in Globals.sandboxes_array
            {
                singlebox := sandbox.name
                break
            }
        }

        for _, sandbox in Globals.sandboxes_array
        {
            box := sandbox.name
            boxpath         := sandbox.bpath
            boxexist        := sandbox.exist
            dropadminrights := sandbox.DropAdminRights
            benabled        := sandbox.Enabled
            if (!benabled)
            {
                Continue
            }

            if (boxexist)
                boxlabel := box
            else
                boxlabel := box . " (empty)"

            if (singleboxmode && box != singlebox)
                continue

            this.menus[box . "_ST2MenuBox"]       := Menu()
            this.menus[box . "_ST2MenuBox"].Name  := box . "_ST2MenuBox"
            this.menus[box . "_ST2StartMenu"]     := Menu()
            this.menus[box . "_ST2StartMenu"].Name := box . "_ST2StartMenu"
            this.menus[box . "_ST2StartMenuAU"]   := Menu()
            this.menus[box . "_ST2StartMenuAU"].Name := box . "_ST2StartMenuAU"
            this.menus[box . "_ST2StartMenuCU"]   := Menu()
            this.menus[box . "_ST2StartMenuCU"].Name := box . "_ST2StartMenuCU"
            this.menus[box . "_ST2Desktop"]       := Menu()
            this.menus[box . "_ST2Desktop"].Name  := box . "_ST2Desktop"
            this.menus[box . "_ST2QuickLaunch"]   := Menu()
            this.menus[box . "_ST2QuickLaunch"].Name := box . "_ST2QuickLaunch"
            this.menus[box . "_ST2MenuExplore"]   := Menu()
            this.menus[box . "_ST2MenuExplore"].Name := box . "_ST2MenuExplore"
            this.menus[box . "_ST2MenuReg"]       := Menu()
            this.menus[box . "_ST2MenuReg"].Name  := box . "_ST2MenuReg"
            this.menus[box . "_ST2MenuTools"]     := Menu()
            this.menus[box . "_ST2MenuTools"].Name := box . "_ST2MenuTools"
            this.menus["SBMenuSetup"]         := Menu()
            this.menus["SBMenuSetup"].Name    := "SBMenuSetup"

            if (singleboxmode)
            {
                this.menus[singlebox . "_ST2MenuBox"].Add("Box " . boxlabel, DummyMenuHandler)
                this.menus[singlebox . "_ST2MenuBox"].Disable("Box " . boxlabel)
                if (boxexist)
                    setMenuIcon(this.menus[singlebox . "_ST2MenuBox"], "Box " . boxlabel, Globals.SbieAgentResFull, Globals.SbieAgentResFullId, Settings.smalliconsize)
                else
                    setMenuIcon(this.menus[singlebox . "_ST2MenuBox"], "Box " . boxlabel, Globals.SbieAgentResEmpty, Globals.SbieAgentResEmptyId, Settings.smalliconsize)
                this.menus[singlebox . "_ST2MenuBox"].Add()
            }

            added_menus := 0
            if (boxexist)
            {
                public_dir := A_AllUsersProfile
                if (public_dir != "")
                {
                    idx := InStr(public_dir, ":")
                    if (idx)
                        public_dir := substr(public_dir, 1, idx - 1) . substr(public_dir, idx + 1)
                }
                if (Settings.seperatedstartmenus)
                {
                    tmp1         := boxpath . "\user\all\Microsoft\Windows\Start Menu"
                    topicons_arr := this.getFilenames(tmp1, 0)
                    if (topicons_arr.Length > 0)
                    {
                        this.addCmdsToMenu(box, this.menus[box . "_ST2StartMenuAU"], topicons_arr)
                        this.menus[box . "_ST2MenuBox"].Add("Start Menu (all users)", this.menus[box . "_ST2StartMenuAU"])
                        setMenuIcon(this.menus[box . "_ST2MenuBox"], "Start Menu (all users)", Globals.shell32, 20, Settings.largeiconsize)
                        added_menus := 1
                    }
                    tmp1       := boxpath . "\user\all\Microsoft\Windows\Start Menu\Programs"
                    files1_arr := this.getFilenames(tmp1, 1)
                    if (files1_arr.Length > 0 && topicons_arr.Length > 0)
                        this.menus[box . "_ST2StartMenuAU"].Add()
                    this.menunum  := 0
                    local numicons := this.buildProgramsMenu1(box, "ST2StartMenuAU", tmp1)
                    if (numicons)
                        added_menus := 1
                    if (topicons_arr.Length == 0 && numicons > 0)
                    {
                        this.menus[box . "_ST2MenuBox"].Add("Start Menu (all users)", this.menus[box . "_ST2StartMenuAU"])
                        setMenuIcon(this.menus[box . "_ST2MenuBox"], "Start Menu (all users)", Globals.shell32, 20, Settings.largeiconsize)
                    }
                    tmp1         := boxpath . "\user\current\AppData\Roaming\Microsoft\Windows\Start Menu"
                    topicons_arr := this.getFilenames(tmp1, 0)
                    if (topicons_arr.Length > 0)
                    {
                        this.addCmdsToMenu(box, this.menus[box . "_ST2StartMenuCU"], topicons_arr)
                        this.menus[box . "_ST2MenuBox"].Add("Start Menu (current user)", this.menus[box . "_ST2StartMenuCU"])
                        setMenuIcon(this.menus[box . "_ST2MenuBox"], "Start Menu (current user)", Globals.shell32, 20, Settings.largeiconsize)
                        added_menus := 1
                    }
                    tmp1       := boxpath . "\user\current\AppData\Roaming\Microsoft\Windows\Start Menu\Programs"
                    files1_arr := this.getFilenames(tmp1, 1)
                    if (files1_arr.Length > 0 && topicons_arr.Length > 0)
                        this.menus[box . "_ST2StartMenuCU"].Add()
                    this.menunum  := 0
                    numicons := this.buildProgramsMenu1(box, "ST2StartMenuCU", tmp1)
                    if (numicons)
                        added_menus := 1
                    if (topicons_arr.Length == 0 && numicons > 0)
                    {
                        this.menus[box . "_ST2MenuBox"].Add("Start Menu (current user)", this.menus[box . "_ST2StartMenuCU"])
                        setMenuIcon(this.menus[box . "_ST2MenuBox"], "Start Menu (current user)", Globals.shell32, 20, Settings.largeiconsize)
                    }
                    tmp1    := boxpath . "\drive\" . public_dir . "\Desktop"
                    this.menunum := 0
                    local m       := this.buildProgramsMenu1(box, "ST2DesktopAU", tmp1)
                    if (m)
                    {
                        added_menus := 1
                        this.menus[box . "_ST2MenuBox"].Add("Desktop (all users)", this.menus[box . "_" . m])
                        setMenuIcon(this.menus[box . "_ST2MenuBox"], "Desktop (all users)", Globals.shell32, 35, Settings.largeiconsize)
                    }
                    tmp1    := boxpath . "\user\current\Desktop"
                    this.menunum := 0
                    m       := this.buildProgramsMenu1(box, "ST2DesktopCU", tmp1)
                    if (m)
                    {
                        added_menus := 1
                        this.menus[box . "_ST2MenuBox"].Add("Desktop (current user)", this.menus[box . "_" . m])
                        setMenuIcon(this.menus[box . "_ST2MenuBox"], "Desktop (current user)", Globals.shell32, 35, Settings.largeiconsize)
                    }
                }
                else
                {
                    tmp1          := boxpath . "\user\all\Microsoft\Windows\Start Menu"
                    files1_arr    := this.getFilenames(tmp1, 0)
                    tmp2          := boxpath . "\user\current\AppData\Roaming\Microsoft\Windows\Start Menu"
                    files2_arr    := this.getFilenames(tmp2, 0)
                    local topicons_arr := files1_arr
                    topicons_arr.Push(files2_arr*)
                    topicons_arr.Sort("CL")
                    if (topicons_arr.Length > 0)
                    {
                        this.addCmdsToMenu(box, this.menus[box . "_ST2StartMenu"], topicons_arr)
                        this.menus[box . "_ST2MenuBox"].Add("Start Menu", this.menus[box . "_ST2StartMenu"])
                        setMenuIcon(this.menus[box . "_ST2MenuBox"], "Start Menu", Globals.shell32, 20, Settings.largeiconsize)
                        added_menus := 1
                    }
                    tmp1       := boxpath . "\user\all\Microsoft\Windows\Start Menu\Programs"
                    files1_arr := this.getFilenames(tmp1, 1)
                    tmp2       := boxpath . "\user\current\AppData\Roaming\Microsoft\Windows\Start Menu\Programs"
                    files2_arr := this.getFilenames(tmp2, 1)
                    if ((files1_arr.Length > 0 || files2_arr.Length > 0) && topicons_arr.Length > 0)
                        this.menus[box . "_ST2StartMenu"].Add()
                    this.menunum  := 0
                    numicons := this.buildProgramsMenu2(box, "ST2StartMenu", tmp1, tmp2)
                    if (numicons)
                        added_menus := 1
                    if (topicons_arr.Length == 0 && numicons > 0)
                    {
                        this.menus[box . "_ST2MenuBox"].Add("Start Menu", this.menus[box . "_ST2StartMenu"])
                        setMenuIcon(this.menus[box . "_ST2MenuBox"], "Start Menu", Globals.shell32, 20, Settings.largeiconsize)
                    }
                    tmp1       := boxpath . "\drive\" . public_dir . "\Desktop"
                    files1_arr := this.getFilenames(tmp1, 1)
                    tmp2       := boxpath . "\user\current\Desktop"
                    files2_arr := this.getFilenames(tmp2, 1)
                    if ((files1_arr.Length > 0 || files2_arr.Length > 0) && topicons_arr.Length > 0)
                        this.menus[box . "_ST2MenuBox"].Add()
                    this.menunum := 0
                    m       := this.buildProgramsMenu2(box, "ST2Desktop", tmp1, tmp2)
                    if (m)
                    {
                        added_menus := 1
                        this.menus[box . "_ST2MenuBox"].Add("Desktop", this.menus[box . "_" . m])
                        setMenuIcon(this.menus[box . "_ST2MenuBox"], "Desktop", Globals.shell32, 35, Settings.largeiconsize)
                    }
                }
                tmp1    := boxpath . "\user\current\AppData\Roaming\Microsoft\Internet Explorer\Quick Launch"
                this.menunum := 0
                m       := this.buildProgramsMenu1(box, "ST2QuickLaunch", tmp1)
                if (m)
                {
                    added_menus := 1
                    this.menus[box . "_ST2MenuBox"].Add("QuickLaunch", this.menus[box . "_" . m])
                    setMenuIcon(this.menus[box . "_ST2MenuBox"], "QuickLaunch", Globals.shell32, 215, Settings.largeiconsize)
                }
                if (added_menus)
                    this.menus[box . "_ST2MenuBox"].Add()
            }
            this.menus[box . "_ST2MenuBox"].Add("Sandboxie's Start Menu", StartMenuMenuHandler)
            setMenuIcon(this.menus[box . "_ST2MenuBox"], "Sandboxie's Start Menu", Globals.SbieAgentResMain, Globals.SbieAgentResMainId, Settings.largeiconsize)
            this.menus[box . "_ST2MenuBox"].Add("Sandboxie's Run Dialog", RunDialogMenuHandler)
            setMenuIcon(this.menus[box . "_ST2MenuBox"], "Sandboxie's Run Dialog", Globals.SbieAgentResMain, Globals.SbieAgentResMainId, Settings.largeiconsize)
            this.menus[box . "_ST2MenuBox"].Add()
            if (NOT boxexist)
            {
                this.menus[box . "_ST2MenuBox"].Add("Explore (Sandboxed)", SExploreMenuHandler)
                setMenuIcon(this.menus[box . "_ST2MenuBox"], "Explore (Sandboxed)", Globals.explorerRes, 1, Settings.largeiconsize)
                this.menus[box . "_ST2MenuBox"].Add("New Sandboxed Shortcut", NewShortcutMenuHandler)
                setMenuIcon(this.menus[box . "_ST2MenuBox"], "New Sandboxed Shortcut", Globals.imageres, 155, Settings.largeiconsize)
            }
            if (boxexist)
            {
                this.BuildExploreMenu(this.menus[box . "_ST2MenuBox"], this.menus[box . "_ST2MenuExplore"])
                this.menus[box . "_ST2MenuReg"].Add("Registry Editor (unsandboxed)", URegEditMenuHandler)
                setMenuIcon(this.menus[box . "_ST2MenuReg"], "Registry Editor (unsandboxed)", Globals.regeditRes, 1, Settings.smalliconsize)
                if (NOT dropadminrights)
                {
                    this.menus[box . "_ST2MenuReg"].Add("Registry Editor (sandboxed)", SRegEditMenuHandler)
                    setMenuIcon(this.menus[box . "_ST2MenuReg"], "Registry Editor (sandboxed)", Globals.regeditRes, 1, Settings.smalliconsize)
                }
                this.menus[box . "_ST2MenuReg"].Add()
                this.menus[box . "_ST2MenuReg"].Add("Registry List and Export", ListRegMenuHandler)
                setMenuIcon(this.menus[box . "_ST2MenuReg"], "Registry List and Export", Globals.regeditRes, 3, Settings.smalliconsize)
                this.menus[box . "_ST2MenuReg"].Add("Watch Registry Changes", WatchRegMenuHandler)
                setMenuIcon(this.menus[box . "_ST2MenuReg"], "Watch Registry Changes", Globals.regeditRes, 3, Settings.smalliconsize)
                this.menus[box . "_ST2MenuBox"].Add("Registry", this.menus[box . "_ST2MenuReg"])
                setMenuIcon(this.menus[box . "_ST2MenuBox"], "Registry", Globals.regeditRes, 1, Settings.largeiconsize)
                this.menus[box . "_ST2MenuReg"].Add()
                this.menus[box . "_ST2MenuReg"].Add("Autostart programs in registry", ListAutostartsMenuHandler)
                setMenuIcon(this.menus[box . "_ST2MenuReg"], "Autostart programs in registry", Globals.regeditRes, 2, Settings.smalliconsize)
                this.menus[box . "_ST2MenuTools"].Add("New Sandboxed Shortcut", NewShortcutMenuHandler)
                setMenuIcon(this.menus[box . "_ST2MenuTools"], "New Sandboxed Shortcut", Globals.imageres, 155, Settings.smalliconsize)
                this.menus[box . "_ST2MenuTools"].Add("Portable Sandbox Creator", PortableSandboxCreatorMenuHandler)
                setMenuIcon(this.menus[box . "_ST2MenuTools"], "Portable Sandbox Creator", Globals.imageres, 118, Settings.smalliconsize)
                this.menus[box . "_ST2MenuTools"].Add()
                this.menus[box . "_ST2MenuTools"].Add("Watch Files and Registry Changes", WatchFilesRegMenuHandler)
                setMenuIcon(this.menus[box . "_ST2MenuTools"], "Watch Files and Registry Changes", Globals.shell32, 172, Settings.smalliconsize)
                this.menus[box . "_ST2MenuTools"].Add()
                this.menus[box . "_ST2MenuTools"].Add("Command Prompt (unsandboxed)", UCmdMenuHandler)
                setMenuIcon(this.menus[box . "_ST2MenuTools"], "Command Prompt (unsandboxed)", Globals.cmdRes, 1, Settings.smalliconsize)
                this.menus[box . "_ST2MenuTools"].Add("Command Prompt (sandboxed)", SCmdMenuHandler)
                setMenuIcon(this.menus[box . "_ST2MenuTools"], "Command Prompt (sandboxed)", Globals.cmdRes, 1, Settings.smalliconsize)
                if (NOT dropadminrights)
                {
                    this.menus[box . "_ST2MenuTools"].Add()
                    this.menus[box . "_ST2MenuTools"].Add("Programs and Features", UninstallMenuHandler)
                    setMenuIcon(this.menus[box . "_ST2MenuTools"], "Programs and Features", A_WinDir . "\system32\appmgr.dll", 1, Settings.smalliconsize)
                }
                this.menus[box . "_ST2MenuTools"].Add()
                this.menus[box . "_ST2MenuTools"].Add("Terminate Sandboxed Programs!", TerminateMenuHandler)
                setMenuIcon(this.menus[box . "_ST2MenuTools"], "Terminate Sandboxed Programs!", Globals.shell32, 220, Settings.smalliconsize)
                this.menus[box . "_ST2MenuTools"].Add("Delete Sandbox!", DeleteBoxMenuHandler)
                setMenuIcon(this.menus[box . "_ST2MenuTools"], "Delete Sandbox!", Globals.shell32, 132, Settings.smalliconsize)
                this.menus[box . "_ST2MenuBox"].Add("Tools", this.menus[box . "_ST2MenuTools"])
                setMenuIcon(this.menus[box . "_ST2MenuBox"], "Tools", Globals.shell32, 36, Settings.largeiconsize)
            }
            if (!singleboxmode)
            {
                this.menus["ST2MainMenu"].Add(boxlabel, this.menus[box . "_ST2MenuBox"])
                if (boxexist)
                    setMenuIcon(this.menus["ST2MainMenu"], boxlabel, Globals.SbieAgentResFull, Globals.SbieAgentResFullId, Settings.largeiconsize)
                else
                    setMenuIcon(this.menus["ST2MainMenu"], boxlabel, Globals.SbieAgentResEmpty, Globals.SbieAgentResEmptyId, Settings.largeiconsize)
            }
        }
        if (singleboxmode)
            mainmenu_obj := this.menus[singlebox . "_ST2MenuBox"]
        else
            mainmenu_obj := this.menus["ST2MainMenu"]
        this.menunum := 0
        m       := this.buildProgramsMenu1("", "ST2UserTools", Settings.usertoolsdir)
        if (m)
        {
            mainmenu_obj.Add()
            mainmenu_obj.Add("User Tools", this.menus["_" . m])
            setMenuIcon(mainmenu_obj, "User Tools", Globals.imageres, 118, Settings.largeiconsize)
        }
        if InStr(Globals.SbieAgent, "SandMan")
        {
            if !ProcessExist("SandMan.exe")
            {
                mainmenu_obj.Add()
                mainmenu_obj.Add("Launch " . Globals.SbieAgentResMainText, LaunchSbieAgentMenuHandler)
                setMenuIcon(mainmenu_obj, "Launch " . Globals.SbieAgentResMainText, Globals.SbieAgentResMain, Globals.SbieAgentResMainId, Settings.largeiconsize)
            }
        }
        if InStr(Globals.SbieAgent, "SbieCtrl")
        {
            if !ProcessExist("SbieCtrl.exe")
            {
                mainmenu_obj.Add()
                mainmenu_obj.Add("Launch " . Globals.SbieAgentResMainText, LaunchSbieAgentMenuHandler)
                setMenuIcon(mainmenu_obj, "Launch " . Globals.SbieAgentResMainText, Globals.SbieAgentResMain, Globals.SbieAgentResMainId, Settings.largeiconsize)
            }
        }
        this.menus["SBMenuSetup"].Add("About and Help", MainHelpMenuHandler)
        setMenuIcon(this.menus["SBMenuSetup"], "About and Help", Globals.shell32, 24, 16)
        this.menus["SBMenuSetup"].Add()
        this.menus["SBMenuSetup"].Add("Large main-menu and box icons?", this.SetupMenuMenuHandler1.Bind(this))
        if (Settings.largeiconsize > 16)
            this.menus["SBMenuSetup"].Check("Large main-menu and box icons?")
        this.menus["SBMenuSetup"].Add("Large sub-menu icons?", this.SetupMenuMenuHandler2.Bind(this))
        if (Settings.smalliconsize > 16)
            this.menus["SBMenuSetup"].Check("Large sub-menu icons?")
        this.menus["SBMenuSetup"].Add("Seperated All Users menus?", this.SetupMenuMenuHandler3.Bind(this))
        if (Settings.seperatedstartmenus)
            this.menus["SBMenuSetup"].Check("Seperated All Users menus?")
        this.menus["SBMenuSetup"].Add()
        this.menus["SBMenuSetup"].Add("Include [#BoxName] in shortcut names?", this.SetupMenuMenuHandler4.Bind(this))
        if (Settings.includeboxnames)
            this.menus["SBMenuSetup"].Check("Include [#BoxName] in shortcut names?")
        this.menus["SBMenuSetup"].Add()
        this.menus["SBMenuSetup"].Add("List empty folders and keys?", this.SetupMenuMenuHandler5.Bind(this))
        if (Settings.listemptyitems)
            this.menus["SBMenuSetup"].Check("List empty folders and keys?")
        mainmenu_obj.Add()
        mainmenu_obj.Add("Options", this.menus["SBMenuSetup"])
        setMenuIcon(mainmenu_obj, "Options", Globals.shell32, 24, 16)
        mainmenu_obj.Show()
    }

    BuildExploreMenu(boxMenu, exploreMenu)
    {
        exploreMenu.Add("Unsandboxed", UExploreMenuHandler)
        setMenuIcon(exploreMenu, "Unsandboxed", Globals.explorerRes, 1, Settings.smalliconsize)
        exploreMenu.Add("Unsandboxed, restricted", URExploreMenuHandler)
        setMenuIcon(exploreMenu, "Unsandboxed, restricted", Globals.explorerRes, 1, Settings.smalliconsize)
        exploreMenu.Add("Sandboxed", SExploreMenuHandler)
        setMenuIcon(exploreMenu, "Sandboxed", Globals.explorerRes, 1, Settings.smalliconsize)
        exploreMenu.Add()
        exploreMenu.Add("Files List and Export", ListFilesMenuHandler)
        setMenuIcon(exploreMenu, "Files List and Export", Globals.shell32, 172, Settings.smalliconsize)
        exploreMenu.Add("Watch Files Changes", WatchFilesMenuHandler)
        setMenuIcon(exploreMenu, "Watch Files Changes", Globals.shell32, 172, Settings.smalliconsize)

        boxMenu.Add("Explore", exploreMenu)
        setMenuIcon(boxMenu, "Explore", Globals.explorerRes, 1, Settings.largeiconsize)
    }
}

; ##############################################################################
; --- SCRIPT INITIALIZATION
; ##############################################################################
SetWorkingDir(A_ScriptDir)
Globals.init()
Settings.load()
A_nl     := "`n"
A_Quotes := """"

; ##############################################################################
; --- SCRIPT MAIN LOGIC
; ##############################################################################

global ignoredDirs := "", ignoredFiles := "", ignoredKeys := "", ignoredValues := ""
global newIgnored_dirs := "", newIgnored_files := "", newIgnored_keys := "", newIgnored_values := ""

; Command Line Parsing
traymode      := 0
singlebox     := ""
singleboxmode := 0
startupfile   := ""
if (A_Args.Length >= 1)
{
    mainarg := A_Args[1]
    if (SubStr(mainarg, 1, 5) == "/box:")
    {
        singlebox     := SubStr(mainarg, 6)
        singleboxmode := 1
        if (A_Args.Length >= 2)
            mainarg := A_Args[2]
        else
            mainarg := ""
    }

    if (mainarg == "/tray")
    {
        traymode := 1
    }
    else if (mainarg == "/makeregconfig")
    {
        err := 0
        if (singleboxmode == 0)
            err := 1
        if (err)
            MsgBox(16, Globals.title, "Required box argument missing.`nUsage to recreate the registry config file:`n" . Globals.nameNoExt . " /box:boxname /makeregconfig`nThe box MUST be empty!")
        else
            MakeRegConfig(singlebox)
        ExitApp
    }
    else
    {
        startupfile := mainarg
    }
}

; Handle startup file argument
if (startupfile != "")
{
    startupfile := A_Args[1]
    startupfile := Trim(startupfile, A_Quotes)
    if (!FileExist(startupfile))
    {
        CmdLineHelp()
        ExitApp
    }
    if (singleboxmode)
    {
        ShortcutManager.NewShortcut(singlebox, startupfile)
        ExitApp
    }
    box := getSandboxName(Globals.sandboxes_array, "Target sandbox for shortcut:", true)
    if (box != "")
        ShortcutManager.NewShortcut(box, startupfile)

    ExitApp
}

; Auto-generate RegConfig.cfg if needed
if (!FileExist(Settings.regconfig))
{
    emptybox := ""
    for _, sandbox in Globals.sandboxes_array
    {
        if (!sandbox.Enabled || sandbox.NeverDelete || sandbox.UseFileImage || sandbox.UseRamDisk)
            Continue
        if (!sandbox.exist)
        {
            emptybox := sandbox.name
            break
        }
    }
    if (emptybox != "")
    {
        MakeRegConfig(emptybox)
        msg := "SandboxToys has generated the registry configuration file`n""" . Settings.regconfig . """`n`n"
        msg .= "That file is necessary to exclude the registry keys and values "
        msg .= "that Sandboxie needs to create in the sandbox for its own use "
        msg .= "from the output of the ""Registry List and Export"" and ""Watch "
        msg .= "Registry Changes"" functions.`n`n"
        msg .= "SandboxToys needs an EMPTY sandbox to create that file. The box "
        msg .= """" . emptybox . """ is empty, and has been used to generate the file.`n`n"
        msg .= "If you need to recreate that file, just delete the file, be sure "
        msg .= "to delete a sandbox, and launch SandboxToys again. You should see "
        msg .= "this dialog again."
        MsgBox(64, Globals.title, msg)
        RunWait(Globals.start . " /box:" . emptybox . " /terminate", , "UseErrorLevel")
        RunWait(Globals.start . " /box:" . emptybox . " delete_sandbox", , "UseErrorLevel")
    }
}

; Main Execution Logic
menuManager := MenuManager()
if (traymode)
{
    A_TrayMenu.Delete()
    A_TrayMenu.Add("About and Help", MainHelpMenuHandler)
    setMenuIcon(A_TrayMenu, "About and Help", Globals.shell32, 24, Settings.smalliconsize)
    A_TrayMenu.Add("Exit", ExitMenuHandler)
    setMenuIcon(A_TrayMenu, "Exit", Globals.shell32, 28, Settings.smalliconsize)
    A_TrayMenu.Add()
    boundBuildMainMenu := menuManager.BuildMainMenu.Bind(menuManager, traymode, singleboxmode, singlebox)
    A_TrayMenu.Add("SandboxToys Menu", boundBuildMainMenu)
    setMenuIcon(A_TrayMenu, "SandboxToys Menu", Globals.SbieAgentResMain, Globals.SbieAgentResMainId, Settings.smalliconsize)
    if (Settings.trayiconfile != "")
    {
        if (Settings.trayiconnumber == "")
            Settings.trayiconnumber := 1
        try A_TrayMenu.SetIcon(Settings.trayiconfile, Settings.trayiconnumber)
    }
    A_TrayMenu.Default := "SandboxToys Menu"
    A_TrayMenu.ClickCount := 1
    if (singleboxmode)
        A_TrayMenu.Tip := Globals.title . "`nBox : " . singlebox
    else
        A_TrayMenu.Tip := Globals.title
}
else
{
    menuManager.BuildMainMenu(traymode, singleboxmode, singlebox)
    ExitApp
}

Return

; ##############################################################################
; ##############################################################################
;
;                                  FUNCTIONS
;
; ##############################################################################
; ##############################################################################


; Removed the old BuildMainMenu and BuildExploreMenu functions.

; ###################################################################################################
; Functions
; ###################################################################################################

ListFiles(boxName, compareFile := "")
{
    IgnoreManager.ReadIgnoredConfig("files")
    local sandbox := Globals.getSandboxByName(boxName)
    if (!IsObject(sandbox))
        return []

    local compareData := ""
    if (compareFile != "" && FileExist(compareFile))
        compareData := FileRead(compareFile)

    local fileList := []
    local mainsbpath := sandbox.bpath
    local mainsbpathlen := StrLen(mainsbpath) + 2

    Loop Files, mainsbpath . "\*", "RF"
    {
        if (A_LoopFileTimeCreated == "19860523174702")
            local status := "-"
        else
            local status := "+"

        if (A_LoopFileIsDir && status == "+")
            continue

        local relativePath := SubStr(A_LoopFileFullPath, mainsbpathlen)
        if (IgnoreManager.IsIgnored("files", ignoredFiles, relativePath, A_LoopFileName) || IgnoreManager.IsIgnored("dirs", ignoredDirs, relativePath))
            continue

        if (compareData != "")
        {
            local relativePath := SubStr(A_LoopFileFullPath, mainsbpathlen)
            local comp := status . " " . A_LoopFileTimeModified . " " . relativePath . ":*:"
            if InStr(compareData, comp)
                continue
        }

        local relativePathForList := SubStr(A_LoopFileFullPath, mainsbpathlen)
        fileList.Push({
            path: A_LoopFileFullPath,
            type: A_LoopFileIsDir ? "Folder" : "File",
            size: A_LoopFileSize,
            modified: A_LoopFileTimeModified,
            relativePath: relativePathForList
        })
    }
    return fileList
}

; This function forces a sandbox to become active by launching a hidden
; run_dialog process. This makes Sandboxie load the sandboxed registry hive
; into the live HKEY_USERS section, allowing it to be read by standard commands.
InitializeBox(boxName)
{
    local sandbox := Globals.getSandboxByName(boxName)
    if (!IsObject(sandbox))
        return 0

    Run(Globals.start . " /box:" . boxName . " run_dialog", , "Hide UseErrorLevel", &run_pid)

    local boxkeypath := sandbox.RegStr_ . '\user\current\software\SandboxAutoExec'
    Loop 100
    {
        Sleep(50)
        try {
            RegRead("HKEY_USERS\" . boxkeypath)
            if (!ErrorLevel)
                break
        }
    }
    return run_pid
}

ReleaseBox(run_pid)
{
    if (run_pid == 0)
        return
    Sleep(800)
    ProcessClose(run_pid)
    Sleep(200)
    return
}

; Gathers all registry keys and values from a given sandbox.
; It uses the InitializeBox/ReleaseBox trick to read the live hive.
ListReg(boxName, compareFile := "")
{
    IgnoreManager.ReadIgnoredConfig("reg")
    local sandbox := Globals.getSandboxByName(boxName)
    if (!IsObject(sandbox))
        return []

    local compareData := ""
    if (compareFile != "" && FileExist(compareFile))
        compareData := FileRead(compareFile)

    local run_pid := InitializeBox(boxName)
    if (run_pid == 0)
    {
        MsgBox("Failed to initialize sandbox " . boxName)
        return []
    }

    local regList := []
    local mainsbkey := sandbox.RegStr_
    local mainsbkeylen := StrLen(mainsbkey) + 2

    Loop Reg, "HKEY_USERS\" . mainsbkey, "KVR"
    {
        local subkey := SubStr(A_LoopRegPath, mainsbkeylen)
        if (A_LoopRegType == "KEY") {
            if (IgnoreManager.IsIgnored("keys", ignoredKeys, subkey . "\" . A_LoopRegName))
                continue
        } else {
            if (IgnoreManager.IsIgnored("values", ignoredValues, subkey, A_LoopRegName == "" ? "@" : A_LoopRegName))
                continue
        }
        if (IgnoreManager.IsIgnored("keys", ignoredKeys, subkey))
            continue

        if (compareData != "")
        {
            local subkey := SubStr(A_LoopRegPath, mainsbkeylen)
            local comp := FormatRegConfigKey(A_LoopRegPath, subkey, A_LoopRegType, A_LoopRegName, A_LoopRegTimeModified, " ")
            if InStr(compareData, comp)
                continue
        }

        local subkey := SubStr(A_LoopRegPath, mainsbkeylen)
        regList.Push({
            key: A_LoopRegPath,
            type: A_LoopRegType,
            size: "",
            modified: A_LoopRegTimeModified,
            relativePath: subkey
        })
    }

    ReleaseBox(run_pid)
    return regList
}

FormatRegConfigKey(RegSubKey, subkey, RegType, RegName, RegTimeModified, separator, includedate := false)
{
    local type := RegType
    local status := ""

    if (RegTimeModified == "19860523174702")
        status := "-"
    else
        status := "+"

    if (type == "KEY")
    {
        if (status == "-")
            type := "-DELETED_KEY"
        outtxt := status . separator . subkey . "\" . RegName . separator . type . separator . separator
    }
    else
    {
        local value := ""
        try {
            value := RegRead(RegSubKey, RegName)
        }
        catch
        {
            value := "(read error)"
        }

        if (InStr(type, "_SZ"))
        {
            value := StrReplace(value, "`n", " ")
            if (type == "REG_MULTI_SZ")
                value := RTrim(value)
        }
        if (StrLen(value) > 80)
            value := SubStr(value, 1, 80) . "..."

        local name := RegName == "" ? "@" : RegName
        outtxt := status . separator . subkey . separator . type . separator . name . separator . value
    }

    if (includedate)
        outtxt .= separator . RegTimeModified

    return outtxt
}

MakeRegConfig(boxName, filename := "")
{
    if (filename == "")
        filename := Settings.regconfig

    local sandbox := Globals.getSandboxByName(boxName)
    if (!IsObject(sandbox))
        return

    local run_pid := InitializeBox(boxName)
    if (run_pid == 0)
        return

    local mainsbkey := "HKEY_USERS\" . sandbox.RegStr_
    local mainsbkeylen := StrLen(mainsbkey) + 2
    local outtxt := ""

    Loop Reg, mainsbkey, "KVR"
    {
        if (A_LoopRegType == "KEY" && A_LoopRegTimeModified != "19860523174702")
            continue

        local subkey := SubStr(A_LoopRegPath, mainsbkeylen)
        local out := FormatRegConfigKey(A_LoopRegPath, subkey, A_LoopRegType, A_LoopRegName, A_LoopRegTimeModified, " ")
        outtxt .= out . "`n"
    }

    try FileDelete(filename)
    FileAppend("`n" . outtxt, filename)

    ReleaseBox(run_pid)
    return
}

MakeFilesConfig(boxName, filename)
{
    local sandbox := Globals.getSandboxByName(boxName)
    if (!IsObject(sandbox))
        return

    local mainsbpath := sandbox.bpath
    local mainsbpathlen := StrLen(mainsbpath) + 2
    local outtxt := ""

    Loop Files, mainsbpath . "\*", "RF"
    {
        if (A_LoopFileTimeCreated == "19860523174702")
            local status := "-"
        else
            local status := "+"

        if (A_LoopFileIsDir && status == "+")
            continue

        local name := SubStr(A_LoopFileFullPath, mainsbpathlen)
        outtxt .= status . " " . A_LoopFileTimeModified . " " . name . ":*:`n"
    }

    try FileDelete(filename)
    FileAppend("`n" . outtxt, filename)
    return
}

WatchRegMenuHandler(ItemName, ItemPos, MyMenu)
{
    local box := getBoxFromMenu()
    local sandbox := Globals.getSandboxByName(box)
    if (!IsObject(sandbox)) return

    local comparefile := A_Temp . "\" . sandbox.RegStr_ . "_reg_compare.cfg"
    MakeRegConfig(box, comparefile)

    local result := MsgBox("The current registry state of sandbox '" . box . "' has been saved.`n`nPerform your actions in the sandbox now. When you are finished, click OK to see the changes.", Globals.title, "1|IconQuestion")

    if (result == "OK")
        ListReg(box, comparefile)
}

WatchFilesMenuHandler(ItemName, ItemPos, MyMenu)
{
    local box := getBoxFromMenu()
    local sandbox := Globals.getSandboxByName(box)
    if (!IsObject(sandbox)) return

    local comparefile := A_Temp . "\" . sandbox.RegStr_ . "_files_compare.cfg"
    MakeFilesConfig(box, comparefile)

    local result := MsgBox("The current file state of sandbox '" . box . "' has been saved.`n`nPerform your actions in the sandbox now. When you are finished, click OK to see the changes.", Globals.title, "1|IconQuestion")

    if (result == "OK")
        ListFiles(box, comparefile)
}

WatchFilesRegMenuHandler(ItemName, ItemPos, MyMenu)
{
    local box := getBoxFromMenu()
    local sandbox := Globals.getSandboxByName(box)
    if (!IsObject(sandbox)) return

    local comparefile_files := A_Temp . "\" . sandbox.RegStr_ . "_files_compare.cfg"
    MakeFilesConfig(box, comparefile_files)

    local comparefile_reg := A_Temp . "\" . sandbox.RegStr_ . "_reg_compare.cfg"
    MakeRegConfig(box, comparefile_reg)

    local result := MsgBox("The current file and registry state of sandbox '" . box . "' has been saved.`n`nPerform your actions in the sandbox now. When you are finished, click OK to see the changes.", Globals.title, "1|IconQuestion")

    if (result == "OK")
    {
        ListFiles(box, comparefile_files)
        ListReg(box, comparefile_reg)
    }
}

SearchAutostart(regpath, location, tick)
{
    local autostartList := []
    Loop Reg, "HKEY_USERS\" . regpath, "V"
    {
        if (A_LoopRegType != "REG_SZ")
            continue

        autostartList.Push({
            name: A_LoopRegName,
            command: A_LoopRegValue,
            location: location,
            ticked: tick
        })
    }
    return autostartList
}

ListAutostarts(boxName)
{
    local sandbox := Globals.getSandboxByName(boxName)
    if (!IsObject(sandbox))
        return []

    local run_pid := InitializeBox(boxName)
    if (run_pid == 0)
    {
        MsgBox("Failed to initialize sandbox " . boxName)
        return []
    }

    local bregstr_ := sandbox.RegStr_
    local allAutostarts := []

    local key, location, tick

    key := bregstr_ . '\machine\Software\Microsoft\Windows\CurrentVersion\RunOnce'
    location := "HKLM RunOnce"
    allAutostarts.Push(SearchAutostart(key, location, 0)*)

    key := bregstr_ . '\machine\Software\Wow6432Node\Microsoft\Windows\CurrentVersion\RunOnce'
    allAutostarts.Push(SearchAutostart(key, location, 0)*)

    key := bregstr_ . '\user\current\Software\Microsoft\Windows\CurrentVersion\RunOnce'
    location := "HKCU RunOnce"
    allAutostarts.Push(SearchAutostart(key, location, 0)*)

    key := bregstr_ . '\user\current\Software\Wow6432Node\Microsoft\Windows\CurrentVersion\RunOnce'
    allAutostarts.Push(SearchAutostart(key, location, 0)*)

    key := bregstr_ . '\machine\Software\Microsoft\Windows\CurrentVersion\Run'
    location := "HKLM Run"
    allAutostarts.Push(SearchAutostart(key, location, 1)*)

    key := bregstr_ . '\machine\Software\Wow6432Node\Microsoft\Windows\CurrentVersion\Run'
    allAutostarts.Push(SearchAutostart(key, location, 1)*)

    key := bregstr_ . '\user\current\Software\Microsoft\Windows\CurrentVersion\Run'
    location := "HKCU Run"
    allAutostarts.Push(SearchAutostart(key, location, 1)*)

    key := bregstr_ . '\user\current\Software\Wow6432Node\Microsoft\Windows\CurrentVersion\Run'
    allAutostarts.Push(SearchAutostart(key, location, 1)*)

    ReleaseBox(run_pid)

    return allAutostarts
}

expandEnvVars(str)
{
    local result := StrReplace(str, "`%SID`%", Globals.SID)
    result := StrReplace(result, "`%SESSION`%", Globals.SESSION)
    result := StrReplace(result, "`%USER`%", Globals.username)
    return EnvExpand(result)
}

stdPathToBoxPath(box, bpath)
{
    local sandbox := Globals.getSandboxByName(box)
    if (!IsObject(sandbox)) return bpath

    local boxpath := sandbox.bpath
    local outpath := ""

    local userprofile := A_UserProfile . "\"
    if (SubStr(bpath, 1, StrLen(userprofile)) == userprofile) {
        local remain := SubStr(bpath, StrLen(userprofile) + 1)
        outpath := boxpath . "\user\current\" . remain
    }

    if (outpath == "") {
        local allusersprofile := A_AllUsersProfile . "\"
        if (SubStr(bpath, 1, StrLen(allusersprofile)) == allusersprofile) {
            local remain := SubStr(bpath, StrLen(allusersprofile) + 1)
            outpath := boxpath . "\user\all\" . remain
        }
    }

    if (outpath == "") {
        if (RegExMatch(bpath, "^([a-zA-Z]):\\", &m)) {
            local drive := m[1]
            local remain := SubStr(bpath, 3)
            outpath := boxpath . "\drive\" . drive . remain
        }
    }

    return outpath != "" ? outpath : bpath
}

boxPathToStdPath(box, bpath)
{
    local sandbox := Globals.getSandboxByName(box)
    if (!IsObject(sandbox)) return bpath

    local boxpath := sandbox.bpath
    if (SubStr(bpath, 1, StrLen(boxpath)) == boxpath)
    {
        local remain := SubStr(bpath, StrLen(boxpath) + 2)
        if (SubStr(remain, 1, 12) == "user\current\") {
            return A_UserProfile . "\" . SubStr(remain, 13)
        }
        if (SubStr(remain, 1, 9) == "user\all\") {
            return A_AllUsersProfile . "\" . SubStr(remain, 10)
        }
        if (SubStr(remain, 1, 6) == "drive\") {
            local driveletter := SubStr(remain, 7, 1)
            return driveletter . ":\" . SubStr(remain, 9)
        }
    }
    return bpath
}

findCurrentDir(box, shortcut)
{
    local outDir := ""
    if (StrEndsWith(shortcut, ".lnk"))
    {
        try {
            outDir := FileGetShortcut(shortcut).Target
            SplitPath(outDir, , &outDir)
        }
    }
    else
        SplitPath(shortcut, , &outDir)

    return expandEnvVars(outDir)
}

executeShortcut(box, shortcut)
{
    local curdir := findCurrentDir(box, shortcut)
    try
        SetWorkingDir(curdir)
    catch
    {
        try
            SetWorkingDir(A_ScriptDir)
    }

    if (box)
        Run(Globals.start . " /box:" . box . " """ . shortcut . """", curdir, "UseErrorLevel")
    else
        Run(shortcut, curdir, "UseErrorLevel")

    SetWorkingDir(A_ScriptDir)
}

setMenuIcon(menuObj, item, iconfile, iconindex, largeiconsize)
{
    try {
        menuObj.SetIcon(item, iconfile, iconindex, largeiconsize)
        return 0
    }
    catch {
        return 1
    }
}

IndexOfIconResource(Filename, ID)
{
    Filename := Trim(Filename, '"')
    Filename := expandEnvVars(Filename)
    ID := Abs(ID)
    hmod := DllCall("GetModuleHandle", "str", Filename)

    loaded := !hmod && (hmod := DllCall("LoadLibraryEx", "str", Filename, "ptr", 0, "uint", 0x2))

    enumproc := CallbackCreate("IndexOfIconResource_EnumIconResources")
    param := Buffer(12, 0)
    NumPut("int", ID, param, 0)

    DllCall("EnumResourceNames", "ptr", hmod, "ptr", 14, "ptr", enumproc, "ptr", param.ptr)
    CallbackFree(enumproc)

    if loaded
        DllCall("FreeLibrary", "ptr", hmod)

    return NumGet(param, 8, "int") ? NumGet(param, 4, "int") : 0
}

IndexOfIconResource_EnumIconResources(hModule, lpszType, lpszName, lParam)
{
    param := Buffer(lParam, 12, 0)
    NumPut("int", NumGet(param, 4, "int") + 1, param, 4)

    if (lpszName == NumGet(param, 0, "int"))
    {
        NumPut("int", 1, param, 8)
        return false
    }
    return true
}

setIconFromSandboxedShortcut(box, shortcut, menuObj, label, iconsize)
{
    local sandbox := Globals.getSandboxByName(box)
    if (!IsObject(sandbox)) return

    local bregstr_ := sandbox.RegStr_
    local iconfile, iconnum, target, extension

    SplitPath(shortcut, , , &extension)
    if (extension == "lnk") {
        local sc := FileGetShortcut(shortcut)
        target := sc.Target
        iconfile := sc.IconFile
        iconnum := sc.IconNum
        if (iconnum == 0) iconnum := 1
        if (iconfile == "") {
            iconfile := target
            iconnum := 1
        }
    } else {
        iconfile := shortcut
        iconnum := 1
    }
    iconfile := Trim(iconfile, '"')
    iconfile := expandEnvVars(iconfile)

    if (InStr(FileExist(iconfile), "D")) {
        setMenuIcon(menuObj, label, Globals.imageres, 4, iconsize)
        return
    }

    local boxfile := stdPathToBoxPath(box, iconfile)
    if (InStr(FileExist(boxfile), "D")) {
        setMenuIcon(menuObj, label, Globals.imageres, 4, iconsize)
        return
    }
    if (FileExist(boxfile)) {
        iconfile := boxfile
    }

    local rc := setMenuIcon(menuObj, label, iconfile, iconnum, iconsize)
    if (rc == 0) return

    ; If setMenuIcon failed, try to get icon from registry
    if (extension == "lnk") {
        SplitPath(target, , , &extension)
    } else {
        SplitPath(shortcut, , , &extension)
    }

    local defaulticon := ""
    try defaulticon := RegRead("HKEY_USERS\" . bregstr_ . "\machine\software\classes\." . extension . "\DefaultIcon")
    catch {}

    if (defaulticon == "") {
        try {
            local keyval := RegRead("HKEY_USERS\" . bregstr_ . "\machine\software\classes\." . extension)
            if (keyval != "")
                defaulticon := RegRead("HKEY_USERS\" . bregstr_ . "\machine\software\classes\" . keyval . "\DefaultIcon")
        } catch {}
    }

    if (defaulticon != "") {
        local parts := StrSplit(defaulticon, ",")
        iconfile := Trim(parts[1], '"')
        iconnum := parts.Length > 1 ? parts[2] : 1
        iconfile := expandEnvVars(iconfile)
        iconfile := stdPathToBoxPath(box, iconfile)
        rc := setMenuIcon(menuObj, label, iconfile, iconnum, iconsize)
        if (rc == 0) return
    }

    ; If still failed, try unsandboxed registry
    try defaulticon := RegRead("HKEY_CLASSES_ROOT\." . extension . "\DefaultIcon")
    catch {}

    if (defaulticon == "") {
        try {
            local keyval := RegRead("HKEY_CLASSES_ROOT\." . extension)
            if (keyval != "")
                defaulticon := RegRead("HKEY_CLASSES_ROOT\" . keyval . "\DefaultIcon")
        } catch {}
    }

    if (defaulticon != "") {
        if (defaulticon == "%1") {
            iconfile := shortcut
            iconnum := 1
        } else {
            local parts := StrSplit(defaulticon, ",")
            iconfile := Trim(parts[1], '"')
            iconnum := parts.Length > 1 ? parts[2] : 1
            if (iconnum < 0)
                iconnum := IndexOfIconResource(iconfile, iconnum)
            else
                iconnum++
        }
        iconfile := expandEnvVars(iconfile)
        rc := setMenuIcon(menuObj, label, iconfile, iconnum, iconsize)
        if (rc == 0) return
    }

    ; Final fallback
    setMenuIcon(menuObj, label, Globals.shell32, 2, iconsize)
}

ListFilesMenuHandler(ItemName, ItemPos, MyMenu)
{
    global box
    local files := ListFiles(box)
    GuiManager.ListGUI("Files", box, "files", files)
}

ListRegMenuHandler(ItemName, ItemPos, MyMenu)
{
    global box
    local keys := ListReg(box)
    GuiManager.ListGUI("Registry", box, "reg", keys)
}

DummyMenuHandler(ItemName, ItemPos, MyMenu)
{
    ; This is a dummy handler for disabled menu items. It does nothing.
    return
}

getBoxFromMenu()
{
    return SubStr(A_ThisMenu, 1, InStr(A_ThisMenu, "_ST2") - 1)
}

TerminateMenuHandler(ItemName, ItemPos, MyMenu)
{
    local box := getBoxFromMenu()
    if GetKeyState("Control", "P")
        ShortcutManager.writeUnsandboxedShortcutFileToDesktop(Globals.start, "Terminate Programs in sandbox " . box, "", "/box:" . box . " /terminate", "Terminate all programs running in sandbox " . box, Globals.shell32, 220, 1)
    else
        RunWait(Globals.start . " /box:" . box . " /terminate",, "UseErrorLevel")
}

DeleteBoxMenuHandler(ItemName, ItemPos, MyMenu)
{
    local box := getBoxFromMenu()
    if GetKeyState("Control", "P") {
        ShortcutManager.writeUnsandboxedShortcutFileToDesktop(Globals.start, "! Delete sandbox " . box . " !", "", "/box:" . box . " delete_sandbox", "Deletes the sandbox " . box, Globals.shell32, 132, 1)
        MsgBox("Warning! Unlike when Delete Sandbox is run from the SandboxToys Menu, the desktop shortcut that has been created doesn't ask for confirmation!`n`nUse the shortcut with care!", Globals.title, "48|IconExclamation")
    } else {
        if (MsgBox("Are you sure you want to delete the sandbox '" . box . "'?", Globals.title, "292|IconQuestion") == "No")
             return
        RunWait(Globals.start . " /box:" . box . " delete_sandbox",, "UseErrorLevel")
    }
}

SCmdMenuHandler(ItemName, ItemPos, MyMenu)
{
    local box := getBoxFromMenu()
    if GetKeyState("Control", "P")
    {
        local args := "/box:" . box . " " . A_ComSpec . " /k ""cd /d " . A_WinDir . "\"""
        ShortcutManager.writeSandboxedShortcutFileToDesktop(Globals.start, "Sandboxed Command Prompt", "", args, "Sandboxed Command Prompt in sandbox " . box, Globals.cmdRes, 1, 1, box)
    }
    else
    {
        local cdpath := FileExist(expandEnvVars(Settings.sbcommandpromptdir)) ? Settings.sbcommandpromptdir : A_WinDir
        Run(Globals.start . " /box:" . box . " " . A_ComSpec . " /k ""cd /d " . cdpath . """",, "UseErrorLevel")
    }
}

UCmdMenuHandler(ItemName, ItemPos, MyMenu)
{
    local box := getBoxFromMenu()
    local sandbox := getSandboxByName(box)
    if (!IsObject(sandbox)) return

    if GetKeyState("Control", "P")
    {
        local args := "/k ""cd /d """ . sandbox.bpath . """"""
        ShortcutManager.writeUnsandboxedShortcutFileToDesktop(A_ComSpec, "Unsandboxed Command Prompt in sandbox " . box, sandbox.bpath, args, "Unsandboxed Command Prompt in sandbox " . box, Globals.cmdRes, 1, 1)
    }
    else
        Run(A_ComSpec . " /k ""cd /d """ . sandbox.bpath . """""",, "UseErrorLevel")
}

RunDialogMenuHandler(ItemName, ItemPos, MyMenu)
{
    local box := getBoxFromMenu()
    if GetKeyState("Control", "P")
        ShortcutManager.writeSandboxedShortcutFileToDesktop(Globals.start, "Sandboxie's Run dialog", "", "/box:" . box . " run_dialog", "Launch Sandboxie's Run Dialog in sandbox " . box, Globals.SbieAgentResMain, Globals.SbieAgentResMainId, 1, box)
    else
        Run(Globals.start . " /box:" . box . " run_dialog",, "UseErrorLevel")
}

StartMenuMenuHandler(ItemName, ItemPos, MyMenu)
{
    local box := getBoxFromMenu()
    if GetKeyState("Control", "P")
        ShortcutManager.writeSandboxedShortcutFileToDesktop(Globals.start, "Sandboxie's Start Menu", "", "/box:" . box . " start_menu", "Launch Sandboxie's Start Menu in sandbox " . box, Globals.SbieAgentResMain, Globals.SbieAgentResMainId, 1, box)
    else
        Run(Globals.start . " /box:" . box . " start_menu",, "UseErrorLevel")
}

UninstallMenuHandler(ItemName, ItemPos, MyMenu)
{
    local box := getBoxFromMenu()
    if GetKeyState("Control", "P")
        ShortcutManager.writeSandboxedShortcutFileToDesktop(Globals.start, "Uninstall Programs", "", "/box:" . box . " appwiz.cpl", "Uninstall or installs programs in sandbox " . box, Globals.shell32, 22, 1, box)
    else
        RunWait(Globals.start . " /box:" . box . " appwiz.cpl",, "UseErrorLevel")
}

SRegEditMenuHandler(ItemName, ItemPos, MyMenu)
{
    local box := getBoxFromMenu()
    if GetKeyState("Control", "P")
        ShortcutManager.writeSandboxedShortcutFileToDesktop(Globals.start, "Sandboxed Registry Editor", "", "/box:" . box . " " . Globals.regeditImg, "Launch RegEdit in sandbox " . box, Globals.regeditRes, 1, 1, box)
    else
        Run(Globals.start . " /box:" . box . " " . Globals.regeditImg, , "UseErrorLevel")
}

URegEditMenuHandler(ItemName, ItemPos, MyMenu)
{
    if GetKeyState("Control", "P") {
        MsgBox("Creating a desktop shortcut to launch the unsandboxed Registry Editor is not supported, as it requires initializing the sandbox first.", Globals.title, "48|IconExclamation")
    } else {
        local box := getBoxFromMenu()
        local sandbox := getSandboxByName(box)
        if (!IsObject(sandbox)) return

        local run_pid := InitializeBox(box)

        local reg_path := "HKEY_USERS\" . sandbox.RegStr_
        try RegWrite(reg_path, "REG_SZ", "HKEY_CURRENT_USER\Software\Microsoft\Windows\CurrentVersion\Applets\Regedit", "LastKey")

        RunWait(Globals.regeditImg)
        ReleaseBox(run_pid)
    }
}

getBoxFromMenu()
{
    return SubStr(A_ThisMenu, 1, InStr(A_ThisMenu, "_ST2") - 1)
}

getSandboxName(title, include_ask := false)
{
    static selected_box := "unset"

    handler(name, *) {
        global selected_box := name
    }

    selected_box := "unset"
    box_menu := Menu()
    box_menu.Add(title, handler.Bind("")).Disable()
    box_menu.Add()


    for _, sandbox in Globals.sandboxes_array
    {
        local label := sandbox.exist ? sandbox.name : sandbox.name . " (empty)"
        box_menu.Add(label, handler.Bind(sandbox.name))
        setMenuIcon(box_menu, label, sandbox.exist ? Globals.SbieAgentResFull : Globals.SbieAgentResEmpty, sandbox.exist ? Globals.SbieAgentResFullId : Globals.SbieAgentResEmptyId, Settings.largeiconsize)
    }

    if (include_ask)
    {
        box_menu.Add()
        box_menu.Add("Ask box at run time", handler.Bind("__ask__"))
        setMenuIcon(box_menu, "Ask box at run time", Globals.SbieAgentResMain, Globals.SbieAgentResMainId, Settings.largeiconsize)
    }

    box_menu.Add()
    box_menu.Add("Cancel", handler.Bind(""))

    box_menu.Show()

    while (selected_box == "unset")
        Sleep(50)

    local result := selected_box
    selected_box := "unset"
    return result
}

NewShortcut(box, file)
{
    SplitPath(file, , &dir, &extension, &label)
    if (!FileExist(dir))
        dir := stdPathToBoxPath(box, dir)

    local iconfile, iconnum
    if (extension == "exe")
    {
        iconfile := file
        iconnum := 1
    }
    else
    {
        ; Simplified icon logic for now. A full port is a future task.
        iconfile := Globals.shell32
        iconnum := 2
    }

    local tip := (box == "__ask__") ? "Launch '" . label . "' in any sandbox" : "Launch '" . label . "' in sandbox " . box
    writeSandboxedShortcutFileToDesktop(Globals.start, label, dir, "/box:" . box . " """ . file . """", tip, iconfile, iconnum, 1, box)
}

NewShortcutMenuHandler(ItemName, ItemPos, MyMenu)
{
    static DefaultShortcutFolder := A_Desktop
    local box := getBoxFromMenu()

    local file := FileSelect(33, DefaultShortcutFolder, "Select the file to launch sandboxed in box " . box, "All files (*.*)")
    if (file == "")
        return

    ShortcutManager.NewShortcut(box, file)
    SplitPath(file, , &DefaultShortcutFolder)
}

hex2dec(hex)
{
    if SubStr(hex, 1, 2) != "0x"
        hex := "0x" . hex
    return Integer(hex)
}

dec2hex(dec, minlength := 2)
{
    hex := Format("{:H}", dec)
    if Mod(StrLen(hex), 2) != 0
        hex := "0" . hex
    while StrLen(hex) < minlength
        hex := "0" . hex
    return hex
}

qword2hex(qword)
{
    if (qword < 0)
    {
        qword := (qword * -1) - 1
        local dec1 := 0xFFFFFFFF - (qword & 0xFFFFFFFF)
        local dec2 := 0xFFFFFFFF - (qword >> 32)
        local hex1 := Format("{:08X}", dec1)
        local hex2 := Format("{:08X}", dec2)
        local hex := hex2 . hex1
    }
    else
    {
        hex := Format("{:016X}", qword)
    }

    local out := ""
    Loop 8
    {
        out .= SubStr(hex, (A_Index - 1) * 2 + 1, 2) . ","
    }
    return RTrim(out, ",")
}

hexstr2hexstrcomas(hex)
{
    local out := ""
    Loop StrLen(hex)
    {
        out .= SubStr(hex, A_Index, 1)
        if Mod(A_Index, 2) == 0
            out .= ","
    }
    return RTrim(out, ",")
}

hexstr2str(hexstr)
{
    local str := ""
    Loop (StrLen(hexstr) / 2)
        str .= Chr("0x" . SubStr(hexstr, (A_Index - 1) * 2 + 1, 2))
    return str
}

str2hexstr(str, replacenlwithzero := false)
{
    local out := ""
    Loop Parse, str
    {
        local h := Format("{:X}", Asc(A_LoopField))
        if (replacenlwithzero && h == "a")
            out .= "00,"
        else
        {
            if (StrLen(h) == 1)
                out .= "0" . h . ","
            else
                out .= h . ","
        }
    }
    out .= "00"
    return out
}

RunUserToolMenuHandler(ItemName, ItemPos, MyMenu)
{
    ; This handler needs access to the menuCommands map from the MenuManager instance.
    ; This is a design flaw of using global handlers with class-based data.
    ; TODO: Refactor menuManager to be a singleton or pass its instance to handlers.
    MsgBox("User Tools are not fully implemented in this version due to a data access issue.", Globals.title, 48)
}

CmdLineHelp()
{
    local msg := ""
    msg .= Globals.title . "`n`n"
    msg .= "SandboxToys2 Command Line usage:`n`n"
    msg .= "> SandboxToys2 [/box:boxname]`n"
    msg .= "Without arguments, SandboxToys2 opens its main menu.`n`n"
    msg .= "> SandboxToys2 [/box:boxname] /tray`n"
    msg .= "Stays resident in the tray.`n`n"
    msg .= "> SandboxToys2 [/box:boxname] ""existing file, folder or shortcut""`n"
    msg .= "Creates a new sandboxed shortcut on the desktop."
    MsgBox(msg, Globals.title, 64)
}

SExploreMenuHandler(ItemName, ItemPos, MyMenu)
{
    local box := getBoxFromMenu()
    if GetKeyState("Control", "P")
        ShortcutManager.writeSandboxedShortcutFileToDesktop(Globals.start, "Explore sandbox " . box . " (Sandboxed)", Globals.sbdir, "/box:" . box . " " . Globals.explorer, "Launches Explorer sandboxed in sandbox " . box, Globals.explorerRes, 1, 1, box)
    else
        Run(Globals.start . " /box:" . box . " " . Globals.explorer, , "UseErrorLevel")
}

UExploreMenuHandler(ItemName, ItemPos, MyMenu)
{
    local box := getBoxFromMenu()
    local sandbox := getSandboxByName(box)
    if (!IsObject(sandbox)) return

    if GetKeyState("Control", "P")
        ShortcutManager.writeUnsandboxedShortcutFileToDesktop(Globals.explorerImg, "Explore sandbox " . box . " (Unsandboxed)", sandbox.bpath, Globals.explorerArgE . " """ . sandbox.bpath . """", "Launches Explorer unsandboxed in sandbox " . box, Globals.explorerRes, 1, 1)
    else
        Run(Globals.explorer . "\" . sandbox.bpath, , "UseErrorLevel")
}

URExploreMenuHandler(ItemName, ItemPos, MyMenu)
{
    local box := getBoxFromMenu()
    local sandbox := getSandboxByName(box)
    if (!IsObject(sandbox)) return

    if GetKeyState("Control", "P")
        ShortcutManager.writeUnsandboxedShortcutFileToDesktop(Globals.explorerImg, "Explore sandbox " . box . " (Unsandboxed, restricted)", sandbox.bpath, Globals.explorerArgER . " """ . sandbox.bpath . """", "Launches Explorer unsandboxed and restricted to sandbox " . box, Globals.explorerRes, 1, 1)
    else
        Run(Globals.explorerERArg . "\" . sandbox.bpath, , "UseErrorLevel")
}

; Handler for the "Portable Sandbox Creator" menu item.
; Creates the UI and orchestrates the tracing process.
PortableSandboxCreatorMenuHandler(ItemName, ItemPos, MyMenu)
{
    static exe_path := ""
    static selected_box := ""
    static trace_mode := 3 ; 1=Files, 2=Reg, 3=Both

    Gui, PSC:New, , "Portable Sandbox Creator"
    Gui, PSC:SetFont, "s10", "Verdana"

    Gui, PSC:Add, "Text", "w400", "Select the program executable to trace:"
    Gui, PSC:Add, "Edit", "w300 vExePath", exe_path
    Gui, PSC:Add, "Button", "x+10 gSelectExe", "Browse..."

    Gui, PSC:Add, "Text", "w400 y+10", "Select the target sandbox:"

    local box_list := ""
    for _, sandbox in Globals.sandboxes_array
        box_list .= sandbox.name . "|"
    box_list := RTrim(box_list, "|")
    Gui, PSC:Add, "DropDownList", "w300 vSelectedBox Choose1", box_list

    Gui, PSC:Add, "GroupBox", "w400 y+10", "Tracing Mode"
    Gui, PSC:Add, "Radio", "vTraceMode1 gSetTraceMode", "Files Only"
    Gui, PSC:Add, "Radio", "vTraceMode2 gSetTraceMode", "Registry Only"
    Gui, PSC:Add, "Radio", "vTraceMode3 gSetTraceMode Checked", "Files and Registry"

    Gui, PSC:Add, "Button", "y+20 w150 h30 gStartPSC", "Start Tracing"
    Gui, PSC:Show
    return

    SelectExe() {
        local file := FileSelect(3, exe_path, "Select Executable", "Programs (*.exe)")
        if (file) {
            exe_path := file
            GuiControl, PSC:, ExePath, %exe_path%
        }
    }

    SetTraceMode(ctrl, *) {
        if (ctrl.Value == 1)
            trace_mode := SubStr(ctrl.Name, -0)
    }

    StartPSC(*) {
        Gui, PSC:Submit, NoHide
        try {
        if (!FileExist(ExePath)) {
            MsgBox("Please select a valid executable file.", Globals.title, 48)
            return
        }
        if (SelectedBox == "") {
            MsgBox("Please select a target sandbox.", Globals.title, 48)
            return
        }
        if (!ProcMonManager.CheckExists()) {
            return
        }

        Gui, PSC:Destroy

        local pml_file := A_Temp . "\sbt_trace.pml"
        local csv_file := A_Temp . "\sbt_trace.csv"
        SplitPath(ExePath, &process_name)

        MsgBox("Starting trace... Please use the target application as comprehensively as possible. Close it when you are finished.", Globals.title, 64)

        ProcMonManager.StartCapture(pml_file)
        RunWait(Globals.start . " /box:" . SelectedBox . " """ . ExePath . """")
        ProcMonManager.StopCapture(pml_file, csv_file)

        MsgBox("Trace complete. Now analyzing log...", Globals.title, 64)
        local dependencies := ParseProcMonLog(csv_file, process_name, Globals.getSandboxByName(SelectedBox).bpath)

        local file_count := dependencies.files.Length
        local reg_count := dependencies.reg.Length
        MsgBox("Analysis complete.`nFound " . file_count . " file dependencies and " . reg_count . " registry dependencies.`nNow copying to sandbox...", Globals.title, 64)

        if (trace_mode == 1 || trace_mode == 3) { ; Files or Both
            if (file_count > 0)
                CopyFilesToSandbox(SelectedBox, dependencies.files)
        }
        if (trace_mode == 2 || trace_mode == 3) { ; Registry or Both
            if (reg_count > 0)
                CopyRegistryKeysToSandbox(SelectedBox, dependencies.reg)
        }

        try FileDelete(pml_file)
        try FileDelete(csv_file)

        MsgBox("Portable sandbox creation complete for box '" . SelectedBox . "'.", Globals.title, 64)
        }
        catch e
        {
            MsgBox("An error occurred during the process: `n" . e.Message, Globals.title, 16)
        }
    }

    PSC_Close() {
        Gui, PSC:Destroy
    }
}

MainHelpMenuHandler(*)
{
    local msg := ""
    msg .= "SandboxToys2 Main Menu usage:`n`n"
    msg .= "The main menu displays the shortcuts present in the Start Menu, Desktop and QuickLaunch folders of your sandboxes. Just select any of these shortcuts to launch the program, sandboxed in the right box.`n`n"
    msg .= "You can create a 'sandboxed shortcut' on your real destkop to launch any program displayed in the SandboxToys Menu even easier! Just Control-Click on the menu entry, and the shortcut will be created on your desktop.`n`n"
    msg .= "Similarly, Shift-clicking on a menu icon opens the folder containing the file. The Windows explorer is run sandboxed.`n`n"
    msg .= "The User Tools menu is a configurable menu. To use it, place a shortcut in the '" . Settings.usertoolsdir . "' folder."
    MsgBox(msg, Globals.title, "64|IconInfo")
}

ExitMenuHandler(*)
{
    ExitApp()
}

class IgnoreManager
{
    static ReadIgnoredConfig(type)
    {
        global ignoredDirs, ignoredFiles, ignoredKeys, ignoredValues
        if (type == "files")
        {
            try ignoredDirs := "`n" . FileRead(Settings.ignorelist . "dirs.cfg")
            catch ignoredDirs := "`n"
            try ignoredFiles := "`n" . FileRead(Settings.ignorelist . "files.cfg")
            catch ignoredFiles := "`n"
        }
        else
        {
            try ignoredKeys := "`n" . FileRead(Settings.ignorelist . "keys.cfg")
            catch ignoredKeys := "`n"
            try ignoredValues := "`n" . FileRead(Settings.ignorelist . "values.cfg")
            catch ignoredValues := "`n"
        }
    }

    static IsIgnored(mode, ignoredList, checkpath, item := "")
    {
        if (ignoredList == "`n") return false

        if (mode == "values" || mode == "files")
        {
            local tocheck := "`n" . checkpath . "\" . item . "`n"
            return InStr(ignoredList, tocheck)
        }
        else
        {
            loop
            {
                local tocheck := "`n" . checkpath . "`n"
                if InStr(ignoredList, tocheck)
                    return true
                SplitPath(checkpath, , &checkpath)
                if (checkpath == "")
                    return false
            }
        }
        return false
    }

    static AddIgnoreItem(mode, item)
    {
        global newIgnored_dirs, newIgnored_files, newIgnored_keys, newIgnored_values
        if (mode == "dirs") newIgnored_dirs .= "`n" . item
        else if (mode == "files") newIgnored_files .= "`n" . item
        else if (mode == "keys") newIgnored_keys .= "`n" . item
        else if (mode == "values") newIgnored_values .= "`n" . item
    }

    static SaveNewIgnoredItems(mode)
    {
        global ignoredDirs, ignoredFiles, ignoredKeys, ignoredValues
        global newIgnored_dirs, newIgnored_files, newIgnored_keys, newIgnored_values

        local pathdata, itemdata, pathfilename, itemfilename
        if (mode == "files")
        {
            if (newIgnored_dirs == "" && newIgnored_files == "") return
            pathdata := ignoredDirs . newIgnored_dirs
            itemdata := ignoredFiles . newIgnored_files
            pathfilename := Settings.ignorelist . "dirs.cfg"
            itemfilename := Settings.ignorelist . "files.cfg"
        }
        else
        {
            if (newIgnored_keys == "" && newIgnored_values == "") return
            pathdata := ignoredKeys . newIgnored_keys
            itemdata := ignoredValues . newIgnored_values
            pathfilename := Settings.ignorelist . "keys.cfg"
            itemfilename := Settings.ignorelist . "values.cfg"
        }

        local pathArray := Sort(StrSplit(pathdata, "`n", "`r"), "U")
        local itemArray := Sort(StrSplit(itemdata, "`n", "`r"), "U")

        ; TODO: Port the sub-path reduction logic from v1 for more efficient ignore files.

        try FileDelete(pathfilename)
        FileAppend(Format("{:s}", pathArray), pathfilename)

        try FileDelete(itemfilename)
        FileAppend(Format("{:s}", itemArray), itemfilename)
    }
}

getSandboxName(title, include_ask := false)
{
    static selected_box := "unset"

    handler(name, *) {
        global selected_box := name
    }

    selected_box := "unset"
    box_menu := Menu()
    box_menu.Add(title, handler.Bind("")).Disable()
    box_menu.Add()


    for _, sandbox in Globals.sandboxes_array
    {
        local label := sandbox.exist ? sandbox.name : sandbox.name . " (empty)"
        box_menu.Add(label, handler.Bind(sandbox.name))
        setMenuIcon(box_menu, label, sandbox.exist ? Globals.SbieAgentResFull : Globals.SbieAgentResEmpty, sandbox.exist ? Globals.SbieAgentResFullId : Globals.SbieAgentResEmptyId, Settings.largeiconsize)
    }

    if (include_ask)
    {
        box_menu.Add()
        box_menu.Add("Ask box at run time", handler.Bind("__ask__"))
        setMenuIcon(box_menu, "Ask box at run time", Globals.SbieAgentResMain, Globals.SbieAgentResMainId, Settings.largeiconsize)
    }

    box_menu.Add()
    box_menu.Add("Cancel", handler.Bind(""))

    box_menu.Show()

    while (selected_box == "unset")
        Sleep(50)

    local result := selected_box
    selected_box := "unset"
    return result
}

NewShortcut(box, file)
{
    SplitPath(file, , &dir, &extension, &label)
    if (!FileExist(dir))
        dir := stdPathToBoxPath(box, dir)

    local iconfile, iconnum
    if (extension == "exe")
    {
        iconfile := file
        iconnum := 1
    }
    else
    {
        ; Simplified icon logic for now. A full port is a future task.
        iconfile := Globals.shell32
        iconnum := 2
    }

    local tip := (box == "__ask__") ? "Launch '" . label . "' in any sandbox" : "Launch '" . label . "' in sandbox " . box
    writeSandboxedShortcutFileToDesktop(Globals.start, label, dir, "/box:" . box . " """ . file . """", tip, iconfile, iconnum, 1, box)
}

NewShortcutMenuHandler(ItemName, ItemPos, MyMenu)
{
    static DefaultShortcutFolder := A_Desktop
    local box := getBoxFromMenu()

    local file := FileSelect(33, DefaultShortcutFolder, "Select the file to launch sandboxed in box " . box, "All files (*.*)")
    if (file == "")
        return

    NewShortcut(box, file)
    SplitPath(file, , &DefaultShortcutFolder)
}

; ... (rest of the original file)
