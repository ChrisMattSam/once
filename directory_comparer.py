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

tester = os.path.join(os.path.dirname(__file__))

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
    print(preamble + ': ' + str(round(t()-value,1)) + ' seconds')

backup_path = '//Isi/ida/Divisions/SFRD/Public/PII Data Curation/PII Data Curation/'
repo_path = '//Isi/ida/Projects/PII Data Curation/'

god_time = t()


print('Reading in all sub-directories...')
start = t()
print('Exploring all sub-directories of the backup folder...')
backup_dir = list(os.walk(backup_path))
print_time(start, 'Complete. Elapsed time: ')

start = t()
print('Exploring all sub-directories of the repository folder, excluding the '+
      '"Python VirtualEnv" sub-folder and all its contents...')

# save time by omitting high-level directory from subsequent directory walk path
exclude = [i for i in os.listdir(repo_path) if i not in os.listdir(backup_path)]
repo_dir = []
for root, dirs, files in os.walk(repo_path):
    dirs[:] = [d for d in dirs if d not in 'Python VirtualEnv' or d not in exclude] # exclude the Python VirtualEnv folder
    repo_dir.append( tuple([root,dirs,files]))
print_time(start)
# note to self: Python VirtualEnv folder has 67,631 Files, 8,578 Folders


repo_dir = return_files(repo_dir)
backup_dir = return_files(backup_dir)

same = [file for file in repo_dir if file.replace(repo_path, backup_path) in backup_dir ]
modified = []
added = [file for file in repo_dir if file not in same]
deleted = [file for file in backup_dir if file.replace(backup_path, repo_path) not in same]

start = t()
for file in same:
    repo_file = file
    backup_file = file.replace(repo_path, backup_path)
    if ctime(os.path.getmtime(repo_file)) > ctime(os.path.getmtime(backup_file)):
        modified.append(repo_file)
print_time(start)




print_time(god_time,'Total time: ')

print('Changed or edited files: ')
[print(file) for file in modified]
print('\nDeleted files: ')
[print(file) for file in deleted]
print('\nAdded files: ')
s = [print(file) for file in added]

files = {'modified': modified, 'deleted': deleted, 'added':added}
with open(backup_path + 'files.tx', 'w') as outfile:
    json.dump(files, outfile)




