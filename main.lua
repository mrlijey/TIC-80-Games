-- STARDRIFT
-- Collect the signal shards and survive the drifting debris.

local W, H = 240, 136
local player
local shards
local rocks
local sparks
local score
local best = 0
local state
local tick

local function spawn_shard()
  return {
    x = 18 + math.random(0, 203),
    y = 24 + math.random(0, 94),
    pulse = math.random(0, 99)
  }
end

local function spawn_rock()
  return {
    x = 252 + math.random(0, 40),
    y = 28 + math.random(0, 91),
    r = math.random(3, 7),
    speed = 0.45 + math.random() * 0.8,
    wobble = math.random(0, 99)
  }
end

local function burst(x, y, color, amount)
  for i = 1, amount do
    local angle = math.random() * math.pi * 2
    local speed = 0.4 + math.random() * 1.6
    table.insert(sparks, {
      x = x,
      y = y,
      dx = math.cos(angle) * speed,
      dy = math.sin(angle) * speed,
      life = 18 + math.random(0, 12),
      color = color
    })
  end
end

local function start_game()
  player = { x = 44, y = 80, r = 4, invincible = 0 }
  shards = {}
  rocks = {}
  sparks = {}
  score = 0
  tick = 0
  state = "play"
  for i = 1, 3 do table.insert(shards, spawn_shard()) end
  for i = 1, 4 do table.insert(rocks, spawn_rock()) end
end

local function circle_hit(a, b)
  local dx = a.x - b.x
  local dy = a.y - b.y
  local radius = a.r + (b.r or 3)
  return dx * dx + dy * dy < radius * radius
end

local function update_sparks()
  for i = #sparks, 1, -1 do
    local spark = sparks[i]
    spark.x = spark.x + spark.dx
    spark.y = spark.y + spark.dy
    spark.life = spark.life - 1
    if spark.life <= 0 then table.remove(sparks, i) end
  end
end

local function update_game()
  tick = tick + 1
  local dx = 0
  local dy = 0
  if btn(0) or btn(4) then dx = dx - 1 end
  if btn(1) or btn(5) then dx = dx + 1 end
  if btn(2) or btn(6) then dy = dy - 1 end
  if btn(3) or btn(7) then dy = dy + 1 end

  player.x = math.max(10, math.min(230, player.x + dx * 1.7))
  player.y = math.max(29, math.min(128, player.y + dy * 1.7))
  player.invincible = math.max(0, player.invincible - 1)

  for i = #rocks, 1, -1 do
    local rock = rocks[i]
    rock.x = rock.x - rock.speed
    rock.y = rock.y + math.sin((tick + rock.wobble) * 0.04) * 0.22
    if rock.x < -12 then table.remove(rocks, i) end
    if player.invincible == 0 and circle_hit(player, rock) then
      burst(player.x, player.y, 8, 18)
      state = "gameover"
      best = math.max(best, score)
    end
  end

  if tick % math.max(16, 42 - math.floor(score / 3)) == 0 then
    table.insert(rocks, spawn_rock())
  end

  for i = #shards, 1, -1 do
    local shard = shards[i]
    shard.pulse = shard.pulse + 1
    if circle_hit(player, { x = shard.x, y = shard.y, r = 5 }) then
      score = score + 1
      burst(shard.x, shard.y, 10, 10)
      table.remove(shards, i)
      table.insert(shards, spawn_shard())
    end
  end
  update_sparks()
end

local function draw_background()
  cls(1)
  rect(0, 20, W, 1, 5)
  for i = 1, 36 do
    local x = (i * 47 + tick * (i % 3 + 1)) % W
    local y = 25 + (i * 31) % 105
    pix(x, y, i % 4 == 0 and 6 or 13)
  end
end

local function draw_sprite(x, y, pattern, colors)
  for row, pixels in ipairs(pattern) do
    for column = 1, #pixels do
      local color = colors[string.sub(pixels, column, column)]
      if color then pix(x + column - 1, y + row - 1, color) end
    end
  end
end

local function draw_shard(shard)
  local glow = 9 + math.floor(math.sin(shard.pulse * 0.12) * 2)
  draw_sprite(shard.x - 3, shard.y - 4, {
    "...c...",
    "..ccc..",
    ".ccgc..",
    "ccggcc.",
    ".ccgc..",
    "..ccc..",
    "...c..."
  }, { c = 10, g = glow })
end

local function draw_rock(rock)
  draw_sprite(rock.x - 5, rock.y - 5, {
    "..dddd...",
    ".dddddd..",
    "ddddddddd",
    "ddddddddd",
    "ddddddddd",
    ".ddddddd.",
    "..ddddd..",
    "...ddd..."
  }, { d = 4 })
  pix(rock.x - 2, rock.y - 1, 3)
  pix(rock.x + 2, rock.y + 2, 3)
end

local function draw_ship(ship)
  draw_sprite(ship.x - 4, ship.y - 4, {
    "....w....",
    "...www...",
    "..wwwww..",
    ".wwwwwbww",
    "wwwwwwwbb",
    ".wwwwwbww",
    "..wwwww..",
    "...www...",
    "....f...."
  }, {
    w = 12,
    b = 15,
    f = tick % 6 < 3 and 9 or 2
  })
end

local function draw_game()
  draw_background()
  print("STARDRIFT", 8, 7, 12, false, 1, true)
  print("SHARDS " .. score, 174, 7, 10, false, 1, true)

  for _, shard in ipairs(shards) do
    draw_shard(shard)
  end

  for _, rock in ipairs(rocks) do
    draw_rock(rock)
  end

  if player.invincible == 0 or tick % 4 < 2 then
    draw_ship(player)
  end

  for _, spark in ipairs(sparks) do pix(spark.x, spark.y, spark.color) end
end

local function draw_gameover()
  rect(35, 47, 170, 45, 1)
  rectb(35, 47, 170, 45, 10)
  print("SIGNAL LOST", 75, 57, 6, false, 2, true)
  print("SCORE " .. score .. "   BEST " .. best, 65, 70, 12)
  print("PRESS Z TO REBOOT", 67, 82, 11)
end

function TIC()
  if not state then start_game() end
  if state == "play" then
    update_game()
  elseif btnp(4) or btnp(5) then
    start_game()
  end
  draw_game()
  if state == "gameover" then draw_gameover() end
end