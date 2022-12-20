require "lightningmdb_common_test"

local function pt(t)
  for k,v in pairs(t) do
    print(k,v)
  end
end

local function ps(e)
  print("--- env stat")
  pt(e:stat())
  print("---")
end

local function test_setup(dir_)
  local dir = "./temp/"..dir_
  os.execute("mkdir -p "..dir)
  os.execute("rm -rf "..dir.."/data.mdb")
  os.execute("rm -rf "..dir.."/lock.mdb")
  return dir
end

local function basic_test()
  print("Lightning MDB version:",lightningmdb.version())
  print("Lightning error:",lightningmdb.strerror(0))

  print("-- globals --")
  pt(lightningmdb)

  -- env
  local e = lightningmdb.env_create()
  print(e)
  local dir = test_setup("foo")
  print(e:open(dir,0,420))
  print("fixedmap",MDB.FIXEDMAP)
  print("read only",MDB.RDONLY)

  print("-- stats --")
  pt(e:stat())

  print("-- info --")
  pt(e:info())
  print("get_path",e:get_path())


  --txn
  local t = e:txn_begin(nil,0)
  print("txn",t)
  t:commit()
  t = e:txn_begin(nil,0)
  print("txn",t)
  t:reset()
  t:renew()
  --t:abort()
  local db = t:dbi_open(nil,0)
  print(string.format("-- txn stat [%d] --",t:id()))
  pt(t:stat(db))
  t:abort()
  e:close()
end

local function grow_db()
  print("--- grow_db ---")
  local num_pages = 5
  local e

  local dir = test_setup("bar")

  local function grow()
    e = lightningmdb.env_create()
    num_pages = num_pages * 2
    print(e:set_mapsize(num_pages*4096))
    print(e:open(dir,0,420))
  end

  grow()
  local t = e:txn_begin(nil,0)
  local db = t:dbi_open(nil,MDB.DUPSORT)
  for i=1,600 do
    local rc,err = t:put(db,"hello "..i,"cruel world",MDB.NODUPDATA)
    if not rc then
      if err:find("MDB_MAP_FULL",1,true) then
        print("making more room at",i)
        t:abort()
        e:close()

        grow()
        t = e:txn_begin(nil,0)
        db = t:dbi_open(nil,MDB.DUPSORT)
      else
        print(rc,err)
      end
    end
  end
end

local function cursor_pairs(cursor_,key_,op_)
  return coroutine.wrap(
    function()
      local k = key_
      repeat
        k,v = cursor_:get(k,op_ or MDB.NEXT)
        if k then
          coroutine.yield(k,v)
        end
      until not k
    end)
end

local function mtest()
  print("--- mtest2")
  local count = math.random(10)+15
  local values = {}
  math.randomseed(os.time())
  for i=1,count do
    values[i] = math.random(1024)
  end

  local e = lightningmdb.env_create()
  e:set_mapsize(10485760)
  local dir = test_setup("testdb")
  e:open(dir,MDB.FIXEDMAP,420)
  local t = e:txn_begin(nil,0)
  local d = t:dbi_open(nil,0)

  print("adding values:",count)
  local j = 0
  for i,v in ipairs(values) do
    local rc = t:put(d,string.format("%03x",v),string.format("%d foo bar",v),
                     MDB.NOOVERWRITE)
    if not rc then
      j = j + 1
    end
  end

  print(j,"duplicates skipped")
  t:commit()
  ps(e)

  t = e:txn_begin(nil,0)
  c = t:cursor_open(d)
  local k


  for k,v in cursor_pairs(c) do
    print(k,v)
  end

  c:close()
  t:abort()
  math.randomseed(os.time())
  j = 0
  for i=count,1,-math.random(5) do
    j = j + 1
    t = e:txn_begin(nil,0)
    local key = string.format("%03x",values[i])
    if not t:del(d,key,nil) then
      j = j - 1
      t:abort()
    else
      t:commit()
    end
  end

  print("deleted",j,"values")
  ps(e)
  t = e:txn_begin(nil,0)
  c = t:cursor_open(d)
  print("cursor next")
  local key
  for k,v in cursor_pairs(c,nil,MDB.NEXT) do
    print(k,v)
    key = k
  end

  print("cursor prev")

  for k,v in cursor_pairs(c,key,MDB.PREV) do
    print(k,v)
  end

  c:close()
  e:dbi_close(d)

  t:abort()
  e:close()
end

local function mtest2()
  print("--- mtest2")

  local count = math.random(10)+15
  local values = {}
  math.randomseed(os.time())
  for i=1,count do
    values[i] = math.random(1024)
  end

  local e = lightningmdb.env_create()
  e:set_mapsize(10485760)
  e:set_maxdbs(4)
  local dir = test_setup("testdb")
  e:open(dir,MDB.FIXEDMAP + MDB.NOSYNC,420)
  local t = e:txn_begin(nil,0)
  local d = t:dbi_open("id1",MDB.CREATE)

  print("adding values:",count)
  local j = 0
  for i,v in ipairs(values) do
    local rc = t:put(d,string.format("%03x",v),string.format("%d foo bar",v),
                     MDB.NOOVERWRITE)
    if not rc then
      j = j + 1
    end
  end

  print(j,"duplicates skipped")
  t:commit()
  ps(e)

  t = e:txn_begin(nil,0)
  c = t:cursor_open(d)
  local k


  for k,v in cursor_pairs(c) do
    print(k,v)
  end

  c:close()
  t:abort()
  math.randomseed(os.time())
  j = 0
  for i=count,1,-math.random(5) do
    j = j + 1
    t = e:txn_begin(nil,0)
    local key = string.format("%03x",values[i])
    if not t:del(d,key,nil) then
      j = j - 1
      t:abort()
    else
      t:commit()
    end
  end

  print("deleted",j,"values")

  ps(e)
  t = e:txn_begin(nil,0)
  c = t:cursor_open(d)
  print("cursor next")
  local key
  for k,v in cursor_pairs(c,nil,MDB.NEXT) do
    print(k,v)
    key = k
  end

  print("cursor prev")

  for k,v in cursor_pairs(c,key,MDB.PREV) do
    print(k,v)
  end

  c:close()
  e:dbi_close(d)

  t:abort()
  e:close()
end

local function mtest3()
  print("--- mtest3")

  local count = math.random(10)+15
  local values = {}
  math.randomseed(os.time())
  for i=1,count do
    values[i] = math.random(1024)
  end

  local e = lightningmdb.env_create()
  e:set_mapsize(10485760)
  e:set_maxdbs(4)
  local dir = test_setup("testdb")
  e:open(dir,MDB.FIXEDMAP + MDB.NOSYNC,420)

  local t = e:txn_begin(nil,0)
  local d = t:dbi_open("id2",MDB.CREATE+MDB.DUPSORT)

  print("adding values:",count)
  local j = 0
  for i,v in ipairs(values) do
    if i%5==0 then
      v = values[i-1]
    end
    local rc = t:put(d,string.format("%03x",v),string.format("%d foo bar",v),
                     MDB.NODUPDATA)
    if not rc then
      j = j + 1
    end
  end
  if j>0 then
    print("duplicate skipped",j)
  end
  t:commit()
  ps(e)

  t = e:txn_begin(nil,0)
  c = t:cursor_open(d)

  for k,v in cursor_pairs(c,nil,MDB.NEXT) do
    print(k,v)
  end

end

basic_test()
grow_db()

mtest()
mtest2()
mtest3()
