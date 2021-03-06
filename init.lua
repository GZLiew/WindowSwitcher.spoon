-- Fuzzy Window Switcher

_fuzzyChoices = nil
_fuzzyChooser = nil
_fuzzyLastWindow = nil

function fuzzyQuery(s, m)
	s_index = 1
	m_index = 1
	match_start = nil
	while true do
		if s_index > s:len() or m_index > m:len() then
			return -1
		end
		s_char = s:sub(s_index, s_index)
		m_char = m:sub(m_index, m_index)
		if s_char == m_char then
			if match_start == nil then
				match_start = s_index
			end
			s_index = s_index + 1
			m_index = m_index + 1
			if m_index > m:len() then
				match_end = s_index
				s_match_length = match_end-match_start
				score = m:len()/s_match_length
				return score
			end
		else
			s_index = s_index + 1
		end
	end
end

function _fuzzyFilterChoices(query)
	if query:len() == 0 then
		_fuzzyChooser:choices(_fuzzyChoices)
		return
	end
	pickedChoices = {}
	for i,j in pairs(_fuzzyChoices) do
		fullText = (j["text"] .. " " .. j["subText"]):lower()
		score = fuzzyQuery(fullText, query:lower())
		if score > 0 then
			j["fzf_score"] = score
			table.insert(pickedChoices, j)
		end
	end
	local sort_func = function( a,b ) return a["fzf_score"] > b["fzf_score"] end
	table.sort(pickedChoices, sort_func)
	_fuzzyChooser:choices(pickedChoices)
end

function _fuzzyPickWindow(item)
	if item == nil then
		if _fuzzyLastWindow then
			-- Workaround so last focused window stays focused after dismissing
			_fuzzyLastWindow:focus()
			_fuzzyLastWindow = nil
		end
		return
	end
	-- saveTime(6)
	id = item["windowID"]
	window = hs.window.get(id)
	window:focus()
end

function swapPositions(dataTable, indexOne, indexTwo)
  temp = dataTable[indexOne]
  dataTable[indexOne] = dataTable[indexTwo]
  dataTable[indexTwo] = temp
end

function windowFuzzySearch()
	windows = hs.window.filter.default:getWindows(hs.window.filter.sortByFocusedLast)
	-- windows = hs.window.orderedWindows()
	_fuzzyChoices = {}
	for i,w in pairs(windows) do
		title = w:title()
		app = w:application():name()
		item = {
			["text"] = app,
			["subText"] = title,
			-- ["image"] = w:snapshot(),
			["windowID"] = w:id()
		}
		-- Handle special cases as necessary
		--if app == "Safari" and title == "" then
			-- skip, it's a weird empty window that shows up sometimes for some reason
		--else
			table.insert(_fuzzyChoices, item)
		--end
	end
  -- swap first and second
  swapPositions(_fuzzyChoices, 1, 2)

	_fuzzyLastWindow = hs.window.focusedWindow()
	_fuzzyChooser = hs.chooser.new(_fuzzyPickWindow):choices(_fuzzyChoices):searchSubText(true)
	_fuzzyChooser:subTextColor(hs.drawing.color.x11.snow)
	_fuzzyChooser:queryChangedCallback(_fuzzyFilterChoices) -- Enable true fuzzy find
	_fuzzyChooser:show()
end

local obj={}
obj.__index = obj

-- Metadata
obj.name = 'WindowSwitcher'
obj.version = '0.1'
obj.author = 'Guozhang <guozhangliew@gmail.com>'
obj.homepage = 'https://github.com/gzliew/WindowSwitcher.spoon'
obj.license = 'MIT - https://opensource.org/licenses/MIT'

function obj:init()
  hs.hotkey.bind({"alt"}, "space", function()
    windowFuzzySearch()
  end)
end

return obj

