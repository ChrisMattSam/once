# -*- coding: utf-8 -*-
"""
Created on Mon Mar 16 19:59:05 2020

@author: csampah
"""

import os
from time import ctime

def get_time(obj,date = 'all'): 
    
    if date == 'created':
        return ctime(os.path.getctime(obj))
        
    elif date == 'modified':
        return ctime(os.path.getmtime(obj))
        
    elif date == 'all':
        print('Created date: ' + ctime(os.path.getctime(obj)))
        print('Last modified: ' + ctime(os.path.getmtime(obj)))
        

backup_dir = '//Isi/ida/Divisions/SFRD/Public/PII Data Curation/PII Data Curation/'
repo_dir = '//Isi/ida/Projects/PII Data Curation/'


backup = os.listdir(backup_dir)
repository = os.listdir(repo_dir)

added = [i for i in repository if i not in backup]
deleted = [i for i in backup if i not in repository]
same = [i for i in backup if i in repository]

#t = repo_dir + same[0]
#vec = [ctime(os.path.getctime(t)),ctime(os.path.getmtime(t))]
#[i.split()[3][:-3] for i in vec]
#vec[0] == vec[1] and vec[1] == vec[2]
    


full_dir = list(os.walk(backup_dir))
test = full_dir[618]

print('Changed files: \n')
for i in same:
    print('File: ' + i + '\nIn the backup directory: ' + get_time(backup_dir + i,'modified'))
    print('In the repository: ' + get_time(repo_dir + i,'modified'))
    print('\n')
    

if len(added) > 0:
    print('Files that have been added:')
    [print(i) for i in added]
    
if len(deleted) > 0:
    print('Files that have been deleted:')
    [print(i) for i in deleted]


