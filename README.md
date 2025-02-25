# 
```text
./sync [COMMIT MESSAGE] - pull + push
./run.sh [MODE] - server run script
./push.sh [SERVIP] [MEDIAIP] - server push script
./src - contents of a website
./nginx - NGINX config files
./baker/baker.sh - runs all ./baker contents
./baker/baker.py - finds each "stuff.<name>" and wraps contents with "dough.<name>", inserts all "insert.<name>" (from ./src/templates) and saves as "<name>"
./baker/lister.py - lists all directories with "index.html" and puts it in ./src/pages.txt
```
