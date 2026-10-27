# Archie for Mac: the desktop widget

A small Mac app that shows Archie as a floating, device-shaped widget with no window frame. Click the device to open the tasks panel. It uses the same `index.html` as the website. The app only supplies the see-through window, plus Google sign-in through Apple's secure sign-in sheet.

## What you need

- macOS 12 (Monterey) or newer
- Apple's Command Line Tools. Install them once by running this in Terminal, then click **Install** when asked:

  ```
  xcode-select --install
  ```

  You do **not** need the full Xcode app.

## Folder layout

Keep the `mac` folder next to `index.html`:

```
archie/
  index.html
  mac/
    build.sh
    Info.plist
    Sources/…
```

## Build it

In Terminal:

```
cd path/to/archie/mac
chmod +x build.sh
./build.sh
```

That creates `mac/build/Archie.app`. Drag it into **Applications**. The first time, **right-click it and choose Open**, because macOS warns about apps that weren't downloaded from the App Store.

Built this way, the app runs in demo mode. Google Tasks sync needs one extra step, below.

## Turn on Google Tasks sync (one-time)

Google doesn't allow sign-in inside embedded web pages, so the app signs in with Apple's secure sign-in sheet. That needs its own client ID, of the **iOS** type. Create it in the same Google Cloud project as your website's client ID.

1. Go to Google Cloud Console → **APIs & Services → Credentials → Create credentials → OAuth client ID**.
2. Application type: **iOS**. Bundle ID: `com.archie.widget`. If you'd rather use your own ID, build with `BUNDLE_ID=com.you.archie ./build.sh …`, and the two must match.
3. Copy the client ID it gives you. It ends in `.apps.googleusercontent.com`.
4. Rebuild with it:

   ```
   ./build.sh 1234567890-abcdef.apps.googleusercontent.com
   ```

5. Open the app and click **Connect Google Tasks**. After you sign in once, the app remembers you in your Mac's Keychain and reconnects on its own. No more hourly "Reconnect" banner.

The Google Tasks API and Google Drive API must be turned on in that project. They already are if your website syncs.

## Using it

- **Move it:** drag the shell, anywhere that isn't a button or the screen.
- **Open the panel:** click the device. The A/B/C buttons and the screen come alive, and the tasks panel slides out on the right.
- **Close the panel:** × or Esc. **Full view** switches to the complete page, including the Recurring card and Log. In full view, drag by the header.
- **Menu bar (Archie menu):**
  - **Keep on Top** (⌘T): float above other windows.
  - **Set Page Address…**: load your published site instead of the copy inside the app (see below).
  - **Use Built-in Page**: switch back to the copy inside the app.
  - **Reload** (⌘R)
  - **Sign Out of Google**
- **Open at login:** System Settings → General → Login Items → add Archie.

## Updating the app after you publish to GitHub Pages

You don't need to rebuild for design or feature changes:

1. Choose **Archie → Set Page Address…** and paste your GitHub Pages address, for example `https://yourname.github.io/archie/`.
2. From then on the widget loads the live site. Publish an update, choose **Reload** (or relaunch), and the widget has it.

You only rebuild (`./build.sh …`) if the Swift files change, or if you want to refresh the built-in copy.

**About your pet's save:** each page address keeps its own copy of the pet in the app. If you're signed in to Google, the Drive cloud save carries your pet across, so switching addresses picks up where you left off. In demo mode, a switched address starts a fresh pet.

## If something's off

- **"Swift isn't installed"**: run `xcode-select --install` and try again.
- **The app won't open ("unidentified developer")**: right-click → Open, or System Settings → Privacy & Security → **Open Anyway**.
- **Sign-in says the client is invalid**: check that the client ID is the iOS type and that its bundle ID matches the one you built with.
- **Google sync fails only on the built-in page**: use **Set Page Address…** with your published site. Some Google services are picky about requests from pages that aren't on a normal web address.
