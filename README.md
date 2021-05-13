# Bot Gloves

![Downloads](https://img.shields.io/github/downloads/zer0k-z/bot-gloves/total?style=flat-square) ![Last commit](https://img.shields.io/github/last-commit/zer0k-z/bot-gloves?style=flat-square) ![Open issues](https://img.shields.io/github/issues/zer0k-z/bot-gloves?style=flat-square) ![Closed issues](https://img.shields.io/github/issues-closed/zer0k-z/bot-gloves?style=flat-square) ![Size](https://img.shields.io/github/repo-size/zer0k-z/bot-gloves?style=flat-square) ![GitHub Workflow Status](https://img.shields.io/github/workflow/status/zer0k-z/bot-gloves/Compile%20with%20SourceMod?style=flat-square)

## Description ##
Add gloves to bots. This is a stripped down version of [kgn's gloves plugin](https://github.com/kgns/gloves), but is modified to work with bots instead.

This was made for GOKZ bots so video editors can change bot's gloves to ones that are used by players. 
*Sidenote: GOKZ bots currently have broken models now.*

**Warning**: This can get your server blacklisted or your GSLT token banned, it is recommended to use in LAN settings only.

## Installation ##
1. Grab the latest release from the release page and unzip it in your sourcemod folder.
2. Restart the server or type `sm plugins load bot-gloves` in the console to load the plugin.

## Usage ##
- ``!botglove``/``!botgloves`` - Set gloves for bots
- ``!botgloves_float <value>`` - Set float value for bots' gloves
- ``!botgloves_worldmodel`` - Toggle world model visibility for bots' gloves

Bots need to respawn for the new gloves to take effect.

