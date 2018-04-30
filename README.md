# rancher-glusterfs-client
This project build a container that work alongside the bernardmaltais/rancher-glusterfs-server project.

It contains glusterfs-client, nginx and PHP with the ability to pull from github a web site for deployment.

This is part of a catalog item as found in bernardmaltais/rancher-catalog

# Introduction

Docker container that lauch NGINX + PHP server leveraging Glusterfs as underlying file system. It's dedicated to work on Rancher environment and use auto discovery service to connect to glusterfs cluster.

## Version

Current Version: **0.1.0**

# Quick Start
Like I have say at the beginning, this container work only on Rancher plateform. On your stack (applications), create new service (Add Service).

## Main section
- NAME : Put 'gluster' as a name of your service. If you change this name, you must add environment variable name SERVICE_NAME with the name of your current service.
- SCALE:  Run 2 or more container. I think you can start with 2 and upgrade later with 4 if needed
- SELECT IMAGE : put 'bmaltais/rancher-glusterfs-client:latest'

## ADVANCED OPTIONS - Command
- ENVIRONMENT VARS : put the environment variable that you need to custom Glusterfs
  - 




