A_Persistent := true
A_SingleInstance := "Off"
version := "3.0.0.0"
; SandboxToys: Main Menu
; Author: r0lZ updated by blap and others
; Developed and compiled with AHK2Exe(Unicode 64-bit.bin) with no compression v 1.1.36.02.
; Tested under Win10 x64 with Sandboxie-Plus v1.9.3.
;
; AutoHotkey script to show a menu with several tools related to Sandboxie,
; and a menu to launch applications installed in any sandbox.
;
; The script can also create a sandboxed shortcut on the desktop if you
; Control-Left-Click on any entry of the menu, or if you call the script with
; an existing file, directory or shortcut (.LNK) file as argument.
;
; Known bugs:
; - The icons used by the script (in the menu and in the shortcuts created
;   on the desktop) are not always correct.
; - The Internet Shortcut (.URL) files cannot currently be launched sandboxed.
;   (It's a Sandboxie bug.)
;
; To do:
; - Option to automatically launch all apps supposed to be launched at Windows
;   startup (from Start Menu\Programs\Startup and RUN keys in registry).
; - Options to clone the sandboxed Start Menu, Desktop or QuickLaunch shortcuts
;   as sandboxed shortcuts in the real equivalent folders.
; - Add an "Explore" item in each sub-menu of the Start Menu, Desktop and
;   QuickLaunch menus (like in the standard Sandboxie Start Menu).
; - Add _ask_ box name in the list of boxes for the Create Shortcut option.

SplitPath(A_ScriptName, , , , &nameNoExt)

; Settings
; Note: these values are overwritten if SandboxToys.ini exists in the directrory
; containing the script, in %appdata% or in %appdata%\SandboxToys2\
smalliconsize := 16 ; other icons
largeiconsize := 32 ; sandbox icons
seperatedstartmenus := 0
includeboxnames := 1
listemptyitems := 0
trayiconfile := ""
trayiconnumber := 1
sbcommandpromptdir := A_UserProfile

inidir := A_ScriptDir
sbtini := A_ScriptDir . "\" . nameNoExt . ".ini"
regconfig := A_ScriptDir . "\" . nameNoExt . "_RegConfig.cfg"
ignorelist := A_ScriptDir . "\" . nameNoExt . "_Ignore_"
usertoolsdir := A_ScriptDir . "\" . nameNoExt . "_UserTools"
if (!FileExist(sbtini))
{
    inidir := A_AppData . "\SandboxToys2"
    sbtini := inidir . "\" . nameNoExt . ".ini"
    regconfig := inidir . "\" . nameNoExt . "_RegConfig.cfg"
    ignorelist := inidir . "\" . nameNoExt . "_Ignore_"
    usertoolsdir := inidir . "\" . nameNoExt . "_UserTools"
    if (!DirExist(inidir))
        DirCreate(inidir)
}
if (!DirExist(usertoolsdir))
    DirCreate(usertoolsdir)

if (FileExist(sbtini)) {
    largeiconsize := IniRead(sbtini, "AutoConfig", "LargeIconSize", largeiconsize)
    smalliconsize := IniRead(sbtini, "AutoConfig", "SmallIconSize", smalliconsize)
    seperatedstartmenus := IniRead(sbtini, "AutoConfig", "SeperatedStartMenus", seperatedstartmenus)
    includeboxnames := IniRead(sbtini, "AutoConfig", "IncludeBoxNames", includeboxnames)
    listemptyitems := IniRead(sbtini, "AutoConfig", "ListEmptyItems", listemptyitems)
    trayiconfile := IniRead(sbtini, "UserConfig", "TrayIconFile", trayiconfile)
    trayiconnumber := IniRead(sbtini, "UserConfig", "TrayIconNumber", trayiconnumber)
    sbcommandpromptdir := IniRead(sbtini, "UserConfig", "SandboxedCommandPromptDir", sbcommandpromptdir)
}
else
{
    IniWrite(largeiconsize, sbtini, "AutoConfig", "LargeIconSize")
    IniWrite(smalliconsize, sbtini, "AutoConfig", "SmallIconSize")
    IniWrite(seperatedstartmenus, sbtini, "AutoConfig", "SeperatedStartMenus")
    IniWrite(includeboxnames, sbtini, "AutoConfig", "IncludeBoxNames")
    IniWrite(listemptyitems, sbtini, "AutoConfig", "ListEmptyItems")
    IniWrite(trayiconfile, sbtini, "UserConfig", "TrayIconFile")
    IniWrite(trayiconnumber, sbtini, "UserConfig", "TrayIconNumber")
    IniWrite(sbcommandpromptdir, sbtini, "UserConfig", "SandboxedCommandPromptDir")
}
if (trayiconfile == "ERROR")
    trayiconfile := ""

if (!A_IsCompiled && trayiconfile == "") {
    tmp := A_ScriptDir . "\SandboxToys2.ico"
    if (FileExist(tmp))
        trayiconfile := tmp
    tmp := A_ScriptDir . "\" . nameNoExt . ".ico"
    if (FileExist(tmp))
        trayiconfile := tmp
}

; some useful constants
SetWorkingDir(A_ScriptDir)
title := "SandboxToys v" . version . " by r0lZ updated by blap"
if (nameNoExt != "SandboxToys")
    title .= " (" . nameNoExt . ")"

A_nl := "`n"
A_Quotes := """"
shell32 := A_WinDir . "\system32\shell32.dll"
imageres := A_WinDir . "\system32\imageres.dll"

cmdRes := A_WinDir . "\system32\cmd.exe"

explorerImg := A_WinDir . "\system32\explorer.exe"
if (!FileExist(explorerImg)) {
    explorerImg := A_WinDir . "\explorer.exe"
}
explorerRes := A_WinDir . "\system32\explorer.exe"
if (!FileExist(explorerRes)) {
    explorerRes := A_WinDir . "\explorer.exe"
}
explorer := explorerImg . " /e,::{20D04FE0-3AEA-1069-A2D8-08002B30309D}"
explorerE := explorerImg . " /e"
explorerER := explorerImg . " /e /root"
explorerERArg := explorerImg . " /e /root,::{20D04FE0-3AEA-1069-A2D8-08002B30309D}"
explorerArg := ",::{20D04FE0-3AEA-1069-A2D8-08002B30309D}"
explorerArgE := "/e,::{20D04FE0-3AEA-1069-A2D8-08002B30309D}"
explorerArgER := "/e /root,::{20D04FE0-3AEA-1069-A2D8-08002B30309D}"

regeditImg := A_WinDir . "\system32\regedit.exe"
if (!FileExist(regeditImg)) {
    regeditImg := A_WinDir . "\regedit.exe"
}
regeditRes := A_WinDir . "\system32\regedit.exe"
if (!FileExist(regeditRes)) {
    regeditRes := A_WinDir . "\regedit.exe"
}

; we need the %SID% and %SESSION% variables, supported by Sandboxie,
; but not directly available as Windows environment variables.
; Get them from the registry.
; %SID%:
Loop Reg, "HKEY_CURRENT_USER\Software\Microsoft\Protected Storage System Provider", "K"
{
    if (A_LoopRegType == "KEY") {
        SID := A_LoopRegName
        break
    }
}
; %SESSION%:
SESSION := RegRead("HKEY_CURRENT_USER\Volatile Environment", "SESSION", 0)
if (SESSION == "" || SESSION == "Console")
    SESSION := 0

; find Sandboxie's installation dir
imagepath := RegRead("HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\services\SbieSvc", "ImagePath")
imagepath := Trim(imagepath,A_Quotes)
SplitPath(imagepath, , &sbdir)
start := sbdir . "\Start.exe"
SbieCtrl := sbdir . "\SbieCtrl.exe"
SbieMngr := sbdir . "\SandMan.exe"
SbieAgent := SbieMngr
if (! FileExist(SbieAgent)) {
    SbieAgent := sbdir . "\SbieCtrl.exe"
    if (! FileExist(SbieAgent)) {
        MsgBox(16, title, "Can't find Sandboxie installation folder. Sorry.")
        ExitApp
    }
}

;@Ahk2Exe-AddResource Resources\IconFull.ico ; Id=6
;@Ahk2Exe-AddResource Resources\IconEmpty.ico ; Id=7
if (SbieAgent == SbieCtrl) {
    SbieAgentResMain := SbieAgent
    SbieAgentResMainId := 1
    SbieAgentResMainText := "Sandboxie Control"
    SbieAgentResFull := SbieCtrl
    SbieAgentResFullId := 3
    SbieAgentResEmpty := SbieCtrl
    SbieAgentResEmptyId := 10
    if (A_IsCompiled) {
        SbieAgentResMain := SbieCtrl
        SbieAgentResMainId := 1
        SbieAgentResMainText := "Sandboxie Control"
        SbieAgentResFull := SbieCtrl
        SbieAgentResFullId := 3
        SbieAgentResEmpty := SbieCtrl
        SbieAgentResEmptyId := 10
    }
}
else {
    SbieAgentResMain := SbieAgent
    SbieAgentResMainId := 1
    SbieAgentResMainText := "Sandboxie-Plus Manager"
    SbieAgentResFull := "Resources\IconFull.ico"
    SbieAgentResFullId := 1
    SbieAgentResEmpty := "Resources\IconEmpty.ico"
    SbieAgentResEmptyId := 1
    if (A_IsCompiled) {
        SbieAgentResMain := SbieMngr
        SbieAgentResMainId := 1
        SbieAgentResMainText := "Sandboxie-Plus Manager"
        SbieAgentResFull := A_ScriptFullPath
        SbieAgentResFullId := 6
        SbieAgentResEmpty := A_ScriptFullPath
        SbieAgentResEmptyId := 7
    }
}

; find Sandboxie's INI file in %A_WinDir% and in Sandboxie's install dir
IniPathO := RegRead("HKLM\SYSTEM\CurrentControlSet\Services\SbieDrv", "IniPath") ; check custom config location in registry
IniPath := IniPathO
ini := ""
if ((IniPath != "") && (SubStr(IniPath, 1, 4) == "\??\") && (SubStr(IniPath, 8) != "") && (FileExist(SubStr(IniPath, 5)))) {
    IniPath := SubStr(IniPath, 5)
    ini := IniPath
}
else {
    IniPath := ""
    ini := sbdir . "\Sandboxie.ini"
    if (!FileExist(ini))
    {
        ini := A_WinDir . "\Sandboxie.ini"
        if (!FileExist(ini))
        {
            MsgBox(16, title, "Can't find Sandboxie.ini.")
            ExitApp
        }
    }
}
; get current Sandboxes installation bpath in the INI file.
; If it is not defined, assumes the default bpath.
sandboxes_path := IniRead(ini, "GlobalSettings", "FileRootPath", A_WinDir . "\Sandbox\`%USER`%\`%SANDBOX`%")
sandboxes_path := expandEnvVars(sandboxes_path)

; Get the map of sandboxes
sandboxes_array := getSandboxesArray(ini)

; parse command line
; If one argument is passed and it's a file or folder,
; creates a sandboxed shortcut to it on the desktop and exit
traymode := 0
singlebox := ""
singleboxmode := 0
startupfile := ""
if (A_Args.Length >= 1)
{
    mainarg := A_Args[1]
    if (SubStr(mainarg, 1, 5) == "/box:") {
        singlebox := SubStr(mainarg, 6)
        singleboxmode := 1
        if (A_Args.Length >= 2)
            mainarg := A_Args[2]
        else
            mainarg := ""
    }
    if (mainarg == "/tray") {
        traymode := 1
    } else if (mainarg == "/makeregconfig") {
        err := 0
        if (singleboxmode == 0)
            err := 1
        if (err)
            MsgBox(16, title, "Required box argument missing.`nUsage to recreate the registry config file:`n" . nameNoExt . " /box:boxname /makeregconfig`nThe box MUST be empty!")
        else
            MakeRegConfig(singlebox)
        ExitApp
    } else {
        ;Menu, Tray, NoIcon ; TODO v2
        startupfile := mainarg
    }
}
if (startupfile != "")
{
    startupfile := A_Args[1]
    startupfile := Trim(startupfile, A_Quotes)
    if (!FileExist(startupfile))
    {
        CmdLineHelp()
        ExitApp
    }
    if (singleboxmode) {
        NewShortcut(singlebox, startupfile)
        ExitApp
    }
    box := getSandboxName(sandboxes_array, "Target sandbox for shortcut:", true)
    if (box != "")
        NewShortcut(box, startupfile)

    ExitApp
}

; If the RegConfig.cfg file doesn't exist and an empty box is available,
; generate it using that empty box.
if (!FileExist(regconfig))
{
    emptybox := ""
    for b, boxdata in sandboxes_array
    {
        if (!boxdata.Enabled || boxdata.NeverDelete || boxdata.UseFileImage || boxdata.UseRamDisk) { ; Skip disabled, neverdelete, usefileimage, or useramdisk boxes
            Continue
        }

        if (!boxdata.exist)
        {
            emptybox := b
            break
        }
    }
    if (emptybox != "")
    {
        MakeRegConfig(emptybox)
        msg := "SandboxToys has generated the registry configuration file`n""" . regconfig . """`n`n"
        msg .= "That file is necessary to exclude the registry keys and values "
        msg .= "that Sandboxie needs to create in the sandbox for its own use "
        msg .= "from the output of the ""Registry List and Export"" and ""Watch "
        msg .= "Registry Changes"" functions.`n`n"
        msg .= "SandboxToys needs an EMPTY sandbox to create that file. The box "
        msg .= """" . emptybox . """ is empty, and has been used to generate the file.`n`n"
        msg .= "If you need to recreate that file, just delete the file, be sure "
        msg .= "to delete a sandbox, and launch SandboxToys again. You should see "
        msg .= "this dialog again."
        MsgBox(64, title, msg)
        RunWait(start . " /box:" . emptybox . " /terminate",, "UseErrorLevel")
        RunWait(start . " /box:" . emptybox . " delete_sandbox",, "UseErrorLevel")
    }
}

if (traymode) {
    A_TrayMenu.Delete()
    A_TrayMenu.Add("About and Help", MainHelpMenuHandler)
    setMenuIcon(A_TrayMenu, "About and Help", shell32, 24, smalliconsize)
    A_TrayMenu.Add("Exit", ExitMenuHandler)
    setMenuIcon(A_TrayMenu, "Exit", shell32, 28, smalliconsize)
    A_TrayMenu.Add()
    A_TrayMenu.Add("SandboxToys Menu", BuildMainMenu)
    setMenuIcon(A_TrayMenu, "SandboxToys Menu", SbieAgentResMain, SbieAgentResMainId, smalliconsize)
    if (trayiconfile != "") {
        if (trayiconnum == "")
            trayiconnum := 1
        try A_TrayMenu.SetIcon(trayiconfile, trayiconnum)
    }
    A_TrayMenu.Default := "SandboxToys Menu"
    A_TrayMenu.ClickCount := 1
    if (singleboxmode)
        A_TrayMenu.Tip := title . "`nBox : " . singlebox
    else
        A_TrayMenu.Tip := title
} else {
    BuildMainMenu()
    ExitApp
}

Return

; ######################################################
; No arguments, or called from tray: build the main menu
; ######################################################

BuildMainMenu(ItemName, ItemPos, MyMenu)
{
    global traymode, sandboxes_array, ini, menucommands, menuicons, numboxes, singleboxmode, singlebox, box, boxpath, boxexist, dropadminrights, benabled, boxlabel
    global SbieAgentResFull, SbieAgentResFullId, SbieAgentResEmpty, SbieAgentResEmptyId, seperatedstartmenus, public, shell32, largeiconsize, smalliconsize
    global added_menus, public_dir, idx, tmp1, topicons, numtopicons, files1, menunum, numicons, m, files2, explorerRes, imageres, regeditRes
    global A_WinDir, cmdRes, SbieAgentResMain, SbieAgentResMainId, usertoolsdir, mainmenu, SbieAgent, SbieAgentResMainText, title, includeboxnames, listemptyitems
    global SBMenuSetup, menus
    if (traymode)
    {
        sandboxes_array := getSandboxesArray(ini)
    }

    ; Init the arrays of menu commands and icons (requires AHK_L)
    menucommands := Map()
    menuicons := Map()
    menus := Map()

    menus["ST2MainMenu"] := Menu()
    menus["ST2MainMenu"].Name := "ST2MainMenu"

    ; Main loop: process all sandboxes
    numboxes := sandboxes_array.Count
    if (numboxes == 1) {
        singleboxmode := 1
        for boxname, boxdata in sandboxes_array
        {
            singlebox := boxname
            break
        }
    }

    ; Build the Main menu
    for box, boxdata in sandboxes_array
    {
        boxpath := boxdata.bpath
        boxexist := boxdata.exist
        dropadminrights := boxdata.DropAdminRights
        benabled := boxdata.Enabled
        if (!benabled) { ; Hide disabled boxes from box list
            Continue
        }

        if (boxexist) {
            boxlabel := box
        }
        else {
            boxlabel := box . " (empty)"
        }

        if (singleboxmode && box != singlebox)
            continue

        menus[box . "_ST2MenuBox"] := Menu()
        menus[box . "_ST2MenuBox"].Name := box . "_ST2MenuBox"
        menus[box . "_ST2StartMenu"] := Menu()
        menus[box . "_ST2StartMenu"].Name := box . "_ST2StartMenu"
        menus[box . "_ST2StartMenuAU"] := Menu()
        menus[box . "_ST2StartMenuAU"].Name := box . "_ST2StartMenuAU"
        menus[box . "_ST2StartMenuCU"] := Menu()
        menus[box . "_ST2StartMenuCU"].Name := box . "_ST2StartMenuCU"
        menus[box . "_ST2Desktop"] := Menu()
        menus[box . "_ST2Desktop"].Name := box . "_ST2Desktop"
        menus[box . "_ST2QuickLaunch"] := Menu()
        menus[box . "_ST2QuickLaunch"].Name := box . "_ST2QuickLaunch"
        menus[box . "_ST2MenuExplore"] := Menu()
        menus[box . "_ST2MenuExplore"].Name := box . "_ST2MenuExplore"
        menus[box . "_ST2MenuReg"] := Menu()
        menus[box . "_ST2MenuReg"].Name := box . "_ST2MenuReg"
        menus[box . "_ST2MenuTools"] := Menu()
        menus[box . "_ST2MenuTools"].Name := box . "_ST2MenuTools"
        SBMenuSetup := Menu()
        SBMenuSetup.Name := "SBMenuSetup"

        if (singleboxmode) {
            menus[singlebox . "_ST2MenuBox"].Add("Box " . boxlabel, DummyMenuHandler)
            menus[singlebox . "_ST2MenuBox"].Disable("Box " . boxlabel)
            if (boxexist) {
                setMenuIcon(menus[singlebox . "_ST2MenuBox"], "Box " . boxlabel, SbieAgentResFull, SbieAgentResFullId, smalliconsize)
            } else {
                setMenuIcon(menus[singlebox . "_ST2MenuBox"], "Box " . boxlabel, SbieAgentResEmpty, SbieAgentResEmptyId, smalliconsize)
            }
            menus[singlebox . "_ST2MenuBox"].Add()
        }

        added_menus := 0
        if (boxexist) {
            ; build bpath to the Public (All Users) directory (and removes the ":")
            public_dir := A_AllUsersProfile
            if (public_dir != "") {
                idx := InStr(public_dir, ":")
                if (idx) {
                    public_dir := substr(public_dir,1,idx-1) . substr(public_dir,idx+1)
                }
            }
            ; Build the Box / Start Menu(s)
            if (seperatedstartmenus) {
                ; get shortcut files from the All Users StartMenu (top section)
                tmp1 := boxpath . "\user\all\Microsoft\Windows\Start Menu"
                topicons := getFilenames(tmp1, 0)
                topicons := Trim(topicons, A_nl)
                Sort(topicons, "CL D`n")
                if (topicons) {
                    numtopicons := addCmdsToMenu(box, "ST2StartMenuAU", topicons)
                    menus[box . "_ST2MenuBox"].Add("Start Menu (all users)", menus[box . "_ST2StartMenuAU"])
                    setMenuIcon(menus[box . "_ST2MenuBox"], "Start Menu (all users)", shell32, 20, largeiconsize)
                    added_menus := 1
                }
                ; and from the Programs section
                tmp1 := boxpath . "\user\all\Microsoft\Windows\Start Menu\Programs"
                files1 := getFilenames(tmp1, 1)
                if (files1 && topicons)
                    menus[box . "_ST2StartMenuAU"].Add()
                menunum := 0
                numicons := buildProgramsMenu1(box, "ST2StartMenuAU", tmp1)
                if (numicons)
                    added_menus := 1
                if (topicons == "" && numicons > 0) {
                    menus[box . "_ST2MenuBox"].Add("Start Menu (all users)", menus[box . "_ST2StartMenuAU"])
                    setMenuIcon(menus[box . "_ST2MenuBox"], "Start Menu (all users)", shell32, 20, largeiconsize)
                }

                ; get shortcut files from the Current User StartMenu (top section)
                tmp1 := boxpath . "\user\current\AppData\Roaming\Microsoft\Windows\Start Menu"
                topicons := getFilenames(tmp1, 0)
                topicons := Trim(topicons, A_nl)
                Sort(topicons, "CL D`n")
                if (topicons) {
                    numtopicons := addCmdsToMenu(box, "ST2StartMenuCU", topicons)
                    menus[box . "_ST2MenuBox"].Add("Start Menu (current user)", menus[box . "_ST2StartMenuCU"])
                    setMenuIcon(menus[box . "_ST2MenuBox"], "Start Menu (current user)", shell32, 20, largeiconsize)
                    added_menus := 1
                }
                ; and from the Programs section
                tmp1 := boxpath . "\user\current\AppData\Roaming\Microsoft\Windows\Start Menu\Programs"
                files1 := getFilenames(tmp1, 1)
                if (files1 && topicons)
                    menus[box . "_ST2StartMenuCU"].Add()
                menunum := 0
                numicons := buildProgramsMenu1(box, "ST2StartMenuCU", tmp1)
                if (numicons)
                    added_menus := 1
                if (topicons == "" && numicons > 0) {
                    menus[box . "_ST2MenuBox"].Add("Start Menu (current user)", menus[box . "_ST2StartMenuCU"])
                    setMenuIcon(menus[box . "_ST2MenuBox"], "Start Menu (current user)", shell32, 20, largeiconsize)
                }

                ; process Public Desktop
                tmp1 := boxpath . "\drive\" . public_dir . "\Desktop"
                menunum := 0
                m := buildProgramsMenu1(box, "ST2DesktopAU", tmp1)
                if (m) {
                    added_menus := 1
                    menus[box . "_ST2MenuBox"].Add("Desktop (all users)", menus[box . "_" . m])
                    setMenuIcon(menus[box . "_ST2MenuBox"], "Desktop (all users)", shell32, 35, largeiconsize)
                }
                ; process User's Desktop
                tmp1 := boxpath . "\user\current\Desktop"
                menunum := 0
                m := buildProgramsMenu1(box, "ST2DesktopCU", tmp1)
                if (m) {
                    added_menus := 1
                    menus[box . "_ST2MenuBox"].Add("Desktop (current user)", menus[box . "_" . m])
                    setMenuIcon(menus[box . "_ST2MenuBox"], "Desktop (current user)", shell32, 35, largeiconsize)
                }
            } else {
                ; get shortcut files from the StartMenu (top section)
                tmp1 := boxpath . "\user\all\Microsoft\Windows\Start Menu"
                files1 := getFilenames(tmp1, 0)
                tmp2 := boxpath . "\user\current\AppData\Roaming\Microsoft\Windows\Start Menu"
                files2 := getFilenames(tmp2, 0)
                topicons := files1 . "`n" . files2
                topicons := Trim(topicons, A_nl)
                Sort(topicons, "CL D`n")
                if (topicons) {
                    numtopicons := addCmdsToMenu(box, "ST2StartMenu", topicons)
                    menus[box . "_ST2MenuBox"].Add("Start Menu", menus[box . "_ST2StartMenu"])
                    setMenuIcon(menus[box . "_ST2MenuBox"], "Start Menu", shell32, 20, largeiconsize)
                    added_menus := 1
                }
                ; and from the Programs section
                tmp1 := boxpath . "\user\all\Microsoft\Windows\Start Menu\Programs"
                files1 := getFilenames(tmp1, 1)
                tmp2 := boxpath . "\user\current\AppData\Roaming\Microsoft\Windows\Start Menu\Programs"
                files2 := getFilenames(tmp2, 1)
                if ((files1 || files2) && topicons)
                    menus[box . "_ST2StartMenu"].Add()
                menunum := 0
                numicons := buildProgramsMenu2(box, "ST2StartMenu", tmp1, tmp2)
                if (numicons)
                    added_menus := 1
                if (topicons == "" && numicons > 0) {
                    menus[box . "_ST2MenuBox"].Add("Start Menu", menus[box . "_ST2StartMenu"])
                    setMenuIcon(menus[box . "_ST2MenuBox"], "Start Menu", shell32, 20, largeiconsize)
                }

                ; process Desktop
                tmp1 := boxpath . "\drive\" . public_dir . "\Desktop"
                files1 := getFilenames(tmp1, 1)
                tmp2 := boxpath . "\user\current\Desktop"
                files2 := getFilenames(tmp2, 1)
                if ((files1 || files2) && topicons)
                    menus[box . "_ST2MenuBox"].Add()
                menunum := 0
                m := buildProgramsMenu2(box, "ST2Desktop", tmp1, tmp2)
                if (m) {
                    added_menus := 1
                    menus[box . "_ST2MenuBox"].Add("Desktop", menus[box . "_" . m])
                    setMenuIcon(menus[box . "_ST2MenuBox"], "Desktop", shell32, 35, largeiconsize)
                }
            }

            ; process QuickLaunch
            tmp1 := boxpath . "\user\current\AppData\Roaming\Microsoft\Internet Explorer\Quick Launch"
            menunum := 0
            m := buildProgramsMenu1(box, "ST2QuickLaunch", tmp1)
            if (m) {
                added_menus := 1
                menus[box . "_ST2MenuBox"].Add("QuickLaunch", menus[box . "_" . m])
                setMenuIcon(menus[box . "_ST2MenuBox"], "QuickLaunch", shell32, 215, largeiconsize)
            }
            if (added_menus)
                menus[box . "_ST2MenuBox"].Add()
        }

        ; add Sandboxie's start menu and run dialog in all boxes
        menus[box . "_ST2MenuBox"].Add("Sandboxie's Start Menu", StartMenuMenuHandler)
        setMenuIcon(menus[box . "_ST2MenuBox"], "Sandboxie's Start Menu", SbieAgentResMain, SbieAgentResMainId, largeiconsize)
        menus[box . "_ST2MenuBox"].Add("Sandboxie's Run Dialog", RunDialogMenuHandler)
        setMenuIcon(menus[box . "_ST2MenuBox"], "Sandboxie's Run Dialog", SbieAgentResMain, SbieAgentResMainId, largeiconsize)
        menus[box . "_ST2MenuBox"].Add()
        if (NOT boxexist) {
            menus[box . "_ST2MenuBox"].Add("Explore (Sandboxed)", SExploreMenuHandler)
            setMenuIcon(menus[box . "_ST2MenuBox"], "Explore (Sandboxed)", explorerRes, 1, largeiconsize)
            menus[box . "_ST2MenuBox"].Add("New Sandboxed Shortcut", NewShortcutMenuHandler)
            setMenuIcon(menus[box . "_ST2MenuBox"], "New Sandboxed Shortcut", imageres, 155, largeiconsize)
        }
        if (boxexist) {
            ; Add the Explore items to the Box menu
            menus[box . "_ST2MenuExplore"].Add("Unsandboxed", UExploreMenuHandler)
            setMenuIcon(menus[box . "_ST2MenuExplore"], "Unsandboxed", explorerRes, 1, smalliconsize)
            menus[box . "_ST2MenuExplore"].Add("Unsandboxed, restricted", URExploreMenuHandler)
            setMenuIcon(menus[box . "_ST2MenuExplore"], "Unsandboxed, restricted", explorerRes, 1, smalliconsize)
            menus[box . "_ST2MenuExplore"].Add("Sandboxed", SExploreMenuHandler)
            setMenuIcon(menus[box . "_ST2MenuExplore"], "Sandboxed", explorerRes, 1, smalliconsize)
            menus[box . "_ST2MenuExplore"].Add()
            menus[box . "_ST2MenuExplore"].Add("Files List and Export", ListFilesMenuHandler)
            setMenuIcon(menus[box . "_ST2MenuExplore"], "Files List and Export", shell32, 172, smalliconsize)
            menus[box . "_ST2MenuExplore"].Add("Watch Files Changes", WatchFilesMenuHandler)
            setMenuIcon(menus[box . "_ST2MenuExplore"], "Watch Files Changes", shell32, 172, smalliconsize)
            menus[box . "_ST2MenuBox"].Add("Explore", menus[box . "_ST2MenuExplore"])
            setMenuIcon(menus[box . "_ST2MenuBox"], "Explore", explorerRes, 1, largeiconsize)

            ; Add the Registry items to the Box menu
            menus[box . "_ST2MenuReg"].Add("Registry Editor (unsandboxed)", URegEditMenuHandler)
            setMenuIcon(menus[box . "_ST2MenuReg"], "Registry Editor (unsandboxed)", regeditRes, 1, smalliconsize)
            if (NOT dropadminrights) {
                menus[box . "_ST2MenuReg"].Add("Registry Editor (sandboxed)", SRegEditMenuHandler)
                setMenuIcon(menus[box . "_ST2MenuReg"], "Registry Editor (sandboxed)", regeditRes, 1, smalliconsize)
            }
            menus[box . "_ST2MenuReg"].Add()
            menus[box . "_ST2MenuReg"].Add("Registry List and Export", ListRegMenuHandler)
            setMenuIcon(menus[box . "_ST2MenuReg"], "Registry List and Export", regeditRes, 3, smalliconsize)
            menus[box . "_ST2MenuReg"].Add("Watch Registry Changes", WatchRegMenuHandler)
            setMenuIcon(menus[box . "_ST2MenuReg"], "Watch Registry Changes", regeditRes, 3, smalliconsize)
            menus[box . "_ST2MenuBox"].Add("Registry", menus[box . "_ST2MenuReg"])
            setMenuIcon(menus[box . "_ST2MenuBox"], "Registry", regeditRes, 1, largeiconsize)
            menus[box . "_ST2MenuReg"].Add()
            menus[box . "_ST2MenuReg"].Add("Autostart programs in registry", ListAutostartsMenuHandler)
            setMenuIcon(menus[box . "_ST2MenuReg"], "Autostart programs in registry", regeditRes, 2, smalliconsize)

            ; Build the Tools menu
            menus[box . "_ST2MenuTools"].Add("New Sandboxed Shortcut", NewShortcutMenuHandler)
            setMenuIcon(menus[box . "_ST2MenuTools"], "New Sandboxed Shortcut", imageres, 155, smalliconsize)
            menus[box . "_ST2MenuTools"].Add()
            menus[box . "_ST2MenuTools"].Add("Watch Files and Registry Changes", WatchFilesRegMenuHandler)
            setMenuIcon(menus[box . "_ST2MenuTools"], "Watch Files and Registry Changes", shell32, 172, smalliconsize)
            menus[box . "_ST2MenuTools"].Add()
            menus[box . "_ST2MenuTools"].Add("Command Prompt (unsandboxed)", UCmdMenuHandler)
            setMenuIcon(menus[box . "_ST2MenuTools"], "Command Prompt (unsandboxed)", cmdRes, 1, smalliconsize)
            menus[box . "_ST2MenuTools"].Add("Command Prompt (sandboxed)", SCmdMenuHandler)
            setMenuIcon(menus[box . "_ST2MenuTools"], "Command Prompt (sandboxed)", cmdRes, 1, smalliconsize)
            if (NOT dropadminrights) {
                menus[box . "_ST2MenuTools"].Add()
                menus[box . "_ST2MenuTools"].Add("Programs and Features", UninstallMenuHandler)
                setMenuIcon(menus[box . "_ST2MenuTools"], "Programs and Features", A_WinDir . "\system32\appmgr.dll", 1, smalliconsize)
            }
            menus[box . "_ST2MenuTools"].Add()
            menus[box . "_ST2MenuTools"].Add("Terminate Sandboxed Programs!", TerminateMenuHandler)
            setMenuIcon(menus[box . "_ST2MenuTools"], "Terminate Sandboxed Programs!", shell32, 220, smalliconsize)
            menus[box . "_ST2MenuTools"].Add("Delete Sandbox!", DeleteBoxMenuHandler)
            setMenuIcon(menus[box . "_ST2MenuTools"], "Delete Sandbox!", shell32, 132, smalliconsize)
            menus[box . "_ST2MenuBox"].Add("Tools", menus[box . "_ST2MenuTools"])
            setMenuIcon(menus[box . "_ST2MenuBox"], "Tools", shell32, 36, largeiconsize)
        }

        ; Build the Main menu
        if (!singleboxmode) {
            menus["ST2MainMenu"].Add(boxlabel, menus[box . "_ST2MenuBox"])
            if (boxexist) {
                setMenuIcon(menus["ST2MainMenu"], boxlabel, SbieAgentResFull, SbieAgentResFullId, largeiconsize)
            } else {
                setMenuIcon(menus["ST2MainMenu"], boxlabel, SbieAgentResEmpty, SbieAgentResEmptyId, largeiconsize)
            }
        }
    }

    if (singleboxmode)
        mainmenu_obj := menus[singlebox . "_ST2MenuBox"]
    else
        mainmenu_obj := menus["ST2MainMenu"]

    ; process User Tools
    menunum := 0
    m := buildProgramsMenu1("", "ST2UserTools", usertoolsdir)
    if (m) {
        mainmenu_obj.Add()
        mainmenu_obj.Add("User Tools", menus["_" . m])
        setMenuIcon(mainmenu_obj, "User Tools", imageres, 118, largeiconsize)
    }

    ; add Launch Sandboxie Agent if it is not already running
    if InStr(SbieAgent, "SandMan")
    {
        if !ProcessExist("SandMan.exe") {
            mainmenu_obj.Add()
            mainmenu_obj.Add("Launch " . SbieAgentResMainText, LaunchSbieAgentMenuHandler)
            setMenuIcon(mainmenu_obj, "Launch " . SbieAgentResMainText, SbieAgentResMain, SbieAgentResMainId, largeiconsize)
        }
    }

    if InStr(SbieAgent, "SbieCtrl")
    {
        if !ProcessExist("SbieCtrl.exe") {
            mainmenu_obj.Add()
            mainmenu_obj.Add("Launch " . SbieAgentResMainText, LaunchSbieAgentMenuHandler)
            setMenuIcon(mainmenu_obj, "Launch " . SbieAgentResMainText, SbieAgentResMain, SbieAgentResMainId, largeiconsize)
        }
    }

    ; add Help & Options menu
    SBMenuSetup.Add("About and Help", MainHelpMenuHandler)
    setMenuIcon(SBMenuSetup, "About and Help", shell32, 24, 16)
    SBMenuSetup.Add()
    SBMenuSetup.Add("Large main-menu and box icons?", SetupMenuMenuHandler1)
    if (largeiconsize > 16)
        SBMenuSetup.Check("Large main-menu and box icons?")
    SBMenuSetup.Add("Large sub-menu icons?", SetupMenuMenuHandler2)
    if (smalliconsize > 16)
        SBMenuSetup.Check("Large sub-menu icons?")
    SBMenuSetup.Add("Seperated All Users menus?", SetupMenuMenuHandler3)
    if (seperatedstartmenus)
        SBMenuSetup.Check("Seperated All Users menus?")
    SBMenuSetup.Add()
    SBMenuSetup.Add("Include [#BoxName] in shortcut names?", SetupMenuMenuHandler4)
    if (includeboxnames)
        SBMenuSetup.Check("Include [#BoxName] in shortcut names?")
    SBMenuSetup.Add()
    SBMenuSetup.Add("List empty folders and keys?", SetupMenuMenuHandler5)
    if (listemptyitems)
        SBMenuSetup.Check("List empty folders and keys?")
    mainmenu_obj.Add()
    mainmenu_obj.Add("Options", SBMenuSetup)
    setMenuIcon(mainmenu_obj, "Options", shell32, 24, 16)

    ; show the menu and wait for user action
    mainmenu_obj.Show()
}

; ###################################################################################################
; Functions
; ###################################################################################################

; get sandbox names, paths and properties from Sandboxie's INI file
; and from the current state of the sandboxes.
; Returns a Map of sandboxes, where each key is the box name and the value is a Map of properties.
getSandboxesArray(iniFile)
{
    sandboxes_map := Map()
    sandboxes_path_template := IniRead(iniFile, "GlobalSettings", "FileRootPath", A_WinDir . "\Sandbox\`%USER`%\`%SANDBOX`%")
    sandboxeskey_path_template := IniRead(iniFile, "GlobalSettings", "KeyRootPath", "\REGISTRY\USER\Sandbox_`%USER`%_`%SANDBOX`%")

    file := FileOpen(iniFile, "r", "UTF-16")
    if !IsObject(file)
    {
        MsgBox("Failed to open " . iniFile)
        return
    }

    boxes_list := []
    while !file.AtEOF
    {
        line := file.ReadLine()
        if (SubStr(line, 1, 1) == "[" && SubStr(line, -0) == "]" && line != "[GlobalSettings]" && SubStr(line, 1, 14) != "[UserSettings_" && SubStr(line, 1, 10) != "[Template_" && line != "[TemplateSettings]") {
            boxes_list.Push(SubStr(line, 2, -1))
        }
    }
    file.Close()
    boxes_list.Sort("CL")

    for _, boxname in boxes_list
    {
        box_data := Map()
        box_data.name := boxname

        current_sandboxes_path := IniRead(iniFile, boxname, "FileRootPath", sandboxes_path_template)
        box_data.FileRootPath := current_sandboxes_path
        expanded_path := expandEnvVars(current_sandboxes_path)
        box_data.bpath := StrReplace(expanded_path, "`%SANDBOX`%", boxname)

        current_sandboxeskey_path := IniRead(iniFile, boxname, "KeyRootPath", sandboxeskey_path_template)
        box_data.KeyRootPath := current_sandboxeskey_path
        expanded_key_path := expandEnvVars(current_sandboxeskey_path)
        box_data.bkey := StrReplace(expanded_key_path, "`%SANDBOX`%", boxname)

        bkeyrootpathR := StrReplace(current_sandboxeskey_path, A_UserName, "`%USER`%")
        regspos := InStr(bkeyrootpathR, "\",, 0)
        regepos := InStr(bkeyrootpathR, "%")
        box_data.RegStr_ := SubStr(bkeyrootpathR, regspos + 1, regepos - regspos - 2)

        box_data.exist := DirExist(box_data.bpath) && FileExist(box_data.bpath . "\RegHive")

        box_data.DropAdminRights := IniRead(iniFile, boxname, "DropAdminRights", "n") == "y"
        box_data.Enabled := IniRead(iniFile, boxname, "Enabled", "y") != "n"
        box_data.NeverDelete := IniRead(iniFile, boxname, "NeverDelete", "n") == "y"
        box_data.UseFileImage := IniRead(iniFile, boxname, "UseFileImage", "n") == "y"
        box_data.UseRamDisk := IniRead(iniFile, boxname, "UseRamDisk", "n") == "y"

        sandboxes_map[boxname] := box_data
    }
    Return sandboxes_map
}

; Prompts the user for a sandbox name.
; Returns "" if the user selects cancel or discard the menu.
getSandboxName(sandboxes_map, title, include_ask := false) {
    global SbieAgentResFull, SbieAgentResFullId, SbieAgentResEmpty, SbieAgentResEmptyId, SbieAgentResMain, SbieAgentResMainId, largeiconsize

    boxMenu := Menu()
    boxMenu.Add(title, (*) => {})
    boxMenu.Disable(title)
    boxMenu.Add()

    handler := getSandboxName_ClickHandler
    boxMenu.OnEvent("Click", handler)

    for boxname, boxdata in sandboxes_map {
        local menuText := boxname
        if !boxdata.exist {
            menuText .= " (empty)"
        }

        boxMenu.Add(menuText)

        if boxdata.exist {
            setMenuIcon(boxMenu, menuText, SbieAgentResFull, SbieAgentResFullId, largeiconsize)
        } else {
            setMenuIcon(boxMenu, menuText, SbieAgentResEmpty, SbieAgentResEmptyId, largeiconsize)
        }
    }

    if include_ask {
        boxMenu.Add()
        boxMenu.Add("Ask box at run time")
        setMenuIcon(boxMenu, "Ask box at run time", SbieAgentResMain, SbieAgentResMainId, largeiconsize)
    }

    boxMenu.Add()
    boxMenu.Add("Cancel")

    global __selected_box__
    __selected_box__ := unset
    boxMenu.Show()

    while __selected_box__ == unset
        Sleep 100

    local retVal := __selected_box__
    __selected_box__ := unset ; reset for next call
    return retVal
}

getSandboxName_ClickHandler(menu, item, *) {
    global __selected_box__
    if (item == "Cancel")
        __selected_box__ := ""
    else if (item == "Ask box at run time")
        __selected_box__ := "__ask__"
    else if (item != "")
        __selected_box__ := Trim(item, " (empty)")
}

setMenuIcon(menuObj, item, iconfile, iconindex, iconsize)
{
    try {
        menuObj.SetIcon(item, iconfile, iconindex, iconsize)
        return 0
    } catch {
        return 1
    }
}

getFilenames(directory, includeFolders)
{
    local files := []
    local loopMode := ""
    if (includeFolders == 0)
        loopMode := "F"
    else if (includeFolders == 1)
        loopMode := "FD"
    else if (includeFolders == 2)
        loopMode := "D"

    Loop Files, directory . "\*", loopMode
    {
        ; Excludes the hidden and system files from list
        if InStr(A_LoopFileAttrib, "H") or InStr(A_LoopFileAttrib, "S")
            Continue
        ; Excludes also the files deleted in the sandbox, but present in the "real world".
        ; They have a "magic" creation date of May 23, 1986, 17:47:02
        if (FileGetTime(A_LoopFileLongPath, "C") == "19860523174702")
            Continue
        ; and keep regular directories and files
        if InStr(A_LoopFileAttrib, "D")
        {
            SplitPath(A_LoopFileName, &OutDirName)
            files.Push(OutDirName . ":" . A_LoopFileLongPath)
        } else {
            SplitPath(A_LoopFileName, , , , &OutNameNoExt)
            files.Push(OutNameNoExt . ":" . A_LoopFileLongPath)
        }
    }
    if (files.Length > 0) {
        files.Sort("CL")
        return files.Join("`n")
    }
    Return ""
}

; Build a menu with the files from a specific directory
buildProgramsMenu1(box, menuname, bpath)
{
    global smalliconsize, menunum, menus, shell32

    if (menunum > 0)
        thismenuname := menuname . "_" . menunum
    else
        thismenuname := menuname

    if (!menus.Has(box . "_" . thismenuname))
        menus[box . "_" . thismenuname] := Menu()
    thismenu := menus[box . "_" . thismenuname]

    numfiles := 0

    menufiles := getFilenames(bpath, 0)
    if (menufiles) {
        numfiles += addCmdsToMenu(box, thismenu, menufiles)
    }

    menudirs := getFilenames(bpath, 2)
    if (menudirs) {
        for _, entry in StrSplit(menudirs, "`n")
        {
            idx := InStr(entry, ":")
            label := SubStr(entry, 1, idx-1)
            dir := SubStr(entry, idx+1)
            menunum++
            newmenuname := buildProgramsMenu1(box, menuname, dir)
            if (newmenuname != "") {
                thismenu.Add(label, menus[box . "_" . newmenuname])
                setMenuIcon(thismenu, label, shell32, 4, smalliconsize)
                numfiles++
            }
        }
    }
    if (numfiles > 0)
        return thismenuname
    else
        return ""
}

; Build a menu with the files from two specific directories by merging them together
buildProgramsMenu2(box, menuname, path1, path2)
{
    global smalliconsize, menunum, menus, shell32
    A_Return := "`n"

    if (menunum > 0)
        thismenuname := menuname . "_" . menunum
    else
        thismenuname := menuname

    if (!menus.Has(box . "_" . thismenuname))
        menus[box . "_" . thismenuname] := Menu()
    thismenu := menus[box . "_" . thismenuname]

    numfiles := 0

    ; process files
    menufiles1 := getFilenames(path1, 0)
    menufiles2 := getFilenames(path2, 0)
    menufiles := menufiles1 . "`n" . menufiles2
    menufiles := Trim(menufiles, A_Return)
    if (menufiles) {
        local file_array := StrSplit(menufiles, "`n")
        file_array.Sort("CL")
        menufiles := file_array.Join("`n")
        numfiles += addCmdsToMenu(box, thismenu, menufiles)
    }

    ; recurse
    menudirs1 := getFilenames(path1, 2)
    menudirs2 := getFilenames(path2, 2)
    menudirsStr := menudirs1 . "`n" . menudirs2
    menudirsStr := Trim(menudirsStr, A_Return)
    if (menudirsStr) {
        dirMap := Map()
        for _, entry in StrSplit(menudirsStr, "`n")
        {
            idx := InStr(entry, ":")
            label := SubStr(entry, 1, idx-1)
            dir := SubStr(entry, idx+1)
            if (dirMap.Has(label))
                dirMap[label].Push(dir)
            else
                dirMap[label] := [dir]
        }

        sortedLabels := []
        for label in dirMap.OwnProps()
            sortedLabels.Push(label)
        sortedLabels.Sort("CL")

        for _, label in sortedLabels
        {
            dirs := dirMap[label]
            menunum++
            newmenuname := ""
            if (dirs.Length == 1) {
                newmenuname := buildProgramsMenu1(box, menuname, dirs[1])
            } else {
                newmenuname := buildProgramsMenu2(box, menuname, dirs[1], dirs[2])
            }

            if (newmenuname != "") {
                thismenu.Add(label, menus[box . "_" . newmenuname])
                setMenuIcon(thismenu, label, shell32, 4, smalliconsize)
                numfiles++
            }
        }
    }
    if (numfiles > 0)
        return thismenuname
    else
        return ""
}

; TODO: rewrite this stuff, too complicated
setIconFromSandboxedShortcut(box, shortcut, menuObj, label, iconsize)
{
    global menuicons, imageres, sandboxes_array, shell32
    A_Quotes := """"

    bregstr_ := sandboxes_array[box].KeyRootPath
    bregstr_ := StrReplace(StrReplace(SubStr(bregstr_, 16), '`%SANDBOX`%', box), '`%USER`%', A_UserName)

    if !menuicons.Has(menuObj.Name)
        menuicons[menuObj.Name] := Map()
    if !menuicons[menuObj.Name].Has(label)
        menuicons[menuObj.Name][label] := Map()

    menuicons[menuObj.Name][label]["file"] := ""
    menuicons[menuObj.Name][label]["num"] := ""

    ; get icon file and number in shortcut.
    ; If not specified, assumes it's the file pointed to by the shortcut
    SplitPath(shortcut, , , &extension)
    local target, iconfile, iconnum
    if (extension == "lnk") {
        FileGetShortcut(shortcut, &target, , , , &iconfile, &iconnum)
        if (iconnum == "")
            iconnum := 1
        if (iconfile == "") {
            iconfile := target
            iconnum := 1
        }
    } else {
        iconfile := shortcut
        iconnum := 1
    }
    iconfile := Trim(iconfile, A_Quotes)
    iconfile := expandEnvVars(iconfile)

    if (DirExist(iconfile)) {
        setMenuIcon(menuObj, label, imageres, 4, iconsize)
        menuicons[menuObj.Name][label]["file"] := imageres
        menuicons[menuObj.Name][label]["num"] := 4
        return imageres . "," . 4
    }

    boxfile := stdPathToBoxPath(box, iconfile)
    if (DirExist(boxfile)) {
        setMenuIcon(menuObj, label, imageres, 4, iconsize)
        menuicons[menuObj.Name][label]["file"] := imageres
        menuicons[menuObj.Name][label]["num"] := 4
        return imageres . "," . 4
    }
    if (FileExist(boxfile)) {
        iconfile := boxfile
    }

    rc := 1
    if (iconfile != "") {
        rc := setMenuIcon(menuObj, label, iconfile, iconnum, iconsize)
        menuicons[menuObj.Name][label]["file"] := iconfile
        menuicons[menuObj.Name][label]["num"] := iconnum
    }

    if (rc) {
        ; If setMenuIcon failed, it's probably because the file pointed to by
        ; the link is a document without icons.
        ; Try to get the right icon reference in the registry.

        if (extension == "lnk") {
            SplitPath(target, , , &extension)
        } else {
            SplitPath(shortcut, , , &extension)
        }
        ; try to get the icon from the sandboxed registry first
        ; (will fail is nothing is running in the sandbox)
        local defaulticon := ""
        try defaulticon := RegRead("HKEY_USERS\" . bregstr_ . "\machine\software\classes\." . extension . "\DefaultIcon")
        catch {
            try {
                keyval := RegRead("HKEY_USERS\" . bregstr_ . "\machine\software\classes\." . extension)
                if (keyval != "") {
                    try defaulticon := RegRead("HKEY_USERS\" . bregstr_ . "\machine\software\classes\" . keyval . "\DefaultIcon")
                }
            }
        }

        if (defaulticon != "") {
            comaidx := InStr(defaulticon, ",", false, 0)
            if (comaidx > 0) {
                iconfile := SubStr(defaulticon, 1, comaidx-1)
                iconnum := SubStr(defaulticon, comaidx+1)
            } else {
                iconfile := defaulticon
                iconnum := 1
            }
            if (iconnum > 0) {
                iconfile := Trim(iconfile, A_Quotes)
                iconfile := expandEnvVars(iconfile)
                iconfile := stdPathToBoxPath(box, iconfile)
                rc := setMenuIcon(menuObj, label, iconfile, iconnum, iconsize)
                menuicons[menuObj.Name][label]["file"] := iconfile
                menuicons[menuObj.Name][label]["num"] := iconnum
            } else
                rc := 1
            if (rc == 0)
                return iconfile . "," . iconnum
        }

        ; searches also in the unsandboxed registry
        try defaulticon := RegRead("HKEY_CLASSES_ROOT", "." . extension . "\DefaultIcon")
        catch {
            try {
                keyval := RegRead("HKEY_CLASSES_ROOT", "." . extension)
                if (keyval == "InternetShortcut") {
                    defaulticon := A_WinDir . "\system32\url.dll,5"
                } else if (keyval != "") {
                    try defaulticon := RegRead("HKEY_CLASSES_ROOT", keyval . "\DefaultIcon")
                }
            }
        }
        if (defaulticon == "") {
            local percievedtype := ""
            try percievedtype := RegRead("HKEY_CLASSES_ROOT", "." . extension, "PerceivedType")
            catch {
                try {
                    keyval := RegRead("HKEY_CLASSES_ROOT", "." . extension)
                    if (keyval != "") {
                        try percievedtype := RegRead("HKEY_CLASSES_ROOT", keyval, "PerceivedType")
                    }
                }
            }
            if (percievedtype == "document") {
                defaulticon := imageres . ",2"
            } else if (percievedtype == "system") {
                defaulticon := imageres . ",63"
            } else if (percievedtype == "text") {
                defaulticon := imageres . ",97"
            } else if (percievedtype == "audio") {
                defaulticon := imageres . ",125"
            } else if (percievedtype == "image") {
                defaulticon := imageres . ",126"
            } else if (percievedtype == "video") {
                defaulticon := imageres . ",127"
            } else if (percievedtype == "compressed") {
                defaulticon := imageres . ",165"
            }
        }
        if (defaulticon != "") {
            if (defaulticon == "%1") {
                iconfile := shortcut
                iconnum := 1
            } else {
                comaidx := InStr(defaulticon, ",", false, 0)
                if (comaidx > 0) {
                    iconfile := SubStr(defaulticon, 1, comaidx-1)
                    iconnum := SubStr(defaulticon, comaidx+1)
                    if (iconnum < 0) {
                        iconnum := IndexOfIconResource(iconfile, iconnum)
                    } else {
                        iconnum++
                    }
                }
            }
            iconfile := Trim(iconfile, A_Quotes)
            rc := setMenuIcon(menuObj, label, iconfile, iconnum, iconsize)
            menuicons[menuObj.Name][label]["file"] := iconfile
            menuicons[menuObj.Name][label]["num"] := iconnum
        } else
            rc := 1
        if (rc) {
            if (InStr(defaulticon, "%programfiles%")) {
                iconfile := StrReplace(iconfile, '`%programfiles`%', A_ProgramFiles)
                rc := setMenuIcon(menuObj, label, iconfile, iconnum, iconsize)
                menuicons[menuObj.Name][label]["file"] := iconfile
                menuicons[menuObj.Name][label]["num"] := iconnum
            }
            if (rc) {
                iconfile := StrReplace(iconfile, '`%programfiles`%', A_ProgramFilesX86)
                rc := setMenuIcon(menuObj, label, iconfile, iconnum, iconsize)
                menuicons[menuObj.Name][label]["file"] := iconfile
                menuicons[menuObj.Name][label]["num"] := iconnum
            }
            if (rc) {
                iconfile := expandEnvVars(iconfile)
                rc := setMenuIcon(menuObj, label, iconfile, iconnum, iconsize)
                menuicons[menuObj.Name][label]["file"] := iconfile
                menuicons[menuObj.Name][label]["num"] := iconnum
            }
        }
        if (rc || iconfile == "") {
            iconfile := shell32
            iconfile := expandEnvVars(iconfile)
            if (extension == "exe")
                iconnum := 3
            else
                iconnum := 2
            rc := setMenuIcon(menuObj, label, iconfile, iconnum, iconsize)
            menuicons[menuObj.Name][label]["file"] := iconfile
            menuicons[menuObj.Name][label]["num"] := iconnum
        }
    }
    return iconfile . "," . iconnum
}

; Retrieve the icon number from its resource TD (negative index).
; Assumes the order of the icon resources defines the icon indices.
IndexOfIconResource(Filename, ID)
{
    A_Quotes := """"
    Filename := Trim(Filename, A_Quotes)
    Filename := expandEnvVars(Filename)
    ID := Abs(ID)
    hmod := DllCall("GetModuleHandle", "str", Filename)
    ; If the DLL isn't already loaded, load it as a data file.
    loaded := !hmod && (hmod := DllCall("LoadLibraryEx", "str", Filename, "ptr", 0, "uint", 0x2))

    enumproc := CallbackCreate(IndexOfIconResource_EnumIconResources, "F")
    param := Buffer(12, 0)
    NumPut("int", ID, param, 0)
    ; Enumerate the icon group resources. (RT_GROUP_ICON=14)
    DllCall("EnumResourceNames", "ptr", hmod, "uint", 14, "ptr", enumproc, "ptr", param.Ptr)
    CallbackFree(enumproc)

    ; If we loaded the DLL, free it now.
    if loaded
        DllCall("FreeLibrary", "ptr", hmod)

    return NumGet(param, 8, "int") ? NumGet(param, 4, "int") : 0
}
IndexOfIconResource_EnumIconResources(hModule, lpszType, lpszName, lParam)
{
    NumPut("int", NumGet(lParam+4, "int")+1, lParam+4)

    if (lpszName == NumGet(lParam+0, "int"))
    {
        NumPut("int", 1, lParam+8)
        return false ; break
    }
    return true
}

GetAssociatedIcon(File, hideshortcutoverlay = true, iconsize = 16, box = "", deleted = 0)
{
    static sfi, iconCache := Map()
    local sfi_size := 352
    local hIcon, Ext, Fileto, FileIcon, FileIconNum
    local programsx86 := EnvGet("ProgramFiles(x86)")
    if !IsSet(sfi)
        sfi := Buffer(sfi_size)

    local cacheKey := File . "|" . hideshortcutoverlay . "|" . iconsize . "|" . box . "|" . deleted
    if iconCache.Has(cacheKey)
        return iconCache[cacheKey]

    SplitPath(File, , , &Ext)
    if (Ext == "LNK")
    {
        FileGetShortcut(File, &Fileto, , , , &FileIcon, &FileIconNum)
        if (hideshortcutoverlay) {
            if (FileIcon) {
                hIcon := MI_ExtractIcon(FileIcon, FileIconNum, iconsize)
                if (hIcon) {
                    iconCache[cacheKey] := hIcon
                    return hIcon
                }
            } else {
                File := Fileto
                SplitPath(File, , , &Ext)
            }
        } else {
            if (!FileExist(FileTo))
            {
                local tmpboxfile := stdPathToBoxPath(box, FileTo)
                if (FileExist(tmpboxfile))
                    FileTo := tmpboxfile
            }
            if (!FileExist(FileTo))
                FileTo := StrReplace(FileTo, programsx86, A_ProgramFiles)
            local attrs := 0x8101
            if (deleted)
                attrs += 0x10000
            if (DllCall("Shell32\SHGetFileInfoW", "wstr", FileTo, "uint", 0, "ptr", sfi.ptr, "uint", sfi_size, "uint", attrs))
            {
                hIcon := NumGet(sfi, 0, "ptr")
                iconCache[cacheKey] := hIcon
                return hIcon
            }
        }
    }

    if (!FileExist(File))
        File := StrReplace(File, programsx86, A_ProgramFiles)

    local attrs := 0x101
    if (deleted)
        attrs += 0x10000
    if (DllCall("Shell32\SHGetFileInfoW", "wstr", File, "uint", 0, "ptr", sfi.ptr, "uint", sfi_size, "uint", attrs))
    {
        hIcon := NumGet(sfi, 0, "ptr")
    } else {
        hIcon := 0
    }
    iconCache[cacheKey] := hIcon
    return hIcon
}

MI_SetMenuItemIcon(MenuNameOrHandle, ItemPos, h_icon, IconSize=0)
{
    local loaded_icon := 0
    local h_menu
    if MenuNameOrHandle is Integer
        h_menu := MenuNameOrHandle
    else
        h_menu := MI_GetMenuHandle(MenuNameOrHandle)

    if !h_menu
        return false

    h_icon := DllCall("CopyImage","ptr",h_icon,"uint",1
        ,"int",IconSize,"int",IconSize,"uint",0)

    ; Get the previous bitmap or icon handle.
    local mii := Buffer(48, 0)
    NumPut("uint", 48, mii)
    NumPut("uint", 0xA0, mii, 4)
    local h_previous := 0
    if DllCall("GetMenuItemInfo","ptr",h_menu,"uint",ItemPos-1,"int",1,"ptr",mii.ptr)
        h_previous := NumGet(mii,44,"ptr")

    h_bitmap := MI_GetBitmapFromIcon32Bit(h_icon, IconSize, IconSize)

    if IsSet(loaded_icon) && loaded_icon
    {
        DllCall("DestroyIcon","ptr",loaded_icon)
        loaded_icon := 0
    }

    if !h_bitmap
        return false

    NumPut("uint", 0x80, mii, 4) ; fMask: Set hbmpItem only, not dwItemData.
    NumPut("ptr", h_bitmap, mii, 44) ; hbmpItem = h_bitmap

    if DllCall("SetMenuItemInfo","ptr",h_menu,"uint",ItemPos-1,"int",1,"ptr",mii.ptr)
    {
        if (h_previous && h_previous < -1 || h_previous > 11)
            DllCall("DeleteObject","ptr",h_previous)
        return true
    }

    if IsSet(loaded_icon) && loaded_icon
        DllCall("DestroyIcon","ptr",loaded_icon)
    return false
}
MI_ExtractIcon(Filename, IconNumber, IconSize)
{
    local hIcon := 0, hIcon_Small := 0
    DllCall("PrivateExtractIcons", "wStr", Filename, "Int", IconNumber-1, "Int", IconSize, "Int", IconSize, "ptr*", &hIcon, "ptr*", 0, "UInt", 1, "UInt", 0)
    if (hIcon)
        Return hIcon

    if DllCall("shell32.dll\ExtractIconExW", "wStr", Filename, "Int", IconNumber-1, "ptr*", &hIcon, "ptr*", &hIcon_Small, "UInt", 1)
    {
        local SmallIconSize := DllCall("GetSystemMetrics", "int", 49)
        if (IconSize <= SmallIconSize) {
            if hIcon DllCall("DestroyIcon", "ptr", hIcon)
            hIcon := hIcon_Small
        } else {
            if hIcon_Small DllCall("DestroyIcon", "ptr", hIcon_Small)
        }

        if (hIcon && IconSize)
            hIcon := DllCall("CopyImage", "ptr", hIcon, "UInt", 1, "Int", IconSize, "Int", IconSize, "UInt", 4|8)
    }
    return hIcon ? hIcon : 0
}
MI_GetMenuHandle(menu_name)
{
    static h_menuDummy
    if !IsSet(h_menuDummy)
    {
        local menuDummy := Menu()
        local tempGui := Gui()
        tempGui.Menu := menuDummy
        h_menuDummy := DllCall("GetMenu", "ptr", tempGui.Hwnd)
    }

    local tempMenu := Menu()
    h_menu := DllCall( "GetSubMenu", "ptr", h_menuDummy, "int", 0 )
    DllCall( "RemoveMenu", "ptr", h_menuDummy, "uint", 0, "uint", 0x400 )

    return h_menu
}

MI_GetBitmapFromIcon32Bit(h_icon, width=0, height=0)
{
    local buf := Buffer(40)
    local hbmColor := 0, hbmMask := 0, pBits := 0
    if DllCall("GetIconInfo","ptr",h_icon,"ptr",buf.ptr) {
        hbmColor := NumGet(buf,16, "ptr")
        hbmMask := NumGet(buf,12, "ptr")
    }

    if !(width && height) {
        if !hbmColor or !DllCall("GetObject","ptr",hbmColor,"int",24,"ptr",buf.ptr)
            return 0
        width := NumGet(buf,4,"int"), height := NumGet(buf,8,"int")
    }

    if (hdcDest := DllCall("CreateCompatibleDC","ptr",0))
    {
        NumPut("uint", 40, buf, 0)
        NumPut("ushort", 1, buf, 12)
        NumPut("int", width, buf, 4)
        NumPut("int", height, buf, 8)
        NumPut("ushort", 32, buf, 14)

        if (bm := DllCall("CreateDIBSection","ptr",hdcDest,"ptr",buf.ptr,"uint",0
            ,"ptr*", &pBits,"ptr",0,"uint",0))
        {
            if (bmOld := DllCall("SelectObject","ptr",hdcDest,"ptr",bm))
            {
                DllCall("DrawIconEx","ptr",hdcDest,"int",0,"int",0,"ptr",h_icon
                    ,"uint",width,"uint",height,"uint",0,"ptr",0,"uint",3)
                DllCall("SelectObject","ptr",hdcDest,"ptr",bmOld)
            }

            local has_alpha_data := false
            Loop, height*width {
                if NumGet(pBits+0,(A_Index-1)*4, "uint") & 0xFF000000 {
                    has_alpha_data := true
                    break
                }
            }
            if !has_alpha_data
            {
                hbmMask := DllCall("CopyImage","ptr",hbmMask,"uint",0
                    ,"int",width,"int",height,"uint",4|8)

                local mask_bits := Buffer(width*height*4)
                if DllCall("GetDIBits","ptr",hdcDest,"ptr",hbmMask,"uint",0
                    ,"uint",height,"ptr",mask_bits.ptr,"ptr",buf.ptr,"uint",0)
                {
                    Loop, height*width {
                        if (NumGet(mask_bits, (A_Index-1)*4, "uint"))
                            NumPut("uint", 0, pBits+(A_Index-1)*4)
                        else
                            NumPut("uint", NumGet(pBits+(A_Index-1)*4, "uint") | 0xFF000000, pBits+(A_Index-1)*4)
                    }
                } else {
                    Loop, height*width
                        NumPut("uint", NumGet(pBits+(A_Index-1)*4, "uint") | 0xFF000000, pBits+(A_Index-1)*4)
                }
            }
        }
        DllCall("DeleteDC","ptr",hdcDest)
    }

    if hbmColor DllCall("DeleteObject","ptr",hbmColor)
    if hbmMask DllCall("DeleteObject","ptr",hbmMask)
    return IsSet(bm) ? bm : 0
}

; converts a path to its equivalent in a sandbox
stdPathToBoxPath(box, bpath)
{
    global sandboxes_path
    local boxpath := StrReplace(sandboxes_path, "`%SANDBOX`%", box)
    local userprofile := A_UserProfile . "\"
    if (SubStr(bpath, 1, StrLen(userprofile)) == userprofile) {
        local remain := SubStr(bpath, StrLen(userprofile) + 1)
        return boxpath . "\user\current\" . remain
    }
    local allusersprofile := A_AllUsersProfile . "\"
    if (SubStr(bpath, 1, StrLen(allusersprofile)) == allusersprofile) {
        local remain := SubStr(bpath, StrLen(allusersprofile) + 1)
        return boxpath . "\user\all\" . remain
    }
    if (SubStr(bpath, 2, 2) == ":\") {
        local drive := SubStr(bpath, 1, 1)
        local remain := SubStr(bpath, 3)
        return boxpath . "\drive\" . drive . remain
    }
    return bpath
}

; converts a sandbox path to its equivalent in "the real world"
boxPathToStdPath(box, bpath)
{
    global sandboxes_path
    local boxpath := StrReplace(sandboxes_path, "`%SANDBOX`%", box)
    if (SubStr(bpath, 1, StrLen(boxpath)) != boxpath) {
        return bpath
    }
    local remain := SubStr(bpath, StrLen(boxpath) + 2)
    local tmp := "user\current\"
    if (SubStr(remain, 1, StrLen(tmp)) == tmp) {
        remain := SubStr(remain, StrLen(tmp) + 1)
        return A_UserProfile . "\" . remain
    }
    tmp := "user\all\"
    if (SubStr(remain, 1, StrLen(tmp)) == tmp) {
        remain := SubStr(remain, StrLen(tmp) + 1)
        return A_AllUsersProfile . "\" . remain
    }
    tmp := "drive\"
    if (SubStr(remain, 1, StrLen(tmp)) == tmp) {
        remain := SubStr(remain, StrLen(tmp) + 1)
        local driveletter := SubStr(remain, 1, 1)
        remain := SubStr(remain, 3)
        return driveletter . ":\" . remain
    }
    return bpath
}

; Add sandboxed commands in the main menu.
; filelist is a list of filenames seperated by newline characters.
addCmdsToMenu(box, menuObj, fileslist)
{
    global menucommands, smalliconsize
    numentries := 0
    for _, entry in StrSplit(fileslist, "`n")
    {
        idx := InStr(entry, ":")
        label := SubStr(entry, 1, idx-1)
        if menucommands.Has(menuObj.Name) && menucommands[menuObj.Name].Has(label)
            label .= " (2)"
        exefile := SubStr(entry, idx+1)
        menuObj.Add(label, RunProgramMenuHandler)
        setIconFromSandboxedShortcut(box, exefile, menuObj, label, smalliconsize)
        numentries++
        if !menucommands.Has(menuObj.Name)
            menucommands[menuObj.Name] := Map()
        menucommands[menuObj.Name][label] := exefile
    }
    return numentries
}

; determines current directory to run the shortcut
findCurrentDir(box, shortcut)
{
    local curdir := ""
    SplitPath(shortcut, , &curdir, &extension)
    if (extension == "lnk") {
        FileGetShortcut(shortcut, &target, &outDir)
        if (outDir != "")
            curdir := outDir
        else
            SplitPath(target, , &curdir)
    }

    curdir := expandEnvVars(curdir)
    return curdir
}

; Substitutes the Windows environment variables in the input string.
; Leave the other %variables% untouched.
expandEnvVars(str)
{
    global SID, SESSION
    str := StrReplace(str, "`%SID`%", SID)
    str := StrReplace(str, "`%SESSION`%", SESSION)
    str := StrReplace(str, "`%USER`%", A_UserName)

    if sz := DllCall("ExpandEnvironmentStrings", "Str", str, "Ptr", 0, "UInt", 0)
    {
        local dst := Buffer(sz * 2)
        if DllCall("ExpandEnvironmentStrings", "Str", str, "Ptr", dst.Ptr, "UInt", sz)
            return StrGet(dst)
    }
    return str
}

; Execute a program under the control of Sandboxie.
; TODO: On an x64 system, AHK cannot launch shortcuts pointing to x64 programs
executeShortcut(box, shortcut)
{
    global start

    ; tries to CD to the directory included in the shortcut
    curdir := findCurrentDir(box, shortcut)
    try {
        SetWorkingDir(curdir)
    } catch {
        ; if it fails, CD to the directory of the shortcut
        SplitPath(shortcut, , &curdir)
        SetWorkingDir(curdir)
    }

    ; run the shortcut or file
    try {
        if (box) {
            Run('"' . start . '" /box:' . box . ' "' . shortcut . '"', curdir)
        } else {
            try {
                Run('"' . shortcut . '"', curdir)
            }
            catch
            {
                ; AHK cannot launch shortcuts pointing to x64 programs in C:\Program Files\
                SplitPath(shortcut, , , &extension)
                if (extension == "lnk") {
                    FileGetShortcut(shortcut, &target, &dir, &args, &runState)
                    target := StrReplace(target, "Program Files (x86)", "Program Files")
                    try
                        Run('"' . target . '" ' . args, curdir)
                    catch
                    {
                        target := StrReplace(target, "Program Files", "Program Files (x86)")
                        Run('"' . target . '" ' . args, curdir)
                    }
                }
            }
        }
    }
    catch
    {
        SoundBeep()
    }
    SetWorkingDir(A_ScriptDir)
    Return
}

; Creates a shortut on the (normal) desktop to run the program under the control of Sandboxie.
createDesktopShortcutFromLnk(box, shortcut, iconfile, iconnum)
{
    global start, title

    SplitPath(shortcut, &outFileName, &outDir1, &outExtension, &outNameNoExt, &outDrive)

    if (box == "") {
        if (outExtension == "lnk") {
            dest := A_UserProfile . "\Desktop\" . outFileName
            if (FileExist(dest))
            {
                if (MsgBox('File "' . dest . '" already exists on your desktop!`n`nClick Continue to overwrite it.', title, "Question YesNo") == "No")
                    Return
            }
            FileCopy(shortcut, dest, 1)
        } else {
            writeUnsandboxedShortcutFileToDesktop(shortcut,outNameNoExt,outDir1,"","SandboxToys User Tool","","",1)
        }
        Return
    }

    SplitPath(shortcut, &outFileName, &outDir1, &outExtension, &outNameNoExt, &outDrive)
    curdir := findCurrentDir(box, shortcut)
    if (outExtension == "lnk") {
        FileGetShortcut(shortcut, &outTarget, &outDir, &outArgs, &outDescription, &outIcon, &outIconNum, &outRunState)
        outArgs := "/box:" . box . " """ . outTarget . """ " . outargs
        if (!outDir)
            outDir := boxPathToStdPath(box, outTarget)
        outDir := stdPathToBoxPath(box, outDir)
        if (outDescription)
            outDescription := "Run """ . outNameNoExt . """ in sandbox " . box . ".`n" . outDescription
        else
            outDescription := "Run """ . outNameNoExt . """ in sandbox " . box . "."
    } else {
        file := boxPathToStdPath(box, shortcut)
        outArgs := "/box:" . box . " """ . file . """"
        SplitPath(file, , &outDir)
        outDescription := "Run """ . outNameNoExt . """ in sandbox " . box . "."
        outRunState := 1
    }
    outIcon := iconfile
    if (iconnum = 0)
        iconnum := 1
    outIconNum := iconnum
    outTarget := start

    ; create the shortcut
    writeSandboxedShortcutFileToDesktop(outTarget, outNameNoExt, outDir, outArgs, outDescription, outIcon, outIconNum, outRunState, box)
    Return
}

; write a sandboxed shortcut
writeSandboxedShortcutFileToDesktop(target,name,dir,args,description,iconFile,iconNum,runState,box)
{
    global title, includeboxnames

    if (includeboxnames)
    {
        if (box == "__ask__")
            name := "[#ask box] " . name
        else
            name := "[#" . box . "] " . name
    }
    else
        name := "[#] " . name
    linkFile := A_UserProfile . "\Desktop\" . name . ".lnk"

    if (FileExist(linkFile))
    {
        if (MsgBox('Shortcut "' . name . '" already exists on your desktop!`n`nClick Continue to overwrite it.', title, "Question YesNo") == "No")
            Return
    }
    ; create the shortcut
    FileCreateShortcut(target, linkFile, dir, args, description, iconFile, iconNum, runState)
    Return
}

; write a normal (unsandboxed) shortcut.
writeUnsandboxedShortcutFileToDesktop(target,name,dir,args,description,iconFile,iconNum,runState)
{
    global title

    linkFile := A_UserProfile . "\Desktop\" . name . ".lnk"

    if (FileExist(linkFile))
    {
        if (MsgBox('Shortcut "' . name . '" already exists on your desktop!`n`nClick Continue to overwrite it.', title, "Question YesNo") == "No")
            Return
    }
    ; create the shortcut
    FileCreateShortcut(target, linkFile, dir, args, description, iconFile, iconNum, runState)
    Return
}

; return the box name of the last selected menu item
getBoxFromMenu(menuName)
{
    Return SubStr(menuName, 1, InStr(menuName, "_ST2") - 1)
}

; create a sandboxed shortcut on the desktop
NewShortcut(box, file)
{
    global start
    SplitPath(file, , &dir, &extension, &label)
    if (!FileExist(dir))
        dir := stdPathToBoxPath(box, dir)
    A_Quotes := '"'
    ; TODO: Handle the .LNK, .URL, .HTM and .HTML files correctly!
    ; TODO: verify that start.exe is not launched in a sandbox!
    local iconfile, iconnum
    if (extension == "exe")
    {
        iconfile := file
        iconnum := 1
    }
    else
    {
        tempMenu := Menu()
        tempMenu.Add("__TEMP__", DummyMenuHandler)
        local icon := setIconFromSandboxedShortcut(box, file, tempMenu.Name, "__TEMP__", 32)
        local idx := InStr(icon, ",",, 0)
        iconfile := SubStr(icon, 1, idx - 1)
        iconnum := SubStr(icon, idx + 1)
        if (iconnum < 0)
            iconnum := IndexOfIconResource(iconfile, iconnum)
        tempMenu.Delete()
    }
    local tip
    if (box == "__ask__")
        tip := "Launch """ . label . """ in any sandbox"
    else
        tip := "Launch """ . label . """ in sandbox " . box
    writeSandboxedShortcutFileToDesktop(start, label, dir, "/box:" . box . " " . A_Quotes . file . A_Quotes, tip, iconfile, iconnum, 1, box)
}

; Since the sandbox has to be active to access its registry, it is necessary
; to run something in the box when the registry has to be accessed.
; This function ensures that the box is active by opening the Sandboxie Run Dialog
; in the specified box.  The Run dialog is launched in hidden mode.
; The function returns the PID of the Run process, that must be used to close
; the Run dialog and release the box.
InitializeBox(box)
{
    global start, username
    global sandboxes_array
    bregstr_ := sandboxes_array[box].KeyRootPath
    bregstr_ := StrReplace(StrReplace(SubStr(bregstr_, 16), '`%SANDBOX`%', box), '`%USER`%', username)
    ; ensure that the box is in use, or the hive will not be loaded
    run_pid := Run('"' . start . '" /box:' . box . ' run_dialog',, "Hide")

    ; wait til the registry hive has been loaded in the global registry
    boxkeypath := bregstr_ . '\user\current\software\SandboxAutoExec'
    Loop 100
    {
        Sleep(50)
        try {
            RegRead("HKEY_USERS\" . boxkeypath)
            break
        }
        catch
        {
            continue
        }
    }

    return run_pid
}

; This function closes the hidden Run dialog, so that Sandboxie can deactivate
; the sandbox (unless something else is running in the box, of course.)
ReleaseBox(run_pid)
{
    Sleep(800)
    DetectHiddenWindows(true)
    try WinClose("ahk_pid " . run_pid, , 1)
    if WinExist("ahk_pid " . run_pid)
        ProcessClose(run_pid)
    Sleep(200)
    Return
}

; ###################################################################################################
; "Find" and associated ListBox functions and handlers
; ###################################################################################################

SearchFiles(bp, rp, boxbasepath, ignoredDirs, ignoredFiles, comparedata:="")
{
    global listemptyitems
    local fileList := []
    local sep := A_Tab

    Loop Files, bp . "\*", "F"
    {
        local rf := rp . "\" . A_LoopFileFullPath
        local bf := bp . "\" . A_LoopFileFullPath
        SplitPath(bf, &fname, &boxsubpath)
        boxsubpath := SubStr(boxsubpath, StrLen(boxbasepath) + 2)
        if (IsIgnored("files", ignoredFiles, boxsubpath, fname))
            continue

        if (comparedata != "")
        {
            local status := (A_LoopFileTimeCreated == "19860523174702") ? "-" : "+"
            local comp := status . " " . A_LoopFileTimeModified . " " . boxsubpath . "\" . fname . ":*:"
            if InStr(comparedata, comp)
                Continue
        }

        local timeCreated := FormatTime(A_LoopFileTimeCreated, "yyyy/MM/dd HH:mm:ss")
        local timeModified := FormatTime(A_LoopFileTimeModified, "yyyy/MM/dd HH:mm:ss")
        local timeAccessed := FormatTime(A_LoopFileTimeAccessed, "yyyy/MM/dd HH:mm:ss")
        local st := (A_LoopFileTimeCreated == "19860523174702") ? "-" : (FileExist(rf) ? "#" : "+")

        fileList.Push(st . sep . rf . sep . A_LoopFileAttrib . sep . A_LoopFileSize . sep . timeCreated . sep . timeModified . sep . timeAccessed . sep . boxsubpath)
    }
    Loop Files, bp . "\*", "D"
    {
        local bdir := bp . "\" . A_LoopFileFullPath
        local boxsubpath := SubStr(bdir, StrLen(boxbasepath) + 2)
        if (IsIgnored("dirs", ignoredDirs, boxsubpath))
            continue

        if (comparedata != "")
        {
            local status := (A_LoopFileTimeCreated == "19860523174702") ? "-" : "+"
            local comp := status . " " . A_LoopFileTimeModified . " " . boxsubpath . ":*:"
            if InStr(comparedata, comp)
                Continue
        }

        local is_empty := !DirExist(bdir . "\*")

        if (is_empty && listemptyitems)
        {
            local rdir_empty := rp . "\" . A_LoopFileFullPath
            local timeCreated := FormatTime(A_LoopFileTimeCreated, "yyyy/MM/dd HH:mm:ss")
            local timeModified := FormatTime(A_LoopFileTimeModified, "yyyy/MM/dd HH:mm:ss")
            local timeAccessed := FormatTime(A_LoopFileTimeAccessed, "yyyy/MM/dd HH:mm:ss")
            local st := (A_LoopFileTimeCreated == "19860523174702") ? "-" : (DirExist(rdir_empty) ? "#" : "+")
            fileList.Push(st . sep . rdir_empty . sep . A_LoopFileAttrib . sep . "0" . sep . timeCreated . sep . timeModified . sep . timeAccessed . sep . boxsubpath)
        }

        local rdir := rp . "\" . A_LoopFileFullPath
        local subFiles := SearchFiles(bdir, rdir, boxbasepath, ignoredDirs, ignoredFiles, comparedata)
        if (subFiles.Length > 0) {
            for _, f in subFiles
                fileList.Push(f)
        }
    }

    return fileList
}


; GUILVViewIcon:
;     GuiControl, +Icon, MyListView
; Return
; GUILVViewTile:
;     GuiControl, +Tile, MyListView
; Return
; GUILVViewIconSmall:
;     GuiControl, +IconSmall, MyListView
; Return
; GUILVViewList:
;     GuiControl, +List, MyListView
; Return
; GUILVViewReport:
;     GuiControl, +Report, MyListView
; Return

SortByPath(a, b, *)
{
    local sep := A_Tab
    local a_fields := StrSplit(a, sep)
    local b_fields := StrSplit(b, sep)
    local path_a := a_fields[2]
    local path_b := b_fields[2]
    if (path_a > path_b)
        return 1
    if (path_a < path_b)
        return -1
    return 0
}

; List files in sandbox
ListFiles(box, bpath, comparefilename="")
{
    global ignoredDirs, ignoredFiles, ignoredKeys, ignoredValues
    global guinotclosed, title, MyListView, LVLastSize
    global newIgnored, guinotclosed, title, MyListView, LVLastSize, listemptyitems

    static MainLabel

    ReadIgnoredConfig("files")
    newIgnored := Map("dirs", "", "files", "")

    Progress(1, "Please wait...", "Searching for files in box """ . box . """...", title)

    local comparedata := ""
    if (comparefilename != "")
        comparedata := FileRead(comparefilename)

    local allfiles := []

    local bp := bpath . "\user\current"
    local rp := A_UserProfile
    if DirExist(bp)
    {
        local f_array := SearchFiles(bp, rp, bpath, ignoredDirs, ignoredFiles, comparedata)
        for _, f in f_array
            allfiles.Push(f)
    }

    Progress(13)
    bp := bpath . "\user\all"
    rp := A_AllUsersProfile
    if DirExist(bp)
    {
        local f_array := SearchFiles(bp, rp, bpath, ignoredDirs, ignoredFiles, comparedata)
        for _, f in f_array
            allfiles.Push(f)
    }

    Progress(16)
    Loop Files, bpath . "\drive\*", "D"
    {
        local drive := A_LoopFileName
        bp := bpath . "\drive\" . A_LoopFileName
        rp := A_LoopFileName . ":"
        local f_array := SearchFiles(bp, rp, bpath, ignoredDirs, ignoredFiles, comparedata)
        for _, f in f_array
            allfiles.Push(f)
    }

    Progress(19, "Please wait...", "Sorting list of files in box """ . box . """...", title)
    if (allfiles.Length > 0)
        allfiles.Sort(SortByPath)
    local numfiles := allfiles.Length
    if (numfiles = 0)
    {
        Progress(0)
        if (comparefilename == "")
            MsgBox("No meaningful files in box """ . box . """!",, "IconInfo")
        else
            MsgBox("No new or modified files in box """ . box . """!",, "IconInfo")
        Return
    }

    if (LVLastSize == "") {
        local mon := SysGet("MonitorWorkArea")
        local width, height
        if (mon.Right == "") {
            width := A_ScreenWidth - 300
            height := A_ScreenHeight - 300
        } else {
            width := mon.Right - mon.Left - 250
            height := mon.Bottom - mon.Top - 250
        }
        if (width < 752)
            width := 752
        local maxrows := height / 18
        local numrows
        if (numfiles < maxrows)
        {
            if (numfiles < 3)
                numrows := 3
            else
                numrows := numfiles
            numrows += 2
            local heightarg := "r" . numrows
        } else
            heightarg := "h" . height
        LVLastSize := "w" . width . " " . heightarg
    }

    MyGui := Gui("+Resize")
    MyGui.Title := title . " - Files in box """ . box . """"
    MainLabel := MyGui.Add("Text", "w900", "Find Files...")

    FileMenu := Menu()
    FileMenu.Add("&Copy Checkmarked Files To...", GuiLVFilesSaveTo)
    FileMenu.Add("Save Checkmarked Entries as CSV &Text", GuiLVFilesSaveAsText)
    FileMenu.Add()
    FileMenu.Add("Add Shortcuts to Checkmarked Files to Sandboxed Start &Menu", GuiLVFilesToStartMenu)
    FileMenu.Add("Add Shortcuts to Checkmarked Files to Sandboxed &Desktop", GuiLVFilesToDesktop)
    FileMenu.Add("Create Sandboxed &Shortcuts to Checkmarked Files on your Real Desktop", GuiLVFilesShortcut)

    EditMenu := Menu()
    EditMenu.Add("&Clear All Checkmarks", GuiLVClearAllCheckmarks)
    EditMenu.Add("&Toggle All Checkmarks", GuiLVToggleAllCheckmarks)
    EditMenu.Add("Toggle &Selected Checkmarks", GuiLVToggleSelected)
    EditMenu.Add()
    EditMenu.Add("&Hide Selected Entries", GuiLVHideSelected)
    EditMenu.Add()
    EditMenu.Add("Add Selected &Files to Ignore List", GuiLVIgnoreSelectedFiles)
    EditMenu.Add("Add Selected &Dirs to Ignore List", GuiLVIgnoreSelectedDirs)

    LVMenuBar := Menu()
    LVMenuBar.Add("&File", FileMenu)
    LVMenuBar.Add("&Edit", EditMenu)
    MyGui.Menu := LVMenuBar

    PopupMenu := Menu()
    PopupMenu.Add("Copy To...", GuiLVCurrentFileSaveTo)
    PopupMenu.Add("Open in Sandbox", GuiLVCurrentFileRun)
    PopupMenu.Add()
    PopupMenu.Add("Open Unsandboxed Container", GuiLVCurrentFileOpenContainerU)
    PopupMenu.Add("Open Sandboxed Container", GuiLVCurrentFileOpenContainerS)
    PopupMenu.Add()
    PopupMenu.Add("Add Shortcut on Sandbox Start Menu", GuiLVCurrentFileToStartMenu)
    PopupMenu.Add("Add Shortcut on Sandbox Desktop", GuiLVCurrentFileToDesktop)
    PopupMenu.Add("Create Sandboxed Shortcut on Real Desktop", GuiLVCurrentFileShortcut)
    PopupMenu.Add()
    PopupMenu.Add("Toggle Checkmark", GuiLVToggleCurrent)
    PopupMenu.Add()
    PopupMenu.Add("Hide from this list", GuiLVHideCurrent)
    PopupMenu.Add()
    PopupMenu.Add("Add File to Ignore List", GuiLVIgnoreCurrentFile)
    PopupMenu.Add("Add Folder to Ignore List", GuiLVIgnoreCurrentDir)
    PopupMenu.Add("Add Sub-Folder to Ignore List...", GuiLVIgnoreCurrentSubDir)

    MyListView := MyGui.Add("ListView", "x10 y30 " . LVLastSize . " Checked AltSubmit", ["Status", "File", "bpath", "Size", "Attribs", "Created", "Modified", "Accessed", "Extension", "Sandbox bpath"])
    MyListView.OnEvent("DoubleClick", GuiLVCurrentFileSaveTo)
    MyListView.OnEvent("RightClick", (ctl, info) => PopupMenu.Show())
    MyGui.OnEvent("Size", GuiSize)
    MyGui.OnEvent("Close", (*) => guinotclosed := 0)

    ; icons array
    local ImageListID1 := IL_Create(10)
    MyListView.SetImageList(ImageListID1)

    Progress(20, "Please wait...", "Building list of files in box """ . box . """...", title)

    ; add entries in listview
    local nummodified := 0
    local numadded := 0
    local numdeleted := 0
    local sep := A_Tab
    MyListView.Redraw := false
    local old_prog := 0
    for i, entry in allfiles
    {
        local prog := Round(80 * i / numfiles) + 20
        if (prog != old_prog)
        {
            Progress(prog)
            Sleep(1)
            old_prog := prog
        }

        local fields := StrSplit(entry, sep)
        local St := fields[1]
        local deleted := 0
        if (St == "#")
            nummodified++
        else if (St == "+")
            numadded++
        else if (St == "-")
        {
            numdeleted++
            deleted := 1
        }

        local OutFileName, OutDir, OutExtension
        SplitPath(fields[2], &OutFileName, &OutDir, &OutExtension)
        local Attribs := fields[3]
        local Size := fields[4]
        local Created := fields[5]
        local Modified := fields[6]
        local Accessed := fields[7]
        local BoxPath := fields[8]

        if (St == "-")
            Created := ""
        local iconfile := bpath . "\" . BoxPath . "\" . OutFileName
        if (!FileExist(iconfile))
            iconfile := boxPathToStdPath(box, iconfile)

        local hIcon := GetAssociatedIcon(iconfile, false, 16, box, deleted)
        local IconNumber := DllCall("ImageList_ReplaceIcon", "ptr", ImageListID1, "int", -1, "ptr", hIcon) + 1
        MyListView.Add("Icon" . IconNumber, St . A_Space, OutFileName, OutDir, Size, Attribs, Created, Modified, Accessed, OutExtension, BoxPath)
    }
    Progress(100)
    Sleep(50)

    MyListView.ModifyCol()
    MyListView.ModifyCol(4, "Integer")

    local msg := "Found " . numfiles . " file"
    if (numfiles != 1)
        msg .= "s"
    msg .= " in the sandbox """ . box . """"
    msg .= " : # " . nummodified . " modified file"
    if (nummodified != 1)
        msg .= "s"
    msg .= " , + " . numadded . " new file"
    if (numadded != 1)
        msg .= "s"
    msg .= " , - " . numdeleted . " deleted file"
    if (numdeleted != 1)
        msg .= "s"
    msg .= ". Double-click an entry to copy the file to the desktop."
    MainLabel.Text := msg

    Progress(0)
    MyListView.Redraw := true
    MyGui.Show()

    guinotclosed := 1
    while (guinotclosed)
        Sleep(1000)
    SaveNewIgnoredItems("files")

    return
}

GuiSize(GuiObj, EventInfo, Width, Height)
{
    if (EventInfo == 1) ; The window has been minimized.  No action needed.
        return
    global LVLastSize, MyListView
    LVLastSize := "w" . (Width - 20) . " h" . (Height - 40)
    MyListView.Move(LVLastSize)
}

; Copy To...
GuiLVCurrentFileSaveTo(ctl, row)
{
    global sandboxes_array, box, DefaultFolder, MyGui, MyListView
    LVFileName := MyListView.GetText(row, 2)
    LVExtension := MyListView.GetText(row, 9)
    LVFilePath := MyListView.GetText(row, 10)
    boxpath := sandboxes_array[box].bpath
    MyGui.Opt("+OwnDialogs")
    if (!InStr(FileExist(DefaultFolder . "\"), "D"))
        DefaultFolder := A_Desktop
    filename := FileSelect("S", DefaultFolder . "\" . LVFileName, "Copy """ . LVFileName . """ from sandbox to...", LVExtension . " files (*." . LVExtension . ")")
    if (filename == "")
        Return
    FileCopy(boxpath . "\" . LVFilePath . "\" . LVFileName, filename, 1)
    SplitPath(filename, , &DefaultFolder)
}

; Open in Sandbox
GuiLVCurrentFileRun(*)
{
    global sandboxes_array, box, MyListView
    local row := MyListView.GetNext(0, "F")
    if (row = 0)
        return
    LVCurrentFileRun(row, box, sandboxes_array[box].bpath)
}
LVCurrentFileRun(row, box, boxpath)
{
    global start, title, MyListView
    local LVFileName := MyListView.GetText(row, 2)
    local LVPath := MyListView.GetText(row, 10)
    local Filename := boxpath . "\" . LVPath . "\" . LVFileName
    local old_pwd := A_WorkingDir
    SetWorkingDir(boxpath . "\" . LVPath)
    try
        Run('"' . start . '" /box:' . box . ' "' . Filename . '"')
    catch
        MsgBox("Failed to run " . Filename, title, 16)
    MsgBox("Running """ . Filename . """ in box " . box . ".`n`nPlease wait...", title, "64 T3")
    SetWorkingDir(old_pwd)
    Return
}
GuiLVCurrentFileOpenContainerU(*) {
    global box, sandboxes_array, MyListView
    local row := MyListView.GetNext(0, "F")
    if (row = 0)
        return
    GuiLVCurrentFileOpenContainer(row, box, sandboxes_array[box].bpath, "u")
}

GuiLVCurrentFileOpenContainerS(*) {
    global box, sandboxes_array, MyListView
    local row := MyListView.GetNext(0, "F")
    if (row = 0)
        return
    GuiLVCurrentFileOpenContainer(row, box, sandboxes_array[box].bpath, "s")
}
GuiLVCurrentFileOpenContainer(row, box, boxpath, mode)
{
    global start, title, MyGui, MyListView
    MyGui.Opt("+OwnDialogs")
    if (mode == "u")
    {
        local CurPath := MyListView.GetText(row, 10)
        Curpath := boxpath . "\" . CurPath
        try
            Run('"' . Curpath . '"')
        catch e
            MsgBox("Failed to open " . CurPath . ".`n" . e.Message, title, 16)
    }
    else
    {
        local LVBoxFile := MyListView.GetText(row, 2)
        local CurPath := MyListView.GetText(row, 3)
        try
            Run('"' . start . '" /box:' . box . ' "' . CurPath . '"')
        catch e
            MsgBox("Failed to open " . CurPath . ".`n" . e.Message, title, 16)

        MsgBox("Opening container of """ . LVBoxFile . """ in box " . box . ".`n`nPlease wait...", title, "64 T3")
    }
    Return
}

GuiLVCurrentFileToStartMenu(*) {
    global box, sandboxes_array, MyListView
    local row := MyListView.GetNext(0, "F")
    if (row = 0)
        return
    GuiLVCurrentFileToStartMenuOrDesktop(row, box, sandboxes_array[box].bpath, "startmenu")
}

GuiLVCurrentFileToDesktop(*) {
    global box, sandboxes_array, MyListView
    local row := MyListView.GetNext(0, "F")
    if (row = 0)
        return
    GuiLVCurrentFileToStartMenuOrDesktop(row, box, sandboxes_array[box].bpath, "desktop")
}
GuiLVCurrentFileToStartMenuOrDesktop(row, box, boxpath, where)
{
    global MyListView
    LVFileName := MyListView.GetText(row, 2)
    LVPath := MyListView.GetText(row, 3)
    SplitPath(LVFileName, , , , &LVFileNameNoExt)
    Target := LVPath . "\" . LVFileName
    if (where == "startmenu")
        ShortcutPath := boxpath . "\user\current\AppData\Roaming\Microsoft\Windows\Start Menu"
    else
        ShortcutPath := boxpath . "\user\current\Desktop"
    ShortcutFile := ShortcutPath . "\" . LVFileNameNoExt . ".lnk"
    if (!DirExist(ShortcutPath))
        DirCreate(ShortcutPath)
    FileCreateShortcut(Target, ShortcutFile, LVPath, , "Run """ . LVFileName . """`nShortcut created by SandboxToys2")
    Return
}

GuiLVCurrentFileShortcut(row, *) {
    GuiLVCurrentFileShortcut(row, box, sandboxes_array[box].bpath)
}
GuiLVCurrentFileShortcut(row, box, boxpath)
{
    global start, MyListView
    LVFileName := MyListView.GetText(row, 2)
    LVPath := MyListView.GetText(row, 3)
    LVBoxPath := MyListView.GetText(row, 10)
    file := LVPath . "\" . LVFileName

    runstate := 1
    SplitPath(file, , &dir, &extension, &label)
    A_Quotes := """"
    if (extension == "exe")
    {
        iconfile := boxpath . "\" . LVBoxPath . "\" . LVFileName
        iconnum := 1
    }
    else if (extension == "lnk")
    {
        FileGetShortcut(boxpath . "\" . LVBoxPath . "\" . LVFileName, &outTarget, &outDir, &outArgs, &outDescription, &iconfile, &iconnum, &runstate)
        if (!FileExist(iconfile))
            iconfile := stdPathToBoxPath(box, iconfile)
    }
    else
    {
        tempMenu := Menu()
        tempMenu.Add("__TEMP__", (*) => {})
        icon := setIconFromSandboxedShortcut(box, file, tempMenu.Name, "__TEMP__", 32)
        idx := InStr(icon, ",", false, 0)
        iconfile := SubStr(icon, 1, idx-1)
        iconnum := SubStr(icon, idx+1)
        if (iconnum < 0)
            iconnum := IndexOfIconResource(iconfile, iconnum)
        tempMenu.Delete()
    }
    tip := "Launch """ . label . """ in sandbox " . box
    writeSandboxedShortcutFileToDesktop(start, label, boxpath . "\" . LVBoxPath, "/box:" . box . " " . A_Quotes . file . A_Quotes, tip, iconfile, iconnum, 1, box)

    Return
}

GuiLVToggleCurrent(row, *) {
    global MyListView
    is_checked := MyListView.GetNext(row, "Checked")
    MyListView.Modify(row, (is_checked ? "-" : "+") . "Check")
}

GuiLVHideCurrent(row, *) {
    global MyListView
    MyListView.Delete(row)
}

GuiLVIgnoreCurrentFile(row, *) {
    LVIgnoreEntry(row, "files")
}
GuiLVIgnoreCurrentDir(row, *) {
    LVIgnoreEntry(row, "dirs")
}
GuiLVIgnoreCurrentValue(row, *) {
    LVIgnoreEntry(row, "values")
}
GuiLVIgnoreCurrentKey(row, *) {
    LVIgnoreEntry(row, "keys")
}
LVIgnoreEntry(row, mode)
{
    global MyListView
    A_nl := "`n"

    if (mode == "dirs" || mode == "files")
        pathcol := 10
    else
        pathcol := 7

    if (mode == "keys")
        item := MyListView.GetText(row, pathcol)
    else if (mode == "dirs")
        item := MyListView.GetText(row, pathcol)
    else if (mode == "values")
    {
        item := MyListView.GetText(row, pathcol)
        val := MyListView.GetText(row, 4)
        item .= "\" . val
    }
    else
    {
        item := MyListView.GetText(row, pathcol)
        val := MyListView.GetText(row, 2)
        item .= "\" . val
    }
    AddIgnoreItem(mode, item)
    MyListView.Delete(row)

    if (mode == "dirs" || mode == "keys") {
        p := item
        row := MyListView.GetCount()
        loop
        {
            item := MyListView.GetText(row, pathcol)
            if (InStr(item, p, 1) == 1)
                MyListView.Delete(row)
            row -= 1
            if (row == 0)
                break
        }
    }
    Return
}

GuiLVIgnoreCurrentSubDir(row, *) {
    global MyGui
    MyGui.Opt("+OwnDialogs")
    LVIgnoreSpecific(row, "dirs")
}
GuiLVIgnoreCurrentSubKey(row, *) {
    global MyGui
    MyGui.Opt("+OwnDialogs")
    LVIgnoreSpecific(row, "keys")
}

GuiLVRegMouseEventHandler(ctl, info) {
    global PopupMenu
    if (info == "DoubleClick") {
        GuiLVCurrentOpenRegEdit(ctl.FocusedRow)
    }
    if (info == "RightClick") {
        PopupMenu.Show()
    }
}

GuiLVCurrentCopyToClipboard(row, *) {
    global MyListView
    clipboard := MyListView.GetText(row, 2)
}

GuiLVCurrentOpenRegEdit(row, *) {
    GuiLVCurrentOpenRegEdit(row, box)
}
GuiLVCurrentOpenRegEdit(row, box)
{
    global bregstr_
    run_pid := InitializeBox(box)
    ; pre-select the right registry key
    LVRegPath := MyListView.GetText(row, 7)
    key := "HKEY_USERS\" . bregstr_ . "\" . LVRegPath
    RegWrite("REG_SZ", "HKEY_CURRENT_USER\Software\Microsoft\Windows\CurrentVersion\Applets\Regedit", "LastKey", key)
    ; launch regedit
    RunWait("RegEdit.exe",, "UseErrorLevel")
    ReleaseBox(run_pid)
    Return
}

GuiLVAutostartMouseEventHandler(ctl, info) {
    global PopupMenu
    if (info == "DoubleClick") {
        GuiLVRegistryRun(ctl.FocusedRow, box)
    }
    if (info == "RightClick") {
        PopupMenu.Show()
    }
}

GuiLVRegistryRun(row, *) {
    GuiLVRegistryRun(row, box)
}
GuiLVRegistryRun(row, box)
{
    global title, start, MyGui, MyListView
    A_Quotes := """"
    MyGui.Opt("+OwnDialogs")
    LVRegName := MyListView.GetText(row, 2)
    LVCommand := MyListView.GetText(row, 3)
    if (LVCommand == "")
        MsgBox("Can't run """ . LVRegName . """ in box " . box . ".`n`nNo command line.", title, 48, 3)
    else
    {
        if (InStr(LVCommand, A_Quotes) == 1)
        {
            idx := InStr(LVCommand, A_Quotes, 0, 2)
            Filename := SubStr(LVCommand, 2, idx-2)
            Args := SubStr(LVCommand, idx+2)
        }
        else
        {
            Filename := LVCommand
            Args := ""
        }
        if (Args == "")
            Run('"' . start . '" /box:' . box . ' "' . Filename . '"',, "UseErrorLevel")
        else
            Run('"' . start . '" /box:' . box . ' "' . Filename . '" ' . Args,, "UseErrorLevel")
        MsgBox("Running """ . LVRegName . """ in box " . box . ".`n`nPlease wait...", title, 64, 3)
    }
    Return
}

GuiLVRegistryToStartMenuStartup(row, *) {
    GuiLVRegistryToStartMenuStartup(box, sandboxes_array[box].bpath)
}
GuiLVRegistryToStartMenuStartup(box, boxpath)
{
    global title, MyListView
    A_Quotes := """"
    numfiles := numOfCheckedFiles()
    if (numfiles == 0)
    {
        SoundBeep()
        Return
    }
    row := 0
    Loop
    {
        row := MyListView.GetNext(row, "Checked")
        if not row
            break
        GuiLVRegistryItemToStartMenuStartup(row, box, boxpath)
    }
    Return
}
GuiLVRegistryItemToStartMenuStartup(row, *) {
    GuiLVRegistryItemToStartMenuStartup(row, box, sandboxes_array[box].bpath)
}
GuiLVRegistryItemToStartMenuStartup(row, box, boxpath)
{
    global title, MyListView
    A_Quotes := """"

    LVProgram := MyListView.GetText(row, 2)
    LVCommand := MyListView.GetText(row, 3)
    LVLocation := MyListView.GetText(row, 4)
    if (LVCommand == "")
    {
        MsgBox("Can't create shortcut to """ . LVProgram . """.`n`nNo command line.", title, 48, 3)
        Return
    }

    if (InStr(LVCommand, A_Quotes) == 1)
    {
        idx := InStr(LVCommand, A_Quotes, 0, 2)
        Filename := SubStr(LVCommand, 2, idx-2)
        Args := SubStr(LVCommand, idx+2)
    }
    else
    {
        Filename := LVCommand
        Args := ""
    }
    if (InStr(LVLocation, "HKCU"))
        ShortcutPath := boxpath . "\user\current\AppData\Roaming\Microsoft\Windows\Start Menu\Programs\Startup"
    else
        ShortcutPath := boxpath . "\user\all\Microsoft\Windows\Start Menu\Programs\Startup"

    ShortcutFile := ShortcutPath . "\" . LVProgram . " (" . LVLocation . ").lnk"
    if (!DirExist(ShortcutPath))
        DirCreate(ShortcutPath)
    if (Args == "")
        FileCreateShortcut(Filename, ShortcutFile, , , "Run """ . LVProgram . """`n(Was in " . LVLocation . ")`nShortcut created by SandboxToys2")
    else
        FileCreateShortcut(Filename, ShortcutFile, , Args, "Run """ . LVProgram . """`n(Was in " . LVLocation . ")`nShortcut created by SandboxToys2")

    Return
}

GuiLVRegistryExploreStartMenuCS(row, *) {
    GuiLVRegistryExploreStartMenu(box, sandboxes_array[box].bpath, "current", "sandboxed")
}
GuiLVRegistryExploreStartMenuCU(row, *) {
    GuiLVRegistryExploreStartMenu(box, sandboxes_array[box].bpath, "current", "unsandboxed")
}
GuiLVRegistryExploreStartMenuAS(row, *) {
    GuiLVRegistryExploreStartMenu(box, sandboxes_array[box].bpath, "all", "sandboxed")
}
GuiLVRegistryExploreStartMenuAU(row, *) {
    GuiLVRegistryExploreStartMenu(box, sandboxes_array[box].bpath, "all", "unsandboxed")
}
GuiLVRegistryExploreStartMenu(box, boxpath, user, mode)
{
    global title, start
    local bpath, mowner
    if (mode == "unsandboxed") {
        if (user == "current") {
            bpath := boxpath . "\user\current\AppData\Roaming\Microsoft\Windows\Start Menu\Programs\Startup"
            mowner := "Current User's"
        } else {
            bpath := boxpath . "\user\all\Microsoft\Windows\Start Menu\Programs\Startup"
            mowner := "All Users"
        }
        if (FileExist(bpath)) {
            Run(bpath)
        } else {
            MsgBox("The " . mowner . " Start Menu of box " . box . " has not been created yet.`n`nCan't explore it unsandboxed.", title, 48)
        }
    }
    else
    {
        if (user == "current")
            bpath := A_StartMenu . "\Programs\Startup"
        else
            bpath := A_StartMenuCommon . "\Programs\Startup"
        Run(start . ' /box:' . box . ' "' . bpath . '"')
    }
}

GuiLVToggleAllCheckmarks(*) {
    global MyListView
    MyListView.Modify(0, "Check")
    loop MyListView.GetCount() {
        if MyListView.IsChecked(A_Index)
            MyListView.Modify(A_Index, "-Check")
    }
}

GuiLVHideSelected(*) {
    global MyListView
    loop MyListView.GetCount() {
        if MyListView.IsSelected(A_Index)
            MyListView.Delete(A_Index)
    }
}

GuiLVIgnoreSelectedValues(*) {
    LVIgnoreSelected("values")
}

GuiLVIgnoreSelectedKeys(*) {
    LVIgnoreSelected("keys")
}

GuiLVIgnoreSelectedFiles(*) {
    LVIgnoreSelected("files")
}

GuiLVIgnoreSelectedDirs(*) {
    LVIgnoreSelected("dirs")
}

GuiLVClearAllCheckmarks(*) {
    global MyListView
    MyListView.Modify(0, "-Check")
}

GuiLVToggleSelected(*) {
    global MyListView
    loop MyListView.GetCount() {
        if MyListView.IsSelected(A_Index)
            MyListView.Modify(A_Index, "ToggleCheck")
    }
}

GuiLVFilesSaveAsText(*) {
    GuiLVSaveAsCSVText(box, "Files in sandbox " . box . ".txt")
}
GuiLVRegistrySaveAsText(*) {
    GuiLVSaveAsCSVText(box, "Registry of sandbox " . box . ".txt")
}
GuiLVSaveAsCSVText(box, defaultfilename)
{
    global DefaultFolder, title, MyGui, MyListView
    A_Quotes := """"
    numfiles := numOfCheckedFiles()
    if (numfiles == 0)
    {
        SoundBeep()
        Return
    }
    MyGui.Opt("+OwnDialogs")
    if (!InStr(FileExist(DefaultFolder . "\"), "D"))
        DefaultFolder := A_Desktop
    filename := FileSelect("S16", DefaultFolder . "\" . defaultfilename, "Select output text file to save the checkmarked items as coma separated values...", "Text files (*.txt)")
    if (filename == "")
        Return
    SplitPath(filename, , &DefaultFolder, &ProvidedExtension)
    if (ProvidedExtension != "txt")
        filename .= ".txt"

    Progress("A M R0-100", "Please wait...", "Saving list of " . numfiles . " files...", title)
    Progress(100)
    FileDelete(filename)
    numcols := MyListView.GetCount("Column")
    row := 0
    filenum := 1
    Loop
    {
        row := MyListView.GetNext(row, "Checked")
        if not row
            break
        line := ""
        loop numcols
        {
            colnum := A_Index
            if (colnum == 1)
                continue
            colitem := MyListView.GetText(row, colnum)
            line .= A_Quotes . colitem . A_Quotes . ","
        }
        line := Trim(line, ",")
        FileAppend(line . "`n", filename)
        filenum++
    }
    Sleep(10)
    Progress("OFF")
    Return
}

GuiLVFilesToStartMenu(*) {
    GuiLVFilesToStartMenuOrDesktop(box, sandboxes_array[box].bpath, "startmenu")
}
GuiLVFilesToDesktop(*) {
    GuiLVFilesToStartMenuOrDesktop(box, sandboxes_array[box].bpath, "desktop")
}
GuiLVFilesToStartMenuOrDesktop(box, boxpath, where)
{
    global MyListView
    numfiles := numOfCheckedFiles()
    if (numfiles == 0)
    {
        SoundBeep()
        Return
    }
    row := 0
    Loop
    {
        row := MyListView.GetNext(row, "Checked")
        if not row
            break
        GuiLVCurrentFileToStartMenuOrDesktop(row, box, boxpath, where)
    }
    Return
}

GuiLVFilesShortcut(*) {
    GuiLVFilesShortcut(box, sandboxes_array[box].bpath)
}
GuiLVFilesShortcut(box, boxpath)
{
    global start, MyListView
    numfiles := numOfCheckedFiles()
    if (numfiles == 0)
    {
        SoundBeep()
        Return
    }
    row := 0
    Loop
    {
        row := MyListView.GetNext(row, "Checked")
        if not row
            break
        GuiLVCurrentFileShortcut(row, box, boxpath)
    }
    Return
}

GuiLVFilesSaveTo(*) {
    LVFilesSaveTo(sandboxes_array[box].bpath)
}
LVFilesSaveTo(boxpath)
{
    static DefaultFolder
    global MyGui, MyListView, title
    numfiles := numOfCheckedFiles()
    if (numfiles == 0)
    {
        SoundBeep()
        Return
    }
    MyGui.Opt("+OwnDialogs")
    if (!InStr(FileExist(DefaultFolder),"D"))
        DefaultFolder := ""
    if (DefaultFolder == "")
        DefaultFolder := A_Desktop
    DefaultFolder := expandEnvVars(DefaultFolder)
    dirname := DirSelect("*" . DefaultFolder, 1, "Copy checkmarked files from sandbox to folder...`n`n********** WARNING: Existing files will be OVERWRITTEN **********")
    if (dirname == "")
        Return
    DefaultFolder := dirname
    Progress("A M R0-100", "Please wait...", "Saving " . numfiles . " files...", title)
    Progress(100)
    row := 0
    filenum := 1
    Overwrite := -1
    Loop
    {
        row := MyListView.GetNext(row, "Checked")
        if not row
            break
        LVFileName := MyListView.GetText(row, 2)
        LVSBFilePath := MyListView.GetText(row, 10)
        outfile := dirname . "\" . LVFileName
        exist := FileExist(outfile)
        if (exist && Overwrite == -1) {
            Progress("OFF")
            result := MsgBox("Warning: Some files exist already in the destination folder.`nOverwrite them?", title, 291)
            prog := ""
            Progress(round(100 * (filenum / numfiles)))
            Sleep(100)
            Progress(100)
            if (result == "Cancel")
            {
                Progress("OFF")
                Return
            }
            if (result == "Yes")
                Overwrite := 1
            else
                Overwrite := 0
        }
        if (!exist || Overwrite == 1)
            FileCopy(boxpath . "\" . LVSBFilePath . "\" . LVFileName, outfile, 1)
        filenum++
    }
    Sleep(10)
    Progress("OFF")
    Return
}

GuiLVRegistrySaveAsReg(*) {
    GuiLVRegistrySaveAsReg(box)
}
GuiLVRegistrySaveAsReg(box)
{
    global title, MyGui, MyListView, username, sandboxes_array
    static DefaultFolder
    A_Quotes := """"
    A_nl := "`n"

    bregstr_ := sandboxes_array[box].KeyRootPath
    bregstr_ := StrReplace(StrReplace(SubStr(bregstr_, 16), '`%SANDBOX`%', box), '`%USER`%', username)

    mainsbkey := bregstr_

    numregs := numOfCheckedFiles()
    if (numregs == 0)
    {
        SoundBeep()
        Return
    }
    MyGui.Opt("+OwnDialogs")
    if (!InStr(FileExist(DefaultFolder . "\"), "D"))
        DefaultFolder := A_Desktop
    filename := FileSelect("S16", DefaultFolder . "\box " . box . ".reg", "Select REG file to save the checkmarked keys and values to", "REG files (*.reg)")
    if (filename == "")
        Return
    SplitPath(filename, , &DefaultFolder, &ProvidedExtension)
    if (ProvidedExtension != "reg")
        filename .= ".reg"
    FileDelete(filename)

    ; ensure that the box is in use, or the hive will not be loaded
    run_pid := InitializeBox(box)

    row := 0
    lastrealkeypath := ""
    failed := ""
    out := "REGEDIT4" . A_nl
    Loop
    {
        line := ""
        row := MyListView.GetNext(row, "Checked")
        if not row
            break
        Status := MyListView.GetText(row, 1)
        status := SubStr(Status,1,1)
        realkeypath := MyListView.GetText(row, 2)
        keytype := MyListView.GetText(row, 3)
        keyvaluename := MyListView.GetText(row, 4)
        boxkeypath := MyListView.GetText(row, 7)
        boxkeypath := mainsbkey . "\" . boxkeypath

        if (keyvaluename == "@")
        {
            valuename := ""
            outvaluename := "@"
        }
        else
        {
            valuename := keyvaluename
            outvaluename := """" . keyvaluename . """"
        }
        if (lastrealkeypath != realkeypath)
        {
            if (keytype == "-DELETED_KEY")
                line := A_nl . "[-" . realkeypath . "]" . A_nl
            else
                line := A_nl . "[" . realkeypath . "]" . A_nl
            lastrealkeypath := realkeypath
        }
        if (keytype == "-DELETED_VALUE")
            line .= outvaluename . "=-" . A_nl
        if (keytype != "-DELETED_KEY" && keytype != "-DELETED_VALUE")
        {
            try keyvalueval := RegRead("HKEY_USERS", boxkeypath, valuename)
            catch
            {
                try keyvalueval := RegRead64("HKEY_USERS", boxkeypath, valuename, false, 65536)
                catch
                    failed .= "[" . boxkeypath . "] " . outvaluename . " (" . keytype . ")" . A_nl
            }

            if (failed == "")
            {
                if (keytype == "REG_SZ")
                {
                    keyvalueval := StrReplace(keyvalueval, "\", "\\")
                    keyvalueval := StrReplace(keyvalueval, A_Quotes, "\" . A_Quotes)
                    line .= outvaluename . "=" . A_Quotes . keyvalueval . A_Quotes . A_nl
                }
                else if (keytype == "REG_EXPAND_SZ")
                {
                    hexstr := str2hexstr(keyvalueval)
                    wrapped := WrapRegString(outvaluename . "=hex(2):" . hexstr)
                    line .= wrapped . A_nl
                }
                else if (keytype == "REG_BINARY")
                {
                    hexstr := hexstr2hexstrcomas(keyvalueval)
                    wrapped := WrapRegString(outvaluename . "=hex:" . hexstr)
                    line .= wrapped . A_nl
                }
                else if (keytype == "REG_DWORD")
                {
                    hex := dec2hex(keyvalueval,8)
                    line .= outvaluename . "=dword:" . hex . A_nl
                }
                else if (keytype == "REG_QWORD")
                {
                    hex := qword2hex(keyvalueval)
                    line .= outvaluename . "=hex(b):" . hex . A_nl
                }
                else if (keytype == "REG_MULTI_SZ")
                {
                    hexstr := str2hexstr(keyvalueval, true)
                    wrapped := WrapRegString(outvaluename . "=hex(7):" . hexstr)
                    line .= wrapped . A_nl
                }
                else
                {
                    failed .= "[" . boxkeypath . "] " . outvaluename . " (" . keytype . ")" . A_nl
                }
            }
        }
        out .= line
    }

    FileAppend(out, filename)
    if (failed != "") {
        MsgBox("Warning! Some key values cannot be saved due to unsupported key type:`n`n" . failed, title, 48)
    }

    ReleaseBox(run_pid)

    Return
}

WrapRegString(str)
{
    if (StrLen(str) <= 80)
        return str

    local out := ""
    local line_len := 78
    local first_line := true

    while (StrLen(str) > 0)
    {
        local prefix := ""
        if (!first_line)
            prefix := "  "

        local current_line_len := line_len - StrLen(prefix)
        local chunk
        if (StrLen(str) > current_line_len)
        {
            local break_pos := 0
            loop current_line_len {
                local pos := current_line_len - A_Index + 1
                if (SubStr(str, pos, 1) == ",") {
                    break_pos := pos
                    break
                }
            }

            if (break_pos == 0)
                break_pos := current_line_len

            chunk := SubStr(str, 1, break_pos)
            str := SubStr(str, break_pos + 1)
            out .= prefix . chunk . "\`n"
        }
        else
        {
            chunk := str
            str := ""
            out .= prefix . chunk
        }
        first_line := false
    }
    return out
}

numOfCheckedFiles()
{
    global MyListView
    num := 0
    row := 0
    Loop
    {
        row := MyListView.GetNext(row, "Checked")
        if not row
            break
        num++
    }
    return num
}

; ###################################################################################################
; Registry functions
; ###################################################################################################

; A_LoopRegName ; Name of the currently retrieved item, which can be either a value name or the name of a subkey. Value names displayed by Windows RegEdit as "(Default)" will be retrieved if a value has been assigned to them, but A_LoopRegName will be blank for them.
; A_LoopRegType ; The type of the currently retrieved item, which is one of the following words: KEY (i.e. the currently retrieved item is a subkey not a value), REG_SZ, REG_EXPAND_SZ, REG_MULTI_SZ, REG_DWORD, REG_QWORD, REG_BINARY, REG_LINK, REG_RESOURCE_LIST, REG_FULL_RESOURCE_DESCRIPTOR, REG_RESOURCE_REQUIREMENTS_LIST, REG_DWORD_BIG_ENDIAN (probably rare on most Windows hardware). It will be empty if the currently retrieved item is of an unknown type.
; A_LoopRegKey ; The name of the root key being accessed (HKEY_LOCAL_MACHINE, HKEY_USERS, HKEY_CURRENT_USER, HKEY_CLASSES_ROOT, or HKEY_CURRENT_CONFIG). For remote registry access, this value will not include the computer name.
; A_LoopRegSubKey ; Name of the current SubKey. This will be the same as the Key parameter unless the Recurse parameter is being used to recursively explore other subkeys. In that case, it will be the full bpath of the currently retrieved item, not including the root key. For example: Software\SomeApplication\My SubKey
; A_LoopRegTimeModified ; The time the current subkey or any of its values was last modified. Format YYYYMMDDHH24MISS. This variable will be empty if the currently retrieved item is not a subkey (i.e. A_LoopRegType is not the word KEY) or if the operating system is Win9x (since Win9x does not track this info).
; Rarely used undocumented value types: REG_QWORD, REG_LINK, REG_RESOURCE_LIST, REG_FULL_RESOURCE_DESCRIPTOR,
; REG_RESOURCE_REQUIREMENTS_LIST, REG_DWORD_BIG_ENDIAN

GetReg(inrootkey, insubkey, outrootkey, outsubkey)
{
    local outtxt := ""
    local insubkeylen := StrLen(insubkey) + 1
    local outfullkey := outrootkey
    if (outsubkey != "")
        outfullkey .= "\" . outsubkey

    Loop Reg, inrootkey . "\" . insubkey, "KVR"
    {
        local subkey := outfullkey . SubStr(A_LoopRegSubKey, insubkeylen)
        local value := ""
        if (A_LoopRegType != "KEY")
        {
            try value := RegRead(A_LoopRegFullPath, A_LoopRegName)
        }
        outtxt .= A_LoopRegTimeModified . " " . A_LoopRegType . " " . A_LoopRegName . " " . subkey . " " . value . "`n"
    }
    return outtxt
}

FormatRegConfigKey(RegSubKey, subkey, RegType, RegName, RegTimeModified, separator, includedate := false)
{
    local type := RegType
    if (type == "") {
        try type := RegRead64KeyType("HKEY_USERS", RegSubKey, RegName, false)
        catch
            type := "UNKNOWN"
    }

    local status := (RegTimeModified == "19860523174702") ? "-" : "+"
    if (type == "REG_SB_DELETED") {
        status := "-"
        type := "-DELETED_VALUE"
    }

    local value := ""
    try {
        value := RegRead("HKEY_USERS\" . RegSubKey, RegName)
    } catch {
        try {
            value := RegRead64("HKEY_USERS", RegSubKey, RegName)
        } catch {
            try {
                value := RegRead64("HKEY_USERS", RegSubKey, RegName, false)
            } catch {
                value := ""
                status := "-"
            }
        }
    }

    if (InStr(type, "_SZ")) {
        value := StrReplace(value, "`n", " ")
        if (type == "REG_MULTI_SZ")
            value := RTrim(value, "`n")
    }
    if (StrLen(value) > 80)
        value := SubStr(value, 1, 80) . "..."

    local name := RegName == "" ? "@" : RegName

    local outtxt := ""
    if (type == "KEY") {
        if (status == "-")
            type := "-DELETED_KEY"
        outtxt := status . separator . subkey . "\" . name . separator . type . separator . separator
    } else {
        outtxt := status . separator . subkey . separator . type . separator . name . separator . value
    }
    if (includedate)
        outtxt .= separator . RegTimeModified
    return outtxt
}

MakeFilesConfig(box, filename, mainsbpath)
{
    local mainsbpathlen := StrLen(mainsbpath) + 2
    local outtxt := ""

    Loop Files, mainsbpath . "\*", "FDR"
    {
        local status := (A_LoopFileTimeCreated == "19860523174702") ? "-" : "+"
        if (InStr(A_LoopFileAttrib, "D") && status == "+")
            Continue
        local name := SubStr(A_LoopFileFullPath, mainsbpathlen)
        outtxt .= status . " " . A_LoopFileTimeModified . " " . name . ":*:`n"
    }

    FileDelete(filename)
    FileAppend("`n" . outtxt, filename)
    Return
}

MakeRegConfig(box, filename := "")
{
    global regconfig, sandboxes_array
    run_pid := InitializeBox(box)

    local bregstr_ := sandboxes_array[box].KeyRootPath
    bregstr_ := StrReplace(StrReplace(SubStr(bregstr_, 16), '`%SANDBOX`%', box), '`%USER`%', A_UserName)

    local mainsbkey := bregstr_
    local mainsbkeylen := StrLen(mainsbkey) + 2
    local outtxt := ""

    Loop Reg, "HKEY_USERS\" . mainsbkey, "KVR"
    {
        local RegTimeModified := A_LoopRegTimeModified

        if (A_LoopRegType == "KEY" && RegTimeModified != "19860523174702")
            Continue

        local subkey := SubStr(A_LoopRegSubKey, mainsbkeylen)
        local out := FormatRegConfigKey(A_LoopRegSubKey, subkey, A_LoopRegType, A_LoopRegName, RegTimeModified, A_Space)
        outtxt .= out . "`n"
    }

    if (filename == "")
        filename := regconfig
    FileDelete(filename)
    FileAppend("`n" . outtxt, filename)

    ReleaseBox(run_pid)
    Return
}

SearchReg(box, ignoredKeys, ignoredValues, filename := "")
{
    global regconfig, sandboxes_array, listemptyitems
    run_pid := InitializeBox(box)

    local bregstr_ := sandboxes_array[box].KeyRootPath
    bregstr_ := StrReplace(StrReplace(SubStr(bregstr_, 16), '`%SANDBOX`%', box), '`%USER`%', A_UserName)

    local mainsbkey := bregstr_
    local mainsbkeylen := StrLen(mainsbkey) + 2

    if (filename == "")
        filename := regconfig
    local regconfigdata := FileRead(filename)
    local outArr := []
    local LastIgnoredKey := "!xxx!:\"

    Loop Reg, "HKEY_USERS\" . mainsbkey, "KVR"
    {
        local RegTimeModified := A_LoopRegTimeModified
        local subkey := SubStr(A_LoopRegSubKey, mainsbkeylen)

        if (InStr(subkey, LastIgnoredKey) == 1)
            continue

        local is_key_without_values := false
        if (A_LoopRegType == "KEY" && listemptyitems)
        {
            local hasValues := false
            Loop Reg, A_LoopRegFullPath, "V"
            {
                hasValues := true
                break
            }
            if (!hasValues)
                is_key_without_values := true
        }

        if (A_LoopRegType == "KEY") {
            if (RegTimeModified != "19860523174702" && !is_key_without_values)
                Continue
            if (IsIgnored("keys", ignoredKeys, subkey . "\" . A_LoopRegName)) {
                LastIgnoredKey := subkey . "\" . A_LoopRegName
                Continue
            }
        }
        else {
            if (A_LoopRegName == "") {
                if (IsIgnored("values", ignoredValues, subkey, "@"))
                    Continue
            }
            else {
                if (IsIgnored("values", ignoredValues, subkey, A_LoopRegName))
                    Continue
            }
        }
        if (IsIgnored("keys", ignoredKeys, subkey)) {
            LastIgnoredKey := subkey
            Continue
        }

        local out := FormatRegConfigKey(A_LoopRegSubKey, subkey, A_LoopRegType, A_LoopRegName, RegTimeModified, A_Space)
        if (is_key_without_values || !InStr(regconfigdata, out)) {
            out := FormatRegConfigKey(A_LoopRegSubKey, subkey, A_LoopRegType, A_LoopRegName, RegTimeModified, Chr(1), true)
            outArr.Push(out)
        }
    }

    ReleaseBox(run_pid)
    return outArr
}

ListReg(box, bpath, filename="")
{
    global ignoredDirs, ignoredFiles, ignoredKeys, ignoredValues
    global guinotclosed, title, MyListView, LVLastSize
    global newIgnored, guinotclosed, title, MyListView, LVLastSize, listemptyitems
    static MainLabel

    local comparemode := filename != ""
    A_Quotes := '"'

    ReadIgnoredConfig("reg")
    newIgnored := Map("keys", "", "values", "")

    Progress(1,"Please wait...", "Scanning registry of box """ . box . """...", title)

    ignoredKeys := StrReplace(ignoredKeys, ":", ".",, 1)
    allregs_array := SearchReg(box, ignoredKeys, ignoredValues, filename)

    Progress(90,"Please wait...", "Sorting list of keys in box """ . box . """...", title)
    Sleep(150)
    if (allregs_array.Length > 0)
        allregs_array.Sort("CL")
    local numregs := allregs_array.Length
    if (numregs = 0)
    {
        Progress(0)
        if (comparemode)
            MsgBox("No registry keys or values have been modified in box """ . box . """!",, "IconInfo")
        else
            MsgBox("No meaningful registry keys or values found in box """ . box . """!",, "IconInfo")
        Return
    }

    if (LVLastSize == "") {
        local mon := SysGet("MonitorWorkArea")
        local width, height
        if (mon.Right == "") {
            width := A_ScreenWidth - 300
            height := A_ScreenHeight - 300
        } else {
            width := mon.Right - mon.Left - 250
            height := mon.Bottom - mon.Top - 250
        }
        if (width < 752)
            width := 752
        local maxrows := height / 18
        local numrows
        if (numregs < maxrows)
        {
            if (numregs < 3)
                numrows := 3
            else
                numrows := numregs
            numrows += 2
            local heightarg := "r" . numrows
        } else
            heightarg := "h" . height
        LVLastSize := "w" . width . " " . heightarg
    }

    MyGui := Gui("+Resize")
    MyGui.Title := title . " - Registry of box """ . box . """"
    if (comparemode)
        MyGui.Title .= " (Changes)"
    MainLabel := MyGui.Add("Text", "w900", "Find Registry Keys...")

    FileMenu := Menu()
    FileMenu.Add("Save Checkmarked entries as &REG file", GuiLVRegistrySaveAsReg)
    FileMenu.Add()
    FileMenu.Add("Save Checkmarked entries as CSV &Text", GuiLVRegistrySaveAsText)

    EditMenu := Menu()
    EditMenu.Add("&Clear All Checkmarks", GuiLVClearAllCheckmarks)
    EditMenu.Add("&Toggle All Checkmarks", GuiLVToggleAllCheckmarks)
    EditMenu.Add("Toggle &Selected Checkmarks", GuiLVToggleSelected)
    EditMenu.Add()
    EditMenu.Add("&Hide Selected Entries", GuiLVHideSelected)
    EditMenu.Add()
    EditMenu.Add("Add Selected &Values to Ignore List", GuiLVIgnoreSelectedValues)
    EditMenu.Add("Add Selected &Keys to Ignore List", GuiLVIgnoreSelectedKeys)

    LVMenuBar := Menu()
    LVMenuBar.Add("&File", FileMenu)
    LVMenuBar.Add("&Edit", EditMenu)
    MyGui.Menu := LVMenuBar

    PopupMenu := Menu()
    PopupMenu.Add("Copy Key to Clipboard", GuiLVCurrentCopyToClipboard)
    PopupMenu.Add("Open Key in RegEdit", GuiLVCurrentOpenRegEdit)
    PopupMenu.Add()
    PopupMenu.Add("Toggle Checkmark", GuiLVToggleCurrent)
    PopupMenu.Add()
    PopupMenu.Add("Hide from this list", GuiLVHideCurrent)
    PopupMenu.Add()
    PopupMenu.Add("Add Value to Ignore List", GuiLVIgnoreCurrentValue)
    PopupMenu.Add("Add Key to Ignore List", GuiLVIgnoreCurrentKey)
    PopupMenu.Add("Add Sub-Key to Ignore List...", GuiLVIgnoreCurrentSubKey)

    MyListView := MyGui.Add("ListView", "x10 y30 " . LVLastSize . " Checked AltSubmit", ["Status", "Key", "Type", "Value Name", "Value Data", "Key modified time", "Sandbox bpath"])
    MyListView.OnEvent("DoubleClick", GuiLVCurrentOpenRegEdit)
    MyListView.OnEvent("RightClick", (ctl, info) => PopupMenu.Show())
    MyGui.OnEvent("Size", GuiSize)
    MyGui.OnEvent("Close", (*) => guinotclosed := 0)

    Progress(100,"Please wait...", "Building list of keys in box """ . box . """...", title)
    Sleep(100)

    ; add entries in listview
    local nummodified := 0, numadded := 0, numdeleted := 0
    MyListView.Redraw := false
    local sep := Chr(1)
    for _, entry in allregs_array
    {
        local fields := StrSplit(entry, sep)
        local St := fields[1]
        local keypath := fields[2]
        local realkeypath := ""
        if (SubStr(keypath, 1, 8) == "machine\")
            realkeypath := "HKEY_LOCAL_MACHINE" . SubStr(keypath, 8)
        else if (SubStr(keypath, 1, 13) == "user\current\")
            realkeypath := "HKEY_CURRENT_USER" . SubStr(keypath, 13)
        else if (SubStr(keypath, 1, 21) == "user\current_classes\")
            realkeypath := "HKEY_CLASSES_ROOT" . SubStr(keypath, 21)

        local keytype := fields[3]
        local keyvaluename := fields[4]
        local keyvalueval := fields[5]
        local modtime := ""
        if fields.Length >= 6
            modtime := FormatTime(fields[6], "yyyy/MM/dd HH:mm:ss")
        if (St == "+") {
            if (keytype != "KEY")
            {
                local idx := InStr(realkeypath, "\")
                local realrootkey := SubStr(realkeypath, 1, idx - 1)
                local realsubkey := SubStr(realkeypath, idx + 1)
                local realkeyvaluename
                if (keyvaluename == "@")
                    realkeyvaluename := ""
                else
                    realkeyvaluename := keyvaluename
                try {
                    RegRead(realrootkey, realsubkey, realkeyvaluename)
                    St := "#"
                } catch {
                    try {
                        RegRead64KeyType(realrootkey, realsubkey, realkeyvaluename)
                        St := "#"
                    }
                }
            }
        } else {
            modtime := ""
        }
        if (St == "#")
            nummodified++
        else if (St == "+")
            numadded++
        else if (St == "-")
            numdeleted++
        MyListView.Add("", St . A_Space, realkeypath, keytype, keyvaluename, keyvalueval, modtime, keypath)
    }
    Sleep(10)

    MyListView.ModifyCol()
    MyListView.ModifyCol(2, "Sort")

    local msg := "Found " . numregs . " registry key"
    if (numregs != 1)
        msg .= "s or values"
    else
        msg .= " or value"
    msg .= " in the sandbox """ . box . """"
    msg .= " : # " . nummodified . " modified"
    msg .= " , + " . numadded . " new"
    msg .= " , - " . numdeleted . " deleted"
    msg .= ". Double-click a key to open it in RegEdit."
    MainLabel.Text := msg

    Progress(0)
    MyListView.Redraw := true
    MyGui.Show()

    guinotclosed := 1
    while (guinotclosed)
        Sleep(1000)
    SaveNewIgnoredItems("reg")

    return
}

SearchAutostart(box, regpath, location, tick)
{
    local outArr := []
    Loop Reg, "HKEY_USERS\" . regpath
    {
        if (A_LoopRegType != "REG_SZ")
            Continue
        outArr.Push(A_LoopRegName . A_Tab . A_LoopRegValue . A_Tab . location . A_Tab . tick)
    }
    outArr.Sort("CL")
    Return outArr
}
ListAutostarts(box, bpath)
{
    global guinotclosed, title, MyListView, LVLastSize, sandboxes_array, username
    static MainLabel

    A_Quotes := '"'
    A_nl := "`n"

    bregstr_ := sandboxes_array[box].KeyRootPath
    bregstr_ := StrReplace(StrReplace(SubStr(bregstr_, 16), '`%SANDBOX`%', box), '`%USER`%', username)

    run_pid := InitializeBox(box)
    Sleep(1000)

    local autostarts := ""
    local key, location

    ; check RunOnce keys
    key := bregstr_ . '\machine\Software\Microsoft\Windows\CurrentVersion\RunOnce'
    location := "HKLM RunOnce"
    autostarts .= SearchAutostart(box, key, location, 0)

    key := bregstr_ . '\machine\Software\Wow6432Node\Microsoft\Windows\CurrentVersion\RunOnce'
    autostarts .= SearchAutostart(box, key, location, 0)

    key := bregstr_ . '\user\current\Software\Microsoft\Windows\CurrentVersion\RunOnce'
    location := "HKCU RunOnce"
    autostarts .= SearchAutostart(box, key, location, 0)

    key := bregstr_ . '\user\current\Software\Wow6432Node\Microsoft\Windows\CurrentVersion\RunOnce'
    autostarts .= SearchAutostart(box, key, location, 0)

    ; check Run keys
    key := bregstr_ . '\machine\Software\Microsoft\Windows\CurrentVersion\Run'
    location := "HKLM Run"
    autostarts .= SearchAutostart(box, key, location, 1)

    key := bregstr_ . '\machine\Software\Wow6432Node\Microsoft\Windows\CurrentVersion\Run'
    autostarts .= SearchAutostart(box, key, location, 1)

    key := bregstr_ . '\user\current\Software\Microsoft\Windows\CurrentVersion\Run'
    location := "HKCU Run"
    autostarts .= SearchAutostart(box, key, location, 1)

    key := bregstr_ . '\user\current\Software\Wow6432Node\Microsoft\Windows\CurrentVersion\Run'
    autostarts .= SearchAutostart(box, key, location, 1)

    ReleaseBox(run_pid)

    autostarts := Trim(autostarts, A_nl)
    local autostarts_array := autostarts ? StrSplit(autostarts, "`n") : []
    local numregs := autostarts_array.Length
    if (numregs = 0)
    {
        MsgBox("No autostart programs found in the registry of box """ . box . """.",, "IconInfo")
        Return
    }

    if (LVLastSize == "") {
        local mon := SysGet("MonitorWorkArea")
        local width, height
        if (mon.Right == "") {
            width := A_ScreenWidth - 300
            height := A_ScreenHeight - 300
        } else {
            width := mon.Right - mon.Left - 250
            height := mon.Bottom - mon.Top - 250
        }
        if (width < 752)
            width := 752
        local maxrows := height / 18
        local numrows
        if (numregs < maxrows)
        {
            if (numregs < 3)
                numrows := 3
            else
                numrows := numregs
            numrows += 2
            local heightarg := "r" . numrows
        } else
            heightarg := "h" . height
        LVLastSize := "w" . width . " " . heightarg
    }

    MyGui := Gui("+Resize")
    MyGui.Title := title . " - Autostart programs in registry of box """ . box . """"
    MainLabel := MyGui.Add("Text", "w900", "Registry Autostarts...")

    FileMenu := Menu()
    FileMenu.Add("Copy Checkmarked Entries to Start Menu\Startup of Sandbox", GuiLVRegistryToStartMenuStartup)
    FileMenu.Add()
    FileMenu.Add("Explore Current User's Startup Menu (Unsandboxed)", GuiLVRegistryExploreStartMenuCU)
    FileMenu.Add("Explore Current User's Startup Menu (Sandboxed)", GuiLVRegistryExploreStartMenuCS)
    FileMenu.Add("Explore All Users Startup Menu (Unsandboxed)", GuiLVRegistryExploreStartMenuAU)
    FileMenu.Add("Explore All Users Startup Menu (Sandboxed)", GuiLVRegistryExploreStartMenuAS)

    EditMenu := Menu()
    EditMenu.Add("&Clear All Checkmarks", GuiLVClearAllCheckmarks)
    EditMenu.Add("&Toggle All Checkmarks", GuiLVToggleAllCheckmarks)
    EditMenu.Add("Toggle &Selected Checkmarks", GuiLVToggleSelected)
    EditMenu.Add()
    EditMenu.Add("&Hide Selected Entries", GuiLVHideSelected)

    LVMenuBar := Menu()
    LVMenuBar.Add("&File", FileMenu)
    LVMenuBar.Add("&Edit", EditMenu)
    MyGui.Menu := LVMenuBar

    PopupMenu := Menu()
    PopupMenu.Add("Run in Sandbox", GuiLVRegistryRun)
    PopupMenu.Add("Copy to Start Menu\Startup of Sandbox", GuiLVRegistryItemToStartMenuStartup)
    PopupMenu.Add()
    PopupMenu.Add("Toggle Checkmark", GuiLVToggleCurrent)
    PopupMenu.Add()
    PopupMenu.Add("&Hide from this list", GuiLVHideCurrent)

    MyListView := MyGui.Add("ListView", "x10 y30 " . LVLastSize . " Checked AltSubmit", ["Status", "Program", "Command", "Location"])
    MyListView.OnEvent("DoubleClick", GuiLVRegistryRun)
    MyListView.OnEvent("RightClick", (ctl, info) => PopupMenu.Show())
    MyGui.OnEvent("Size", GuiSize)
    MyGui.OnEvent("Close", (*) => guinotclosed := 0)

    ; icons array
    local ImageListID1 := IL_Create(10)
    MyListView.SetImageList(ImageListID1)

    ; add entries in listview
    MyListView.Redraw := false
    local sep := Chr(1)
    local row := 1
    for _, entry in autostarts_array
    {
        local fields := StrSplit(entry, A_Tab)
        local valuename := fields[1]
        local valuedata := fields[2]
        local location := fields[3]
        local ticked := fields[4]
        if (valuedata != "")
        {
            local program := valuedata
            if (SubStr(valuedata, 1, 1) == A_Quotes)
            {
                local idx2 := InStr(valuedata, A_Quotes, 0, 2)
                if (idx2)
                    program := SubStr(valuedata, 2, idx2 - 2)
            }
            local boxprogram := StdPathToBoxPath(box, program)
            if (!FileExist(boxprogram))
                boxprogram := program
            local hIcon := GetAssociatedIcon(boxprogram, false, 16, box)
            local IconNumber := DllCall("ImageList_ReplaceIcon", "uint", ImageListID1, "int", -1, "uint", hIcon) + 1
            MyListView.Add("Icon" . IconNumber, "", valuename, valuedata, location)
            if (ticked)
                MyListView.Modify(row, "Check")
        }
        else
            MyListView.Add("Icon0", "", valuename, "", location)

        row++
    }
    MyListView.ModifyCol()

    local msg := "Found " . numregs . " autostart program"
    if (numregs != 1)
        msg .= "s"
    msg .= " in the sandbox """ . box . """."
    msg .= " Double-click an entry to run it."
    MainLabel.Text := msg
    MyListView.Redraw := true
    MyGui.Show()

    guinotclosed := 1
    while (guinotclosed)
        Sleep(1000)
    return
}

; _reg64.ahk ver 0.1 by tomte
; Script for AutoHotkey   ( http://www.autohotkey.com/ )
;
; Provides RegRead64() and RegWrite64() functions that do not redirect to Wow6432Node on 64-bit machines
; RegRead64() and RegWrite64() takes the same parameters as regular AHK RegRead and RegWrite commands, plus one optional DataMaxSize param for RegRead64()
;
; RegRead64() can handle the same types of values as AHK RegRead:
; REG_SZ, REG_EXPAND_SZ, REG_MULTI_SZ, REG_DWORD, and REG_BINARY
; (values are returned in same fashion as with RegRead - REG_BINARY as hex string, REG_MULTI_SZ split with linefeed etc.)
;
; RegWrite64() can handle REG_SZ, REG_EXPAND_SZ and REG_DWORD only
;
; Usage:
; myvalue := RegRead64("HKEY_LOCAL_MACHINE", "SOFTWARE\SomeCompany\Product\Subkey", "valuename")
; RegWrite64("REG_SZ", "HKEY_LOCAL_MACHINE", "SOFTWARE\SomeCompany\Product\Subkey", "valuename", "mystring")
; If the value name is blank/omitted the subkey's default value is used, if the value is omitted with RegWrite64() a blank/zero value is written
;
; argument to read either in 64bit or 32bit mode added by r0lZ
RegRead64(sRootKey, sKeyName, sValueName="", mode64bit=true, DataMaxSize=1024) {
    static keyMap := Map(
        "HKEY_CLASSES_ROOT", 0x80000000, "HKEY_CURRENT_USER", 0x80000001, "HKEY_LOCAL_MACHINE", 0x80000002,
        "HKEY_USERS", 0x80000003, "HKEY_CURRENT_CONFIG", 0x80000005, "HKEY_DYN_DATA", 0x80000006
    )
    static REG_NONE := 0, REG_SZ := 1, REG_EXPAND_SZ := 2, REG_BINARY := 3, REG_DWORD := 4,
           REG_DWORD_BIG_ENDIAN := 5, REG_LINK := 6, REG_MULTI_SZ := 7, REG_RESOURCE_LIST := 8,
           REG_FULL_RESOURCE_DESCRIPTOR := 9, REG_RESOURCE_REQUIREMENTS_LIST := 10, REG_QWORD := 11
    static KEY_QUERY_VALUE := 0x0001, KEY_WOW64_64KEY := 0x0100, KEY_WOW64_32KEY := 0x0200

    if !keyMap.Has(sRootKey) {
        throw Error("Invalid root key specified.")
    }
    local myhKey := keyMap[sRootKey]
    local RegAccessRight := mode64bit ? (KEY_QUERY_VALUE | KEY_WOW64_64KEY) : (KEY_QUERY_VALUE | KEY_WOW64_32KEY)

    local hKey := 0
    if DllCall("Advapi32.dll\RegOpenKeyEx", "ptr", myhKey, "str", sKeyName, "uint", 0, "uint", RegAccessRight, "ptr*", &hKey) != 0 {
        throw Error("Failed to open registry key.")
    }
    defer DllCall("Advapi32.dll\RegCloseKey", "ptr", hKey)

    local sValueType := 0, vValueSize := 0
    DllCall("Advapi32.dll\RegQueryValueEx", "ptr", hKey, "str", sValueName, "ptr", 0, "uint*", &sValueType, "ptr", 0, "uint*", &vValueSize)

    local sValue
    if (sValueType == REG_SZ || sValueType == REG_EXPAND_SZ) {
        sValue := Buffer(vValueSize)
        DllCall("Advapi32.dll\RegQueryValueEx", "ptr", hKey, "str", sValueName, "ptr", 0, "ptr", 0, "str", sValue, "uint*", &vValueSize)
        return StrGet(sValue)
    } else if (sValueType == REG_DWORD || sValueType == REG_DWORD_BIG_ENDIAN) {
        local dwordValue := 0
        DllCall("Advapi32.dll\RegQueryValueEx", "ptr", hKey, "str", sValueName, "ptr", 0, "ptr", 0, "uint*", &dwordValue, "uint*", &vValueSize)
        return dwordValue
    } else if (sValueType == REG_QWORD) {
        local qwordValue := 0
        DllCall("Advapi32.dll\RegQueryValueEx", "ptr", hKey, "str", sValueName, "ptr", 0, "ptr", 0, "uint64*", &qwordValue, "uint*", &vValueSize)
        return qwordValue
    } else if (sValueType == REG_MULTI_SZ) {
        local sTmp := Buffer(vValueSize)
        DllCall("Advapi32.dll\RegQueryValueEx", "ptr", hKey, "str", sValueName, "ptr", 0, "ptr", 0, "ptr", sTmp, "uint*", &vValueSize)
        local result := ""
        local offset := 0
        while offset < vValueSize - 1 {
            local part := StrGet(sTmp.Ptr + offset)
            if part == ""
                break
            result .= part . "`n"
            offset += (StrLen(part) + 1) * (A_IsUnicode ? 2 : 1)
        }
        return result
    } else if (sValueType == REG_BINARY) {
        local sTmp := Buffer(vValueSize)
        DllCall("Advapi32.dll\RegQueryValueEx", "ptr", hKey, "str", sValueName, "ptr", 0, "ptr", 0, "ptr", sTmp, "uint*", &vValueSize)
        local result := ""
        Loop vValueSize {
            result .= Format("{:02X}", NumGet(sTmp, A_Index - 1, "UChar"))
        }
        return result
    } else if (sValueType == REG_NONE) {
        return ""
    } else {
        throw Error("Unsupported value type or value does not exist.")
    }
}

RegRead64KeyType(sRootKey, sKeyName, sValueName = "", mode64bit=true) {
    static keyMap := Map(
        "HKEY_CLASSES_ROOT", 0x80000000, "HKEY_CURRENT_USER", 0x80000001, "HKEY_LOCAL_MACHINE", 0x80000002,
        "HKEY_USERS", 0x80000003, "HKEY_CURRENT_CONFIG", 0x80000005, "HKEY_DYN_DATA", 0x80000006
    )
    static typeMap := Map(
        0, "REG_NONE", 1, "REG_SZ", 2, "REG_EXPAND_SZ", 3, "REG_BINARY", 4, "REG_DWORD",
        5, "REG_DWORD_BIG_ENDIAN", 6, "REG_LINK", 7, "REG_MULTI_SZ", 8, "REG_RESOURCE_LIST",
        9, "REG_FULL_RESOURCE_DESCRIPTOR", 10, "REG_RESOURCE_REQUIREMENTS_LIST", 11, "REG_QWORD",
        0x786F6273, "REG_SB_DELETED"
    )
    static KEY_QUERY_VALUE := 0x0001, KEY_WOW64_64KEY := 0x0100, KEY_WOW64_32KEY := 0x0200

    if !keyMap.Has(sRootKey) {
        throw Error("Invalid root key specified.")
    }
    local myhKey := keyMap[sRootKey]

    local RegAccessRight := mode64bit ? (KEY_QUERY_VALUE | KEY_WOW64_64KEY) : (KEY_QUERY_VALUE | KEY_WOW64_32KEY)

    local hKey := 0
    if DllCall("Advapi32.dll\RegOpenKeyEx", "ptr", myhKey, "str", sKeyName, "uint", 0, "uint", RegAccessRight, "ptr*", &hKey) != 0 {
        throw Error("Failed to open registry key.")
    }
    defer DllCall("Advapi32.dll\RegCloseKey", "ptr", hKey)

    local sValueType := 0
    DllCall("Advapi32.dll\RegQueryValueEx", "ptr", hKey, "str", sValueName, "ptr", 0, "uint*", &sValueType, "ptr", 0, "ptr", 0)

    return typeMap.Has(sValueType) ? typeMap[sValueType] : ""
}

RegEnumKey(sRootKey, sKeyName, x64mode=true) {
    static keyMap := Map(
        "HKEY_CLASSES_ROOT", 0x80000000, "HKEY_CURRENT_USER", 0x80000001, "HKEY_LOCAL_MACHINE", 0x80000002,
        "HKEY_USERS", 0x80000003, "HKEY_CURRENT_CONFIG", 0x80000005, "HKEY_DYN_DATA", 0x80000006
    )
    static KEY_ENUMERATE_SUB_KEYS := 0x0008, KEY_WOW64_64KEY := 0x0100, KEY_WOW64_32KEY := 0x0200
    static ERROR_NO_MORE_ITEMS := 259

    if !keyMap.Has(sRootKey) {
        throw Error("Invalid root key specified.")
    }
    local myhKey := keyMap[sRootKey]

    local RegAccessRight := x64mode ? (KEY_ENUMERATE_SUB_KEYS | KEY_WOW64_64KEY) : (KEY_ENUMERATE_SUB_KEYS | KEY_WOW64_32KEY)

    local hKey := 0
    if DllCall("Advapi32.dll\RegOpenKeyEx", "ptr", myhKey, "str", sKeyName, "uint", 0, "uint", RegAccessRight, "ptr*", &hKey) != 0 {
        throw Error("Failed to open registry key.")
    }
    defer DllCall("Advapi32.dll\RegCloseKey", "ptr", hKey)

    local names := []
    local dwIndex := 0
    local lpName := Buffer(512 * (A_IsUnicode ? 2 : 1))

    while DllCall("Advapi32.dll\RegEnumKeyEx", "ptr", hKey, "uint", dwIndex, "str", lpName, "uint*", 512, "ptr", 0, "ptr", 0, "ptr", 0, "ptr", 0) == 0 {
        names.Push(StrGet(lpName))
        dwIndex++
    }

    names.Sort("CL")
    return names
}

RegEnumValue(sRootKey, sKeyName, x64mode=true) {
    static keyMap := Map(
        "HKEY_CLASSES_ROOT", 0x80000000, "HKEY_CURRENT_USER", 0x80000001, "HKEY_LOCAL_MACHINE", 0x80000002,
        "HKEY_USERS", 0x80000003, "HKEY_CURRENT_CONFIG", 0x80000005, "HKEY_DYN_DATA", 0x80000006
    )
    static KEY_QUERY_VALUE := 0x0001, KEY_WOW64_64KEY := 0x0100, KEY_WOW64_32KEY := 0x0200
    static ERROR_NO_MORE_ITEMS := 259

    if !keyMap.Has(sRootKey) {
        throw Error("Invalid root key specified.")
    }
    local myhKey := keyMap[sRootKey]

    local RegAccessRight := x64mode ? (KEY_QUERY_VALUE | KEY_WOW64_64KEY) : (KEY_QUERY_VALUE | KEY_WOW64_32KEY)

    local hKey := 0
    if DllCall("Advapi32.dll\RegOpenKeyEx", "ptr", myhKey, "str", sKeyName, "uint", 0, "uint", RegAccessRight, "ptr*", &hKey) != 0 {
        throw Error("Failed to open registry key.")
    }
    defer DllCall("Advapi32.dll\RegCloseKey", "ptr", hKey)

    local lpcMaxValueNameLen := 0
    DllCall("Advapi32.dll\RegQueryInfoKey", "ptr", hKey, "ptr", 0, "ptr", 0, "ptr", 0, "ptr", 0, "ptr", 0, "ptr", 0, "ptr", 0, "uint*", &lpcMaxValueNameLen, "ptr", 0, "ptr", 0, "ptr", 0)

    local names := []
    local dwIndex := 0
    local lpName := Buffer((lpcMaxValueNameLen + 1) * (A_IsUnicode ? 2 : 1))

    while DllCall("Advapi32.dll\RegEnumValue", "ptr", hKey, "uint", dwIndex, "wstr", lpName, "uint*", lpcMaxValueNameLen + 1, "ptr", 0, "ptr", 0, "ptr", 0, "ptr", 0) == 0 {
        names.Push(StrGet(lpName))
        dwIndex++
    }

    names.Sort("CL")
    return names
}

; ###########################################
; Dec/Hex and String/Hex conversion functions
; ###########################################

dec2hex(dec, minlength := 2) {
    hex := Format("{:X}", dec)
    while (StrLen(hex) < minlength) {
        hex := "0" . hex
    }
    if (Mod(StrLen(hex), 2) != 0) {
        hex := "0" . hex
    }
    return hex
}

qword2hex(qword) {
    if (qword < 0) {
        qword := ~qword
        hex := Format("{:08X}{:08X}", qword >> 32, qword & 0xFFFFFFFF)
    } else {
        hex := Format("{:X}", qword)
        while (StrLen(hex) < 16) {
            hex := "0" . hex
        }
    }

    out := ""
    loop 8 {
        out .= SubStr(hex, (A_Index - 1) * 2 + 1, 2) . ","
    }
    return Trim(out, ",")
}

hexstr2hexstrcomas(hex) {
    out := ""
    loop, StrLen(hex) {
        out .= SubStr(hex, A_Index, 1)
        if (Mod(A_Index, 2) == 0) {
            out .= ","
        }
    }
    return Trim(out, ",")
}

hexstr2str(hexstr) {
    str := ""
    loop, StrLen(hexstr) / 2 {
        str .= Chr("0x" . SubStr(hexstr, (A_Index - 1) * 2 + 1, 2))
    }
    return str
}

str2hexstr(str, replacenlwithzero := false) {
    out := ""
    ; TODO: convert really to UTF-16
    loop, Parse, str {
        h := Format("{:X}", Asc(A_LoopField))
        if (replacenlwithzero && h == "A") {
            out .= "00,"
        } else {
            if (StrLen(h) == 1) {
                out .= "0" . h . ","
            } else {
                out .= h . ","
            }
        }
    }
    out .= "00"
    return out
}

; mode = hide (just temporarly hide entries: do not
Return

; Add a registry key or value or a folder or file to the ignore list
; mode = values, keys, files or dirs
LVIgnoreSelected(mode)
{
    global MyListView
    local A_nl := "`n"
    local pathcol

    if (mode == "dirs" || mode == "files")
        pathcol := 10
    else
        pathcol := 7

    local Srows := ""
    local RowNumber := 0
    Loop
    {
        RowNumber := MyListView.GetNext(RowNumber)
        if not RowNumber
            break
        Srows .= RowNumber . ","
    }
    Srows := Trim(Srows, ",")
    local removedpaths := ""
    local Srows_arr := StrSplit(Srows, ",")
    for _, row in Srows_arr
    {
        local item
        if (mode == "keys") {
            item := MyListView.GetText(row, pathcol)
            removedpaths .= item . A_nl
        }
        else if (mode == "dirs") {
            item := MyListView.GetText(row, pathcol)
            removedpaths .= item . A_nl
        }
        else if (mode == "values") {
            item := MyListView.GetText(row, pathcol)
            local val := MyListView.GetText(row, 4)
            item .= "\" . val
        }
        else {
            item := MyListView.GetText(row, pathcol)
            local val := MyListView.GetText(row, 2)
            item .= "\" . val
        }
        AddIgnoreItem(mode, item)
    }

    Srows_arr.Sort("NR")
    for _, row in Srows_arr
        MyListView.Delete(row)

    if (mode == "dirs" || mode == "keys") {
        removedpaths := Trim(removedpaths, A_nl)
        local removedpaths_arr := StrSplit(removedpaths, "`n")
        for _, p in removedpaths_arr
        {
            local row := MyListView.GetCount()
            loop
            {
                local item := MyListView.GetText(row, pathcol)
                if (InStr(item, p, 1) == 1)
                    MyListView.Delete(row)
                row -= 1
                if (row == 0)
                    break
            }
        }
    }
    Return
}

ReadIgnoredConfig(type)
{
    Global ignoredDirs, ignoredFiles, ignoredKeys, ignoredValues, ignorelist

    if (type == "files") {
        ignoredDirs := "`n"
        try ignoredDirs .= FileRead(ignorelist . "dirs.cfg") . "`n"
        ignoredFiles := "`n"
        try ignoredFiles .= FileRead(ignorelist . "files.cfg") . "`n"
    }
    else {
        ignoredKeys := "`n"
        try ignoredKeys .= FileRead(ignorelist . "keys.cfg") . "`n"
        ignoredValues := "`n"
        try ignoredValues .= FileRead(ignorelist . "values.cfg") . "`n"
    }
    Return
}

AddIgnoreItem(mode, item)
{
    global newIgnored
    newIgnored[mode] .= "`n" . item
    Return
}

SaveNewIgnoredItems(mode)
{
    Global ignoredDirs, ignoredFiles, ignoredKeys, ignoredValues, ignorelist, newIgnored
    local A_nl := "`n"
    local path_type, item_type
    if (mode == "files") {
        path_type := "dirs"
        item_type := "files"
    } else {
        path_type := "keys"
        item_type := "values"
    }

    if (newIgnored.Has(path_type) && newIgnored[path_type] == "" && newIgnored.Has(item_type) && newIgnored[item_type] == "")
        Return

    local pathdata := (mode == "files" ? ignoredDirs : ignoredKeys) . (newIgnored.Has(path_type) ? newIgnored[path_type] : "")
    local itemdata := (mode == "files" ? ignoredFiles : ignoredValues) . (newIgnored.Has(item_type) ? newIgnored[item_type] : "")

    local pathfilename := ignorelist . path_type . ".cfg"
    local itemfilename := ignorelist . item_type . ".cfg"

    local path_arr := StrSplit(pathdata, A_nl, A_nl . " `t`r")
    path_arr.Sort("U")
    pathdata := path_arr.Join(A_nl)

    local item_arr := StrSplit(itemdata, A_nl, A_nl . " `t`r")
    item_arr.Sort("U")
    itemdata := item_arr.Join(A_nl)

    local outpathdata := A_nl
    loop, parse, pathdata, A_nl
    {
        if (A_LoopField == "")
            Continue
        local sub := A_LoopField
        local found := false
        Loop
        {
            SplitPath(sub, , &sub)
            if (sub == "")
                break
            if (InStr(outpathdata, A_nl . sub . A_nl)) {
                found := true
                break
            }
        }
        if (!found)
            outpathdata .= A_LoopField . A_nl
    }

    local outitemdata := A_nl
    loop, parse, itemdata, A_nl
    {
        if (A_LoopField == "")
            Continue
        local sub := A_LoopField
        local found := false
        Loop
        {
            SplitPath(sub, , &sub)
            if (sub == "")
                break
            if (InStr(outpathdata, A_nl . sub . A_nl)) {
                found := true
                break
            }
        }
        if (!found)
            outitemdata .= A_LoopField . A_nl
    }

    FileDelete(pathfilename)
    FileAppend(outpathdata, pathfilename)

    FileDelete(itemfilename)
    FileAppend(outitemdata, itemfilename)

    Return
}

LVIgnoreSpecific(row, mode)
{
    global MyListView
    if (mode == "dirs")
    {
        pathcol := 10
        name := "directory"
        names := "directories"
    }
    else
    {
        pathcol := 7
        name := "key"
        names := "keys"
    }

    tohide := MyListView.GetText(row, pathcol)

    prompt := "Type the name of the " . name . " to permanently hide.`n"
    prompt .= "Use the format of the last column (Sandbox bpath).`n"
    prompt .= "Do not type the leading box bpath and the tailing backslash.`n"
    prompt .= "Note that all sub-" . names . " will be hidden as well.`n"
    prompt .= "Take care: The ignore list is global to all sandboxes!"
    tohide := InputBox("Add item to Ignore List", prompt, , , , , , , , tohide).Value
    if (tohide == "")
        Return

    tohide := Trim(tohide, "\")
    if (tohide != "")
        AddIgnoreItem(mode, tohide)

    tohidepath := tohide . "\"
    row := MyListView.GetCount()
    loop
    {
        item := MyListView.GetText(row, pathcol)
        if (InStr(item, tohidepath, 1) == 1)
            MyListView.Delete(row)
        else if (item == tohide)
            MyListView.Delete(row)
        row -= 1
        if (row == 0)
            break
    }

    Return
}

IsIgnored(mode, ignoredList, checkpath, item := "") {
    checkpath := StrReplace(checkpath, ":", ".")
    if (ignoredList == "") {
        return false
    }

    local A_nl := "`n"

    if (mode == "values" || mode == "files") {
        local tocheck := A_nl . checkpath . "\" . item . A_nl
        return InStr(ignoredList, tocheck)
    } else {
        loop {
            local tocheck := A_nl . checkpath . A_nl
            if (InStr(ignoredList, tocheck)) {
                return true
            }
            SplitPath(checkpath, , &checkpath)
            if (checkpath == "") {
                return false
            }
        }
    }
    return false
}

; ###################################################################################################
; Menu handlers
; ###################################################################################################

RunProgramMenuHandler(ItemName, ItemPos, MyMenu) {
    box := getBoxFromMenu(MyMenu.Name)
    shortcut := menucommands[MyMenu.Name, ItemName]
    ; TODO: handle shortcuts to .URL files
    if (GetKeyState("Control", "P")) {
        iconfile := menuicons[MyMenu.Name, ItemName, "file"]
        iconnum := menuicons[MyMenu.Name, ItemName, "num"]
        if (iconnum < 0)
            iconnum := IndexOfIconResource(iconfile, iconnum)
        createDesktopShortcutFromLnk(box, shortcut, iconfile, iconnum)
    } else if (GetKeyState("Shift", "P")) {
        SplitPath(shortcut, , &dir)
        Run(start . " /box:" . box . " """ . dir . """")
        MsgBox("Opening sandboxed folder`n""" . dir . """`n`nPlease wait",, "IconInfo SystemModal")
    } else {
        executeShortcut(box, shortcut)
    }
}

RunUserToolMenuHandler(ItemName, ItemPos, MyMenu) {
    shortcut := menucommands[MyMenu.Name, ItemName]
    executeShortcut("", shortcut)
}

NewShortcutMenuHandler(ItemName, ItemPos, MyMenu) {
    box := getBoxFromMenu(MyMenu.Name)
    static DefaultShortcutFolder
    if (!DirExist(DefaultShortcutFolder))
        DefaultShortcutFolder := A_Desktop
    file := FileSelect(33, A_ProgramFiles, "Select the file to launch sandboxed in box " . box . " via a shortcut on the desktop", "Executable files (*.exe)")
    if (!file)
        return
    NewShortcut(box, file)
    SplitPath(file, , &DefaultShortcutFolder)
}

RunDialogMenuHandler(ItemName, ItemPos, MyMenu) {
    box := getBoxFromMenu(MyMenu.Name)
    if (GetKeyState("Control", "P"))
        writeSandboxedShortcutFileToDesktop(start, "Sandboxie's Run dialog", "", "/box:" . box . " run_dialog", "Launch Sandboxie's Run Dialog in sandbox " . box, SbieAgentResMain, SbieAgentResMainId, 1, box)
    else
        Run(start . " /box:" . box . " run_dialog")
}

StartMenuMenuHandler(ItemName, ItemPos, MyMenu) {
    box := getBoxFromMenu(MyMenu.Name)
    if (GetKeyState("Control", "P"))
        writeSandboxedShortcutFileToDesktop(start, "Sandboxie's Start Menu", "", "/box:" . box . " start_menu", "Launch Sandboxie's Start Menu in sandbox " . box, SbieAgentResMain, SbieAgentResMainId, 1, box)
    else
        Run(start . " /box:" . box . " start_menu")
}

SCmdMenuHandler(ItemName, ItemPos, MyMenu) {
    box := getBoxFromMenu(MyMenu.Name)
    if (GetKeyState("Control", "P")) {
        args := "/box:" . box . " " . A_ComSpec . " /k ""cd /d " . A_WinDir . "\"""
        writeSandboxedShortcutFileToDesktop(start, "Sandboxed Command Prompt", "", args, "Sandboxed Command Prompt in sandbox " . box, cmdRes, 1, 1, box)
    } else {
        cdpath := DirExist(expandEnvVars(sbcommandpromptdir)) ? sbcommandpromptdir : A_WinDir
        Run(start . " /box:" . box . " " . A_ComSpec . " /k ""cd /d " . cdpath . """")
    }
}

UCmdMenuHandler(ItemName, ItemPos, MyMenu) {
    box := getBoxFromMenu(MyMenu.Name)
    bpath := sandboxes_array[box].bpath
    if (GetKeyState("Control", "P")) {
        args := "/k ""cd /d """ . bpath . """"""
        writeUnsandboxedShortcutFileToDesktop(A_ComSpec, "Unsandboxed Command Prompt in sandbox " . box, bpath, args, "Unsandboxed Command Prompt in sandbox " . box, cmdRes, 1, 1)
    } else {
        Run(A_ComSpec . " /k ""cd /d """ . bpath . """""")
    }
}

SRegEditMenuHandler(ItemName, ItemPos, MyMenu) {
    box := getBoxFromMenu(MyMenu.Name)
    if (GetKeyState("Control", "P"))
        writeSandboxedShortcutFileToDesktop(start, "Sandboxed Registry Editor", "", "/box:" . box . " " . regeditImg, "Launch RegEdit in sandbox " . box, regeditRes, 1, 1, box)
    else
        Run(start . " /box:" . box . " " . regeditImg)
}

URegEditMenuHandler(ItemName, ItemPos, MyMenu) {
    if (GetKeyState("Control", "P")) {
        MsgBox("Since something must be running in the box to analyse its registry, creating a desktop shortcut to launch the unsandboxed Registry Editor is not supported. Sorry.`n`nNote that creating a shortcut to a sandboxed Registry Editor is supported, but on x64 systems you can launch it only in sandboxes with the Drop Rights restriction disabled.",, "IconStop")
    } else {
        box := getBoxFromMenu(MyMenu.Name)
        ; ensure that the box is in use, or the hive will not be loaded
        run_pid := InitializeBox(box)
        ; pre-select the right registry key
        bregstr_ := sandboxes_array[box].KeyRootPath
        bregstr_ := StrReplace(StrReplace(SubStr(bregstr_, 16), '`%SANDBOX`%', box), '`%USER`%', A_UserName)
        RegWrite("REG_SZ", "HKEY_CURRENT_USER\Software\Microsoft\Windows\CurrentVersion\Applets\Regedit", "LastKey", "HKEY_USERS\" . bregstr_)
        ; launch regedit
        RunWait("RegEdit.exe")
        ReleaseBox(run_pid)
    }
}

UninstallMenuHandler(ItemName, ItemPos, MyMenu) {
    box := getBoxFromMenu(MyMenu.Name)
    if (GetKeyState("Control", "P"))
        writeSandboxedShortcutFileToDesktop(start, "Uninstall Programs", "", "/box:" . box . " appwiz.cpl", "Uninstall or installs programs in sandbox " . box, shell32, 22, 1, box)
    else
        RunWait(start . " /box:" . box . " appwiz.cpl")
}

TerminateMenuHandler(ItemName, ItemPos, MyMenu) {
    box := getBoxFromMenu(MyMenu.Name)
    if (GetKeyState("Control", "P"))
        writeUnsandboxedShortcutFileToDesktop(start, "Terminate Programs in sandbox " . box, "", "/box:" . box . " /terminate", "Terminate all programs running in sandbox " . box, shell32, 220, 1)
    else
        RunWait(start . " /box:" . box . " /terminate")
}

DeleteBoxMenuHandler(ItemName, ItemPos, MyMenu) {
    box := getBoxFromMenu(MyMenu.Name)
    if (GetKeyState("Control", "P")) {
        writeUnsandboxedShortcutFileToDesktop(start, "! Delete sandbox " . box . " !", "", "/box:" . box . " delete_sandbox", "Deletes the sandbox " . box, shell32, 132, 1)
        MsgBox("Warning! Unlike when Delete Sandbox is run from the SandboxToys Menu, the desktop shortcut that has been created doesn't ask for confirmation!`n`nUse the shortcut with care!",, "IconStop")
    } else {
        if (MsgBox("Are you sure you want to delete the sandbox """ . box . """?",, "YesNo IconQuestion") == "Yes") {
            RunWait(start . " /box:" . box . " delete_sandbox")
        }
    }
}

SExploreMenuHandler(ItemName, ItemPos, MyMenu) {
    box := getBoxFromMenu(MyMenu.Name)
    if (GetKeyState("Control", "P"))
        writeSandboxedShortcutFileToDesktop(start, "Explore sandbox " . box . " (Sandboxed)", sbdir, "/box:" . box . " " . explorer, "Launches Explorer sandboxed in sandbox " . box, explorerRes, 1, 1, box)
    else
        Run(start . " /box:" . box . " " . explorer)
}

UExploreMenuHandler(ItemName, ItemPos, MyMenu) {
    box := getBoxFromMenu(MyMenu.Name)
    bpath := sandboxes_array[box].bpath
    if (GetKeyState("Control", "P"))
        writeUnsandboxedShortcutFileToDesktop(explorerImg, "Explore sandbox " . box . " (Unsandboxed)", bpath, explorerArgE . " \ "" . bpath . """", "Launches Explorer unsandboxed in sandbox " . box, explorerRes, 1, 1)
    else
        Run(explorer . "\" . bpath)
}

URExploreMenuHandler(ItemName, ItemPos, MyMenu) {
    box := getBoxFromMenu(MyMenu.Name)
    bpath := sandboxes_array[box].bpath
    if (GetKeyState("Control", "P"))
        writeUnsandboxedShortcutFileToDesktop(explorerImg, "Explore sandbox " . box . " (Unsandboxed, restricted)", bpath, explorerArgER . " \ "" . bpath . """", "Launches Explorer unsandboxed and restricted to sandbox " . box, explorerRes, 1, 1)
    else
        Run(explorerERArg . "\" . bpath)
}

LaunchSbieAgentMenuHandler(*) {
    if (GetKeyState("Control", "P")) {
        if (SbieAgent == SbieMngr) {
            writeUnsandboxedShortcutFileToDesktop(SbieAgent, SbieAgentResMainText, sbdir, "", "Launch " . SbieAgentResMainText, "", "", 1)
        }
        if (SbieAgent == SbieCtrl) {
            writeUnsandboxedShortcutFileToDesktop(SbieAgent, SbieAgentResMainText, sbdir, "", "Launch " . SbieAgentResMainText, "", "", 1)
        }
    } else {
        Run(SbieAgent)
    }
}

ListFilesMenuHandler(ItemName, ItemPos, MyMenu) {
    box := getBoxFromMenu(MyMenu.Name)
    bpath := sandboxes_array[box].bpath
    ListFiles(box, bpath)
}

ListRegMenuHandler(ItemName, ItemPos, MyMenu) {
    box := getBoxFromMenu(MyMenu.Name)
    bpath := sandboxes_array[box].bpath
    ListReg(box, bpath)
}

ListAutostartsMenuHandler(ItemName, ItemPos, MyMenu) {
    box := getBoxFromMenu(MyMenu.Name)
    bpath := sandboxes_array[box].bpath
    ListAutostarts(box, bpath)
}

WatchRegMenuHandler(ItemName, ItemPos, MyMenu) {
    box := getBoxFromMenu(MyMenu.Name)
    bpath := sandboxes_array[box].bpath
    bregstr_ := sandboxes_array[box].KeyRootPath
    bregstr_ := StrReplace(StrReplace(SubStr(bregstr_, 16), '`%SANDBOX`%', box), '`%USER`%', username)
    comparefile = A_Temp . "\S" . regstr_ . "_reg_compare.cfg"
    MakeRegConfig(box, comparefile)
    if (MsgBox("The current state of the registry of sandbox """ . box . """ has been saved.`n`nYou can now work in the box. When finished, click Continue, and the new state of the registry will be compared with the old state, and the result displayed so that you can analyse the changes, and export them as a REG file if you wish.`n`nNote that the registry keys and the deleted registry values will not be listed. However, a deleted key or value will be listed if it is present in the ""real world"".`n`n*** Click Continue ONLY when ready! ***", title, 38) == "Continue")
        ListReg(box, bpath, comparefile)
    else
        WatchRegMenuHandler()
}

WatchFilesMenuHandler(ItemName, ItemPos, MyMenu) {
    box := getBoxFromMenu(MyMenu.Name)
    bpath := sandboxes_array[box].bpath
    bregstr_ := sandboxes_array[box].KeyRootPath
    bregstr_ := StrReplace(StrReplace(SubStr(bregstr_, 16), '`%SANDBOX`%', box), '`%USER`%', username)
    comparefile = A_Temp . "\" . regstr_ . "_files_compare.cfg"
    MakeFilesConfig(box, comparefile, bpath)
    if (MsgBox("The current state of the files in sandbox """ . box . """ has been saved.`n`nYou can now work in the box. When finished, click Continue, and the new state of the files will be compared with the old state, and the result displayed so that you can analyse the changes, and export the modified or new files if you wish.`n`nNote that the folders and the deleted files will not be listed. However, a deleted folder or file will be listed if it is present in the ""real world"".`n`n*** Click Continue ONLY when ready! ***", title, 38) == "Continue")
        ListFiles(box, bpath, comparefile)
    else
        WatchFilesMenuHandler()
}

WatchFilesRegMenuHandler(ItemName, ItemPos, MyMenu) {
    box := getBoxFromMenu(MyMenu.Name)
    bpath := sandboxes_array[box].bpath
    bregstr_ := sandboxes_array[box].KeyRootPath
    bregstr_ := StrReplace(StrReplace(SubStr(bregstr_, 16), '`%SANDBOX`%', box), '`%USER`%', username)
    comparefile1 := A_Temp . "\" . regstr_ . "_files_compare.cfg"
    MakeFilesConfig(box, comparefile1, bpath)
    comparefile2 := A_Temp . "\" . regstr_ . "_reg_compare.cfg"
    MakeRegConfig(box, comparefile2)
    if (MsgBox("The current state of the files and registry of sandbox """ . box . """ has been saved.`n`nYou can now work in the box. When finished, click Continue, and the new state of the files and registry will be compared with the old state, and the result displayed so that you can analyse the changes.`n`nNote that the folders, the deleted files, the registry keys and the deleted registry values will not be listed. However, a deleted folder, file, key or value will be listed if it is present in the ""real world"".`n`n*** Click Continue ONLY when ready! ***", title, 38) == "Continue") {
        ListFiles(box, bpath, comparefile1)
        ListReg(box, bpath, comparefile2)
    } else {
        WatchFilesRegMenuHandler()
    }
}

SetupMenuMenuHandler1(*) {
    global largeiconsize, SBMenuSetup, sbtini
    largeiconsize := largeiconsize > 16 ? 16 : 32
    SBMenuSetup.ToggleCheck("Large main-menu and box icons?")
    IniWrite(largeiconsize, sbtini, "AutoConfig", "LargeIconSize")
}
SetupMenuMenuHandler2(*) {
    global smalliconsize, SBMenuSetup, sbtini
    smalliconsize := smalliconsize > 16 ? 16 : 32
    SBMenuSetup.ToggleCheck("Large sub-menu icons?")
    IniWrite(smalliconsize, sbtini, "AutoConfig", "SmallIconSize")
}
SetupMenuMenuHandler3(*) {
    global seperatedstartmenus, SBMenuSetup, sbtini
    seperatedstartmenus := !seperatedstartmenus
    SBMenuSetup.ToggleCheck("Seperated All Users menus?")
    IniWrite(seperatedstartmenus, sbtini, "AutoConfig", "SeperatedStartMenus")
}
SetupMenuMenuHandler4(*) {
    global includeboxnames, SBMenuSetup, sbtini
    includeboxnames := !includeboxnames
    SBMenuSetup.ToggleCheck("Include [#BoxName] in shortcut names?")
    IniWrite(includeboxnames, sbtini, "AutoConfig", "IncludeBoxNames")
}

SetupMenuMenuHandler5(*) {
    global listemptyitems, SBMenuSetup, sbtini
    listemptyitems := !listemptyitems
    SBMenuSetup.ToggleCheck("List empty folders and keys?")
    IniWrite(listemptyitems, sbtini, "AutoConfig", "ListEmptyItems")
}

MainHelpMenuHandler(*) {
    MsgBox(title . "`n`nSandboxToys2 Main Menu usage:`n`nThe main menu displays the shortcuts present in the Start Menu, Desktop and QuickLaunch folders of your sandboxes. Just select any of these shortcuts to launch the program, sandboxed in the right box. Of course, there must be programs installed in your sandboxes, or the menus will not be displayed.`n`nNote also that you can create easily a ""sandboxed shortcut"" on your real destkop to launch any program displayed in the SandboxToys Menu even easier! Just Control-Click on the menu entry, and the shortcut will be created on your desktop. (Note: This work also with most icons of the Explore, Registry and Tools menu.)`n`nSimilarly, Shift-clicking on a menu icon opens the folder containing the file. The Windows explorer is run sandboxed.`n`nSandboxToys2 offers also some tools in its Explore, Registry and Tools Menus. They should be self-explanatory.`nUnlike the method explained above, Tools -> New Sandboxed Shortcut creates a sandboxed shortcut on your desktop to any unsandboxed file located in your real discs.`n`nThe User Tools menu is a configurable menu, that can contain almost anything you want. To use it, place a (normal or sandboxed) shortcut in the """ . usertoolsdir . """ folder, and it will be displayed in the User Tools menu. Note that the tools launched via that menu are run unsandboxed, unless the shortcut itself is sandboxed (ie it uses Sandboxie's Start.exe to launch the command). You can create sub-menus in the User Tools menu by placing shortcuts in folders within the """ . usertoolsdir . """ folder.", title, 64)
}

CmdLineHelp() {
    MsgBox(title . "`n`nSandboxToys2 Command Line usage:`n`n> SandboxToys2 [/box:boxname]`nWithout arguments, SandboxToys2 opens its main menu, waits for a selection, execute it and then exits immediately.`nThe optional argument /box:boxname can be used to restrict the menu to a single sandbox.`n`n> SandboxToys2 [/box:boxname] /tray`nSandboxToys2 stays resident in the tray.`nClick the tray icon to launch the main SandboxToys Menu.`nRight-click the tray icon to exit SandboxToys.`n`n> SandboxToys2 [/box:boxname] ""existing file, folder or shortcut""`nCreates a new sandboxed shortcut on the desktop. If the /box:boxname argument is not present, you will need to select the target box in a menu.`nIt is recommended to create a shortcut to SandboxToys in your SendTo folder to easily create sandboxed shortcuts to any file or folder.`nYour SendTo folder should be:`n""" . A_AppData . "\Microsoft\Windows\SendTo""`n`nNote: The SandboxToys2.ini file holds the settings of SandboxToys. It should be in """ . A_AppData . "\SandboxToys2\"" or in the same folder than the SandboxToys2 executable. The name of the INI file is the same than the name of the SandboxToys2 executable file, so if you rename SandboxToys2.exe, you should rename also SandboxToys2.ini.`nSimilarly, the name of the ""SandboxToys2_UserTools"" folder depends of the name of SandboxToys2.exe, and it should be also in your APPDATA folder or in the SandboxToys2.exe folder.`nThis allows you to run several instances of SandboxToys2 with different configurations and/or user tools.", title, 64)
}

DummyMenuHandler(*) {
}

ExitMenuHandler(*) {
    ExitApp()
}
