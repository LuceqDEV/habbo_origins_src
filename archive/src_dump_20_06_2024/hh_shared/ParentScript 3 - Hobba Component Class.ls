property pCryDataBase

on construct me
  pCryDataBase = [:]
  registerMessage(#sendCallForHelp, me.getID(), #send_cryForHelp)
  registerMessage(#sendCallForHelpWithReporting, me.getID(), #handleCryForHelpWithReporting)
  return 1
end

on deconstruct me
  pCryDataBase = [:]
  unregisterMessage(#sendCallForHelp, me.getID())
  unregisterMessage(#sendCallForHelpWithReporting, me.getID())
  return 1
end

on receive_cryforhelp me, tMsg
  pCryDataBase[tMsg[#cry_id]] = tMsg
  me.getInterface().ShowAlert()
  me.getInterface().updateCryWnd()
  return 1
end

on receive_pickedCry me, tMsg
  if voidp(pCryDataBase[tMsg[#cry_id]]) then
    return 0
  end if
  pCryDataBase[tMsg[#cry_id]].picker = tMsg[#picker]
  me.getInterface().updateCryWnd()
  return 1
end

on deleteCry me, tid
  pCryDataBase.deleteProp(tid)
  me.getInterface().updateCryWnd()
  return 1
end

on send_changeCfhType me, tCryID, tCategoryNum
  if not connectionExists(getVariable("connection.info.id")) then
    return 0
  end if
  if tCategoryNum = 2 then
    tNewCategory = 1
    executeMessage(#alert, [#msg: "hobba_sent_to_helpers"])
  else
    if tCategoryNum = 1 then
      tNewCategory = 2
      executeMessage(#alert, [#msg: "hobba_sent_to_moderators"])
    else
      return error(me, "Original category number illegal:" && tCategoryNum, #send_changeCfhType)
    end if
  end if
  getConnection(getVariable("connection.info.id")).send("CHANGECALLCATEGORY", [#string: tCryID, #integer: tNewCategory])
  return 1
end

on send_cryPick me, tCryID, tGoHelp
  if not connectionExists(getVariable("connection.info.id")) then
    return 0
  end if
  getConnection(getVariable("connection.info.id")).send("PICK_CRYFORHELP", [#string: tCryID])
  if tGoHelp then
    tdata = pCryDataBase[tCryID].duplicate()
    if voidp(tdata) then
      return 0
    end if
    tOk = 1
    tOk = (tdata[#picker].ilk = #string) and tOk
    tOk = (tdata[#url_id].ilk = #string) and tOk
    tOk = (tdata[#roomname].ilk = #string) and tOk
    tOk = (tdata[#cry_id].ilk = #string) and tOk
    tOk = (tdata[#type].ilk = #symbol) and tOk
    tOk = (tdata[#msg].ilk = #string) and tOk
    if not tOk then
      return error(me, "Invalid or missing data in saved help cry!", #send_cryPick)
    end if
    if tdata[#type] = #private then
      tdata[#casts] = getVariableValue("room.cast.private")
    else
      if ilk(tdata[#casts]) = #string then
        tCasts = tdata[#casts]
        tdata[#casts] = []
        tDelim = the itemDelimiter
        the itemDelimiter = ","
        repeat with c = 1 to tCasts.item.count
          tdata[#casts].add(tCasts.item[c])
        end repeat
        the itemDelimiter = tDelim
      end if
    end if
    tdata[#id] = tdata[#room_id]
    executeMessage(#pickAndGoCFH, tdata[#sender])
    executeMessage(#executeRoomEntry, tdata[#id], tdata)
  end if
  return 1
end

on handleCryForHelpWithReporting me, callDetails
  tCount = 0
  tSendList = [#integer: callDetails.topicId, #integer: integer(callDetails.reportedRoomId), #string: callDetails.reportedUser, #string: callDetails.reportText, #integer: 0]
  repeat with i = 1 to count(callDetails.selectedChat)
    tSendList.addProp(#string, callDetails.selectedChat[1])
    callDetails.selectedChat.deleteAt(1)
    tCount = tCount + 1
  end repeat
  tSendList[5] = tCount
  getConnection(getVariable("connection.info.id")).send("CREATECALLWITHREPORTING", tSendList)
end

on send_cryForHelp me, tMsg, ttype
  tMsg = replaceChars(tMsg, "/", SPACE)
  tMsg = replaceChunks(tMsg, RETURN, "<br>")
  tMsg = convertSpecialChars(tMsg, 1)
  if ttype = #habbo_helpers then
    tSendType = 2
  else
    if ttype = #emergency then
      tSendType = 1
    else
      return error(me, "Illegal type for CFH!", #send_cryForHelp)
    end if
  end if
  tPropList = [#string: tMsg, #integer: tSendType]
  if connectionExists(getVariable("connection.room.id")) then
    return getConnection(getVariable("connection.room.id")).send("CRYFORHELP", tPropList)
  else
    return error(me, "Failed to access room connection!", #send_cryForHelp)
  end if
end

on send_CfhReply me, tCryID, tMsg
  if not connectionExists(getVariable("connection.info.id")) then
    return 0
  end if
  tCharsCounted = 0
  repeat with i = 1 to tMsg.char.count
    tCharsCounted = tCharsCounted + 1
    if (tCharsCounted > 45) and (tMsg.char[i] = SPACE) then
      put "<br>" into tMsg.char[i]
      tCharsCounted = 0
    end if
  end repeat
  tMsg = replaceChunks(tMsg, RETURN, "<br>")
  tMsg = convertSpecialChars(tMsg, 1)
  getConnection(getVariable("connection.info.id")).send("MESSAGETOCALLER", [#string: tCryID, #string: tMsg])
  return 1
end

on getCryDataBase me
  return pCryDataBase
end

on clearCryDataBase me
  pCryDataBase = [:]
  return 1
end
