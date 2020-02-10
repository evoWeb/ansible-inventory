#!/usr/bin/python

# Copyright: (c) 2019 William Bartlett
# GNU General Public License v3.0+
# (see https://www.gnu.org/licenses/gpl-3.0.txt)
# https://github.com/punkstarman/ansible-gsettings-module

from ansible.module_utils.basic import AnsibleModule
from gi.repository import Gio, GLib

ANSIBLE_METADATA = {
    'metadata_version': '1.1',
    'status': ['preview'],
    'supported_by': 'community'
}

DOCUMENTATION = '''
---
module: gsettings

short_description: Configure Gnome settings

version_added: "2.9"

description:
    - "Configure Gnome settings"

options:
    path:
        description:
            - path within the settings
        required: true
    key:
        description:
            - a setting key
        required: true
    value:
        description:
            - value to be set
        required: false

author:
    - William Bartlett (@bartlettstarman)
'''

EXAMPLES = '''
# Set a key
- name: Set proxy mode to manual
  gsettings:
    path: org.gnome.system.proxy
    key: mode
    value: "'manual'"

# Reset a key
- name: Reset proxy mode
  gsettings:
    path: org.gnome.system.proxy
    key: mode
    state: reset

# Read the value of a key
- name: Read http proxy host
  gsettings:
    path: org.gnome.system.proxy.http
    key: host
    state: get
  register: http_proxy_host
'''

RETURN = '''
value:
    description: value associated with the requested key
'''


def run_module():
    # define available arguments/parameters a user can pass to the module
    module_args = dict(
        state=dict(
            type='str',
            choices=['present', 'reset', 'reset-recursively', 'get'],
            default='present'),
        schema=dict(type='str', required=False),
        path=dict(type='str', require=True),
        key=dict(type='str', required=True),
        value=dict(type='str', required=False, default='@as []')
    )

    # seed the result dict in the object
    # we primarily care about changed and state
    # change is if this module effectively modified the target
    # state will include any data that you want your module to pass back
    # for consumption, for example, in a subsequent task
    result = dict(
        changed=False,
        value=None
    )

    # the AnsibleModule object will be our abstraction working with Ansible
    # this includes instantiation, a couple of common attr would be the
    # args/params passed to the execution, as well as if the module
    # supports check mode
    module = AnsibleModule(
        argument_spec=module_args,
        supports_check_mode=True
    )

    # if the user is working with this module in only check mode we do not
    # want to make any changes to the environment, just return the current
    # state with no modifications
    if module.check_mode:
        return result

    # manipulate or modify the state as needed (this is going to be the
    # part where your module will do what it needs to do)
    path = module.params['path']
    key = module.params['key']
    state = module.params['state']
    value = module.params['value']

    setting = Gio.Settings.new(path)
    old_value = setting.get_value(key)
    new_value = GLib.Variant.parse(None, value, None, None)

    if state == 'present' and old_value != new_value:
        setting.set_value(key, new_value)
        result['changed'] = True

    if state == 'reset' and setting.get_user_value(key) is not None:
        setting.reset(key)
        result['changed'] = True

    result['value'] = setting.get_value(key).unpack()

    # during the execution of the module, if there is an exception or a
    # conditional state that effectively causes a failure, run
    # AnsibleModule.fail_json() to pass in the message and the result
    # if module.params['name'] == 'fail me':
    #     module.fail_json(msg='You requested this to fail', **result)

    # in the event of a successful module execution, you will want to
    # simple AnsibleModule.exit_json(), passing the key/value results
    module.exit_json(**result)


def main():
    run_module()


if __name__ == '__main__':
    main()
