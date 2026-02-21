# Wingpanel Power Indicator
[![Translation status](https://l10n.elementaryos.org/widget/wingpanel/power/svg-badge.svg)](https://l10n.elementaryos.org/engage/wingpanel/)
![Screenshot](data/screenshot.png?raw=true)

## Building and Installation

You'll need the following dependencies:

* libgranite-7-dev
* libgtop2-dev
* libudev-dev
* libwingpanel-9-dev
* libnotify-dev
* meson >= 0.58.0
* valac

Run `meson` to configure the build environment and then `ninja` to build

    meson build --prefix=/usr
    cd build
    ninja

To install, use `ninja install`

    sudo ninja install
