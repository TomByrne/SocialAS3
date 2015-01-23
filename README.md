SocialAS3
=========

An AS3 library for connecting to various social media platforms and standardising returned info.

Currently supported (API coverage):
====================

- Instagram (90%)
- Dropbox (90%)
- Facebook (40%)

Also includes integration for existing these Single Sign On Native Extensions:
========================================================================

- FreshPlanet (https://github.com/freshplanet/ANE-Facebook)
- Distriqt (http://distriqt.com/product/air-native-extensions/facebookapi)


To Build SWC
============

- Download ANEs for 2 external libraries, copy to libs folder
- Copy these two ANEs to the build/lib folder and change extension to 'swc'
- Run 'build' task in build/build.xml ANT file

Note about FreshPlanet usage
===========
If you're having packaging issues using the FreshPlanet ANE, it means they haven't merged our pull request.

Try the ANE found here:

*https://github.com/WhitechDev/ANE-Facebook/tree/feature/use-facebook-sdk-properly*

