on construct me
  return me.regMsgList(1)
end

on deconstruct me
  return me.regMsgList(0)
end

on handleDisconnect me, tMsg
  error(me, "Connection was disconnected:" && tMsg.connection.getID(), #handleMsg)
  return me.getInterface().showDisconnect()
end

on handleHello me, tMsg
  error(me, "Received Hello, sending GENERATEKEY", #handleMsg)
  return tMsg.connection.send("GENERATEKEY")
end

on handleSessionParameters me, tMsg
  error(me, "Received SessionParameters total Pairs", #handleMsg)
  tPairsCount = tMsg.connection.GetIntFrom()
  if integerp(tPairsCount) then
    if tPairsCount > 0 then
      repeat with i = 1 to tPairsCount
        tid = tMsg.connection.GetIntFrom()
        tSession = getObject(#session)
        case tid of
          0:
            tValue = tMsg.connection.GetIntFrom()
            tSession.set("conf_coppa", tValue > 0)
            tSession.set("conf_strong_coppa_required", tValue > 1)
          1:
            tValue = tMsg.connection.GetIntFrom()
            tSession.set("conf_voucher", tValue > 0)
          2:
            tValue = tMsg.connection.GetIntFrom()
            tSession.set("conf_parent_email_request", tValue > 0)
          3:
            tValue = tMsg.connection.GetIntFrom()
            tSession.set("conf_parent_email_request_reregistration", tValue > 0)
          4:
            tValue = tMsg.connection.GetIntFrom()
            tSession.set("conf_allow_direct_mail", tValue > 0)
          5:
            tValue = tMsg.connection.GetStrFrom()
            if not objectExists(#dateFormatter) then
              createObject(#dateFormatter, ["Date Class"])
            end if
            tDateForm = getObject(#dateFormatter)
            if not (tDateForm = 0) then
              tDateForm.define(tValue)
            end if
        end case
      end repeat
    end if
  end if
  return me.sendLogin(tMsg.connection)
end

on handleSecretKey me, tMsg
  error(me, "Received SecretKey", #handleMsg)
  tKey = secretDecode(tMsg.content)
  tMsg.connection.setDecoder(createObject(#temp, getClassVariable("connection.decoder.class")))
  tMsg.connection.getDecoder().setKey(tKey)
  tMsg.connection.setEncryption(1)
  tClientURL = getMoviePath() & "habbo.dcr"
  tExtVarsURL = getExtVarPath()
  tHost = tMsg.connection.getProperty(#host)
  if tHost contains deobfuscate("��KfGNuSE��@kLK��KiOIgCW{\S") then
    tClientURL = EMPTY
  end if
  if tHost contains deobfuscate("8<��;������") then
    tClientURL = EMPTY
  end if
  if not (the runMode contains "Plugin") then
    tClientURL = EMPTY
    tExtVarsURL = EMPTY
  end if
  error(me, "Sending VERSIONCHECK", #handleMsg)
  tMsg.connection.send("VERSIONCHECK", [#integer: getIntVariable("client.version.id"), #string: tClientURL, #string: tExtVarsURL])
  tMsg.connection.send("UNIQUEID", [#string: getMachineID()])
  tMsg.connection.send("GET_SESSION_PARAMETERS")
  return 1
end

on sendLogin me, tConnection
  if objectExists("nav_problem_obj") then
    removeObject("nav_problem_obj")
  end if
  if me.getComponent().isOkToLogin() then
    tUserName = getObject(#session).get(#userName)
    tPassword = getObject(#session).get(#password)
    tOneTimePassword = getObject(#session).get(#totp)
    if not stringp(tUserName) or not stringp(tPassword) then
      return removeConnection(tConnection.getID())
    end if
    if (tUserName = EMPTY) or (tPassword = EMPTY) then
      return removeConnection(tConnection.getID())
    end if
    return tConnection.send("TRY_LOGIN", [#string: tUserName, #string: tPassword, #string: tOneTimePassword])
  end if
  return 1
end

on handlePing me, tMsg
  tMsg.connection.send("PONG")
end

on handleRegistrationOK me, tMsg
  tEmailAddress = getObject(#session).get(#email)
  tPassword = getObject(#session).get(#password)
  tTotpCode = tMsg.connection.GetStrFrom()
  if not stringp(tEmailAddress) or not stringp(tPassword) then
    return removeConnection(tMsg.connection.getID())
  end if
  if (tEmailAddress = EMPTY) or (tPassword = EMPTY) then
    return removeConnection(tMsg.connection.getID())
  end if
  return tMsg.connection.send("TRY_LOGIN", [#string: tEmailAddress, #string: tPassword, #string: tTotpCode])
end

on handleOneTimePassword me, tMsg
  return me.getInterface().showOneTimePassword()
end

on handleLoginOK me, tMsg
  tMsg.connection.send("GET_INFO")
  tMsg.connection.send("GET_CREDITS")
  tMsg.connection.send("GETAVAILABLEBADGES")
  tMsg.connection.send("GET_CFH_CATEGORIES")
  if objectExists(#session) then
    getObject(#session).set("userLoggedIn", 1)
    getObject(#session).set("reportable_users", [])
  end if
  if not objectExists("loggertool") then
    if memberExists("Debug System Class") then
      createObject("loggertool", "Debug System Class")
      if getIntVariable("client.debug.window", 0) = 3 then
        getObject("loggertool").initDebug()
      else
        getObject("loggertool").tryAutoStart()
      end if
    end if
  end if
end

on handleUserObj me, tMsg
  tuser = [:]
  tDelim = the itemDelimiter
  the itemDelimiter = "="
  repeat with i = 1 to tMsg.content.line.count
    tLine = tMsg.content.line[i]
    tuser[tLine.item[1]] = tLine.item[2..tLine.item.count]
  end repeat
  if not voidp(tuser["sex"]) then
    if (tuser["sex"] contains "F") or (tuser["sex"] contains "f") then
      tuser["sex"] = "F"
    else
      tuser["sex"] = "M"
    end if
  end if
  if objectExists("Figure_System") then
    tuser["figure"] = getObject("Figure_System").parseFigure(tuser["figure"], tuser["sex"], "user", "USEROBJECT")
  end if
  the itemDelimiter = tDelim
  tSession = getObject(#session)
  repeat with i = 1 to tuser.count
    tSession.set("user_" & tuser.getPropAt(i), tuser[i])
  end repeat
  tSession.set(#userName, tSession.get("user_name"))
  tSession.set("user_password", tSession.get(#password))
  executeMessage(#updateFigureData)
  if getObject(#session).exists("user_logged") then
    return 
  else
    getObject(#session).set("user_logged", 1)
  end if
  if getIntVariable("quickLogin", 0) and (the runMode contains "Author") then
    setPref(getVariable("fuse.project.id", "fusepref"), string([getObject(#session).get(#userName), getObject(#session).get(#password)]))
    me.getInterface().hideLogin()
  else
    me.getInterface().showUserFound()
  end if
  executeMessage(#userlogin, "userLogin")
end

on handleUserBanned me, tMsg
  tBanMsg = getText("Alert_YouAreBanned") & RETURN & tMsg.content
  executeMessage(#openGeneralDialog, #ban, [#id: "BannWarning", #title: "Alert_YouAreBanned_T", #msg: tBanMsg, #modal: 1])
  removeConnection(tMsg.connection.getID())
end

on handleEPSnotify me, tMsg
  ttype = EMPTY
  tdata = EMPTY
  tDelim = the itemDelimiter
  the itemDelimiter = "="
  repeat with f = 1 to tMsg.content.line.count
    tProp = tMsg.content.line[f].item[1]
    tDesc = tMsg.content.line[f].item[2]
    case tProp of
      "t":
        ttype = integer(tDesc)
      "p":
        tdata = tDesc
    end case
  end repeat
  the itemDelimiter = tDelim
  case ttype of
    580:
      if not createObject("lang_test", "CLangTest") then
        return error(me, "Failed to init lang tester!", #handle_eps_notify)
      else
        return getObject("lang_test").setWord(tdata)
      end if
  end case
  executeMessage(#notify, ttype, tdata, tMsg.connection.getID())
end

on handleSystemBroadcast me, tMsg
  tMsg = tMsg[#content]
  tMsg = replaceChunks(tMsg, "\r", RETURN)
  tMsg = replaceChunks(tMsg, "<br>", RETURN)
  executeMessage(#alert, [#msg: tMsg])
  the keyboardFocusSprite = 0
end

on handleCheckSum me, tMsg
  getObject(#session).set("user_checksum", tMsg.content)
end

on handleAvailableBadges me, tMsg
  tBadgeList = []
  tNumber = tMsg.connection.GetIntFrom()
  repeat with i = 1 to tNumber
    tBadgeID = tMsg.connection.GetStrFrom()
    tBadgeList.add(tBadgeID)
  end repeat
  tChosenBadge = tMsg.connection.GetIntFrom()
  tVisible = tMsg.connection.GetIntFrom()
  tChosenBadge = tChosenBadge + 1
  if tChosenBadge < 1 then
    tChosenBadge = 1
  end if
  getObject("session").set("available_badges", tBadgeList)
  getObject("session").set("chosen_badge_index", tChosenBadge)
  getObject("session").set("badge_visible", tVisible)
end

on handleRights me, tMsg
  tSession = getObject(#session)
  tSession.set("user_rights", [])
  tRights = tSession.get("user_rights")
  tPrivilegeFound = 1
  repeat while tPrivilegeFound = 1
    tPrivilege = tMsg.connection.GetStrFrom()
    if (tPrivilege = VOID) or (tPrivilege = EMPTY) then
      tPrivilegeFound = 0
      next repeat
    end if
    tRights.add(tPrivilege)
  end repeat
  return 1
end

on handleErr me, tMsg
  error(me, "Error from server:" && tMsg.content, #handle_error)
  if tMsg.content contains "login incorrect" then
    removeConnection(tMsg.connection.getID())
    me.getComponent().setaProp(#pOkToLogin, 0)
    if getObject(#session).exists("failed_password") then
      openNetPage(getVariable("login_forgottenPassword_url"))
      me.getInterface().showLogin()
      return 0
    else
      getObject(#session).set("failed_password", 1)
      me.getInterface().showLogin()
      executeMessage(#alert, [#msg: "Alert_WrongNameOrPassword"])
    end if
  else
    if tMsg.content contains "mod_warn" then
      tDelim = the itemDelimiter
      the itemDelimiter = "/"
      tTextStr = tMsg.content.item[2..tMsg.content.item.count]
      the itemDelimiter = tDelim
      executeMessage(#alert, [#title: "alert_warning", #msg: tTextStr, #modal: 1])
    else
      if tMsg.content contains "Version not correct" then
        executeMessage(#alert, [#msg: "Old client version!!!"])
      end if
    end if
  end if
  return 1
end

on handleModAlert me, tMsg
  if not voidp(tMsg.content) then
    executeMessage(#alert, [#title: "alert_warning", #msg: tMsg.content])
  else
    error(me, "Error in moderator alert:" && tMsg.content, #handleModAlert)
  end if
end

on handleCallForHelpCategories me, tMsg
  tCategories = []
  tTotalCategories = tMsg.connection.GetIntFrom()
  repeat with i = 1 to tTotalCategories
    tCategoryName = tMsg.connection.GetStrFrom()
    tTotalTopics = tMsg.connection.GetIntFrom()
    tTopics = []
    repeat with j = 1 to tTotalTopics
      tReasonIdentifier = tMsg.connection.GetStrFrom()
      tTopicID = tMsg.connection.GetIntFrom()
      tConsequence = tMsg.connection.GetStrFrom()
      tTopics[j] = [#reason: tReasonIdentifier, #topicId: tTopicID, #consequence: tConsequence]
    end repeat
    tCategories[i] = [#name: tCategoryName, #topics: tTopics]
  end repeat
  getObject(#session).set("cfh_categories", tCategories)
end

on regMsgList me, tBool
  tMsgs = [:]
  tMsgs.setaProp(-1, #handleDisconnect)
  tMsgs.setaProp(0, #handleHello)
  tMsgs.setaProp(1, #handleSecretKey)
  tMsgs.setaProp(2, #handleRights)
  tMsgs.setaProp(3, #handleLoginOK)
  tMsgs.setaProp(5, #handleUserObj)
  tMsgs.setaProp(20, #handleOneTimePassword)
  tMsgs.setaProp(33, #handleErr)
  tMsgs.setaProp(35, #handleUserBanned)
  tMsgs.setaProp(50, #handlePing)
  tMsgs.setaProp(51, #handleRegistrationOK)
  tMsgs.setaProp(52, #handleEPSnotify)
  tMsgs.setaProp(139, #handleSystemBroadcast)
  tMsgs.setaProp(141, #handleCheckSum)
  tMsgs.setaProp(161, #handleModAlert)
  tMsgs.setaProp(229, #handleAvailableBadges)
  tMsgs.setaProp(257, #handleSessionParameters)
  tMsgs.setaProp(550, #handleCallForHelpCategories)
  tCmds = [:]
  tCmds.setaProp("TRY_LOGIN", 4)
  tCmds.setaProp("VERSIONCHECK", 5)
  tCmds.setaProp("UNIQUEID", 6)
  tCmds.setaProp("GET_INFO", 7)
  tCmds.setaProp("GET_CREDITS", 8)
  tCmds.setaProp("GET_PASSWORD", 47)
  tCmds.setaProp("LANGCHECK", 58)
  tCmds.setaProp("BTCKS", 105)
  tCmds.setaProp("GETAVAILABLEBADGES", 157)
  tCmds.setaProp("GET_SESSION_PARAMETERS", 181)
  tCmds.setaProp("PONG", 196)
  tCmds.setaProp("GENERATEKEY", 202)
  tCmds.setaProp("GET_CFH_CATEGORIES", 550)
  tConn = getVariable("connection.info.id", #info)
  if tBool then
    registerListener(tConn, me.getID(), tMsgs)
    registerCommands(tConn, me.getID(), tCmds)
  else
    unregisterListener(tConn, me.getID(), tMsgs)
    unregisterCommands(tConn, me.getID(), tCmds)
  end if
  return 1
end
