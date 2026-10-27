import Cocoa

/// Builds the menu bar. The Edit menu matters: without it, ⌘C / ⌘V / ⌘A don't work in the page's text boxes.
enum MenuBuilder {
    static func build(target: AppDelegate, keepOnTop: Bool) -> NSMenu {
        let main = NSMenu()

        let app = NSMenu(title: "Archie")
        app.addItem(withTitle: "About Archie", action: #selector(NSApplication.orderFrontStandardAboutPanel(_:)), keyEquivalent: "")
        app.addItem(.separator())
        let top = item("Keep on Top", #selector(AppDelegate.toggleKeepOnTop(_:)), "t", target)
        top.state = keepOnTop ? .on : .off
        app.addItem(top)
        app.addItem(item("Set Page Address…", #selector(AppDelegate.setPageAddress(_:)), "", target))
        app.addItem(item("Use Built-in Page", #selector(AppDelegate.useBuiltInPage(_:)), "", target))
        app.addItem(item("Reload", #selector(AppDelegate.reloadPage(_:)), "r", target))
        app.addItem(.separator())
        app.addItem(item("Sign Out of Google", #selector(AppDelegate.signOutOfGoogle(_:)), "", target))
        app.addItem(.separator())
        app.addItem(withTitle: "Hide Archie", action: #selector(NSApplication.hide(_:)), keyEquivalent: "h")
        app.addItem(withTitle: "Quit Archie", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q")
        attach(app, to: main)

        let edit = NSMenu(title: "Edit")
        edit.addItem(withTitle: "Undo", action: Selector(("undo:")), keyEquivalent: "z")
        edit.addItem(withTitle: "Redo", action: Selector(("redo:")), keyEquivalent: "Z")
        edit.addItem(.separator())
        edit.addItem(withTitle: "Cut", action: #selector(NSText.cut(_:)), keyEquivalent: "x")
        edit.addItem(withTitle: "Copy", action: #selector(NSText.copy(_:)), keyEquivalent: "c")
        edit.addItem(withTitle: "Paste", action: #selector(NSText.paste(_:)), keyEquivalent: "v")
        edit.addItem(withTitle: "Select All", action: #selector(NSText.selectAll(_:)), keyEquivalent: "a")
        attach(edit, to: main)

        return main
    }

    private static func item(_ title: String, _ action: Selector, _ key: String, _ target: AnyObject) -> NSMenuItem {
        let item = NSMenuItem(title: title, action: action, keyEquivalent: key)
        item.target = target
        return item
    }

    private static func attach(_ menu: NSMenu, to main: NSMenu) {
        let holder = NSMenuItem()
        holder.submenu = menu
        main.addItem(holder)
    }
}
