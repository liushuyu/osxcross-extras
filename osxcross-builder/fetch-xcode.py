import requests
import logging
import json
import time
import os
import sys
from html5lib.html5parser import HTMLParser
from html5lib.treebuilders import getTreeBuilder

USER = ''
PASS = ''
XCODE_VER = '9.2'
MAC_VER = '10.13'
BLOB_URL = ''
UA = 'Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/67.0.3396.62 Safari/537.36'


def generateDownload(cookies):
    logging.info('Generating download script...')
    template = '#!/bin/bash\nwget --show-progress -q -c --no-cookie --header \'User-Agent: %s\'\
               --header \'Cookie: %s\' \'%s\''
    cookie_string = ''
    found = False
    for cookie in cookies:
        if cookie[0] == 'ADCDownloadAuth':
            found = True
        cookie_string += '%s=%s;' % (cookie[0], cookie[1])
    if not found:
        logging.exception('Unable to find download auth token.\n\
        You need to agree to EULA on https://developer.apple.com/download/')
    file_name = 'download_xcode%s.sh' % XCODE_VER
    with open(file_name, 'wt') as f:
        f.write(template % (UA, cookie_string, BLOB_URL))
    logging.info('Run %s to start your download.' % file_name)


def openLogin():
    logging.info('Loading login page...')
    s = requests.Session()
    # trigger login page
    resp = s.get('https://developer.apple.com/download/', headers={
        'User-Agent': UA
    })
    resp.raise_for_status()
    parser = HTMLParser(getTreeBuilder('dom'))
    parser = parser.parse(resp.text)
    form_input = bakeRequest(parser)
    logging.info('Logging in ...')
    resp = s.post('https://idmsa.apple.com/IDMSWebAuth/authenticate',
                  headers={'User-Agent': UA}, data=form_input)
    resp.raise_for_status()
    if resp.url.find('authenticate') > 0:
        raise Exception('Login failed')
    logging.info('Fetching download token...')
    resp = s.post('https://developer.apple.com/services-account/QH65B2/downloadws/listDownloads.action',
                  headers={'User-Agent': UA}, data='')
    resp.raise_for_status()
    generateDownload(s.cookies.items())


def bakeRequest(parser):
    hidden_params = ['appIdKey', 'accNameLocked', 'language', 'path', 'rv',
                     'requestUri', 'Env', 'scnt']
    fields = {'accountPassword': PASS, 'appleId': USER}
    telemetry = {}
    login_form = parser.getElementsByTagName('form')
    if len(login_form) != 1:
        raise Exception('Unable to pinpoint the form for login!')
    for field in login_form[0].getElementsByTagName('input'):
        name = field.getAttribute('name')
        if name in hidden_params:
            fields[name] = field.getAttribute('value')
    tz = time.strftime('%z', time.localtime())
    tz = tz[:3] + ':' + tz[3:]
    telemetry = {'U': UA, 'L': fields.get('language'), 'V': '1.1',
                 'Z': 'GMT%s' % (tz)}
    fields['fdcBrowserData'] = fields['clientInfo'] = json.dumps(telemetry)
    return fields


if __name__ == '__main__':
    logging.getLogger("urllib3").setLevel(logging.INFO)
    logging.getLogger().setLevel(logging.INFO)
    USER = os.environ.get('XCODE_USERNAME')
    PASS = os.environ.get('XCODE_PASSWORD')
    XCODE_VER = os.environ.get('XCODE_VER') or '9.2'
    BLOB_URL = 'https://download.developer.apple.com/Developer_Tools/Command_Line_Tools_macOS_%s_for_Xcode_%s/Command_Line_Tools_macOS_%s_for_Xcode_%s.dmg' % (MAC_VER, XCODE_VER, MAC_VER, XCODE_VER)
    if (not USER) or (not PASS):
        print('\tPlease specify Apple ID and password using \n\
        XCODE_USERNAME and XCODE_PASSWORD environment varables. \n\
        Make sure you have agreed to EULA on \n\
        https://developer.apple.com/download/')
        sys.exit(1)

    openLogin()
