# Ansible module: docker-runner

This is a thing for operating a bunch of Docker containers. You want to
specify how to bring them up and how their ports and directory mounts should
work, in a form like an Ansible inventory, something like this.

    all:
        hosts:
            name1:
                from: "ubuntu:latest"
                mounts:
                    /work: "{{ ROOTDIR }}/work"
                    /testcases: "{{ ROOTDIR }}/testcases"
                ports:
                    80: 8080
                    22: 2222
            name2:
            name3:
        vars:
            ROOTDIR: "/home/{{ USER }}/foo"
            USER: "{{ echo whoami | bash }}"     # does this work???

On the first pass we pull all this stuff in. Then our first playbook play
makes sure all these containers are present and awake, and gets their IP
addresses and assigns them in the in-memory inventory. I'm still figuring
out how to do that, it seems to involve...

Anyway the IP address ends up as if you'd said

    name1:
        ansible_ssh_host: 12.34.56.78

Random thoughts:

- It might be good to tag the hosts to indicate which ones want to be closer
  together, like affinity groups.
- How to configure a container to use only a particular network interface? Look
  at cgroups and other @b0rk stuff.
- It might be interesting to try this on Raspberry Pi, or the cross-compiling
  might just make it a pain.

## Using the Ansible module

    # ad-hoc command
    ansible -i myInventory.yaml -m docker-runner -a "state=present var1=foo var2=bar"

    # playbook
    - hosts: whoever
      tasks:
      - name: Ensure docker containers are running
        docker-runner:
          state: present
          var1: foo
          var2: bar


## Online resources for creating an Ansibel module

- [here](https://docs.ansible.com/ansible/latest/dev_guide/developing_modules_general.html)

Copy or soft-link `docker_runner.py` to
`ansible/lib/ansible/modules/clustering/docker/docker_runner.py` and add an
empty `ansible/lib/ansible/modules/clustering/docker/__init__.py` file. Set up
the virtualenv, run `. hacking/env-setup`, and
[run the test playbook](https://docs.ansible.com/ansible/latest/dev_guide/developing_modules_general.html#exercising-module-code-in-a-playbook).
