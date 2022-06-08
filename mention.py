token = "5323542329:AAHqfZ6NfsHvSWhyZIcTcwCu_Cn3WUA8phQ"  # Your bot token.
api_id = 15942537  # the api id from my.telegram.org
api_hash = "e891c773ab993957f8e94c8d62a32fa1"  # the api hash from my.telegram.org

try:
    import asyncio, sys, time, redis
    from telethon import TelegramClient
except ImportError:
    print("Please install the required libraries. (pip install -r requirements.txt)")
    sys.exit()

r = redis.StrictRedis(
    host="localhost", port=6379, charset="utf-8", decode_responses=True
)
try:
    chat_id = int(sys.argv[1])  # the chatID of the group you want to mention.
except IndexError:  # if no chatID is given.
    print("Usage: python3 mention.py <chat_id>")
    sys.exit()
storeMentionsWithString, StoreMentionsArray = "", []
overFourMentionsSum, totalUsers = [0, 0]


async def starts():  # start the bot function
    global storeMentionsWithString, overFourMentionsSum, totalUsers
    try:
        app = TelegramClient(
            token.split(":")[0], api_id, api_hash
        )  # Connect to the client.
        await app.connect()  # Connect to the client.
        if not await app.is_user_authorized():  # Check if the user is authorized.
            await app.start(bot_token=token)  # if not then Start the client.
        for user in await app.get_participants(chat_id):  # Get all participants.
            if user.id and user.first_name:
                StoreMentionsArray.append(
                    f"[{user.first_name}](tg://user?id={user.id})"
                )
        for mention in StoreMentionsArray:  # Get all mentions.
            if r.get(f"stop:{chat_id}"):  # Check if the bot is stopped.
                print("stopped: " + str(chat_id))
                return sys.exit()
            overFourMentionsSum += 1
            totalUsers += 1
            storeMentionsWithString += str(totalUsers) + "- " + str(mention) + "\n"
            if overFourMentionsSum == 4:
                await app.send_message(chat_id, storeMentionsWithString)
                storeMentionsWithString, overFourMentionsSum = "", 0
                time.sleep(
                    1
                )  # sleep for 1 second to prevent telegram from blocking the bot.
        await app.send_message(chat_id, "Done!,\ntotal users ~ " + str(totalUsers))
    except Exception as e:  # If there is an error.
        with open("log.txt", "a") as f:  # Log the error.
            f.write(str(e) + "\n")
        f.close()
    print("done: " + str(chat_id))  # print the chat id that the bot finished.


if __name__ == "__main__":  # start the bot.
    loop = asyncio.get_event_loop()
    loop.run_until_complete(starts())
