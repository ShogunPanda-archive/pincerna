# pincerna

[![Gem Version](https://badge.fury.io/rb/pincerna.png)](http://badge.fury.io/rb/pincerna)
[![Dependency Status](https://gemnasium.com/ShogunPanda/pincerna.png?travis)](https://gemnasium.com/ShogunPanda/pincerna)
[![Build Status](https://secure.travis-ci.org/ShogunPanda/pincerna.png?branch=master)](https://travis-ci.org/ShogunPanda/pincerna)
[![Code Climate](https://codeclimate.com/github/ShogunPanda/pincerna.png)](https://codeclimate.com/github/ShogunPanda/pincerna)
[![Coverage Status](https://coveralls.io/repos/ShogunPanda/pincerna/badge.png)](https://coveralls.io/r/ShogunPanda/pincerna)

A bunch of useful Alfred 2 workflows.

http://sw.cow.tc/pincerna

http://rdoc.info/gems/pincerna

## Installation

### Preparation of the environment

#### Users of MacOSX Mavericks

On OSX Mountain Lion (10.9), the default Ruby version is 2.0.0, so no additional steps are required.

#### Users of MacOSX Mountain Lion and older

On OSX Mountain Lion (10.8) and older, the default Ruby version is 1.8.7.

This version is really older and no longer maintained. Pincerna requires at least Ruby 1.9 and works on 2.0 too.

The scripts support using [rvm](https://rvm.io/) for loading a new Ruby version. To install, check its documentation. In short, it should resolv to these steps:

    \curl -L https://get.rvm.io | sudo bash -s stable
    rvm install [1.9.3|2.0.0]
    rvm use [1.9.3|2.0.0] --default

### Installation of the gem and the workflow

    gem i pincerna
    pincerna install

## Uninstallation

    pincerna uninstall
    pincerna quit
    gem uni pincerna

## Usage

Pincerna supports many shortcut which will save your work. Here's the comprehensive list.

### Unit conversion

Thanks to the [ruby-units](http://github.com/olbrich/ruby-units) gem, you can convert values between units.

The recognized syntaxes are:

* `convert 123 $FROM_UNIT to $TO_UNIT`
* `c 123.45 $FROM_UNIT to $TO_UNIT`

`to` can be omitted. Actioning on the result will copy the result to the clipboard.

If `with rate` is appended, also the conversion rate will be copied as well.

If `split units` is appended, the value in feet will be shown in `X ft Y in` form, pounds (lbs) or ounces (oz) will be shown in `X lbs Y oz` form.

Examples:

  * `convert 123.45 m to m`
  * `c 123 kg oz with rate split units`

### Currency conversion

Thanks to the [rate-exchange API](http://rate-exchange.appspot.com/), you can convert values between currencies.

The recognized syntaxes are:

* `currency 123 $FROM_CURRENCY to $TO_CURRENCY`
* `cc 123.45 $FROM_CURRENCY to $TO_CURRENCY`

`to` can be omitted. Actioning on the result will copy the result to the clipboard.

If `with rate` is appended, also the conversion rate will be copied as well.

Examples:

  * `currency 123.45 EUR to USD`
  * `cc 123 EUR JPY with rate`
  * `cc 123 € $ with rate`

### Translation with Google Translate

You can translate words or sentences between languages using [Google Translate](http://translate.google.com/).

The recognized syntax is:

* `translate $FROM_LANGUAGE to $TO_LANGUAGE $TEXT`
* `t $FROM_LANGUAGE to $TO_LANGUAGE $TEXT`

`to` can be omitted. Actioning on the result will copy the first result to the clipboard.

`$FROM_LANGUAGE` can also be omitted as well, will default to `en`.

Examples:

  * `translate it to en Ciao mondo`
  * `t it en Ciao mondo`
  * `t it Hello`

### View location in Google Maps

You can view locations on [Google Maps](http://maps.google.com).

The recognized syntax is:

* `map $LOCATION`
* `m $LOCATION`

Actioning on the result will open the location in Google Maps on the default browser.

Examples:

  * `map Campobasso, Italy`
  * `m San Mateo, CA`
  * `m 12.34,56.78`

### Yahoo! Weather Forecast

You can view the current weather condition and tomorrow's forecast on [Yahoo! Weather](http://weather.yahoo.com).

The recognized syntax is:

* `forecast $LOCATION`

The location can be a name or a WOEID. Actioning on the result will open the forecast in Yahoo! Weather on the default browser.

Examples:

  * `forecast San Mateo`
  * `forecast 2406170`

### Fetch the list of local and public IP

You can view the list of all IP address of the current machine, including the public IP (thanks to [exip.org](http://exip.org)). Both IPv4 and IPv6 are supported.

The recognized syntax is:

* `ip $INTERFACE`

`$INTERFACE` is optional and it is only used to filter results (use `public` to get only the public IP).

Actioning on the results will copy the IP on the clipboard.

Examples:

  * `ip`
  * `ip Ethernet`
  * `ip lo0`
  * `ip public`

### Connect or disconnect from VPNs

You can connect or disconnect from your VPNs.

The recognized syntax is:

* `vpn $NAME`

`$NAME` is optional and it is only used to filter results.

Examples:

  * `vpn`
  * `vpn Office`

### Open Chrome, Firefox or Safari bookmarks

You can search and open your Chrome, Firefox or Safari bookmarks and open in the respective browsers.

The recognized syntax is:

* `bc $NAME` for Chrome
* `bs $NAME` for Safari
* `bf $NAME` for Firefox

`$NAME` is optional and it is only used to filter results.

Examples:

  * `bc Google`
  * `bf Google`
  * `bs Google`

Actioning on the results will open the bookmark in the browser. Note that this won't use the default browser but the one the bookmarks belongs to.

## Contributing to pincerna
 
* Check out the latest master to make sure the feature hasn't been implemented or the bug hasn't been fixed yet.
* Check out the issue tracker to make sure someone already hasn't requested it and/or contributed it.
* Fork the project.
* Start a feature/bugfix branch.
* Commit and push until you are happy with your contribution.
* Make sure to add tests for it. This is important so I don't break it in a future version unintentionally.
* Please try not to mess with the Rakefile, version, or history. If you want to have your own version, or is otherwise necessary, that is fine, but please isolate to its own commit so I can cherry-pick around it.

## Copyright

Copyright (C) 2013 and above Shogun (shogun@cowtech.it).

Licensed under the MIT license, which can be found at http://www.opensource.org/licenses/mit-license.php.

The icons used are by the [Cold Fusion HD set](http://chrisbanks2.deviantart.com/art/Cold-Fusion-HD-Icon-Pack-277808597) by *chrisbanks2*.