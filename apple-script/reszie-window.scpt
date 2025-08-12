tell application "System Events"
	set frontApp to name of first application process whose frontmost is true
end tell

-- Get screen dimensions
tell application "Finder"
	set screenBounds to bounds of window of desktop
end tell

set screenLeft to item 1 of screenBounds
set screenTop to item 2 of screenBounds
set screenRight to item 3 of screenBounds
set screenBottom to item 4 of screenBounds

set screenWidth to screenRight - screenLeft
set screenHeight to screenBottom - screenTop

-- Set window size to 4/5 (0.8) of screen size
set newWidth to screenWidth * 0.9
set newHeight to screenHeight * 0.8
set newLeft to screenLeft + (screenWidth - newWidth) / 2
set newTop to screenTop + (screenHeight - newHeight) / 2
set newRight to newLeft + newWidth
set newBottom to newTop + newHeight

tell application "System Events"
	tell application process frontApp
		try
			set position of front window to {newLeft, newTop}
			set size of front window to {newWidth, newHeight}
		end try
	end tell
end tell
