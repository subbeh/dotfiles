#!/bin/sh

# 'base16' draws from the terminal's ANSI palette (color0-15), which kitty sets
# from the same theme vars, so highlighting follows the theme without shipping a
# .tmTheme and rebuilding bat's cache
export BAT_THEME="base16"
