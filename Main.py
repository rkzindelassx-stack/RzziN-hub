import discord
from discord import app_commands
import asyncio

TOKEN    = "MTU3MzE3MTA3NTgwMDM3MTI1MA.Grd6fH.VUDcLScbZIMpxQQ8ZhH_5WcPwFoOQnQxZBfH5c"
GUILD_ID = 1573168849078059088

STRUCTURE = {
    "central": [("🚩・entrada","text"),("📋・termos","text"),("🔔・anúncios","text"),("🎉・sorteio","text"),("❓・como-comprar","text")],
    "interagir": [("💬・chat","text")],
    "clientes": [("🛍️・vendas","text"),("⭐・avaliações","text"),("📸・setups","text"),("🖼️・wallpapers","text")],
    "j4ilbr3aks": [("🎁・pacote-vip","text"),("🟡・j4il-claude","text"),("🦭・j4il-deepseek","text"),("💻・j4il-opencode","text"),("🤖・j4il-chatgpt","text"),("🚀・j4il-gemini","text"),("⌨️・prompts","text"),("⚙️・offsets","text")],
    "produtos": [("🤖・chatgpt-plus","text"),("💻・mtd-nitrO","text"),("🔧・m3t0dos","text"),("🛸・f0rn-gringo","text")],
}

CATEGORY_PERMISSIONS = {
    "central":    {"read_messages":True,"send_messages":False},
    "interagir":  {"read_messages":True,"send_messages":True},
    "clientes":   {"read_messages":True,"send_messages":False},
    "j4ilbr3aks": {"read_messages":False,"send_messages":False},
    "produtos":   {"read_messages":True,"send_messages":False},
}

intents = discord.Intents.default()
intents.guilds = True
intents.members = True

class MyBot(discord.Client):
    def __init__(self):
        super().__init__(intents=intents)
        self.tree = app_commands.CommandTree(self)
    async def setup_hook(self):
        guild = discord.Object(id=GUILD_ID)
        self.tree.copy_global_to(guild=guild)
        await self.tree.sync(guild=guild)

bot = MyBot()

async def set_perms(cat, guild, perms):
    ow = discord.PermissionOverwrite(read_messages=perms.get("read_messages",True),send_messages=perms.get("send_messages",True))
    try: await cat.set_permissions(guild.default_role,overwrite=ow)
    except: pass

async def get_or_create_cat(guild, name, pos):
    for c in guild.categories:
        if c.name.lower()==name.lower(): return c
    return await guild.create_category(name,position=pos)

async def get_or_create_ch(guild, cat, name, typ, pos):
    for c in cat.channels:
        if c.name.lower()==name.lower(): return c
    if typ=="voice": return await guild.create_voice_channel(name,category=cat,position=pos)
    return await guild.create_text_channel(name,category=cat,position=pos)

@bot.tree.command(name="organizar",description="Organiza os canais do servidor")
@app_commands.checks.has_permissions(administrator=True)
async def organizar(interaction: discord.Interaction):
    await interaction.response.defer(ephemeral=True)
    try:
        for i,(cat_name,channels) in enumerate(STRUCTURE.items()):
            cat = await get_or_create_cat(interaction.guild,cat_name,i)
            perms = CATEGORY_PERMISSIONS.get(cat_name,{})
            if perms: await set_perms(cat,interaction.guild,perms)
            for j,(ch_name,ch_type) in enumerate(channels):
                await get_or_create_ch(interaction.guild,cat,ch_name,ch_type,j)
                await asyncio.sleep(0.5)
            await asyncio.sleep(1)
        await interaction.followup.send("✅ Organizado!",ephemeral=True)
    except Exception as e:
        await interaction.followup.send(f"❌ Erro: {e}",ephemeral=True)

@bot.event
async def on_ready():
    print(f"✅ Bot online: {bot.user}")

bot.run(TOKEN)
