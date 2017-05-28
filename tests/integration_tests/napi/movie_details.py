#!/usr/bin/python2

class MovieDetails(object):
    """
    Encapsulates most of the details that napiprojekt XML provides
    """

    def __init__(self,
            title,
            otherTitle,
            year,
            countryPl,
            countryEn,
            genrePl,
            genreEn,
            direction,
            screenplay,
            cinematography,
            imdb,
            filmweb,
            fdb,
            stopklatka,
            onet,
            wp,
            rating = 0,
            votes = 0):
        self.title = title
        self.otherTitle = otherTitle
        self.year = int(year)
        self.countryPl = countryPl
        self.countryEn = countryEn
        self.genrePl = genrePl
        self.genreEn = genreEn
        self.direction = direction
        self.screenplay = screenplay
        self.cinematography = cinematography
        self.imdb = imdb
        self.filmweb = filmweb
        self.fdb = fdb
        self.stopklatka = stopklatka
        self.onet = onet
        self.wp = wp
        self.rating = rating
        self.votes = votes

    @staticmethod
    def makeSimple(title,
            year,
            countryPl,
            genrePl,
            direction,
            imdb,
            filmweb,
            fdb,
            stopklatka,
            onet,
            wp):
        return MovieDetails(title,
                title,
                year,
                countryPl,
                countryPl,
                genrePl,
                genrePl,
                direction,
                direction,
                direction,
                imdb,
                filmweb,
                fdb,
                stopklatka,
                onet,
                wp)
