on prepareMovie
  castLib(2).preloadMode = 1
  preloadNetThing(castLib(2).fileName)
  set the centerStage to 1
  moveToFront(the stage)
  set the exitLock to 1
  puppetTempo(15)
end

on stopMovie
  stopClient()
  go(1)
end
