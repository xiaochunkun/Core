
-- web_ranks.lua

-- Implements the Ranks tab in the webadmin





--- Maximum number of groups displayed within a rank's row.
-- If there are more groups than this, a triple-dot is displayed at the end of the list
local MAX_GROUPS = 10

local ins = table.insert
local con = table.concat





--- Translates MC color code to HTML-related properties of each code
local g_ColorCodeDef =
{
	["0"] = { FgColor = "#fff", BgColor = "#000", Name = "Black" },
	["1"] = { FgColor = "#fff", BgColor = "#00a", Name = "Dark blue" },
	["2"] = { FgColor = "#fff", BgColor = "#0a0", Name = "Dark green" },
	["3"] = { FgColor = "#fff", BgColor = "#0aa", Name = "Dark aqua" },
	["4"] = { FgColor = "#fff", BgColor = "#a00", Name = "Dark red" },
	["5"] = { FgColor = "#fff", BgColor = "#a0a", Name = "Dark purple" },
	["6"] = { FgColor = "#000", BgColor = "#fa0", Name = "Gold" },
	["7"] = { FgColor = "#000", BgColor = "#aaa", Name = "Gray" },
	["8"] = { FgColor = "#fff", BgColor = "#fff", Name = "Dark gray" },
	["9"] = { FgColor = "#fff", BgColor = "#55f", Name = "Blue" },
	["a"] = { FgColor = "#000", BgColor = "#5f5", Name = "Green" },
	["b"] = { FgColor = "#000", BgColor = "#5ff", Name = "Aqua" },
	["c"] = { FgColor = "#000", BgColor = "#f55", Name = "Red" },
	["d"] = { FgColor = "#000", BgColor = "#f5f", Name = "Light purple" },
	["e"] = { FgColor = "#000", BgColor = "#ff5", Name = "Yellow" },
	["f"] = { FgColor = "#000", BgColor = "#fff", Name = "White" },

	[""] = { SpecialHTML = "<i>(None)</i>" }
}





--- Returns the HTML code that visualises the given color code:
--   - sets the font color and background
--   - writes out the color name
local function ColorCodeToHTML(a_ColorCode)
	local ColorCodeDef = g_ColorCodeDef[a_ColorCode]

	-- Check if the color code is valid:
	if (ColorCodeDef == nil) then
		return "<b><i>未知颜色代码</i></b>"
	end

	-- If the code has special HTML, use that instead:
	if (ColorCodeDef.SpecialHTML ~= nil) then
		return ColorCodeDef.SpecialHTML
	end

	-- Compose the default color:
	local Code = {"<span style='color: "}
	ins(Code, ColorCodeDef.FgColor)
	ins(Code, "; background-color: ")
	ins(Code, ColorCodeDef.BgColor)
	ins(Code, "; padding: 3px'/>")
	ins(Code, ColorCodeDef.Name)
	ins(Code, "</span>")

	-- Concat the result together:
	return con(Code)
end





--- Returns the HTML contents of the group list combobox
local function GetGroupList(a_SelectedGroup)
	local GroupList = {}
	ins(GroupList, "<select name='NewGroupName'>")

	local AllGroups = cRankManager:GetAllGroups()
	table.sort(AllGroups)

	for _, group in ipairs(AllGroups) do
		local HTMLGroupName = cWebAdmin:GetHTMLEscapedString(group)
		ins(GroupList, "<option value='")
		ins(GroupList, HTMLGroupName)
		if (HTMLGroupName == a_SelectedGroup) then
			ins(GroupList, "' selected>")
		else
			ins(GroupList, "'>")
		end
		ins(GroupList, HTMLGroupName)
		ins(GroupList, "</option>")
	end
	ins(GroupList, "</select>")

	return con(GroupList)
end





-- Returns the HTML contents of the rank list
local function GetRankList(a_SelectedRank)
	local RankList = {}
	ins(RankList, "<select name='NewGroupName'>")

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





--- Returns the HTML contents of a single row in the Ranks table
local function GetRankRow(a_RankName)
	-- First row: rank name:
	local Row = {"<tr><td>"}
	ins(Row, cWebAdmin:GetHTMLEscapedString(a_RankName))
	ins(Row, "</td><td>")

	-- List all groups in the rank:
	local Groups = cRankManager:GetRankGroups(a_RankName)
	table.sort(Groups)
	local NumGroups = #Groups
	if (NumGroups <= MAX_GROUPS) then
		ins(Row, con(Groups, "<br/>"))
	else
		-- There are more than MAX_GROUPS groups, display a triple-dot at the end of the list:
		ins(Row, con(Groups, "<br/>", 1, MAX_GROUPS))
		ins(Row, "<br/>...")
	end
	ins(Row, "</td><td>")

	-- Display the visuals:
	local MsgPrefix, MsgSuffix, MsgNameColorCode = cRankManager:GetRankVisuals(a_RankName)
	ins(Row, "消息前缀: ")
	ins(Row, MsgPrefix)
	ins(Row, "<br/>消息后缀: ")
	ins(Row, MsgSuffix)
	ins(Row, "<br/>名称颜色: ")
	ins(Row, ColorCodeToHTML(MsgNameColorCode))

	-- Display actions for this rank:
	ins(Row, "</td><td><form>")
	ins(Row, GetFormButton("editgroups", "编辑权限组", {RankName = a_RankName}))
	ins(Row, "</form><form>")
	ins(Row, GetFormButton("editvisuals", "编辑视觉效果", {RankName = a_RankName}))
	ins(Row, "</form><form>")
	ins(Row, GetFormButton("confirmdel", "删除阶级", {RankName = a_RankName}))

	-- Terminate the row and return the entire concatenated string:
	ins(Row, "</form></td></tr>")
	return con(Row)
end





--- Returns the HTML contents of the main Ranks page
local function ShowMainRanksPage(a_Request)
	-- Accumulator for the page data
	local Page = {}

	-- Add the rank control header:
	ins(Page, "<p><a href='?subpage=addrank'>添加新阶级</a></p>")

	-- Add a table describing each rank:
	ins(Page, "<table><tr><th>阶级</th><th>权限组</th><th>视觉效果</th><th>操作</th></tr>\n")
	local AllRanks = cRankManager:GetAllRanks()
	table.sort(AllRanks)
	for _, rank in ipairs(AllRanks) do
		ins(Page, GetRankRow(rank))
	end
	ins(Page, "</table>")

	-- Display default rank:
	--ins(Page, "<table><tr><th>Default rank</th><td>")
	--ins(Page, GetRankList(cRankManager:GetDefaultRank()))
	--ins(Page, "</td><td><input type='submit' name='EditDefaultRank' value='Edit' /></td></tr></table>")
	ins(Page, "<form method='POST'><b>默认阶级:</b> ")
	ins(Page, GetRankList(cRankManager:GetDefaultRank()))
	ins(Page, "<input type='submit' name='EditDefaultRank' value='设置' />")
	ins(Page, "<input type='hidden' name='subpage' value='editdefaultrank' /></form>")

	-- Return the entire concatenated string:
	return con(Page)
end





--- Processes the AddGroup page, adding a new group to the specified rank and redirecting back to rank's group list
local function ShowAddGroupPage(a_Request)
	-- Check params:
	local RankName = a_Request.PostParams["RankName"]
	local NewGroupName = a_Request.PostParams["NewGroupName"]
	if ((RankName == nil) or (NewGroupName == nil)) then
		return HTMLError("请求出错")
	end

	-- Add the group:
	cRankManager:AddGroupToRank(NewGroupName, RankName)

	-- Redirect the player:
	return
		"<p>已添加权限组 <a href='/" ..
		a_Request.Path ..
		"?subpage=editgroups&RankName=" ..
		cUrlParser:UrlEncode(RankName) ..
		"'>返回</a>"
end





--- Processes the RemoveGroup page, removing a group from the specified rank and redirecting back to rank's group list
local function ShowRemoveGroupPage(a_Request)
	-- Check params:
	local RankName = a_Request.PostParams["RankName"]
	local GroupName = a_Request.PostParams["GroupName"]
	if ((RankName == nil) or (GroupName == nil)) then
		return HTMLError("请求出错")
	end

	-- Remove the group:
	cRankManager:RemoveGroupFromRank(GroupName, RankName)

	-- Redirect the user:
	return
		"<p>已删除权限组 <a href='/" ..
		a_Request.Path ..
		"?subpage=editgroups&RankName=" ..
		cUrlParser:UrlEncode(RankName) ..
		"'>返回</a>."
end





--- Handles the AddRank subpage.
-- Displays the HTML form for adding a new rank, processes the input
local function ShowAddRankPage(a_Request)
	-- Display the "Add rank" webpage:
	-- TODO: Improve the color code input
	return [[
		<form method='POST'>
		<input type='hidden' name='subpage' value='addrankproc'/>
		<table>
			<tr>
				<th>阶级名称:</th>
				<td><input type="text" name="RankName"/></td>
			</tr><tr>
				<th>消息前缀:</th>
				<td><input type="text" name="MsgPrefix"/></td>
			</tr><tr>
				<th>消息后缀:</th>
				<td><input type="text" name="MsgSuffix"/></td>
			</tr><tr>
				<th>名称颜色:</th>
				<td><input type="text" name="MsgNameColorCode"/></td>
			</tr><tr>
				<td/>
				<td><input type="submit" name="AddRank" value="添加"/></td>
			</tr>
		</table></form>
	]]
end





--- Processes the AddRank page's input, creating a new rank and redirecting to the rank list
local function ShowAddRankProcessPage(a_Request)
	-- Check the received values:
	local RankName         = a_Request.PostParams["RankName"]
	local MsgPrefix        = a_Request.PostParams["MsgPrefix"]
	local MsgSuffix        = a_Request.PostParams["MsgSuffix"]
	local MsgNameColorCode = a_Request.PostParams["MsgNameColorCode"]
	if ((RankName == nil) or (MsgPrefix == nil) or (MsgSuffix == nil) or (MsgNameColorCode == nil)) then
		return HTMLError("请求出错")
	end

	-- Add the new rank:
	cRankManager:AddRank(RankName, MsgPrefix, MsgSuffix, MsgNameColorCode)
	return "<p>已创建阶级 <a href='/" .. a_Request.Path .. "'>返回</a></p>"
end





--- Shows a confirmation page for deleting the specified rank
local function ShowConfirmDelPage(a_Request)
	-- Check the input:
	local RankName = a_Request.PostParams["RankName"]
	if (RankName == nil) then
		return HTMLError("Bad request")
	end

	-- Show confirmation:
	return [[
		<h4>删除阶级</h4>
		<p>您确认要删除阶级 ]] .. RankName .. [[ 吗?</p>
		<p><a href='?subpage=del&RankName=]] .. RankName .. [['>删除</a></p>
		<p><a href='/]] .. a_Request.Path .. [['>取消</a></p>
	]]
end





--- Deletes the specified rank and redirects back to list
local function ShowDelPage(a_Request)
	-- Check the input:
	local RankName = a_Request.PostParams["RankName"]
	if (RankName == nil) then
		return HTMLError("请求出错")
	end

	-- Delete the rank:
	cRankManager:RemoveRank(RankName)

	-- Redirect back to list:
	return "<p>阶级已删除 <a href='/" .. a_Request.Path .. "'>返回</a>"
end






--- Changes the default rank and redirects back to the list
local function ShowEditDefaultRankPage(a_Request)
	-- Check the input:
	local RankName = a_Request.PostParams["NewGroupName"]
	if ((RankName == nil) or (RankName == "")) then
		return HTMLError("请求出错")
	end

	-- Change the default rank:
	if (cRankManager:SetDefaultRank(RankName)) then
		return "<p>已将默认阶级更改为 " .. RankName .. "! <a href='/" .. a_Request.Path .. "'>返回</a></p>"
	else
		return "<p>操作失败! <a href='/" .. a_Request.Path .. "'>返回</a></p>"
	end
end





--- Displays a page with all the groups, lets user add and remove groups to a rank
local function ShowEditGroupsPage(a_Request)
	-- Check the input:
	local RankName = a_Request.PostParams["RankName"]
	if (RankName == nil) then
		return HTMLError("请求出错")
	end

	-- Add header:
	local Page = {[[
		<p><a href='/]] .. a_Request.Path .. [['/>返回</a></p>
		<h4>添加权限组</h4>
		<form method='POST'>
		<input type='hidden' name='subpage' value='addgroup'/>
		<table>
			<tr>
				<th>权限组:</th>
				<td>]] .. GetGroupList("") .. [[</td>
			</tr>
			<tr>
				<td/>
				<td><input type='submit' value='添加'/></td>
			</tr>
		</table>
		<input type='hidden' name='RankName' value=']]
	}
	ins(Page, cWebAdmin:GetHTMLEscapedString(RankName))
	ins(Page, "'/></form>")

	-- List all the groups in the rank:
	local Groups = cRankManager:GetRankGroups(RankName)
	table.sort(Groups)
	ins(Page, "<h4>阶级 ")
	ins(Page, cWebAdmin:GetHTMLEscapedString(RankName))
	ins(Page, " 的权限组</h4>")
	ins(Page, "<table><tr><th>权限组</th><th>操作</th></tr>")
	for _, Group in ipairs(Groups) do
		ins(Page, "<tr><td>")
		ins(Page, Group)
		ins(Page, "</td><td><form method='POST'><input type='hidden' name='RankName' value='")
		ins(Page, RankName)
		ins(Page, "'/><input type='hidden' name='GroupName' value='")
		ins(Page, Group)
		ins(Page, "'/><input type='submit' value='删除'/>")
		ins(Page, "<input type='hidden' name='subpage' value='removegroup'/></form></td></tr>")
	end
	ins(Page, "</table>")

	return con(Page)
end





--- Displays a page with the rank's visuals, lets user edit them
local function ShowEditVisualsPage(a_Request)
	-- Check params:
	local RankName = a_Request.PostParams["RankName"]
	if (RankName == nil) then
		return HTMLError("请求出错")
	end

	-- Get the current visuals to fill in:
	local MsgPrefix, MsgSuffix, MsgNameColorCode = cRankManager:GetRankVisuals(RankName)
	if (MsgPrefix == nil) then
		return HTMLError("操作失败：阶级不存在")
	end

	-- Insert the form for changing the values:
	local Page = {"<h4>编辑视觉效果 - "}
	ins(Page, cWebAdmin:GetHTMLEscapedString(RankName))
	ins(Page, "</h4><form method='POST'><table><tr><th>消息前缀:</th><td><input type='text' name='MsgPrefix' value='")
	ins(Page, cWebAdmin:GetHTMLEscapedString(MsgPrefix))
	ins(Page, "'/></td></tr><tr><th>消息后缀:</th><td><input type='text' name='MsgSuffix' value='")
	ins(Page, cWebAdmin:GetHTMLEscapedString(MsgSuffix))
	ins(Page, "'/></td></tr><tr><th>名称颜色:</th><td><input type='text' name='MsgNameColorCode' value='")
	ins(Page, cWebAdmin:GetHTMLEscapedString(MsgNameColorCode))
	ins(Page, "'/></td></tr><tr><th/><td>")
	ins(Page, GetFormButton("savevisuals", "保存", {RankName = RankName}))
	ins(Page, "</td></tr></table></form>")

	return con(Page)
end





--- Saves the rank visuals, posted by ShowEditVisualsPage
local function ShowSaveVisualsPage(a_Request)
	-- Check params:
	local RankName         = a_Request.PostParams["RankName"]
	local MsgPrefix        = a_Request.PostParams["MsgPrefix"]
	local MsgSuffix        = a_Request.PostParams["MsgSuffix"]
	local MsgNameColorCode = a_Request.PostParams["MsgNameColorCode"]
	if ((RankName == nil) or (MsgPrefix == nil) or (MsgSuffix == nil) or (MsgNameColorCode == nil)) then
		return HTMLError("请求出错")
	end

	if (not g_ColorCodeDef[MsgNameColorCode]) then
		return HTMLError("无效的颜色代码")
	end
	-- Save the visuals:
	cRankManager:SetRankVisuals(RankName, MsgPrefix, MsgSuffix, MsgNameColorCode)

	return "<p>视觉效果已保存 <a href='/" .. a_Request.Path .. "'>返回</a>"
end





--- Handlers for the individual subpages in this tab
-- Each item maps a subpage name to a handler function that receives a HTTPRequest object and returns the HTML to return
local g_SubpageHandlers =
{
	[""]                = ShowMainRanksPage,
	["addgroup"]        = ShowAddGroupPage,
	["addrank"]         = ShowAddRankPage,
	["addrankproc"]     = ShowAddRankProcessPage,
	["confirmdel"]      = ShowConfirmDelPage,
	["del"]             = ShowDelPage,
	["editdefaultrank"] = ShowEditDefaultRankPage,
	["editgroups"]      = ShowEditGroupsPage,
	["editvisuals"]     = ShowEditVisualsPage,
	["removegroup"]     = ShowRemoveGroupPage,
	["savevisuals"]     = ShowSaveVisualsPage,
}





--- Handles the web request coming from MCS
-- Returns the entire tab's HTML contents, based on the player's request
function HandleRequest_Ranks(a_Request)
	local Subpage = (a_Request.PostParams["subpage"] or "")
	local Handler = g_SubpageHandlers[Subpage]
	if (Handler == nil) then
		return HTMLError("服务器内部错误，无法处理子页面 " .. Subpage .. ".")
	end

	local PageContent = Handler(a_Request)

	--[[
	-- DEBUG: Save content to a file for debugging purposes:
	local f = io.open("ranks.html", "wb")
	if (f ~= nil) then
		f:write(PageContent)
		f:close()
	end
	--]]

	return PageContent
end
