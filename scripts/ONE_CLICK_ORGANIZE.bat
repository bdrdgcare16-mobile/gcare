@echo off
echo Moving all files to organized folders...
move *.md docs\ 2>nul
move *.bat scripts\ 2>nul
move *.js tools\ 2>nul
move *.ps1 tools\ 2>nul
echo Done! Files organized.
pause 