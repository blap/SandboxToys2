#Persistent
#SingleInstance Off

A_UseHook := false
version := 2.5.4
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
    global A_WinDir, cmdRes, SbieAgentResMain, SbieAgentResMainId, usertoolsdir, mainmenu, SbieAgent, SbieAgentResMainText, title, includeboxnames
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
getSandboxesArray(ini)
{
    global username
    sandboxes_map := Map()
    sandboxes_path_template := IniRead(ini, "GlobalSettings", "FileRootPath", A_WinDir . "\Sandbox\`%USER`%\`%SANDBOX`%")
    sandboxeskey_path_template := IniRead(ini, "GlobalSettings", "KeyRootPath", "\REGISTRY\USER\Sandbox_`%USER`%_`%SANDBOX`%")

    old_encoding := A_FileEncoding
    A_FileEncoding := "UTF-16"

    boxes_str := ""
    Loop Read, ini
    {
        line := A_LoopReadLine
        if (SubStr(line, 1, 1) == "[" && SubStr(line, -1) == "]" && line != "[GlobalSettings]" && SubStr(line, 1, 14) != "[UserSettings_" && SubStr(line, 1, 10) != "[Template_" && line != "[TemplateSettings]") {
            boxes_str .= SubStr(line, 2, -1) . ","
        }
    }
    A_FileEncoding := old_encoding
    boxes_str := Trim(boxes_str, ",")
    boxlist := StrSplit(boxes_str, ",")
    Sort(boxlist, "CL D")

    for _, boxname in boxlist
    {
        box_data := Map()
        box_data.name := boxname

        current_sandboxes_path := IniRead(ini, boxname, "FileRootPath", sandboxes_path_template)
        box_data.FileRootPath := current_sandboxes_path
        expanded_path := expandEnvVars(current_sandboxes_path)
        box_data.bpath := StrReplace(expanded_path, "`%SANDBOX`%", boxname)

        current_sandboxeskey_path := IniRead(ini, boxname, "KeyRootPath", sandboxeskey_path_template)
        box_data.KeyRootPath := current_sandboxeskey_path
        expanded_key_path := expandEnvVars(current_sandboxeskey_path)
        box_data.bkey := StrReplace(expanded_key_path, "`%SANDBOX`%", boxname)

        bkeyrootpathR := StrReplace(current_sandboxeskey_path, username, "`%USER`%")
        regspos := InStr(bkeyrootpathR, "\",, 0)
        regepos := InStr(bkeyrootpathR, "%")
        box_data.RegStr_ := SubStr(bkeyrootpathR, regspos + 1, regepos - regspos - 2)

        box_data.exist := DirExist(box_data.bpath) && FileExist(box_data.bpath . "\RegHive")

        box_data.DropAdminRights := IniRead(ini, boxname, "DropAdminRights", "n") == "y"
        box_data.Enabled := IniRead(ini, boxname, "Enabled", "y") != "n"
        box_data.NeverDelete := IniRead(ini, boxname, "NeverDelete", "n") == "y"
        box_data.UseFileImage := IniRead(ini, boxname, "UseFileImage", "n") == "y"
        box_data.UseRamDisk := IniRead(ini, boxname, "UseRamDisk", "n") == "y"

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

    boxMenu.OnEvent("Click", getSandboxName_ClickHandler)

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

    global __selected_box__ := unset
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
        if IsObject(menuObj)
            menuObj.SetIcon(item, iconfile, iconindex, iconsize)
        else
            Menu(menuObj).SetIcon(item, iconfile, iconindex, iconsize)
        return 0
    } catch {
        return 1
    }
}

getFilenames(directory, includeFolders)
{
    files := ""
    loopMode := ""
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
            files .= OutDirName . ":" . A_LoopFileLongPath . "`n"
        } else {
            SplitPath(A_LoopFileName, , , , &OutNameNoExt)
            files .= OutNameNoExt . ":" . A_LoopFileLongPath . "`n"
        }
    }
    files := Trim(files, "`n")
    if (files)
        Sort(files, "CL D`n Z")
    Return files
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
        Sort(menufiles, "CL D`n Z")
        numfiles += addCmdsToMenu(box, thismenu, menufiles)
    }

    menudirs := getFilenames(bpath, 2)
    if (menudirs) {
        Sort(menudirs, "CL D`n Z")
        Loop, parse, menudirs, "`n"
        {
            entry := A_LoopField
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
        Sort(menufiles, "CL D`n")
        numfiles += addCmdsToMenu(box, thismenu, menufiles)
    }

    ; recurse
    menudirs1 := getFilenames(path1, 2)
    menudirs2 := getFilenames(path2, 2)
    menudirsStr := menudirs1 . "`n" . menudirs2
    menudirsStr := Trim(menudirsStr, A_Return)
    if (menudirsStr) {
        dirMap := Map()
        Loop, parse, menudirsStr, "`n"
        {
            entry := A_LoopField
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
        Sort(sortedLabels, "CL")

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
setIconFromSandboxedShortcut(box, shortcut, menuname, label, iconsize)
{
    global menuicons, imageres, username, sandboxes_array, shell32
    A_Quotes := """"

    bregstr_ := sandboxes_array[box].KeyRootPath
    bregstr_ := StrReplace(StrReplace(SubStr(bregstr_, 16), '`%SANDBOX`%', box), '`%USER`%', username)

    menuicons[menuname,label,"file"] := ""
    menuicons[menuname,label,"num"] := ""

    ; get icon file and number in shortcut.
    ; If not specified, assumes it's the file pointed to by the shortcut
    SplitPath(shortcut, , , &extension)
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

    if (InStr(FileExist(iconfile), "D")) {
        setMenuIcon(menuname, label, imageres, 4, iconsize)
        menuicons[menuname,label,"file"] := imageres
        menuicons[menuname,label,"num"] := 4
        return imageres . "," . 4
    }

    boxfile := stdPathToBoxPath(box, iconfile)
    if (InStr(FileExist(boxfile), "D")) {
        setMenuIcon(menuname, label, imageres, 4, iconsize)
        menuicons[menuname,label,"file"] := imageres
        menuicons[menuname,label,"num"] := 4
        return imageres . "," . 4
    }
    if (FileExist(boxfile)) {
        iconfile := boxfile
    }

    rc := 1
    if (iconfile != "") {
        rc := setMenuIcon(menuname, label, iconfile, iconnum, iconsize)
        menuicons[menuname,label,"file"] := iconfile
        menuicons[menuname,label,"num"] := iconnum
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
        try defaulticon := RegRead("HKEY_USERS", bregstr_ . "\machine\software\classes\." . extension . "\DefaultIcon")
        catch {
            try {
                keyval := RegRead("HKEY_USERS", bregstr_ . "\machine\software\classes\." . extension)
                if (keyval != "") {
                    try defaulticon := RegRead("HKEY_USERS", bregstr_ . "\machine\software\classes\" . keyval . "\DefaultIcon")
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
                rc := setMenuIcon(menuname, label, iconfile, iconnum, iconsize)
                menuicons[menuname,label,"file"] := iconfile
                menuicons[menuname,label,"num"] := iconnum
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
            }
            if (percievedtype == "system") {
                defaulticon := imageres . ",63"
            }
            if (percievedtype == "text") {
                defaulticon := imageres . ",97"
            }
            if (percievedtype == "audio") {
                defaulticon := imageres . ",125"
            }
            if (percievedtype == "image") {
                defaulticon := imageres . ",126"
            }
            if (percievedtype == "video") {
                defaulticon := imageres . ",127"
            }
            if (percievedtype == "compressed") {
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
            rc := setMenuIcon(menuname, label, iconfile, iconnum, iconsize)
            menuicons[menuname,label,"file"] := iconfile
            menuicons[menuname,label,"num"] := iconnum
        } else
            rc := 1
        if (rc) {
            if (InStr(defaulticon, "%programfiles%")) {
                iconfile := StrReplace(iconfile, '`%programfiles`%', A_ProgramFiles)
                rc := setMenuIcon(menuname, label, iconfile, iconnum, iconsize)
                menuicons[menuname,label,"file"] := iconfile
                menuicons[menuname,label,"num"] := iconnum
            }
            if (rc) {
                iconfile := StrReplace(iconfile, '`%programfiles`%', A_ProgramFilesX86)
                rc := setMenuIcon(menuname, label, iconfile, iconnum, iconsize)
                menuicons[menuname,label,"file"] := iconfile
                menuicons[menuname,label,"num"] := iconnum
            }
            if (rc) {
                iconfile := expandEnvVars(iconfile)
                rc := setMenuIcon(menuname, label, iconfile, iconnum, iconsize)
                menuicons[menuname,label,"file"] := iconfile
                menuicons[menuname,label,"num"] := iconnum
            }
        }
        if (rc || iconfile == "") {
            iconfile := shell32
            iconfile := expandEnvVars(iconfile)
            if (extension == "exe")
                iconnum := 3
            else
                iconnum := 2
            rc := setMenuIcon(menuname, label, iconfile, iconnum, iconsize)
            menuicons[menuname,label,"file"] := iconfile
            menuicons[menuname,label,"num"] := iconnum
        }
    }
    return iconfile . "," . iconnum
}

; Retrieve the icon number from its resource TD (negative index).
; Assumes the order of the icon resources defines the icon indices.
IndexOfIconResource(Filename, ID)
{
    A_Quotes = "
    Filename := Trim(Filename, A_Quotes)
    Filename := expandEnvVars(Filename)
    ID := Abs(ID)
    hmod := DllCall("GetModuleHandle", "str", Filename)
    ; If the DLL isn't already loaded, load it as a data file.
    loaded := !hmod
        && hmod := DllCall("LoadLibraryEx", "str", Filename, "uint", 0, "uint", 0x2)

    enumproc := RegisterCallback("IndexOfIconResource_EnumIconResources","F")
    VarSetCapacity(param,12,0), NumPut(ID,param,0)
    ; Enumerate the icon group resources. (RT_GROUP_ICON=14)
    DllCall("EnumResourceNames", "uint", hmod, "uint", 14, "uint", enumproc, "uint", &param)
    DllCall("GlobalFree", "uint", enumproc)

    ; If we loaded the DLL, free it now.
    if loaded
        DllCall("FreeLibrary", "uint", hmod)

    return NumGet(param,8) ? NumGet(param,4) : 0
}
IndexOfIconResource_EnumIconResources(hModule, lpszType, lpszName, lParam)
{
    NumPut(NumGet(lParam+4)+1, lParam+4)

    if (lpszName = NumGet(lParam+0))
    {
        NumPut(1, lParam+8)
        return false ; break
    }
    return true
}

GetAssociatedIcon(File, hideshortcutoverlay = true, iconsize = 16, box = "", deleted = 0)
{
    static
    sfi_size:=352
    local hIcon, Ext, Fileto, FileIcon, FileIconNum, old, programsx86
    EnvGet, programsx86, ProgramFiles(x86)
    If not sfi
        VarSetCapacity(sfi, sfi_size)

    SplitPath, File,,, Ext
    If ext=LNK
    {
        FileGetShortcut,%File%,Fileto,,,,FileIcon,FileIconNum
        if (hideshortcutoverlay) {
            if (FileIcon) {
                hIcon := MI_ExtractIcon(FileIcon,FileIconNum,iconsize)
                if (hIcon)
                    return hIcon
            } else {
                File := Fileto
                SplitPath, File,,, Ext
            }
        } else {
            if (! FileExist(FileTo))
            {
                tmpboxfile := stdPathToBoxPath(box,FileTo)
                if (FileExist(tmpboxfile))
                    FileTo = %tmpboxfile%
            }
            if (! FileExist(FileTo))
                StringReplace, FileTo, FileTo, %programs86%, %ProgramW6432%
            attrs := 0x8101
            if (deleted)
                attrs := attrs + 0x10000
            If (DllCall("Shell32\SHGetFileInfoA", "astr", FileTo, "uint", 0, "str", sfi, "uint", sfi_size, "uint", attrs))
            {
                hIcon = 0
                Loop 4
                    hIcon += *(&sfi + A_Index-1) << 8*(A_Index-1)
                return hIcon
            }
        }
    }

    if (! FileExist(File))
        StringReplace, File, File, %Programx86%, %ProgramW6432%

    ; TODO: verify coherence of variable name, or use Object()
    if (StrLen(ext) <= 4)
        old := "hIcon_" ext "_" hideshortcutoverlay "_" iconsize
    else
        old =
    if old =
    {
        attrs := 0x101
        if (deleted)
            attrs := attrs + 0x10000
        If (DllCall("Shell32\SHGetFileInfoA", "astr", File, "uint", 0, "str", sfi, "uint", sfi_size, "uint", attrs))
        {
            hIcon = 0
            Loop 4
                hIcon += *(&sfi + A_Index-1) << 8*(A_Index-1)
        }
        ; TODO: verify coherence of variable name, or use Object()
        if Ext in EXE,ICO,ANI,CUR
        {
        }
        else
        {
            if (StrLen(ext) <= 4)
                hicon := "hIcon_" ext "_" hideshortcutoverlay "_" iconsize
        }
    } else {
        hicon := old
    }
    return hIcon
}

MI_SetMenuItemIcon(MenuNameOrHandle, ItemPos, h_icon, IconSize=0)
{
    ; Set for compatibility with older scripts:
    unused1=0
    unused2=0

    if MenuNameOrHandle is integer
        h_menu := MenuNameOrHandle
    else
        h_menu := MI_GetMenuHandle(MenuNameOrHandle)

    if !h_menu
        return false

    h_icon := DllCall("CopyImage","uint",h_icon,"uint",1
        ,"int",IconSize,"int",IconSize,"uint",0)

    ; Get the previous bitmap or icon handle.
    VarSetCapacity(mii,48,0), NumPut(48,mii), NumPut(0xA0,mii,4)
    if DllCall("GetMenuItemInfo","uint",h_menu,"uint",ItemPos-1,"uint",1,"uint",&mii)
        h_previous := NumGet(mii,44,"int")

    h_bitmap := MI_GetBitmapFromIcon32Bit(h_icon, IconSize, IconSize)

    if loaded_icon
    {
        ; The icon we loaded is no longer needed.
        DllCall("DestroyIcon","uint",loaded_icon)
        ; Don't try to destroy the now invalid handle again:
        loaded_icon := 0
    }

    if !h_bitmap
        return false

    NumPut(0x80,mii,4) ; fMask: Set hbmpItem only, not dwItemData.
        , NumPut(h_bitmap,mii,44) ; hbmpItem = h_bitmap

    if DllCall("SetMenuItemInfo","uint",h_menu,"uint",ItemPos-1,"uint",1,"uint",&mii)
    {
        ; Only now that we know it's a success, delete the previous icon or bitmap.
        if (h_previous < -1 || h_previous > 11)
            DllCall("DeleteObject","uint",h_previous)
        return true
    }
    ; ELSE FAIL
    if loaded_icon
        DllCall("DestroyIcon","uint",loaded_icon)
    return false
}
MI_ExtractIcon(Filename, IconNumber, IconSize)
{
    DllCall("PrivateExtractIcons", "wStr", Filename, "Int", IconNumber-1, "Int", IconSize, "Int", IconSize, "UInt*", hIcon, "UInt*", 0, "UInt", 1, "UInt", 0, "Int")
    If !ErrorLevel
        Return hIcon

    If DllCall("shell32.dll\ExtractIconExA", "wStr", Filename, "Int", IconNumber-1, "UInt*", hIcon, "UInt*", hIcon_Small, "UInt", 1)
    {
        SysGet, SmallIconSize, 49
        If (IconSize <= SmallIconSize) {
            DllCall("DeStroyIcon", "UInt", hIcon)
            hIcon := hIcon_Small
        }
        Else
            DllCall("DeStroyIcon", "UInt", hIcon_Small)

        If (hIcon && IconSize)
            hIcon := DllCall("CopyImage", "UInt", hIcon, "UInt", 1, "Int", IconSize, "Int", IconSize, "UInt", 4|8)
    }
    Return, hIcon ? hIcon : 0
}
MI_GetMenuHandle(menu_name)
{
    static h_menuDummy
    ; v2.2: Check for !h_menuDummy instead of h_menuDummy="" in case init failed last time.
    If !h_menuDummy
    {
        Menu, menuDummy, Add
        Menu, menuDummy, DeleteAll

        Gui, 99:Menu, menuDummy
        ; v2.2: Use LastFound method instead of window title. [Thanks animeaime.]
        Gui, 99:+LastFound

        h_menuDummy := DllCall("GetMenu", "uint", WinExist())

        Gui, 99:Menu
        Gui, 99:Destroy

        ; v2.2: Return only after cleaning up. [Thanks animeaime.]
        if !h_menuDummy
            return 0
    }

    Menu, menuDummy, Add, :%menu_name%
    h_menu := DllCall( "GetSubMenu", "uint", h_menuDummy, "int", 0 )
    DllCall( "RemoveMenu", "uint", h_menuDummy, "uint", 0, "uint", 0x400 )
    Menu, menuDummy, Delete, :%menu_name%

    return h_menu
}

MI_GetBitmapFromIcon32Bit(h_icon, width=0, height=0)
{
    VarSetCapacity(buf,40) ; used as ICONINFO (20), BITMAP (24), BITMAPINFO (40)
    if DllCall("GetIconInfo","uint",h_icon,"uint",&buf) {
        hbmColor := NumGet(buf,16) ; used to measure the icon
        hbmMask := NumGet(buf,12) ; used to generate alpha data (if necessary)
    }

    if !(width && height) {
        if !hbmColor or !DllCall("GetObject","uint",hbmColor,"int",24,"uint",&buf)
            return 0
        width := NumGet(buf,4,"int"), height := NumGet(buf,8,"int")
    }

    ; Create a device context compatible with the screen.
    if (hdcDest := DllCall("CreateCompatibleDC","uint",0))
    {
        ; Create a 32-bit bitmap to draw the icon onto.
        VarSetCapacity(buf,40,0), NumPut(40,buf), NumPut(1,buf,12,"ushort")
        NumPut(width,buf,4), NumPut(height,buf,8), NumPut(32,buf,14,"ushort")

        if (bm := DllCall("CreateDIBSection","uint",hdcDest,"uint",&buf,"uint",0
            ,"uint*",pBits,"uint",0,"uint",0))
        {
            ; SelectObject -- use hdcDest to draw onto bm
            if (bmOld := DllCall("SelectObject","uint",hdcDest,"uint",bm))
            {
                ; Draw the icon onto the 32-bit bitmap.
                DllCall("DrawIconEx","uint",hdcDest,"int",0,"int",0,"uint",h_icon
                    ,"uint",width,"uint",height,"uint",0,"uint",0,"uint",3)

                DllCall("SelectObject","uint",hdcDest,"uint",bmOld)
            }

            ; Check for alpha data.
            has_alpha_data := false
            Loop, % height*width
                if NumGet(pBits+0,(A_Index-1)*4) & 0xFF000000 {
                    has_alpha_data := true
                    break
                }
            if !has_alpha_data
            {
                ; Ensure the mask is the right size.
                hbmMask := DllCall("CopyImage","uint",hbmMask,"uint",0
                    ,"int",width,"int",height,"uint",4|8)

                VarSetCapacity(mask_bits, width*height*4, 0)
                if DllCall("GetDIBits","uint",hdcDest,"uint",hbmMask,"uint",0
                    ,"uint",height,"uint",&mask_bits,"uint",&buf,"uint",0)
                { ; Use icon mask to generate alpha data.
                    Loop, % height*width
                        if (NumGet(mask_bits, (A_Index-1)*4))
                            NumPut(0, pBits+(A_Index-1)*4)
                        else
                            NumPut(NumGet(pBits+(A_Index-1)*4) | 0xFF000000, pBits+(A_Index-1)*4)
                } else { ; Make the bitmap entirely opaque.
                    Loop, % height*width
                        NumPut(NumGet(pBits+(A_Index-1)*4) | 0xFF000000, pBits+(A_Index-1)*4)
                }
            }
        }

        ; Done using the device context.
        DllCall("DeleteDC","uint",hdcDest)
    }

    if hbmColor
        DllCall("DeleteObject","uint",hbmColor)
    if hbmMask
        DllCall("DeleteObject","uint",hbmMask)
    return bm
}

; converts a path to its equivalent in a sandbox
stdPathToBoxPath(box, bpath)
{
    global sandboxes_path
    StringReplace, boxpath, sandboxes_path, `%SANDBOX`%, %box%, All
    outpath =
    userprofile = %userprofile%\
    if (SubStr(bpath, 1, strLen(userprofile)) == userprofile) {
        remain := SubStr(bpath, strLen(userprofile)+1)
        outpath = %boxpath%\user\current\%remain%
    }
    if (outpath == "") {
        allusersprofile = %allusersprofile%\
        if (SubStr(bpath, 1, strLen(allusersprofile)) == allusersprofile) {
            remain := SubStr(bpath, strLen(allusersprofile)+1)
            outpath = %boxpath%\user\all\%remain%
        }
    }
    if (outpath == "") {
        if (subStr(bpath, 2, 2) == ":\") {
            drive := SubStr(bpath, 1, 1)
            remain := SubStr(bpath, 3)
            outpath = %boxpath%\drive\%drive%%remain%
        }
    }
    if (outpath == "") {
        outpath := bpath
    }
    return %outpath%
}

; converts a sandbox path to its equivalent in "the real world"
boxPathToStdPath(box, bpath)
{
    global sandboxes_path
    StringReplace, boxpath, sandboxes_path, `%SANDBOX`%, %box%, All
    if (SubStr(bpath, 1, strLen(boxpath)) == boxpath) {
        remain := SubStr(bpath, strLen(boxpath)+2)
        tmp = user\current\
        if (SubStr(remain, 1, strLen(tmp)) == tmp) {
            remain := SubStr(remain, strLen(tmp))
            bpath = %userprofile%%remain%
            return %bpath%
        }
        tmp = user\all\
        if (SubStr(remain, 1, strLen(tmp)) == tmp) {
            remain := SubStr(remain, strLen(tmp))
            bpath = %allusersprofile%%remain%
            return %bpath%
        }
        tmp = drive\
        if (SubStr(remain, 1, strLen(tmp)) == tmp) {
            remain := SubStr(remain, strLen(tmp)+1)
            driveletter = SubStr(remain, 1, 1)
            remain := SubStr(remain, 3)
            bpath = %driveletter%:\%remain%
            return %bpath%
        }
    }
    return %bpath%
}

; Add sandboxed commands in the main menu.
; filelist is a list of filenames seperated by newline characters.
addCmdsToMenu(box, menuObj, fileslist)
{
    global menucommands, smalliconsize
    numentries := 0
    Loop, parse, fileslist, "`n"
    {
        entry := A_LoopField
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
    SplitPath, shortcut, , , extension
    if (extension == "lnk") {
        FileGetShortcut, %shortcut%, target, outDir, outArgs, outDescription, outIcon, outIconNum, outRunState
        if (outDir != "")
            curdir := outDir
        else
            SplitPath, target, , curdir
    } else {
        SplitPath, shortcut, , curdir
    }

    ;curdir := expandVariables(curdir, box)
    curdir := expandEnvVars(curdir)
    return %curdir%
}

; Substitutes the Windows environment variables in the input string.
; Leave the other %variables% untouched.
expandEnvVars(str)
{
    global SID, SESSION
    StringReplace, str, str, `%SID`%, %SID%, All
    StringReplace, str, str, `%SESSION`%, %SESSION%, All
    StringReplace, str, str, `%USER`%, %username%, All

    if sz:=DllCall("ExpandEnvironmentStrings", "uint", &str
        , "uint", 0, "uint", 0)
    {
        VarSetCapacity(dst, A_IsUnicode ? sz*2:sz)
        if DllCall("ExpandEnvironmentStrings", "uint", &str
            , "str", dst, "uint", sz)
            return dst
    }
    return src
}

; Execute a program under the control of Sandboxie.
; TODO: On an x64 system, AHK cannot launch shortcuts pointing to x64 programs
executeShortcut(box, shortcut)
{
    global start

    ; tries to CD to the directory included in the shortcut
    curdir := findCurrentDir(box, shortcut)
    SetWorkingDir, %curdir%
    if (ErrorLevel) {
        ; if it fails, CD to the directory of the shortcut
        SplitPath, shortcut, , curdir
        SetWorkingDir, %curdir%
    }

    ; run the shortcut or file
    if (box) {
        run, %start% /box:%box% %shortcut%, %curdir%, UseErrorLevel
    } else {
        run, %shortcut%, %curdir%, UseErrorLevel
        ; AHK cannot launch shortcuts pointing to x64 programs in C:\Program Files\
        if (ErrorLevel != 0) {
            SplitPath, shortcut, , , extension
            if (extension == "lnk") {
                FileGetShortcut, %shortcut%, target, dir, args, , , , runState
                stringReplace, target, target, Program Files (x86), Program Files
                run, %target% %args%, %curdir%, UseErrorLevel
                if (ErrorLevel != 0) {
                    stringReplace, target, target, Program Files, Program Files (x86)
                    run, %target% %args%, %curdir%, UseErrorLevel
                }
            }
        }
        if (ErrorLevel == "ERROR")
            soundbeep
    }
    setWorkingDir %A_ScriptDir%
    Return
}

; Creates a shortut on the (normal) desktop to run the program under the control of Sandboxie.
createDesktopShortcutFromLnk(box, shortcut, iconfile, iconnum)
{
    global start

    SplitPath, shortcut, outFileName, outDir1, outExtension, outNameNoExt, outDrive

    if (box == "") {
        if (outExtension == "lnk") {
            dest = %userprofile%\Desktop\%outFileName%
            ; safety check
            loop
            {
                ifExist %dest%
                {
                    MsgBox, 294, %title%, File "%dest%" already exists on your desktop!`n`nClick Continue to overwrite it.
                    ifMsgBox Continue
                        break
                    ifMsgBox Cancel
                        Return
                } else
                    break
            }
            FileCopy, %shortcut%, %dest%, 1
        } else {
            writeUnsandboxedShortcutFileToDesktop(shortcut,outNameNoExt,outDir1,"","SandboxToys User Tool","","",1)
        }
        Return
    }

    SplitPath, shortcut, outFileName, outDir1, outExtension, outNameNoExt, outDrive
    curdir := findCurrentDir(box, shortcut)
    if (outExtension == "lnk") {
        FileGetShortcut, %shortcut%, outTarget, outDir, outArgs, outDescription, outIcon, outIconNum, outRunState
        outArgs = /box:%box% "%outTarget%" %outargs%
        if (NOT outDir)
            outDir := boxPathToStdPath(box, outTarget)
        OutDir := stdPathToBoxPath(box, outDir)
        if (outDescription)
            outDescription = Run "%outNameNoExt%" in sandbox %box%.`n%outDescription%
        else
            outDescription = Run "%outNameNoExt%" in sandbox %box%.
    } else {
        file := boxPathToStdPath(box, shortcut)
        outArgs = /box:%box% "%file%"
        splitPath, file, , outDir
        outDescription = Run "%outNameNoExt%" in sandbox %box%.
        outRunState = 1
    }
    outIcon := iconfile
    if (iconnum = 0)
        iconnum = 1
    outIconNum := iconnum
    outTarget = %start%

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
            name = [#ask box] %name%
        else
            name = [#%box%] %name%
    }
    else
        name = [#] %name%
    linkFile = %userprofile%\Desktop\%name%.lnk

    ; safety check
    loop
    {
        ifExist %linkFile%
        {
            MsgBox, 294, %title%, Shortcut "%name%" already exists on your desktop!`n`nClick Continue to overwrite it.
            ifMsgBox Continue
                break
            ifMsgBox Cancel
                Return
        } else
            break
    }
    ; create the shortcut
    FileCreateShortcut, %Target%, %linkFile%, %Dir%, %Args%, %Description%, %IconFile%, , %IconNum%, %RunState%
    Return
}

; write a normal (unsandboxed) shortcut.
writeUnsandboxedShortcutFileToDesktop(target,name,dir,args,description,iconFile,iconNum,runState)
{
    global title

    linkFile = %userprofile%\Desktop\%name%.lnk

    ; safety check
    loop
    {
        ifExist %linkFile%
        {
            MsgBox, 294, %title%, Shortcut "%name%" already exists on your desktop!`n`nClick Continue to overwrite it.
            ifMsgBox Continue
                break
            ifMsgBox Cancel
                Return
        } else
            break
    }
    ; create the shortcut
    FileCreateShortcut, %Target%, %linkFile%, %Dir%, %Args%, %Description%, %IconFile%, , %IconNum%, %RunState%
    Return
}

; return the box name of the last selected menu item
getBoxFromMenu()
{
    Return (SubStr(A_ThisMenu, 1, InStr(A_ThisMenu, "_ST2")-1))
}

; create a sandboxed shortcut on the desktop
NewShortcut(box, file)
{
    global menuicons, start
    splitPath, file, , dir, extension, label
    if (! FileExist(dir))
        dir := stdPathToBoxPath(box, dir)
    A_Quotes = "
    ; TODO: Handle the .LNK, .URL, .HTM and .HTML files correctly!
    ; TODO: verify that start.exe is not launched in a sandbox!
    if (extension == "exe")
    {
        iconfile := file
        iconnum = 1
    }
    else
    {
        Menu, __TEMP__, Add, __TEMP__, DummyMenuHandler
        icon := setIconFromSandboxedShortcut(box, file, "__TEMP__", "__TEMP__", 32)
        idx := InStr(icon, ",", false, 0)
        iconfile := SubStr(icon, 1, idx-1)
        iconnum := SubStr(icon, idx+1)
        if (iconnum < 0)
            iconnum := IndexOfIconResource(iconfile, iconnum)
    }
    if (box == "__ask__")
        tip = Launch "%label%" in any sandbox
    else
        tip = Launch "%label%" in sandbox %box%
    writeSandboxedShortcutFileToDesktop(start, label, dir, "/box:" box " " A_Quotes file A_Quotes, tip, iconfile, iconnum, 1, box)
}

; Since the sandbox has to be active to access its registry, it is necessary
; to run something in the box when the registry has to be accessed.
; This function ensures that the box is active by opening the Sandboxie Run Dialog
; in the specified box.  The Run dialog is launched in hidden mode.
; The function returns the PID of the Run process, that must be used to close
; the Run dialog and release the box.
InitializeBox(box)
{
    global start
    global sandboxes_array
    bregstr_ := sandboxes_array[box].KeyRootPath
    bregstr_ := StrReplace(StrReplace(SubStr(bregstr_, 16), `%SANDBOX`%, box), `%USER`%, username)
    ; ensure that the box is in use, or the hive will not be loaded
    Run %start% /box:%box% run_dialog, , HIDE UseErrorLevel, run_pid

    ; wait til the registry hive has been loaded in the global registry
    boxkeypath = %bregstr_%\user\current\software\SandboxAutoExec
    loop, 100
    {
        sleep, 50
        RegRead, keyvalueval, HKEY_USERS, %boxkeypath%
        if (NOT ErrorLevel)
            break
    }

    Return, %run_pid%
}

; This function closes the hidden Run dialog, so that Sandboxie can deactivate
; the sandbox (unless something else is running in the box, of course.)
ReleaseBox(run_pid)
{
    Sleep 800
    DetectHiddenWindows, on
    WinClose, ahk_pid %run_pid%, , 1
    IfWinExist, ahk_pid %run_pid%
        Process, Close, %run_pid%
    Sleep 200
    Return
}

; ###################################################################################################
; "Find" and associated ListBox functions and handlers
; ###################################################################################################

SearchFiles(bp, rp, boxbasepath, ignoredDirs, ignoredFiles, comparedata="")
{
    A_nl = `n
    sep := A_Tab

    olddir := A_WorkingDir
    SetWorkingDir %bp%

    boxbasepathlen := StrLen(boxbasepath) + 2

    r =
    Loop, *, 0, 0
    {
        rf = %rp%\%A_LoopFileFullPath%
        bf = %bp%\%A_LoopFileFullPath%
        SplitPath, bf, fname, boxsubpath
        boxsubpath := SubStr(boxsubpath, boxbasepathlen)
        if (IsIgnored("files", ignoredFiles, boxsubpath, fname))
            continue

        if (comparedata != "")
        {
            if (A_LoopFileTimeCreated == "19860523174702")
                status = -
            else
                status = +
            comp = %status% %A_LoopFileTimeModified% %boxsubpath%\%fname%:*:
            if (InStr(comparedata, comp))
                Continue
        }

        FormatTime, timeCreated, %A_LoopFileTimeCreated%, yyyy/MM/dd HH:mm:ss
        FormatTime, timeModified, %A_LoopFileTimeModified%, yyyy/MM/dd HH:mm:ss
        FormatTime, timeAccessed, %A_LoopFileTimeAccessed%, yyyy/MM/dd HH:mm:ss
        if (A_LoopFileTimeCreated == "19860523174702")
            st = -
        else
        {
            if (FileExist(rf))
                st = #
            else
                st = +
        }
        r = %r%%st%%sep%%rf%%sep%%A_LoopFileAttrib%%sep%%A_LoopFileSize%%sep%%timeCreated%%sep%%timeModified%%sep%%timeAccessed%%sep%%boxsubpath%`n
    }
    Loop, *, 2, 0
    {
        bdir = %bp%\%A_LoopFileFullPath%
        boxsubpath := SubStr(bdir, boxbasepathlen)
        if (IsIgnored("dirs", ignoredDirs, boxsubpath))
            continue

        if (comparedata != "")
        {
            if (A_LoopFileTimeCreated == "19860523174702")
                status = -
            else
                status = +
            comp = %status% %A_LoopFileTimeModified% %boxsubpath%:*:
            if (InStr(comparedata, comp))
                Continue
        }

        rdir = %rp%\%A_LoopFileFullPath%
        ret := SearchFiles(bdir, rdir, boxbasepath, ignoredDirs, ignoredFiles, comparedata)
        if (ret != "")
            r = %r%%ret%`n
    }
    r := Trim(r,A_nl)

    SetWorkingDir %olddir%

    return %r%
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

; List files in sandbox
ListFiles(box, bpath, comparefilename="")
{
    global ignoredDirs, ignoredFiles, ignoredKeys, ignoredValues
    global guinotclosed, title, MyListView, LVLastSize
    global newIgnored_dirs, newIgnored_files

    static MainLabel

    A_nl = `n
    allfiles =

    ReadIgnoredConfig("files")
    newIgnored_dirs =
    newIgnored_files =

    Progress, A M R0-100, Please wait..., Searching for files`nin box "%box%"., %title%
    Progress, 10

    if (comparefilename != "")
        FileRead, comparedata, %comparefilename%
    else
        comparedata =

    bp = %bpath%\user\current
    rp = %userprofile%
    if (InStr(FileExist(bp),"D"))
    {
        f := SearchFiles(bp, rp, bpath, ignoredDirs, ignoredFiles, comparedata)
        allfiles = %allfiles%%f%`n
    }

    Progress, 13
    bp = %bpath%\user\all
    rp = %allusersprofile%
    if (InStr(FileExist(bp),"D"))
    {
        f := SearchFiles(bp, rp, bpath, ignoredDirs, ignoredFiles, comparedata)
        allfiles = %allfiles%%f%`n
    }

    Progress, 16
    Loop, %bpath%\drive\*, 2, 0
    {
        drive := A_LoopFileName
        bp = %bpath%\drive\%A_LoopFileName%
        rp = %A_LoopFileName%:
        f := SearchFiles(bp, rp, bpath, ignoredDirs, ignoredFiles, comparedata)
        allfiles = %allfiles%%f%`n
    }

    Progress, 19, Please wait..., Sorting list of files`nin box "%box%"., %title%
    Sort(allfiles, "CL P3")
    allfiles := Trim(allfiles, A_nl)
    numfiles = 0
    loop, parse, allfiles, `n
        numfiles ++
    if (numfiles = 0)
    {
        Progress, OFF
        if (comparefilename == "")
            MsgBox, 64, %title%, No meaningful files in box "%box%"!
        else
            MsgBox, 64, %title%, No new or modified files in box "%box%"!
        Return
    }

    if (LVLastSize == "") {
        SysGet, mon, MonitorWorkArea
        if (monRight == "") {
            width := A_ScreenWidth - 300
            height := A_ScreenHeight - 300
        } else {
            width := monRight - monLeft - 250
            height := monBottom - monTop - 250
        }
        if (width < 752)
            width = 752
        maxrows := height / 18
        if (numfiles < maxrows)
        {
            if (numfiles < 3)
                numrows = 3
            else
                numrows = %numfiles%
            numrows := numrows+2
            heightarg = r%numrows%
        } else
            heightarg = h%height%
        LVLastSize = w%width% %heightarg%
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
    ImageListID1 := IL_Create(10)
    MyListView.SetImageList(ImageListID1)

    Progress(20, "Please wait...", "Building list of files`nin box """ . box . """...", title)

    ; add entries in listview
    nummodified := 0
    numadded := 0
    numdeleted := 0
    sep := A_Tab
    MyListView.Redraw := false
    old_prog := 0
    loop, parse, allfiles, `n
    {
        entry := A_LoopField
        prog := round(80 * A_Index / numfiles) + 20
        if (prog != old_prog)
        {
            Progress(prog)
            Sleep(1)
            old_prog := prog
        }

        loop, parse, entry, sep
        {
            if (A_Index == 1)
            {
                St := A_LoopField
                deleted := 0
                if (St == "#")
                    nummodified++
                else if (St == "+")
                    numadded++
                else if (St == "-")
                {
                    numdeleted++
                    deleted := 1
                }
            }
            else if (A_Index == 2)
                SplitPath(A_LoopField, &OutFileName, &OutDir, &OutExtension)
            else if (A_Index == 3)
                Attribs := A_LoopField
            else if (A_Index == 4)
                Size := A_LoopField
            else if (A_Index == 5)
                Created := A_LoopField
            else if (A_Index == 6)
                Modified := A_LoopField
            else if (A_Index == 7)
                Accessed := A_LoopField
            else if (A_Index == 8)
                BoxPath := A_LoopField
        }
        if (St == "-")
            Created := ""
        iconfile := bpath . "\" . BoxPath . "\" . OutFileName
        if (!FileExist(iconfile))
            iconfile := boxPathToStdPath(box, iconfile)

        hIcon := GetAssociatedIcon(iconfile, false, 16, box, deleted)
        IconNumber := DllCall("ImageList_ReplaceIcon", "uint", ImageListID1, "int", -1, "uint", hIcon) + 1
        MyListView.Add("Icon" . IconNumber, St . A_Space, OutFileName, OutDir, Size, Attribs, Created, Modified, Accessed, OutExtension, BoxPath)
    }
    Progress(100)
    Sleep(50)

    MyListView.ModifyCol()
    MyListView.ModifyCol(4, "Integer")

    msg = Found %numfiles% file
    if (numfiles != 1)
        msg = %msg%s
    msg = %msg% in the sandbox "%box%"
    msg = %msg% : # %nummodified% modified file
    if (nummodified != 1)
        msg = %msg%s
    msg = %msg% , + %numadded% new file
    if (numadded != 1)
        msg = %msg%s
    msg = %msg% , - %numdeleted% deleted file
    if (numdeleted != 1)
        msg = %msg%s
    msg = %msg%. Double-click an entry to copy the file to the desktop.
    MainLabel.Text := msg

    Progress, OFF
    MyListView.Redraw := true
    MyGui.Show()

    guinotclosed = 1
    while (guinotclosed)
        Sleep 1000
    SaveNewIgnoredItems("files")

    return
}

GuiSize(GuiObj, EventInfo, Width, Height)
{
    if EventInfo = 1 ; The window has been minimized.  No action needed.
        return
    global LVLastSize, MyListView
    LVLastSize := "w" . (Width - 20) . " h" . (Height - 40)
    MyListView.Move(LVLastSize)
}

; Copy To...
GuiLVCurrentFileSaveTo(row)
{
    global sandboxes_array, box, DefaultFolder, MyGui, MyListView
    LVFileName := MyListView.GetText(row, 2)
    LVExtension := MyListView.GetText(row, 9)
    LVFilePath := MyListView.GetText(row, 10)
    boxpath := sandboxes_array[box].bpath
    MyGui.Opt("+OwnDialogs")
    if (!InStr(FileExist(DefaultFolder . "\"), "D"))
        DefaultFolder := A_Desktop
    filename := FileSelect("S16", DefaultFolder . "\" . LVFileName, "Copy """ . LVFileName . """ from sandbox to...", LVExtension . " files (*." . LVExtension . ")")
    if (filename == "")
        Return
    FileCopy(boxpath . "\" . LVFilePath . "\" . LVFileName, filename, 1)
    SplitPath(filename, , &DefaultFolder)
}

; Open in Sandbox
GuiLVCurrentFileRun(row)
{
    global sandboxes_array, box
    LVCurrentFileRun(row, box, sandboxes_array[box].bpath)
}
LVCurrentFileRun(row, box, boxpath)
{
    global start, title, MyListView
    LVFileName := MyListView.GetText(row, 2)
    LVPath := MyListView.GetText(row, 10)
    Filename := boxpath . "\" . LVPath . "\" . LVFileName
    old_pwd := A_WorkingDir
    SetWorkingDir(boxpath . "\" . LVPath)
    Run('"' . start . '" /box:' . box . ' "' . Filename . '"',, "UseErrorLevel")
    MsgBox("Running """ . Filename . """ in box " . box . ".`n`nPlease wait...", title, 64, 3)
    SetWorkingDir(old_pwd)
    Return
}
GuiLVCurrentFileOpenContainerU(row, *) {
    GuiLVCurrentFileOpenContainer(row, box, sandboxes_array[box].bpath, "u")
}

GuiLVCurrentFileOpenContainerS(row, *) {
    GuiLVCurrentFileOpenContainer(row, box, sandboxes_array[box].bpath, "s")
}
GuiLVCurrentFileOpenContainer(row, box, boxpath, mode)
{
    global start, title, MyGui, MyListView
    MyGui.Opt("+OwnDialogs")
    if (mode == "u")
    {
        CurPath := MyListView.GetText(row, 10)
        Curpath := boxpath . "\" . CurPath
        Run('"' . Curpath . '"',, "UseErrorLevel")
    }
    else
    {
        LVBoxFile := MyListView.GetText(row, 2)
        CurPath := MyListView.GetText(row, 3)
        Run('"' . start . '" /box:' . box . ' "' . CurPath . '"',, "UseErrorLevel")
        MsgBox("Opening container of """ . LVBoxFile . """ in box " . box . ".`n`nPlease wait...", title, 64, 3)
    }
    Return
}

GuiLVCurrentFileToStartMenu(row, *) {
    GuiLVCurrentFileToStartMenuOrDesktop(row, box, sandboxes_array[box].bpath, "startmenu")
}

GuiLVCurrentFileToDesktop(row, *) {
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
    if (mode == "unsandboxed") {
        if (user == "current") {
            bpath = %boxpath%\user\current\AppData\Roaming\Microsoft\Windows\Start Menu\Programs\Startup
            mowner = Current User's
        } else {
            bpath = %boxpath%\user\all\Microsoft\Windows\Start Menu\Programs\Startup
            mowner = All Users
        }
        if (FileExist(bpath)) {
            Run, %bpath%
        } else {
            MsgBox, 48, %title%, The %mowner% Start Menu of box %box% has not been created yet.`n`nCan't explore it unsandboxed.
        }
    }
    else
    {
        if (user == "current")
            bpath = %A_StartMenu%\Programs\Startup
        else
            bpath = %A_StartMenuCommon%\Programs\Startup
        Run, %start% /box:%box% "%bpath%"
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
    if (strLen(str) <= 80)
        return %str%

    A_Quotes = "
    idx := InStr(str, A_Quotes . "=")
    if (idx < 76)
        idx = 76
    idx := InStr(str, ",", 0, idx)
    if (idx == 0)
        return %str%

    out := SubStr(str, 1, idx)
    out = %out%\`n
    str := subStr(str, idx+1)
    loop
    {
        if (StrLen(str) < 78)
        {
            out = %out% %str%
            break
        }
        idx := InStr(str, ",", 0, 75)
        sub := subStr(str, 1, idx)
        out = %out% %sub%\`n
        str := subStr(str, idx+1)
    }
    return %out%
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
    outtxt =
    insubkeylen := StrLen(insubkey)+1
    outfullkey = %outrootkey%
    if (outsubkey != "")
        outfullkey = %outfullkey%\%outsubkey%

    Loop, %inrootkey%, %insubkey%, 1, 1
    {
        subkey := outfullkey . SubStr(A_LoopRegSubKey, insubkeylen)
        if (A_LoopRegType != "KEY")
            RegRead, value
        else
            value =
        outtxt = %outtxt%%A_LoopRegTimeModified% %A_LoopRegType% %A_LoopRegName% %subkey% %value%`n
    }
    return %outtxt%
}

FormatRegConfigKey(RegSubKey, subkey, RegType, RegName, RegTimeModified, separator, includedate=false)
{
    type := RegType
    if (type == "")
        type := RegRead64KeyType("HKEY_USERS", RegSubKey, RegName, false)
    if (type == "")
        type = UNKNOWN

    if (RegTimeModified == "19860523174702")
        status = -
    else
        status = +
    if (type == "REG_SB_DELETED")
    {
        status = -
        type = -DELETED_VALUE
    }

    RegRead, value
    if (ErrorLevel)
    {
        value := RegRead64("HKEY_USERS", RegSubKey, RegName)
        if (ErrorLevel)
        {
            value := RegRead64("HKEY_USERS", RegSubKey, RegName, false)
            if (ErrorLevel)
            {
                value =
                status = -
            }
        }
    }
    if (InStr(type, "_SZ"))
    {
        StringReplace, value, value, `n, %A_Space%, 1
        if (type == "REG_MULTI_SZ")
            StringTrimRight, value, value, 1
    }
    if (StrLen(value) > 80)
        value := SubStr(value, 1, 80) . "..."

    name = %RegName%
    if (name == "")
        name = @

    if (type == "KEY")
    {
        if (status == "-")
            type = -DELETED_KEY
        outtxt = %status%%separator%%subkey%\%name%%separator%%type%%separator%%separator%
    }
    else
        outtxt = %status%%separator%%subkey%%separator%%type%%separator%%name%%separator%%value%
    if (includedate)
        outtxt = %outtxt%%separator%%RegTimeModified%
    return %outtxt%
}

MakeFilesConfig(box, filename, mainsbpath)
{
    mainsbpathlen := StrLen(mainsbpath) + 2

    outtxt =

    Loop, %mainsbpath%\drive\*, 1, 1
    {
        if (A_LoopFileTimeCreated == "19860523174702")
            status = -
        else
            status = +
        if (InStr(A_LoopFileAttrib, "D") && status == "+")
            Continue
        name := SubStr(A_LoopFileFullPath, mainsbpathlen)
        outtxt = %outtxt%%status% %A_LoopFileTimeModified% %name%:*:`n
    }
    Loop, %mainsbpath%\user\*, 1, 1
    {
        if (A_LoopFileTimeCreated == "19860523174702")
            status = -
        else
            status = +
        if (InStr(A_LoopFileAttrib, "D") && status == "+")
            Continue
        name := SubStr(A_LoopFileFullPath, mainsbpathlen)
        outtxt = %outtxt%%status% %A_LoopFileTimeModified% %name%:*:`n
    }

    FileDelete, %filename%
    FileAppend, `n%outtxt%, %filename%
    Return
}

MakeRegConfig(box, filename="")
{
    global regconfig
    run_pid := InitializeBox(box)

    global sandboxes_array
    bregstr_ := sandboxes_array[box].KeyRootPath
    bregstr_ := StrReplace(StrReplace(SubStr(bregstr_, 16), `%SANDBOX`%, box), `%USER`%, username)

    mainsbkey = %bregstr_%
    mainsbkeylen := StrLen(mainsbkey) + 2

    outtxt =

    Loop, HKEY_USERS, %mainsbkey%, 1, 1
    {
        if (A_LoopRegTimeModified != "")
            RegTimeModified = %A_LoopRegTimeModified%

        if (A_LoopRegType == "KEY" && A_LoopRegTimeModified != "19860523174702")
            Continue

        subkey := SubStr(A_LoopRegSubKey, mainsbkeylen)
        out := FormatRegConfigKey(A_LoopRegSubKey, subkey, A_LoopRegType, A_LoopRegName, RegTimeModified, A_Space)
        outtxt = %outtxt%%out%`n
    }

    if (filename == "")
        filename = %regconfig%
    FileDelete, %filename%
    FileAppend, `n%outtxt%, %filename%

    ReleaseBox(run_pid)

    Return
}

SearchReg(box, ignoredKeys, ignoredValues, filename="")
{
    global regconfig

    run_pid := InitializeBox(box)

    global sandboxes_array
    bregstr_ := sandboxes_array[box].KeyRootPath
    bregstr_ := StrReplace(StrReplace(SubStr(bregstr_, 16), `%SANDBOX`%, box), `%USER`%, username)

    mainsbkey = %bregstr_%
    mainsbkeylen := StrLen(mainsbkey) + 2

    if (filename == "")
        filename = %regconfig%
    FileRead, regconfigdata, %filename%
    outtxt =

    LastIgnoredKey = !xxx!:\
    Loop, HKEY_USERS, %mainsbkey%, 1, 1
    {
        if (A_LoopRegTimeModified != "")
            RegTimeModified := A_LoopRegTimeModified

        subkey := SubStr(A_LoopRegSubKey, mainsbkeylen)
        if (InStr(subkey, LastIgnoredKey) == 1)
            Continue

        if (A_LoopRegType == "KEY")
        {
            if (A_LoopRegTimeModified != "19860523174702")
                Continue
            if (IsIgnored("keys", ignoredKeys, subkey . "\" . A_LoopRegName))
            {
                LastIgnoredKey = %subkey%\%A_LoopRegName%
                Continue
            }
        }
        else
        {
            if A_LoopRegName =
            {
                if (IsIgnored("values", ignoredValues, subkey, "@"))
                    Continue
            }
            else
            {
                if (IsIgnored("values", ignoredValues, subkey, A_LoopRegName))
                    Continue
            }
        }
        if (IsIgnored("keys", ignoredKeys, subkey))
        {
            LastIgnoredKey = %subkey%
            Continue
        }

        out := FormatRegConfigKey(A_LoopRegSubKey, subkey, A_LoopRegType, A_LoopRegName, RegTimeModified, A_Space)
        if (NOT InStr(regconfigdata, out))
        {
            out := FormatRegConfigKey(A_LoopRegSubKey, subkey, A_LoopRegType, A_LoopRegName, RegTimeModified, chr(1), true)
            outtxt = %outtxt%%out%`n
        }
    }

    ReleaseBox(run_pid)

    Return %outtxt%
}

ListReg(box, bpath, filename="")
{
    global ignoredDirs, ignoredFiles, ignoredKeys, ignoredValues
    global guinotclosed, title, MyListView, LVLastSize
    global newIgnored_keys, newIgnored_values
    static MainLabel

    if (filename != "")
        comparemode = 1
    else
        comparemode = 0
    A_Quotes = "

    ReadIgnoredConfig("reg")
    newIgnored_keys =
    newIgnored_values =

    A_nl = `n
    Progress, A M R0-100, Please wait..., Scanning registry`nof box "%box%"., %title%
    Progress, 50

    StringReplace, ignoredKeys, ignoredKeys, :, ., 1
    allregs := SearchReg(box, ignoredKeys, ignoredValues, filename)

    Progress, 90, Please wait..., Sorting list of files`nin box "%box%"., %title%
    sleep 150
    Sort(allregs, "P3")
    allregs := Trim(allregs, A_nl)
    numregs = 0
    loop, parse, allregs, `n
        numregs ++
    if (numregs = 0)
    {
        Progress, OFF
        if (comparemode)
            MsgBox, 64, %title%, No registry keys or values have been modified in box "%box%"!
        else
            MsgBox, 64, %title%, No meaningful registry keys or values found in box "%box%"!
        Return
    }

    if (LVLastSize == "") {
        SysGet, mon, MonitorWorkArea
        if (monRight == "") {
            width := A_ScreenWidth - 300
            height := A_ScreenHeight - 300
        } else {
            width := monRight - monLeft - 250
            height := monBottom - monTop - 250
        }
        if (width < 752)
            width = 752
        maxrows := height / 18
        if (numregs < maxrows)
        {
            if (numregs < 3)
                numrows = 3
            else
                numrows = %numregs%
            numrows := numrows+2
            heightarg = r%numrows%
        } else
            heightarg = h%height%
        LVLastSize = w%width% %heightarg%
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

    Progress, 100, Please wait..., Building list of keys`nin box "%box%"., %title%
    Sleep, 100

    ; add entries in listview
    nummodified := 0
    numadded := 0
    numdeleted := 0
    MyListView.Redraw := false
    sep := Chr(1)
    loop, parse, allregs, `n
    {
        entry := A_LoopField
        loop, parse, entry, sep
        {
            if (A_Index == 1) {
                St := A_LoopField
            } else if (A_Index == 2) {
                ; HKEY_USERS\%mainsbkey%\machine
                ; -> HKEY_LOCAL_MACHINE
                ;
                ; HKEY_USERS\%mainsbkey%\user\current\software
                ; -> HKEY_CURRENT_USER\Software
                ;
                ; HKEY_USERS\%mainsbkey%\user\current_classes
                ; same as HKEY_USERS\%mainsbkey%\user\current\software\classes
                ; -> HKEY_CLASSES_ROOT

                keypath := A_LoopField
                if (SubStr(keypath, 1, 8) == "machine\")
                    realkeypath := "HKEY_LOCAL_MACHINE" . SubStr(keypath, 8)
                else if (SubStr(keypath, 1, 13) == "user\current\")
                    realkeypath := "HKEY_CURRENT_USER" . SubStr(keypath, 13)
                else if (SubStr(keypath, 1, 21) == "user\current_classes\")
                    realkeypath := "HKEY_CLASSES_ROOT" . SubStr(keypath, 21)
            } else if (A_Index == 3) {
                keytype := A_LoopField
            } else if (A_Index == 4) {
                keyvaluename := A_LoopField
            } else if (A_Index == 5) {
                keyvalueval := A_LoopField
            } else if (A_Index == 6) {
                modtime := FormatTime(A_LoopField, "yyyy/MM/dd HH:mm:ss")
            }
        }
        if (St == "+") {
            if (keytype != "KEY")
            {
                idx := InStr(realkeypath, "\")
                realrootkey := SubStr(realkeypath, 1, idx-1)
                realsubkey := SubStr(realkeypath, idx+1)
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
        } else{
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

    msg = Found %numregs% registry key
    if (numregs != 1)
        msg = %msg%s or values
    else
        msg = %msg% or value
    msg = %msg% in the sandbox "%box%"
    msg = %msg% : # %nummodified% modified
    msg = %msg% , + %numadded% new
    msg = %msg% , - %numdeleted% deleted
    msg = %msg%. Double-click a key to open it in RegEdit.
    MainLabel.Text := msg

    Progress, OFF
    MyListView.Redraw := true
    MyGui.Show()

    guinotclosed = 1
    while (guinotclosed)
        Sleep 1000
    SaveNewIgnoredItems("reg")

    return
}

SearchAutostart(box, regpath, location, tick)
{
    A_Nl = `n
    outtxt =
    Loop, HKEY_USERS, %regpath%, 0, 0
    {
        if (A_LoopRegType != "REG_SZ")
            Continue
        RegRead, value
        outtxt := outtxt . A_LoopRegName . A_Tab . value . A_Tab . location . A_Tab . tick . A_nl
    }
    Sort(outtxt, "CL D`n")
    Return outtxt
}
ListAutostarts(box, bpath)
{
    global guinotclosed, title, MyListView
    static MainLabel

    A_Quotes = "
    A_nl = `n

    global sandboxes_array
    bregstr_ := sandboxes_array[box].KeyRootPath
    bregstr_ := StrReplace(StrReplace(SubStr(bregstr_, 16), `%SANDBOX`%, box), `%USER`%, username)

    run_pid := InitializeBox(box)
    Sleep 1000

    autostarts =

    ; check RunOnce keys
    key = %bregstr_%\machine\Software\Microsoft\Windows\CurrentVersion\RunOnce
    location = HKLM RunOnce
    autostarts := autostarts . SearchAutostart(box, key, location, 0)

    key = %bregstr_%\machine\Software\Wow6432Node\Microsoft\Windows\CurrentVersion\RunOnce
    location = HKLM RunOnce
    autostarts := autostarts . SearchAutostart(box, key, location, 0)

    key = %bregstr_%\user\current\Software\Microsoft\Windows\CurrentVersion\RunOnce
    location = HKCU RunOnce
    autostarts := autostarts . SearchAutostart(box, key, location, 0)

    key = %bregstr_%\user\current\Software\Wow6432Node\Microsoft\Windows\CurrentVersion\RunOnce
    location = HKCU RunOnce
    autostarts := autostarts . SearchAutostart(box, key, location, 0)

    ; check Run keys
    key = %bregstr_%\machine\Software\Microsoft\Windows\CurrentVersion\Run
    location = HKLM Run
    autostarts := autostarts . SearchAutostart(box, key, location, 1)

    key = S%bregstr_%\machine\Software\Wow6432Node\Microsoft\Windows\CurrentVersion\Run
    location = HKLM Run
    autostarts := autostarts . SearchAutostart(box, key, location, 1)

    key = %bregstr_%\user\current\Software\Microsoft\Windows\CurrentVersion\Run
    location = HKCU Run
    autostarts := autostarts . SearchAutostart(box, key, location, 1)

    key = %bregstr_%\user\current\Software\Wow6432Node\Microsoft\Windows\CurrentVersion\Run
    location = HKCU Run
    autostarts := autostarts . SearchAutostart(box, key, location, 1)

    ReleaseBox(run_pid)

    numregs = 0
    autostarts := Trim(autostarts, A_nl)
    loop, parse, autostarts, `n
        numregs ++
    if (numregs = 0)
    {
        MsgBox, 64, %title%, No autostart programs found in the registry of box "%box%".
        Return
    }

    if (LVLastSize == "") {
        SysGet, mon, MonitorWorkArea
        if (monRight == "") {
            width := A_ScreenWidth - 300
            height := A_ScreenHeight - 300
        } else {
            width := monRight - monLeft - 250
            height := monBottom - monTop - 250
        }
        if (width < 752)
            width = 752
        maxrows := height / 18
        if (numregs < maxrows)
        {
            if (numregs < 3)
                numrows = 3
            else
                numrows = %numregs%
            numrows := numrows+2
            heightarg = r%numrows%
        } else
            heightarg = h%height%
        LVLastSize = w%width% %heightarg%
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
    ImageListID1 := IL_Create(10)
    MyListView.SetImageList(ImageListID1)

    ; add entries in listview
    MyListView.Redraw := false
    sep := Chr(1)
    row := 1
    loop, parse, autostarts, `n
    {
        entry := A_LoopField
        loop, parse, entry, A_Tab
        {
            ; A_LoopRegName / value / location / tick
            if (A_Index == 1) {
                valuename := A_LoopField
            } else if (A_Index == 2) {
                valuedata := A_LoopField
            } else if (A_Index == 3) {
                location := A_LoopField
            } else if (A_Index == 4) {
                ticked := A_LoopField
            }
        }
        if (valuedata != "")
        {
            program := valuedata
            if (SubStr(valuedata, 1, 1) == A_Quotes)
            {
                idx2 := InStr(valuedata, A_Quotes, 0, 2)
                if (idx2)
                    program := SubStr(valuedata, 2, idx2-2)
            }
            boxprogram := StdPathToBoxPath(box, program)
            if (!FileExist(boxprogram))
                boxprogram := program
            hIcon := GetAssociatedIcon(boxprogram, false, 16, box)
            IconNumber := DllCall("ImageList_ReplaceIcon", "uint", ImageListID1, "int", -1, "uint", hIcon) + 1
            MyListView.Add("Icon" . IconNumber, "", valuename, valuedata, location)
            if (ticked)
                MyListView.Modify(row, "Check")
        }
        else
            MyListView.Add("Icon0", "", valuename, "", location)

        row++
    }
    MyListView.ModifyCol()

    msg = Found %numregs% autostart program
    if (numregs != 1)
        msg = %msg%s
    else
        msg = %msg%
    msg = %msg% in the sandbox "%box%"
    msg = %msg%. Double-click an entry to run it.
    MainLabel.Text := msg
    MyListView.Redraw := true
    MyGui.Show()

    guinotclosed = 1
    while (guinotclosed)
        Sleep 1000
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
    HKEY_CLASSES_ROOT := 0x80000000 ; http://msdn.microsoft.com/en-us/library/aa393286.aspx
    HKEY_CURRENT_USER := 0x80000001
    HKEY_LOCAL_MACHINE := 0x80000002
    HKEY_USERS := 0x80000003
    HKEY_CURRENT_CONFIG := 0x80000005
    HKEY_DYN_DATA := 0x80000006

    ; http://msdn.microsoft.com/en-us/library/ms724884.aspx
    REG_NONE := 0 ; unsupported
    REG_SZ := 1 ; supported
    REG_EXPAND_SZ := 2 ; supported
    REG_BINARY := 3 ; supported
    REG_DWORD := 4 ; supported
    REG_DWORD_BIG_ENDIAN := 5 ; supported, but handled like REG_DWORD
    REG_LINK := 6
    REG_MULTI_SZ := 7 ; supported
    REG_RESOURCE_LIST := 8 ; UNSUPPORTED!
    ; added by r0lZ
    REG_FULL_RESOURCE_DESCRIPTOR := 9 ; UNSUPPORTED!
    REG_RESOURCE_REQUIREMENTS_LIST := 10 ; UNSUPPORTED!
    REG_QWORD := 11 ; supported (but not in unsigned mode)

    KEY_QUERY_VALUE := 0x0001 ; http://msdn.microsoft.com/en-us/library/ms724878.aspx
    KEY_WOW64_64KEY := 0x0100 ; http://msdn.microsoft.com/en-gb/library/aa384129.aspx (do not redirect to Wow6432Node on 64-bit machines)
    KEY_WOW64_32KEY := 0x0200

    myhKey := %sRootKey% ; pick out value (0x8000000x) from list of HKEY_xx vars
    IfEqual,myhKey,, { ; Error - Invalid root key
        ErrorLevel := 3
        return ""
    }

    ; argument to read either in 64bit or 32bit mode added by r0lZ
    if (mode64bit)
        RegAccessRight := KEY_QUERY_VALUE + KEY_WOW64_64KEY
    else
        RegAccessRight := KEY_QUERY_VALUE + KEY_WOW64_32KEY

    DllCall("Advapi32.dll\RegOpenKeyEx", "uint", myhKey, "str", sKeyName, "uint", 0, "uint", RegAccessRight, "uint*", hKey) ; open key
    If (hKey==0) {
        ErrorLevel := 4
        return ""
    }
    DllCall("Advapi32.dll\RegQueryValueEx", "uint", hKey, "str", sValueName, "uint", 0, "uint*", sValueType, "uint", 0, "uint", 0) ; get value type

    If (sValueType == REG_SZ or sValueType == REG_EXPAND_SZ) {
        VarSetCapacity(sValue, vValueSize:=DataMaxSize)
        DllCall("Advapi32.dll\RegQueryValueEx", "uint", hKey, "str", sValueName, "uint", 0, "uint", 0, "str", sValue, "uint*", vValueSize) ; get string or string-exp
    } Else If (sValueType == REG_DWORD or sValueType == REG_DWORD_BIG_ENDIAN) {
        VarSetCapacity(sValue, vValueSize:=4)
        DllCall("Advapi32.dll\RegQueryValueEx", "uint", hKey, "str", sValueName, "uint", 0, "uint", 0, "uint*", sValue, "uint*", vValueSize) ; get dword
    } Else If (sValueType == REG_QWORD) {
        VarSetCapacity(sValue, vValueSize:=8) ; added by r0lZ
        DllCall("Advapi32.dll\RegQueryValueEx", "uint", hKey, "str", sValueName, "uint", 0, "uint", 0, "uint64*", sValue, "uint*", vValueSize) ; get qword
    } Else If (sValueType == REG_MULTI_SZ) {
        VarSetCapacity(sTmp, vValueSize:=DataMaxSize)
        DllCall("Advapi32.dll\RegQueryValueEx", "uint", hKey, "str", sValueName, "uint", 0, "uint", 0, "str", sTmp, "uint*", vValueSize) ; get string-mult
        if (as_hex)
        {
            sValue := ""
            SetFormat, integer, H
            Loop %vValueSize% {
                hex := SubStr(Asc(SubStr(sTmp,A_Index,1)),3)
                sValue := sValue hex
            }
            SetFormat, integer, d
        }
        else
        {
            sValue := ExtractData(&sTmp) "`n"
            Loop {
                If (errorLevel+2 >= &sTmp + vValueSize)
                    Break
                sValue := sValue ExtractData( errorLevel+1 ) "`n"
            }
        }
    } Else If (sValueType == REG_BINARY) {
        VarSetCapacity(sTmp, vValueSize:=DataMaxSize)
        DllCall("Advapi32.dll\RegQueryValueEx", "uint", hKey, "str", sValueName, "uint", 0, "uint", 0, "str", sTmp, "uint*", vValueSize) ; get binary
        sValue := ""
        SetFormat, integer, H
        Loop %vValueSize% {
            hex := SubStr(Asc(SubStr(sTmp,A_Index,1)),3)
            sValue := sValue hex
        }
        SetFormat, integer, d
    } Else If (sValueType == REG_NONE) {
        sValue := ""
    } Else { ; value does not exist or unsupported value type
        DllCall("Advapi32.dll\RegCloseKey", "uint", hKey)
        ErrorLevel := 1
        return ""
    }
    DllCall("Advapi32.dll\RegCloseKey", "uint", hKey)
    return sValue
}

RegRead64KeyType(sRootKey, sKeyName, sValueName = "", mode64bit=true) {
    HKEY_CLASSES_ROOT := 0x80000000 ; http://msdn.microsoft.com/en-us/library/aa393286.aspx
    HKEY_CURRENT_USER := 0x80000001
    HKEY_LOCAL_MACHINE := 0x80000002
    HKEY_USERS := 0x80000003
    HKEY_CURRENT_CONFIG := 0x80000005
    HKEY_DYN_DATA := 0x80000006

    REG_NONE := 0 ; http://msdn.microsoft.com/en-us/library/ms724884.aspx
    REG_SZ := 1
    REG_EXPAND_SZ := 2
    REG_BINARY := 3
    REG_DWORD := 4
    REG_DWORD_BIG_ENDIAN := 5
    REG_LINK := 6
    REG_MULTI_SZ := 7
    REG_RESOURCE_LIST := 8

    REG_FULL_RESOURCE_DESCRIPTOR := 9
    REG_RESOURCE_REQUIREMENTS_LIST := 10
    REG_QWORD := 11

    ; Unofficial REG type used by Sandboxie to "delete" an existing key in the sandbox registry.
    ; REG_SB_DELETED := 0x6B757A74
    REG_SB_DELETED := 0x786F6273

    KEY_QUERY_VALUE := 0x0001 ; http://msdn.microsoft.com/en-us/library/ms724878.aspx
    KEY_WOW64_64KEY := 0x0100 ; http://msdn.microsoft.com/en-gb/library/aa384129.aspx (do not redirect to Wow6432Node on 64-bit machines)
    KEY_WOW64_32KEY := 0x0200

    myhKey := %sRootKey% ; pick out value (0x8000000x) from list of HKEY_xx vars
    IfEqual,myhKey,, { ; Error - Invalid root key
        ErrorLevel := 3
        return ""
    }

    if (mode64)
        RegAccessRight := KEY_QUERY_VALUE + KEY_WOW64_64KEY
    else
        RegAccessRight := KEY_QUERY_VALUE + KEY_WOW64_32KEY

    DllCall("Advapi32.dll\RegOpenKeyEx", "uint", myhKey, "str", sKeyName, "uint", 0, "uint", RegAccessRight, "uint*", hKey) ; open key
    If (hKey==0) {
        ErrorLevel := 4
        return ""
    }
    DllCall("Advapi32.dll\RegQueryValueEx", "uint", hKey, "str", sValueName, "uint", 0, "uint*", sValueType, "uint", 0, "uint", 0) ; get value type

    If (sValueType == REG_NONE)
        keytype := "REG_NONE"
    Else If (sValueType == REG_SZ)
        keytype := "REG_SZ"
    Else If (sValueType == REG_EXPAND_SZ)
        keytype := "REG_EXPAND_SZ"
    Else If (sValueType == REG_BINARY)
        keytype := "REG_BINARY"
    Else If (sValueType == REG_DWORD)
        keytype := "REG_DWORD"
    Else If (sValueType == REG_DWORD_BIG_ENDIAN)
        keytype := "REG_DWORD_BIG_ENDIAN"
    Else If (sValueType == REG_LINK)
        keytype := "REG_LINK"
    Else If (sValueType == REG_MULTI_SZ)
        keytype := "REG_MULTI_SZ"
    Else If (sValueType == REG_RESOURCE_LIST)
        keytype := "REG_RESOURCE_LIST"
    Else If (sValueType == REG_FULL_RESOURCE_DESCRIPTOR)
        keytype := "REG_FULL_RESOURCE_DESCRIPTOR"
    Else If (sValueType == REG_RESOURCE_REQUIREMENTS_LIST)
        keytype := "REG_RESOURCE_REQUIREMENTS_LIST"
    Else If (sValueType == REG_QWORD)
        keytype := "REG_QWORD"
    Else If (sValueType == REG_SB_DELETED)
        keytype := "REG_SB_DELETED"
    Else ; value does not exist or unsupported value type
        keytype := ""

    DllCall("Advapi32.dll\RegCloseKey", "uint", hKey)
    return keytype
}

RegEnumKey(sRootKey, sKeyName, x64mode=true) {
    HKEY_CLASSES_ROOT := 0x80000000 ; http://msdn.microsoft.com/en-us/library/aa393286.aspx
    HKEY_CURRENT_USER := 0x80000001
    HKEY_LOCAL_MACHINE := 0x80000002
    HKEY_USERS := 0x80000003
    HKEY_CURRENT_CONFIG := 0x80000005
    HKEY_DYN_DATA := 0x80000006
    HKCR := HKEY_CLASSES_ROOT
    HKCU := HKEY_CURRENT_USER
    HKLM := HKEY_LOCAL_MACHINE
    HKU := HKEY_USERS
    HKCC := HKEY_CURRENT_CONFIG

    KEY_ENUMERATE_SUB_KEYS := 0x0008
    KEY_WOW64_64KEY := 0x0100
    KEY_WOW64_32KEY := 0x0200

    ERROR_NO_MORE_ITEMS = 259

    myhKey := %sRootKey% ; pick out value (0x8000000x) from list of HKEY_xx vars
    IfEqual,myhKey,, { ; Error - Invalid root key
        ErrorLevel := 3
        return ""
    }

    if (x64mode)
        RegAccessRight := KEY_ENUMERATE_SUB_KEYS + KEY_WOW64_64KEY
    else
        RegAccessRight := KEY_ENUMERATE_SUB_KEYS + KEY_WOW64_32KEY

    DllCall("Advapi32.dll\RegOpenKeyEx", "uint", myhKey, "str", sKeyName, "uint", 0, "uint", RegAccessRight, "uint*", hKey)
    if (hKey == 0) {
        ErrorLevel := 4
        return ""
    }

    lpcName := 512
    VarSetCapacity(lpName, lpcName)
    names =

    dwIndex = 0
    loop
    {
        lpcName := 512
        rc := DllCall("Advapi32.dll\RegEnumKeyEx", "uint", hKey, "uint", dwIndex, "str", lpName, "uint*", lpcName, "uint", 0, "uint", 0, "uint", 0, "uint", 0)
        if (rc == 0) {
            names = %names%%lpName%`n
            dwIndex ++
        } else {
            if (rc == ERROR_NO_MORE_ITEMS)
                ErrorLevel = 0
            else
                ErrorLevel := rc
            Break
        }
    }

    DllCall("Advapi32.dll\RegCloseKey", "uint", hKey)

    StringTrimRight, names, names, 1
    Sort(names, "CL")
    return names
}

RegEnumValue(sRootKey, sKeyName, x64mode=true) {
    HKEY_CLASSES_ROOT := 0x80000000 ; http://msdn.microsoft.com/en-us/library/aa393286.aspx
    HKEY_CURRENT_USER := 0x80000001
    HKEY_LOCAL_MACHINE := 0x80000002
    HKEY_USERS := 0x80000003
    HKEY_CURRENT_CONFIG := 0x80000005
    HKEY_DYN_DATA := 0x80000006
    HKCR := HKEY_CLASSES_ROOT
    HKCU := HKEY_CURRENT_USER
    HKLM := HKEY_LOCAL_MACHINE
    HKU := HKEY_USERS
    HKCC := HKEY_CURRENT_CONFIG

    KEY_QUERY_VALUE := 0x0001 ; http://msdn.microsoft.com/en-us/library/ms724878.aspx
    KEY_WOW64_64KEY := 0x0100
    KEY_WOW64_32KEY := 0x0200

    ERROR_NO_MORE_ITEMS = 259

    myhKey := %sRootKey% ; pick out value (0x8000000x) from list of HKEY_xx vars
    IfEqual,myhKey,, { ; Error - Invalid root key
        ErrorLevel := 3
        return ""
    }

    if (x64mode)
        RegAccessRight := KEY_QUERY_VALUE + KEY_WOW64_64KEY
    else
        RegAccessRight := KEY_QUERY_VALUE + KEY_WOW64_32KEY

    DllCall("Advapi32.dll\RegOpenKeyEx", "uint", myhKey, "str", sKeyName, "uint", 0, "uint", RegAccessRight, "uint*", hKey)
    if (hKey == 0) {
        ErrorLevel := 4
        return ""
    }

    rc := DllCall("Advapi32.dll\RegQueryInfoKey", "uint", hKey, "uint", 0, "uint", 0, "uint", 0, "uint", 0, "uint", 0, "uint", 0, "uint", 0, "uint *", lpcMaxValueNameLen, "uint", 0, "uint", 0, "uint", 0)
    lpcMaxValueNameLen := lpcMaxValueNameLen * 2 + 2
    lpcName := lpcMaxValueNameLen
    VarSetCapacity(lpName, lpcName)
    names =

    dwIndex = 0
    loop
    {
        lpcName := lpcMaxValueNameLen
        rc := DllCall("Advapi32.dll\RegEnumValue", "uint", hKey, "uint", dwIndex, "Wstr", lpName, "uint*", lpcName, "uint", 0, "uint", 0, "uint", 0, "uint", 0)
        if (rc == 0) {
            names = %names%%lpName%`n
            dwIndex ++
        } else {
            if (rc == ERROR_NO_MORE_ITEMS)
                ErrorLevel = 0
            else
                ErrorLevel := rc
            Break
        }
    }

    DllCall("Advapi32.dll\RegCloseKey", "uint", hKey)

    StringTrimRight, names, names, 1
    Sort(names, "CL")
    return names
}

ExtractData(pointer) { ; http://www.autohotkey.com/forum/viewtopic.php?p=91578#91578 SKAN
    Loop {
        errorLevel := ( pointer+(A_Index-1) )
        Asc := *( errorLevel )
        IfEqual, Asc, 0, Break ; Break if NULL Character
        String := String . Chr(Asc)
    }
    Return String
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
    A_nl := "`n"

    if (mode == "dirs" || mode == "files")
        pathcol := 10
    else
        pathcol := 7

    Srows := ""
    RowNumber := 0
    Loop
    {
        RowNumber := MyListView.GetNext(RowNumber)
        if not RowNumber
            break
        Srows .= RowNumber . ","
    }
    Srows := Trim(Srows, ",")
    removedpaths := ""
    Loop, Parse, Srows, "CSV"
    {
        if (mode == "keys")
        {
            item := MyListView.GetText(A_LoopField, pathcol)
            removedpaths .= item . "`n"
        }
        else if (mode == "dirs")
        {
            item := MyListView.GetText(A_LoopField, pathcol)
            removedpaths .= item . "`n"
        }
        else if (mode == "values")
        {
            item := MyListView.GetText(A_LoopField, pathcol)
            val := MyListView.GetText(A_LoopField, 4)
            item .= "\" . val
        }
        else
        {
            item := MyListView.GetText(A_LoopField, pathcol)
            val := MyListView.GetText(A_LoopField, 2)
            item .= "\" . val
        }
        AddIgnoreItem(mode, item)
    }

    Sort(Srows, "N R D,")
    Loop, Parse, Srows, "CSV"
        MyListView.Delete(A_LoopField)

    if (mode == "dirs" || mode == "keys") {
        removedpaths := Trim(removedpaths, A_nl)
        Loop, Parse, removedpaths, "`n"
        {
            p := A_LoopField
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
    }

    Return
}

ReadIgnoredConfig(type)
{
    Global ignoredDirs, ignoredFiles, ignoredKeys, ignoredValues, ignorelist

    if (type == "files")
    {
        ignoredDirs = `n
        Loop, Read, %ignorelist%dirs.cfg
        {
            if (A_LoopReadLine == "")
                Continue
            ignoredDirs = %ignoredDirs%%A_LoopReadLine%`n
        }
        ignoredFiles = `n
        Loop, Read, %ignorelist%files.cfg
        {
            if (A_LoopReadLine == "")
                Continue
            ignoredFiles = %ignoredFiles%%A_LoopReadLine%`n
        }
    }
    else
    {
        ignoredKeys = `n
        Loop, Read, %ignorelist%keys.cfg
        {
            if (A_LoopReadLine == "")
                Continue
            ignoredKeys = %ignoredKeys%%A_LoopReadLine%`n
        }
        ignoredValues = `n
        Loop, Read, %ignorelist%values.cfg
        {
            if (A_LoopReadLine == "")
                Continue
            ignoredValues = %ignoredValues%%A_LoopReadLine%`n
        }
    }
    Return
}

AddIgnoreItem(mode, item)
{
    global newIgnored_dirs, newIgnored_files, newIgnored_keys, newIgnored_values
    data := newIgnored_%mode%
    data = %data%`n%item%
    newIgnored_%mode% = %data%
    Return
}

SaveNewIgnoredItems(mode)
{
    Global ignoredDirs, ignoredFiles, ignoredKeys, ignoredValues, ignorelist
    Global newIgnored_dirs, newIgnored_files, newIgnored_keys, newIgnored_values
    A_nl = `n

    if (mode == "files")
    {
        if (newIgnored_dirs == "" && newIgnored_files == "")
            Return
        pathdata = %ignoredDirs%`n%newIgnored_dirs%
        itemdata = %ignoredFiles%`n%newIgnored_files%
        pathfilename = %ignorelist%dirs.cfg
        itemfilename = %ignorelist%files.cfg
    }
    else
    {
        if (newIgnored_keys == "" && newIgnored_values == "")
            Return
        pathdata = %ignoredKeys%`n%newIgnored_keys%
        itemdata = %ignoredValues%`n%newIgnored_values%
        pathfilename = %ignorelist%keys.cfg
        itemfilename = %ignorelist%values.cfg
    }
    Sort(pathdata, "U")
    Sort(itemdata, "U")

    outpathdata = `n
    loop, parse, pathdata, `n
    {
        if (A_LoopField == "")
            Continue
        sub = %A_LoopField%
        found = 0
        Loop
        {
            SplitPath, sub, , sub
            if (sub = "")
                break
            if (InStr(outpathdata, A_nl . sub . A_nl))
            {
                found = 1
                break
            }
        }
        if (! found)
            outpathdata = %outpathdata%%A_LoopField%`n
    }

    outitemdata = `n
    loop, parse, itemdata, `n
    {
        if (A_LoopField == "")
            Continue
        sub = %A_LoopField%
        found = 0
        Loop
        {
            SplitPath, sub, , sub
            if (sub = "")
                break
            if (InStr(outpathdata, A_nl . sub . A_nl))
            {
                found = 1
                break
            }
        }
        if (! found)
            outitemdata = %outitemdata%%A_LoopField%`n
    }

    FileDelete, %pathfilename%
    FileAppend, %outpathdata%, %pathfilename%

    FileDelete, %itemfilename%
    FileAppend, %outitemdata%, %itemfilename%

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
    box := getBoxFromMenu()
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
        MsgBox("Opening sandboxed folder`n""" . dir . """`n`nPlease wait", title, 64 + 262144)
    } else {
        executeShortcut(box, shortcut)
    }
}

RunUserToolMenuHandler(ItemName, ItemPos, MyMenu) {
    shortcut := menucommands[MyMenu.Name, ItemName]
    executeShortcut("", shortcut)
}

NewShortcutMenuHandler(box := "") {
    static DefaultShortcutFolder
    if (box == "")
        box := getBoxFromMenu()
    if (!InStr(FileExist(DefaultShortcutFolder . "\"), "D"))
        DefaultShortcutFolder := A_Desktop
    file := FileSelect(33, A_ProgramFiles, "Select the file to launch sandboxed in box " . box . " via a shortcut on the desktop", "Executable files (*.exe)")
    if (!file)
        return
    NewShortcut(box, file)
    SplitPath(file, , &DefaultShortcutFolder)
}

RunDialogMenuHandler(*) {
    box := getBoxFromMenu()
    if (GetKeyState("Control", "P"))
        writeSandboxedShortcutFileToDesktop(start, "Sandboxie's Run dialog", "", "/box:" . box . " run_dialog", "Launch Sandboxie's Run Dialog in sandbox " . box, SbieAgentResMain, SbieAgentResMainId, 1, box)
    else
        Run(start . " /box:" . box . " run_dialog")
}

StartMenuMenuHandler(*) {
    box := getBoxFromMenu()
    if (GetKeyState("Control", "P"))
        writeSandboxedShortcutFileToDesktop(start, "Sandboxie's Start Menu", "", "/box:" . box . " start_menu", "Launch Sandboxie's Start Menu in sandbox " . box, SbieAgentResMain, SbieAgentResMainId, 1, box)
    else
        Run(start . " /box:" . box . " start_menu")
}

SCmdMenuHandler(*) {
    box := getBoxFromMenu()
    if (GetKeyState("Control", "P")) {
        args := "/box:" . box . " " . A_ComSpec . " /k ""cd /d " . A_WinDir . "\"""
        writeSandboxedShortcutFileToDesktop(start, "Sandboxed Command Prompt", "", args, "Sandboxed Command Prompt in sandbox " . box, cmdRes, 1, 1, box)
    } else {
        cdpath := InStr(FileExist(expandEnvVars(sbcommandpromptdir)), "D") ? sbcommandpromptdir : A_WinDir
        Run(start . " /box:" . box . " " . A_ComSpec . " /k ""cd /d " . cdpath . """")
    }
}

UCmdMenuHandler(*) {
    box := getBoxFromMenu()
    bpath := sandboxes_array[box].bpath
    if (GetKeyState("Control", "P")) {
        args := "/k ""cd /d """ . bpath . """"""
        writeUnsandboxedShortcutFileToDesktop(A_ComSpec, "Unsandboxed Command Prompt in sandbox " . box, bpath, args, "Unsandboxed Command Prompt in sandbox " . box, cmdRes, 1, 1)
    } else {
        Run(A_ComSpec . " /k ""cd /d """ . bpath . """""")
    }
}

SRegEditMenuHandler(*) {
    box := getBoxFromMenu()
    if (GetKeyState("Control", "P"))
        writeSandboxedShortcutFileToDesktop(start, "Sandboxed Registry Editor", "", "/box:" . box . " " . regeditImg, "Launch RegEdit in sandbox " . box, regeditRes, 1, 1, box)
    else
        Run(start . " /box:" . box . " " . regeditImg)
}

URegEditMenuHandler(*) {
    if (GetKeyState("Control", "P")) {
        MsgBox("Since something must be running in the box to analyse its registry, creating a desktop shortcut to launch the unsandboxed Registry Editor is not supported. Sorry.`n`nNote that creating a shortcut to a sandboxed Registry Editor is supported, but on x64 systems you can launch it only in sandboxes with the Drop Rights restriction disabled.", title, 48)
    } else {
        box := getBoxFromMenu()
        ; ensure that the box is in use, or the hive will not be loaded
        run_pid := InitializeBox(box)
        ; pre-select the right registry key
        bregstr_ := sandboxes_array[box].KeyRootPath
        bregstr_ := StrReplace(StrReplace(SubStr(bregstr_, 16), '`%SANDBOX`%', box), '`%USER`%', username)
        RegWrite("REG_SZ", "HKEY_CURRENT_USER\Software\Microsoft\Windows\CurrentVersion\Applets\Regedit", "LastKey", "HKEY_USERS\" . regstr_)
        ; launch regedit
        RunWait("RegEdit.exe")
        ReleaseBox(run_pid)
    }
}

UninstallMenuHandler(*) {
    box := getBoxFromMenu()
    if (GetKeyState("Control", "P"))
        writeSandboxedShortcutFileToDesktop(start, "Uninstall Programs", "", "/box:" . box . " appwiz.cpl", "Uninstall or installs programs in sandbox " . box, shell32, 22, 1, box)
    else
        RunWait(start . " /box:" . box . " appwiz.cpl")
}

TerminateMenuHandler(*) {
    box := getBoxFromMenu()
    if (GetKeyState("Control", "P"))
        writeUnsandboxedShortcutFileToDesktop(start, "Terminate Programs in sandbox " . box, "", "/box:" . box . " /terminate", "Terminate all programs running in sandbox " . box, shell32, 220, 1)
    else
        RunWait(start . " /box:" . box . " /terminate")
}

DeleteBoxMenuHandler(*) {
    box := getBoxFromMenu()
    if (GetKeyState("Control", "P")) {
        writeUnsandboxedShortcutFileToDesktop(start, "! Delete sandbox " . box . " !", "", "/box:" . box . " delete_sandbox", "Deletes the sandbox " . box, shell32, 132, 1)
        MsgBox("Warning! Unlike when Delete Sandbox is run from the SandboxToys Menu, the desktop shortcut that has been created doesn't ask for confirmation!`n`nUse the shortcut with care!", title, 48)
    } else {
        if (MsgBox("Are you sure you want to delete the sandbox """ . box . """?", title, 289) == "OK") {
            RunWait(start . " /box:" . box . " delete_sandbox")
        }
    }
}

SExploreMenuHandler(*) {
    box := getBoxFromMenu()
    if (GetKeyState("Control", "P"))
        writeSandboxedShortcutFileToDesktop(start, "Explore sandbox " . box . " (Sandboxed)", sbdir, "/box:" . box . " " . explorer, "Launches Explorer sandboxed in sandbox " . box, explorerRes, 1, 1, box)
    else
        Run(start . " /box:" . box . " " . explorer)
}

UExploreMenuHandler(*) {
    box := getBoxFromMenu()
    bpath := sandboxes_array[box].bpath
    if (GetKeyState("Control", "P"))
        writeUnsandboxedShortcutFileToDesktop(explorerImg, "Explore sandbox " . box . " (Unsandboxed)", bpath, explorerArgE . " \ "" . bpath . """", "Launches Explorer unsandboxed in sandbox " . box, explorerRes, 1, 1)
    else
        Run(explorer . "\" . bpath)
}

URExploreMenuHandler(*) {
    box := getBoxFromMenu()
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

ListFilesMenuHandler(*) {
    box := getBoxFromMenu()
    bpath := sandboxes_array[box].bpath
    ListFiles(box, bpath)
}

ListRegMenuHandler(*) {
    box := getBoxFromMenu()
    bpath := sandboxes_array[box].bpath
    ListReg(box, bpath)
}

ListAutostartsMenuHandler(*) {
    box := getBoxFromMenu()
    bpath := sandboxes_array[box].bpath
    ListAutostarts(box, bpath)
}

WatchRegMenuHandler(*) {
    box := getBoxFromMenu()
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

WatchFilesMenuHandler(*) {
    box := getBoxFromMenu()
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

WatchFilesRegMenuHandler(*) {
    box := getBoxFromMenu()
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
