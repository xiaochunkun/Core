function HandleRequest_ManageServer( Request )
	local Content = ""
	if (Request.PostParams["RestartServer"] ~= nil) then
		cRoot:Get():QueueExecuteConsoleCommand("restart")
	elseif (Request.PostParams["ReloadServer"] ~= nil) then
		cRoot:Get():GetPluginManager():ReloadPlugins()
	elseif (Request.PostParams["StopServer"] ~= nil) then
		cRoot:Get():QueueExecuteConsoleCommand("stop")
	elseif (Request.PostParams["WorldSaveAllChunks"] ~= nil) then
		cRoot:Get():GetWorld(Request.PostParams["WorldSaveAllChunks"]):QueueSaveAllChunks()
	end
	Content = Content .. [[
	<form method="POST">
	<table>
	<th colspan="2">服务器管理</th>
	<tr><td><input type="submit" value="重启" name="RestartServer"> 重启服务器</td></tr>
	<tr><td><input type="submit" value="重载" name="ReloadServer"> 重载服务器插件</td></tr>
	<tr><td><input type="submit" value="停止" name="StopServer"> 关闭服务器</td></tr>
	</th>
	</table>
	<br />
	<table>
	<th colspan="2">世界管理</th>
	]]
	local LoopWorlds = function( World )
		Content = Content .. [[
		<tr><td><input type="submit" value="]] .. World:GetName() .. [[" name="WorldSaveAllChunks"> 保存 ]] .. World:GetName() .. [[ 世界</td></tr>

		]]
	end
	cRoot:Get():ForEachWorld( LoopWorlds )
	Content = Content .. "</th></table>"

	return Content
end
