#!/usr/bin/python3

# This program makes lists of different types
# of pages for frontend navigation

import os

DIR = './src'

if __name__ == '__main__':
    urilist = ''
    for root, dirs, files in os.walk(DIR):
        if 'index.html' in files:
            print(root)
            urilist += root[5:]+'\n'
    f = open(f'{DIR}/static_data/listed-pages-all.txt', 'w', encoding='utf-8')
    f.write(urilist.strip())
    f.close()
