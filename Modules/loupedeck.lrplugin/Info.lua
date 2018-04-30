
return {

	LrSdkVersion = 6.0,
	LrSdkMinimumVersion = 6	, -- minimum SDK version required by this plug-in

	LrToolkitIdentifier = 'com.LoupeDeck.Loupedeck',

	LrPluginName = "Loupedeck",

  	LrInitPlugin = "InitPlugin.lua" ,
  	LrShutdownPlugin = "ShutdownPlugin.lua",
  	LrShutdownApp = "ShutdownApp.lua",

  	LrEnablePlugin = "EnablePlugin.lua",
  	LrDisablePlugin = "DisablePlugin.lua",

  	LrForceInitPlugin = true,

	-- Add the menu item to the File menu.
	LrExportMenuItems = {
		title = "About",
		file = "VersionInfoMenuItem.lua",
	},

	VERSION = { major=1, minor=5, revision=1, build=201 },
}


