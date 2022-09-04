#UseHook off
#persistent
#singleinstance off

version = 2.1
; SandboxToys: Main Menu
; Author: r0lZ
; Developed and compiled with AHK_Lw v 1.1.34.04 in Sep 2022.
; Tested under Win10 x64 with Sandboxie v1.32.
; AHK_Lw is a build of AutoHotkey supporting unicode and icons in menus:
; http://www.autohotkey.net/~Lexikos/AutoHotkey_L/
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

SplitPath, A_ScriptName, , , , nameNoExt

; Settings
; Note: these values are overwritten if SandboxToys.ini exists in the directrory
; containing the script, in %appdata% or in %appdata%\SandboxToys2\
smalliconsize = 16  ; other icons
largeiconsize = 32  ; sandbox icons
seperatedstartmenus = 0
includeboxnames = 1
trayiconfile =
trayiconnumber = 1
sbcommandpromptdir = `%userprofile`%


inidir       = %A_ScriptDir%
sbtini       = %A_ScriptDir%\%nameNoExt%.ini
regconfig    = %A_ScriptDir%\%nameNoExt%_RegConfig.cfg
ignorelist   = %A_ScriptDir%\%nameNoExt%_Ignore_
usertoolsdir = %A_ScriptDir%\%nameNoExt%_UserTools
if (NOT FileExist(sbtini))
{
    inidir       = %appdata%\SandboxToys2
    sbtini       = %inidir%\%nameNoExt%.ini
    regconfig    = %inidir%\%nameNoExt%_RegConfig.cfg
    ignorelist   = %inidir%\%nameNoExt%_Ignore_
    usertoolsdir = %inidir%\%nameNoExt%_UserTools
    if (NOT FileExist(inidir))
        FileCreateDir, %inidir%
}
if (NOT FileExist(usertoolsdir))
    FileCreateDir, %usertoolsdir%

if (FileExist(sbtini)) {
    IniRead, largeiconsize,       %sbtini%, AutoConfig, LargeIconSize,       %largeiconsize%
    IniRead, smalliconsize,       %sbtini%, AutoConfig, SmallIconSize,       %smalliconsize%
    IniRead, seperatedstartmenus, %sbtini%, AutoConfig, SeperatedStartMenus, %seperatedstartmenus%
    IniRead, includeboxnames,     %sbtini%, AutoConfig, IncludeBoxNames,     %includeboxnames%
    IniRead, trayiconfile,        %sbtini%, UserConfig, TrayIconFile,        %trayiconfile%
    IniRead, trayiconnumber,      %sbtini%, UserConfig, TrayIconNumber,      %trayiconnumber%
    IniRead, sbcommandpromptdir,  %sbtini%, UserConfig, SandboxedCommandPromptDir, %sbcommandpromptdir%
}
else
{
    IniWrite, %largeiconsize%,       %sbtini%, AutoConfig, LargeIconSize
    IniWrite, %smalliconsize%,       %sbtini%, AutoConfig, SmallIconSize
    IniWrite, %seperatedstartmenus%, %sbtini%, AutoConfig, SeperatedStartMenus
    IniWrite, %includeboxnames%,     %sbtini%, AutoConfig, IncludeBoxNames
    IniWrite, %trayiconfile%,        %sbtini%, UserConfig, TrayIconFile
    IniWrite, %trayiconnumber%,      %sbtini%, UserConfig, TrayIconNumber
    IniWrite, %sbcommandpromptdir%,  %sbtini%, UserConfig, SandboxedCommandPromptDir
}
if (trayiconfile == "ERROR")
    trayiconfile =

if (NOT A_IsCompiled && trayiconfile == "") {
    tmp = %A_ScriptDir%\SandboxToys2.ico
    if (FileExist(tmp))
        trayiconfile := tmp
    tmp = %A_ScriptDir%\%nameNoExt%.ico
    if (FileExist(tmp))
        trayiconfile := tmp
}


; some useful constants
setWorkingDir %A_ScriptDir%
title = SandboxToys v%version% by r0lZ
if (nameNoExt != "SandboxToys")
    title = %title% (%nameNoExt%)

A_nl = `n
A_Quotes = "
shell32  = %A_WinDir%\system32\shell32.dll
imageres = %A_Windir%\system32\imageres.dll
explorer = %A_WinDir%\system32\explorer.exe

; we need the %SID% and %SESSION% variables, supported by Sandboxie,
; but not directly available as Windows environment variables.
; Get them from the registry.
; %SID%:
Loop, HKEY_CURRENT_USER, Software\Microsoft\Protected Storage System Provider, 1, 0
{
    if (A_LoopRegType == "KEY") {
        SID = %A_LoopRegName%
        break
    }
}
; %SESSION%:
RegRead, SESSION, HKEY_CURRENT_USER, Volatile Environment, SESSION
if (SESSION == "" || SESSION == "Console")
    SESSION = 0



if (NOT A_IsUnicode) {
    msgBox, 16, %title%, This program must be run under the AutoHotkey_L (AHK_Lw) build of AutoHotkey.
    ExitApp
}

; find Sandboxie's installation dir
RegRead, imagepath, HKEY_LOCAL_MACHINE, SYSTEM\CurrentControlSet\services\SbieSvc, ImagePath
imagepath := Trim(imagepath,A_Quotes)
splitpath, imagepath, , sbdir
start    = %sbdir%\Start.exe
sbiectrl = %sbdir%\SbieCtrl.exe
if (! FileExist(sbiectrl))
{
    MsgBox 16, %title%, Can't find Sandboxie installation folder.  Sorry.
    ExitApp
}

; find Sandboxie's INI file in %A_WinDir% and in Sandboxie's install dir
ini = %A_WinDir%\Sandboxie.ini
if (! FileExist(ini))
{
    ini = %sbdir%\Sandboxie.ini
    if (! FileExist(ini))
    {
        MsgBox, 16, %title%, Can't find Sandboxie.ini.
        ExitApp
    }
}

; get current Sandboxes installation path in the INI file.
; If it is not defined, assumes the default path.
IniRead, sandboxes_path, %ini%, GlobalSettings, FileRootPath, %systemdrive%\Sandbox\`%USER`%\`%SANDBOX`%
sandboxes_path := expandEnvVars(sandboxes_path)

; Get the array of sandboxes (requires AHK_L)
sandboxes_array := Object()
getSandboxesArray(sandboxes_array,ini)

; parse command line
; If one argument is passed and it's a file or folder,
; creates a sandboxed shortcut to it on the desktop and exit
traymode = 0
singlebox = ""
singleboxmode = 0
startupfile := ""
if 0 >= 1
{
    mainarg = %1%
    if (SubStr(mainarg, 1, 5) == "/box:") {
        singlebox := SubStr(mainarg, 6)
        singleboxmode = 1
        if 0 >= 2
            mainarg = %2%
        else
            mainarg =
    }
    if (mainarg == "/tray") {
        traymode = 1
    } else if (mainarg == "/makeregconfig") {
        err = 0
        if (singleboxmode == 0)
            err = 1
        if (err)
            MsgBox, 16, %title%, Required box argument missing.`nUsage to recreate the registry config file:`n%nameNoExt% /box:boxname /makeregconfig`nThe box MUST be empty!
        else
            MakeRegConfig(singlebox)
        ExitApp
    } else {
        Menu, Tray, NoIcon
        startupfile := mainarg
    }
}
if (startupfile != "")
{
    startupfile = %1%
    startupfile := Trim(startupfile, A_Quotes)
    If (NOT FileExist(startupfile))
    {
        GoSub, CmdLineHelp
        ExitApp
    }
    numboxes := sandboxes_array[0]
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
    numboxes := sandboxes_array[0]
    emptybox =
    Loop, %numboxes%
    {
        b := sandboxes_array[A_Index,"name"]
        exist := sandboxes_array[b,"exist"]
        if (NOT exist)
        {
            emptybox := b
            break
        }
    }
    if (emptybox != "")
    {
        MakeRegConfig(emptybox)
        msg = SandboxToys has generated the registry configuration file`n"%regconfig%"`n`n
        msg = %msg%That file is necessary to exclude the registry keys and values
        msg = %msg% that Sandboxie needs to create in the sandbox for its own use
        msg = %msg% from the output of the "Registry List and Export" and "Watch
        msg = %msg% Registry Changes" functions.`n`n
        msg = %msg%SandboxToys needs an EMPTY sandbox to create that file.  The box
        msg = %msg% "%emptybox%" is empty, and has been used to generate the file.`n`n
        msg = %msg%If you need to recreate that file, just delete the file, be sure
        msg = %msg% to delete a sandbox, and launch SandboxToys again.  You should see
        msg = %msg% this dialog again.
        MsgBox, 64, %title%, %msg%
        runWait, %start% /box:%emptybox% delete_sandbox, , UseErrorLevel
    }
}

if (traymode) {
    Menu, Tray, Nostandard
    Menu, Tray, Add, About and Help, MainHelpMenuHandler
    setMenuIcon("Tray", "About and Help", shell32, 24, smalliconsize)
    Menu, Tray, Add, Exit, ExitMenuHandler
    setMenuIcon("Tray", "Exit", shell32, 28, smalliconsize)
    Menu, Tray, Add
    Menu, Tray, Add, SandboxToys menu, BuildMainMenu
    setMenuIcon("Tray", "SandboxToys menu", sbiectrl, 1, smalliconsize)
    if (trayiconfile != "") {
        if (trayiconnum == "")
            trayiconnum = 1
        menu, %menu%, UseErrorLevel, on
        Menu, Tray, Icon, %trayiconfile%, %trayiconnum%, 1
        menu, %menu%, UseErrorLevel, off
    }
    Menu, Tray, Default, SandboxToys menu
    Menu, Tray, Click, 1
    if (singleboxmode)
        Menu, Tray, Tip, %title%`nBox :  %singlebox%
    else
        Menu, Tray, Tip, %title%
} else {
    GoSub, BuildMainMenu
    ExitApp
}


Return

; ######################################################
; No arguments, or called from tray: build the main menu
; ######################################################

BuildMainMenu:
    if (traymode)
    {
        sandboxes_array := Object()
        getSandboxesArray(sandboxes_array,ini)
    }

    ; Init the arrays of menu commands and icons (requires AHK_L)
    menucommands := Object()
    menuicons    := Object()

    Menu, ST2MainMenu, Add
    Menu, ST2MainMenu, DeleteAll

    ; Main loop: process all sandboxes
    numboxes := sandboxes_array[0]
    if (numboxes == 1) {
        singleboxmode = 1
        singlebox := sandboxes_array[1,"name"]
    }

    ; Build the Main menu
    loop, %numboxes%
    {
        box             := sandboxes_array[A_Index,"name"]
        boxpath         := sandboxes_array[box,"path"]
        boxexist        := sandboxes_array[box,"exist"]
        dropadminrights := sandboxes_array[box,"DropAdminRights"]

        if (boxexist)
            boxlabel = %box%
        else
            boxlabel = %box% (empty)

        if (singleboxmode && box != singlebox)
            continue

        Menu, %box%_ST2MenuBox, Add
        Menu, %box%_ST2MenuBox, DeleteAll
        Menu, %box%_ST2StartMenu, Add
        Menu, %box%_ST2StartMenu, DeleteAll
        Menu, %box%_ST2StartMenuAU, Add
        Menu, %box%_ST2StartMenuAU, DeleteAll
        Menu, %box%_ST2StartMenuCU, Add
        Menu, %box%_ST2StartMenuCU, DeleteAll
        Menu, %box%_ST2Desktop, Add
        Menu, %box%_ST2Desktop, DeleteAll
        Menu, %box%_ST2QuickLaunch, Add
        Menu, %box%_ST2QuickLaunch, DeleteAll
        Menu, %box%_ST2MenuExplore, Add
        Menu, %box%_ST2MenuExplore, DeleteAll
        Menu, %box%_ST2MenuTools, Add
        Menu, %box%_ST2MenuTools, DeleteAll

        if (singleboxmode) {
            Menu, %singlebox%_ST2MenuBox, Add, Box  %boxlabel%, DummyMenuHandler
            Menu, %singlebox%_ST2MenuBox, Disable, Box  %boxlabel%
            if (boxexist) {
                setMenuIcon(singlebox "_ST2MenuBox", "Box  " boxlabel, sbiectrl, 3, smalliconsize)
            } else {
                setMenuIcon(singlebox "_ST2MenuBox", "Box  " boxlabel, sbiectrl, 10, smalliconsize)
            }
            Menu, %singlebox%_ST2MenuBox, Add
        }

        added_menus = 0
        if (boxexist) {
            ; build path to the Public (All Users) directory (and removes the ":")
            public_dir = %public%
            if (public_dir != "") {
                idx := InStr(public_dir, ":")
                if (idx) {
                    public_dir := substr(public_dir,1,idx-1) . substr(public_dir,idx+1)
                }
            }
            ; Build the Box / Start Menu(s)
            if (seperatedstartmenus) {
                ; get shortcut files from the All Users StartMenu (top section)
                tmp1 = %boxpath%\user\all\Microsoft\Windows\Start Menu
                topicons := getFilenames(tmp1, 0)
                topicons := Trim(topicons, A_nl)
                Sort, topicons, CL D`n
                if (topicons) {
                    numtopicons := addCmdsToMenu(box, "ST2StartMenuAU", topicons)
                    Menu, %box%_ST2MenuBox, Add,  Start Menu (all users), :%box%_ST2StartMenuAU
                    setMenuIcon(box "_ST2MenuBox", "Start Menu (all users)", shell32, 20, largeiconsize)
                    added_menus = 1
                }
                ; and from the Programs section
                tmp1 = %boxpath%\user\all\Microsoft\Windows\Start Menu\Programs
                files1 := getFilenames(tmp1, 1)
                if (files1 && topicons)
                    Menu, %box%_ST2StartMenuAU, Add
                menunum = 0
                numicons := buildProgramsMenu1(box, "ST2StartMenuAU", tmp1)
                if (numicons)
                    added_menus = 1
                if (topicons == "" && numicons > 0) {
                    Menu, %box%_ST2MenuBox, Add,  Start Menu (all users), :%box%_ST2StartMenuAU
                    setMenuIcon(box "_ST2MenuBox", "Start Menu (all users)", shell32, 20, largeiconsize)
                }

                ; get shortcut files from the Current User StartMenu (top section)
                tmp1 = %boxpath%\user\current\AppData\Roaming\Microsoft\Windows\Start Menu
                topicons := getFilenames(tmp1, 0)
                topicons := Trim(topicons, A_nl)
                Sort, topicons, CL D`n
                if (topicons) {
                    numtopicons := addCmdsToMenu(box, "ST2StartMenuCU", topicons)
                    Menu, %box%_ST2MenuBox, Add,  Start Menu (current user), :%box%_ST2StartMenuCU
                    setMenuIcon(box "_ST2MenuBox", "Start Menu (current user)", shell32, 20, largeiconsize)
                    added_menus = 1
                }
                ; and from the Programs section
                tmp1 = %boxpath%\user\current\AppData\Roaming\Microsoft\Windows\Start Menu\Programs
                files1 := getFilenames(tmp1, 1)
                if (files1 && topicons)
                    Menu, %box%_ST2StartMenuCU, Add
                menunum = 0
                numicons := buildProgramsMenu1(box, "ST2StartMenuCU", tmp1)
                if (numicons)
                    added_menus = 1
                if (topicons == "" && numicons > 0) {
                    Menu, %box%_ST2MenuBox, Add,  Start Menu (current user), :%box%_ST2StartMenuCU
                    setMenuIcon(box "_ST2MenuBox", "Start Menu (current user)", shell32, 20, largeiconsize)
                }

                ; process Public Desktop
                tmp1 = %boxpath%\drive\%public_dir%\Desktop
                menunum = 0
                m := buildProgramsMenu1(box, "ST2DesktopAU", tmp1)
                if (m) {
                    added_menus = 1
                    Menu, %box%_ST2MenuBox, Add,  Desktop (all users), :%box%_%m%
                    setMenuIcon(box "_ST2MenuBox", "Desktop (all users)", shell32, 35, largeiconsize)
                }
                ; process User's Desktop
                tmp1 = %boxpath%\user\current\Desktop
                menunum = 0
                m := buildProgramsMenu1(box, "ST2DesktopCU", tmp1)
                if (m) {
                    added_menus = 1
                    Menu, %box%_ST2MenuBox, Add,  Desktop (current user), :%box%_%m%
                    setMenuIcon(box "_ST2MenuBox", "Desktop (current user)", shell32, 35, largeiconsize)
                }
            } else {
                ; get shortcut files from the StartMenu (top section)
                tmp1 = %boxpath%\user\all\Microsoft\Windows\Start Menu
                files1 := getFilenames(tmp1, 0)
                tmp2 = %boxpath%\user\current\AppData\Roaming\Microsoft\Windows\Start Menu
                files2 := getFilenames(tmp2, 0)
                topicons = %files1%`n%files2%
                topicons := Trim(topicons, A_nl)
                Sort, topicons, CL D`n
                if (topicons) {
                    numtopicons := addCmdsToMenu(box, "ST2StartMenu", topicons)
                    Menu, %box%_ST2MenuBox, Add,  Start Menu, :%box%_ST2StartMenu
                    setMenuIcon(box "_ST2MenuBox", "Start Menu", shell32, 20, largeiconsize)
                    added_menus = 1
                }
                ; and from the Programs section
                tmp1 = %boxpath%\user\all\Microsoft\Windows\Start Menu\Programs
                files1 := getFilenames(tmp1, 1)
                tmp2 = %boxpath%\user\current\AppData\Roaming\Microsoft\Windows\Start Menu\Programs
                files2 := getFilenames(tmp2, 1)
                if ((files1 || files2) && topicons)
                    Menu, %box%_ST2StartMenu, Add
                menunum = 0
                numicons := buildProgramsMenu2(box, "ST2StartMenu", tmp1, tmp2)
                if (numicons)
                    added_menus = 1
                if (topicons == "" && numicons > 0) {
                    Menu, %box%_ST2MenuBox, Add,  Start Menu, :%box%_ST2StartMenu
                    setMenuIcon(box "_ST2MenuBox", "Start Menu", shell32, 20, largeiconsize)
                }

                ; process Desktop
                tmp1 = %boxpath%\drive\%public_dir%\Desktop
                files1 := getFilenames(tmp1, 1)
                tmp2 = %boxpath%\user\current\Desktop
                files2 := getFilenames(tmp2, 1)
                if ((files1 || files2) && topicons)
                     Menu, %box%_ST2MenuBox, Add
                menunum = 0
                m := buildProgramsMenu2(box, "ST2Desktop", tmp1, tmp2)
                if (m) {
                    added_menus = 1
                    Menu, %box%_ST2MenuBox, Add,  Desktop, :%box%_%m%
                    setMenuIcon(box "_ST2MenuBox", "Desktop", shell32, 35, largeiconsize)
                }
            }

            ; process QuickLaunch
            tmp1 = %boxpath%\user\current\AppData\Roaming\Microsoft\Internet Explorer\Quick Launch
            menunum = 0
            m := buildProgramsMenu1(box, "ST2QuickLaunch", tmp1)
            if (m) {
                added_menus = 1
                Menu, %box%_ST2MenuBox, Add,  QuickLaunch, :%box%_%m%
                setMenuIcon(box "_ST2MenuBox", "QuickLaunch", shell32, 215, largeiconsize)
            }
            if (added_menus)
                Menu, %box%_ST2MenuBox, Add
        }

        ; add sandboxie's start menu and run dialob in all boxes
        Menu, %box%_ST2MenuBox, Add,  Sandboxie's Start Menu, StartMenuMenuHandler
        setMenuIcon(box "_ST2MenuBox", "Sandboxie's Start Menu", sbiectrl, 1, largeiconsize)
        Menu, %box%_ST2MenuBox, Add,  Sandboxie's Run Dialog, RunDialogMenuHandler
        setMenuIcon(box "_ST2MenuBox", "Sandboxie's Run Dialog", sbiectrl, 1, largeiconsize)
        Menu, %box%_ST2MenuBox, Add
        if (NOT boxexist) {
            Menu, %box%_ST2MenuBox, Add, Explore (Sandboxed),   SExploreMenuHandler
            setMenuIcon(box "_ST2MenuBox", "Explore (Sandboxed)", explorer, 1, largeiconsize)
            Menu, %box%_ST2MenuBox, Add,  New Sandboxed Shortcut, NewShortcutMenuHandler
            setMenuIcon(box "_ST2MenuBox", "New Sandboxed Shortcut", imageres, 155, largeiconsize)
        }
        if (boxexist) {
            ; Add the Explore items to the Box menu
            Menu, %box%_ST2MenuExplore, Add,  Unsandboxed, UExploreMenuHandler
            setMenuIcon(box "_ST2MenuExplore", "Unsandboxed", explorer, 1, smalliconsize)
            Menu, %box%_ST2MenuExplore, Add,  Unsandboxed`, restricted, URExploreMenuHandler
            setMenuIcon(box "_ST2MenuExplore", "Unsandboxed, restricted", explorer, 1, smalliconsize)
            Menu, %box%_ST2MenuExplore, Add,  Sandboxed,   SExploreMenuHandler
            setMenuIcon(box "_ST2MenuExplore", "Sandboxed",   explorer, 1, smalliconsize)
            Menu, %box%_ST2MenuExplore, Add
            Menu, %box%_ST2MenuExplore, Add, Files List and Export, ListFilesMenuHandler
            setMenuIcon(box "_ST2MenuExplore", "Files List and Export", shell32, 172, smalliconsize)
            Menu, %box%_ST2MenuExplore, Add, Watch Files Changes, WatchFilesMenuHandler
            setMenuIcon(box "_ST2MenuExplore", "Watch Files Changes", shell32, 172, smalliconsize)
            Menu, %box%_ST2MenuBox, Add, Explore, :%box%_ST2MenuExplore
            setMenuIcon(box "_ST2MenuBox", "Explore", explorer, 1, largeiconsize)

            ; Add the Registry items to the Box menu
            Menu, %box%_ST2MenuReg, Add,  Registry Editor (unsandboxed), URegEditMenuHandler
            setMenuIcon(box "_ST2MenuReg", "Registry Editor (unsandboxed)", A_WinDir "\system32\regedit.exe", 1, smalliconsize)
            if (NOT dropadminrights) {
                Menu, %box%_ST2MenuReg, Add,  Registry Editor (sandboxed), SRegEditMenuHandler
                setMenuIcon(box "_ST2MenuReg", "Registry Editor (sandboxed)", A_WinDir "\system32\regedit.exe", 1, smalliconsize)
            }
            Menu, %box%_ST2MenuReg, Add
            Menu, %box%_ST2MenuReg, Add, Registry List and Export, ListRegMenuHandler
            setMenuIcon(box "_ST2MenuReg", "Registry List and Export", systemroot . "\system32\regedit.exe", 3, smalliconsize)
            Menu, %box%_ST2MenuReg, Add, Watch Registry Changes, WatchRegMenuHandler
            setMenuIcon(box "_ST2MenuReg", "Watch Registry Changes", systemroot . "\system32\regedit.exe", 3, smalliconsize)
            Menu, %box%_ST2MenuBox, Add, Registry, :%box%_ST2MenuReg
            setMenuIcon(box "_ST2MenuBox", "Registry", A_WinDir "\system32\regedit.exe", 1, largeiconsize)
            Menu, %box%_ST2MenuReg, Add
            Menu, %box%_ST2MenuReg, Add, Autostart programs in registry, ListAutostartsMenuHandler
            setMenuIcon(box "_ST2MenuReg", "Autostart programs in registry", systemroot . "\system32\regedit.exe", 2, smalliconsize)

            ; Build the Tools menu
            Menu, %box%_ST2MenuTools, Add,  New Sandboxed Shortcut, NewShortcutMenuHandler
            setMenuIcon(box "_ST2MenuTools", "New Sandboxed Shortcut", imageres, 155, smalliconsize)
            Menu, %box%_ST2MenuTools, Add
            Menu, %box%_ST2MenuTools, Add, Watch Files and Registry Changes, WatchFilesRegMenuHandler
            setMenuIcon(box "_ST2MenuTools", "Watch Files and Registry Changes", shell32, 172, smalliconsize)
            Menu, %box%_ST2MenuTools, Add
            Menu, %box%_ST2MenuTools, Add,  Command Prompt (unsandboxed), UCmdMenuHandler
            setMenuIcon(box "_ST2MenuTools", "Command Prompt (unsandboxed)", A_WinDir "\system32\cmd.exe", 1, smalliconsize)
            Menu, %box%_ST2MenuTools, Add,  Command Prompt (sandboxed),   SCmdMenuHandler
            setMenuIcon(box "_ST2MenuTools", "Command Prompt (sandboxed)", A_WinDir "\system32\cmd.exe", 1, smalliconsize)
            if (NOT dropadminrights) {
                Menu, %box%_ST2MenuTools, Add
                Menu, %box%_ST2MenuTools, Add,  Programs and Features, UninstallMenuHandler
                setMenuIcon(box "_ST2MenuTools", "Programs and Features", A_WinDir "\system32\appmgr.dll", 1, smalliconsize)
            }
            Menu, %box%_ST2MenuTools, Add
            Menu, %box%_ST2MenuTools, Add,  Terminate Sandboxed Programs!, TerminateMenuHandler
            setMenuIcon(box "_ST2MenuTools", "Terminate Sandboxed Programs!", shell32, 220, smalliconsize)
            Menu, %box%_ST2MenuTools, Add,  Delete Sandbox!, DeleteBoxMenuHandler
            setMenuIcon(box "_ST2MenuTools", "Delete Sandbox!", shell32, 132, smalliconsize)
            Menu, %box%_ST2MenuBox, Add, Tools, :%box%_ST2MenuTools
            setMenuIcon(box "_ST2MenuBox", "Tools", shell32, 36, largeiconsize)
        }

        ; Build the Main menu
        if (! singleboxmode) {
            Menu, ST2MainMenu, Add,  %boxlabel%, :%box%_ST2MenuBox
            if (boxexist) {
                setMenuIcon("ST2MainMenu", boxlabel, sbiectrl, 3, largeiconsize)
            } else {
                setMenuIcon("ST2MainMenu", boxlabel, sbiectrl, 10, largeiconsize)
            }
        }
    }

    if (singleboxmode)
        mainmenu = %singlebox%_ST2MenuBox
    else
        mainmenu = ST2MainMenu

    ; process User Tools
    menunum = 0
    m := buildProgramsMenu1("", "ST2UserTools", usertoolsdir)
    if (m) {
        Menu, %mainmenu%, Add
        Menu, %mainmenu%, Add,  User Tools, :_%m%
        setMenuIcon(mainmenu, "User Tools", imageres, 118, largeiconsize)
    }

    ; add Launch Sandboxie Control if it is not already running
    process, Exist, SbieCtrl.exe
    if (ErrorLevel == 0) {
        Menu, %mainmenu%, Add
        Menu, %mainmenu%, Add,  Launch Sandboxie Control, LaunchSbieCtrlMenuHandler
        setMenuIcon(mainmenu, "Launch Sandboxie Control", sbiectrl, 1, largeiconsize)
    }

    ; add Help & Options menu
    Menu, SBMenuSetup, Add, About and Help, MainHelpMenuHandler
    setMenuIcon("SBMenuSetup", "About and Help", shell32, 24, 16)
    Menu, SBMenuSetup, Add
    Menu, SBMenuSetup, Add, Large main-menu and box icons?, SetupMenuMenuHandler1
    if (largeiconsize > 16)
        Menu, SBMenuSetup, Check, Large main-menu and box icons?
    Menu, SBMenuSetup, Add, Large sub-menu icons?, SetupMenuMenuHandler2
    if (smalliconsize > 16)
        Menu, SBMenuSetup, Check, Large sub-menu icons?
    Menu, SBMenuSetup, Add, Seperated All Users menus?, SetupMenuMenuHandler3
    if (seperatedstartmenus)
        Menu, SBMenuSetup, Check, Seperated All Users menus?
    Menu, SBMenuSetup, Add
    Menu, SBMenuSetup, Add, Include [#BoxName] in shortcut names?, SetupMenuMenuHandler4
    if (includeboxnames)
        Menu, SBMenuSetup, Check, Include [#BoxName] in shortcut names?
    Menu, %mainmenu%, Add
    Menu, %mainmenu%, Add, Options, :SBMenuSetup
    setMenuIcon(mainmenu, "Options", shell32, 24, 16)

    ; show the menu and wait for user action
    Menu, %mainmenu%, Show

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
;  Object["boxname","path"] = complete, absolute path to the sandbox folder.
;  Object["boxname","exist"] = flag: true if the sandbox is not empty at the time of the check.
;  Object["boxname","DropAdminRights"] = flag: state of the DropAdminRights flag in the INI.
; Returns the number of sandboxes.
getSandboxesArray(array,ini)
{
    IniRead, sandboxes_path, %ini%, GlobalSettings, FileRootPath, %systemdrive%\Sandbox\`%USER`%\`%SANDBOX`%
    sandboxes_path := expandEnvVars(sandboxes_path)

    ; Requires AHK_Lw
    old_encoding = %A_FileEncoding%
    FileEncoding, UTF-16

    ; get the list of boxes in the INI and sort it
    boxes =
    Loop, Read, %ini%
    {
        if (SubStr(A_LoopReadLine, 1, 1) == "[" && SubStr(A_LoopReadLine, 0) == "]" && A_LoopReadLine != "[GlobalSettings]" && SubStr(A_LoopReadLine, 1, 14) != "[UserSettings_") {
            box := SubStr(A_LoopReadLine, 2, -1)
            boxes = %boxes%%box%,
        }
    }
    boxes := Trim(boxes, ",")   ; requires AHK_L
    Sort, boxes, CL D`,

    ; Requires AHK_Lw
    FileEncoding, %old_encoding%

    ; fills the array
    Loop, Parse, boxes, CSV
    {
        array[0] := A_Index
        array[A_Index,"name"] := A_LoopField
        StringReplace, path, sandboxes_path, `%SANDBOX`%, %A_LoopField%, All
        array[A_LoopField,"path"] := path
        test = %path%\RegHive
        array[A_LoopField,"exist"] := FileExist(test)
        ; since running the registry editor works with elevated privileges,
        ; checks if the box has DropAdminRights=y in the INI
        IniRead, dropadminrights, %ini%, %A_LoopField%, DropAdminRights, n
        if (dropadminrights == "y")
            array[A_LoopField,"DropAdminRights"] := 1
        else
            array[A_LoopField,"DropAdminRights"] := 0
    }
    Return % array[0]
}

; Prompts the user for a sandbox name.
; Returns "" if the user selects cancel or discard the menu.
getSandboxName(sandboxes_array, title, include_ask=false)
{
    global __box__, sbiectrl, largeiconsize
    numboxes := sandboxes_array[0]

    Menu, Menu, Add
    Menu, Menu, DeleteAll

    Menu, Menu, Add, %title%, DummyMenuHandler
    Menu, Menu, Disable, %title%
    Menu, Menu, Add
    loop, %numboxes%
    {
        box := sandboxes_array[A_Index,"name"]
        if (sandboxes_array[box,"exist"]) {
            Menu, Menu, Add, %box%, getSandboxNameBoxMenuHandler
            setMenuIcon("Menu", box, sbiectrl, 3, largeiconsize)
        } else {
            Menu, Menu, Add, %box% (empty), getSandboxNameBoxMenuHandler
            setMenuIcon("Menu", box " (empty)", sbiectrl, 10, largeiconsize)
        }
    }
    if (include_ask)
    {
        Menu, Menu, Add
        Menu, Menu, Add, Ask box at run time, getSandboxNameAskMenuHandler
        setMenuIcon("Menu", "Ask box at run time", sbiectrl, 1, largeiconsize)
    }
    Menu, Menu, Add
    Menu, Menu, Add, Cancel, getSandboxNameCancelMenuHandler
    Menu, Menu, Show

    return %__box__%
}
getSandboxNameBoxMenuHandler:
    __box__ := sandboxes_array[A_ThisMenuItemPos -2,"name"]
Return
getSandboxNameAskMenuHandler:
    __box__ = __ask__
Return
getSandboxNameCancelMenuHandler:
    __box__ =
Return

setMenuIcon(menu, item, iconfile, iconindex, largeiconsize)
{
    menu, %menu%, UseErrorLevel, on
    Menu, %menu%, Icon, %item%, %iconfile%, %iconindex%, %largeiconsize%
    rc := ErrorLevel
    menu, %menu%, UseErrorLevel, off
    return %rc%
}

getFilenames(directory, includeFolders)
{
    files =
    Loop, %directory%\*, %includeFolders%, 0
    {
        ; Excludes the hidden and system files from list
        attributes := A_LoopFileAttrib
        IfInString, %Attributes%, H
            Continue
        IfInString, %Attributes%, S
            Continue
        ; Excludes also the files deleted in the sandbox, but present in the "real world".
        ; They have a "magic" creation date of May 23, 1986, 17:47:02
        FileGetTime, creationTime, %A_LoopFileLongPath%, C
        if (creationTime == "19860523174702")
            Continue
        ; and keep regular directories and files
        IfInString, Attributes, D
        {
            SplitPath, A_LoopFileName, OutDirName
            files = %files%%OutDirName%:%A_LoopFileLongPath%`n
        } else {
            SplitPath, A_LoopFileName, , , , OutNameNoExt,
            files = %files%%OutNameNoExt%:%A_LoopFileLongPath%`n
        }
    }
    StringTrimRight, files, files, 1
    if (files)
        Sort, files, CL D`n Z
    Return %files%
}

; Build a menu with the files from a specific directory
buildProgramsMenu1(box, menuname, path)
{
    global smalliconsize, menunum

    if (menunum > 0)
        thismenuname = %menuname%_%menunum%
    else
        thismenuname = %menuname%

    numfiles = 0

;    path = %path%\*
    menufiles := getFilenames(path, 0)
    if (menufiles) {
        Sort, menufiles, CL D`n Z
        numfiles := addCmdsToMenu(box, thismenuname, menufiles)
    }
;    else if (numfiles == 0) {
;        numfiles = 1
;    }
    ; recurse
    menudirs := getFilenames(path, 2)

    if (menudirs) {
        Sort, menudirs, CL D`n Z
        Loop, parse, menudirs, `n
        {
            entry = %A_LoopField%
            idx   := InStr(entry, ":")
            label := subStr(entry, 1, idx-1)
            dir   := subStr(entry, idx+1)
            menunum ++
            newmenuname := buildProgramsMenu1(box, menuname, dir)
            if (newmenuname != "") {
                Menu, %box%_%thismenuname%, Add, %label%, :%box%_%newmenuname%
                setMenuIcon(box "_" thismenuname, label, A_WinDir "\system32\shell32.dll", 4, smalliconsize)
                numfiles ++
            }
        }
    }
    if (numfiles)
        return %thismenuname%
    else
        return ""
}

; Build a menu with the files from two specific directories by merging them together
buildProgramsMenu2(box, menuname, path1, path2)
{
    global smalliconsize, menunum
    A_Return = `n

    if (menunum > 0)
        thismenuname = %menuname%_%menunum%
    else
        thismenuname = %menuname%

    numfiles = 0

;    path1 = %path1%\*
;    path2 = %path2%\*

    ; process files
    menufiles1 := getFilenames(path1, 0)
    menufiles2 := getFilenames(path2, 0)
    menufiles = %menufiles1%`n%menufiles2%
    menufiles := Trim(menufiles, A_Return)
    if (menufiles) {
        Sort, menufiles, CL D`n
        numfiles := addCmdsToMenu(box, thismenuname, menufiles)
    }
;    else if (numfiles == 0) {
;        numfiles = 1
;    }


    ; recurse
    menudirs1 := getFilenames(path1, 2)
    menudirs2 := getFilenames(path2, 2)
    menudirs = %menudirs1%`n%menudirs2%
    menudirs := Trim(menudirs, A_Return)
    if (menudirs) {
        Sort, menudirs, CL D`n

        Loop, parse, menudirs, `n
        {
            entry = %A_LoopField%
            idx   := InStr(entry, ":")
            label := subStr(entry, 1, idx-1)
            dir   := subStr(entry, idx+1)
            dir_labels_%A_Index% := label
            dir_list_%A_Index%   := dir
            numdirs := A_Index
        }
        skip = 0
        loop, %numdirs%
        {
            if (skip)
            {
                skip = 0
                continue
            }
            menunum ++
            label := dir_labels_%A_Index%
            dir1  := dir_list_%A_Index%
            next := A_Index + 1
            nextlabel := dir_labels_%next%
            if  (nextlabel == label)
            {
                skip = 1
                dir2 := dir_list_%next%
                newmenuname := buildProgramsMenu2(box, menuname, dir1, dir2)
            }
            else
                newmenuname := buildProgramsMenu1(box, menuname, dir1)
            if (newmenuname) {
                Menu, %box%_%thismenuname%, Add, %label%, :%box%_%newmenuname%
                setMenuIcon(box "_" thismenuname, label, A_WinDir "\system32\shell32.dll", 4, smalliconsize)
                numfiles ++
            }
        }
    }
    if (numfiles)
        return %thismenuname%
    else
        return ""
}


; TODO: rewrite this stuff, too complicated
setIconFromSandboxedShortcut(box, shortcut, menuname, label, iconsize)
{
    global menuicons, imageres
    A_Quotes = "

    menuicons[menuname,label,"file"] := ""
    menuicons[menuname,label,"num"]  := ""

    ; get icon file and number in shortcut.
    ; If not specified, assumes it's the file pointed to by the shortcut
    SplitPath, shortcut, , , extension
    if (extension == "lnk") {
        FileGetShortcut, %shortcut%, target, , , , iconfile, iconnum
        if (iconnum == "")
            iconnum = 1
        if (iconfile == "") {
            iconfile = %target%
            iconnum = 1
        }
    } else {
        iconfile = %shortcut%
        iconnum = 1
    }
    iconfile := Trim(iconfile, A_Quotes)
    iconfile := expandEnvVars(iconfile)

    if (InStr(FileExist(iconfile), "D")) {
        setMenuIcon(menuname, label, imageres, 4, iconsize)
        menuicons[menuname,label,"file"] := imageres
        menuicons[menuname,label,"num"]  := 4
        return % imageres "," 4
    }

    boxfile := stdPathToBoxPath(box, iconfile)
    if (InStr(FileExist(boxfile), "D")) {
        setMenuIcon(menuname, label, imageres, 4, iconsize)
        menuicons[menuname,label,"file"] := imageres
        menuicons[menuname,label,"num"]  := 4
        return % imageres "," 4
    }
    if (FileExist(boxfile)) {
        iconfile := boxfile
    }

    if (iconfile == "")
        rc = 1
    else {
        rc := setMenuIcon(menuname, label, iconfile, iconnum, iconsize)
        menuicons[menuname,label,"file"] := iconfile
        menuicons[menuname,label,"num"]  := iconnum
    }
    if (rc) {
        ; If setMenuIcon failed, it's probably because the file pointed to by
        ; the link is a document without icons.
        ; Try to get the right icon reference in the registry.

        if (extension == "lnk") {
            SplitPath, target, , , extension
        } else {
            SplitPath, shortcut, , , extension
        }
        ; try to get the icon from the sandboxed registry first
        ; (will fail is nothing is running in the sandbox)
        RegRead, defaulticon, HKEY_USERS, Sandbox_%username%_%box%\machine\software\classes\.%extension%\DefaultIcon,
        if (defaulticon == "") {
            RegRead, keyval, HKEY_USERS, Sandbox_%username%_%box%\machine\software\classes\.%extension%,
            if (keyval != "") {
                RegRead, defaulticon, HKEY_USERS, Sandbox_%username%_%box%\machine\software\classes\%keyval%\DefaultIcon,
            }
        }
        if (defaulticon != "") {
            comaidx := InStr(defaulticon, ",", false, 0)
            if (comaidx > 0) {
                iconfile := SubStr(defaulticon, 1, comaidx-1)
                iconnum  := SubStr(defaulticon, comaidx+1)
            } else {
                iconfile = %defaulticon%
                iconnum  = 1
            }
            if (iconnum > 0) {
                iconfile := Trim(iconfile, A_Quotes)
                iconfile := expandEnvVars(iconfile)
                iconfile := stdPathToBoxPath(box, iconfile)
                rc := setMenuIcon(menuname, label, iconfile, iconnum, iconsize)
                menuicons[menuname,label,"file"] := iconfile
                menuicons[menuname,label,"num"]  := iconnum
            } else
                rc = 1
            if (rc == 0)
                return % iconfile "," iconnum
        }

        ; searches also in the unsandboxed registry
        RegRead, defaulticon, HKEY_CLASSES_ROOT, .%extension%\DefaultIcon,
        if (defaulticon == "") {
            RegRead, keyval, HKEY_CLASSES_ROOT, .%extension%,
            if (keyval == "InternetShortcut") {
                defaulticon = %A_Windir%\system32\url.dll,5
            } else if (keyval != "") {
                RegRead, defaulticon, HKEY_CLASSES_ROOT, %keyval%\DefaultIcon,
            }
        }
        if (defaulticon == "") {
            RegRead, percievedtype, HKEY_CLASSES_ROOT, .%extension%, PerceivedType
            if (percievedtype == "") {
                RegRead, keyval, HKEY_CLASSES_ROOT, .%extension%,
                if (keyval != "") {
                    RegRead, percievedtype, HKEY_CLASSES_ROOT, %keybal%, PerceivedType
                }
            }
            if (percievedtype == "document") {
                defaulticon = %imageres%,2
            }
            if (percievedtype == "system") {
                defaulticon = %imageres%,63
            }
            if (percievedtype == "text") {
                defaulticon = %imageres%,97
            }
            if (percievedtype == "audio") {
                defaulticon = %imageres%,125
            }
            if (percievedtype == "image") {
                defaulticon = %imageres%,126
            }
            if (percievedtype == "video") {
                defaulticon = %imageres%,127
            }
            if (percievedtype == "compressed") {
                defaulticon = %imageres%,165
            }
        }
        if (defaulticon != "") {
            if (defaulticon == "%1") {
                iconfile := shortcut
                iconnum  = 1
            } else {
                comaidx := InStr(defaulticon, ",", false, 0)
                if (comaidx > 0) {
                    iconfile := SubStr(defaulticon, 1, comaidx-1)
                    iconnum  := SubStr(defaulticon, comaidx+1)
                    if (iconnum < 0) {
                        iconnum := IndexOfIconResource(iconfile, iconnum)
                    } else {
                        iconnum ++
                    }
                }
            }
            iconfile := Trim(iconfile, A_Quotes)
            rc := setMenuIcon(menuname, label, iconfile, iconnum, iconsize)
            menuicons[menuname,label,"file"] := iconfile
            menuicons[menuname,label,"num"]  := iconnum
        } else
            rc = 1
        if (rc) {
            if (InStr(defaulticon, "%programfiles%")) {
                StringReplace, iconfile, iconfile, `%programfiles`%, %programw6432%
                rc := setMenuIcon(menuname, label, iconfile, iconnum, iconsize)
                menuicons[menuname,label,"file"] := iconfile
                menuicons[menuname,label,"num"]  := iconnum
            }
            if (rc) {
                StringReplace, iconfile, iconfile, `%programfiles`%, `%programfiles(x86)`%
                rc := setMenuIcon(menuname, label, iconfile, iconnum, iconsize)
                menuicons[menuname,label,"file"] := iconfile
                menuicons[menuname,label,"num"]  := iconnum
            }
            if (rc) {
                iconfile := expandEnvVars(iconfile)
                rc := setMenuIcon(menuname, label, iconfile, iconnum, iconsize)
                menuicons[menuname,label,"file"] := iconfile
                menuicons[menuname,label,"num"]  := iconnum
            }
        }
        if (rc || iconfile == "") {
            iconfile = %A_WinDir%\system32\shell32.dll
            iconfile := expandEnvVars(iconfile)
            if (extension == "exe")
                iconnum  = 3
            else
                iconnum  = 2
            rc := setMenuIcon(menuname, label, iconfile, iconnum, iconsize)
            menuicons[menuname,label,"file"] := iconfile
            menuicons[menuname,label,"num"]  := iconnum
        }
    }
    return % iconfile "," iconnum
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
        return false    ; break
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
        old := hIcon_%ext%_%hideshortcutoverlay%_%iconsize%
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
                hicon_%ext%_%hideshortcutoverlay%_%iconsize% := hicon
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
    static   h_menuDummy
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
        hbmColor := NumGet(buf,16)  ; used to measure the icon
        hbmMask  := NumGet(buf,12)  ; used to generate alpha data (if necessary)
    }

    if !(width && height) {
        if !hbmColor or !DllCall("GetObject","uint",hbmColor,"int",24,"uint",&buf)
            return 0
        width := NumGet(buf,4,"int"),  height := NumGet(buf,8,"int")
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
                {   ; Use icon mask to generate alpha data.
                    Loop, % height*width
                        if (NumGet(mask_bits, (A_Index-1)*4))
                            NumPut(0, pBits+(A_Index-1)*4)
                        else
                            NumPut(NumGet(pBits+(A_Index-1)*4) | 0xFF000000, pBits+(A_Index-1)*4)
                } else {   ; Make the bitmap entirely opaque.
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
stdPathToBoxPath(box, path)
{
    global sandboxes_path
    StringReplace, boxpath, sandboxes_path, `%SANDBOX`%, %box%, All
    outpath =
    userprofile = %userprofile%\
    if (SubStr(path, 1, strLen(userprofile)) == userprofile) {
        remain := SubStr(path, strLen(userprofile)+1)
        outpath = %boxpath%\user\current\%remain%
    }
    if (outpath == "") {
        allusersprofile = %allusersprofile%\
        if (SubStr(path, 1, strLen(allusersprofile)) == allusersprofile) {
            remain := SubStr(path, strLen(allusersprofile)+1)
            outpath = %boxpath%\user\all\%remain%
        }
    }
    if (outpath == "") {
        if (subStr(path, 2, 2) == ":\") {
            drive  := SubStr(path, 1, 1)
            remain := SubStr(path, 3)
            outpath = %boxpath%\drive\%drive%%remain%
        }
    }
    if (outpath == "") {
        outpath := path
    }
    return %outpath%
}

; converts a sandbox path to its equivalent in "the real world"
boxPathToStdPath(box, path)
{
    global sandboxes_path
    StringReplace, boxpath, sandboxes_path, `%SANDBOX`%, %box%, All
    if (SubStr(path, 1, strLen(boxpath)) == boxpath) {
        remain := SubStr(path, strLen(boxpath)+2)
        tmp = user\current\
        if (SubStr(remain, 1, strLen(tmp)) == tmp) {
            remain := SubStr(remain, strLen(tmp))
            path = %userprofile%%remain%
            return %path%
        }
        tmp = user\all\
        if (SubStr(remain, 1, strLen(tmp)) == tmp) {
            remain := SubStr(remain, strLen(tmp))
            path = %allusersprofile%%remain%
            return %path%
        }
        tmp = drive\
        if (SubStr(remain, 1, strLen(tmp)) == tmp) {
            remain := SubStr(remain, strLen(tmp)+1)
            driveletter = SubStr(remain, 1, 1)
            remain := SubStr(remain, 3)
            path = %driveletter%:\%remain%
            return %path%
        }
    }
    return %path%
}

; Add sandboxed commands in the main menu.
; filelist is a list of filenames seperated by newline characters.
addCmdsToMenu(box, menuname, fileslist)
{
    global menucommands, smalliconsize

    thismenu = %box%_%menuname%
    numentries = 0
    Loop, parse, fileslist, `n
    {
        entry = %A_LoopField%
        idx := InStr(entry, ":")
        label := subStr(entry, 1, idx-1)
        if (menucommands[thismenu,label] != "")
            label = %label% (2)
        exefile := subStr(entry, idx+1)
        Menu, %thismenu%, Add, %label%, RunProgramMenuHandler
        setIconFromSandboxedShortcut(box, exefile, thismenu, label, smalliconsize)
        numentries ++
        menucommands[thismenu,label] := exefile
    }
    return %numentries%
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

; execute a program under the control of sandboxie.
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

; creates a shortut on the (normal) desktop to run the program under the control of sandboxie.
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
    Return (SubStr(A_ThisMenu, 1, InStr(A_ThisMenu, "_ST2MenuReg")-1))
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
        iconnum  := SubStr(icon, idx+1)
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
    ; ensure that the box is in use, or the hive will not be loaded
    Run %start% /box:%box% run_dialog, , HIDE UseErrorLevel, run_pid

    ; wait til the registry hive has been loaded in the global registry
    boxkeypath = Sandbox_%username%_%box%\user\current\software\SandboxieAutoExec
    loop, 100
    {
        sleep, 50
        RegRead, keyvalueval, HKEY_USERS, %boxkeypath%
        if (NOT ErrorLevel)
            break
    }

    Return, %run_pid%
}

; This function closes the hidden Run dialog, so that Sandboxie can desactivate
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

        FormatTime, timeCreated,  %A_LoopFileTimeCreated%,  yyyy/MM/dd HH:mm:ss
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
ListFiles(box, path, comparefilename="")
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

    bp = %path%\user\current
    rp = %userprofile%
    if (InStr(FileExist(bp),"D"))
    {
        f := SearchFiles(bp, rp, path, ignoredDirs, ignoredFiles, comparedata)
        allfiles = %allfiles%%f%`n
    }

    Progress, 13
    bp = %path%\user\all
    rp = %allusersprofile%
    if (InStr(FileExist(bp),"D"))
    {
        f := SearchFiles(bp, rp, path, ignoredDirs, ignoredFiles, comparedata)
        allfiles = %allfiles%%f%`n
    }

    Progress, 16
    Loop, %path%\drive\*, 2, 0
    {
        drive := A_LoopFileName
        bp = %path%\drive\%A_LoopFileName%
        rp = %A_LoopFileName%:
        f := SearchFiles(bp, rp, path, ignoredDirs, ignoredFiles, comparedata)
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
            MsgBox, 64, %title%, No meaningfull files in box "%box%"!
        else
            MsgBox, 64, %title%, No new or modified files in box "%box%"!
        Return
    }

    if (LVLastSize == "") {
        SysGet, mon, MonitorWorkArea
        if (monRight == "") {
            width  := A_ScreenWidth - 300
            height := A_ScreenHeight - 300
        } else {
            width  := monRight - monLeft - 250
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

    Gui, Destroy
    Gui, +Resize
    Gui, Add, Text, W900 vMainLabel, Find Files...

    Menu, FileMenu, Add
    Menu, FileMenu, DeleteAll
    Menu, FileMenu, Add, &Copy Checkmarked Files To..., GuiLVFilesSaveTo
    Menu, FileMenu, Add, Save Checkmarked Entries as CSV &Text, GuiLVFilesSaveAsText
    Menu, FileMenu, Add
    Menu, FileMenu, Add, Add Shortcuts to Checkmarked Files to Sandboxed Start &Menu, GuiLVFilesToStartMenu
    Menu, FileMenu, Add, Add Shortcuts to Checkmarked Files to Sandboxed &Desktop, GuiLVFilesToDesktop
    Menu, FileMenu, Add, Create Sandboxed &Shortcuts to Checkmarked Files on your Real Desktop, GuiLVFilesShortcut

    Menu, EditMenu, Add
    Menu, EditMenu, DeleteAll
    Menu, EditMenu, Add, &Clear All Checkmarks, GuiLVClearAllCheckmarks
    Menu, EditMenu, Add, &Toggle All Checkmarks, GuiLVToggleAllCheckmarks
    Menu, EditMenu, Add, Toggle &Selected Checkmarks, GuiLVToggleSelected
    Menu, EditMenu, Add
    Menu, EditMenu, Add, &Hide Selected Entries, GuiLVHideSelected
    Menu, EditMenu, Add
    Menu, EditMenu, Add, Add Selected &Files to Ignore List, GuiLVIgnoreSelectedFiles
    Menu, EditMenu, Add, Add Selected &Dirs to Ignore List,  GuiLVIgnoreSelectedDirs

    Menu, LVMenuBar, Add
    Menu, LVMenuBar, DeleteAll
    Menu, LVMenuBar, Add, &File, :FileMenu
    Menu, LVMenuBar, Add, &Edit, :EditMenu
    Gui, Menu, LVMenuBar

    Menu, PopupMenu, Add
    Menu, PopupMenu, DeleteAll
    Menu, PopupMenu, Add, Copy To..., GuiLVCurrentFileSaveTo
    Menu, PopupMenu, Add, Open in Sandbox, GuiLVCurrentFileRun
    Menu, PopupMenu, Add
    Menu, PopupMenu, Add, Open Unsandboxed Container, GuiLVCurrentFileOpenContainerU
    Menu, PopupMenu, Add, Open Sandboxed Container, GuiLVCurrentFileOpenContainerS
    Menu, PopupMenu, Add
    Menu, PopupMenu, Add, Add Shortcut on Sandbox Start Menu, GuiLVCurrentFileToStartMenu
    Menu, PopupMenu, Add, Add Shortcut on Sandbox Desktop, GuiLVCurrentFileToDesktop
    Menu, PopupMenu, Add, Create Sandboxed Shortcut on Real Desktop, GuiLVCurrentFileShortcut
    Menu, PopupMenu, Add
    Menu, PopupMenu, Add, Toggle Checkmark, GuiLVToggleCurrent
    Menu, PopupMenu, Add
    Menu, PopupMenu, Add, Hide from this list, GuiLVHideCurrent
    Menu, PopupMenu, Add
    Menu, PopupMenu, Add, Add File to Ignore List, GuiLVIgnoreCurrentFile
    Menu, PopupMenu, Add, Add Folder to Ignore List, GuiLVIgnoreCurrentDir
    Menu, PopupMenu, Add, Add Sub-Folder to Ignore List..., GuiLVIgnoreCurrentSubDir


    Gui, Add, ListView, X10 Y30 %LVLastSize% Checked Count%numrows% gGuiLVFileMouseEventHandler vMyListView AltSubmit, Status|File|Path|Size|Attribs|Created|Modified|Accessed|Extension|Sandbox path

    ; icons array
    ImageListID1 := IL_Create(10)
    LV_SetImageList(ImageListID1)

    Progress, 20, Please wait..., Building list of files`nin box "%box%"., %title%

    ; add entries in listview
    nummodified = 0
    numadded = 0
    numdeleted = 0
    sep := A_Tab
    GuiControl, -Redraw, MyListView
    loop, parse, allfiles, `n
    {
        entry := A_LoopField
        prog := round(80 * A_Index / numfiles) + 20
        if (prog != old_prog)
        {
            Progress, %prog%
            sleep 1
            old_prog = %prog%
        }

        loop, parse, entry, %sep%
        {
            if (A_Index == 1)
            {
                St = %A_LoopField%
                deleted = 0
                if (St == "#")
                    nummodified ++
                else if (St == "+")
                    numadded ++
                else if (St == "-")
                {
                    numdeleted ++
                    deleted = 1
                }
            }
            else if (A_Index == 2)
                SplitPath, A_LoopField, OutFileName, OutDir, OutExtension
            else if (A_Index == 3)
                Attribs = %A_LoopField%
            else if (A_Index == 4)
                Size = %A_LoopField%
            else if (A_Index == 5)
                Created = %A_LoopField%
            else if (A_Index == 6)
                Modified = %A_LoopField%
            else if (A_Index == 7)
                Accessed = %A_LoopField%
            else if (A_Index == 8)
                BoxPath = %A_LoopField%
        }
        if (St == "-")
            Created =
        iconfile = %path%\%BoxPath%\%OutFileName%
        if (! FileExist(iconfile))
            iconfile := boxPathToStdPath(box, iconfile)

        hIcon := GetAssociatedIcon(iconfile, false, 16, box, deleted)
        IconNumber := DllCall("ImageList_ReplaceIcon", "uint", ImageListID1, "int", -1, "uint", hIcon) + 1
        LV_Add("Icon" . IconNumber, St . A_Space, OutFileName, OutDir, Size, Attribs, Created, Modified, Accessed, OutExtension, BoxPath)
    }
    Progress, 100
    Sleep, 50

    LV_ModifyCol()
    LV_ModifyCol(4, "Integer")

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
    msg = %msg%.  Double-click an entry to copy the file to the desktop.
    GuiControl, , MainLabel, %msg%

    Progress, OFF
    Gui, Show, , %title%, Files in box "%box%"
    GuiControl, +Redraw, MyListView

    guinotclosed = 1
    while (guinotclosed)
        Sleep 1000
    SaveNewIgnoredItems("files")

    return
}

GuiSize:
    if A_EventInfo = 1  ; The window has been minimized.  No action needed.
        return
    LVLastSize := "W" . (A_GuiWidth - 20) . " H" . (A_GuiHeight - 40)
    GuiControl, Move, MyListView, %LVLastSize%
return

GuiLVFileMouseEventHandler:
    row := A_EventInfo
    if (row == 0)
        Return

    if (A_GuiEvent == "DoubleClick") {
        GoSub, GuiLVCurrentFileSaveTo
    }
    if (A_GuiEvent == "RightClick") {
        Menu, PopupMenu, Show
    }
Return

; Copy To...
GuiLVCurrentFileSaveTo:
    LV_GetText(LVFileName,  row, 2)
    LV_GetText(LVExtension, row, 9)
    LV_GetText(LVFilePath,  row, 10)
    boxpath := sandboxes_array[box,"path"]
    Gui, +OwnDialogs
    if (! InStr(FileExist(DefaultFolder . "\"), "D"))
        DefaultFolder = %userprofile%\Desktop
    FileSelectFile, filename, S16, %DefaultFolder%\%LVFileName%, Copy "%LVFileName%" from sandbox to..., %LVExtension% files (*.%LVExtension%)
    if (filename == "")
        Return
    FileCopy, %boxpath%\%LVFilePath%\%LVFileName%, %filename%, 1
    SplitPath, filename, , DefaultFolder
Return

; Open in Sandbox
GuiLVCurrentFileRun:
    LVCurrentFileRun(row, box, sandboxes_array[box,"path"])
Return
LVCurrentFileRun(row, box, boxpath)
{
    global start, title
    LV_GetText(LVFileName,   row, 2)
    LV_GetText(LVPath, row, 10)
    Filename = %boxpath%\%LVPath%\%LVFileName%
    old_pwd = %A_WorkingDir%
    SetWorkingDir, %boxpath%\%LVPath%
    run, "%start%" /box:%box% "%Filename%", , UseErrorLevel
    MsgBox, 64, %title%, Running "%FileName%" in box %box%.`n`nPlease wait..., 3
    SetWorkingDir, %old_pwd%
    Return
}
; Open Unsandboxed Container
GuiLVCurrentFileOpenContainerU:
    GuiLVCurrentFileOpenContainer(row, box, sandboxes_array[box,"path"], "u")
Return
; Open Sandboxed Container
GuiLVCurrentFileOpenContainerS:
    GuiLVCurrentFileOpenContainer(row, box, sandboxes_array[box,"path"], "s")
Return
GuiLVCurrentFileOpenContainer(row, box, boxpath, mode)
{
    global start, title
    Gui, +OwnDialogs
    if (mode == "u")
    {
        LV_GetText(CurPath, row, 10)
        Curpath = %boxpath%\%CurPath%
        run, "%Curpath%", , UseErrorLevel
    }
    else
    {
        LV_GetText(LVBoxFile, row, 2)
        LV_GetText(CurPath, row, 3)
        run, "%start%" /box:%box% "%Curpath%", , UseErrorLevel
        MsgBox, 64, %title%, Opening container of "%LVBoxFile%" in box %box%.`n`nPlease wait..., 3
    }
    Return
}

; Add Shortcut in Sandbox Start Menu
GuiLVCurrentFileToStartMenu:
    GuiLVCurrentFileToStartMenuOrDesktop(row, box, sandboxes_array[box,"path"], "startmenu")
Return
; Add Shortcut in Sandbox Desktop
GuiLVCurrentFileToDesktop:
    GuiLVCurrentFileToStartMenuOrDesktop(row, box, sandboxes_array[box,"path"], "desktop")
Return
GuiLVCurrentFileToStartMenuOrDesktop(row, box, boxpath, where)
{
    LV_GetText(LVFileName,   row, 2)
    LV_GetText(LVPath, row, 3)
    SplitPath, LVFileName, , , , LVFileNameNoExt
    Target = %LVPath%\%LVFileName%
    if (where == "startmenu")
        ShortcutPath = %boxpath%\user\current\AppData\Roaming\Microsoft\Windows\Start Menu
    else
        ShortcutPath = %boxpath%\user\current\Desktop
    ShortcutFile = %ShortcutPath%\%LVFileNameNoExt%.lnk
    if (! FileExist(ShortcutPath))
        FileCreateDir, %ShortcutPath%
    FileCreateShortcut, %Target%, %ShortcutFile%, %LVPath%, , Run "%LVFileName%"`nShortcut created by SandboxToys2
    Return
}

; Create Sandboxed Shortcut...
GuiLVCurrentFileShortcut:
    GuiLVCurrentFileShortcut(row, box, sandboxes_array[box,"path"])
Return
GuiLVCurrentFileShortcut(row, box, boxpath)
{
    global start
    LV_GetText(LVFileName,   row, 2)
    LV_GetText(LVPath, row, 3)
    LV_GetText(LVBoxPath, row, 10)
    file = %LVPath%\%LVFileName%

    runstate = 1
    splitPath, file, , dir, extension, label
    A_Quotes = "
    if (extension == "exe")
    {
        iconfile = %boxpath%\%LVBoxPath%\%LVFileName%
        iconnum = 1
    }
    else if (extension == "lnk")
    {
        FileGetShortcut, %boxpath%\%LVBoxPath%\%LVFileName%, , , , , iconfile, iconnum, runstate
        if (! FileExist(iconfile))
            iconfile := stdPathToBoxPath(box, iconfile)
    }
    else
    {
        Menu, __TEMP__, Add, __TEMP__, DummyMenuHandler
        icon := setIconFromSandboxedShortcut(box, file, "__TEMP__", "__TEMP__", 32)
        idx := InStr(icon, ",", false, 0)
        iconfile := SubStr(icon, 1, idx-1)
        iconnum  := SubStr(icon, idx+1)
        if (iconnum < 0)
            iconnum := IndexOfIconResource(iconfile, iconnum)
        Menu, __TEMP__, DeleteAll
    }
    tip = Launch "%label%" in sandbox %box%
    writeSandboxedShortcutFileToDesktop(start, label, boxpath . "\" . LVBoxPath, "/box:" box " " A_Quotes file A_Quotes, tip, iconfile, iconnum, 1, box)

    Return
}

; Toggle Checkmark
GuiLVToggleCurrent:
    Gui +LastFound
    SendMessage, 4140, row - 1, 0xF000, SysListView321
    IsChecked := (ErrorLevel >> 12) - 1
    if (IsChecked)
        LV_Modify(row, "-Check")
    else
        LV_Modify(row, "Check")
Return

; Hide from this list
GuiLVHideCurrent:
    LV_Delete(row)
Return

; Add File to Ignore List
GuiLVIgnoreCurrentFile:
    LVIgnoreEntry(row, "files")
Return
; Add Folder to Ignore List
GuiLVIgnoreCurrentDir:
    LVIgnoreEntry(row, "dirs")
Return
; Add Reg Value to Ignore List
GuiLVIgnoreCurrentValue:
    LVIgnoreEntry(row, "values")
Return
; Add Reg Key to Ignore List
GuiLVIgnoreCurrentKey:
    LVIgnoreEntry(row, "keys")
Return
LVIgnoreEntry(row, mode)
{
    A_nl = `n

    if (mode == "dirs" || mode == "files")
        pathcol = 10
    else
        pathcol = 7

    if (mode == "keys")
        LV_GetText(item, row, pathcol)
    else if (mode == "dirs")
        LV_GetText(item, row, pathcol)
    else if (mode == "values")
    {
        LV_GetText(item, row, pathcol)
        LV_GetText(val,  row, 4)
        item = %item%\%val%
    }
    else
    {
        LV_GetText(item, row, pathcol)
        LV_GetText(val,  row, 2)
        item = %item%\%val%
    }
    AddIgnoreItem(mode, item)
    LV_Delete(row)

    if (mode == "dirs" || mode == "keys") {
        p = %item%
        row := LV_GetCount()
        loop
        {
            LV_GetText(item, row, pathcol)
            if ( InStr(item, p, 1) == 1 )
                LV_Delete(row)
            row -= 1
            if (row == 0)
                break
        }
    }
    Return
}

; Add Sub-Folder to Ignore List...
GuiLVIgnoreCurrentSubDir:
    Gui +OwnDialogs
    LVIgnoreSpecific(row, "dirs")
Return
; Add Reg Sub-Key to Ignore List...
GuiLVIgnoreCurrentSubKey:
    Gui +OwnDialogs
    LVIgnoreSpecific(row, "keys")
Return

GuiLVRegMouseEventHandler:
    row := A_EventInfo
    if (row == 0)
        Return

    if (A_GuiEvent == "DoubleClick") {
        GoSub, GuiLVCurrentOpenRegEdit
        Return
    }
    if (A_GuiEvent == "RightClick") {
        Menu, PopupMenu, Show
    }
Return

GuiLVCurrentCopyToClipboard:
    LV_GetText(LVRegPath,  row, 2)
    clipboard := LVRegPath
Return

GuiLVCurrentOpenRegEdit:
    GuiLVCurrentOpenRegEdit(row, box)
Return
GuiLVCurrentOpenRegEdit(row, box)
{
    run_pid := InitializeBox(box)
    ; pre-select the right registry key
    LV_GetText(LVRegPath, row, 7)
    key = HKEY_USERS\Sandbox_%username%_%box%\%LVRegPath%
    RegWrite, REG_SZ, HKEY_CURRENT_USER, Software\Microsoft\Windows\CurrentVersion\Applets\Regedit, LastKey, %key%
    ; launch regedit
    RunWait, RegEdit.exe, , UseErrorLevel
    ReleaseBox(run_pid)
    Return
}

GuiLVAutostartMouseEventHandler:
    row := A_EventInfo
    if (row == 0)
        Return

    Gui, +OwnDialogs
    if (A_GuiEvent == "DoubleClick") {
        GuiLVRegistryRun(row, box)
        Return
    }
    if (A_GuiEvent == "RightClick") {
        Menu, PopupMenu, Show
    }
Return

GuiLVRegistryRun:
    GuiLVRegistryRun(row, box)
Return
GuiLVRegistryRun(row, box)
{
    global title, start
    A_Quotes = "
    Gui, +OwnDialogs
    LV_GetText(LVRegName, row, 2)
    LV_GetText(LVCommand, row, 3)
    if (LVCommand == "")
        MsgBox, 48, %title%, Can't run "%LVRegName%" in box %box%.`n`nNo command line., 3
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
            Filename = %LVCommand%
            Args =
        }
        if (Args == "")
            run, %start% /box:%box% "%Filename%", , UseErrorLevel
        else
            run, %start% /box:%box% "%Filename%" %Args%, , UseErrorLevel
        MsgBox, 64, %title%, Running "%LVRegName%" in box %box%.`n`nPlease wait..., 3
    }
    Return
}

GuiLVRegistryToStartMenuStartup:
    GuiLVRegistryToStartMenuStartup(box, sandboxes_array[box,"path"])
Return
GuiLVRegistryToStartMenuStartup(box, boxpath)
{
    global title
    A_Quotes = "
    numfiles := numOfCheckedFiles()
    if (numfiles == 0)
    {
        SoundBeep
        Return
    }
    row = 0
    Loop
    {
        row := LV_GetNext(row, "Checked")
        if not row
            break
        GuiLVRegistryItemToStartMenuStartup(row, box, boxpath)
    }
    Return
}
GuiLVRegistryItemToStartMenuStartup:
    GuiLVRegistryItemToStartMenuStartup(row, box, sandboxes_array[box,"path"])
Return
GuiLVRegistryItemToStartMenuStartup(row, box, boxpath)
{
    global title
    A_Quotes = "

    LV_GetText(LVProgram,  row, 2)
    LV_GetText(LVCommand,  row, 3)
    LV_GetText(LVLocation, row, 4)
    if (LVCommand == "")
    {
        MsgBox, 48, %title%, Can't create shortcut to "%LVProgram%".`n`nNo command line., 3
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
        Filename = %LVCommand%
        Args =
    }
    if (InStr(LVLocation, "HKCU"))
        ShortcutPath = %boxpath%\user\current\AppData\Roaming\Microsoft\Windows\Start Menu\Programs\Startup
    else
        ShortcutPath = %boxpath%\user\all\Microsoft\Windows\Start Menu\Programs\Startup

    ShortcutFile = %ShortcutPath%\%LVProgram% (%LVLocation%).lnk
    if (! FileExist(ShortcutPath))
        FileCreateDir, %ShortcutPath%
    if (Args == "")
        FileCreateShortcut, %Filename%, %ShortcutFile%, , , Run "%LVProgram%"`n(Was in %LVLocation%)`nShortcut created by SandboxToys2
    else
        FileCreateShortcut, %Filename%, %ShortcutFile%, , %Args%, Run "%LVProgram%"`n(Was in %LVLocation%)`nShortcut created by SandboxToys2

    Return
}

GuiLVRegistryExploreStartMenuCS:
    GuiLVRegistryExploreStartMenu(box, sandboxes_array[box,"path"], "current", "sandboxed")
Return
GuiLVRegistryExploreStartMenuCU:
    GuiLVRegistryExploreStartMenu(box, sandboxes_array[box,"path"], "current", "unsandboxed")
Return
GuiLVRegistryExploreStartMenuAS:
    GuiLVRegistryExploreStartMenu(box, sandboxes_array[box,"path"], "all", "sandboxed")
Return
GuiLVRegistryExploreStartMenuAU:
    GuiLVRegistryExploreStartMenu(box, sandboxes_array[box,"path"], "all", "unsandboxed")
Return
GuiLVRegistryExploreStartMenu(box, boxpath, user, mode)
{
    global title, start
    if (mode == "unsandboxed") {
        if (user == "current") {
            path = %boxpath%\user\current\AppData\Roaming\Microsoft\Windows\Start Menu\Programs\Startup
            mowner = Current User's
        } else {
            path = %boxpath%\user\all\Microsoft\Windows\Start Menu\Programs\Startup
            mowner = All Users
        }
        if (FileExist(path)) {
            Run, %path%
        } else {
            MsgBox, 48, %title%, The %mowner% Start Menu of box %box% has not been created yet.`n`nCan't explore it unsandboxed.
        }
    }
    else
    {
        if (user == "current")
            path = %A_StartMenu%\Programs\Startup
        else
            path = %A_StartMenuCommon%\Programs\Startup
        Run, %start% /box:%box% "%path%"
    }
}

GuiLVToggleAllCheckmarks:
    Checkedrows =
    RowNumber = 0
    Loop
    {
        RowNumber := LV_GetNext(RowNumber, "Checked")
        if not RowNumber
            break
        Checkedrows = %Checkedrows%%RowNumber%,
    }
    Checkedrows := Trim(Checkedrows, ",")
    LV_Modify(0, "Check")
    Loop, Parse, Checkedrows, CSV
        LV_Modify(A_LoopField, "-Check")
Return

GuiLVHideSelected:
    Srows =
    RowNumber = 0
    Loop
    {
        RowNumber := LV_GetNext(RowNumber)
        if not RowNumber
            break
        Srows = %Srows%%RowNumber%,
    }
    Srows := Trim(Srows, ",")
    Sort, Srows, N R D,
    Loop, Parse, Srows, CSV
        LV_Delete(A_LoopField)
Return

GuiLVIgnoreSelectedValues:
    LVIgnoreSelected("values")
Return

GuiLVIgnoreSelectedKeys:
    LVIgnoreSelected("keys")
Return

GuiLVIgnoreSelectedFiles:
    LVIgnoreSelected("files")
Return

GuiLVIgnoreSelectedDirs:
    LVIgnoreSelected("dirs")
Return

GuiLVClearAllCheckmarks:
    numrows := LV_GetCount()
    Loop, %numrows%
        LV_Modify(A_Index, "-Check")
Return

GuiLVToggleSelected:
    row = 0
    Loop
    {
        row := LV_GetNext(row)
        if not row
            break
        Gui +LastFound
        SendMessage, 4140, row - 1, 0xF000, SysListView321
        IsChecked := (ErrorLevel >> 12) - 1
        if (IsChecked)
            LV_Modify(row, "-Check")
        else
            LV_Modify(row, "Check")
    }
Return

GuiLVFilesSaveAsText:
    GuiLVSaveAsCSVText(box, "Files in sandbox " . box . ".txt")
Return
GuiLVRegistrySaveAsText:
    GuiLVSaveAsCSVText(box, "Registry of sandbox " . box . ".txt")
Return
GuiLVSaveAsCSVText(box, defaultfilename)
{
    global DefaultFolder, title
    A_Quotes = "
    numfiles := numOfCheckedFiles()
    if (numfiles == 0)
    {
        SoundBeep
        Return
    }
    Gui, +OwnDialogs
    if (! InStr(FileExist(DefaultFolder . "\"), "D"))
        DefaultFolder = %userprofile%\Desktop
    FileSelectFile, filename, S16, %DefaultFolder%\%defaultfilename%, Select output text file to save the checkmarked items as coma separated values..., Text files (*.txt)
    if (filename == "")
        Return
    SplitPath, filename, , DefaultFolder, ProvidedExtension
    if (ProvidedExtension != "txt")
        filename = %filename%.txt

    Progress, A M R0-100, Please wait..., Saving list of %numfiles% files..., %title%
    Progress, 100
    FileDelete, %filename%
    numcols := LV_GetCount("Column")
    row = 0
    filenum = 1
    Loop
    {
        row := LV_GetNext(row, "Checked")
        if not row
            break
        line =
        loop, %numcols%
        {
            colnum = %A_Index%
            if (colnum == 1)
                continue
            LV_GetText(colitem, row, colnum)
            line = %line%%A_Quotes%%colitem%%A_Quotes%,
        }
        line := Trim(line, ",")
        FileAppend, %line%`n, %filename%
        filenum ++
    }
    sleep 10
    Progress, OFF
    Return
}

GuiLVFilesToStartMenu:
    GuiLVFilesToStartMenuOrDesktop(box, sandboxes_array[box,"path"], "startmenu")
Return
GuiLVFilesToDesktop:
    GuiLVFilesToStartMenuOrDesktop(box, sandboxes_array[box,"path"], "desktop")
Return
GuiLVFilesToStartMenuOrDesktop(box, boxpath, where)
{
    numfiles := numOfCheckedFiles()
    if (numfiles == 0)
    {
        SoundBeep
        Return
    }
    row = 0
    Loop
    {
        row := LV_GetNext(row, "Checked")
        if not row
            break
        GuiLVCurrentFileToStartMenuOrDesktop(row, box, boxpath, where)
    }
    Return
}

GuiLVFilesShortcut:
    GuiLVFilesShortcut(box, sandboxes_array[box,"path"])
Return
GuiLVFilesShortcut(box, boxpath)
{
    global start
    numfiles := numOfCheckedFiles()
    if (numfiles == 0)
    {
        SoundBeep
        Return
    }
    row = 0
    Loop
    {
        row := LV_GetNext(row, "Checked")
        if not row
            break
        GuiLVCurrentFileShortcut(row, box, boxpath)
    }
    Return
}

GuiLVFilesSaveTo:
    LVFilesSaveTo(sandboxes_array[box,"path"])
Return
LVFilesSaveTo(boxpath)
{
    static DefaultFolder
    numfiles := numOfCheckedFiles()
    if (numfiles == 0)
    {
        SoundBeep
        Return
    }
    Gui, +OwnDialogs
    if (Not Instr(FileExist(DefaultFolder),"D"))
        DefaultFolder =
    if DefaultFolder =
        DefaultFolder = %userprofile%\Desktop
    DefaultFolder := expandEnvVars(DefaultFolder)
    FileSelectFolder, dirname, *%DefaultFolder%, 1, Copy checkmarked files from sandbox to folder...`n`n********** WARNING: Existing files will be OVERWRITTEN **********
    if (dirname == "")
        Return
    DefaultFolder = %dirname%
    Progress, A M R0-100, Please wait..., Saving %numfiles% files..., %title%
    Progress, 100
    row = 0
    filenum = 1
    Overwrite = -1
    Loop
    {
        row := LV_GetNext(row, "Checked")
        if not row
            break
        LV_GetText(LVFileName,   row, 2)
        LV_GetText(LVSBFilePath, row, 10)
        outfile = %dirname%\%LVFileName%
        exist := FileExist(outfile)
        if (exist && overwrite == -1) {
            Progress, OFF
            MsgBox, 291, %title%, Warning: Some files exist already in the destination folder.`nOverwrite them?
            prog := 
            Progress, % round(100 * (filenum / numfiles))
            Sleep, 100
            Progress, 100
            IfMsgBox, Cancel
            {
                Progress, OFF
                Return
            }
            IfMsgBox, Yes
                Overwrite = 1
            else
                Overwrite = 0
        }
        if (NOT exist || Overwrite == 1)
            FileCopy, %boxpath%\%LVSBFilePath%\%LVFileName%, %outfile%, 1
        filenum ++
    }
    sleep 10
    Progress, OFF
    Return
}

GuiLVRegistrySaveAsReg:
    GuiLVRegistrySaveAsReg(box)
Return
GuiLVRegistrySaveAsReg(box)
{
    global title
    static DefaultFolder
    A_Quotes = "
    A_nl = `n

    mainsbkey = Sandbox_%username%_%box%

    numregs := numOfCheckedFiles()
    if (numregs == 0)
    {
        SoundBeep
        Return
    }
    Gui, +OwnDialogs
    if (! InStr(FileExist(DefaultFolder . "\"), "D"))
        DefaultFolder = %userprofile%\Desktop
    FileSelectFile, filename, S16, %DefaultFolder%\box %box%.reg, Select REG file to save the checkmarked keys and values to, REG files (*.reg)
    if (filename == "")
        Return
    SplitPath, filename, , DefaultFolder, ProvidedExtension
    if (ProvidedExtension != "reg")
        filename = %filename%.reg
    FileDelete, %filename%

    ; ensure that the box is in use, or the hive will not be loaded
    run_pid := InitializeBox(box)

    row = 0
    lastrealkeypath =
    failed =
    out = REGEDIT4`n
    Loop
    {
        line =
        row := LV_GetNext(row, "Checked")
        if not row
            break
        LV_GetText(Status, row, 1)
        status = SubStr(Status,1,1)
        LV_GetText(realkeypath, row, 2)
        LV_GetText(keytype, row, 3)
        LV_GetText(keyvaluename, row, 4)
        LV_GetText(boxkeypath, row, 7)
        boxkeypath = %mainsbkey%\%boxkeypath%

        if (keyvaluename == "@")
        {
            valuename =
            outvaluename = @
        }
        else
        {
            valuename = %keyvaluename%
            outvaluename = "%keyvaluename%"
        }
        if (lastrealkeypath != realkeypath)
        {
            if (keytype == "-DELETED_KEY")
                line = `n[-%realkeypath%]`n
            else
                line = `n[%realkeypath%]`n
            lastrealkeypath = %realkeypath%
        }
        if (keytype == "-DELETED_VALUE")
            line = %line%%outvaluename%=-`n
        if (keytype != "-DELETED_KEY" && keytype != "-DELETED_VALUE")
        {
            RegRead, keyvalueval, HKEY_USERS, %boxkeypath%, %valuename%
            if (ErrorLevel)
            {
                keyvalueval := RegRead64("HKEY_USERS", boxkeypath, valuename, false, 65536)
                if (ErrorLevel)
                    failed = %failed%[%boxkeypath%] %outvaluename% (%keytype%)`n
            }
            if (! ErrorLevel)
            {
                if (keytype == "REG_SZ")
                {
                    StringReplace, keyvalueval, keyvalueval, \, \\, 1
                    StringReplace, keyvalueval, keyvalueval, %A_Quotes%, \%A_Quotes%, 1
                    line = %line%%outvaluename%="%keyvalueval%"`n
                }
                else if (keytype == "REG_EXPAND_SZ")
                {
                    hexstr := str2hexstr(keyvalueval)
                    wrapped := WrapRegString(outvaluename . "=hex(2):" . hexstr)
                    line = %line%%wrapped%`n
                }
                else if (keytype == "REG_BINARY")
                {
                    hexstr := hexstr2hexstrcomas(keyvalueval)
                    wrapped := WrapRegString(outvaluename . "=hex:" . hexstr)
                    line = %line%%wrapped%`n
                }
                else if (keytype == "REG_DWORD")
                {
                    hex := dec2hex(keyvalueval,8)
                    line = %line%%outvaluename%=dword:%hex%`n
                }
                else if (keytype == "REG_QWORD")
                {
                    hex := qword2hex(keyvalueval)
                    line = %line%%outvaluename%=hex(b):%hex%`n
                }
                else if (keytype == "REG_MULTI_SZ")
                {
                    hexstr := str2hexstr(keyvalueval, true)
                    wrapped := WrapRegString(outvaluename . "=hex(7):" . hexstr)
                    line = %line%%wrapped%`n
                }
                else
                {
                    failed = %failed%[%boxkeypath%] %outvaluename% (%keytype%)`n
                }
            }
        }
        out = %out%%line%
    }


    FileAppend, %out%, %filename%
    if (failed != "") {
        MsgBox, 48, %title%, Warning!  Some key values cannot be saved due to unsupported key type:`n`n%failed%
    }

    ReleaseBox(run_pid)

    Return
}

GuiClose:
    Gui, Destroy
    guinotclosed = 0
Return

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
            out = %out%  %str%
            break
        }
        idx := InStr(str, ",", 0, 75)
        sub := subStr(str, 1, idx)
        out = %out%  %sub%\`n
        str := subStr(str, idx+1)
    }
    return %out%
}

numOfCheckedFiles()
{
    num = 0
    row = 0
    Loop
    {
        row := LV_GetNext(row, "Checked")
        if not row
            break
        num ++
    }
    return num
}

; ###################################################################################################
; Registry functions
; ###################################################################################################

; A_LoopRegName ; Name of the currently retrieved item, which can be either a value name or the name of a subkey. Value names displayed by Windows RegEdit as "(Default)" will be retrieved if a value has been assigned to them, but A_LoopRegName will be blank for them.
; A_LoopRegType ; The type of the currently retrieved item, which is one of the following words: KEY (i.e. the currently retrieved item is a subkey not a value), REG_SZ, REG_EXPAND_SZ, REG_MULTI_SZ, REG_DWORD, REG_QWORD, REG_BINARY, REG_LINK, REG_RESOURCE_LIST, REG_FULL_RESOURCE_DESCRIPTOR, REG_RESOURCE_REQUIREMENTS_LIST, REG_DWORD_BIG_ENDIAN (probably rare on most Windows hardware). It will be empty if the currently retrieved item is of an unknown type.
; A_LoopRegKey ; The name of the root key being accessed (HKEY_LOCAL_MACHINE, HKEY_USERS, HKEY_CURRENT_USER, HKEY_CLASSES_ROOT, or HKEY_CURRENT_CONFIG). For remote registry access, this value will not include the computer name.
; A_LoopRegSubKey ; Name of the current SubKey. This will be the same as the Key parameter unless the Recurse parameter is being used to recursively explore other subkeys. In that case, it will be the full path of the currently retrieved item, not including the root key. For example: Software\SomeApplication\My SubKey
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
                value  =
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

    mainsbkey = Sandbox_%username%_%box%
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

    mainsbkey = Sandbox_%username%_%box%
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

ListReg(box, path, filename="")
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
    Sort, allregs, P3
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
            MsgBox, 64, %title%, No meaningfull registry keys or values found in box "%box%"!
        Return
    }

    if (LVLastSize == "") {
        SysGet, mon, MonitorWorkArea
        if (monRight == "") {
            width  := A_ScreenWidth - 300
            height := A_ScreenHeight - 300
        } else {
            width  := monRight - monLeft - 250
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

    Gui, Destroy
    Gui, +Resize
    Gui, Add, Text, W900 vMainLabel, Find Registry Keys...

    Menu, FileMenu, Add
    Menu, FileMenu, DeleteAll
    Menu, FileMenu, Add, Save Checkmarked entries as &REG file, GuiLVRegistrySaveAsReg
    Menu, FileMenu, Add
    Menu, FileMenu, Add, Save Checkmarked entries as CSV &Text, GuiLVRegistrySaveAsText

    Menu, EditMenu, Add
    Menu, EditMenu, DeleteAll
    Menu, EditMenu, Add, &Clear All Checkmarks, GuiLVClearAllCheckmarks
    Menu, EditMenu, Add, &Toggle All Checkmarks, GuiLVToggleAllCheckmarks
    Menu, EditMenu, Add, Toggle &Selected Checkmarks, GuiLVToggleSelected
    Menu, EditMenu, Add
    Menu, EditMenu, Add, &Hide Selected Entries,  GuiLVHideSelected
    Menu, EditMenu, Add
    Menu, EditMenu, Add, Add Selected &Values to Ignore List, GuiLVIgnoreSelectedValues
    Menu, EditMenu, Add, Add Selected &Keys to Ignore List,   GuiLVIgnoreSelectedKeys
;    Menu, EditMenu, Add, Add Specific &Key to Ignore List,    GuiLVIgnoreSpecificKey

    Menu, LVMenuBar, Add
    Menu, LVMenuBar, DeleteAll
    Menu, LVMenuBar, Add, &File, :FileMenu
    Menu, LVMenuBar, Add, &Edit, :EditMenu
    Gui, Menu, LVMenuBar

    Menu, PopupMenu, Add
    Menu, PopupMenu, DeleteAll
    Menu, PopupMenu, Add, Copy Key to Clipboard, GuiLVCurrentCopyToClipboard
    Menu, PopupMenu, Add, Open Key in RegEdit, GuiLVCurrentOpenRegEdit
    Menu, PopupMenu, Add
    Menu, PopupMenu, Add, Toggle Checkmark, GuiLVToggleCurrent
    Menu, PopupMenu, Add
    Menu, PopupMenu, Add, Hide from this list, GuiLVHideCurrent
    Menu, PopupMenu, Add
    Menu, PopupMenu, Add, Add Value to Ignore List, GuiLVIgnoreCurrentValue
    Menu, PopupMenu, Add, Add Key to Ignore List, GuiLVIgnoreCurrentKey
    Menu, PopupMenu, Add, Add Sub-Key to Ignore List..., GuiLVIgnoreCurrentSubKey


    Gui, Add, ListView, X10 Y30 %LVLastSize% Checked Count%numrows% gGuiLVRegMouseEventHandler vMyListView AltSubmit, Status|Key|Type|Value Name|Value Data|Key modified time|Sandbox Path

    Progress, 100, Please wait..., Building list of keys`nin box "%box%"., %title%
    Sleep, 100

    ; add entries in listview
    nummodified = 0
    numadded = 0
    numdeleted = 0
    GuiControl, -Redraw, MyListView
    sep := chr(1)
    loop, parse, allregs, `n
    {
        entry := A_LoopField
        loop, parse, entry, %sep%
        {
            if (A_Index == 1) {
                St = %A_LoopField%
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

                keypath = %A_LoopField%
                if (substr(keypath, 1, 8) == "machine\")
                    realkeypath := "HKEY_LOCAL_MACHINE" . substr(keypath, 8)
                else if (substr(keypath, 1, 13) == "user\current\")
                    realkeypath := "HKEY_CURRENT_USER" . substr(keypath, 13)
                else if (substr(keypath, 1, 21) == "user\current_classes\")
                    realkeypath := "HKEY_CLASSES_ROOT" . substr(keypath, 21)
            } else if (A_Index == 3) {
                keytype = %A_LoopField%
            } else if (A_Index == 4) {
                keyvaluename = %A_LoopField%
            } else if (A_Index == 5) {
                keyvalueval = %A_LoopField%
            } else if (A_Index == 6) {
                FormatTime, modtime, %A_LoopField%, yyyy/MM/dd HH:mm:ss
            }
        }
        if (St == "+") {
            if (keytype != "KEY")
            {
                idx := InStr(realkeypath, "\")
                realrootkey := SubStr(realkeypath, 1, idx-1)
                realsubkey  := SubStr(realkeypath, idx+1)
                if (keyvaluename == "@")
                    realkeyvaluename =
                else
                    realkeyvaluename = %keyvaluename%
                RegRead, tmp, %realrootkey%, %realsubkey%, %realkeyvaluename%
                if (NOT ErrorLevel)
                    St = #
                else {
                    tmp := RegRead64KeyType(realrootkey, realsubkey, realkeyvaluename)
                    if (NOT ErrorLevel)
                        St = #
                }
            }
        } else{
            modtime =
        }
        if (St == "#")
            nummodified ++
        else if (St == "+")
            numadded ++
        else if (St == "-")
            numdeleted ++
        LV_Add("" , St . A_Space, realkeypath, keytype, keyvaluename, keyvalueval, modtime, keypath)
    }
    Sleep, 10

    LV_ModifyCol()
    LV_ModifyCol(2, "Sort")

    msg = Found %numregs% registry key
    if (numregs != 1)
        msg = %msg%s or values
    else
        msg = %msg% or value
    msg = %msg% in the sandbox "%box%"
    msg = %msg% : # %nummodified% modified
    msg = %msg% , + %numadded% new
    msg = %msg% , - %numdeleted% deleted
    msg = %msg%.  Double-click a key to open it in RegEdit.
    GuiControl, , MainLabel, %msg%

    Progress, OFF
    if (comparemode)
        Gui, Show, , %title% - Changes in registry of box "%box%"
    else
        Gui, Show, , %title% - Registry of box "%box%"
    GuiControl, +Redraw, MyListView

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
    Sort, outtxt, CL D`n
    Return %outtxt%
}
ListAutostarts(box, path)
{
    global guinotclosed, title, MyListView
    static MainLabel

    A_Quotes = "
    A_nl = `n

    run_pid := InitializeBox(box)
    Sleep 1000

    autostarts =

    ; check RunOnce keys
    key = Sandbox_%username%_%box%\machine\Software\Microsoft\Windows\CurrentVersion\RunOnce
    location = HKLM RunOnce
    autostarts := autostarts . SearchAutostart(box, key, location, 0)
    
    key = Sandbox_%username%_%box%\machine\Software\Wow6432Node\Microsoft\Windows\CurrentVersion\RunOnce
    location = HKLM RunOnce
    autostarts := autostarts . SearchAutostart(box, key, location, 0)

    key = Sandbox_%username%_%box%\user\current\Software\Microsoft\Windows\CurrentVersion\RunOnce
    location = HKCU RunOnce
    autostarts := autostarts . SearchAutostart(box, key, location, 0)
    
    key = Sandbox_%username%_%box%\user\current\Software\Wow6432Node\Microsoft\Windows\CurrentVersion\RunOnce
    location = HKCU RunOnce
    autostarts := autostarts . SearchAutostart(box, key, location, 0)

    ; check Run keys
    key = Sandbox_%username%_%box%\machine\Software\Microsoft\Windows\CurrentVersion\Run
    location = HKLM Run
    autostarts := autostarts . SearchAutostart(box, key, location, 1)
    
    key = Sandbox_%username%_%box%\machine\Software\Wow6432Node\Microsoft\Windows\CurrentVersion\Run
    location = HKLM Run
    autostarts := autostarts . SearchAutostart(box, key, location, 1)

    key = Sandbox_%username%_%box%\user\current\Software\Microsoft\Windows\CurrentVersion\Run
    location = HKCU Run
    autostarts := autostarts . SearchAutostart(box, key, location, 1)
    
    key = Sandbox_%username%_%box%\user\current\Software\Wow6432Node\Microsoft\Windows\CurrentVersion\Run
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
            width  := A_ScreenWidth - 300
            height := A_ScreenHeight - 300
        } else {
            width  := monRight - monLeft - 250
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

    Gui, Destroy
    Gui, +Resize
    Gui, Add, Text, W900 vMainLabel, Registry Autostarts...

    Menu, FileMenu, Add
    Menu, FileMenu, DeleteAll
    Menu, FileMenu, Add, Copy Checkmarked Entries to Start Menu\Startup of Sandbox, GuiLVRegistryToStartMenuStartup
    Menu, FileMenu, Add
    Menu, FileMenu, Add, Explore Current User's Startup Menu (Unsandboxed), GuiLVRegistryExploreStartMenuCU
    Menu, FileMenu, Add, Explore Current User's Startup Menu (Sandboxed),   GuiLVRegistryExploreStartMenuCS
    Menu, FileMenu, Add, Explore All Users Startup Menu (Unsandboxed),      GuiLVRegistryExploreStartMenuAU
    Menu, FileMenu, Add, Explore All Users Startup Menu (Sandboxed),        GuiLVRegistryExploreStartMenuAS

    Menu, EditMenu, Add
    Menu, EditMenu, DeleteAll
    Menu, EditMenu, Add, &Clear All Checkmarks, GuiLVClearAllCheckmarks
    Menu, EditMenu, Add, &Toggle All Checkmarks, GuiLVToggleAllCheckmarks
    Menu, EditMenu, Add, Toggle &Selected Checkmarks, GuiLVToggleSelected
    Menu, EditMenu, Add
    Menu, EditMenu, Add, &Hide Selected Entries,  GuiLVHideSelected

    Menu, LVMenuBar, Add
    Menu, LVMenuBar, DeleteAll
    Menu, LVMenuBar, Add, &File, :FileMenu
    Menu, LVMenuBar, Add, &Edit, :EditMenu
    Gui, Menu, LVMenuBar

    Menu, PopupMenu, Add
    Menu, PopupMenu, DeleteAll
    Menu, PopupMenu, Add, Run in Sandbox, GuiLVRegistryRun
    Menu, PopupMenu, Add, Copy to Start Menu\Startup of Sandbox, GuiLVRegistryItemToStartMenuStartup
    Menu, PopupMenu, Add
    Menu, PopupMenu, Add, Toggle Checkmark, GuiLVToggleCurrent
    Menu, PopupMenu, Add
    Menu, PopupMenu, Add, &Hide from this list,  GuiLVHideCurrent


    Gui, Add, ListView, X10 Y30 %LVLastSize% Checked Count%numrows% gGuiLVAutostartMouseEventHandler vMyListView AltSubmit, Status|Program|Command|Location

    ; icons array
    ImageListID1 := IL_Create(10)
    LV_SetImageList(ImageListID1)

    ; add entries in listview
    GuiControl, -Redraw, MyListView
    sep := chr(1)
    row = 1
    loop, parse, autostarts, `n
    {
        entry := A_LoopField
        loop, parse, entry, %A_Tab%
        {
            ; A_LoopRegName / value / location / tick
            if (A_Index == 1) {
                valuename = %A_LoopField%
            } else if (A_Index == 2) {
                valuedata = %A_LoopField%
            } else if (A_Index == 3) {
                location = %A_LoopField%
            } else if (A_Index == 4) {
                ticked = %A_LoopField%
            }
        }
        if (valuedata != "")
        {
            program = %valuedata%
            if (SubStr(valuedata, 1, 1) == A_Quotes)
            {
                idx2 := InStr(valuedata, A_Quotes, 0, 2)
                if (idx2)
                    program := SubStr(valuedata, 2, idx2-2)
            }
            boxprogram := StdPathToBoxPath(box, program)
            if (! FileExist(boxprogram))
                boxprogram = %program%
            hIcon := GetAssociatedIcon(boxprogram, false, 16, box)
            IconNumber := DllCall("ImageList_ReplaceIcon", "uint", ImageListID1, "int", -1, "uint", hIcon) + 1
            LV_Add("Icon" . IconNumber, "", valuename, valuedata, location)
            if (ticked)
                LV_Modify(row, "Check")
        }
        else
            LV_Add("Icon0" , "", valuename, "", location)

        row ++
    }
    LV_ModifyCol()

    msg = Found %numregs% autostart program
    if (numregs != 1)
        msg = %msg%s
    else
        msg = %msg%
    msg = %msg% in the sandbox "%box%"
    msg = %msg%.  Double-click an entry to run it.
    GuiControl, , MainLabel, %msg%
    Gui, Show, , %title% - Autostart programs in registry of box "%box%"
    GuiControl, +Redraw, MyListView

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
    HKEY_CLASSES_ROOT   := 0x80000000   ; http://msdn.microsoft.com/en-us/library/aa393286.aspx
    HKEY_CURRENT_USER   := 0x80000001
    HKEY_LOCAL_MACHINE  := 0x80000002
    HKEY_USERS          := 0x80000003
    HKEY_CURRENT_CONFIG := 0x80000005
    HKEY_DYN_DATA       := 0x80000006

    ; http://msdn.microsoft.com/en-us/library/ms724884.aspx
    REG_NONE             := 0   ; unsupported
    REG_SZ               := 1   ; supported
    REG_EXPAND_SZ        := 2   ; supported
    REG_BINARY           := 3   ; supported
    REG_DWORD            := 4   ; supported
    REG_DWORD_BIG_ENDIAN := 5   ; supported, but handled like REG_DWORD
    REG_LINK             := 6
    REG_MULTI_SZ         := 7   ; supported
    REG_RESOURCE_LIST    := 8   ; UNSUPPORTED!
    ; added by r0lZ
    REG_FULL_RESOURCE_DESCRIPTOR := 9 ; UNSUPPORTED!
    REG_RESOURCE_REQUIREMENTS_LIST := 10 ; UNSUPPORTED!
    REG_QWORD            := 11  ; supported (but not in unsigned mode)

    KEY_QUERY_VALUE := 0x0001   ; http://msdn.microsoft.com/en-us/library/ms724878.aspx
    KEY_WOW64_64KEY := 0x0100   ; http://msdn.microsoft.com/en-gb/library/aa384129.aspx (do not redirect to Wow6432Node on 64-bit machines)
    KEY_WOW64_32KEY := 0x0200

    myhKey := %sRootKey%      ; pick out value (0x8000000x) from list of HKEY_xx vars
    IfEqual,myhKey,, {      ; Error - Invalid root key
        ErrorLevel := 3
        return ""
    }

    ; argument to read either in 64bit or 32bit mode added by r0lZ
    if (mode64bit)
        RegAccessRight := KEY_QUERY_VALUE + KEY_WOW64_64KEY
    else
        RegAccessRight := KEY_QUERY_VALUE + KEY_WOW64_32KEY

    DllCall("Advapi32.dll\RegOpenKeyEx", "uint", myhKey, "str", sKeyName, "uint", 0, "uint", RegAccessRight, "uint*", hKey)   ; open key
    If (hKey==0) {
        ErrorLevel := 4
        return ""
    }
    DllCall("Advapi32.dll\RegQueryValueEx", "uint", hKey, "str", sValueName, "uint", 0, "uint*", sValueType, "uint", 0, "uint", 0)      ; get value type

    If (sValueType == REG_SZ or sValueType == REG_EXPAND_SZ) {
        VarSetCapacity(sValue, vValueSize:=DataMaxSize)
        DllCall("Advapi32.dll\RegQueryValueEx", "uint", hKey, "str", sValueName, "uint", 0, "uint", 0, "str", sValue, "uint*", vValueSize)   ; get string or string-exp
    } Else If (sValueType == REG_DWORD or sValueType == REG_DWORD_BIG_ENDIAN) {
        VarSetCapacity(sValue, vValueSize:=4)
        DllCall("Advapi32.dll\RegQueryValueEx", "uint", hKey, "str", sValueName, "uint", 0, "uint", 0, "uint*", sValue, "uint*", vValueSize)   ; get dword
    } Else If (sValueType == REG_QWORD) {
        VarSetCapacity(sValue, vValueSize:=8)   ; added by r0lZ
        DllCall("Advapi32.dll\RegQueryValueEx", "uint", hKey, "str", sValueName, "uint", 0, "uint", 0, "uint64*", sValue, "uint*", vValueSize)   ; get qword
    } Else If (sValueType == REG_MULTI_SZ) {
        VarSetCapacity(sTmp, vValueSize:=DataMaxSize)
        DllCall("Advapi32.dll\RegQueryValueEx", "uint", hKey, "str", sValueName, "uint", 0, "uint", 0, "str", sTmp, "uint*", vValueSize)   ; get string-mult
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
        DllCall("Advapi32.dll\RegQueryValueEx", "uint", hKey, "str", sValueName, "uint", 0, "uint", 0, "str", sTmp, "uint*", vValueSize)   ; get binary
        sValue := ""
        SetFormat, integer, H
        Loop %vValueSize% {
            hex := SubStr(Asc(SubStr(sTmp,A_Index,1)),3)
            sValue := sValue hex
        }
        SetFormat, integer, d
    } Else If (sValueType == REG_NONE) {
        sValue := ""
    } Else {            ; value does not exist or unsupported value type
        DllCall("Advapi32.dll\RegCloseKey", "uint", hKey)
        ErrorLevel := 1
        return ""
    }
    DllCall("Advapi32.dll\RegCloseKey", "uint", hKey)
    return sValue
}

RegRead64KeyType(sRootKey, sKeyName, sValueName = "", mode64bit=true) {
    HKEY_CLASSES_ROOT   := 0x80000000   ; http://msdn.microsoft.com/en-us/library/aa393286.aspx
    HKEY_CURRENT_USER   := 0x80000001
    HKEY_LOCAL_MACHINE  := 0x80000002
    HKEY_USERS          := 0x80000003
    HKEY_CURRENT_CONFIG := 0x80000005
    HKEY_DYN_DATA       := 0x80000006

    REG_NONE             := 0   ; http://msdn.microsoft.com/en-us/library/ms724884.aspx
    REG_SZ               := 1
    REG_EXPAND_SZ        := 2
    REG_BINARY           := 3
    REG_DWORD            := 4
    REG_DWORD_BIG_ENDIAN := 5
    REG_LINK             := 6
    REG_MULTI_SZ         := 7
    REG_RESOURCE_LIST    := 8

    REG_FULL_RESOURCE_DESCRIPTOR := 9
    REG_RESOURCE_REQUIREMENTS_LIST := 10
    REG_QWORD            := 11

    ; Unofficial REG type used by Sandboxie to "delete" an existing key in the sandbox registry.
    REG_SB_DELETED       := 0x6B757A74

    KEY_QUERY_VALUE := 0x0001   ; http://msdn.microsoft.com/en-us/library/ms724878.aspx
    KEY_WOW64_64KEY := 0x0100   ; http://msdn.microsoft.com/en-gb/library/aa384129.aspx (do not redirect to Wow6432Node on 64-bit machines)
    KEY_WOW64_32KEY := 0x0200

    myhKey := %sRootKey%      ; pick out value (0x8000000x) from list of HKEY_xx vars
    IfEqual,myhKey,, {      ; Error - Invalid root key
        ErrorLevel := 3
        return ""
    }

    if (mode64)
        RegAccessRight := KEY_QUERY_VALUE + KEY_WOW64_64KEY
    else
        RegAccessRight := KEY_QUERY_VALUE + KEY_WOW64_32KEY

    DllCall("Advapi32.dll\RegOpenKeyEx", "uint", myhKey, "str", sKeyName, "uint", 0, "uint", RegAccessRight, "uint*", hKey)   ; open key
    If (hKey==0) {
        ErrorLevel := 4
        return ""
    }
    DllCall("Advapi32.dll\RegQueryValueEx", "uint", hKey, "str", sValueName, "uint", 0, "uint*", sValueType, "uint", 0, "uint", 0)      ; get value type

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
    Else            ; value does not exist or unsupported value type
        keytype := ""

    DllCall("Advapi32.dll\RegCloseKey", "uint", hKey)
    return keytype
}

RegEnumKey(sRootKey, sKeyName, x64mode=true) {
    HKEY_CLASSES_ROOT   := 0x80000000   ; http://msdn.microsoft.com/en-us/library/aa393286.aspx
    HKEY_CURRENT_USER   := 0x80000001
    HKEY_LOCAL_MACHINE  := 0x80000002
    HKEY_USERS          := 0x80000003
    HKEY_CURRENT_CONFIG := 0x80000005
    HKEY_DYN_DATA       := 0x80000006
    HKCR := HKEY_CLASSES_ROOT
    HKCU := HKEY_CURRENT_USER
    HKLM := HKEY_LOCAL_MACHINE
    HKU  := HKEY_USERS
    HKCC := HKEY_CURRENT_CONFIG

    KEY_ENUMERATE_SUB_KEYS := 0x0008
    KEY_WOW64_64KEY := 0x0100
    KEY_WOW64_32KEY := 0x0200

    ERROR_NO_MORE_ITEMS = 259

    myhKey := %sRootKey%      ; pick out value (0x8000000x) from list of HKEY_xx vars
    IfEqual,myhKey,, {      ; Error - Invalid root key
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
    Sort, names, CL
    return %names%
}


RegEnumValue(sRootKey, sKeyName, x64mode=true) {
    HKEY_CLASSES_ROOT   := 0x80000000   ; http://msdn.microsoft.com/en-us/library/aa393286.aspx
    HKEY_CURRENT_USER   := 0x80000001
    HKEY_LOCAL_MACHINE  := 0x80000002
    HKEY_USERS          := 0x80000003
    HKEY_CURRENT_CONFIG := 0x80000005
    HKEY_DYN_DATA       := 0x80000006
    HKCR := HKEY_CLASSES_ROOT
    HKCU := HKEY_CURRENT_USER
    HKLM := HKEY_LOCAL_MACHINE
    HKU  := HKEY_USERS
    HKCC := HKEY_CURRENT_CONFIG

    KEY_QUERY_VALUE := 0x0001   ; http://msdn.microsoft.com/en-us/library/ms724878.aspx
    KEY_WOW64_64KEY := 0x0100
    KEY_WOW64_32KEY := 0x0200

    ERROR_NO_MORE_ITEMS = 259

    myhKey := %sRootKey%      ; pick out value (0x8000000x) from list of HKEY_xx vars
    IfEqual,myhKey,, {      ; Error - Invalid root key
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
    Sort, names, CL
    return %names%
}

ExtractData(pointer) {  ; http://www.autohotkey.com/forum/viewtopic.php?p=91578#91578 SKAN
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

hex2dec(hex)
{
    if (SubStr(hex,1,2) != "0x")
        hex = 0x%hex%
    oldformat := A_FormatInteger
    SetFormat, integer, decimal
    dec := hex + 0 ; Convert from hex to dec.
    SetFormat, integer, %oldformat%
    return % SubStr(dec,1)
}

dec2hex(dec,minlength=2)
{
    oldformat := A_FormatInteger
    SetFormat, integer, H   ; H = upper case, h = lower case
    dec += 0 ; Convert from decimal to hex.
    SetFormat, integer, %oldformat%
    hex := substr(dec,3)
    if (mod(strLen(hex),2) != 0)
        hex = 0%hex%
    loop
    {
        if (strlen(hex) >= minlength)
            break
        hex = 0%hex%
    }
    return %hex%
}

qword2hex(qword)
{
    oldformat := A_FormatInteger
    SetFormat, integer, H
    if (qword < 0)
    {
        qword := (qword * -1) - 1
        dec1 := 0xFFFFFFFF - (qword & 0xFFFFFFFF)
        dec2 := 0xFFFFFFFF - (qword >> 32)
        dec1 := SubStr(dec1, 3)
        loop {
            if (strLen(dec1) == 8)
                break
            dec1 = 0%dec1%
        }
        dec2 := SubStr(dec2, 3)
        loop {
            if (strLen(dec2) == 8)
                break
            dec2 = 0%dec2%
        }
        hex = %dec2%%dec1%
    } else {
        qword += 0 ; Convert from decimal to hex.
        hex := substr(qword, 3)
        loop
        {
            if (strlen(hex) >= 16)
                break
            hex = 0%hex%
        }
    }
    SetFormat, integer, %oldformat%

    out =
    loop, 8
    {
        b := SubStr(hex, (A_Index-1)*2+1, 2)
        out = %b%,%out%
    }
    out := Trim(out, ",")
    return %out%
}

hexstr2hexstrcomas(hex)
{
    limit := StrLen(hex)
    out =
    loop, %limit%
    {
        out := out . SubStr(hex, A_Index, 1)
        if (mod(A_Index,2)==0)
            out = %out%,
    }
    out := Trim(out, ",")
    return %out%
}

hexstr2str(hexstr)
{
    str =
    numchars := StrLen(hexstr) / 2
    oldformat := A_FormatInteger
    SetFormat, integer, decimal
    Loop, %numchars%
        str := str . chr("0x" . substr(hexstr, (A_Index-1)*2+1, 2))
    SetFormat, integer, %oldformat%
    return %str%
}

str2hexstr(str,replacenlwithzero=false)
{
    out =
    oldformat := A_FormatInteger
    SetFormat, integer, H   ; H = upper case, h = lower case
    ; TODO: convert really to UTF-16
    loop, Parse, str
    {
        h := SubStr(Asc(A_LoopField),3)
        if (replacenlwithzero && h == "a")
            out = %out%00,
        else
        {
            if (StrLen(h)==1)
                out = %out%0%h%,
            else
                out = %out%%h%,
        }
    }
    out = %out%00
    SetFormat, integer, %oldformat%
    return %out%
}


; mode = hide (just temporarly hide entries: do not
Return

; Add a registry key or value or a folder or file to the ignore list
; mode = values, keys, files or dirs
LVIgnoreSelected(mode)
{
    A_nl = `n

    if (mode == "dirs" || mode == "files")
        pathcol = 10
    else
        pathcol = 7

    Srows =
    RowNumber = 0
    Loop
    {
        RowNumber := LV_GetNext(RowNumber)
        if not RowNumber
            break
        Srows = %Srows%%RowNumber%,
    }
    Srows := Trim(Srows, ",")
    removedpaths =
    Loop, Parse, Srows, CSV
    {
        if (mode == "keys")
        {
            LV_GetText(item, A_LoopField, pathcol)
            removedpaths = %removedpaths%%item%`n
        }
        else if (mode == "dirs")
        {
            LV_GetText(item, A_LoopField, pathcol)
            removedpaths = %removedpaths%%item%`n
        }
        else if (mode == "values")
        {
            LV_GetText(item, A_LoopField, pathcol)
            LV_GetText(val,  A_LoopField, 4)
            item = %item%\%val%
        }
        else
        {
            LV_GetText(item, A_LoopField, pathcol)
            LV_GetText(val,  A_LoopField, 2)
            item = %item%\%val%
        }
        AddIgnoreItem(mode, item)
    }

    Sort, Srows, N R D,
    Loop, Parse, Srows, CSV
        LV_Delete(A_LoopField)

    if (mode == "dirs" || mode == "keys") {
        removedpaths := Trim(removedpaths, A_nl)
        Loop, Parse, removedpaths, `n
        {
            p = %A_LoopField%
            row := LV_GetCount()
            loop
            {
                LV_GetText(item, row, pathcol)
                if ( InStr(item, p, 1) == 1 )
                    LV_Delete(row)
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
    Sort, pathdata, U
    Sort, itemdata, U

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
    if (mode == "dirs")
    {
        pathcol = 10
        name = directory
        names = directories
    }
    else
    {
        pathcol = 7
        name = key
        names = keys
    }

    LV_GetText(tohide, row, pathcol)

    prompt = Type the name of the %name% to permanently hide.`n
    prompt = %prompt%Use the format of the last column (Sandbox path).`n
    prompt = %prompt%Do not type the leading box path and the tailing backslash.`n
    prompt = %prompt%Note that all sub-%names% will be hidden as well.`n
    prompt = %prompt%Take care: The ignore list is global to all sandboxes!
    InputBox, tohide, Add item to Ignore List, %prompt%, , , , , , , , %tohide%
    if (ErrorLevel)
        Return

    tohide := Trim(tohide, "\")
    if (tohide != "")
        AddIgnoreItem(mode, tohide)

    tohidepath = %tohide%\
    row := LV_GetCount()
    loop
    {
        LV_GetText(item, row, pathcol)
        if ( InStr(item, tohidepath, 1) == 1 )
            LV_Delete(row)
        else if ( item == tohide )
            LV_Delete(row)
        row -= 1
        if (row == 0)
            break
    }

    Return
}


IsIgnored(mode, ignoredList, checkpath, item="")
{
    StringReplace, checkpath, checkpath, :, ., 1 
    if IgnoredList =
        Return 0

    ; TODO: doesn't work well due to new line characters
    A_nl = `n

    if (mode == "values" || mode == "files")
    {
        tocheck = `n%checkpath%\%item%`n
        Return % InStr(ignoredList, tocheck)
    }
    else
    {
        loop
        {
            tocheck = `n%checkpath%`n
            if (InStr(ignoredList, tocheck))
                Return 1
            SplitPath, checkpath, , checkpath
            if checkpath =
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
        iconnum  := menuicons[A_ThisMenu,A_ThisMenuItem,"num"]
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
        writeSandboxedShortcutFileToDesktop(start,"Sandboxie's Run dialog","","/box:" box " run_dialog","Launch Sandboxie's Run Dialog in sandbox " box,sbiectrl,1,1, box)
    else
        run, %start% /box:%box% run_dialog, , UseErrorLevel
Return

StartMenuMenuHandler:
    box := getBoxFromMenu()
    if (GetKeyState("Control", "P"))
        writeSandboxedShortcutFileToDesktop(start,"Sandboxie's Start Menu","","/box:" box " start_menu","Launch Sandboxie's Start Menu in sandbox " box,sbiectrl,1,1, box)
    else
        run, %start% /box:%box% start_menu, , UseErrorLevel
Return

SCmdMenuHandler:
    box := getBoxFromMenu()
    if (GetKeyState("Control", "P"))
    {
        args = /box:%box% %comspec% /k "cd /d %systemdrive%\"
        writeSandboxedShortcutFileToDesktop(start,"Sandboxed Command Prompt","",args,"Sandboxed Command Prompt in sandbox " box,A_WinDir "\system32\cmd.exe", 1,1, box)
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

UCmdMenuHandler:
    box := getBoxFromMenu()
    path := sandboxes_array[box,"path"]
    if (GetKeyState("Control", "P"))
    {
        args = /k "cd /d "%path%""
        writeUnsandboxedShortcutFileToDesktop(comspec,"Unsandboxed Command Prompt in sandbox " box,path,args,"Unsandboxed Command Prompt in sandbox " box,A_WinDir "\system32\cmd.exe",1,1)
    }
    else
        run, %comspec% /k "cd /d "%path%"", , UseErrorLevel
Return

SRegEditMenuHandler:
    box := getBoxFromMenu()
    if (GetKeyState("Control", "P"))
        writeSandboxedShortcutFileToDesktop(start,"Sandboxed Registry Editor","","/box:" box " regedit.exe","Launch RegEdit in sandbox " box, "regedit.exe",1,1, box)
    else
        run, %start% /box:%box% RegEdit.exe, , UseErrorLevel
Return

URegEditMenuHandler:
    if (GetKeyState("Control", "P"))
        MsgBox 48, %title%, Since something must be running in the box to analyse its registry`, creating a desktop shortcut to launch the unsandboxed Registry Editor is not supported.  Sorry.`n`nNote that creating a shortcut to a sandboxed Registry Editor is supported`, but on x64 systems you can launch it only in sandboxes with the Drop Rights restriction disabled.
    else
    {
        box := getBoxFromMenu()
        ; ensure that the box is in use, or the hive will not be loaded
        run_pid := InitializeBox(box)
        ; pre-select the right registry key
        RegWrite, REG_SZ, HKEY_CURRENT_USER, Software\Microsoft\Windows\CurrentVersion\Applets\Regedit, LastKey, HKEY_USERS\Sandbox_%username%_%box%
        ; launch regedit
        RunWait, RegEdit.exe, , UseErrorLevel
        ReleaseBox(run_pid)
    }
Return

UninstallMenuHandler:
    box := getBoxFromMenu()
    if (GetKeyState("Control", "P"))
        writeSandboxedShortcutFileToDesktop(start,"Uninstall Programs","","/box:" box " appwiz.cpl","Uninstall or installs programs in sandbox " box,shell32,22,1, box)
    else
        runWait, %start% /box:%box% appwiz.cpl, , UseErrorLevel
Return

TerminateMenuHandler:
    box := getBoxFromMenu()
    if (GetKeyState("Control", "P"))
        writeUnsandboxedShortcutFileToDesktop(start,"Terminate Programs in sandbox " box,"","/box:" box " /terminate","Terminate all programs running in sandbox " box,shell32,220,1)
    else
        runWait, %start% /box:%box% /terminate, , UseErrorLevel
Return

DeleteBoxMenuHandler:
    box := getBoxFromMenu()
    if (GetKeyState("Control", "P")) {
        writeUnsandboxedShortcutFileToDesktop(start,"! Delete sandbox " box " !","","/box:" box " delete_sandbox","Deletes the sandbox " box,shell32,132,1)
        msgbox, 48, %title%, Warning!  Unlike when Delete Sandbox is run from the SandboxToys menu`, the desktop shortcut that has been created doesn't ask for confirmation!`n`nUse the shortcut with care!
    } else {
        msgbox, 289, %title%, Are you sure you want to delete the sandbox "%box%"?
        ifMsgbox, Cancel, Return
        runWait, %start% /box:%box% delete_sandbox, , UseErrorLevel
    }
Return

SExploreMenuHandler:
    box := getBoxFromMenu()
    if (GetKeyState("Control", "P"))
        writeSandboxedShortcutFileToDesktop(start,"Explore sandbox " box " (Sandboxed)","","/box:" box " explorer.exe","Launches Explorer sandboxed in sandbox " box,"explorer.exe",1,1, box)
    else
        run, %start% /box:%box% explorer.exe, , UseErrorLevel
Return

UExploreMenuHandler:
    box := getBoxFromMenu()
    path := sandboxes_array[box,"path"]
    if (GetKeyState("Control", "P"))
        writeUnsandboxedShortcutFileToDesktop(WinDir "\explorer.exe","Explore sandbox " box " (Unsandboxed)",path,A_Quotes path A_Quotes,"Launches Explorer unsandboxed in sandbox " box,"explorer.exe",1,1)
    else
        run, explorer.exe "%path%", , UseErrorLevel
Return

URExploreMenuHandler:
    box := getBoxFromMenu()
    path := sandboxes_array[box,"path"]
    if (GetKeyState("Control", "P"))
        writeUnsandboxedShortcutFileToDesktop(WinDir "\explorer.exe","Explore sandbox " box " (Unsandboxed, restricted)",path,"/root`,"A_Quotes path A_Quotes,"Launches Explorer unsandboxed and restricted to sandbox " box,"explorer.exe",1,1)
    else
        run, explorer.exe /root`,"%path%", , UseErrorLevel
Return

LaunchSbieCtrlMenuHandler:
    if (GetKeyState("Control", "P"))
        writeUnsandboxedShortcutFileToDesktop(sbiectrl,"Sandboxie Control","","","Launches Sandboxie Control","","",1)
    else
        run, %sbiectrl%, , UseErrorLevel
Return

ListFilesMenuHandler:
    box := getBoxFromMenu()
    path := sandboxes_array[box,"path"]
    ListFiles(box, path)
Return

ListRegMenuHandler:
    box := getBoxFromMenu()
    path := sandboxes_array[box,"path"]
    ListReg(box, path)
Return

ListAutostartsMenuHandler:
    box := getBoxFromMenu()
    path := sandboxes_array[box,"path"]
    ListAutostarts(box, path)
Return

WatchRegMenuHandler:
    box := getBoxFromMenu()
    path := sandboxes_array[box,"path"]
    comparefile = %temp%\sandbox_%username%_%box%_reg_compare.cfg
    MakeRegConfig(box, comparefile)
    MsgBox, 38, %title%, The current state of the registry of sandbox "%box%" has been saved.`n`nYou can now work in the box.  When finished`, click Continue, and the new state of the registry will be compared with the old state`, and the result displayed so that you can analyse the changes`, and export them as a REG file if you wish.`n`nNote that the registry keys and the deleted registry values will not be listed.  However, a deleted key or value will be listed if it is present in the "real world".`n`n*** Click Continue ONLY when ready! ***
    ifMsgBox Continue
        ListReg(box, path, comparefile)
    ifMsgBox TryAgain
        GoSub, WatchRegMenuHandler
Return

WatchFilesMenuHandler:
    box := getBoxFromMenu()
    path := sandboxes_array[box,"path"]
    comparefile = %temp%\sandbox_%username%_%box%_files_compare.cfg
    MakeFilesConfig(box, comparefile, path)
    MsgBox, 38, %title%, The current state of the files in sandbox "%box%" has been saved.`n`nYou can now work in the box.  When finished`, click Continue, and the new state of the files will be compared with the old state`, and the result displayed so that you can analyse the changes`, and export the modified or new files if you wish.`n`nNote that the folders and the deleted files will not be listed.  However, a deleted folder or file will be listed if it is present in the "real world".`n`n*** Click Continue ONLY when ready! ***
    ifMsgBox Continue
        ListFiles(box, path, comparefile)
    ifMsgBox TryAgain
        GoSub, WatchFilesMenuHandler
Return

WatchFilesRegMenuHandler:
    box := getBoxFromMenu()
    path := sandboxes_array[box,"path"]
    comparefile1 = %temp%\sandbox_%username%_%box%_files_compare.cfg
    MakeFilesConfig(box, comparefile1, path)
    comparefile2 = %temp%\sandbox_%username%_%box%_reg_compare.cfg
    MakeRegConfig(box, comparefile2)
    MsgBox, 38, %title%, The current state of the files and registry of sandbox "%box%" has been saved.`n`nYou can now work in the box.  When finished`, click Continue, and the new state of the files and registry will be compared with the old state`, and the result displayed so that you can analyse the changes.`n`nNote that the folders, the deleted files, the registry keys and the deleted registry values will not be listed.  However, a deleted folder, file, key or value will be listed if it is present in the "real world".`n`n*** Click Continue ONLY when ready! ***
    ifMsgBox Continue
    {
        ListFiles(box, path, comparefile1)
        ListReg(box, path, comparefile2)
    }
    ifMsgBox TryAgain
        GoSub, WatchFilesRegMenuHandler
Return


SetupMenuMenuHandler1:
    if (largeiconsize > 16) {
        largeiconsize = 16
        Menu, SBMenuSetup, UnCheck, Large main-menu and box icons?
    } else {
        largeiconsize = 32
        Menu, SBMenuSetup, Check, Large main-menu and box icons?
    }
    IniWrite, %largeiconsize%, %sbtini%, AutoConfig, LargeIconSize
Return
SetupMenuMenuHandler2:
    if (smalliconsize > 16) {
        smalliconsize = 16
        Menu, SBMenuSetup, UnCheck, Large sub-menu icons?
    } else {
        smalliconsize = 32
        Menu, SBMenuSetup, Check, Large sub-menu icons?
    }
    IniWrite, %smalliconsize%, %sbtini%, AutoConfig, SmallIconSize
Return
SetupMenuMenuHandler3:
    if (seperatedstartmenus) {
        seperatedstartmenus = 0
        Menu, SBMenuSetup, UnCheck, Seperated All Users menus?
    } else {
        seperatedstartmenus = 1
        Menu, SBMenuSetup, Check, Seperated All Users menus?
    }
    IniWrite, %seperatedstartmenus%, %sbtini%, AutoConfig, SeperatedStartMenus
Return
SetupMenuMenuHandler4:
    if (includeboxnames) {
        includeboxnames = 0
        Menu, SBMenuSetup, UnCheck, Include [#BoxName] in shortcut names?
    } else {
        includeboxnames = 1
        Menu, SBMenuSetup, Check, Include [#BoxName] in shortcut names?
    }
    IniWrite, %includeboxnames%, %sbtini%, AutoConfig, IncludeBoxNames
Return


MainHelpMenuHandler:
    msgbox, 64, %title%, %title%`n`nSandboxToys2 Main Menu usage:`n`nThe main menu displays the shortcuts present in the Start Menu, Desktop and QuickLaunch folders of your sandboxes.  Just select any of these shortcuts to launch the program, sandboxed in the right box.  Of course, there must be programs installed in your sandboxes, or the menus will not be displayed.`n`nNote also that you can create easily a "sandboxed shortcut" on your real destkop to launch any program displayed in the SandboxToys menu even easier!  Just Control-Click on the menu entry, and the shortcut will be created on your desktop.  (Note: This work also with most icons of the Explore, Registry and Tools menu.)`n`nSimilarly, Shift-clicking on a menu icon opens the folder containing the file.  The Windows explorer is run sandboxed.`n`nSandboxToys2 offers also some tools in its Explore, Registry and Tools Menus.  They should be self-explanatory.`nUnlike the method explained above, Tools -> New Sandboxed Shortcut creates a sandboxed shortcut on your desktop to any unsandboxed file located in your real discs.`n`nThe User Tools menu is a configurable menu, that can contain almost anything you want.  To use it, place a (normal or sandboxed) shortcut in the "%usertoolsdir%" folder, and it will be displayed in the User Tools menu.  Note that the tools launched via that menu are run unsandboxed, unless the shortcut itself is sandboxed (ie it uses Sandboxie's Start.exe to launch the command).  You can create sub-menus in the User Tools menu by placing shortcuts in folders within the "%usertoolsdir%" folder.
CmdLineHelp:
    msgbox, 64, %title%, %title%`n`nSandboxToys2 Command Line usage:`n`n> SandboxToys2 [/box:boxname]`nWithout arguments, SandboxToys2 opens its main menu, waits for a selection, execute it and then exits immediately.`nThe optional argument /box:boxname can be used to restrict the menu to a single sandbox.`n`n> SandboxToys2 [/box:boxname] /tray`nSandboxToys2 stays resident in the tray.`nClick the tray icon to launch the main SandboxToys menu.`nRight-click the tray icon to exit SandboxToys.`n`n> SandboxToys2 [/box:boxname] "existing file, folder or shortcut"`nCreates a new sandboxed shortcut on the desktop.  If the /box:boxname argument is not present, you will need to select the target box in a menu.`nIt is recommended to create a shortcut to SandboxToys in your SendTo folder to easily create sandboxed shortcuts to any file or folder.`nYour SendTo folder should be:`n"%appdata%\Microsoft\Windows\SendTo"`n`nNote: The SandboxToys2.ini file holds the settings of SandboxToys.  It should be in "%APPDATA%\SandboxToys2\" or in the same folder than the SandboxToys2 executable.  The name of the INI file is the same than the name of the SandboxToys2 executable file, so if you rename SandboxToys2.exe, you should rename also SandboxToys2.ini.`nSimilarly, the name of the "SandboxToys2_UserTools" folder depends of the name of SandboxToys2.exe, and it should be also in your APPDATA folder or in the SandboxToys2.exe folder.`nThis allows you to run several instances of SandboxToys2 with different configurations and/or user tools.
Return

DummyMenuHandler:
Return

ExitMenuHandler:
ExitApp
