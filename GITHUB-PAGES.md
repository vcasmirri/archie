# Hosting Archie on GitHub Pages

GitHub Pages hosts Archie for free at a real web address, for example `https://yourname.github.io/archie/`. Once it's set up:

- You don't need to run a local server.
- It works from any device, including your phone.
- Your pet follows you between devices through the Google Drive cloud save.

Setup takes about 15 minutes. These steps assume you've already finished the Google Cloud setup in `README.md` (steps 1–5) and have a client ID.

---

## 1. Create a GitHub account

If you don't have one, sign up at <https://github.com/signup>. Your username becomes part of your Archie address, as `https://USERNAME.github.io/...`.

## 2. Create a repository

1. Click **+** (top right) → **New repository**.
2. **Repository name:** `archie` (any name works; it becomes the end of your address).
3. Choose **Public**. Free GitHub accounts can only publish Pages from public repositories (see "Is this safe?" below).
4. Check **Add a README file**.
5. Click **Create repository**.

## 3. Upload Archie

1. Open `index.html` in a text editor and make sure your client ID is pasted into `CONFIG` near the top of the script.
2. In your new repository, click **Add file → Upload files**.
3. Drag in **`index.html`**. You can also upload this guide and `README.md` if you'd like them kept with the project. The README you upload will replace the placeholder one GitHub created, which is fine.
4. Click **Commit changes**.

The file must be named exactly `index.html` and sit at the top level of the repository, not inside a folder.

## 4. Turn on GitHub Pages

1. In the repository, go to **Settings → Pages** (in the left sidebar).
2. Under **Build and deployment**:
   - **Source:** Deploy from a branch
   - **Branch:** `main`, folder **/ (root)**
3. Click **Save**.
4. Wait a minute or two, then refresh the page. A box appears at the top saying **"Your site is live at https://USERNAME.github.io/archie/"**. Copy that address.

If you open the address right away and get a 404, wait another minute. The first publish takes a little while.

## 5. Tell Google about the new address

Google sign-in only works from addresses you've approved. Here's how to add yours:

1. Go to <https://console.cloud.google.com/> and select your Archie project.
2. Open **APIs & Services → Credentials**. In newer consoles, this is **Google Auth Platform → Clients**.
3. Click your OAuth client (the Web application one).
4. Under **Authorized JavaScript origins**, click **Add URI** and enter:
   ```
   https://USERNAME.github.io
   ```
   - Use `https`.
   - Enter **only** the part up to `.io`. Don't include `/archie/` or a trailing slash. Google wants the origin, not the full page address.
   - Keep `http://localhost:8000` in the list too if you still want to test locally.
5. Click **Save**. It can take a few minutes, occasionally longer, to take effect.

## 6. Open Archie and connect

1. Visit `https://USERNAME.github.io/archie/`.
2. Click **Connect Google Tasks** and sign in with the same account you added as a test user.
3. Allow both permissions (your tasks, and Archie's own Drive folder).

If you used cloud saves while running locally, your pet loads from Google Drive automatically. If you only ever ran Archie locally *without* cloud saves, that pet lives in the local browser's storage and won't carry over. Open the local version once, click **Reconnect**, and allow Drive to upload it first.

## 7. Put it on your phone (optional)

Archie works as a home-screen app with a phone layout: the device fills the top of the screen, and a tab bar at the bottom switches between Tasks, Vitals, Recurring, and Log.

**One extra Google step first.** Phones sign in by leaving the page for Google's sign-in screen and coming back, so Google needs to know where "back" is:

1. In the Google Cloud console, open your Web application client again (same place as step 5).
2. Under **Authorized redirect URIs**, click **Add URI** and enter your full Archie address, with the trailing slash:
   ```
   https://USERNAME.github.io/archie/
   ```
3. Click **Save**.

**Then add it to your home screen:**
- **iPhone (Safari):** open your Archie address, tap the Share button → **Add to Home Screen** → **Add**.
- **Android (Chrome):** ⋮ menu → **Add to Home screen** (or **Install app**).

Open Archie from the new icon and tap **Connect Google Tasks**. Sign-in lasts about an hour, as on the web; when it expires, tap **Reconnect** and you'll briefly bounce to Google and back.

---

## Updating Archie later

When you get a new version of `index.html`:

1. Paste your client ID into the new file's `CONFIG` section.
2. In the repository, click **Add file → Upload files**, drag in the new `index.html`, and **Commit changes**. It replaces the old one.
3. Wait a minute or two for GitHub to republish, then refresh the page. If you still see the old version, do a hard refresh: **Ctrl+Shift+R** on Windows, **Cmd+Shift+R** on Mac.

Your pet isn't affected by updates. It lives in your Google Drive, not in the file.

## Is this safe in a public repository?

Yes:

- **The client ID isn't a secret.** It's designed to sit in web pages where anyone can see it. Archie doesn't use a client secret at all.
- **Google only accepts sign-ins from the addresses you approved in step 5**, so another site can't reuse your client ID.
- **Visitors can't see your tasks or your pet.** Each visitor would have to sign in with their *own* Google account. While your Google app is in **Testing** mode, only the test users you listed can sign in at all.
- **The code itself is public,** so others could read or copy it. Nothing personal is in it as long as you don't add personal info to the file.

## Troubleshooting

| Problem | Fix |
|---|---|
| **404 at your Pages address** | Wait a few minutes after enabling Pages. Check that the file is named exactly `index.html` and is at the top level of the repository. |
| **`origin_mismatch` / `redirect_uri_mismatch` when signing in** | The address in step 5 doesn't match. It must be exactly `https://USERNAME.github.io`: `https`, no path, no trailing slash, with your username spelled the same. Wait a few minutes after saving. |
| **"Access blocked" or "app has not completed verification"** | Your Google account isn't on the test-user list. In the Google console, open **OAuth consent screen** (or **Google Auth Platform → Audience**) and add your email under **Test users**. |
| **"Add your Google OAuth client ID…" banner** | The uploaded `index.html` still has the placeholder. Paste your client ID into `CONFIG` and upload again. |
| **Banner about turning on the Google Drive API** | Enable **Google Drive API** in your Cloud project (README step 2), then click **Reconnect**. |
| **☁ label says "Saved in this browser only"** | Archie couldn't reach Drive just then. Changes are kept and upload on the next save. If it persists, click **Reconnect** and make sure the Drive permission is allowed. |
| **`redirect_uri_mismatch` on your phone** | Add your full Archie address (`https://USERNAME.github.io/archie/`, with the trailing slash) under **Authorized redirect URIs** on the Web client (step 7). |
| **Changes don't show up after uploading a new version** | Wait for GitHub to republish (watch the **Actions** tab for a green check), then hard-refresh. |

## Want a shorter address?

If you name the repository exactly `USERNAME.github.io` instead of `archie`, Archie lives at `https://USERNAME.github.io/` with no `/archie/` on the end. The origin you add in step 5 is the same either way.
