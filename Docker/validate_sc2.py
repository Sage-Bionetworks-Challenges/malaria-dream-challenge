#!/usr/bin/env python
import pandas as pd
import argparse
import json
parser = argparse.ArgumentParser()
parser.add_argument("-r", "--results", required=True, help="validation results")
parser.add_argument("-e", "--entity_type", required=True, help="synapse entity type downloaded")
parser.add_argument("-s", "--submission_file", help="Submission File")
parser.add_argument("-g", "--goldstandard", required=True, help="Goldstandard for scoring")

args = parser.parse_args()
invalid_reasons = []
if args.submission_file is None:
    prediction_file_status = "INVALID"
    invalid_reasons = ['Expected FileEntity type but found ' + args.entity_type]
else:
    try:
        subdf = pd.read_csv(args.submission_file, sep="\t")
    except Exception:
        invalid_reasons.append("Cannot read submission, must be tsv.")

    if not invalid_reasons:
        if 'Isolate' not in subdf.columns or 'Predicted_Categorical_Clearance' not in subdf.columns:
            invalid_reasons.append("Must have columns 'Isolate' and 'Predicted_Categorical_Clearance'")
        else:
            golddf = pd.read_csv(args.goldstandard)
            isolates = golddf['Isolate_Number']
            if not isolates.isin(subdf['Isolate']).all() or not subdf['Isolate'].isin(isolates).all() or subdf['Isolate'].duplicated().any():
                invalid_reasons.append("Must have all the 'Isolate' and no duplicates allowed")
            if not subdf['Predicted_Categorical_Clearance'].isin(["Fast", "Slow"]).all():
                invalid_reasons.append("'Predicted_Categorical_Clearance' must be 'Fast' or 'Slow' and no NAs are allowed")

if not invalid_reasons:
    prediction_file_status = "VALIDATED"
else:
    prediction_file_status = "INVALID"

result = {'prediction_file_errors': "\n".join(invalid_reasons),
          'prediction_file_status': prediction_file_status}
with open(args.results, 'w') as o:
    o.write(json.dumps(result))
