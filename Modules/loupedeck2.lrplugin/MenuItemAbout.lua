require 'Globals'
trace('About')

local header = string.format("Loupedeck plugin v%d.%d.%d", plugin.version.major, plugin.version.minor, plugin.version.revision)
local message = string.format("Copyright © %d LoupeDeck Oy. All rights reserved.", os.date("*t").year)

import 'LrDialogs'.message(header, message, "info");
