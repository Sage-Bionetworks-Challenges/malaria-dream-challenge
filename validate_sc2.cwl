#!/usr/bin/env cwl-runner
#
# Example validate submission file
#
# This version of validate.cwl uses the gold standard to test the input file

cwlVersion: v1.0
class: CommandLineTool
baseCommand: validate_sc2.py
hints:
  DockerRequirement:
    dockerPull: docker.synapse.org/syn16924920/scoring_harness

inputs:
  - id: entity_type
    type: string
  - id: inputfile
    type: File?
  - id: goldstandard
    type: File

arguments:
  - valueFrom: $(inputs.inputfile.path)
    prefix: -s
  - valueFrom: results.json
    prefix: -r
  - valueFrom: $(inputs.goldstandard.path)
    prefix: -g
  - valueFrom: $(inputs.entity_type)
    prefix: -e

requirements:
  - class: InlineJavascriptRequirement
     
outputs:

  - id: results
    type: File
    outputBinding:
      glob: results.json   

  - id: status
    type: string
    outputBinding:
      glob: results.json
      loadContents: true
      outputEval: $(JSON.parse(self[0].contents)['prediction_file_status'])

  - id: invalid_reasons
    type: string
    outputBinding:
      glob: results.json
      loadContents: true
      outputEval: $(JSON.parse(self[0].contents)['prediction_file_errors'])
