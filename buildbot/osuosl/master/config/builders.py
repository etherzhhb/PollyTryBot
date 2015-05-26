from zorg.buildbot.builders import PollyBuilder
reload(PollyBuilder)
from zorg.buildbot.builders import PollyBuilder


def get_builders():
    return [
        {'name': "polly-amd64-linux",
         'slavenames':["parkas1", "parkas2", "parkas3", "gcc10", "gcc14", "gcc16", "gcc20"],
         'builddir':"polly-amd64-linux",
         'category' : "polly",
         'factory': PollyBuilder.getPollyBuildFactory()},

        {'name': "perf-x86_64-penryn-O3-polly-fast",
         'slavenames':["parkas1", "parkas2", "parkas3"],
         'builddir': "perf-x86_64-penryn-O3-polly-fast",
         'category' : "polly",
         'factory': PollyBuilder.getPollyLNTFactory(triple="x86_64-pc-linux-gnu",
                                                    nt_flags=['--multisample=1', '--mllvm=-polly', '-j16' ],
                                                    reportBuildslave=False,
                                                    package_cache="http://parkas1.inria.fr/packages",
                                                    submitURL='http://gcc45.fsffrance.org:8808/submitRun',
                                                    testerName='x86_64-penryn-O3-polly-fast')},

        {'name': "perf-x86_64-penryn-O3-polly-parallel-fast",
         'slavenames':["parkas1", "parkas2", "parkas3"],
         'builddir': "perf-x86_64-penryn-O3-polly-parallel-fast",
         'category' : "polly",
         'factory': PollyBuilder.getPollyLNTFactory(triple="x86_64-pc-linux-gnu",
                                                    nt_flags=['--multisample=1', '--mllvm=-polly', '--mllvm=-polly-parallel', '-j16', '--cflag=-lgomp' ],
                                                    reportBuildslave=False,
                                                    package_cache="http://parkas1.inria.fr/packages",
                                                    submitURL='http://gcc45.fsffrance.org:8808/submitRun',
                                                    testerName='x86_64-penryn-O3-polly-parallel-fast')},

        {'name': "perf-x86_64-penryn-O3-polly-detect-only",
         'slavenames':["parkas1", "parkas2", "parkas3"],
         'builddir':"perf-x86_64-penryn-O3-polly-detect-only",
         'category' : "polly",
         'properties' : {'lnt_jobs': 1},
         'factory': PollyBuilder.getPollyLNTFactory(triple="x86_64-pc-linux-gnu",
                                                    nt_flags=['--multisample=10', '--mllvm=-polly', '--mllvm=-polly-code-generator=none', '--mllvm=-polly-optimizer=none', '--mllvm=-polly-run-dce=false', '--rerun'],
                                                    reportBuildslave=False,
                                                    package_cache="http://parkas1.inria.fr/packages",
                                                    submitURL='http://gcc45.fsffrance.org:8808/submitRun',
                                                    testerName='x86_64-penryn-O3-polly-detect-only')},

        {'name': "perf-x86_64-penryn-O3-polly-detect-and-dependences-only",
         'slavenames':["parkas1", "parkas2", "parkas3"],
         'builddir':"perf-x86_64-penryn-O3-polly-detect-and-dependences-only",
         'category' : "polly",
         'properties' : {'lnt_jobs': 1},
         'factory': PollyBuilder.getPollyLNTFactory(triple="x86_64-pc-linux-gnu",
                                                    nt_flags=['--multisample=10',
                                                              '--mllvm=-polly',
                                                              '--mllvm=-polly-optimizer=none',
                                                              '--mllvm=-polly-code-generator=none',
                                                              '--rerun'],
                                                    reportBuildslave=False,
                                                    package_cache="http://parkas1.inria.fr/packages",
                                                    submitURL='http://gcc45.fsffrance.org:8808/submitRun',
                                                    testerName='x86_64-penryn-O3-polly-detect-and-dependences-only')},

        {'name': "perf-x86_64-penryn-O3-polly",
         'slavenames':["parkas1", "parkas2", "parkas3"],
         'builddir':"perf-x86_64-penryn-O3-polly",
         'category' : "polly",
         'properties' : {'lnt_jobs': 1},
         'factory': PollyBuilder.getPollyLNTFactory(triple="x86_64-pc-linux-gnu",
                                                    nt_flags=['--multisample=10', '--mllvm=-polly', '--rerun'],
                                                    reportBuildslave=False,
                                                    package_cache="http://parkas1.inria.fr/packages",
                                                    submitURL='http://gcc45.fsffrance.org:8808/submitRun',
                                                    testerName='x86_64-penryn-O3-polly')}
    ]

