#!/usr/bin/python

import argparse
import os
import sys
import BaseHTTPServer
import json

class ProgrammableFakeNapiprojekt(BaseHTTPServer.BaseHTTPRequestHandler):

    def httpRequestLast(self):
        if hasattr(self.server, 'httpRequests'):
            self.log_message("Returning last received HTTP request details")
            self.wfile.write(json.dumps(self.server.httpRequests[-1]))
            self.send_response(200)
        else:
            self.log_error("No HTTP requests received beforehand")
            self.send_response(400)

    def httpRequestPurge(self):
        self.log_message("Purging request history")
        if hasattr(self.server, 'httpRequests'):
            delattr(self.server, 'httpRequests')
        self.send_response(200)

    def httpResponseAppend(self):
        pass

    def httpResponsePurge(self):
        self.log_message("Purging programmed responses")
        if hasattr(self.server, 'httpResponses'):
            delattr(self.server, 'httpResponses')
        self.send_response(200)

    def logRequest(self):
        request = {}
        request['method'] = self.command
        request['path'] = self.path
        request['headers'] = []

        if self.command == 'POST':
            length = self.headers.getheader('content-length')
            if length:
                request['data'] = self.rfile.read(int(length))

        for k,v in self.headers.items():
            request['headers'].append({ k: v })

        if hasattr(self.server, 'httpRequests'):
            self.server.httpRequests.append(request)
        else:
            self.server.httpRequests = [ request ]

    def handleNapiprojektGet(self):
        self.log_message("Napiprojekt GET request")
        self.send_response(200)

    def handleNapiprojektPost(self):
        self.log_message("Napiprojekt POST request")
        self.send_response(200)

    def do_GET(self):
        try:
            {
                "/fake/napiprojekt/httprequest/last": self.httpRequestLast,
            }[self.path.split('?')[0]]()
        except KeyError:
            # log only requests from test environment, ignore the mgmt ones
            self.logRequest()
            self.handleNapiprojektGet()

    def do_POST(self):
        try:
            {
                "/fake/napiprojekt/httpresponse/append": self.httpResponseAppend,
                "/fake/napiprojekt/httpresponse/purge": self.httpResponsePurge,
                "/fake/napiprojekt/httprequest/purge": self.httpRequestPurge,
            }[self.path.split('?')[0]]()
        except KeyError:
            # log only requests from test environment, ignore the mgmt ones
            self.logRequest()
            self.handleNapiprojektPost()

def makeArgParser():
    desc = 'Fake napiprojekt server'
    argParser = argparse.ArgumentParser(prog = sys.argv[0],
            description = desc)

    argParser.add_argument("-p", "--port",
            type = int,
            default = os.environ.get("NAPISERVER_PORT", 8888))

    return argParser

def main():
    ap = makeArgParser()
    args = ap.parse_args()

    address = ('', args.port)
    httpd = BaseHTTPServer.HTTPServer(address, ProgrammableFakeNapiprojekt)

    while True:
        # dispatch a single request
        httpd.handle_request()

if __name__ == '__main__':
    main()
