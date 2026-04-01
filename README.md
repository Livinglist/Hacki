# <img width="64" src="https://user-images.githubusercontent.com/7277662/167775086-0b234f28-dee4-44f6-aae4-14a28ed4bbb6.png"> Hacki for Hacker News

A [Hacker News](https://news.ycombinator.com/) client built with Flutter.

[![App Store](https://img.shields.io/itunes/v/1602043763?label=App%20Store&logo=appstore)](https://apps.apple.com/us/app/hacki/id1602043763?platform=iphone)
[![Google Play](https://img.shields.io/endpoint?color=green&logo=googleplay&logoColor=green&url=https%3A%2F%2Fplay.cuzi.workers.dev%2Fplay%3Fi%3Dcom.jiaqifeng.hacki%26gl%3DUS%26hl%3Den%26l%3DGoogle%2520Play%26m%3D%24version)](https://play.google.com/store/apps/details?id=com.jiaqifeng.hacki&hl=en_US&gl=US&pli=1)
[![Fdroid version](https://img.shields.io/f-droid/v/com.jiaqifeng.hacki?logo=fdroid)](https://f-droid.org/en/packages/com.jiaqifeng.hacki/)
[![GH version](https://img.shields.io/github/release/livinglist/hacki.svg?logo=github)](https://github.com/Livinglist/Hacki/releases/latest)
[![GitHub](https://img.shields.io/github/stars/livinglist/hacki)](https://github.com/Livinglist/Hacki)

[![Publish (iOS)](https://github.com/Livinglist/Hacki/actions/workflows/publish_ios.yml/badge.svg?branch=master)](https://github.com/Livinglist/Hacki/actions/workflows/publish_ios.yml)
[![Build Android APK](https://github.com/Livinglist/Hacki/actions/workflows/build_android_apk.yml/badge.svg?branch=master)](https://github.com/Livinglist/Hacki/actions/workflows/build_android_apk.yml)
[![Parser Check](https://github.com/Livinglist/Hacki/actions/workflows/parser_check.yml/badge.svg?branch=master)](https://github.com/Livinglist/Hacki/actions/workflows/parser_check.yml)

[<img src="assets/images/app_store_badge.png" height="50">](https://apps.apple.com/us/app/hacki/id1602043763?platform=iphone) [<img src="assets/images/google_play_badge.png" height="50">](https://play.google.com/store/apps/details?id=com.jiaqifeng.hacki&hl=en_US&gl=US) [<img src="assets/images/f_droid_badge.png" height="50">](https://f-droid.org/en/packages/com.jiaqifeng.hacki/)

# Features
- Hacker News account [login](#login-reply-notification-favorites-sync-and-more)
- [Favorites sync](#login-reply-notification-favorites-sync-and-more)
- [Hacker News Search](#hacker-news-search)
- [In-thread search](#in-thread-local-and-global-search)
- [Ancestor lookup](#ancestor-lookup) so you don't have to scroll back up to regain context
- [In-thread notification for new comments](#new-comments-notification-and-lookup) since your last visit
- [In-app notification for new replies](#login-reply-notification-favorites-sync-and-more) to your comments or stories
- [Offline mode](#settings)
- Synced settings across devices (iOS only)
- [Favorites import and export](#settings)
- Open Hacker News link in Hacki via system share dialog
- [Share story or comment as image](#share-story-or-comment-as-image)
- [Reply](#reply-to-comment-or-story), vote, filter, block
- [Polls](#polls)
- [True dark mode](#true-dark-mode)
- [Tablet support](#tablet-support)
- [Accent color](#thread) and [font customization](#accent-color-and-font-customization)
- And more...

## Home page and story tile customization
<p align="center">
    <img width="200" src="assets/new_screenshots/hacki_01.png">
    <img width="200" src="assets/new_screenshots/hacki_04.png">
    <img width="200" src="assets/new_screenshots/hacki_05.png"> 
    <img width="200" src="assets/new_screenshots/hacki_08.png"> 
    <img width="200" src="assets/new_screenshots/hacki_02.png"> 
    <img width="200" src="assets/new_screenshots/hacki_03.png">
    <img width="200" src="assets/new_screenshots/hacki_06.png">
    <img width="200" src="assets/new_screenshots/hacki_07.png">
    <img width="200" src="assets/new_screenshots/hacki_09.png">
    <img width="200" src="assets/new_screenshots/hacki_10.png"> 
    <img width="200" src="assets/new_screenshots/hacki_11.png"> 
    <img width="200" src="assets/new_screenshots/hacki_12.png">
</p>

## Thread
<p align="center">
    <img width="200" src="assets/new_screenshots/hacki_21.png"> 
    <img width="200" src="assets/new_screenshots/hacki_70.png">
    <img width="200" src="assets/new_screenshots/hacki_22.png"> 
    <img width="200" src="assets/new_screenshots/hacki_69.png">
</p>

## New comments notification and lookup
<p align="center">
    <img width="300" src="assets/new_screenshots/hacki_59.png"> 
    <img width="300" src="assets/new_screenshots/hacki_60.png">
</p>

## In-thread local and global search
<p align="center">
    <img width="250" src="assets/new_screenshots/hacki_91.png">
    <img width="250" src="assets/new_screenshots/hacki_93.png">
    <img width="250" src="assets/new_screenshots/hacki_95.png">
    <img width="250" src="assets/new_screenshots/hacki_101.png">
    <img width="250" src="assets/new_screenshots/hacki_97.png">
    <img width="250" src="assets/new_screenshots/hacki_99.png">
</p>
<p align="center">
    <img width="250" src="assets/new_screenshots/hacki_92.png">
    <img width="250" src="assets/new_screenshots/hacki_94.png">
    <img width="250" src="assets/new_screenshots/hacki_96.png">
    <img width="250" src="assets/new_screenshots/hacki_102.png">
    <img width="250" src="assets/new_screenshots/hacki_98.png">
    <img width="250" src="assets/new_screenshots/hacki_100.png">
</p>

## Ancestor lookup
<p align="center">
    <img width="200" src="assets/new_screenshots/hacki_61.png">
    <img width="200" src="assets/new_screenshots/hacki_64.png">
    <img width="200" src="assets/new_screenshots/hacki_65.png">
    <img width="200" src="assets/new_screenshots/hacki_68.png">
</p>
<p align="center">
    <img width="200" src="assets/new_screenshots/hacki_62.png">
    <img width="200" src="assets/new_screenshots/hacki_63.png">
    <img width="200" src="assets/new_screenshots/hacki_66.png">
    <img width="200" src="assets/new_screenshots/hacki_67.png">
</p>

## Share story or comment as image
<p align="center">
    <img width="250" src="assets/new_screenshots/hacki_103.png">
    <img width="250" src="assets/new_screenshots/hacki_105.png">
    <img width="250" src="assets/new_screenshots/hacki_107.png">
    <img width="250" src="assets/new_screenshots/hacki_109.png">
    <img width="250" src="assets/new_screenshots/hacki_111.png">
    <img width="250" src="assets/new_screenshots/hacki_113.png">
</p>

<p align="center">
    <img width="250" src="assets/new_screenshots/hacki_104.png">
    <img width="250" src="assets/new_screenshots/hacki_106.png">
    <img width="250" src="assets/new_screenshots/hacki_108.png">
    <img width="250" src="assets/new_screenshots/hacki_110.png">
    <img width="250" src="assets/new_screenshots/hacki_112.png">
    <img width="250" src="assets/new_screenshots/hacki_114.png">
</p>

## Reply to comment or story
<p align="center">
    <img width="200" src="assets/new_screenshots/hacki_115.png">
    <img width="200" src="assets/new_screenshots/hacki_117.png">
    <img width="200" src="assets/new_screenshots/hacki_119.png">
    <img width="200" src="assets/new_screenshots/hacki_121.png">
</p>
<p align="center">
    <img width="200" src="assets/new_screenshots/hacki_116.png">
    <img width="200" src="assets/new_screenshots/hacki_118.png">
    <img width="200" src="assets/new_screenshots/hacki_120.png">
    <img width="200" src="assets/new_screenshots/hacki_122.png">
</p>

## Open comment in separate thread
<p align="center">
    <img width="200" src="assets/new_screenshots/hacki_135.png">
    <img width="200" src="assets/new_screenshots/hacki_137.png">
    <img width="200" src="assets/new_screenshots/hacki_139.png">
    <img width="200" src="assets/new_screenshots/hacki_141.png">
</p>
<p align="center">
    <img width="200" src="assets/new_screenshots/hacki_136.png">
    <img width="200" src="assets/new_screenshots/hacki_138.png">
    <img width="200" src="assets/new_screenshots/hacki_140.png">
    <img width="200" src="assets/new_screenshots/hacki_142.png">
</p>

# Hacker News search
<p align="center">
    <img width="250" src="assets/new_screenshots/hacki_129.png">
    <img width="250" src="assets/new_screenshots/hacki_131.png">
    <img width="250" src="assets/new_screenshots/hacki_133.png">
</p>
<p align="center">
    <img width="250" src="assets/new_screenshots/hacki_130.png">
    <img width="250" src="assets/new_screenshots/hacki_132.png">
    <img width="250" src="assets/new_screenshots/hacki_134.png">
</p>

# Login, reply notification, favorites sync and more
<p align="center">
    <img width="250" src="assets/new_screenshots/hacki_37.png">
    <img width="250" src="assets/new_screenshots/hacki_39.png">
    <img width="250" src="assets/new_screenshots/hacki_47.png">
</p>
<p align="center">
    <img width="250" src="assets/new_screenshots/hacki_38.png">
    <img width="250" src="assets/new_screenshots/hacki_40.png">
    <img width="250" src="assets/new_screenshots/hacki_48.png">
</p>

# Settings
<p align="center">
    <img width="200" src="assets/new_screenshots/hacki_71.png">
    <img width="200" src="assets/new_screenshots/hacki_74.png">
    <img width="200" src="assets/new_screenshots/hacki_75.png">
    <img width="200" src="assets/new_screenshots/hacki_78.png">
</p>

<p align="center">
    <img width="200" src="assets/new_screenshots/hacki_72.png">
    <img width="200" src="assets/new_screenshots/hacki_73.png">
    <img width="200" src="assets/new_screenshots/hacki_76.png">
    <img width="200" src="assets/new_screenshots/hacki_77.png">
</p>

# Accent color and font customization
<p align="center">
    <img width="200" src="assets/new_screenshots/hacki_79.png">
    <img width="200" src="assets/new_screenshots/hacki_80.png">
    <img width="200" src="assets/new_screenshots/hacki_81.png">
    <img width="200" src="assets/new_screenshots/hacki_82.png">
</p>

# True dark mode
<p align="center">
    <img width="200" src="assets/new_screenshots/hacki_143.png">
    <img width="200" src="assets/new_screenshots/hacki_145.png">
    <img width="200" src="assets/new_screenshots/hacki_144.png">
    <img width="200" src="assets/new_screenshots/hacki_146.png">
</p>

# Polls
<p align="center">
    <img width="200" src="assets/new_screenshots/hacki_147.png">
    <img width="200" src="assets/new_screenshots/hacki_148.png">
    <img width="200" src="assets/new_screenshots/hacki_149.png">
    <img width="200" src="assets/new_screenshots/hacki_150.png">
</p>

# Tablet support
<p align="center">
   <img width="400" alt="ipad-01" src="assets/screenshots/selected/hacki_tablet_01.png"> 
   <img width="400" alt="ipad-02" src="assets/screenshots/selected/hacki_tablet_02.png"> 
   <img width="400" alt="ipad-03" src="assets/screenshots/selected/hacki_tablet_03.png"> 
   <img width="400" alt="ipad-04" src="assets/screenshots/selected/hacki_tablet_04.png"> 
</p>
