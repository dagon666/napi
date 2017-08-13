#!/usr/bin/python2

from pretenders.client.http import HTTPMock

from . import xml_result

class NapiprojektMock(object):

    DEFAULT_ADDRESS = 'napiserver'
    DEFAULT_PORT = 8000

    def __init__(self,
            address = DEFAULT_ADDRESS,
            port = DEFAULT_PORT):
        self.address = address
        self.port = port
        self.http = HTTPMock(self.address, self.port)
        self.defaultHeaders = {
                'Content-Type': 'text/xml; charset=UTF-8',
                }

    def getUrl(self):
        return self.http.pretend_url

    def getRequest(self, n = 0):
        return self.http.get_request(n)

    def programPlainRequest(self,
            blob = None,
            status = None,
            times = 1):

        body = None
        data = blob.getData() if blob else ''
        if not status:
            status = 200 if blob else 404

        self.http.when(
                'GET /unit_napisy/dl.php',
                body = body).reply(
                data,
                status = status,
                headers = self.defaultHeaders,
                times = times)

    def programXmlRequest(self,
            media,
            subtitles = None,
            cover = None,
            movieDetails = None,
            times = 1):
        status = 200
        # pretenders matches body from the beginning of the string - due to
        # that body filtering at the moment is out of question
        body = None
        self.http.when(
                'POST /api/api-napiprojekt3.php',
                body = body).reply(
                xml_result.XmlResult(subtitles, cover, movieDetails).toString(),
                status = status,
                headers = self.defaultHeaders,
                times = times)


