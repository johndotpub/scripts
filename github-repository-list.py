#!/usr/bin/env python

""" Print all repositories for a GitHub organization.

The github3.py module is required::

    $ pip install github3.py

Usage example::

    $ python github-repository-list.py

Advanced use.  This will actually clone all the repos for a
GitHub organization or user::

    $ for url in $(python list-all-repos.py); do git clone $url; done
"""

import github3
import getpass
import pprint

try:
    # Python 2
    prompt = raw_input
except NameError:
    # Python 3
    prompt = input

def two_factor():
    code = ''
    while not code:
        code = prompt('Enter 2FA code: ')
    return code

usr = prompt('Username: ')
biz = prompt('Organization: ')
pwd = getpass.getpass(prompt='Password: ', stream=None)

gh = github3.login(usr, pwd, two_factor_callback=two_factor)
org = gh.organization(biz)
repos = list(org.repositories(type="all"))

pprint.pprint(repos)
