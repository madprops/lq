script -c 'lq --help' -q help.tscript
cat help.tscript | sed '1d;$d' | aha --title lq > docs/index.html
rm help.tscript