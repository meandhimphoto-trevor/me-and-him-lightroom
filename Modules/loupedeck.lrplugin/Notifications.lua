local LrDialogs	= import "LrDialogs"

NOTIFICATIONS = {
	WELCOME      = "Loupedeck thinks you look great today.",
	MODE_RATINGS = "Loupedeck is using Star ratings.",
	MODE_COLORS = "Loupedeck is using Colour ratings.",
	COPY		= "Develop settings copied from current photo.",
	PASTE		= "Develop settings applied to selected photo(s).",
	NO_MATCH	= "Did not found any matching images.",
}

function showNotification( notification )
	
	if(NOTIFICATIONS[notification] == nil) then return end

	LrDialogs.showBezel(NOTIFICATIONS[notification], 3)
end

function showMatchingImagesNotification( count )
	local s = count > 1 and "Found "..count.." matching images" or "Found 1 matching image"
	LrDialogs.showBezel(s, 3)
end

function showSetColorRatingNotification( rating )
	local s = rating == "none" and "Removed color label" or "Set color label to "..rating
	LrDialogs.showBezel(s,3)
end