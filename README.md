# Docker Tricks and Things

![Silly docker meme jpeg](https://raw.githubusercontent.com/wware/docker-tricks/master/docker_meme.jpg)

## Containerization is increasingly popular because containers are

* Flexible: Even the most complex applications can be containerized.
* Lightweight: Containers leverage and share the host kernel, making them much
  more efficient in terms of system resources than virtual machines.
* Portable: You can build locally, deploy to the cloud, and run anywhere.
* Loosely coupled: Containers are highly self sufficient and encapsulated,
  allowing you to replace or upgrade one without disrupting others.
* Scalable: You can increase and automatically distribute container replicas
  across a datacenter.
* Secure: Containers apply aggressive constraints and isolations to processes
  without any configuration required on the part of the user.

## Some handy links

* https://docs.docker.com/get-started/
* https://docs.docker.com/storage/bind-mounts/
* https://github.com/fijiwebdesign/docker-quickstart-tutorial
* https://github.com/kinecosystem/blockchain-ops/tree/master/apps/docker-quickstart
* https://github.com/atamahjoubfar/docker-quickstart-cheatsheet

I work on a Buildbot-based CI/CD system at my job, and I'm keenly interested
in migrating it to a bunch of Docker containers to gain all the benefits
appearing above, most importantly, smoothly going from "Works on my machine"
to "Works wherever I want it to work".

## Julia Evans

Her cartoons and zines are a great friendly way to learn topics that are
normally daunting.

* https://twitter.com/search?q=from%3A%40b0rk%20container%20since%3A2019-01-01
