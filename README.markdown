# RDProgressHUD

A lightweight progress view for iOS apps. Its public API is meant to be similar to the private UIProgressHUD, and thus is also similar to other reimplementations of that API (e.g. [MBProgressHUD](https://github.com/jdg/MBProgressHUD)).

So why create another HUD? Three reasons:

1. Many of those other implementations have features that we don't need, so there's no need to include all of that code.
2. Baking in a simple API to switch from indeterminate progress to a success or failure indicator at the end of a process, as well as providing some canned images. 
3. It's good exercise!

## Usage

To use this view in your own apps, just add `RDProgressHUD.h`, `RDProgressHUD.m`, and `RDProgressHUD.bundle` to your project in Xcode, and update your documentation as instructed by the license.

While this class will probably work in older setups, we assume iOS 7+, and ARC.

Use `-showInView:` to display the view (typically, passing the window) and `-hide` to dismiss it.

If you want to replace the indefinite progress with an indicator, call `-done` (which assumes success) or `-done:` (which takes a Boolean). Either will automatically call `-hide` after the `doneVisibleDuration`.

Some day, this class may get a simple delegate protocol and/or more convenience methods, but for right now it's your responsibility to keep track of the HUD view, and manage it appropriately.
