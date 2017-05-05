# See bottom of file for default license and copyright information

package Foswiki::Plugins::WebPrefPlugin;

use strict;
use warnings;

use Foswiki::Func    ();    # The plugins API
use Foswiki::Plugins ();    # For the API version

our $VERSION = '1.0';
our $RELEASE = '1.0';

our $SHORTDESCRIPTION = 'Read WebPreferences.';

our $NO_PREFS_IN_TOPIC = 1;

sub initPlugin {
    my ( $topic, $web, $user, $installWeb ) = @_;

    # check for Plugins.pm versions
    if ( $Foswiki::Plugins::VERSION < 2.0 ) {
        Foswiki::Func::writeWarning( 'Version mismatch between ',
            __PACKAGE__, ' and Plugins.pm' );
        return 0;
    }

    Foswiki::Func::registerTagHandler(
        'WEBPREF', \&_WEBPREF );
    Foswiki::Func::registerTagHandler(
        'WEBMATCHPREF', \&_WEBMATCHPREF );
    # Plugin correctly initialized
    return 1;
}

sub _WEBPREF {
    my ( $session, $attributes, $topic, $web ) = @_;

    $web = $attributes->{web} if $attributes->{web};

    if($attributes->{l}) {
        for(my $level = 0; $level < $attributes->{l}; $level++) {
            unless ($web =~ s#/[^/]*$##) {
                $web = 'dummy';
                last;
            }
        }
    }

    my $val = Foswiki::Func::getPreferencesValue($attributes->{_DEFAULT}, $web);
    return $val if defined $val;
    return Foswiki::Func::decodeFormatTokens($attributes->{alt} || '');
}

sub _WEBMATCHPREF {
    my ( $session, $attributes, $topic, $web ) = @_;

    my $subweb = $attributes->{web} || '';
    my $exclude = $attributes->{exclude} || '(Trash|Tasks|Custom|Sandbox|System)';
    my $include = $attributes->{include} if $attributes->{include};
    my $expand = $attributes->{expand} || 1;
    my $separator = $attributes->{separator} || ',';

    if($attributes->{l}) {
        for(my $level = 0; $level < $attributes->{l}; $level++) {
            unless ($web =~ s#/[^/]*$##) {
                $web = 'dummy';
                last;
            }
        }
    }

    my @webs;
    my @owebs;
    @webs = Foswiki::Func::getListOfWebs("user",$subweb);
    @webs = grep {!/$exclude/} @webs if $exclude;
    @webs = grep {/$include/} @webs if $include;
    foreach my $web (@webs) {
        Foswiki::Func::pushTopicContext($web,'WebPreferences');
        my $webPref = Foswiki::Func::getPreferencesValue($attributes->{_DEFAULT});
        if($expand) {
            $webPref = Foswiki::Func::expandCommonVariables($webPref);
        }
        Foswiki::Func::popTopicContext();
        if ( !$attributes->{value} || $webPref =~ m/$attributes->{value}/ ) {
            push @owebs, $web;
        }
    }
    return join($separator, @owebs);
}

sub maintenanceHandler {
    Foswiki::Plugins::MaintenancePlugin::registerCheck("WebPrefPlugin:pluginorder", {
        name => "WebPrefPlugin in PluginsOrder",
        description => "WebPrefPlugin should be in {PluginsOrder} before KVPPlugin.",
        check => sub {
            return { result => 0 } unless $Foswiki::cfg{Plugins}{KVPPlugin}{Enabled};

            unless($Foswiki::cfg{PluginsOrder} =~ m#\bWebPrefPlugin\b.*\bKVPPlugin\b#) {
                my $suggestion = $Foswiki::cfg{PluginsOrder};
                $suggestion =~ s#,\s*WebPrefPlugin\b\s*##g;
                $suggestion =~ s#^\s*WebPrefPlugin\s*,##;
                unless($suggestion =~ s#\bKVPPlugin\b#WebPrefPlugin,KVPPlugin#) {
                    $suggestion .= ",WebPrefPlugin";
                }
                return {
                    result => 1,
                    priority => $Foswiki::Plugins::MaintenancePlugin::WARN,
                    solution => "Add WebPrefPlugin to {PluginsOrder} before KVPPlugin in configure:<br /> =\$Foswiki::cfg{PluginsOrder}= = =$suggestion="
                }
            } else {
                return { result => 0 };
            }
        }
    });
}

1;

__END__
Foswiki - The Free and Open Source Wiki, http://foswiki.org/

Copyright (C) 2008-2014 Foswiki Contributors. Foswiki Contributors
are listed in the AUTHORS file in the root of this distribution.
NOTE: Please extend that file, not this notice.

This program is free software; you can redistribute it and/or
modify it under the terms of the GNU General Public License
as published by the Free Software Foundation; either version 2
of the License, or (at your option) any later version. For
more details read LICENSE in the root of this distribution.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.

As per the GPL, removal of this notice is prohibited.
