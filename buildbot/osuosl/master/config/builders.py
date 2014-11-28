from zorg.buildbot.builders import PollyBuilder
reload(PollyBuilder)
from zorg.buildbot.builders import PollyBuilder


def get_builders():
    yield {'name': "polly-intel32-linux",
           'category' : "polly",
           'slavenames':["botether"],
           'builddir':"polly-intel32-linux",
           'factory': PollyBuilder.getPollyBuildFactory()}

    yield  {'name': "perf-i386-penryn-O3-polly-detect-only",
         'slavenames':["botether"],
         'category' : "polly",
         'builddir':"perf-x86_64-penryn-O3-polly-detect-only",
         'factory': PollyBuilder.getPollyLNTFactory(triple="x86_64-pc-linux-gnu",
                                                    nt_flags=['--multisample=10', '--mllvm=-polly', '--mllvm=-polly-code-generator=none', '--mllvm=-polly-optimizer=none', '--mllvm=-polly-run-dce=false', '--rerun'],
                                                    reportBuildslave=False,
                                                    package_cache="http://parkas1.inria.fr/packages",
                                                    submitURL='http://supper.bad.url',
                                                    testerName='x86_64-penryn-O3-polly-detect-only')}

