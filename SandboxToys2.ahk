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

SplitPath(A_ScriptName,,,, &nameNoExt)

; Settings
; Note: these values are overwritten if SandboxToys.ini exists in the directrory
; containing the script, in %appdata% or in %appdata%\SandboxToys2\
smalliconsize := 16 ; other icons
largeiconsize := 32 ; sandbox icons
seperatedstartmenus := 0
includeboxnames := 1
trayiconfile := ""
trayiconnumber := 1
sbcommandpromptdir := "%userprofile%"

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

if (!A_IsCompiled and trayiconfile == "") {
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
    title := title . " (" . nameNoExt . ")"

A_nl := "\n"
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
SESSION := RegRead("HKEY_CURRENT_USER\Volatile Environment", "SESSION")
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
sandboxes_path := IniRead(ini, "GlobalSettings", "FileRootPath", "%systemdrive%\Sandbox\`%USER`%\`%SANDBOX`%")
sandboxes_path := expandEnvVars(sandboxes_path)

; Get the array of sandboxes (requires AHK_L)
sandboxes_array := Object()
getSandboxesArray(sandboxes_array,ini)

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
if (! FileExist(regconfig))
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
    global SBMenuSetup
    if (traymode)
    {
        sandboxes_array := Object()
        getSandboxesArray(sandboxes_array,ini)
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
            public_dir := public
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
                Sort topicons, "CL D`n"
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
                Sort topicons, "CL D`n"
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
                Sort topicons, "CL D`n"
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

Return

; ###################################################################################################
; Functions
; ###################################################################################################

; get sandbox names, paths and properties from Sandboxie's INI file
; and from the current state of the sandboxes.
; Arguments:
;  array: an initialized Object
;  ini: filename of Sandboxie's ini file
; Fills the object with the array:
;  Object[0] = number of sandboxes.
;  Object[N,"name"] = sandbox N name.
;  Object["boxname","bpath"] = complete, absolute bpath to the sandbox folder.
;  Object["boxname","exist"] = flag: true if the sandbox is not empty at the time of the check.
;  Object["boxname","DropAdminRights"] = flag: state of the DropAdminRights flag in the INI.
; Returns the number of sandboxes.
getSandboxesArray(ByRef sandboxes_array, ini)
{
    global username
    sandboxes_path_template := IniRead(ini, "GlobalSettings", "FileRootPath", "%systemdrive%\Sandbox\`%USER`%\`%SANDBOX`%")
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
    Sort boxes_str, "CL D,"

    sandboxes_array := Map()
    boxlist := StrSplit(boxes_str, ",")

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
        box_data.UseRamDisk := IniRead(ini, A_LoopField, "UseRamDisk", "n") == "y"

        sandboxes_array[boxname] := box_data
    }
    Return sandboxes_array.Count
}

; Prompts the user for a sandbox name.
; Returns "" if the user selects cancel or discard the menu.
getSandboxName(sandboxes_array, title, include_ask=false)
{
    global __box__, SbieAgentResFull, SbieAgentResFullId, SbieAgentResEmpty, SbieAgentResEmptyId, SbieAgentResMain, SbieAgentResMainId, largeiconsize

    TheMenu := Menu()

    TheMenu.Add(title, DummyMenuHandler)
    TheMenu.Disable(title)
    TheMenu.Add()
    for box, boxdata in sandboxes_array
    {
        if (boxdata.exist) {
            TheMenu.Add(box, getSandboxNameBoxMenuHandler)
            setMenuIcon(TheMenu, box, SbieAgentResFull, SbieAgentResFullId, largeiconsize)
        } else {
            TheMenu.Add(box . " (empty)", getSandboxNameBoxMenuHandler)
            setMenuIcon(TheMenu, box . " (empty)", SbieAgentResEmpty, SbieAgentResEmptyId, largeiconsize)
        }
    }
    if (include_ask)
    {
        TheMenu.Add()
        TheMenu.Add("Ask box at run time", getSandboxNameAskMenuHandler)
        setMenuIcon(TheMenu, "Ask box at run time", SbieAgentResMain, SbieAgentResMainId, largeiconsize)
    }
    TheMenu.Add()
    TheMenu.Add("Cancel", getSandboxNameCancelMenuHandler)
    TheMenu.Show()

    return __box__
}

getSandboxNameBoxMenuHandler(ItemName, ItemPos, MyMenu)
{
    global __box__
    __box__ := RTrim(ItemName, " (empty)")
}

getSandboxNameAskMenuHandler(ItemName, ItemPos, MyMenu)
{
    global __box__
    __box__ := "__ask__"
}

getSandboxNameCancelMenuHandler(ItemName, ItemPos, MyMenu)
{
    global __box__
    __box__ := ""
}

setMenuIcon(menu, item, iconfile, iconindex, largeiconsize)
{
    try
    {
        menu.SetIcon(item, iconfile, iconindex, largeiconsize)
        return 0
    }
    catch
    {
        return 1
    }
}

getFilenames(directory, includeFolders)
{
    files := ""
    mode := ""
    if (includeFolders == 0)
        mode := "FD"
    else if (includeFolders == 1)
        mode := "F"
    else if (includeFolders == 2)
        mode := "D"

    Loop Files, directory . "\*", mode
    {
        ; Excludes the hidden and system files from list
        attributes := A_LoopFileAttrib
        if InStr(Attributes, "H")
            Continue
        if InStr(Attributes, "S")
            Continue
        ; Excludes also the files deleted in the sandbox, but present in the "real world".
        ; They have a "magic" creation date of May 23, 1986, 17:47:02
        creationTime := FileGetTime(A_LoopFileLongPath, "C")
        if (creationTime == "19860523174702")
            Continue
        ; and keep regular directories and files
        if InStr(Attributes, "D")
        {
            SplitPath(A_LoopFileName, &OutDirName)
            files .= OutDirName . ":" . A_LoopFileLongPath . "`n"
        } else {
            SplitPath(A_LoopFileName, , , , &OutNameNoExt)
            files .= OutNameNoExt . ":" . A_LoopFileLongPath . "`n"
        }
    }
    files := SubStr(files, 1, -1)
    if (files)
        Sort(files, "CL D`n Z")
    Return files
}

; Build a menu with the files from a specific directory
buildProgramsMenu1(box, menuname, bpath)
{
    global smalliconsize, menunum, menus, shell32

    if (menunum > 0)
        thismenuName := menuname . "_" . menunum
    else
        thismenuName := menuname

    if !menus.Has(box . "_" . thismenuName)
        menus[box . "_" . thismenuName] := Menu()
    thisMenu := menus[box . "_" . thismenuName]
    thisMenu.Name := box . "_" . thismenuName

    numfiles := 0

    menufiles := getFilenames(bpath, 0)
    if (menufiles) {
        Sort menufiles, "CL D`n Z"
        numfiles := addCmdsToMenu(box, thismenuName, menufiles)
    }

    menudirs := getFilenames(bpath, 2)
    if (menudirs) {
        Sort menudirs, "CL D`n Z"
        for i, entry in StrSplit(menudirs, "`n")
        {
            if (entry == "")
                continue
            idx := InStr(entry, ":")
            label := subStr(entry, 1, idx-1)
            dir := subStr(entry, idx+1)
            menunum++
            submenuName := buildProgramsMenu1(box, menuname, dir)
            if (submenuName != "") {
                thisMenu.Add(label, menus[box . "_" . submenuName])
                setMenuIcon(thisMenu, label, shell32, 4, smalliconsize)
                numfiles++
            }
        }
    }
    if (numfiles)
        return thismenuName
    else
        return ""
}

; Build a menu with the files from two specific directories by merging them together
buildProgramsMenu2(box, menuname, path1, path2)
{
    global smalliconsize, menunum, menus, shell32
    A_Return := "`n"

    if (menunum > 0)
        thismenuName := menuname . "_" . menunum
    else
        thismenuName := menuname

    if !menus.Has(box . "_" . thismenuName)
        menus[box . "_" . thismenuName] := Menu()
    thisMenu := menus[box . "_" . thismenuName]
    thisMenu.Name := box . "_" . thismenuName

    numfiles := 0

    menufiles1 := getFilenames(path1, 0)
    menufiles2 := getFilenames(path2, 0)
    menufiles := menufiles1 . "`n" . menufiles2
    menufiles := Trim(menufiles, A_Return)
    if (menufiles) {
        Sort menufiles, "CL D`n"
        numfiles := addCmdsToMenu(box, thismenuName, menufiles)
    }

    menudirs1 := getFilenames(path1, 2)
    menudirs2 := getFilenames(path2, 2)
    menudirs := menudirs1 . "`n" . menudirs2
    menudirs := Trim(menudirs, A_Return)
    if (menudirs) {
        Sort menudirs, "CL D`n"

        dirList := []
        for i, entry in StrSplit(menudirs, "`n") {
            if (entry == "")
                continue
            idx := InStr(entry, ":")
            label := subStr(entry, 1, idx-1)
            dir := subStr(entry, idx+1)
            dirList.Push({label: label, path: dir})
        }

        i := 1
        while i <= dirList.Length
        {
            menunum++
            label := dirList[i].label
            dir1 := dirList[i].path

            if (i < dirList.Length && dirList[i+1].label == label)
            {
                dir2 := dirList[i+1].path
                newmenuname := buildProgramsMenu2(box, menuname, dir1, dir2)
                i++ ; Increment to skip next item
            }
            else
                newmenuname := buildProgramsMenu1(box, menuname, dir1)

            if (newmenuname) {
                thisMenu.Add(label, menus[box . "_" . newmenuname])
                setMenuIcon(thisMenu, label, shell32, 4, smalliconsize)
                numfiles++
            }
            i++
        }
    }
    if (numfiles)
        return thismenuName
    else
        return ""
}

; TODO: rewrite this stuff, too complicated
setIconFromSandboxedShortcut(box, shortcut, menu, label, iconsize)
{
    global menuicons, imageres, username, A_WinDir, programw6432, shell32
    A_Quotes := """"

    global sandboxes_array
    bregstr_ := sandboxes_array[box,"KeyRootPath"]
    bregstr_ := StrReplace(StrReplace(SubStr(bregstr_, 16), '`%SANDBOX`%', box), '`%USER`%', username)

    if !menuicons.Has(menu.Name)
        menuicons[menu.Name] := Map()
    if !menuicons[menu.Name].Has(label)
        menuicons[menu.Name][label] := Map()
    menuicons[menu.Name][label]["file"] := ""
    menuicons[menu.Name][label]["num"] := ""

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
        setMenuIcon(menu, label, imageres, 4, iconsize)
        menuicons[menu.Name][label]["file"] := imageres
        menuicons[menu.Name][label]["num"] := 4
        return imageres . "," . 4
    }

    boxfile := stdPathToBoxPath(box, iconfile)
    if (InStr(FileExist(boxfile), "D")) {
        setMenuIcon(menu, label, imageres, 4, iconsize)
        menuicons[menu.Name][label]["file"] := imageres
        menuicons[menu.Name][label]["num"] := 4
        return imageres . "," . 4
    }
    if (FileExist(boxfile)) {
        iconfile := boxfile
    }

    if (iconfile == "")
        rc := 1
    else {
        rc := setMenuIcon(menu, label, iconfile, iconnum, iconsize)
        menuicons[menu.Name][label]["file"] := iconfile
        menuicons[menu.Name][label]["num"] := iconnum
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
        defaulticon := RegRead("HKEY_USERS\" . bregstr_ . "\machine\software\classes\." . extension . "\DefaultIcon")
        if (defaulticon == "") {
            keyval := RegRead("HKEY_USERS\" . bregstr_ . "\machine\software\classes\." . extension)
            if (keyval != "") {
                defaulticon := RegRead("HKEY_USERS\" . bregstr_ . "\machine\software\classes\" . keyval . "\DefaultIcon")
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
                rc := setMenuIcon(menu, label, iconfile, iconnum, iconsize)
                menuicons[menu.Name][label]["file"] := iconfile
                menuicons[menu.Name][label]["num"] := iconnum
            } else
                rc := 1
            if (rc == 0)
                return iconfile . "," . iconnum
        }

        ; searches also in the unsandboxed registry
        defaulticon := RegRead("HKEY_CLASSES_ROOT\." . extension . "\DefaultIcon")
        if (defaulticon == "") {
            keyval := RegRead("HKEY_CLASSES_ROOT\." . extension)
            if (keyval == "InternetShortcut") {
                defaulticon := A_WinDir . "\system32\url.dll,5"
            } else if (keyval != "") {
                defaulticon := RegRead("HKEY_CLASSES_ROOT\" . keyval . "\DefaultIcon")
            }
        }
        if (defaulticon == "") {
            percievedtype := RegRead("HKEY_CLASSES_ROOT\." . extension, "PerceivedType")
            if (percievedtype == "") {
                keyval := RegRead("HKEY_CLASSES_ROOT\." . extension)
                if (keyval != "") {
                    percievedtype := RegRead("HKEY_CLASSES_ROOT\" . keyval, "PerceivedType")
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
            rc := setMenuIcon(menu, label, iconfile, iconnum, iconsize)
            menuicons[menu.Name][label]["file"] := iconfile
            menuicons[menu.Name][label]["num"] := iconnum
        } else
            rc := 1
        if (rc) {
            if (InStr(defaulticon, "%programfiles%")) {
                iconfile := StrReplace(iconfile, '`%programfiles`%', programw6432)
                rc := setMenuIcon(menu, label, iconfile, iconnum, iconsize)
                menuicons[menu.Name][label]["file"] := iconfile
                menuicons[menu.Name][label]["num"] := iconnum
            }
            if (rc) {
                iconfile := StrReplace(iconfile, '`%programfiles`%', '`%programfiles(x86)`%')
                rc := setMenuIcon(menu, label, iconfile, iconnum, iconsize)
                menuicons[menu.Name][label]["file"] := iconfile
                menuicons[menu.Name][label]["num"] := iconnum
            }
            if (rc) {
                iconfile := expandEnvVars(iconfile)
                rc := setMenuIcon(menu, label, iconfile, iconnum, iconsize)
                menuicons[menu.Name][label]["file"] := iconfile
                menuicons[menu.Name][label]["num"] := iconnum
            }
        }
        if (rc || iconfile == "") {
            iconfile := shell32
            iconfile := expandEnvVars(iconfile)
            if (extension == "exe")
                iconnum := 3
            else
                iconnum := 2
            rc := setMenuIcon(menu, label, iconfile, iconnum, iconsize)
            menuicons[menu.Name][label]["file"] := iconfile
            menuicons[menu.Name][label]["num"] := iconnum
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
    loaded := !hmod
        && hmod := DllCall("LoadLibraryEx", "str", Filename, "uint", 0, "uint", 0x2)

    enumproc := CallbackCreate(IndexOfIconResource_EnumIconResources)
    param := Buffer(12, 0)
    NumPut("int", ID, param, 0)
    ; Enumerate the icon group resources. (RT_GROUP_ICON=14)
    DllCall("EnumResourceNames", "ptr", hmod, "uint", 14, "ptr", enumproc, "ptr", param.Ptr)
    CallbackFree(enumproc)

    ; If we loaded the DLL, free it now.
    if loaded
        DllCall("FreeLibrary", "uint", hmod)

    return NumGet(param, 8, "int") ? NumGet(param, 4, "int") : 0
}

IndexOfIconResource_EnumIconResources(hModule, lpszType, lpszName, lParam)
{
    NumPut("int", NumGet(lParam+4, "int")+1, lParam, 4)

    if (lpszName == NumGet(lParam, 0, "int"))
    {
        NumPut("int", 1, lParam, 8)
        return 0 ; break
    }
    return 1
}

GetAssociatedIcon(File, hideshortcutoverlay = true, iconsize = 16, box = "", deleted = 0)
{
    static
    sfi_size:=352
    local hIcon, Ext, Fileto, FileIcon, FileIconNum, old, programsx86
    programsx86 := EnvGet("ProgramFiles(x86)")
    if !IsSet(sfi)
        sfi := Buffer(sfi_size)

    SplitPath(File, , , &Ext)
    if (ext = "LNK")
    {
        FileGetShortcut(File, &Fileto, , , , &FileIcon, &FileIconNum)
        if (hideshortcutoverlay) {
            if (FileIcon) {
                hIcon := MI_ExtractIcon(FileIcon,FileIconNum,iconsize)
                if (hIcon)
                    return hIcon
            } else {
                File := Fileto
                SplitPath(File, , , &Ext)
            }
        } else {
            if (!FileExist(FileTo))
            {
                tmpboxfile := stdPathToBoxPath(box,FileTo)
                if (FileExist(tmpboxfile))
                    FileTo := tmpboxfile
            }
            if (!FileExist(FileTo))
                FileTo := StrReplace(FileTo, programsx86, ProgramW6432)
            attrs := 0x8101
            if (deleted)
                attrs := attrs + 0x10000
            if (DllCall("Shell32\SHGetFileInfoA", "astr", FileTo, "uint", 0, "ptr", sfi.Ptr, "uint", sfi_size, "uint", attrs))
            {
                hIcon := NumGet(sfi, 0, "UInt")
                return hIcon
            }
        }
    }

    if (!FileExist(File))
        File := StrReplace(File, Programx86, ProgramW6432)

    ; TODO: verify coherence of variable name, or use Object()
    if (StrLen(ext) <= 4)
        old := "hIcon_" . ext . "_" . hideshortcutoverlay . "_" . iconsize
    else
        old := ""
    if (old == "")
    {
        attrs := 0x101
        if (deleted)
            attrs := attrs + 0x10000
        if (DllCall("Shell32\SHGetFileInfoA", "astr", File, "uint", 0, "ptr", sfi.Ptr, "uint", sfi_size, "uint", attrs))
        {
            hIcon := NumGet(sfi, 0, "UInt")
        }
        ; TODO: verify coherence of variable name, or use Object()
        if (ext = "EXE" or ext = "ICO" or ext = "ANI" or ext = "CUR")
        {
        }
        else
        {
            if (StrLen(ext) <= 4)
                hicon := "hIcon_" . ext . "_" . hideshortcutoverlay . "_" . iconsize
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
addCmdsToMenu(box, menuname, fileslist)
{
    global menucommands, smalliconsize, menus

    thismenuName := box . "_" . menuname
    if !menus.Has(thismenuName)
        menus[thismenuName] := Menu()
    thismenu := menus[thismenuName]
    thismenu.Name := thismenuName

    if !menucommands.Has(thismenuName)
        menucommands[thismenuName] := Map()

    numentries := 0
    for i, entry in StrSplit(fileslist, "`n")
    {
        if (entry == "")
            continue
        idx := InStr(entry, ":")
        label := subStr(entry, 1, idx-1)
        if (menucommands[thismenuName].Has(label))
            label := label . " (2)"
        exefile := subStr(entry, idx+1)
        thismenu.Add(label, RunProgramMenuHandler)
        setIconFromSandboxedShortcut(box, exefile, thismenu, label, smalliconsize)
        numentries++
        menucommands[thismenuName][label] := exefile
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
                    Result := MsgBox(294, title, "File """ . dest . """ already exists on your desktop!`n`nClick Continue to overwrite it.")
                    if (Result == "Continue")
                        break
                    if (Result == "Cancel")
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
            name := "[#ask box] " . name
        else
            name := "[#" . box . "] " . name
    }
    else
        name := "[#] " . name
    linkFile := A_Desktop . "\" . name . ".lnk"

    ; safety check
    loop
    {
        if (FileExist(linkFile))
        {
            Result := MsgBox(294, title, 'Shortcut "' . name . '" already exists on your desktop!`n`nClick Continue to overwrite it.')
            if (Result == "Continue")
                break
            if (Result == "Cancel")
                Return
        } else
            break
    }
    ; create the shortcut
    FileCreateShortcut(Target, linkFile, Dir, Args, Description, IconFile, "", IconNum, RunState)
    Return
}

; write a normal (unsandboxed) shortcut.
writeUnsandboxedShortcutFileToDesktop(target,name,dir,args,description,iconFile,iconNum,runState)
{
    global title

    linkFile := A_Desktop . "\" . name . ".lnk"

    ; safety check
    loop
    {
        if (FileExist(linkFile))
        {
            Result := MsgBox(294, title, 'Shortcut "' . name . '" already exists on your desktop!`n`nClick Continue to overwrite it.')
            if (Result == "Continue")
                break
            if (Result == "Cancel")
                Return
        } else
            break
    }
    ; create the shortcut
    FileCreateShortcut(Target, linkFile, Dir, Args, Description, IconFile, "", IconNum, RunState)
    Return
}

; return the box name of the last selected menu item
getBoxFromMenuObj(menuObj)
{
    Return SubStr(menuObj.Name, 1, InStr(menuObj.Name, "_ST2") - 1)
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
    bregstr_ := sandboxes_array[box,"KeyRootPath"]
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
    global title, MyListView, LVLastSize
    global newIgnored_dirs, newIgnored_files, sandboxes_array

    static MainLabel

    allfiles := ""

    ReadIgnoredConfig("files")
    newIgnored_dirs := ""
    newIgnored_files := ""

    Progress("R0-100", "Please wait..., Searching for files`nin box """ . box . """.", title)
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
    Sort, allfiles, CL P3
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
    MyGui.SetMenu(LVMenuBar)

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

    MyListView := MyGui.Add("ListView", "x10 y30 " . LVLastSize . " Checked Count" . numrows . " AltSubmit", ["Status", "File", "bpath", "Size", "Attribs", "Created", "Modified", "Accessed", "Extension", "Sandbox bpath"])
    MyListView.OnEvent("DoubleClick", GuiLVFileMouseEventHandler)
    MyListView.OnEvent("RightClick", GuiLVFileMouseEventHandler)

    ; icons array
    ImageListID1 := IL_Create(10)
    LV_SetImageList(ImageListID1)

    Progress, 20, Please wait..., Building list of files`nin box "%box%"., %title%

    ; add entries in listview
    nummodified := 0
    numadded := 0
    numdeleted := 0
    sep := A_Tab
    MyListView.SetRedraw(false)
    allfiles_arr := StrSplit(allfiles, "`n")
    for i, entry in allfiles_arr
    {
        prog := round(80 * i / allfiles_arr.Length) + 20
        Progress(prog)

        entry_parts := StrSplit(entry, sep)
        St := entry_parts[1]
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
        SplitPath(entry_parts[2], &OutFileName, &OutDir, &OutExtension)
        Attribs := entry_parts[3]
        Size := entry_parts[4]
        Created := entry_parts[5]
        Modified := entry_parts[6]
        Accessed := entry_parts[7]
        BoxPath := entry_parts[8]

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

    msg := "Found " . numfiles . " file" . (numfiles!=1 ? "s" : "")
    msg .= " in the sandbox """ . box . """"
    msg .= " : # " . nummodified . " modified file" . (nummodified!=1 ? "s" : "")
    msg .= ", + " . numadded . " new file" . (numadded!=1 ? "s" : "")
    msg .= ", - " . numdeleted . " deleted file" . (numdeleted!=1 ? "s" : "")
    msg .= ". Double-click an entry to copy the file to the desktop."
    MainLabel.Text := msg

    Progress(0)
    MyGui.Show(, "Files in box """ . box . """")
    MyListView.SetRedraw(true)

    MyGui.OnEvent("Close", (*) => SaveNewIgnoredItems("files"))
    MyGui.OnEvent("Size", GuiSize)
}

GuiSize(GuiObj, EventInfo, Width, Height)
{
    if EventInfo = 1 ; The window has been minimized.  No action needed.
        return
    LVLastSize := "W" . (Width - 20) . " H" . (Height - 40)
    MyListView.Move(,, Width - 20, Height - 40)
}

GuiLVFileMouseEventHandler(ctl, info)
{
    if (info == "DoubleClick") {
        GuiLVCurrentFileSaveTo(ctl.FocusedRow)
    }
    if (info == "RightClick") {
        PopupMenu.Show()
    }
}

; Copy To...
GuiLVCurrentFileSaveTo(row)
{
    global sandboxes_array, box, DefaultFolder
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
    global start, title
    LVFileName := MyListView.GetText(row, 2)
    LVPath := MyListView.GetText(row, 10)
    Filename := boxpath . "\" . LVPath . "\" . LVFileName
    old_pwd := A_WorkingDir
    SetWorkingDir(boxpath . "\" . LVPath)
    Run('"' . start . '" /box:' . box . ' "' . Filename . '"',, "UseErrorLevel")
    MsgBox(64, title, "Running """ . FileName . """ in box " . box . ".`n`nPlease wait...", 3)
    SetWorkingDir(old_pwd)
}
; Open Unsandboxed Container
GuiLVCurrentFileOpenContainerU(row)
{
    global sandboxes_array, box
    GuiLVCurrentFileOpenContainer(row, box, sandboxes_array[box].bpath, "u")
}
; Open Sandboxed Container
GuiLVCurrentFileOpenContainerS(row)
{
    global sandboxes_array, box
    GuiLVCurrentFileOpenContainer(row, box, sandboxes_array[box].bpath, "s")
}
GuiLVCurrentFileOpenContainer(row, box, boxpath, mode)
{
    global start, title
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
        Run('"' . start . '" /box:' . box . ' "' . Curpath . '"',, "UseErrorLevel")
        MsgBox(64, title, "Opening container of """ . LVBoxFile . """ in box " . box . ".`n`nPlease wait...", 3)
    }
}

; Add Shortcut in Sandbox Start Menu
GuiLVCurrentFileToStartMenu(row)
{
    global sandboxes_array, box
    GuiLVCurrentFileToStartMenuOrDesktop(row, box, sandboxes_array[box].bpath, "startmenu")
}
; Add Shortcut in Sandbox Desktop
GuiLVCurrentFileToDesktop(row)
{
    global sandboxes_array, box
    GuiLVCurrentFileToStartMenuOrDesktop(row, box, sandboxes_array[box].bpath, "desktop")
}
GuiLVCurrentFileToStartMenuOrDesktop(row, box, boxpath, where)
{
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
    FileCreateShortcut(Target, ShortcutFile, LVPath, "", "Run """ . LVFileName . """`nShortcut created by SandboxToys2")
}

; Create Sandboxed Shortcut...
GuiLVCurrentFileShortcut(row)
{
    global sandboxes_array, box
    _GuiLVCurrentFileShortcut(row, box, sandboxes_array[box].bpath)
}
_GuiLVCurrentFileShortcut(row, box, boxpath)
{
    global start
    LVFileName := MyListView.GetText(row, 2)
    LVPath := MyListView.GetText(row, 3)
    LVBoxPath := MyListView.GetText(row, 10)
    file := LVPath . "\" . LVFileName

    runstate := 1
    splitPath(file, , &dir, &extension, &label)
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
        TempMenu := Menu()
        TempMenu.Add("__TEMP__", DummyMenuHandler)
        icon := setIconFromSandboxedShortcut(box, file, TempMenu, "__TEMP__", 32)
        idx := InStr(icon, ",",, 0)
        iconfile := SubStr(icon, 1, idx-1)
        iconnum := SubStr(icon, idx+1)
        if (iconnum < 0)
            iconnum := IndexOfIconResource(iconfile, iconnum)
    }
    tip := "Launch """ . label . """ in sandbox " . box
    writeSandboxedShortcutFileToDesktop(start, label, boxpath . "\" . LVBoxPath, "/box:" . box . " " . A_Quotes . file . A_Quotes, tip, iconfile, iconnum, 1, box)
}

; Toggle Checkmark
GuiLVToggleCurrent(row)
{
    if (MyListView.IsChecked(row))
        MyListView.Modify(row, "-Check")
    else
        MyListView.Modify(row, "Check")
}

; Hide from this list
GuiLVHideCurrent(row)
{
    MyListView.Delete(row)
}

; Add File to Ignore List
GuiLVIgnoreCurrentFile(row)
{
    LVIgnoreEntry(row, "files")
}
; Add Folder to Ignore List
GuiLVIgnoreCurrentDir(row)
{
    LVIgnoreEntry(row, "dirs")
}
; Add Reg Value to Ignore List
GuiLVIgnoreCurrentValue(row)
{
    LVIgnoreEntry(row, "values")
}
; Add Reg Key to Ignore List
GuiLVIgnoreCurrentKey(row)
{
    LVIgnoreEntry(row, "keys")
}
LVIgnoreEntry(row, mode)
{
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
        item := item . "\" . val
    }
    else
    {
        item := MyListView.GetText(row, pathcol)
        val := MyListView.GetText(row, 2)
        item := item . "\" . val
    }
    AddIgnoreItem(mode, item)
    MyListView.Delete(row)

    if (mode == "dirs" || mode == "keys") {
        p := item
        loop MyListView.GetCount()
        {
            i := MyListView.GetCount() - A_Index + 1
            item := MyListView.GetText(i, pathcol)
            if (InStr(item, p, 1) == 1)
                MyListView.Delete(i)
        }
    }
}

; Add Sub-Folder to Ignore List...
GuiLVIgnoreCurrentSubDir(row)
{
    MyGui.Opt("+OwnDialogs")
    LVIgnoreSpecific(row, "dirs")
}
; Add Reg Sub-Key to Ignore List...
GuiLVIgnoreCurrentSubKey(row)
{
    MyGui.Opt("+OwnDialogs")
    LVIgnoreSpecific(row, "keys")
}

GuiLVRegMouseEventHandler(ctl, info)
{
    if (info == "DoubleClick") {
        GuiLVCurrentOpenRegEdit(ctl.FocusedRow)
    }
    if (info == "RightClick") {
        PopupMenu.Show()
    }
}

GuiLVCurrentCopyToClipboard(row)
{
    clipboard := MyListView.GetText(row, 2)
}

GuiLVCurrentOpenRegEdit(row)
{
    global box
    _GuiLVCurrentOpenRegEdit(row, box)
}
_GuiLVCurrentOpenRegEdit(row, box)
{
    global bregstr_
    run_pid := InitializeBox(box)
    ; pre-select the right registry key
    LVRegPath := MyListView.GetText(row, 7)
    key := "HKEY_USERS\" . bregstr_ . "\" . LVRegPath
    RegWrite(key, "LastKey", "HKEY_CURRENT_USER\Software\Microsoft\Windows\CurrentVersion\Applets\Regedit", "REG_SZ")
    ; launch regedit
    RunWait("RegEdit.exe",, "UseErrorLevel")
    ReleaseBox(run_pid)
}

GuiLVAutostartMouseEventHandler(ctl, info)
{
    global box
    MyGui.Opt("+OwnDialogs")
    if (info == "DoubleClick") {
        GuiLVRegistryRun(ctl.FocusedRow, box)
    }
    if (info == "RightClick") {
        PopupMenu.Show()
    }
}

GuiLVRegistryRun(row, box)
{
    global title, start
    A_Quotes := """"
    MyGui.Opt("+OwnDialogs")
    LVRegName := MyListView.GetText(row, 2)
    LVCommand := MyListView.GetText(row, 3)
    if (LVCommand == "")
        MsgBox(48, title, "Can't run """ . LVRegName . """ in box " . box . ".`n`nNo command line.", 3)
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
        MsgBox(64, title, "Running """ . LVRegName . """ in box " . box . ".`n`nPlease wait...", 3)
    }
}

GuiLVRegistryToStartMenuStartup()
{
    global box, sandboxes_array
    _GuiLVRegistryToStartMenuStartup(box, sandboxes_array[box].bpath)
}
_GuiLVRegistryToStartMenuStartup(box, boxpath)
{
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
        _GuiLVRegistryItemToStartMenuStartup(row, box, boxpath)
    }
}

GuiLVRegistryItemToStartMenuStartup(row)
{
    global box, sandboxes_array
    _GuiLVRegistryItemToStartMenuStartup(row, box, sandboxes_array[box].bpath)
}
_GuiLVRegistryItemToStartMenuStartup(row, box, boxpath)
{
    global title
    A_Quotes := """"

    LVProgram := MyListView.GetText(row, 2)
    LVCommand := MyListView.GetText(row, 3)
    LVLocation := MyListView.GetText(row, 4)
    if (LVCommand == "")
    {
        MsgBox(48, title, "Can't create shortcut to """ . LVProgram . """.`n`nNo command line.", 3)
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
        FileCreateShortcut(Filename, ShortcutFile, "", "", "Run """ . LVProgram . """`n(Was in " . LVLocation . ")`nShortcut created by SandboxToys2")
    else
        FileCreateShortcut(Filename, ShortcutFile, "", Args, "Run """ . LVProgram . """`n(Was in " . LVLocation . ")`nShortcut created by SandboxToys2")
}

GuiLVRegistryExploreStartMenuCS()
{
    global box, sandboxes_array
    GuiLVRegistryExploreStartMenu(box, sandboxes_array[box].bpath, "current", "sandboxed")
}
GuiLVRegistryExploreStartMenuCU()
{
    global box, sandboxes_array
    GuiLVRegistryExploreStartMenu(box, sandboxes_array[box].bpath, "current", "unsandboxed")
}
GuiLVRegistryExploreStartMenuAS()
{
    global box, sandboxes_array
    GuiLVRegistryExploreStartMenu(box, sandboxes_array[box].bpath, "all", "sandboxed")
}
GuiLVRegistryExploreStartMenuAU()
{
    global box, sandboxes_array
    GuiLVRegistryExploreStartMenu(box, sandboxes_array[box].bpath, "all", "unsandboxed")
}
GuiLVRegistryExploreStartMenu(box, boxpath, user, mode)
{
    global title, start
    if (mode == "unsandboxed") {
        if (user == "current") {
            bpath := boxpath . "\user\current\AppData\Roaming\Microsoft\Windows\Start Menu\Programs\Startup"
            mowner := "Current User's"
        } else {
            bpath := boxpath . "\user\all\Microsoft\Windows\Start Menu\Programs\Startup"
            mowner := "All Users"
        }
        if (DirExist(bpath)) {
            Run(bpath)
        } else {
            MsgBox(48, title, "The " . mowner . " Start Menu of box " . box . " has not been created yet.`n`nCan't explore it unsandboxed.")
        }
    }
    else
    {
        if (user == "current")
            bpath := A_StartMenu . "\Programs\Startup"
        else
            bpath := A_StartMenuCommon . "\Programs\Startup"
        Run('"' . start . '" /box:' . box . ' "' . bpath . '"')
    }
}

GuiLVToggleAllCheckmarks()
{
    Checkedrows := []
    RowNumber := 0
    Loop
    {
        RowNumber := MyListView.GetNext(RowNumber, "Checked")
        if not RowNumber
            break
        Checkedrows.Push(RowNumber)
    }
    MyListView.Modify(0, "Check")
    for i, row in Checkedrows
        MyListView.Modify(row, "-Check")
}

GuiLVHideSelected()
{
    Srows := []
    RowNumber := 0
    Loop
    {
        RowNumber := MyListView.GetNext(RowNumber, "Focused")
        if not RowNumber
            break
        Srows.Push(RowNumber)
    }
    Srows.Sort("R")
    for i, row in Srows
        MyListView.Delete(row)
}

GuiLVIgnoreSelectedValues()
{
    LVIgnoreSelected("values")
}

GuiLVIgnoreSelectedKeys()
{
    LVIgnoreSelected("keys")
}

GuiLVIgnoreSelectedFiles()
{
    LVIgnoreSelected("files")
}

GuiLVIgnoreSelectedDirs()
{
    LVIgnoreSelected("dirs")
}

GuiLVClearAllCheckmarks()
{
    MyListView.Modify(0, "-Check")
}

GuiLVToggleSelected()
{
    row := 0
    Loop
    {
        row := MyListView.GetNext(row, "Focused")
        if not row
            break
        if (MyListView.IsChecked(row))
            MyListView.Modify(row, "-Check")
        else
            MyListView.Modify(row, "Check")
    }
}

GuiLVFilesSaveAsText()
{
    global box
    GuiLVSaveAsCSVText(box, "Files in sandbox " . box . ".txt")
}
GuiLVRegistrySaveAsText()
{
    global box
    GuiLVSaveAsCSVText(box, "Registry of sandbox " . box . ".txt")
}
GuiLVSaveAsCSVText(box, defaultfilename)
{
    global DefaultFolder, title
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

    Progress("R0-100", "Please wait..., Saving list of " . numfiles . " files...", title)
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
        loop (numcols -1)
        {
            colnum := A_Index + 1
            colitem := MyListView.GetText(row, colnum)
            line .= A_Quotes . colitem . A_Quotes . ","
        }
        line := Trim(line, ",")
        FileAppend(line . "`n", filename)
        filenum++
    }
    sleep(10)
    Progress(0)
}

GuiLVFilesToStartMenu()
{
    global box, sandboxes_array
    _GuiLVFilesToStartMenuOrDesktop(box, sandboxes_array[box].bpath, "startmenu")
}
GuiLVFilesToDesktop()
{
    global box, sandboxes_array
    _GuiLVFilesToStartMenuOrDesktop(box, sandboxes_array[box].bpath, "desktop")
}
_GuiLVFilesToStartMenuOrDesktop(box, boxpath, where)
{
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
}

GuiLVFilesShortcut()
{
    global box, sandboxes_array
    _GuiLVFilesShortcut(box, sandboxes_array[box].bpath)
}
_GuiLVFilesShortcut(box, boxpath)
{
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
        _GuiLVCurrentFileShortcut(row, box, boxpath)
    }
}

GuiLVFilesSaveTo()
{
    global box, sandboxes_array
    LVFilesSaveTo(sandboxes_array[box].bpath)
}
LVFilesSaveTo(boxpath)
{
    static DefaultFolder
    numfiles := numOfCheckedFiles()
    if (numfiles == 0)
    {
        SoundBeep()
        Return
    }
    MyGui.Opt("+OwnDialogs")
    if (Not Instr(FileExist(DefaultFolder),"D"))
        DefaultFolder := ""
    if DefaultFolder == ""
        DefaultFolder := A_Desktop
    DefaultFolder := expandEnvVars(DefaultFolder)
    dirname := DirSelect("*" . DefaultFolder, 1, "Copy checkmarked files from sandbox to folder...`n`n********** WARNING: Existing files will be OVERWRITTEN **********")
    if (dirname == "")
        Return
    DefaultFolder := dirname
    Progress("R0-100", "Please wait..., Saving " . numfiles . " files...", title)
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
            Progress(0)
            Result := MsgBox("Warning: Some files exist already in the destination folder.`nOverwrite them?", title, "YesNoCancel")
            Progress(round(100 * (filenum / numfiles)))
            if (Result == "Cancel")
            {
                Progress(0)
                Return
            }
            if (Result == "Yes")
                Overwrite := 1
            else
                Overwrite := 0
        }
        if (!exist || Overwrite == 1)
            FileCopy(boxpath . "\" . LVSBFilePath . "\" . LVFileName, outfile, 1)
        filenum++
    }
    sleep(10)
    Progress(0)
}

GuiLVRegistrySaveAsReg()
{
    global box
    _GuiLVRegistrySaveAsReg(box)
}
_GuiLVRegistrySaveAsReg(box)
{
    global title, sandboxes_array, username
    static DefaultFolder
    A_Quotes := """"

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

    run_pid := InitializeBox(box)

    row := 0
    lastrealkeypath := ""
    failed := ""
    out := "REGEDIT4`n"
    Loop
    {
        line := ""
        row := MyListView.GetNext(row, "Checked")
        if not row
            break
        Status := MyListView.GetText(row, 1)
        status := SubStr(Status, 1, 1)
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
                line := "`n[-" . realkeypath . "]`n"
            else
                line := "`n[" . realkeypath . "]`n"
            lastrealkeypath := realkeypath
        }
        if (keytype == "-DELETED_VALUE")
            line .= outvaluename . "=-`n"
        if (keytype != "-DELETED_KEY" && keytype != "-DELETED_VALUE")
        {
            keyvalueval := RegRead("HKEY_USERS\" . boxkeypath, valuename)
            if (ErrorLevel)
            {
                keyvalueval := RegRead64("HKEY_USERS", boxkeypath, valuename, false, 65536)
                if (ErrorLevel)
                    failed .= "[" . boxkeypath . "] " . outvaluename . " (" . keytype . ")`n"
            }
            if (!ErrorLevel)
            {
                if (keytype == "REG_SZ")
                {
                    keyvalueval := StrReplace(keyvalueval, "\", "\\")
                    keyvalueval := StrReplace(keyvalueval, A_Quotes, '\"')
                    line .= outvaluename . '="' . keyvalueval . '"`n'
                }
                else if (keytype == "REG_EXPAND_SZ")
                {
                    hexstr := str2hexstr(keyvalueval)
                    wrapped := WrapRegString(outvaluename . "=hex(2):" . hexstr)
                    line .= wrapped . "`n"
                }
                else if (keytype == "REG_BINARY")
                {
                    hexstr := hexstr2hexstrcomas(keyvalueval)
                    wrapped := WrapRegString(outvaluename . "=hex:" . hexstr)
                    line .= wrapped . "`n"
                }
                else if (keytype == "REG_DWORD")
                {
                    hex := dec2hex(keyvalueval,8)
                    line .= outvaluename . "=dword:" . hex . "`n"
                }
                else if (keytype == "REG_QWORD")
                {
                    hex := qword2hex(keyvalueval)
                    line .= outvaluename . "=hex(b):" . hex . "`n"
                }
                else if (keytype == "REG_MULTI_SZ")
                {
                    hexstr := str2hexstr(keyvalueval, true)
                    wrapped := WrapRegString(outvaluename . "=hex(7):" . hexstr)
                    line .= wrapped . "`n"
                }
                else
                {
                    failed .= "[" . boxkeypath . "] " . outvaluename . " (" . keytype . ")`n"
                }
            }
        }
        out .= line
    }

    FileAppend(out, filename)
    if (failed != "") {
        MsgBox(48, title, "Warning! Some key values cannot be saved due to unsupported key type:`n`n" . failed)
    }

    ReleaseBox(run_pid)
}

GuiClose()
{
    MyGui.Destroy()
}

WrapRegString(str)
{
    if (strLen(str) <= 80)
        return str

    A_Quotes := """"
    idx := InStr(str, A_Quotes . "=")
    if (idx < 76)
        idx := 76
    idx := InStr(str, ",",, idx)
    if (idx == 0)
        return str

    out := SubStr(str, 1, idx)
    out .= "\`n"
    str := subStr(str, idx+1)
    loop
    {
        if (StrLen(str) < 78)
        {
            out .= " " . str
            break
        }
        idx := InStr(str, ",",, 75)
        sub := subStr(str, 1, idx)
        out .= " " . sub . "\`n"
        str := subStr(str, idx+1)
    }
    return out
}

numOfCheckedFiles()
{
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
    outtxt := ""
    insubkeylen := StrLen(insubkey)+1
    outfullkey := outrootkey
    if (outsubkey != "")
        outfullkey .= "\" . outsubkey

    Loop Reg, inrootkey . "\" . insubkey, "KV", 1
    {
        subkey := outfullkey . SubStr(A_LoopRegSubKey, insubkeylen)
        if (A_LoopRegType != "KEY")
            value := RegRead(A_LoopRegKey . "\" . A_LoopRegSubKey, A_LoopRegName)
        else
            value := ""
        outtxt .= A_LoopRegTimeModified . " " . A_LoopRegType . " " . A_LoopRegName . " " . subkey . " " . value . "`n"
    }
    return outtxt
}

FormatRegConfigKey(RegSubKey, subkey, RegType, RegName, RegTimeModified, separator, includedate=false)
{
    type := RegType
    if (type == "")
        type := RegRead64KeyType("HKEY_USERS", RegSubKey, RegName, false)
    if (type == "")
        type := "UNKNOWN"

    if (RegTimeModified == "19860523174702")
        status := "-"
    else
        status := "+"
    if (type == "REG_SB_DELETED")
    {
        status := "-"
        type := "-DELETED_VALUE"
    }

    try value := RegRead("HKEY_USERS\" . RegSubKey, RegName)
    catch
    {
        try value := RegRead64("HKEY_USERS", RegSubKey, RegName)
        catch
        {
            try value := RegRead64("HKEY_USERS", RegSubKey, RegName, false)
            catch
            {
                value := ""
                status := "-"
            }
        }
    }

    if (InStr(type, "_SZ"))
    {
        value := StrReplace(value, "`n", A_Space)
        if (type == "REG_MULTI_SZ")
            value := RTrim(value, A_Space)
    }
    if (StrLen(value) > 80)
        value := SubStr(value, 1, 80) . "..."

    name := RegName
    if (name == "")
        name := "@"

    if (type == "KEY")
    {
        if (status == "-")
            type := "-DELETED_KEY"
        outtxt := status . separator . subkey . "\" . name . separator . type . separator . separator
    }
    else
        outtxt := status . separator . subkey . separator . type . separator . name . separator . value
    if (includedate)
        outtxt .= separator . RegTimeModified
    return outtxt
}

MakeFilesConfig(box, filename, mainsbpath)
{
    mainsbpathlen := StrLen(mainsbpath) + 2
    outtxt := ""

    Loop Files, mainsbpath . "\drive\*", "F"
    {
        if (A_LoopFileTimeCreated == "19860523174702")
            status := "-"
        else
            status := "+"
        if (InStr(A_LoopFileAttrib, "D") && status == "+")
            Continue
        name := SubStr(A_LoopFileFullPath, mainsbpathlen)
        outtxt .= status . " " . A_LoopFileTimeModified . " " . name . ":*:`n"
    }
    Loop Files, mainsbpath . "\user\*", "F"
    {
        if (A_LoopFileTimeCreated == "19860523174702")
            status := "-"
        else
            status := "+"
        if (InStr(A_LoopFileAttrib, "D") && status == "+")
            Continue
        name := SubStr(A_LoopFileFullPath, mainsbpathlen)
        outtxt .= status . " " . A_LoopFileTimeModified . " " . name . ":*:`n"
    }

    FileDelete(filename)
    FileAppend("`n" . outtxt, filename)
}

MakeRegConfig(box, filename="")
{
    global regconfig, sandboxes_array, username
    run_pid := InitializeBox(box)

    bregstr_ := sandboxes_array[box].KeyRootPath
    bregstr_ := StrReplace(StrReplace(SubStr(bregstr_, 16), '`%SANDBOX`%', box), '`%USER`%', username)

    mainsbkey := bregstr_
    mainsbkeylen := StrLen(mainsbkey) + 2
    outtxt := ""

    Loop Reg, "HKEY_USERS\" . mainsbkey, "KV", 1
    {
        RegTimeModified := ""
        if (A_LoopRegTimeModified != "")
            RegTimeModified := A_LoopRegTimeModified

        if (A_LoopRegType == "KEY" && RegTimeModified != "19860523174702")
            Continue

        subkey := SubStr(A_LoopRegSubKey, mainsbkeylen)
        out := FormatRegConfigKey(A_LoopRegSubKey, subkey, A_LoopRegType, A_LoopRegName, RegTimeModified, A_Space)
        outtxt .= out . "`n"
    }

    if (filename == "")
        filename := regconfig
    FileDelete(filename)
    FileAppend("`n" . outtxt, filename)

    ReleaseBox(run_pid)
}

SearchReg(box, ignoredKeys, ignoredValues, filename="")
{
    global regconfig, sandboxes_array, username
    run_pid := InitializeBox(box)

    bregstr_ := sandboxes_array[box].KeyRootPath
    bregstr_ := StrReplace(StrReplace(SubStr(bregstr_, 16), '`%SANDBOX`%', box), '`%USER`%', username)

    mainsbkey := bregstr_
    mainsbkeylen := StrLen(mainsbkey) + 2

    if (filename == "")
        filename := regconfig
    regconfigdata := FileRead(filename)
    outtxt := ""

    LastIgnoredKey := "!xxx!:\\"
    Loop Reg, "HKEY_USERS\" . mainsbkey, "KV", 1
    {
        RegTimeModified := ""
        if (A_LoopRegTimeModified != "")
            RegTimeModified := A_LoopRegTimeModified

        subkey := SubStr(A_LoopRegSubKey, mainsbkeylen)
        if (InStr(subkey, LastIgnoredKey) == 1)
            Continue

        if (A_LoopRegType == "KEY")
        {
            if (RegTimeModified != "19860523174702")
                Continue
            if (IsIgnored("keys", ignoredKeys, subkey . "\" . A_LoopRegName))
            {
                LastIgnoredKey := subkey . "\" . A_LoopRegName
                Continue
            }
        }
        else
        {
            if (A_LoopRegName == "")
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
            LastIgnoredKey := subkey
            Continue
        }

        out := FormatRegConfigKey(A_LoopRegSubKey, subkey, A_LoopRegType, A_LoopRegName, RegTimeModified, A_Space)
        if (NOT InStr(regconfigdata, out))
        {
            out := FormatRegConfigKey(A_LoopRegSubKey, subkey, A_LoopRegType, A_LoopRegName, RegTimeModified, chr(1), true)
            outtxt .= out . "`n"
        }
    }

    ReleaseBox(run_pid)

    Return outtxt
}

ListReg(box, bpath, filename="")
{
    global ignoredDirs, ignoredFiles, ignoredKeys, ignoredValues, title, MyListView, LVLastSize, newIgnored_keys, newIgnored_values
    static MainLabel

    if (filename != "")
        comparemode := 1
    else
        comparemode := 0

    ReadIgnoredConfig("reg")
    newIgnored_keys := ""
    newIgnored_values := ""

    Progress("R0-100", "Please wait..., Scanning registry`nof box """ . box . """.", title)
    Progress(50)

    ignoredKeys := StrReplace(ignoredKeys, ":", ".")
    allregs := SearchReg(box, ignoredKeys, ignoredValues, filename)

    Progress(90, "Please wait..., Sorting list of files`nin box """ . box . """.", title)
    sleep(150)
    Sort(allregs, "P3")
    allregs := Trim(allregs, "`n")

    allregs_arr := StrSplit(allregs, "`n")
    numregs := allregs_arr.Length
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
    MyGui.SetMenu(LVMenuBar)

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

    MyListView := MyGui.Add("ListView", "x10 y30 " . LVLastSize . " Checked Count" . numrows . " AltSubmit", ["Status", "Key", "Type", "Value Name", "Value Data", "Key modified time", "Sandbox bpath"])
    MyListView.OnEvent("DoubleClick", GuiLVRegMouseEventHandler)
    MyListView.OnEvent("RightClick", GuiLVRegMouseEventHandler)

    Progress, 100, Please wait..., Building list of keys`nin box "%box%"., %title%
    Sleep, 100

    ; add entries in listview
    nummodified := 0
    numadded := 0
    numdeleted := 0
    MyListView.SetRedraw(false)
    sep := chr(1)
    for i, entry in allregs_arr
    {
        entry_parts := StrSplit(entry, sep)
        St := entry_parts[1]

        keypath := entry_parts[2]
        if (substr(keypath, 1, 8) == "machine\")
            realkeypath := "HKEY_LOCAL_MACHINE" . substr(keypath, 8)
        else if (substr(keypath, 1, 13) == "user\current\")
            realkeypath := "HKEY_CURRENT_USER" . substr(keypath, 13)
        else if (substr(keypath, 1, 21) == "user\current_classes\")
            realkeypath := "HKEY_CLASSES_ROOT" . substr(keypath, 21)

        keytype := entry_parts[3]
        keyvaluename := entry_parts[4]
        keyvalueval := entry_parts[5]
        modtime := FormatTime(entry_parts[6], "yyyy/MM/dd HH:mm:ss")

        if (St == "+") {
            if (keytype != "KEY")
            {
                idx := InStr(realkeypath, "\")
                realrootkey := SubStr(realkeypath, 1, idx-1)
                realsubkey := SubStr(realkeypath, idx+1)
                realkeyvaluename := (keyvaluename == "@") ? "" : keyvaluename

                try {
                    RegRead(realrootkey . "\" . realsubkey, realkeyvaluename)
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

    msg := "Found " . numregs . " registry key" . (numregs!=1 ? "s or values" : " or value")
    msg .= " in the sandbox """ . box . """"
    msg .= " : # " . nummodified . " modified"
    msg .= ", + " . numadded . " new"
    msg .= ", - " . numdeleted . " deleted"
    msg .= ". Double-click a key to open it in RegEdit."
    MainLabel.Text := msg

    Progress(0)
    if (comparemode)
        MyGui.Show(, title . " - Changes in registry of box """ . box . """")
    else
        MyGui.Show(, title . " - Registry of box """ . box . """")
    MyListView.SetRedraw(true)

    MyGui.OnEvent("Close", (*) => SaveNewIgnoredItems("reg"))
}

SearchAutostart(box, regpath, location, tick)
{
    outtxt := ""
    Loop Reg, "HKEY_USERS\" . regpath, "V"
    {
        if (A_LoopRegType != "REG_SZ")
            Continue
        outtxt .= A_LoopRegName . A_Tab . A_LoopRegValue . A_Tab . location . A_Tab . tick . "`n"
    }
    Sort outtxt, "CL D`n"
    Return outtxt
}
ListAutostarts(box, bpath)
{
    global title, MyListView, sandboxes_array, username
    static MainLabel

    bregstr_ := sandboxes_array[box].KeyRootPath
    bregstr_ := StrReplace(StrReplace(SubStr(bregstr_, 16), '`%SANDBOX`%', box), '`%USER`%', username)

    run_pid := InitializeBox(box)
    Sleep(1000)

    autostarts := ""

    ; check RunOnce keys
    key := bregstr_ . "\machine\Software\Microsoft\Windows\CurrentVersion\RunOnce"
    location := "HKLM RunOnce"
    autostarts .= SearchAutostart(box, key, location, 0)

    key := bregstr_ . "\machine\Software\Wow6432Node\Microsoft\Windows\CurrentVersion\RunOnce"
    autostarts .= SearchAutostart(box, key, location, 0)

    key := bregstr_ . "\user\current\Software\Microsoft\Windows\CurrentVersion\RunOnce"
    location := "HKCU RunOnce"
    autostarts .= SearchAutostart(box, key, location, 0)

    key := bregstr_ . "\user\current\Software\Wow6432Node\Microsoft\Windows\CurrentVersion\RunOnce"
    autostarts .= SearchAutostart(box, key, location, 0)

    ; check Run keys
    key := bregstr_ . "\machine\Software\Microsoft\Windows\CurrentVersion\Run"
    location := "HKLM Run"
    autostarts .= SearchAutostart(box, key, location, 1)

    key := "S" . bregstr_ . "\machine\Software\Wow6432Node\Microsoft\Windows\CurrentVersion\Run"
    autostarts .= SearchAutostart(box, key, location, 1)

    key := bregstr_ . "\user\current\Software\Microsoft\Windows\CurrentVersion\Run"
    location := "HKCU Run"
    autostarts .= SearchAutostart(box, key, location, 1)

    key := bregstr_ . "\user\current\Software\Wow6432Node\Microsoft\Windows\CurrentVersion\Run"
    autostarts .= SearchAutostart(box, key, location, 1)

    ReleaseBox(run_pid)

    autostarts := Trim(autostarts, "`n")
    autostarts_arr := StrSplit(autostarts, "`n")
    numregs := autostarts_arr.Length
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
    MyGui.SetMenu(LVMenuBar)

    PopupMenu := Menu()
    PopupMenu.Add("Run in Sandbox", GuiLVRegistryRun)
    PopupMenu.Add("Copy to Start Menu\Startup of Sandbox", GuiLVRegistryItemToStartMenuStartup)
    PopupMenu.Add()
    PopupMenu.Add("Toggle Checkmark", GuiLVToggleCurrent)
    PopupMenu.Add()
    PopupMenu.Add("&Hide from this list", GuiLVHideCurrent)

    MyListView := MyGui.Add("ListView", "x10 y30 " . LVLastSize . " Checked Count" . numrows . " AltSubmit", ["Status", "Program", "Command", "Location"])
    MyListView.OnEvent("DoubleClick", GuiLVAutostartMouseEventHandler)
    MyListView.OnEvent("RightClick", GuiLVAutostartMouseEventHandler)

    ; icons array
    ImageListID1 := IL_Create(10)
    LV_SetImageList(ImageListID1)

    ; add entries in listview
    MyListView.SetRedraw(false)
    row := 1
    A_Quotes := """"
    for i, entry in autostarts_arr
    {
        entry_parts := StrSplit(entry, A_Tab)
        valuename := entry_parts[1]
        valuedata := entry_parts[2]
        location := entry_parts[3]
        ticked := entry_parts[4]

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

    msg := "Found " . numregs . " autostart program" . (numregs!=1 ? "s" : "")
    msg .= " in the sandbox """ . box . """."
    msg .= " Double-click an entry to run it."
    MainLabel.Text := msg
    MyGui.Show(, title . " - Autostart programs in registry of box """ . box . """")
    MyListView.SetRedraw(true)
    MyGui.OnEvent("Close", (*) => MyGui.Destroy())
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
    static HKEY := Map( "HKEY_CLASSES_ROOT", 0x80000000, "HKEY_CURRENT_USER", 0x80000001, "HKEY_LOCAL_MACHINE", 0x80000002, "HKEY_USERS", 0x80000003, "HKEY_CURRENT_CONFIG", 0x80000005, "HKEY_DYN_DATA", 0x80000006)
    static REG_NONE := 0, REG_SZ := 1, REG_EXPAND_SZ := 2, REG_BINARY := 3, REG_DWORD := 4, REG_DWORD_BIG_ENDIAN := 5, REG_LINK := 6, REG_MULTI_SZ := 7, REG_RESOURCE_LIST := 8, REG_FULL_RESOURCE_DESCRIPTOR := 9, REG_RESOURCE_REQUIREMENTS_LIST := 10, REG_QWORD := 11
    static KEY_QUERY_VALUE := 0x0001, KEY_WOW64_64KEY := 0x0100, KEY_WOW64_32KEY := 0x0200

    myhKey := HKEY.Has(sRootKey) ? HKEY[sRootKey] : ""
    if (myhKey == "") {
        throw Error("Invalid root key", -1)
    }

    RegAccessRight := mode64bit ? KEY_QUERY_VALUE + KEY_WOW64_64KEY : KEY_QUERY_VALUE + KEY_WOW64_32KEY

    hKey := 0
    if DllCall("Advapi32.dll\RegOpenKeyEx", "Ptr", myhKey, "Str", sKeyName, "UInt", 0, "UInt", RegAccessRight, "Ptr*", &hKey) != 0 {
        throw Error("Failed to open registry key", -1)
    }

    sValueType := 0
    DllCall("Advapi32.dll\RegQueryValueEx", "Ptr", hKey, "Str", sValueName, "UInt", 0, "UInt*", &sValueType, "Ptr", 0, "Ptr", 0)

    if (sValueType == REG_SZ || sValueType == REG_EXPAND_SZ) {
        sValue := Buffer(vValueSize := DataMaxSize)
        DllCall("Advapi32.dll\RegQueryValueEx", "Ptr", hKey, "Str", sValueName, "UInt", 0, "UInt", 0, "Str", sValue, "UInt*", &vValueSize)
        sValue := StrGet(sValue, vValueSize)
    } else if (sValueType == REG_DWORD || sValueType == REG_DWORD_BIG_ENDIAN) {
        vValueSize := 4
        sValue := 0
        DllCall("Advapi32.dll\RegQueryValueEx", "Ptr", hKey, "Str", sValueName, "UInt", 0, "UInt", 0, "UInt*", &sValue, "UInt*", &vValueSize)
    } else if (sValueType == REG_QWORD) {
        vValueSize := 8
        sValue := 0
        DllCall("Advapi32.dll\RegQueryValueEx", "Ptr", hKey, "Str", sValueName, "UInt", 0, "UInt", 0, "Int64*", &sValue, "UInt*", &vValueSize)
    } else if (sValueType == REG_MULTI_SZ) {
        sTmp := Buffer(vValueSize := DataMaxSize)
        DllCall("Advapi32.dll\RegQueryValueEx", "Ptr", hKey, "Str", sValueName, "UInt", 0, "UInt", 0, "Ptr", sTmp, "UInt*", &vValueSize)
        sValue := ""
        offset := 0
        while (offset < vValueSize) {
            str := StrGet(sTmp.Ptr + offset)
            if (str == "") break
            sValue .= str . "`n"
            offset += StrLen(str) * (A_IsUnicode ? 2 : 1) + (A_IsUnicode ? 2 : 1)
        }
    } else if (sValueType == REG_BINARY) {
        sTmp := Buffer(vValueSize := DataMaxSize)
        DllCall("Advapi32.dll\RegQueryValueEx", "Ptr", hKey, "Str", sValueName, "UInt", 0, "UInt", 0, "Ptr", sTmp, "UInt*", &vValueSize)
        sValue := ""
        Loop vValueSize {
            sValue .= Format("{:02X}", NumGet(sTmp, A_Index - 1, "UChar"))
        }
    } else if (sValueType == REG_NONE) {
        sValue := ""
    } else {
        DllCall("Advapi32.dll\RegCloseKey", "Ptr", hKey)
        throw Error("Unsupported value type", -1)
    }
    DllCall("Advapi32.dll\RegCloseKey", "Ptr", hKey)
    return sValue
}

RegRead64KeyType(sRootKey, sKeyName, sValueName = "", mode64bit=true) {
    static HKEY := Map( "HKEY_CLASSES_ROOT", 0x80000000, "HKEY_CURRENT_USER", 0x80000001, "HKEY_LOCAL_MACHINE", 0x80000002, "HKEY_USERS", 0x80000003, "HKEY_CURRENT_CONFIG", 0x80000005, "HKEY_DYN_DATA", 0x80000006)
    static REG_TYPES := Map(0, "REG_NONE", 1, "REG_SZ", 2, "REG_EXPAND_SZ", 3, "REG_BINARY", 4, "REG_DWORD", 5, "REG_DWORD_BIG_ENDIAN", 6, "REG_LINK", 7, "REG_MULTI_SZ", 8, "REG_RESOURCE_LIST", 9, "REG_FULL_RESOURCE_DESCRIPTOR", 10, "REG_RESOURCE_REQUIREMENTS_LIST", 11, "REG_QWORD", 0x786F6273, "REG_SB_DELETED")
    static KEY_QUERY_VALUE := 0x0001, KEY_WOW64_64KEY := 0x0100, KEY_WOW64_32KEY := 0x0200

    myhKey := HKEY.Has(sRootKey) ? HKEY[sRootKey] : ""
    if (myhKey == "") {
        throw Error("Invalid root key", -1)
    }

    RegAccessRight := mode64bit ? KEY_QUERY_VALUE + KEY_WOW64_64KEY : KEY_QUERY_VALUE + KEY_WOW64_32KEY

    hKey := 0
    if DllCall("Advapi32.dll\RegOpenKeyEx", "Ptr", myhKey, "Str", sKeyName, "UInt", 0, "UInt", RegAccessRight, "Ptr*", &hKey) != 0 {
        throw Error("Failed to open registry key", -1)
    }

    sValueType := 0
    DllCall("Advapi32.dll\RegQueryValueEx", "Ptr", hKey, "Str", sValueName, "UInt", 0, "UInt*", &sValueType, "Ptr", 0, "Ptr", 0)
    DllCall("Advapi32.dll\RegCloseKey", "Ptr", hKey)

    return REG_TYPES.Has(sValueType) ? REG_TYPES[sValueType] : ""
}

RegEnumKey(sRootKey, sKeyName, x64mode=true) {
    static HKEY := Map( "HKEY_CLASSES_ROOT", 0x80000000, "HKEY_CURRENT_USER", 0x80000001, "HKEY_LOCAL_MACHINE", 0x80000002, "HKEY_USERS", 0x80000003, "HKEY_CURRENT_CONFIG", 0x80000005, "HKEY_DYN_DATA", 0x80000006)
    static KEY_ENUMERATE_SUB_KEYS := 0x0008, KEY_WOW64_64KEY := 0x0100, KEY_WOW64_32KEY := 0x0200
    static ERROR_NO_MORE_ITEMS := 259

    myhKey := HKEY.Has(sRootKey) ? HKEY[sRootKey] : ""
    if (myhKey == "") {
        throw Error("Invalid root key", -1)
    }

    RegAccessRight := x64mode ? KEY_ENUMERATE_SUB_KEYS + KEY_WOW64_64KEY : KEY_ENUMERATE_SUB_KEYS + KEY_WOW64_32KEY

    hKey := 0
    if DllCall("Advapi32.dll\RegOpenKeyEx", "Ptr", myhKey, "Str", sKeyName, "UInt", 0, "UInt", RegAccessRight, "Ptr*", &hKey) != 0 {
        throw Error("Failed to open registry key", -1)
    }

    names := ""
    dwIndex := 0
    loop
    {
        lpcName := 512
        lpName := Buffer(lpcName)
        rc := DllCall("Advapi32.dll\RegEnumKeyEx", "Ptr", hKey, "UInt", dwIndex, "Str", lpName, "UInt*", &lpcName, "Ptr", 0, "Ptr", 0, "Ptr", 0, "Ptr", 0)
        if (rc == 0) {
            names .= StrGet(lpName) . "`n"
            dwIndex++
        } else {
            if (rc != ERROR_NO_MORE_ITEMS)
                throw Error("RegEnumKeyEx failed", -1, rc)
            break
        }
    }

    DllCall("Advapi32.dll\RegCloseKey", "Ptr", hKey)

    names := Trim(names, "`n")
    Sort names, "CL"
    return names
}

RegEnumValue(sRootKey, sKeyName, x64mode=true) {
    static HKEY := Map( "HKEY_CLASSES_ROOT", 0x80000000, "HKEY_CURRENT_USER", 0x80000001, "HKEY_LOCAL_MACHINE", 0x80000002, "HKEY_USERS", 0x80000003, "HKEY_CURRENT_CONFIG", 0x80000005, "HKEY_DYN_DATA", 0x80000006)
    static KEY_QUERY_VALUE := 0x0001, KEY_WOW64_64KEY := 0x0100, KEY_WOW64_32KEY := 0x0200
    static ERROR_NO_MORE_ITEMS := 259

    myhKey := HKEY.Has(sRootKey) ? HKEY[sRootKey] : ""
    if (myhKey == "") {
        throw Error("Invalid root key", -1)
    }

    RegAccessRight := x64mode ? KEY_QUERY_VALUE + KEY_WOW64_64KEY : KEY_QUERY_VALUE + KEY_WOW64_32KEY

    hKey := 0
    if DllCall("Advapi32.dll\RegOpenKeyEx", "Ptr", myhKey, "Str", sKeyName, "UInt", 0, "UInt", RegAccessRight, "Ptr*", &hKey) != 0 {
        throw Error("Failed to open registry key", -1)
    }

    lpcMaxValueNameLen := 0
    DllCall("Advapi32.dll\RegQueryInfoKey", "Ptr", hKey, "Ptr", 0, "Ptr", 0, "Ptr", 0, "Ptr", 0, "Ptr", 0, "Ptr", 0, "Ptr", 0, "UInt*", &lpcMaxValueNameLen, "Ptr", 0, "Ptr", 0, "Ptr", 0)
    lpcMaxValueNameLen := lpcMaxValueNameLen * 2 + 2

    names := ""
    dwIndex := 0
    loop
    {
        lpcName := lpcMaxValueNameLen
        lpName := Buffer(lpcName)
        rc := DllCall("Advapi32.dll\RegEnumValue", "Ptr", hKey, "UInt", dwIndex, "WStr", lpName, "UInt*", &lpcName, "Ptr", 0, "Ptr", 0, "Ptr", 0, "Ptr", 0)
        if (rc == 0) {
            names .= StrGet(lpName) . "`n"
            dwIndex++
        } else {
            if (rc != ERROR_NO_MORE_ITEMS)
                throw Error("RegEnumValue failed", -1, rc)
            break
        }
    }

    DllCall("Advapi32.dll\RegCloseKey", "Ptr", hKey)

    names := Trim(names, "`n")
    Sort names, "CL"
    return names
}

ExtractData(pointer) {
    return StrGet(pointer)
}

; ###########################################
; Dec/Hex and String/Hex conversion functions
; ###########################################

hex2dec(hex)
{
    return Integer("0x" . LTrim(hex, "0x"))
}

dec2hex(dec,minlength=2)
{
    hex := Format("{:X}", dec)
    while (StrLen(hex) < minlength)
        hex := "0" . hex
    return hex
}

qword2hex(qword)
{
    hex := Format("{:X}", qword)
    while (StrLen(hex) < 16)
        hex := "0" . hex

    out := ""
    loop 8
    {
        b := SubStr(hex, (A_Index-1)*2+1, 2)
        out .= b . ","
    }
    return Trim(out, ",")
}

hexstr2hexstrcomas(hex)
{
    out := ""
    loop StrLen(hex)
    {
        out .= SubStr(hex, A_Index, 1)
        if (Mod(A_Index,2)==0)
            out .= ","
    }
    return Trim(out, ",")
}

hexstr2str(hexstr)
{
    str := ""
    loop (StrLen(hexstr) / 2)
        str .= Chr("0x" . SubStr(hexstr, (A_Index-1)*2+1, 2))
    return str
}

str2hexstr(str,replacenlwithzero=false)
{
    out := ""
    ; TODO: convert really to UTF-16
    for i, char in StrSplit(str, "")
    {
        h := Format("{:X}", Asc(char))
        if (replacenlwithzero && h == "A")
            out .= "00,"
        else
        {
            if (StrLen(h)==1)
                out .= "0" . h . ","
            else
                out .= h . ","
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
    if (mode == "dirs" || mode == "files")
        pathcol := 10
    else
        pathcol := 7

    Srows := []
    RowNumber := 0
    Loop
    {
        RowNumber := MyListView.GetNext(RowNumber, "Focused")
        if not RowNumber
            break
        Srows.Push(RowNumber)
    }

    removedpaths := []
    for i, row in Srows
    {
        if (mode == "keys" || mode == "dirs")
        {
            item := MyListView.GetText(row, pathcol)
            removedpaths.Push(item)
        }
        else if (mode == "values")
        {
            item := MyListView.GetText(row, pathcol)
            val := MyListView.GetText(row, 4)
            item := item . "\" . val
        }
        else
        {
            item := MyListView.GetText(row, pathcol)
            val := MyListView.GetText(row, 2)
            item := item . "\" . val
        }
        AddIgnoreItem(mode, item)
    }

    Srows.Sort("R")
    for i, row in Srows
        MyListView.Delete(row)

    if (mode == "dirs" || mode == "keys") {
        for i, p in removedpaths
        {
            loop MyListView.GetCount()
            {
                j := MyListView.GetCount() - A_Index + 1
                item := MyListView.GetText(j, pathcol)
                if (InStr(item, p, 1) == 1)
                    MyListView.Delete(j)
            }
        }
    }
}

ReadIgnoredConfig(type)
{
    global ignoredDirs, ignoredFiles, ignoredKeys, ignoredValues, ignorelist

    if (type == "files")
    {
        ignoredDirs := "`n"
        if (FileExist(ignorelist . "dirs.cfg"))
            ignoredDirs .= FileRead(ignorelist . "dirs.cfg") . "`n"
        ignoredFiles := "`n"
        if (FileExist(ignorelist . "files.cfg"))
            ignoredFiles .= FileRead(ignorelist . "files.cfg") . "`n"
    }
    else
    {
        ignoredKeys := "`n"
        if (FileExist(ignorelist . "keys.cfg"))
            ignoredKeys .= FileRead(ignorelist . "keys.cfg") . "`n"
        ignoredValues := "`n"
        if (FileExist(ignorelist . "values.cfg"))
            ignoredValues .= FileRead(ignorelist . "values.cfg") . "`n"
    }
}

AddIgnoreItem(mode, item)
{
    global newIgnored_dirs, newIgnored_files, newIgnored_keys, newIgnored_values
    if (mode == "dirs")
        newIgnored_dirs .= item . "`n"
    else if (mode == "files")
        newIgnored_files .= item . "`n"
    else if (mode == "keys")
        newIgnored_keys .= item . "`n"
    else if (mode == "values")
        newIgnored_values .= item . "`n"
}

SaveNewIgnoredItems(mode)
{
    global ignoredDirs, ignoredFiles, ignoredKeys, ignoredValues, ignorelist, newIgnored_dirs, newIgnored_files, newIgnored_keys, newIgnored_values

    if (mode == "files")
    {
        if (newIgnored_dirs == "" && newIgnored_files == "")
            Return
        pathdata := ignoredDirs . newIgnored_dirs
        itemdata := ignoredFiles . newIgnored_files
        pathfilename := ignorelist . "dirs.cfg"
        itemfilename := ignorelist . "files.cfg"
    }
    else
    {
        if (newIgnored_keys == "" && newIgnored_values == "")
            Return
        pathdata := ignoredKeys . newIgnored_keys
        itemdata := ignoredValues . newIgnored_values
        pathfilename := ignorelist . "keys.cfg"
        itemfilename := ignorelist . "values.cfg"
    }
    Sort pathdata, "U"
    Sort itemdata, "U"

    outpathdata := "`n"
    for i, field in StrSplit(pathdata, "`n", "`r")
    {
        if (field == "")
            Continue
        sub := field
        found := 0
        Loop
        {
            SplitPath(sub, , &sub)
            if (sub == "")
                break
            if (InStr(outpathdata, "`n" . sub . "`n"))
            {
                found := 1
                break
            }
        }
        if (!found)
            outpathdata .= field . "`n"
    }

    outitemdata := "`n"
    for i, field in StrSplit(itemdata, "`n", "`r")
    {
        if (field == "")
            Continue
        sub := field
        found := 0
        Loop
        {
            SplitPath(sub, , &sub)
            if (sub == "")
                break
            if (InStr(outpathdata, "`n" . sub . "`n"))
            {
                found := 1
                break
            }
        }
        if (!found)
            outitemdata .= field . "`n"
    }

    FileDelete(pathfilename)
    FileAppend(outpathdata, pathfilename)

    FileDelete(itemfilename)
    FileAppend(outitemdata, itemfilename)
}

LVIgnoreSpecific(row, mode)
{
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

    result := InputBox("Add item to Ignore List", prompt, , , , , , , , tohide)
    if result.Result == "Cancel"
        Return
    tohide := result.Value

    tohide := Trim(tohide, "\")
    if (tohide != "")
        AddIgnoreItem(mode, tohide)

    tohidepath := tohide . "\"
    loop MyListView.GetCount()
    {
        i := MyListView.GetCount() - A_Index + 1
        item := MyListView.GetText(i, pathcol)
        if (InStr(item, tohidepath, 1) == 1 || item == tohide)
            MyListView.Delete(i)
    }
}

IsIgnored(mode, ignoredList, checkpath, item="")
{
    checkpath := StrReplace(checkpath, ":", ".")
    if (ignoredList == "")
        Return 0

    if (mode == "values" || mode == "files")
    {
        tocheck := "`n" . checkpath . "\" . item . "`n"
        return InStr(ignoredList, tocheck)
    }
    else
    {
        loop
        {
            tocheck := "`n" . checkpath . "`n"
            if (InStr(ignoredList, tocheck))
                Return 1
            SplitPath(checkpath, , &checkpath)
            if (checkpath == "")
                Return 0
        }
    }
    Return 0
}

; ###################################################################################################
; Menu handlers
; ###################################################################################################

RunProgramMenuHandler:
    box := getBoxFromMenu()
    shortcut := menucommands[A_ThisMenu,A_ThisMenuItem]
    ; TODO: handle shortcuts to .URL files
    if (GetKeyState("Control", "P")) {
        iconfile := menuicons[A_ThisMenu,A_ThisMenuItem,"file"]
        iconnum := menuicons[A_ThisMenu,A_ThisMenuItem,"num"]
        if (iconnum < 0)
            iconnum := IndexOfIconResource(iconfile, iconnum)
        createDesktopShortcutFromLnk(box, shortcut, iconfile, iconnum)
    } else if (GetKeyState("Shift", "P")) {
        SplitPath, shortcut, , dir
        Run, %start% /box:%box% "%dir%"
        MsgBox, 64, %title%, Opening sandboxed folder`n"%dir%"`n`nPlease wait, 3
    } else {
        executeShortcut(box, shortcut)
    }
Return

RunUserToolMenuHandler:
    shortcut := menucommands[A_ThisMenu,A_ThisMenuItem]
    executeShortcut("", shortcut)
Return

NewShortcutMenuHandler:
    NewShortcutMenuHandler(box)
Return
NewShortcutMenuHandler(box)
{
    static DefaultShortcutFolder
    box := getBoxFromMenu()
    if (! InStr(FileExist(DefaultShortcutFolder . "\"), "D"))
        DefaultShortcutFolder = %userprofile%\Desktop
    FileSelectFile, file, 33, %A_ProgramFiles%\, Select the file to launch sanboxed in box %box% via a shortcut on the desktop, Executable files (*.exe)
    if (NOT file)
        return
    NewShortcut(box, file)
    SplitPath, filename, , DefaultShortcutFolder
    Return
}

RunDialogMenuHandler:
    box := getBoxFromMenu()
    if (GetKeyState("Control", "P"))
        writeSandboxedShortcutFileToDesktop(start,"Sandboxie's Run dialog","","/box:" box " run_dialog","Launch Sandboxie's Run Dialog in sandbox " box,SbieAgentResMain,SbieAgentResMainId,1, box)
    else
        run, %start% /box:%box% run_dialog, , UseErrorLevel
Return

StartMenuMenuHandler:
    box := getBoxFromMenu()
    if (GetKeyState("Control", "P"))
        writeSandboxedShortcutFileToDesktop(start,"Sandboxie's Start Menu","","/box:" box " start_menu","Launch Sandboxie's Start Menu in sandbox " box,SbieAgentResMain,SbieAgentResMainId,1, box)
    else
        run, %start% /box:%box% start_menu, , UseErrorLevel
Return

SCmdMenuHandler:
    box := getBoxFromMenu()
    if (GetKeyState("Control", "P"))
    {
        args = /box:%box% %comspec% /k "cd /d %systemdrive%\"
        writeSandboxedShortcutFileToDesktop(start,"Sandboxed Command Prompt","",args,"Sandboxed Command Prompt in sandbox " box,cmdRes, 1,1, box)
    }
    else
    {
        if (InStr(FileExist(expandEnvVars(sbcommandpromptdir)), "D"))
            cdpath = %sbcommandpromptdir%
        else
            cdpath = %systemdrive%\
        run, %start% /box:%box% %comspec% /k "cd /d %cdpath%", , UseErrorLevel
    }
Return

UCmdMenuHandler(ItemName, ItemPos, MyMenu)
{
    global sandboxes_array, comspec, cmdRes
    box := getBoxFromMenuObj(MyMenu)
    bpath := sandboxes_array[box, "bpath"]
    if (GetKeyState("Control", "P"))
    {
        args := '/k "cd /d ""' . bpath . '"""'
        writeUnsandboxedShortcutFileToDesktop(comspec, "Unsandboxed Command Prompt in sandbox " . box, bpath, args, "Unsandboxed Command Prompt in sandbox " . box, cmdRes, 1, 1)
    }
    else
        Run(comspec . ' /k "cd /d ""' . bpath . '"""',, "UseErrorLevel")
}

SRegEditMenuHandler(ItemName, ItemPos, MyMenu)
{
    global start, regeditImg, regeditRes
    box := getBoxFromMenuObj(MyMenu)
    if (GetKeyState("Control", "P"))
        writeSandboxedShortcutFileToDesktop(start, "Sandboxed Registry Editor", "", "/box:" . box . " " . regeditImg, "Launch RegEdit in sandbox " . box, regeditRes, 1, 1, box)
    else
        Run(start . " /box:" . box . " " . regeditImg,, "UseErrorLevel")
}

URegEditMenuHandler(ItemName, ItemPos, MyMenu)
{
    global title, sandboxes_array, username
    if (GetKeyState("Control", "P"))
        MsgBox(48, title, "Since something must be running in the box to analyse its registry, creating a desktop shortcut to launch the unsandboxed Registry Editor is not supported. Sorry.`n`nNote that creating a shortcut to a sandboxed Registry Editor is supported, but on x64 systems you can launch it only in sandboxes with the Drop Rights restriction disabled.")
    else
    {
        box := getBoxFromMenuObj(MyMenu)
        ; ensure that the box is in use, or the hive will not be loaded
        run_pid := InitializeBox(box)
        ; pre-select the right registry key
        bregstr_ := sandboxes_array[box, "KeyRootPath"]
        bregstr_ := StrReplace(StrReplace(SubStr(bregstr_, 16), '`%SANDBOX`%', box), '`%USER`%', username)
        RegWrite "HKEY_USERS\" . bregstr_, "HKEY_CURRENT_USER\Software\Microsoft\Windows\CurrentVersion\Applets\Regedit", "LastKey", "REG_SZ"
        ; launch regedit
        RunWait('RegEdit.exe',, 'UseErrorLevel')
        ReleaseBox(run_pid)
    }
}

UninstallMenuHandler(ItemName, ItemPos, MyMenu)
{
    global start, shell32
    box := getBoxFromMenuObj(MyMenu)
    if (GetKeyState("Control", "P"))
        writeSandboxedShortcutFileToDesktop(start, "Uninstall Programs", "", "/box:" . box . " appwiz.cpl", "Uninstall or installs programs in sandbox " . box, shell32, 22, 1, box)
    else
        RunWait(start . " /box:" . box . " appwiz.cpl",, "UseErrorLevel")
}

TerminateMenuHandler(ItemName, ItemPos, MyMenu)
{
    global start, shell32
    box := getBoxFromMenuObj(MyMenu)
    if (GetKeyState("Control", "P"))
        writeUnsandboxedShortcutFileToDesktop(start, "Terminate Programs in sandbox " . box, "", "/box:" . box . " /terminate", "Terminate all programs running in sandbox " . box, shell32, 220, 1)
    else
        RunWait(start . " /box:" . box . " /terminate",, "UseErrorLevel")
}

DeleteBoxMenuHandler(ItemName, ItemPos, MyMenu)
{
    global start, shell32, title
    box := getBoxFromMenuObj(MyMenu)
    if (GetKeyState("Control", "P")) {
        writeUnsandboxedShortcutFileToDesktop(start, "! Delete sandbox " . box . " !", "", "/box:" . box . " delete_sandbox", "Deletes the sandbox " . box, shell32, 132, 1)
        MsgBox(48, title, "Warning! Unlike when this is run from the SandboxToys Menu, the desktop shortcut that has been created doesn't ask for confirmation!`n`nUse the shortcut with care!")
    } else {
        if (MsgBox("Are you sure you want to delete the sandbox """ . box . """?", title, "YesNoCancel IconQuestion") != "Yes")
            Return
        RunWait(start . " /box:" . box . " delete_sandbox",, "UseErrorLevel")
    }
}

SExploreMenuHandler(ItemName, ItemPos, MyMenu)
{
    global start, sbdir, explorer, explorerRes
    box := getBoxFromMenuObj(MyMenu)
    if (GetKeyState("Control", "P"))
        writeSandboxedShortcutFileToDesktop(start, "Explore sandbox " . box . " (Sandboxed)", sbdir, "/box:" . box . " " . explorer, "Launches Explorer sandboxed in sandbox " . box, explorerRes, 1, 1, box)
    else
        Run(start . " /box:" . box . " " . explorer,,, "UseErrorLevel")
}

UExploreMenuHandler(ItemName, ItemPos, MyMenu)
{
    global sandboxes_array, explorerImg, explorerArgE, explorer, explorerRes, A_Quotes
    box := getBoxFromMenuObj(MyMenu)
    bpath := sandboxes_array[box, "bpath"]
    if (GetKeyState("Control", "P"))
        writeUnsandboxedShortcutFileToDesktop(explorerImg, "Explore sandbox " . box . " (Unsandboxed)", bpath, explorerArgE . " " . A_Quotes . bpath . A_Quotes, "Launches Explorer unsandboxed in sandbox " . box, explorerRes, 1, 1)
    else
        Run(explorer . " " . A_Quotes . bpath . A_Quotes,,, "UseErrorLevel")
}

URExploreMenuHandler(ItemName, ItemPos, MyMenu)
{
    global sandboxes_array, explorerImg, explorerArgER, explorerERArg, explorerRes, A_Quotes
    box := getBoxFromMenuObj(MyMenu)
    bpath := sandboxes_array[box, "bpath"]
    if (GetKeyState("Control", "P"))
        writeUnsandboxedShortcutFileToDesktop(explorerImg, "Explore sandbox " . box . " (Unsandboxed, restricted)", bpath, explorerArgER . " " . A_Quotes . bpath . A_Quotes, "Launches Explorer unsandboxed and restricted to sandbox " . box, explorerRes, 1, 1)
    else
        Run(explorerERArg . " " . A_Quotes . bpath . A_Quotes,,, "UseErrorLevel")
}

LaunchSbieAgentMenuHandler(ItemName, ItemPos, MyMenu)
{
    global SbieAgent, SbieMngr, SbieCtrl, SbieAgentResMainText, sbdir
    if (GetKeyState("Control", "P")) {
        if (SbieAgent == SbieMngr) {
            writeUnsandboxedShortcutFileToDesktop(SbieAgent, SbieAgentResMainText, sbdir, "", "Launch " . SbieAgentResMainText, "", "", 1)
        }
        if (SbieAgent == SbieCtrl) {
            writeUnsandboxedShortcutFileToDesktop(SbieAgent, SbieAgentResMainText, sbdir, "", "Launch " . SbieAgentResMainText, "", "", 1)
        }
    }
    else {
        Run(SbieAgent,, "UseErrorLevel")
    }
}

ListFilesMenuHandler(ItemName, ItemPos, MyMenu)
{
    global sandboxes_array
    box := getBoxFromMenuObj(MyMenu)
    bpath := sandboxes_array[box, "bpath"]
    ListFiles(box, bpath)
}

ListRegMenuHandler(ItemName, ItemPos, MyMenu)
{
    global sandboxes_array
    box := getBoxFromMenuObj(MyMenu)
    bpath := sandboxes_array[box, "bpath"]
    ListReg(box, bpath)
}

ListAutostartsMenuHandler(ItemName, ItemPos, MyMenu)
{
    global sandboxes_array
    box := getBoxFromMenuObj(MyMenu)
    bpath := sandboxes_array[box, "bpath"]
    ListAutostarts(box, bpath)
}

WatchRegMenuHandler(ItemName, ItemPos, MyMenu)
{
    global sandboxes_array, username, temp, title
    box := getBoxFromMenuObj(MyMenu)
    bpath := sandboxes_array[box, "bpath"]
    bregstr_ := sandboxes_array[box, "KeyRootPath"]
    bregstr_ := StrReplace(StrReplace(SubStr(bregstr_, 16), '`%SANDBOX`%', box), '`%USER`%', username)
    comparefile := temp . "\S" . regstr_ . "_reg_compare.cfg"
    MakeRegConfig(box, comparefile)
    result := MsgBox("The current state of the registry of sandbox """ . box . """ has been saved.`n`nYou can now work in the box. When finished, click Continue, and the new state of the registry will be compared with the old state, and the result displayed so that you can analyse the changes, and export them as a REG file if you wish.`n`nNote that the registry keys and the deleted registry values will not be listed. However, a deleted key or value will be listed if it is present in the ""real world"".`n`n*** Click Continue ONLY when ready! ***", title, "Continue&Try Again&Cancel")
    if (result == "Continue")
        ListReg(box, bpath, comparefile)
    else if (result == "Try Again")
        WatchRegMenuHandler(ItemName, ItemPos, MyMenu)
}

WatchFilesMenuHandler(ItemName, ItemPos, MyMenu)
{
    global sandboxes_array, username, temp, title
    box := getBoxFromMenuObj(MyMenu)
    bpath := sandboxes_array[box, "bpath"]
    bregstr_ := sandboxes_array[box, "KeyRootPath"]
    bregstr_ := StrReplace(StrReplace(SubStr(bregstr_, 16), '`%SANDBOX`%', box), '`%USER`%', username)
    comparefile := temp . "\" . regstr_ . "_files_compare.cfg"
    MakeFilesConfig(box, comparefile, bpath)
    result := MsgBox("The current state of the files in sandbox """ . box . """ has been saved.`n`nYou can now work in the box. When finished, click Continue, and the new state of the files will be compared with the old state, and the result displayed so that you can analyse the changes, and export the modified or new files if you wish.`n`nNote that the folders and the deleted files will not be listed. However, a deleted folder or file will be listed if it is present in the ""real world"".`n`n*** Click Continue ONLY when ready! ***", title, "Continue&Try Again&Cancel")
    if (result == "Continue")
        ListFiles(box, bpath, comparefile)
    else if (result == "Try Again")
        WatchFilesMenuHandler(ItemName, ItemPos, MyMenu)
}

WatchFilesRegMenuHandler(ItemName, ItemPos, MyMenu)
{
    global sandboxes_array, username, temp, title
    box := getBoxFromMenuObj(MyMenu)
    bpath := sandboxes_array[box, "bpath"]
    bregstr_ := sandboxes_array[box, "KeyRootPath"]
    bregstr_ := StrReplace(StrReplace(SubStr(bregstr_, 16), '`%SANDBOX`%', box), '`%USER`%', username)
    comparefile1 := temp . "\" . regstr_ . "_files_compare.cfg"
    MakeFilesConfig(box, comparefile1, bpath)
    comparefile2 := temp . "\S" . regstr_ . "_reg_compare.cfg"
    MakeRegConfig(box, comparefile2)
    result := MsgBox("The current state of the files and registry of sandbox """ . box . """ has been saved.`n`nYou can now work in the box. When finished, click Continue, and the new state of the files and registry will be compared with the old state, and the result displayed so that you can analyse the changes.`n`nNote that the folders, the deleted files, the registry keys and the deleted registry values will not be listed. However, a deleted folder, file, key or value will be listed if it is present in the ""real world"".`n`n*** Click Continue ONLY when ready! ***", title, "Continue&Try Again&Cancel")
    if (result == "Continue")
    {
        ListFiles(box, bpath, comparefile1)
        ListReg(box, bpath, comparefile2)
    }
    else if (result == "Try Again")
        WatchFilesRegMenuHandler(ItemName, ItemPos, MyMenu)
}

SetupMenuMenuHandler1(ItemName, ItemPos, MyMenu)
{
    global largeiconsize, sbtini
    if (largeiconsize > 16) {
        largeiconsize := 16
        MyMenu.Uncheck(ItemName)
    } else {
        largeiconsize := 32
        MyMenu.Check(ItemName)
    }
    IniWrite(largeiconsize, sbtini, "AutoConfig", "LargeIconSize")
}

SetupMenuMenuHandler2(ItemName, ItemPos, MyMenu)
{
    global smalliconsize, sbtini
    if (smalliconsize > 16) {
        smalliconsize := 16
        MyMenu.Uncheck(ItemName)
    } else {
        smalliconsize := 32
        MyMenu.Check(ItemName)
    }
    IniWrite(smalliconsize, sbtini, "AutoConfig", "SmallIconSize")
}

SetupMenuMenuHandler3(ItemName, ItemPos, MyMenu)
{
    global seperatedstartmenus, sbtini
    if (seperatedstartmenus) {
        seperatedstartmenus := 0
        MyMenu.Uncheck(ItemName)
    } else {
        seperatedstartmenus := 1
        MyMenu.Check(ItemName)
    }
    IniWrite(seperatedstartmenus, sbtini, "AutoConfig", "SeperatedStartMenus")
}

SetupMenuMenuHandler4(ItemName, ItemPos, MyMenu)
{
    global includeboxnames, sbtini
    if (includeboxnames) {
        includeboxnames := 0
        MyMenu.Uncheck(ItemName)
    } else {
        includeboxnames := 1
        MyMenu.Check(ItemName)
    }
    IniWrite(includeboxnames, sbtini, "AutoConfig", "IncludeBoxNames")
}

MainHelpMenuHandler(ItemName, ItemPos, MyMenu)
{
    global title, usertoolsdir
    MsgBox(64, title, title . "`n`nSandboxToys2 Main Menu usage:`n`nThe main menu displays the shortcuts present in the Start Menu, Desktop and QuickLaunch folders of your sandboxes. Just select any of these shortcuts to launch the program, sandboxed in the right box. Of course, there must be programs installed in your sandboxes, or the menus will not be displayed.`n`nNote also that you can create easily a ""sandboxed shortcut"" on your real destkop to launch any program displayed in the SandboxToys Menu even easier! Just Control-Click on the menu entry, and the shortcut will be created on your desktop. (Note: This work also with most icons of the Explore, Registry and Tools menu.)`n`nSimilarly, Shift-clicking on a menu icon opens the folder containing the file. The Windows explorer is run sandboxed.`n`nSandboxToys2 offers also some tools in its Explore, Registry and Tools Menus. They should be self-explanatory.`nUnlike the method explained above, Tools -> New Sandboxed Shortcut creates a sandboxed shortcut on your desktop to any unsandboxed file located in your real discs.`n`nThe User Tools menu is a configurable menu, that can contain almost anything you want. To use it, place a (normal or sandboxed) shortcut in the """ . usertoolsdir . """ folder, and it will be displayed in the User Tools menu. Note that the tools launched via that menu are run unsandboxed, unless the shortcut itself is sandboxed (ie it uses Sandboxie's Start.exe to launch the command). You can create sub-menus in the User Tools menu by placing shortcuts in folders within the """ . usertoolsdir . """ folder.")
}

CmdLineHelp()
{
    global title
    MsgBox(64, title, title . "`n`nSandboxToys2 Command Line usage:`n`n> SandboxToys2 [/box:boxname]`nWithout arguments, SandboxToys2 opens its main menu, waits for a selection, execute it and then exits immediately.`nThe optional argument /box:boxname can be used to restrict the menu to a single sandbox.`n`n> SandboxToys2 [/box:boxname] /tray`nSandboxToys2 stays resident in the tray.`nClick the tray icon to launch the main SandboxToys Menu.`nRight-click the tray icon to exit SandboxToys.`n`n> SandboxToys2 [/box:boxname] ""existing file, folder or shortcut""`nCreates a new sandboxed shortcut on the desktop. If the /box:boxname argument is not present, you will need to select the target box in a menu.`nIt is recommended to create a shortcut to SandboxToys in your SendTo folder to easily create sandboxed shortcuts to any file or folder.`nYour SendTo folder should be:`n""%appdata%\Microsoft\Windows\SendTo""`n`nNote: The SandboxToys2.ini file holds the settings of SandboxToys. It should be in ""%APPDATA%\SandboxToys2\"" or in the same folder than the SandboxToys2 executable. The name of the INI file is the same than the name of the SandboxToys2 executable file, so if you rename SandboxToys2.exe, you should rename also SandboxToys2.ini.`nSimilarly, the name of the ""SandboxToys2_UserTools"" folder depends of the name of SandboxToys2.exe, and it should be also in your APPDATA folder or in the SandboxToys2.exe folder.`nThis allows you to run several instances of SandboxToys2 with different configurations and/or user tools.")
}

DummyMenuHandler(ItemName, ItemPos, MyMenu)
{
}

ExitMenuHandler(ItemName, ItemPos, MyMenu)
{
    ExitApp
}
