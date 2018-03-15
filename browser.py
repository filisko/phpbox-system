#!/usr/bin/env python
#
# PHP Box v1.0
#
# Copyright (C) 2018 Filis Futsarov
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License
# as published by the Free Software Foundation; either version 2
# of the License, or (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

import argparse
import sys
import signal
import gi
gi.require_version('Gtk', '3.0')
gi.require_version('Gdk', '3.0')
gi.require_version('WebKit', '3.0')

from gi.repository import Gtk as gtk
from gi.repository import Gdk
from gi.repository import GLib as glib
from gi.repository import WebKit as webkit

def str2bool(v):
    if v.lower() in ('yes', 'true', 't', 'y', '1'):
        return True
    elif v.lower() in ('no', 'false', 'f', 'n', '0'):
        return False
    else:
        raise argparse.ArgumentTypeError('Boolean value expected.')

class Browser:
    def __init__(self):
        parser = argparse.ArgumentParser()
        parser.add_argument("--title", type=str, help="set window title", default='App title')
        parser.add_argument("--url", type=str, help="set webview URL", default='http://example.com')
        parser.add_argument("--width", type=int, help="set window width", default=600)
        parser.add_argument("--height", type=int, help="set window height", default=400)
        parser.add_argument("--fullscreen", type=str2bool, help="start the window in fullscreen mode", default=False)
        parser.add_argument("--resizable", type=str2bool, help="whether the window is resizable or not", default=False)
        parser.add_argument("--maximized", type=str2bool, help="start the window maximized", default=False)
        parser.add_argument("--icon", type=str, help="window icon relative path", default=None)

        args = parser.parse_args()

        self.window = gtk.Window()
        self.window.connect("destroy", self.destroy)

        if args.icon is not None and args.icon is not '':
            self.window.set_icon_from_file(args.icon)

        self.window.set_title(args.title)
        self.window.set_resizable(args.resizable)
        self.window.set_size_request(args.width, args.height)
        self.window.set_position(gtk.WindowPosition.CENTER)

        self.web_view = webkit.WebView()
        self.web_view.props.settings.props.enable_default_context_menu = False
        self.web_view.open(args.url)

        scroll_window = gtk.ScrolledWindow(None, None)
        # scroll_window.set_policy(gtk.POLICY_NEVER, gtk.POLICY_NEVER)
        # scroll_window.set_placement(gtk.CORNER_TOP_LEFT)
        scroll_window.add(self.web_view)
        box = gtk.VBox(False, 0)
        box.add(scroll_window)
        self.window.add(box)

        if args.maximized:
            self.window.maximize()

        if args.fullscreen:
            self.window.fullscreen()

        self.window.show_all()

    def destroy(self, widget, data=None):
        gtk.main_quit()

    def main(self):
        gtk.main()

if __name__ == "__main__":
    browser = Browser()
    # Exit on SIGINT
    glib.unix_signal_add(glib.PRIORITY_DEFAULT, signal.SIGINT, gtk.main_quit)
    browser.main()
