
-- web_playerranks.lua

-- Implements the Player Ranks tab in the webadmin





--- Maximum number of players displayed on a single page.
local PLAYERS_PER_PAGE = 20

local ins = table.insert
local con = table.concat





--- Updates the rank from the ingame player with this uuid
local function UpdateIngamePlayer(a_PlayerUUID, a_Message)
	cRoot:Get():ForEachPlayer(
		function(a_Player)
			if (a_Player:GetUUID() == a_PlayerUUID) then
				if (a_Message ~= "") then
					a_Player:SendMessage(a_Message)
				end
				a_Player:LoadRank()
			end
		end
	)
end





--- Returns the HTML contents of the rank list
local function GetRankList(a_SelectedRank)
	local RankList = {}
	ins(RankList, "<select name='RankName'>")

	local AllRanks = cRankManager:GetAllRanks()
	table.sort(AllRanks)

	for _, Rank in ipairs(AllRanks) do
		local HTMLRankName = cWebAdmin:GetHTMLEscapedString(Rank)
		ins(RankList, "<option value='")
		ins(RankList, HTMLRankName)
		if (HTMLRankName == a_SelectedRank) then
			ins(RankList, "' selected>")
		else
			ins(RankList, "'>")
		end
		ins(RankList, HTMLRankName)
		ins(RankList, "</option>")
	end
	ins(RankList, "</select>")

	return con(RankList)
end





--- Returns the HTML contents of a single row in the Players table
local function GetPlayerRow(a_PlayerUUID)
	-- Get the player name/rank:
	local PlayerName = cRankManager:GetPlayerName(a_PlayerUUID)
	local PlayerRank = cRankManager:GetPlayerRankName(a_PlayerUUID)

	-- First row: player name:
	local Row = {"<tr><td>"}
	ins(Row, cWebAdmin:GetHTMLEscapedString(PlayerName))
	ins(Row, "</td><td>")

	-- Rank:
	ins(Row, cWebAdmin:GetHTMLEscapedString(PlayerRank))

	-- Display actions for this player:
	ins(Row, "</td><td><form style='float: left'>")
	ins(Row, GetFormButton("editplayer", "编辑", {PlayerUUID = a_PlayerUUID}))
	ins(Row, "</form><form style='float: left'>")
	ins(Row, GetFormButton("confirmdel", "移除权限", {PlayerUUID = a_PlayerUUID, PlayerName = PlayerName}))

	-- Terminate the row and return the entire concatenated string:
	ins(Row, "</form></td></tr>")
	return con(Row)
end





--- Returns the HTML contents of the main Rankplayers page
local function ShowMainPlayersPage(a_Request)
	-- Read the page number:
	local PageNumber = tonumber(a_Request.Params["PageNumber"])
	if (PageNumber == nil) then
		PageNumber = 1
	end
	local StartRow = (PageNumber - 1) * PLAYERS_PER_PAGE
	local EndRow = PageNumber * PLAYERS_PER_PAGE - 1

	-- Accumulator for the page data
	local PageText = {}
	ins(PageText, "<p><a href='?subpage=addplayer'>创建玩家</a>, <a href='?subpage=confirmclear'>清除玩家</a></p>")

	-- Add a table describing each player:
	ins(PageText, "<table><tr><th>玩家</th><th>权限</th><th>操作</th></tr>\n")
	local AllPlayers = cRankManager:GetAllPlayerUUIDs()
	for i = StartRow, EndRow, 1 do
		local PlayerUUID = AllPlayers[i + 1]
		if (PlayerUUID ~= nil) then
			ins(PageText, GetPlayerRow(PlayerUUID))
		end
	end
	ins(PageText, "</table>")

	-- Calculate the page num:
	local MaxPages = math.floor((#AllPlayers + PLAYERS_PER_PAGE - 1) / PLAYERS_PER_PAGE)

	-- Display the pages list:
	ins(PageText, "<table style='width: 100%;'><tr>")
	if (PageNumber > 1) then
		ins(PageText, "<td><a href='?PageNumber=" .. (PageNumber - 1) .. "'><b>&lt;&lt;&lt;</b></a></td>")
	else
		ins(PageText, "<td><b>&lt;</b></td>")
	end
	ins(PageText, "<th style='width: 100%; text-align: center;'>Page " .. PageNumber .. " of " .. MaxPages .. "</th>")
	if (PageNumber < MaxPages) then
		ins(PageText, "<td><a href='?PageNumber=" .. (PageNumber + 1) .. "'><b>&gt;&gt;&gt;</b></a></td>")
	else
		ins(PageText, "<td><b>&gt;</b></td>")
	end
	ins(PageText, "</tr></table>")

	-- Return the entire concatenated string:
	return con(PageText)
end





--- Returns the HTML contents of the player add page
local function ShowAddPlayerPage(a_Request)
	return [[
		<h4>创建玩家</h4>
		<form method="POST">
		<input type="hidden" name="subpage" value="addplayerproc" />
		<table>
			<tr>
				<th>玩家名:</th>
				<td><input type="text" name="PlayerName" maxlength="16" /></td>
			</tr>
			<tr>
				<th>玩家 UUID (短UUID):</th>
				<td>
					<input type="text" name="PlayerUUID" maxlength="32" />
					若此处留空，则由服务器自动生成随机 UUID
				</td>
			</tr>
			<tr>
				<th>权限</th>
				<td>]] .. GetRankList(cRankManager:GetDefaultRank()) .. [[</td>
			</tr>
			<tr>
				<td />
				<td><input type="submit" name="AddPlayer" value="创建" /></td>
			</tr>
		</table>
	</form>]]
end





--- Processes the AddPlayer page's input, creating a new player and redirecting to the player rank list
local function ShowAddPlayerProcessPage(a_Request)
	-- Check the received values:
	local PlayerName = a_Request.PostParams["PlayerName"]
	local PlayerUUID = a_Request.PostParams["PlayerUUID"]
	local RankName   = a_Request.PostParams["RankName"]
	if ((PlayerName == nil) or (PlayerUUID == nil) or (RankName == nil) or (RankName == "")) then
		return HTMLError("请求错误：缺少必要参数")
	end

	-- Check if playername is given
	if (PlayerName == "") then
		return [[
			<h4>创建玩家</h4>
			<p>未填写玩家名，或玩家名超过16个字符！</p>
			<p><a href="?subpage=addplayer">返回</a></p>
		]]
	end

	-- Search the uuid (if uuid line is empty)
	if (PlayerUUID == "") then
		if (cRoot:Get():GetServer():ShouldAuthenticate()) then
			PlayerUUID = cMojangAPI:GetUUIDFromPlayerName(PlayerName, false)
		else
			PlayerUUID = cClientHandle:GenerateOfflineUUID(PlayerName)
		end
	end

	-- Check if the uuid is correct
	if ((PlayerUUID == "") or (string.len(PlayerUUID) ~= 32)) then
		if (a_Request.PostParams["PlayerUUID"] == "") then
			return [[
				<h4>创建玩家</h4>
				<p>无效的 uuid. <a href="?subpage=addplayer">返回</a></p>
			]]
		else
			return [[
				<h4>创建玩家</h4>
				<p>无法找到玩家 ]] .. PlayerName .. [[ 的UUID!<br />
				可能此玩家不存在?</p>
				<p><a href="?subpage=addplayer">返回</a></p>
			]]
		end
	end

	-- Exists the player already?
	if (cRankManager:GetPlayerRankName(PlayerUUID) ~= "") then
		return [[
			<h4>创建玩家</h4>
			<p>创建失败！原因：已存在相同的 UUID</p>
			<p><a href="?subpage=addplayer">返回</a></p>
		]]
	end

	-- Add the new player:
	cRankManager:SetPlayerRank(PlayerUUID, PlayerName, RankName)
	UpdateIngamePlayer(PlayerUUID, "你已被 Web 管理赋予 " .. RankName .. " 权限")
	return "<p>已创建玩家 <a href='/" .. a_Request.Path .. "'>返回</a>.</p>"
end




--- Deletes the specified player and redirects back to list
local function ShowDelPlayerPage(a_Request)
	-- Check the input:
	local PlayerUUID = a_Request.PostParams["PlayerUUID"]
	if (PlayerUUID == nil) then
		return HTMLError("请求错误：缺少必要参数")
	end

	-- Delete the player:
	cRankManager:RemovePlayerRank(PlayerUUID)
	UpdateIngamePlayer(PlayerUUID, "你已被 Web 管理赋予 " .. cRankManager:GetDefaultRank() .. " 权限")

	-- Redirect back to list:
	return "<p>已删除权限 <a href='/" .. a_Request.Path .. "'>返回</a>."
end





--- Shows a confirmation page for deleting the specified player
local function ShowConfirmDelPage(a_Request)
	-- Check the input:
	local PlayerUUID = a_Request.PostParams["PlayerUUID"]
	local PlayerName = a_Request.PostParams["PlayerName"]
	if ((PlayerUUID == nil) or (PlayerName == nil)) then
		return HTMLError("请求错误：缺少必要参数")
	end

	-- Show confirmation:
	return [[
		<h4>删除玩家</h4>
		<p>你确定要删除玩家 ]] .. PlayerName .. [[ 吗?<br />
		<short>UUID: ]] .. PlayerUUID .. [[</short></p>
		<p><a href='?subpage=delplayer&PlayerUUID=]] .. PlayerUUID .. [['>删除</a></p>
		<p><a href='/]] .. a_Request.Path .. [['>取消</a></p>
	]]
end





--- Returns the HTML contents of the playerrank edit page.
local function ShowEditPlayerRankPage(a_Request)
	-- Check the input:
	local PlayerUUID = a_Request.PostParams["PlayerUUID"]
	if ((PlayerUUID == nil) or (string.len(PlayerUUID) ~= 32)) then
		return HTMLError("请求错误：缺少必要参数")
	end

	-- Get player name:
	local PlayerName = cRankManager:GetPlayerName(PlayerUUID)
	local PlayerRank = cRankManager:GetPlayerRankName(PlayerUUID)

	return [[
		<h4>修改玩家权限： ]] .. PlayerName .. [[</h4>
		<form method="POST">
		<input type="hidden" name="subpage" value="editplayerproc" />
		<input type="hidden" name="PlayerUUID" value="]] .. PlayerUUID .. [[" />
		<table>
			<tr>
				<th>UUID</th>
				<td>]] .. PlayerUUID .. [[</td>
			</tr>
			<tr>
				<th>当前权限</th>
				<td>]] .. PlayerRank .. [[</td>
			</tr>
			<tr>
				<th>新的权限</th>
				<td>]] .. GetRankList(PlayerRank) .. [[</td>
			</tr>
			<tr>
				<td />
				<td><input type="submit" name="EditPlayerRank" value="修改" /></td>
			</tr>
		</table>
		</form>
	]]
end





--- Processes the edit rank page's input, change the rank and redirecting to the player rank list
local function ShowEditPlayerRankProcessPage(a_Request)
	-- Check the input:
	local PlayerUUID = a_Request.PostParams["PlayerUUID"]
	local NewRank    = a_Request.PostParams["RankName"]
	if ((PlayerUUID == nil) or (NewRank == nil) or (string.len(PlayerUUID) ~= 32) or (NewRank == "")) then
		return HTMLError("请求错误：缺少必要参数")
	end

	-- Get the player name:
	local PlayerName = cRankManager:GetPlayerName(PlayerUUID)
	if (PlayerName == "") then
		return [[
			<p>修改失败：玩家不存在！</p>
			<p><a href="/]] .. a_Request.Path .. [[">返回</a></p>
		]]
	end

	-- Edit the rank:
	cRankManager:SetPlayerRank(PlayerUUID, PlayerName, NewRank)
	UpdateIngamePlayer(PlayerUUID, "你已被 Web 管理赋予 " .. NewRank .. " 权限")
	return "<p>玩家 " .. PlayerName .. " 已被更改至 " .. NewRank .. ". <a href='/" .. a_Request.Path .. "'>返回</a>.</p>"
end





--- Processes the clear of all player ranks
local function ShowClearPlayersPage(a_Request)
	cRankManager:ClearPlayerRanks()
	LOGINFO("WebAdmin: 管理员清除了所有玩家的权限")

	-- Update ingame players:
	cRoot:Get():ForEachPlayer(
		function(a_Player)
			a_Player:LoadRank()
		end
	)

	return "<p>已清除玩家权限！ <a href='/" .. a_Request.Path .. "'>返回</a>.</p>"
end





--- Shows a confirmation page for deleting all players
local function ShowConfirmClearPage(a_Request)
	-- Show confirmation:
	return [[
		<h4>清除所有玩家权限</h4>
		<p>您确认要清空玩家权限数据库吗？</p>
		<p><a href='?subpage=clear'>确认</a></p>
		<p><a href='/]] .. a_Request.Path .. [['>取消</a></p>
	]]
end





--- Handlers for the individual subpages in this tab
-- Each item maps a subpage name to a handler function that receives a HTTPRequest object and returns the HTML to return
local g_SubpageHandlers =
{
	[""]               = ShowMainPlayersPage,
	["addplayer"]      = ShowAddPlayerPage,
	["addplayerproc"]  = ShowAddPlayerProcessPage,
	["delplayer"]      = ShowDelPlayerPage,
	["confirmdel"]     = ShowConfirmDelPage,
	["editplayer"]     = ShowEditPlayerRankPage,
	["editplayerproc"] = ShowEditPlayerRankProcessPage,
	["clear"]          = ShowClearPlayersPage,
	["confirmclear"]   = ShowConfirmClearPage,
}





--- Handles the web request coming from MCS
-- Returns the entire tab's HTML contents, based on the player's request
function HandleRequest_PlayerRanks(a_Request)
	local Subpage = (a_Request.PostParams["subpage"] or "")
	local Handler = g_SubpageHandlers[Subpage]
	if (Handler == nil) then
		return HTMLError("服务器内部错误，无法处理子页面 " .. Subpage .. ".")
	end

	local PageContent = Handler(a_Request)
	return PageContent
end
