#! /usr/bin/Python
# -*- coding: utf-8 -*-
"""
Created on Wed Mar 18 10:18:55 2020

@author: csampah

Helpful links:
    https://stackoverflow.com/questions/19859840/excluding-directories-in-os-walk
    https://stackoverflow.com/questions/3021641/concatenation-of-many-lists-in-python
    https://stackoverflow.com/questions/38604805/convert-list-into-list-of-lists
"""
import os
from time import time as t
from time import ctime
import json
import inspect

'''
Without the two lines below, print functions are held until the end of execution, and
will not print at all if there is any error
'''
from functools import partial
print = partial(print, flush=True) 

def return_files(directory):
    '''
    From list(os.walk(string)) output of a list of 3-tuples of:
    (full file path of sub-directory A,
    the list of directories one level beneath sub-directory A,
    list of files within sub-directory A ),
    this function a list comprisin of all files within sub-directory A for every
    element of the main list. For example
    os.walk(CS/example/path) = [X,Y,Z], where
    X = ["CS/example/path/sub_dir_x", [folder1_inside_sub_dir_x, folder2_inside_sub_dir_x],
    file_1_inside_sub_dir_x, file_2_inside_sub_dir_x];
    Y = ["CS/example/path/sub_dir_y",...], similarly with Z
    
    Returns: ["CS/example/path/sub_dir_x/file_1_inside_sub_dir_x", "CS/example/path/sub_dir_x/file_1_inside_sub_dir_x",
    ...., "CS/example/path/sub_dir_z/file_1_inside_sub_dir_z"]
    '''
    d = [list(sub_dir) for sub_dir in directory]
    
    for sub_dir in d:
        sub_dir[2] = [ (sub_dir[0] + '/'+ file).replace('\\',"/") for file in sub_dir[2]]
    
    return sum([sub_dir[2] for sub_dir in d ], [])


def print_time(value, preamble = 'Elapsed time'):
    from time import time as t
    f = t() - value
    unit = 'seconds'
    if f > 60:
        f = f/60
        unit = 'minutes'
    print(preamble + ': ' + str(round(f)) + ' ' + unit )

god_time = t()
repo_path = '//Isi/ida/Projects/PII Data Curation/'

f = inspect.getframeinfo(inspect.currentframe()).filename
backup_path = os.path.dirname(os.path.abspath(f)).replace('repository_compare','')
backup_path = backup_path.replace('\\','/')

print('Reading in all sub-directories')
start = t()
print('Exploring all sub-directories of the backup folder...')
backup_dir = list(os.walk(backup_path))
print_time(start, 'Complete. Elapsed time')

start = t()
print('\nExploring all sub-directories of the repository folder, excluding the '+
      '"Python VirtualEnv" sub-folder and all its contents...')

# save time by excluding high-level directory from subsequent directory walk path
exclude = [i for i in os.listdir(repo_path) if i not in os.listdir(backup_path)]
repo_dir = []
for root, dirs, files in os.walk(repo_path):
    # exclude "Python VirtualEnv" sub-dir, which has 67,631 Files under 8,578 Folders
    dirs[:] = [d for d in dirs if d not in exclude and 'Python VirtualEnv' not in d] 
    repo_dir.append( tuple([root,dirs,files]))


repo_dir = return_files(repo_dir)
backup_dir = return_files(backup_dir)
print_time(start,'Complete. Elapsed time')

print('\nComparing similar files between repository and backup directory...')
start = t()
same = [file for file in repo_dir if file.replace(repo_path, backup_path) in backup_dir ]
modified = []
added = [file for file in repo_dir if file not in same]
deleted = [file for file in backup_dir if file.replace(backup_path, repo_path) not 
           in same and 'repository_compare' not in file]

for file in same:
    repo_file = file
    backup_file = file.replace(repo_path, backup_path)
    if ctime(os.path.getmtime(repo_file)) > ctime(os.path.getmtime(backup_file)):
        modified.append(repo_file)
print_time(start,'Complete. Elapsed time')
print_time(god_time + 1,'Total run-time')

with open(backup_path + 'repository_compare/files.json', 'w') as outfile:
    json.dump({'modified': modified, 'deleted': deleted, 'added':added}, outfile)
    
