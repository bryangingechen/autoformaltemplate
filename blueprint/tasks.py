import os
import random
import shutil
from pathlib import Path
import http.server
import socketserver

from invoke import run, task

BP_DIR = Path(__file__).parent


@task
def print_bp(ctx):
    cwd = os.getcwd()
    os.chdir(BP_DIR)
    os.makedirs("print", exist_ok=True)
    run('cd src && xelatex -output-directory=../print print.tex')
    os.chdir(cwd)


@task
def bp(ctx):
    cwd = os.getcwd()
    os.chdir(BP_DIR)
    os.makedirs("print", exist_ok=True)
    # latexmk auto-iterates xelatex to convergence per src/latexmkrc,
    # avoiding the "Label(s) may have changed. Rerun..." trap when two
    # fixed passes aren't enough (e.g. when math-heavy section titles
    # shift the TOC across passes).
    run('cd src && latexmk')
    # Mirror leanblueprint's behavior: copy print/print.bbl to
    # src/web.bbl so the subsequent `inv web` plastex run sees a
    # bibliography. plastex does not run bibtex itself.
    bbl = BP_DIR / "print" / "print.bbl"
    if bbl.exists():
        shutil.copy(bbl, BP_DIR / "src" / "web.bbl")
    os.chdir(cwd)


@task
def web(ctx):
    cwd = os.getcwd()
    os.chdir(BP_DIR / 'src')
    run('plastex -c plastex.cfg web.tex')
    os.chdir(cwd)


@task
def serve(ctx, random_port=False):
    cwd = os.getcwd()
    os.chdir(BP_DIR / 'web')
    Handler = http.server.SimpleHTTPRequestHandler
    if random_port:
        port = random.randint(8000, 8100)
        print("Serving on port " + str(port))
    else:
        port = 8000
    httpd = socketserver.TCPServer(("", port), Handler)
    httpd.serve_forever()
    os.chdir(cwd)
