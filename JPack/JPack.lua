--简体中文
DEBUG=false
TYPE_BAG="容器"
TYPE_QUEST="任务"
TYPE_WEAPON="武器"
TYPE_CONSUMABLE="消耗品"
superItems={"炉石","紫色灵翼幼龙的缰绳","紫色骷髅战马","矿工锄","剥皮小刀","鱼竿","符文恒金棒","神圣蜡烛","闪光粉","传送符文","传送门符文","魔粉","轻羽毛","超级法力药水","超级治疗药水","厚灵纹绷带","饼干","魔法冰川水","清洁的德拉诺之水","魔法山泉水","魔法羊角面包","魔法肉桂面包","公正徽章","阿拉希盆地荣誉奖章","战歌峡谷荣誉奖章","风暴之眼荣誉奖章","奥特兰克山谷荣誉奖章","6级霜狼勋章","6级雷矛勋章","联盟军旗","雷矛军旗","部落军旗","霜狼军旗"}
--[[
PlayerClass 对应 物品类型列表
可用装备(布甲,皮甲,锁甲,板甲,盾牌,)
消耗物,药剂,装置,爆炸物
投射物,灵魂石,("Miscellaneous" - includes Spellstones and Firestones )
材料,商品,其他,宝石
]]--
JPack={
	asc=true,
	packing=false,
	packingBank=false,
	bankOpened=false,
	
	bagGroups={},
	packingGroupIndex=1,
	packingBags={}
}
JPack.asc=true;
--[[
function i18n()
	if locale == "zhCN" then
	--简体中文
		TYPE_BAG="容器"
		TYPE_QUEST="任务"
		TYPE_CONSUMABLE="消耗品"
		superItems={"炉石","紫色灵翼幼龙的缰绳","紫色骷髅战马","矿工锄","剥皮小刀","鱼竿","符文恒金棒","符文精金棒","神圣蜡烛","闪光粉","传送符文","传送门符文","魔粉","轻羽毛","超级法力药水","超级治疗药水","厚灵纹绷带","饼干","魔法冰川水","清洁的德拉诺之水","魔法山泉水","魔法羊角面包","魔法肉桂面包","公正徽章","阿拉希盆地荣誉奖章","战歌峡谷荣誉奖章","风暴之眼荣誉奖章","奥特兰克山谷荣誉奖章","6级霜狼勋章","6级雷矛勋章","联盟军旗","雷矛军旗","部落军旗","霜狼军旗"}
	elseif locale == "zhTW" then
	--繁体中文
		TYPE_BAG="容器"
		TYPE_QUEST="任务"
		TYPE_CONSUMABLE="消耗品"
		superItems={"炉石","矿工锄","剥皮小刀","鱼竿"}
	else
		
	end
end
]]--
local bagSize=0;
local packingBags={}

--TODO: 整理前堆叠物品（将stack > 1,名称相同的物品拿起来，放下去）
--OnUpdate   1. 堆叠中 2.整理背包分组 3移动中
--itemStackCount， GetItemInfo   stack>1 then tryZip
--GetItemCount(itemID or "itemLink", [includeBank]) 
--[[
IsEquippedItem
    IsUsableItem(item)   - Returns usable, noMana.  可使用
    IsConsumableItem(item)   -  可消耗
    IsCurrentItem(item)   - 
    IsEquippedItem(item)   -  可装备
    IsEquippableItem(itemid or "name" or itemLink)  - Returns 1 or nil. 
    IsEquippedItemType("type")   - Where "type" is any valid inventory type, item class, or item subclass.
]]--
--[[
比较用的字符串,与排序直接相关的函数
]]--

function getCompareStr(item)
	if(not item)then
		return nil
	elseif(not item.compareStr)then
		local _,_,textureType,textureIndex=string.find(item.texture,"\\.*\\([^_]+_?[^_]*_?[^_]*)_?(%d*)")
		if(not item.rarity)then item.rarity='1' end
		--去掉 ..item.type.." "..item.subType
		item.compareStr= getPerffix(item).." "..item.rarity..item.type.." "..item.subType.." "..textureType.." "
			..string.format("%2d",item.minLevel).." "..string.format("%2d",item.level).." "..(textureIndex or "00")..item.name
	end
	return item.compareStr
end

--[[
return 
超级物品 | 可使用 | 非消耗 | 装备品 
9xx -- 超级物品
81x -- 可使用非消耗品
80x -- 可使用消耗品
7xx -- 优秀装备品
6xx -- 任务物品
5xx -- 普通物品
09x -- 垃圾物品
08-- 不可用武器
07-- 不可用护甲
]]--
function getPerffix(item)
	if(item==nil)then return nil end
	for i=1,table.getn(superItems) do
		if(item.name==superItems[i])then
			return '9'..string.format("%2d",100-i)..' '
		end
	end
	if(IsEquippableItem(item.name) and item.type~=TYPE_BAG) then 
		if(item.rarity > 1 and IsUsableItem(item.name)) then
			return '7 ' 
		else
			if(item.type==TYPE_WEAPON)then
				return '08 '
			else
				return '07 '
			end
			return '0 '
		end
	elseif(item.type==TYPE_QUEST)then
		return '6 '
	elseif(item.rarity==0)then
		return '09 ' 
	elseif(item.type==TYPE_CONSUMABLE) then
		return '81'
		--[[
	elseif(IsConsumableItem(item.name))then 
		return '81 '
	elseif(IsUsableItem(item.name))then 
		return '80 '
		]]--
	end
	return '5 ';
end

--[[
bagIds = {1,3,5}
packIndex ---JPack的index
bagID --- wow 的bagId
slotId ---- wow 的slotId
]]--
function pack()
	groupBags()
	groupBank()
	JPack.packingGroupIndex=1
	JPack.packingBags=JPack.bagGroups[1]
	startPack()
end

function bagpack()
	groupBags()
	JPack.packingGroupIndex=1
	JPack.packingBags=JPack.bagGroups[1]
	startPack()
end


function bankpack()
	groupBank()
	JPack.packingGroupIndex=1
	JPack.packingBags=JPack.bagGroups[1]
	startPack()
end

--[[
将背包按类型分组
bagGroups
bankGroups
bagTypes
packingTypeIndex
packingBags
]]--
function groupBags()
	local groups={}
	groups[TYPE_BAG]={}
	groups[TYPE_BAG][1]=0
	for i=1,4 do
		local name=GetBagName(i);
		if(name)then
			local itemName, itemLink, itemRarity, itemLevel, itemMinLevel, itemType, subType, itemStackCount,
itemEquipLoc, itemTexture = GetItemInfo(name)
			if(groups[subType]==nil)then
				groups[subType]={}
			end
			local t = groups[subType]
			t[table.getn(t)+1]=i
		end
	end
	local j=1
	for k,v in pairs(groups) do
		JPack.bagGroups[j]=v
		j=j+1
	end
end

function groupBank()
	if(not JPack.bankOpened)then return end
	local groups={}
	groups[TYPE_BAG]={}
	groups[TYPE_BAG][1]=-1
	for i=5,11 do
		local name=GetBagName(i);
		if(name)then
			local itemName, itemLink, itemRarity, itemLevel, itemMinLevel, itemType, subType, itemStackCount,
itemEquipLoc, itemTexture = GetItemInfo(name)
			if(groups[subType]==nil)then
				groups[subType]={}
			end
			local t = groups[subType]
			t[table.getn(t)+1]=i
		end
	end
	local j=table.getn(JPack.bagGroups)+1
	for k,v in pairs(groups) do
		JPack.bagGroups[j]=v
		j=j+1
	end
end

function startPack()
	local items,count = getPackingItems()
	bagSize=count;
	local sorted = jsort(items)
	--debug("sorted...")
	for i=1,table.getn(sorted) do
		--debug(getCompareStr(sorted[i]))
	end
	sortTo(items,sorted)
end

function getPackingItems()
	local c=1
	local items={}
	if(JPack.asc)then
		for i=1,table.getn(JPack.packingBags) do
			local num = GetContainerNumSlots(JPack.packingBags[i]) 
			for j = 1,num do
				local link = GetContainerItemLink(JPack.packingBags[i],j) 
				if(link ~= nil)then
					items[c]={}
					items[c].name, items[c].link, items[c].rarity, 
					items[c].level, items[c].minLevel, items[c].type, items[c].subType, items[c].stackCount,
					items[c].equipLoc, items[c].texture = GetItemInfo(link) 
					--debug("items:"..c.."="..items[c].name..","..items[c].type..","..items[c].subType..","..items[c].level..","..items[c].minLevel)
				end
				c = c+1
			end
		end
	else
		for i=table.getn(JPack.packingBags),1,-1 do
			local num = GetContainerNumSlots(JPack.packingBags[i]) 
			for j = num,1,-1 do
				local link = GetContainerItemLink(JPack.packingBags[i],j) 
				if(link ~= nil)then
					items[c]={}
					items[c].name, items[c].link, items[c].rarity, 
					items[c].level, items[c].minLevel, items[c].type, items[c].subType, items[c].stackCount,
					items[c].equipLoc, items[c].texture = GetItemInfo(link) 
					--debug("items:"..c.."="..items[c].name..","..items[c].type..","..items[c].subType..","..items[c].level..","..items[c].minLevel)
				end
				c = c+1
			end
		end
	end
	return items,c-1;	
end

--[[
将 PackIndex 转换为 BagId,SlotId
]]--
function getSlotId(packIndex)
	local slot=packIndex
	--debug('get slot id');
	if(JPack.asc==true)then
		--debug('asc = true');
		for i=1,table.getn(JPack.packingBags) do
			local num=GetContainerNumSlots(JPack.packingBags[i]) 
			if(slot<=num)then
				return JPack.packingBags[i],slot
			end
			slot = slot - num;
		end
	else
		--debug('JPack.asc = false');
		for i=table.getn(JPack.packingBags),1,-1 do
			local num=GetContainerNumSlots(JPack.packingBags[i]) 
			if(slot<=num)then
				return JPack.packingBags[i],1+num-slot
			end
			slot = slot - num;
		end
	end
	return -1,-1
end

function moveTo(oldIndex,newIndex)
	PickupContainerItem(getSlotId(oldIndex));
	PickupContainerItem(getSlotId(newIndex));
end

--[[
比较两个物品
return 1 a 在前
return -1 b 在前
]]--
local function compare(a, b)
	local ret=0;
	if(a==b)then
		ret= 0
	elseif(a==nil)then
		ret= -1
	elseif(b==nil)then
		ret= 1
	elseif(a.name==b.name)then
		ret= 0
	else
		local sa = getCompareStr(a)
		local sb = getCompareStr(b)
		if(sa>sb)then
			--debug(sa.." compare to "..sb.." 1")
			ret= 1
		elseif(sa<sb) then
			--debug(sa.." compare to "..sb.." -1")
			ret= -1
		end
		--debug(sa.." compare to "..sb.." 0")
	end
	--print(JPack.asc);
	--ret=0-ret;
	--print(ret);
	return ret;
	--[[
	if(a.v>b.v)then
	    return 1
	elseif(a.v==b.v)then
	    return 0
	else
	    return -1
	end
	]]--
end

--Item[] itemsInBag = Item:new[64];

local function swap(items,i,j)
	local y=items[i];
	items[i]=items[j];
	items[j]=y;
end

local function qsort(items,from,to)

	local i,j=from,to;
	local ix=items[i];
	local x=i;
	while(i<j) do
		while(j>x) do
			if(compare(items[j], ix)==1)then
				swap(items,j,x);
				x=j;
      		else
   				j=j-1
			end
  		end
		while(i<x)do
			if(compare(items[i], ix)==-1)then
				swap(items,i,x);
				x=i;
			else
   				i=i+1
			end
  		end
 	end
	if(x-1 > from) then
		qsort(items,from,x-1)
	end
	if(x+1 < to) then
		qsort(items,x+1,to);
	end
end

function jsort(items)
	local clone = {};--Item:new[items.length];
	for i=1,bagSize do
		clone[i] = items[i];
	end
	qsort(clone,1,bagSize);
	return clone;
end

function isLocked(index)
	local texture, itemCount, locked, quality, readable = GetContainerItemInfo(getSlotId(index));
	return locked
end

--[[
获取最后一个非移动物品的索引
]]--
function GetLastItemIndex(items,key)
	local i=bagSize;
	while(i>0)do
		--if(items[i] ~= nil and not items[i].moving and items[i].name == key)then
		if(items[i] ~= nil and not isLocked(i) and items[i].name == key)then
			return i;
		end
		i= i-1
	end
	return -1;
end

local current,to;
--[[
移动一次
]]--
function moveOnce()
	local continue=false;
	local i=1;
	while(to[i] ~=nil)do
		--debug("to"..i.."="..to[i].name)
		--if(current[i] == nil or (to[i].name ~= current[i].name and not current[i].moving))then
		if(current[i] == nil or to[i].name ~= current[i].name)then
			continue = true
			if(not isLocked(i))then
				local slot =GetLastItemIndex(current, to[i].name);
				if(slot ~= -1)then
					--debug("move "..to[i].name.." from "..slot .." to "..i);
					moveTo(slot,i) -- 移动物品
					local x=current[slot];
					current[slot]=current[i];
					current[i]=x;
				end
			end
		end
		i=i+1
	end
	return continue;
end

JPackFrame=CreateFrame("Frame",nil,UIParent)

local moving=false;
function sortTo(_current, _to)
	current=_current
	to=_to
	--JPack:RegisterEvent("ITEM_LOCK_CHANGED")
	JPack.packing=true;
end
PackOnBagOpen=true
function JPackFrame:OnEvent()
	--debug(event)
	if(event=="PLAYER_ENTERING_WORLD")then
		self:Init();
	elseif(event=="BAG_OPEN")then
		if(PackOnBagOpen)then
			pack()
		end
	elseif(event=="BANKFRAME_OPENED")then
		JPack.bankOpened=true
		--debug("bank opened")
	elseif(event=="BANKFRAME_CLOSED")then
		JPack.bankOpened=false
		--debug("bank closed")
	end
end

function JPackFrame:OnUpdate()
	if(JPack.packing)then
		local oncePacking=moveOnce()
		if(not oncePacking)then
			JPack.packingGroupIndex=JPack.packingGroupIndex + 1
			--debug("index"..JPack.packingGroupIndex)
			JPack.packingBags=JPack.bagGroups[JPack.packingGroupIndex]
			--debug("JPack.bagGroups . size = "..table.getn(JPack.bagGroups))
			for i=1,table.getn(JPack.bagGroups) do
				for j=1,table.getn(JPack.bagGroups[i]) do
					--debug("i"..i.."j"..j..":"..JPack.bagGroups[i][j])
				end
			end
			if(JPack.packingBags==nil)then
				JPack.packing=false
				JPack.bagGroups={}
				print('背包整理完毕！')
				print('聊天栏输入/bgn bank 察看离线银行')
				print('请访问:http://wowshell.ys168.com 查看最新版本')
			else
				--debug("Packing "..JPack.packingGroupIndex)
				startPack()
			end
		end
	end
end

JPackFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
JPackFrame:RegisterEvent("PLAYER_LOGIN")
JPackFrame:RegisterEvent("UPDATE_FACTION")

JPackFrame:SetScript("OnEvent",JPackFrame.OnEvent);
JPackFrame:SetScript("OnUpdate",JPackFrame.OnUpdate);
function JPackFrame:Init()
	JPackFrame:RegisterEvent("BAG_OPEN")
	JPackFrame:RegisterEvent("BANKFRAME_OPENED")
	JPackFrame:RegisterEvent("BANKFRAME_CLOSED")	
	SlashCmdList["JPACK"] = JPackFrame_Slash
	SLASH_JPACK1 = "/jpack"
	SLASH_JPACK2 = "/jp"
end

function JPackFrame_Slash(msg)
	local a,b,c=strfind(msg, "(%S+)");
	if(a~=nil)then
		debug('a='..a..' b='..b..' c='..c);
	end
	if(c=="asc")then
		JPack.asc=true
	elseif(c=="desc")then
		JPack.asc=false
	elseif(c=="debug")then
		DEBUG=true
		return;
	elseif(c=="nodebug")then
		DEBUG=false
		return;
	end
	pack();
end
