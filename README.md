# Archie — a virtual pet powered by Google Tasks

A baby octopus that eats your completed tasks, frets over overdue ones, and grows into a legendary kraken as you build daily streaks. The page is styled like an old nautical chart, with a light (parchment) and dark (night chart) look that follows your system setting.

*Archie was previously called Taskling. If you set things up under the old name, nothing breaks: your pet, saves, and Google setup all keep working. To have Google's sign-in screen show the new name, change the app name on the consent screen (step 3) to `Archie`.*

## How it works

| Your tasks | What happens to the pet |
|---|---|
| Complete a task (in the app **or** in Google Tasks on your phone) | +15 fullness, +10 happiness, +4 health. Overdue tasks give a bigger happiness boost when you finally clear them. |
| Tasks sit overdue | Happiness and health drain every hour for each overdue task. |
| Time passes | Fullness and happiness slowly drop. If fullness hits 0, health drops too. |
| Health hits 0 | The pet faints (it doesn't die). Completing any task revives it. |
| Daily streak (at least one task done per day) | Grows from an **Egg → Hatchling** (first completion) **→ Inkling** (3 days) **→ Tidecaller** (7) **→ Deepwarden** (14) **→ Kraken** (30), a crowned, horned sea-king. Evolution is based on your best streak, so a missed day doesn't make it regress. |

### Standing orders (required tasks)

Click the **anchor** next to any task to make it a *standing order*. The rules:

- A standing order is required **on its due date**. It has to be checked off by the end of that day.
- A day counts toward your streak only if **every standing order due that day** is done, and at least one task is finished overall.
- Missing one breaks the streak for that day. If you finish it the next day, it's still a miss.
- Days with no standing orders due work as before: any finished task keeps the streak going.
- Standing orders are matched by **task name**, so repeating tasks in Google Tasks keep their standing order each time they come back, even though Google gives every repeat a new copy.
- A standing order with no due date never counts. Give it a due date or a repeat schedule in Google Tasks.
- Orders apply from the day you set them, so they never erase streak days you'd already earned.
- Removing an order also clears any misses it caused.

The **Standing Orders** panel lists each order with today's status (*Due today*, *Done today*, *Overdue*, *Next: date*, or *No due date*) and tells you whether today's streak is secured. Standing orders are saved with your pet, so they follow you between devices.

Click the pet (or PAT) for a small happiness boost every 5 minutes. Click its name to rename it.

On the first sync of a list, existing completed tasks count toward your streak history but don't feed the pet (no free feast). Everything after that does.

## Try it now (demo mode, no setup)

Double-click `index.html`. It opens in demo mode with sample tasks stored in your browser.

## Connect Google Tasks (one-time setup, ~10 minutes)

Use a **personal Gmail account** for this. Firm/Google Workspace accounts often block unverified apps unless an admin approves them.

1. **Create a project.** Go to <https://console.cloud.google.com/>, click the project picker at the top, choose **New project**, name it `Archie`, and create it. Make sure it's selected.
2. **Enable two APIs.** Go to **APIs & Services → Library**, search **Google Tasks API**, open it, and click **Enable**. Then do the same for **Google Drive API** (used to save your pet to the cloud).
3. **Set up the consent screen.** Go to **APIs & Services → OAuth consent screen** (newer consoles call this **Google Auth Platform**, with **Branding** and **Audience** tabs).
   - App name: `Archie`; support email: yours.
   - Audience/user type: **External**.
   - Leave it in **Testing** mode and add your own Gmail address under **Test users**.
4. **Create the client ID.** Go to **Credentials** (or **Clients**) → **Create credentials → OAuth client ID**.
   - Application type: **Web application**.
   - Under **Authorized JavaScript origins**, add exactly: `http://localhost:8000`
   - No redirect URIs needed. Click **Create** and copy the **Client ID** (ends in `.apps.googleusercontent.com`). You do *not* need the client secret.
5. **Paste it into the app.** Open `index.html` in a text editor, find `CONFIG` near the top of the `<script>`, and replace `PASTE_YOUR_CLIENT_ID.apps.googleusercontent.com` with your ID.
6. **Run a tiny local server.** Google sign-in won't work from a double-clicked file, so in a terminal:
   ```
   cd path/to/archie
   python3 -m http.server 8000
   ```
   (On Windows use `python` or `py` instead of `python3`.) Then open <http://localhost:8000>.
7. **Connect.** Click **Connect Google Tasks** and sign in. You'll see a "Google hasn't verified this app" screen — that's normal for your own testing app. Click **Continue**, and allow both permissions (your tasks, and Archie's own Drive folder). Pick which task list to use from the dropdown.

Changes in the Google Console can take a few minutes to kick in; if you get an `origin_mismatch` error, double-check step 4 and wait a bit.

## Good to know

- **Sign-in lasts about an hour.** That's how browser-only Google sign-in works. When it expires, a **Reconnect** button appears (one click, no password usually).
- **Syncing:** the app checks Google every 2 minutes while open and whenever you switch back to the tab, so tasks you finish on your phone still feed the pet.
- **Where data lives:** once you connect Google, your pet (stats, name, streak history, log) is saved as a small file in your Google Drive's hidden *app data* folder. Only Archie can see that folder; it doesn't show up in your Drive and Archie can't see the rest of your Drive. A copy is also kept in your browser as a backup. Your tasks stay in Google Tasks. The access token is never saved to disk.
- **Cloud saves:** the pet saves to Drive a moment after anything meaningful happens (eating a task, a pat, renaming, evolving) and checks Drive for newer saves whenever it syncs. The **☁** label in the header shows the save status. The first time a browser connects, it loads the pet from Drive if one exists there; after that the most recent save wins. Demo mode stays in the browser only.
- **Already connected before cloud saves existed?** Turn on the Google Drive API (step 2), then click **Reconnect** and allow the new Drive permission. Your current pet is uploaded as the first cloud save.
- **Tweak the game:** the `RATES`, `FEED`, and `STAGES` objects near the top of the script control decay speeds, feeding amounts, and evolution thresholds.

## Ideas for next steps

- Host it (e.g., GitHub Pages) so it works from any device — add that URL as another authorized JavaScript origin.
- Turn it into a Chrome extension so the pet's mood shows in the toolbar.
- Track multiple lists at once, or give different lists different "foods."
