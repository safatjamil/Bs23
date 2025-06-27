#!/bin/bash

# I have used my docker repository. You must log in to your repository using `docker login` 
# command before pushing an image

# Install shyaml if not installed `pip install shyaml`
remote_repo="shafatjamil/wxapi"
version=$(cat version.yaml | shyaml get-value apiVersion)
sudo docker build -t wxapi:$version .
sudo docker tag wxapi:1.0.0 $remote_repo:$version
sudo docker push $remote_repo:$version