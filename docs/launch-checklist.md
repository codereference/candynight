# Launch checklist

These are the steps only the game's owner (Sep_1264) can do, because they need your Roblox account.
Work through them in order. Everything you create gives you an id; each id goes into
`src/shared/Config.luau`. Until an id is filled in, that feature quietly does nothing (it's
"Coming soon!" in the store, badges aren't sent to Roblox, and placeholder parts stay), so the game
works at every step.

Tracked in issue #28.

## 1. Play it in Studio first

1. Start the sync server from the repo:

   ```bash
   rojo serve
   ```

2. In Roblox Studio: **File → New → Baseplate**, then **Plugins → Rojo → Connect**.
3. Press **Play**. Serve customers, buy buttons, hire a baker, place a Gumdrop Turret, and
   survive a night. Open **👑 Admin** to skip to night, spawn shadows, or give yourself cash.
4. Try it as a phone: **Test → Device** and choose a phone, then play again with touch.

## 2. Create the experience

1. **File → Publish to Roblox**. Name it **Sweet Nights Tycoon**.
2. In **Game Settings → Security**, turn on **Enable Studio Access to API Services** (this is
   what lets saving and the leaderboard work in Studio).
3. In **Game Settings → Places → Sweet Nights Tycoon**, set **Max Players** to **6**. Each server
   has exactly 6 shops.
4. On the Creator Dashboard, open the experience and fill in the **Experience Questionnaire**.
   Answer honestly: cartoon spooky creatures, no blood or gore. The goal is the **Mild** rating.
5. **Monetization → Private Servers**: turn them on and set the price to **Free**.
6. **Localization**: turn on **Automatic Translation** and **Automatic Text Capture**. The
   `Strings` table syncs from `localization/Strings.csv`, so translators can also fill it in.
   To spot-check, set your Roblox language to Spanish and look over the UI.

## 3. Group

1. Create a Roblox group for the game (for example "Sweet Nights Studio").
2. Copy the group id from its URL into `Group.id`.

## 4. Gamepasses (Monetization → Passes)

Create each one, set a price, then copy its id into `Monetization.passes`:

| Config key | Name | Suggested price |
| --- | --- | --- |
| `DoubleCash` | 2x Cash | 199 Robux |
| `VIP` | VIP | 299 Robux |
| `ExtraHelper` | Extra Helper | 149 Robux |
| `SweetStyle` | Sweet Style | 99 Robux |

## 5. Developer products (Monetization → Developer Products)

Copy each id into `Monetization.products`:

| Config key | Name | Suggested price |
| --- | --- | --- |
| `InstantRepair` | Instant Repair | 25 Robux |
| `TurretOverdrive` | Turret Overdrive | 49 Robux |
| `NightShield` | Night Shield | 39 Robux |

## 6. Badges (Engagement → Badges)

Create one badge per key and copy each id into `Badges`:
`FirstSale`, `FirstStaff`, `FirstDefense`, `FirstNight`, `Streak5`, `Streak10`, `Streak25`,
`Served1000`, `FirstRebirth`, `Rebirth5`. The display names are in `Strings` under `Badge.*`.

## 7. Meshes

Follow **Art: low-poly meshes** in the README: bulk-import `assets/meshes/*.obj` in Studio,
then copy each mesh's asset id into `Meshes`.

## 8. Music

Pick a cheerful day track and a spooky-but-cute night track (check that their licences allow
use in your game). Put them in `Audio.dayMusic` and `Audio.nightMusic` as `"rbxassetid://<id>"`.

## 9. Icon and thumbnails

* **Icon (512×512):** a cute pink bakery on the left and a big-eyed shadow peeking in on the right.
* **Thumbnails (1920×1080):** one bright daytime shop full of customers, one the same shop at
  night with turrets firing candy, and one Blood Moon.

Upload them under **Places → Sweet Nights Tycoon → Icon/Thumbnails**.

## 10. Launch

1. Fill in the codes you want to announce in `Codes` (the launch ones are `SWEETNIGHTS` and
   `RELEASE`).
2. Run `scripts/check.sh`, sync with Rojo, and **Publish to Roblox**.
3. Set the experience to **Public**.
4. Then plan the next update. Regular updates keep Roblox recommending the game.
