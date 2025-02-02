local function AddWorldButtons(inName)
	result = "<form method='POST'><input type='hidden' name='WorldName' value='" .. inName .. "'>"
	result = result .. "<input type='submit' name='SetTime' value='清晨'>"
	result = result .. "<input type='submit' name='SetTime' value='正午'>"
	result = result .. "<input type='submit' name='SetTime' value='黄昏'>"
	result = result .. "<input type='submit' name='SetTime' value='夜晚'>"
	result = result .. "<input type='submit' name='SetTime' value='午夜'>"
	result = result .. "<input type='submit' name='SetWeather' value='晴朗'>"
	result = result .. "<input type='submit' name='SetWeather' value='下雨'>"
	result = result .. "<input type='submit' name='SetWeather' value='雷暴'></form>"
	return result
end

function HandleRequest_Weather(Request)
	if (Request.PostParams["WorldName"] ~= nil) then		-- World is selected!
		workWorldName = Request.PostParams["WorldName"]
		workWorld = cRoot:Get():GetWorld(workWorldName)
		if( Request.PostParams["SetTime"] ~= nil ) then
			-- Times used replicate vanilla: http://minecraft.gamepedia.com/Day-night_cycle#Commands
			if (Request.PostParams["SetTime"] == "Dawn") then
				workWorld:SetTimeOfDay(0)
				LOG("Time set to dawn in " .. workWorldName)
			elseif (Request.PostParams["SetTime"] == "Day") then
				workWorld:SetTimeOfDay(1000)
				LOG("Time set to day in " .. workWorldName)
			elseif (Request.PostParams["SetTime"] == "Dusk") then
				workWorld:SetTimeOfDay(12000)
				LOG("Time set to dusk in " .. workWorldName)
			elseif (Request.PostParams["SetTime"] == "Night") then
				workWorld:SetTimeOfDay(14000)
				LOG("Time set to night in " .. workWorldName)
			elseif (Request.PostParams["SetTime"] == "Midnight") then
				workWorld:SetTimeOfDay(18000)
				LOG("Time set to midnight in " .. workWorldName)
			end
		end
		
		if (Request.PostParams["SetWeather"] ~= nil) then
			if (Request.PostParams["SetWeather"] == "Sun") then
				workWorld:SetWeather(wSunny)
				LOG("Weather changed to sun in " .. workWorldName)
			elseif (Request.PostParams["SetWeather"] == "Rain") then
				workWorld:SetWeather(wRain)
				LOG("Weather changed to rain in  " .. workWorldName)
			elseif (Request.PostParams["SetWeather"] == "Storm") then
				workWorld:SetWeather(wStorm)
				LOG("Weather changed to storm in " .. workWorldName)
			end
		end
	end
	
	return GenerateContent()
end

function GenerateContent()
	local content = "<h4>操作:</h4><br>"
	local worldCount = 0
	local AddWorldToTable = function( inWorld )
		worldCount = worldCount + 1
		content = content.."<tr><td style='width: 10px;'>"..worldCount..".</td><td>"..inWorld:GetName().."</td>"
		content = content.."<td>"..AddWorldButtons( inWorld:GetName() ).."</td></tr>"
	end
	
	content = content.."<table>"
	cRoot:Get():ForEachWorld( AddWorldToTable )
	if( worldCount == 0 ) then
		content = content.."<tr><td>不存在的世界! O_O</td></tr>"
	end
	content = content.."</table>"
	
	return content
end
