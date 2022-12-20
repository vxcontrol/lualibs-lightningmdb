lightningmdb_lib=require "lightningmdb"

lightningmdb = _VERSION>="Lua 5.2" and lightningmdb_lib or lightningmdb
MDB = setmetatable({}, {__index = function(t, k)
  return lightningmdb["MDB_" .. k]
end})

