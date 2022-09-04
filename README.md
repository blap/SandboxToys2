# SandboxToys2
SandboxToys2 by r0lZ updated by blap

Original file from: https://sandboxie-website-archive.github.io/www.sandboxie.com/old-forums/viewtopic33fc33fc.html?f=22&t=2028

Original README file:

SandboxToys2 is a freeware tool to facilitate the use of Sandboxie, and especially to launch programs and open files located in your sandbox.

SandboxToys2 is designed to run under Windows 7 (x32 or x64).  It works probably under Vista as well, but this hasn't been tested.  Do not try to run it under an earlier system, as it will certainly not work properly.


-------------------------------------------------------------------------------
Installation
-------------------------------------------------------------------------------

There is no installer, but it is sufficient to copy SandboxToys2.exe in any folder, and to create a shortcut to that file in your Start Menu or your desktop, or to pin it to your Launch bar.

Additionnaly, it might be a good idea to create a shortcut to SandboxToys2 in your SendTo folder (normally "C:\Users\<your user name>\AppData\Roaming\Microsoft\Windows\SendTo").  Rename that shortcut "Sandboxed shortcut".  More on this later.

When SandboxToys2 is run for the first time, it creates a folder in your APPDATA folder (usually "C:\Users\<your user name>\AppData\Roaming\SandboxToys2").  Its configuration options are stored in the INI file in that new folder.  (Nothing is stored in the registry.)  Also, a SandboxToys2_UserTools empty folder is created there, where you can place shortcuts to the tools you would like to access easily from the SandboxToys2 menu.  See below.

Note: it is possible to store the configuration file (SandboxToys2.ini) and the UserTools folder in the same folder than the SandboxToys2 executable, but if you want to do that, you have to store SandboxToys2.exe in a folder where you have full access rights.  Then, simply move the INI file and the UserTools folder in that folder.

If you want to use ST_Toggle_DropAdminRights (that allows you to change the DropAdminRights option of any sandbox with a simple click), copy DropAdminRights.exe as well, and then right-click it and select Properties.  In the Compatibility tab, tick the "Run this program as an administrator" option.  (Administrator rights are necessary to be able to modify the Sandboxie configuration file, located in a protected folder.)

SandboxToys2 has several tools to display, monitor and report changes of the registry of your sandboxes.  Since many registry keys are modified anyway by Sandboxie when a box is created, it is useless to display and monitor them.  So, when SandboxToys2 is run for the first time, it tries to locate an empty box, and it initialize it, then it records the registry content in a file that is used later to know which registry keys should not be included in the reports.  If no empty box is found, SandboxToys2 does nothing, but it will retry the next time it is run.  So, it is a good idea to launch it at least once with an empty box.


-------------------------------------------------------------------------------
The SandboxToys2 menu
-------------------------------------------------------------------------------

When SandboxToys2.exe is launched, it displays a popup menu under your mouse pointer.  The content of that menu depends of the content of your sandboxes, and of your UserTools folder.

Boxes sub-menus:

It contains a sub-menu for each of your sandboxes.  Each sandbox menu has a sub-menu containing the shortcuts installed in the Start menu, Desktop and QuickLaunch folders of the sandbox.  Unlike the regular Sandboxie Start Menu, only the shortcuts present in the sandbox are displayed in the menu.  The sub-menu is present only if some shortcuts are present in the corresponding folder of your sandbox.  That means that the sub-menus will not be present if nothing has been installed in the sandbox.

To launch a program or open a document in the sandbox, just select it in the menu.

You can also press the SHIFT key when you select the program or document, and instead of launching it, SandboxToys2 will open a sandboxed Windows Explorer right on the Folder containing the shortcut.

If you press the CONTROL key when you select a program or document, a "sandboxed shortcut" to that program or document will be placed on your (real) desktop.  You will then be able to easily launch the program or document in the sandbox just by double-clicking the shortcut.

Note that the icons of the box menus are different when a box is empty (the yellow icon) and when it has been initialized (icon with the red dots).  Unlike SandboxieControl, the red dots do not mean that something is currently running in the box.


- Sandboxie's Start Menu:

Launch the regular StartMenu of Sandboxie in the sandbox.


- Sandboxie's Run Dialog:

Launch the regular Run dialog of Sandboxie in the sandbox.


- Explore sub-menu:

That sub-menu contains several tools to launch the Windows Explorer, sandboxed or not, in the current sandbox.  It contains also two tools to view and watch changes to the files in the sandbox.  More on this later.


- Registry sub-menu:

Similar to the Explore menu, this menu contains tools to launch the Windows Registry Editor, sandboxed or not, to easily examine or modify the registry of the sandbox.  It contains also tools to view and watch the registry changes in your sandbox.  More on this later.  Finally, it contains a tool to show and optionally launch the programs that are installed in the Autostart (Run keys) of the registry.  That option allows you to easily launch the programs that are supposed to be launched automatically when Windows start, but that Sandboxie doesn't launch automatically.


- Tools sub-menu:

Each sandbox has also a Tools menu containing tools to create sandboxed shortcuts, monitor file and registry changes, launch the Windows Command Prompt (sandboxed or not), install or uninstall programs and features in the sandbox, kill all programs currently running in the sandbox, and delete the content of the sandbox.

Note that some tools are available only when there is something in the sandbox, as it doesn't make sense to launch them if the sandbox is empty.  Also, some tools are present only if the DropAdminRights option is off.  For example, the "Programs and Features" option is not present if DropAdminRights option is off as to use it, you need to have the administrator rights.

Most of the tools of the Explore, Registry and Tools sub-menus can be Control-Clicked to create a shrtcut to that tool on your desktop.  For example, if you Control-click the "Terminate Sandboxed Programs!" tool in the menu of your DefaultBox, a shortcut "Terminate Programs in sandbox DefaultBox" will be created on your desktop.


- User Tools menu:

If you create or copy some shortcuts (sandboxed or not) or files in the SandboxToys2_UserTools folder (in APPDATA), then the global User Tools menu will be visible, and in that menu, you will see the shortcuts or files that are in the folder.  Note that it is possible to define sub-menus in that menu as well.  Just creates sub-folders in the UserTools folder, and place your shortcuts in them.

The User Tools menu is global, and not tied to any particular sandbox.  That means that the tools of that menu are not launched sandboxed.  If you want to launch a user tool sandboxed, you have to create a sandboxed shortcut.  For example, to launch Notepad sandboxed, the command line of the shortcut should be something like this:
"C:\Program Files\Sandboxie\Start.exe" /box:DefaultBox "C:\Windows\System32\notepad.exe"


- Options menu:

"About and Help" shows two dialogs with the version number of SandboxToys2 and a short help.

"Large main-menu and box icons": Use big icons in the top level menu, and in the box-sub menus.

"Large sub-menu icons": Use big icons in the box, explorer, registry, tools and user tools sub-menus.

"Seperated All Users menus": Normally, the Current User and All Users start menus and desktops are merged, like Windows does.  With this option, you can display them as different sub-menus.  This is handy to see if a program has been installed for all users or for the current user only.

"Include [#BoxName] in shortcut names": When SandboxToys2 creates a sandboxed shortcut, it adds the name of the box in which the probram will run in the shortcut name.  If you use the free version of Sandboxie, you might want to turn that option off.


-------------------------------------------------------------------------------
Viewing, modifying and exporting files and registry keys
-------------------------------------------------------------------------------

In the Explore, Registry and Tools menus of SandboxToys2, you will find options to show the content of the box in listview windows.  This allows you to easily see what files and registry keys have been installed in the box.
Note that, unlike with the Explorer or the Registry Editor, those tools show you when a file or registry key has been deleted in the box but exists in your real system.  Sandboxie uses a trick (based to the file or key creation date) to mark a file or key as deleted.  Unfortunately, if you run the Windows Explorer or Registry Editor unsandboxed, there is no easy way to see if a file is deleted or really present in the box, as both are displayed the same way.  In the SandboxToys2 list views, the Status column contains a "+" when the file has been created in the box and doesn't exist in your real system, a "-" when the file exists in the real system and has been deleted in the box, and a "#" when the file exists in your real system and in the box.  (Note that "#" doesn't mean that the file has been modified in the box.  It might just have been recreated with the same content.)

There are two menus in the listviews.  The file menu allows you to export the files or registry values to your real system.

With the Files listview, it is also possible to add shortcut to any file in the Start Menu or Desktop of the current box, and to create a sandboxed shortcuts on your real desktop.

The registry (.REG) file created when you export key values to your real system contains the keys corresponding to your real system.  That means that when you double-click the file, its content is added to your REAL registry.  You can, of course, run the REG file in a sandbox to adds or replces the corresponding keys of the sandboxed registry.

Most of the items of the Edit menu of the listviews should be self-explanatory.


The Ignore Lists:

Add Selected Files (or Values)/Folders (or Keys) to Ignore List:
Normally, all files or registry values are displayed in the listview.  However, usually, some files or values are not useful.  It is therefore possible to exclude them from the listview.

Note that adding a Folder (or Key) to the Ignore List hides all values of that folder (or key) but also all sub-folders (or sub-keys) and their values.  So, use this option with caution.

Note also that the file containing the list of suppressed items are global to all sandboxes and are NOT destroyed automatically when a box is emptied.  That means that this setting is permanent, and applied to all sandboxes.  (It is however possible to manually delete or edit the config files.  They are stored in the SandboxToys2 configuration folder.)

Finally, note that folders without files or keys without values are never displayed in the listview.

Important note:

When a box is created, Sandboxie stores immediately some registry keys that it needs to overwrite to work properly.  Since that keys are necessary for Sandboxie but not (normally) accessed by the programs you install in the sandboxes, they should be excluded anyway.  So, when the Registry Exclude List file doesn't exist whan SandboxToys is launched, it tries to create a list with the default exclude list.  For this to work, it needs an empty box.  This is why it is a good idea to launch SandboxToys2 at least once with an empty box.
You can of course add the registry values to the list manually, but that's really not easy!


-------------------------------------------------------------------------------
Watching files and registry changes
-------------------------------------------------------------------------------

There are 3 functions to watch the files and registry changes in your sandbox.  Explore -> Watch Files Changes and Registry -> Watch Registry Changes watch only the files or registry changes respectively.  Tools -> Watch Files and Registry Changes watch both the files and registry changes.

To use those functions, launch the watch function you need.  SandboxToys2 now records a temporary file (stored in your %TEMP% folder), similar to the Exclude List files but containing all items present in your sandbox.  After that, it shows you a dialog.  Do NOT close that dialog box.  Launch anything you want in the box.  You can, for example, install a new program.   When done, click the Continue button.  SandboxToys2 scans the folders or registry again, and when it has finished, it displays the files or registry values that have been modified since the first scan.

Ths listviews used by the Watch functions are exactly identical than the one described in the previous section, so you can also export the changes if you wish.

Note: Clicking the Try Again button of the dialog restarts the operation and rescans the box.

-------------------------------------------------------------------------------
Command line options
-------------------------------------------------------------------------------

SandboxToys2 works as explained above when you launch it without any option.  It is possible to modify its behavior with the following command line options:

/box:boxname
With this option, SandboxToys2 is restricted to a single box.  It will show you only the content of the specified box, and the box sub-menus are suppressed.  (The Start Menu, Desktop, QuickLaunch and Tools menus are placed immediately in the root of the popup menu.)
This option can also be used in conjunction with the following options.

/tray
Normally, when SandboxToys2 is launched, it opens its menu, and launches whatever you want to launch, then SandboxToys2 is closed.  With the /tray option, SandboxToys2 stays resident in the tray, and you can open its menu simply by clicking its icon in the tray.  Launching it this way is a bit faster, but it consumes some memory.
This option can be used in conjunction with the /box option to display the content of a specific box only.

"filename"
When a file name is passed as an argumnent to SandboxToys2, a sandboxed shortcut to that file is created on your real desktop.  If the /box option is not specified and you have several sandboxes, SandboxToys2 will display a little menu in which you can select the box to use for the shortcut (or "__ask__" if you want to be prompted each time you launch the shortcut).
To use this feature easlly, it is recommended to put a shortcut to SandboxToys2 in your SendTo menu (normally "C:\Users\<your user name>\AppData\Roaming\Microsoft\Windows\SendTo").  Rename it "Sandboxed Shortcut".  This way, to create a sandboxed shortcut to any file, just right-click the file and select Sandboxed Shortcut.
It is also possible to put a shortcut to SandboxToys2 on your desktop.  Drag and drop any file over that shortcut to create the sandboxed shortcut.


-------------------------------------------------------------------------------
Creating several instances of SandboxToys2
-------------------------------------------------------------------------------

If you want to launch SandboxToys2 with different configurations (for example for different sandboxes), you can simply copy SandboxToys2.exe under a different name.  All configuration files (and the UserTools folder) are named upon the name of the executable file.  It is therefore possible to define several different configurations for the different instances of the program.
It is even possible to change the tray icon of a particular instance by editing manually its INI file.


-------------------------------------------------------------------------------
SandboxToys2.ini
-------------------------------------------------------------------------------

SandboxToys2.ini holds the configuration options of SandboxToys2.  It is created in the "%APPDATA%\SandboxToys2\" folder when SandboxToys2 is launched for the first time.  If you prefer, you can move that file (and the other files in the same folder) in the same folder than SandboxToys2.exe, if you have full access rights on that folder.  The other configuration files will be saved automatically in the folder containing SandboxToys2.ini.

As explained earlier, the name of the ini file depends of the name of the exe file, so if you rename SandboxToys2.exe, a new ini file will be created again in your APPDATA folder.

There are two sections in the ini file.  The [AutoConfig] section is generated automatically, and corresponds to the options you can change with the Options sub-menu.  You should not need to edit that section.

Note that the LargeIconSize and SmallIconSize options in the [AutoConfig] section are normally set to 16 or 32, but can be set manually to another size, such as 24.  However, using a non-standard size for the icons is not recommended.

The [UserConfig] section holds some options that you can modify only by editing the ini file:

TrayIconFile and TrayIconNumber allows you to change the icon that is displayed in the tray when SandboxToys2 is launched with the /tray command line argument.  By default, TrayIconFile is not specified, and that means that the internal icon of SandboxToys2.exe is used.

SandboxedCommandPromptDir is the default path to open in the Sandboxed Command Prompt.  That folder must exist (in your real system), or your system drive (usually C:\) will be used.  Environment variables (such as %systemdrive%) can be used.  Do not put quotes around the path name.  The default is %userprofile%.
For technical reasons, it is not possible to define the default path for the Unsandboxed Command Prompt.


-------------------------------------------------------------------------------
ST_Toggle_DropAdminRights
-------------------------------------------------------------------------------

This is a simple tool to toggle the state of the DropAdminRights option of any sandbox.  If, like me, you are running Sandboxie under an x64 system, you know that is is not possible to install a program in a sandbox when DropAdminRights is enabled.  But when DropAdminRights is disabled, your system is not completely immune to viruses.  So, it is important to disable DropAdminRights only when it's absolutely necessary.  Since it is relatively difficult to access that option with the standard Sandboxie GUI, I wrote ST_Toggle_DropAdminRights.  It must be run with administrative rights, as the program must modify the content of the Sandboxie INI file, that is normally stored in a protected folder.

By default this program toggles the DropAdminRights option of your DefaultBox box.  To use it with another box, you have to use the command line option /box:boxname.

Note that Sandboxie will take the new state ot the DropAdminRights option into account only the next time you open something in the box.  It is therefore recommended to use ST_Toggle_DropAdminRights only when nothing is currently running in the box.

This tool is not included with the main SandboxToys2 executable, as it would require you to run the main program with administrative rights.  Also, x32 users do not need it.


-------------------------------------------------------------------------------
Known bugs
-------------------------------------------------------------------------------

- You might see sometimes a message from Sandboxie telling that it is unable to unload the registry hive.  I haven't been able to understand why this happens sometimes, but anyway, it's not really important.  The message means that, even if there is nothing running in the box, the registry keys specific to the box are still tied to your real registry.  The next time you run something in the box, the registry hive will be replaced anyway, and it will (hopefully) be unloaded successfully when needed.  To force Sandboxie to retry to unload the hive, you can for example run any tool in the box, and close it.

- Sometimes, the icon of a document in the Start Menu, Desktop or QuickStart menus is not the right icon associated with that file type.  (It is not always easy to find the right icon.  That doesn't mean that the shortcut itself points to a wrong file!)

- The Internet Shortcut (.URL) files cannot be launched sandboxed. (It's a Sandboxie bug.)


Have fun!

