local token = '5323542329:AAEddFw_50a0YaGqcS0U71BTnoOqg2jLI7U'
local admin = "709733712";
local bot = require('telegram-bot-lua.core').configure(token)
local tools = require('telegram-bot-lua.tools')
local redis = require 'redis'
local thread = require "llthreads2"
local json = require("dkjson")
local client = redis.connect('127.0.0.1', 6379)
local rq = require("requests")
local mn = {}
local startTime = os.time()

local function stopFile(name, text)
    local file = io.open("stops/stop[" .. name .. "].txt", "w")
    file:write(text)
    file:close()
end

function time_format(seconds)
    local seconds = tonumber(seconds)
    local d = math.floor(seconds / (3600 * 24))
    local h = math.floor(seconds / 3600 % 24)
    local m = math.floor(seconds % 3600 / 60)
    local s = math.floor(seconds % 3600 % 60)
    if d > 0 then
        return ('%.fD %.fH %.fm %.fs'):format(d, h, m, s)
    elseif h > 0 then
        return ('%.fH %.fm %.fs'):format(h, m, s)
    elseif m > 0 then
        return ('%.fm %.fs'):format(m, s)
    elseif s > 0 then
        return ('%.fs'):format(s)
    end
    return '-'
end

function bot.on_update(update)
    if not update.message then return end
    local message = update.message
    local chat_id = message.chat.id
    local from_id = tostring(message.from.id)
    local first_name = message.from.first_name
    local text = message.text
    local chat_type = message.chat.type
    if (not client:sismember("totalusers", from_id)) and chat_type == "private" then
        client:sadd("totalusers", from_id)
        print("new user: " .. first_name .. "\nid: " .. from_id)
    end
    if (not client:sismember("totalsupergroups", chat_id)) and chat_type == "supergroup" then
        client:sadd("totalsupergroups", chat_id)
        print("new group: " .. message.chat.title .. "\nid: " .. chat_id)
        bot.send_message(admin, "New group !\n" .. message.chat.title .. "\n@" .. (message.chat.username or "None"))
    end
    if text and text:match("^/start") then
        return bot.send_message(chat_id, "Hello, *" .. tools.escape_markdown(first_name) .. "*\nuse `/mention` to mention all users.\nuse `/stopmention` to stop mentioning users.\n\n- `Note`:\n1- it only works on supergroups\n2- you need to be an Admin for this to work.\n3- theBot does not require to be An admin for this to work.",
            "markdown",
            true, false, message.message_id, bot.inline_keyboard():row(
                bot.row():url_button(
                    "🧚‍♂️",
                    'https://t.me/notmafia')))
    end
    if text and text:match("^/mention") and chat_type == "supergroup" then
        local stats = rq.get("https://api.telegram.org/bot" .. token .. "/getChatMember?chat_id=" .. chat_id .. "&user_id=" .. from_id).text;
        local info = json.decode(stats);
        local you = info['result']['status'];
        if (string.lower(you) == "administrator") or (string.lower(you) == "creator" or from_id == admin) then
            if client:get("mn:" .. chat_id) then return end
            bot.send_message(chat_id, "Okay, *" .. tools.escape_markdown(first_name) .. "*\n`Note:`\n1- It send's 10 users each 1 second\n2- It can't send over 10 users per message, telegram issues.\n3- have fun :)", "markdown",
                true, false, message.message_id, bot.inline_keyboard():row(
                    bot.row():url_button(
                        "🧚‍♂️",
                        'https://t.me/notmafia')))
            local text = text:gsub("%/mention%@MentionsAllBot", "")
            local text = text:match("^/mention(.*)") or text
            if #text > 200 then return bot.send_message(chat_id, "You can't write over 200 chars.", "markdown",
                    true, false, message.message_id)
            end
            local tt = string.format([[
chat_id = "%s"
redis = require("redis")
local client = redis.connect('127.0.0.1', 6379)
os.execute("python3 mention.py "..chat_id)
client:del("mn:"..chat_id)
client:del("stop:"..chat_id)
client:del(chat_id..":text")
]]           , chat_id)
            mn[chat_id] = thread.new(tt)
            mn[chat_id]:start()
            client:rpush("totalmentions", 1)
            client:set(chat_id..":text", text)
            return client:set("mn:" .. chat_id, 1)
        else
            return bot.send_message(chat_id, "You're not an Admin!", "markdown",
                true, false, message.message_id)
        end
    end
    --
    --
    --
    --
    --
    if text and text:match("^/stopmention") and chat_type == "supergroup" then
        local stats = rq.get("https://api.telegram.org/bot" .. token .. "/getChatMember?chat_id=" .. chat_id .. "&user_id=" .. from_id).text;
        local info = json.decode(stats);
        local you = info['result']['status'];
        if (string.lower(you) == "administrator") or (string.lower(you) == "creator" or from_id == admin) then
            if not client:get("mn:" .. chat_id) then
                return bot.send_message(chat_id, "*No running mentions!*", "markdown",
                    true, false, message.message_id)
            end
            bot.send_message(chat_id, "Okay, *" .. tools.escape_markdown(first_name) .. "*\nStopping now.", "markdown",
                true, false, message.message_id, bot.inline_keyboard():row(
                    bot.row():url_button(
                        "🧚‍♂️",
                        'https://t.me/notmafia')))
            mn[chat_id] = nil;
            client:rpush("totalstopmentions", 1)
            return client:set("stop:" .. chat_id, 1)
        else
            return bot.send_message(chat_id, "You're not an Admin!", "markdown",
                true, false, message.message_id)
        end
    end
    if text and text:match("^/stats") then
        return bot.send_message(chat_id,
            "*Up time*: `" .. time_format(os.difftime(os.time(), startTime)) .. "`\n\n- Users: *" .. (#client:smembers("totalusers") or 0) .. "*\n- Groups: *" .. (#client:smembers("totalsupergroups") or 0) .. "*\n- Mentions: *" .. (#(client:lrange("totalmentions", 0, -1) or 0)) .. "*\n- Stoped Mentions: *" .. (#(client:lrange("totalstopmentions", 0, -1) or 0)) .. "*", "markdown",
            true, false, message.message_id)
    end
end

bot.run()
