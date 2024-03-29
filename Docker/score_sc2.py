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
result = {}
if args.status == "VALIDATED":
    prediction_file_status = "SCORED"
    subdf = pd.read_csv(args.submissionfile, sep="\t")
    golddf = pd.read_csv(args.goldstandard)
    mergeddf = subdf.merge(golddf, left_on="Isolate",
                           right_on="Isolate_Number")
    y = np.array(mergeddf.Clearance)
    y = y < 5
    pred = np.array(mergeddf.Probability)
    precision, recall, _ = metrics.precision_recall_curve(y, pred)
    score = metrics.auc(recall, precision)
    result['score'] = score
    result['score_rounded'] = round(score, 4)

    # categorical = np.array(mergeddf.Predicted_Categorical_Clearance)
    # # SLOW is turned into True
    # bool_cat = categorical == 'SLOW' 
    # # True == 1
    # int_cat = bool_cat.astype(int)
    # bac = metrics.balanced_accuracy_score(y, int_cat)
    # result['bac'] = bac
    # result['bac_rounded'] = round(bac, 4)

    auc = metrics.roc_auc_score(y, pred)
    mergeddf['Newprobability'] = 1 - mergeddf['Probability']
    spearman = mergeddf['Newprobability'].corr(mergeddf['Clearance'],
                                            method="spearman")

else:
    raise ValueError("INVALID PREDICITON FILE")
    prediction_file_status = args.status
result['prediction_file_status'] = prediction_file_status
with open(args.results, 'w') as o:
    o.write(json.dumps(result))
