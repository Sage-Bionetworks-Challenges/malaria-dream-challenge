#!/usr/bin/env python3
import argparse
import json
import pandas as pd
import numpy as np
from sklearn import metrics

parser = argparse.ArgumentParser()
parser.add_argument("-f", "--submissionfile", required=True,
                    help="Submission File")
parser.add_argument("-s", "--status", required=True,
                    help="Submission status")
parser.add_argument("-r", "--results", required=True,
                    help="Scoring results")
parser.add_argument("-g", "--goldstandard", required=True,
                    help="Goldstandard for scoring")

args = parser.parse_args()
if args.status == "VALIDATED":
    prediction_file_status = "SCORED"
    subdf = pd.read_csv(args.submissionfile, sep="\t")
    golddf = pd.read_csv(args.goldstandard)

    mergeddf = subdf.merge(golddf, left_on="Isolate",
                           right_on="Isolate_Number")
    y = np.array(mergeddf.Clearance)
    pred = np.array(mergeddf.Predicted_Categorical_Clearance)
    fpr, tpr, thresholds = metrics.precision_recall_curve(y, pred)
    score = metrics.auc(fpr, tpr)
else:
    prediction_file_status = args.status
    score = None
result = {'score': score, 'score_rounded': round(score, 4),
          'prediction_file_status': prediction_file_status}
with open(args.results, 'w') as o:
    o.write(json.dumps(result))
