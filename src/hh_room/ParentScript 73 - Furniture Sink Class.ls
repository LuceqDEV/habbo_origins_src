property pDoorTimer, pTokenList

on prepare me
  pTokenList = value(getVariable("obj_" & me.pClass))
  if not listp(pTokenList) then
    pTokenList = [18]
  end if
  return 1
end

on updateStuffdata me, tValue
  if (tValue = "TRUE") or (tValue = "1") then
    pDoorTimer = 80
  else
    pDoorTimer = 0
  end if
end

on select me
  tUserObj = getThread(#room).getComponent().getOwnUser()
  if tUserObj = 0 then
    return 1
  end if
  case me.pDirection[1] of
    4:
      if (me.pLocX = tUserObj.pLocX) and ((me.pLocY - tUserObj.pLocY) = -1) then
        if the doubleClick then
          me.giveDrink()
        end if
      else
        getThread(#room).getComponent().getRoomConnection().send("MOVE", [#short: me.pLocX, #short: me.pLocY + 1])
      end if
    0:
      if (me.pLocX = tUserObj.pLocX) and ((me.pLocY - tUserObj.pLocY) = 1) then
        if the doubleClick then
          me.giveDrink()
        end if
      else
        getThread(#room).getComponent().getRoomConnection().send("MOVE", [#short: me.locX, #short: me.pLocY - 1])
      end if
    2:
      if (me.pLocY = tUserObj.pLocY) and ((me.pLocX - tUserObj.pLocX) = -1) then
        if the doubleClick then
          me.giveDrink()
        end if
      else
        getThread(#room).getComponent().getRoomConnection().send("MOVE", [#short: me.pLocX + 1, #short: me.pLocY])
      end if
    6:
      if (me.pLocY = tUserObj.pLocY) and ((me.pLocX - tUserObj.pLocX) = 1) then
        if the doubleClick then
          me.giveDrink()
        end if
      else
        getThread(#room).getComponent().getRoomConnection().send("MOVE", [#short: me.pLocX - 1, #short: me.pLocY])
      end if
  end case
  return 1
end

on giveDrink me
  tConnection = getThread(#room).getComponent().getRoomConnection()
  if tConnection = 0 then
    return 0
  end if
  getThread(#room).getComponent().getRoomConnection().send("SETSTUFFDATA", [#string: string(me.getID()), #string: "TRUE"])
  tConnection.send("LOOKTO", me.pLocX && me.pLocY)
  tConnection.send("CARRYDRINK", [#string: string(me.getDrinkname())])
end

on getDrinkname me
  return pTokenList[random(pTokenList.count)]
end

on update me
  if pDoorTimer <> 0 then
    if me.pSprList.count < 2 then
      return 
    end if
    tName = me.pSprList[2].member.name
    tName = tName.char[1..length(tName) - 1] & 1
    tmember = member(abs(getmemnum(tName)))
    pDoorTimer = pDoorTimer - 1
    if pDoorTimer = 0 then
      tName = tName.char[1..length(tName) - 1] & 0
      tmember = member(getmemnum(tName))
    end if
    me.pSprList[2].castNum = tmember.number
    me.pSprList[2].width = tmember.width
    me.pSprList[2].height = tmember.height
  end if
end
