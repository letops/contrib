from pipeline.compilers import SubProcessCompiler, CompilerBase
from os.path import dirname
from django.conf import settings
import subprocess

# DEPRECATED ... NOT REQUIRED. USED DJANGO-COMPRESSOR INSTEAD OF
#   DJANGO-PIPELINES


class BabelCompiler(SubProcessCompiler):
    output_extension = 'js'

    def match_file(self, path):
        return path.endswith('.jsx')

    def compile_file(self, infile, outfile, outdated=False, force=False):
        if not force and not outdated:
            # File doesn't need to be recompiled
            return
        pipeline_settings = settings.PIPELINE
        command = [
            pipeline_settings.get('BABEL_BINARY', '{}/node_modules/babel-cli/bin/babel.js'.format(settings.DJANGO_ROOT)),
            infile,
            "--out-file",
            outfile,
            pipeline_settings.get('BABEL_ARGUMENTS', '--presets react'),
        ]
        return self.execute_command(command, cwd=dirname(infile))
