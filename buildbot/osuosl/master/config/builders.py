from zorg.buildbot.builders import PollyBuilder
reload(PollyBuilder)
from zorg.buildbot.builders import PollyBuilder


def get_builders():
    yield {'name': "polly-intel32-linux",
           'category' : "polly",
           'slavenames':["botether"],
           'builddir':"polly-intel32-linux",
           'factory': PollyBuilder.getPollyBuildFactory()}

