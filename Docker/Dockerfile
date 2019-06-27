FROM python:3.6

RUN pip install synapseclient pandas scipy sklearn

COPY score_sc1.py /usr/local/bin/score_sc1.py
COPY validate_sc1.py /usr/local/bin/validate_sc1.py
COPY score_sc2.py /usr/local/bin/score_sc2.py
COPY validate_sc2.py /usr/local/bin/validate_sc2.py