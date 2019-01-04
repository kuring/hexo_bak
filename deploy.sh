#!/bin/bash

hexo g && hexo d

git add . && git commit -m "add" && git push origin master

