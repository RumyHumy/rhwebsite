#!/usr/bin/python3

import os

DIR = './src'
TEMPL = f'{DIR}/templates'

# Loads text with check to ensure predictablity
def LoadText(fpath, typ):
    if not os.path.isfile(fpath):
        print(f'[ERR] No corresponding "{typ}" file')
        exit(1)
    f = open(fpath, 'r', encoding='utf-8')
    contents = f.read()
    f.close()
    return contents

def Insert(contents, pre, src):
    #print(f'    -> inserting: {pre}')
    ent = contents.split(f'@{pre}')
    for i in range(1, len(ent)):
        ent[i] = ent[i].split('@', 1)
        if len(ent[i]) != 2:
            print('[ERR] Unclosed "@"')
            exit(1)
        fname = f'{src}/{pre}{ent[i][0]}'
        print(f'    loading: "{fname}"')
        ent[i][0] = LoadText(fname, f"{pre}*").strip()
        ent[i] = ''.join(ent[i])
    s = ''.join(ent)
    return s[:len(s)-1]

def BakeEntry(root, files, fname):
    # Extract name
    name = fname[len('stuff.'):]
    print(f'    {fname} -> {name}')
    if len(name) == 0:
        print('[ERR] No stuff name provided')
        exit(1)
    # Loading text from dough file
    contents = LoadText(f'{TEMPL}/dough.{name}', 'dough.*')
    outname = name
    contents = Insert(contents, 'stuff.', root)
    contents = Insert(contents, 'other.', root)
    contents = Insert(contents, 'insert.', TEMPL)
    f = open(f'{root}/{outname}', 'w', encoding='utf-8')
    f.write(contents)
    f.close()

if __name__ == '__main__':
    for root, dirs, files in os.walk(DIR):
        print(f'{root}')
        for fname in files:
            if fname.startswith('stuff.'):
                BakeEntry(root, files, fname) 
