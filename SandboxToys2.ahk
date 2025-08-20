A_Persistent := true
A_SingleInstance := "Off"

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
        this.sandboxes_array := getSandboxesArray(this.ini)
    }
}

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
            this.largeiconsize       := IniRead(this.sbtini, "AutoConfig", "LargeIconSize", this.largeiconsize)
            this.smalliconsize       := IniRead(this.sbtini, "AutoConfig", "SmallIconSize", this.smalliconsize)
            this.seperatedstartmenus := IniRead(this.sbtini, "AutoConfig", "SeperatedStartMenus", this.seperatedstartmenus)
            this.includeboxnames     := IniRead(this.sbtini, "AutoConfig", "IncludeBoxNames", this.includeboxnames)
            this.listemptyitems      := IniRead(this.sbtini, "AutoConfig", "ListEmptyItems", this.listemptyitems)
            this.trayiconfile        := IniRead(this.sbtini, "UserConfig", "TrayIconFile", this.trayiconfile)
            this.trayiconnumber      := IniRead(this.sbtini, "UserConfig", "TrayIconNumber", this.trayiconnumber)
            this.sbcommandpromptdir  := IniRead(this.sbtini, "UserConfig", "SandboxedCommandPromptDir", this.sbcommandpromptdir)
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

class GuiManager
{
    static ListGUI(title, box, type, data)
    {
        Gui, ListGui:New, +Resize, % Globals.title . " - " . title . " - " . box
        Gui, ListGui:Font, s10, Verdana
        Gui, ListGui:Add, ListView, w780 h500 vMyListView gMyListView, Path|Type|Size|Modified
        LV_ModifyCol(1, 400)
        LV_ModifyCol(2, 70)
        LV_ModifyCol(3, 70, "Integer")
        LV_ModifyCol(4, 140)

        if (type == "files")
        {
            for _, item in data
            {
                LV_Add("", item.path, item.type, item.size, item.modified)
            }
        }
        else if (type == "reg")
        {
            for _, item in data
            {
                LV_Add("", item.key, item.type, item.size, item.modified)
            }
        }

        Gui, ListGui:Add, Button, gExportListGui x10 y510 w100, Export List
        Gui, ListGui:Add, Button, gCloseListGui x120 y510 w100, Close
        Gui, ListGui:Show
        return

    MyListView:
        if (A_GuiEvent == "DoubleClick")
        {
            LV_GetText(item, A_EventInfo)
            if (type == "files")
                Run(item)
            else
                MsgBox("Double-clicking registry keys is not supported.")
        }
        return

    ExportListGui:
        ; ... export logic ...
        MsgBox("Export not implemented yet.")
        return

    CloseListGui:
    ListGui_Close:
        Gui, ListGui:Destroy
        return
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

            menuObj.Add(label, this.RunProgramMenuHandler.Bind(this))
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
            createDesktopShortcutFromLnk(box, shortcut, "", "")
        } else if GetKeyState("Shift", "P") {
            SplitPath(shortcut, , &dir)
            Run(Globals.start . " /box:" . box . " """ . dir . """")
        } else {
            executeShortcut(box, shortcut)
        }
    }

    BuildMainMenu(traymode, singleboxmode, singlebox)
    {
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
        this.menus["SBMenuSetup"].Add("Large main-menu and box icons?", SetupMenuMenuHandler1)
        if (Settings.largeiconsize > 16)
            this.menus["SBMenuSetup"].Check("Large main-menu and box icons?")
        this.menus["SBMenuSetup"].Add("Large sub-menu icons?", SetupMenuMenuHandler2)
        if (Settings.smalliconsize > 16)
            this.menus["SBMenuSetup"].Check("Large sub-menu icons?")
        this.menus["SBMenuSetup"].Add("Seperated All Users menus?", SetupMenuMenuHandler3)
        if (Settings.seperatedstartmenus)
            this.menus["SBMenuSetup"].Check("Seperated All Users menus?")
        this.menus["SBMenuSetup"].Add()
        this.menus["SBMenuSetup"].Add("Include [#BoxName] in shortcut names?", SetupMenuMenuHandler4)
        if (Settings.includeboxnames)
            this.menus["SBMenuSetup"].Check("Include [#BoxName] in shortcut names?")
        this.menus["SBMenuSetup"].Add()
        this.menus["SBMenuSetup"].Add("List empty folders and keys?", SetupMenuMenuHandler5)
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
        NewShortcut(singlebox, startupfile)
        ExitApp
    }
    box := getSandboxName(Globals.sandboxes_array, "Target sandbox for shortcut:", true)
    if (box != "")
        NewShortcut(box, startupfile)

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

getSandboxByName(name)
{
    for _, sandbox in Globals.sandboxes_array
    {
        if (sandbox.name == name)
            return sandbox
    }
    return ""
}

ListFiles(boxName, compareFile := "")
{
    local sandbox := getSandboxByName(boxName)
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

        if (compareData != "")
        {
            local relativePath := SubStr(A_LoopFileFullPath, mainsbpathlen)
            local comp := status . " " . A_LoopFileTimeModified . " " . relativePath . ":*:"
            if InStr(compareData, comp)
                continue
        }

        fileList.Push({
            path: A_LoopFileFullPath,
            type: A_LoopFileIsDir ? "Folder" : "File",
            size: A_LoopFileSize,
            modified: A_LoopFileTimeModified
        })
    }
    return fileList
}

InitializeBox(boxName)
{
    local sandbox := getSandboxByName(boxName)
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

ListReg(boxName, compareFile := "")
{
    local sandbox := getSandboxByName(boxName)
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
        if (compareData != "")
        {
            local subkey := SubStr(A_LoopRegPath, mainsbkeylen)
            local comp := FormatRegConfigKey(A_LoopRegPath, subkey, A_LoopRegType, A_LoopRegName, A_LoopRegTimeModified, " ")
            if InStr(compareData, comp)
                continue
        }

        regList.Push({
            key: A_LoopRegPath,
            type: A_LoopRegType,
            size: "",
            modified: A_LoopRegTimeModified
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

    local sandbox := getSandboxByName(boxName)
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
    local sandbox := getSandboxByName(boxName)
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
    local sandbox := getSandboxByName(box)
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
    local sandbox := getSandboxByName(box)
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
    local sandbox := getSandboxByName(box)
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
    local sandbox := getSandboxByName(boxName)
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
    local sandbox := getSandboxByName(box)
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
    local sandbox := getSandboxByName(box)
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

writeUnsandboxedShortcutFileToDesktop(target, name, dir, args, description, iconFile, iconNum, runState)
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

writeSandboxedShortcutFileToDesktop(target, name, dir, args, description, iconFile, iconNum, runState, box)
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

createDesktopShortcutFromLnk(box, shortcut, iconfile, iconnum)
{
    local outTarget, outDir, outArgs, outDescription, outRunState, outNameNoExt, outExtension, file

    SplitPath(shortcut, &outNameNoExt, &outDir, &outExtension)

    if (box == "") {
        if (outExtension == "lnk") {
            local dest := A_Desktop . "\" . outNameNoExt . ".lnk"
            FileCopy(shortcut, dest, true)
        } else {
            writeUnsandboxedShortcutFileToDesktop(shortcut, outNameNoExt, outDir, "", "SandboxToys User Tool", "", "", 1)
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
    writeSandboxedShortcutFileToDesktop(outTarget, outNameNoExt, outDir, outArgs, outDescription, iconfile, iconNumToUse, outRunState, box)
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
    local sandbox := getSandboxByName(box)
    if (!IsObject(sandbox)) return

    ; This function is very complex. For now, we'll use a simplified version.
    ; TODO: Port the full icon resolution logic from v1.
    local iconfile, iconnum, target

    if (StrEndsWith(shortcut, ".lnk")) {
        try {
            local sc := FileGetShortcut(shortcut)
            target := sc.Target
            iconfile := sc.IconFile
            iconnum := sc.IconNum
            if (iconnum == 0) iconnum := 1
            if (iconfile == "") iconfile := target
        }
    } else {
        iconfile := shortcut
        iconnum := 1
    }

    iconfile := Trim(iconfile, '"')
    iconfile := expandEnvVars(iconfile)

    local boxfile := stdPathToBoxPath(box, iconfile)
    if (FileExist(boxfile)) {
        iconfile := boxfile
    }

    local rc := setMenuIcon(menuObj, label, iconfile, iconnum, iconsize)
    if (rc != 0) {
        setMenuIcon(menuObj, label, Globals.shell32, 2, iconsize) ; Default icon
    }
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

; ... (rest of the original file)
