
return {

	LrSdkVersion = 6.0,
	LrSdkMinimumVersion = 6	, -- minimum SDK version required by this plug-in

	LrToolkitIdentifier = 'com.LoupeDeck.Loupedeck',

	LrPluginName = "Loupedeck",

  	LrInitPlugin = "InitPlugin.lua" ,
  	LrShutdownApp = "ShutdownApp.lua",

  	LrForceInitPlugin = true,

	-- Add the menu item to the File menu.
	LrExportMenuItems = {
		title = "About",
		file = "VersionInfoMenuItem.lua",
	},

	VERSION = { major=1, minor=3, revision=0, build=191},
}


