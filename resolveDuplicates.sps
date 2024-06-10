* SPSS Python macro to resolve duplicate cases
* by Jamie DeCoster

* This macro is designed to resolve duplicate cases in a data set. It asks you to specify
* a list of key variables that will be used to identify duplicates, such that rows with the 
* same values on all of the key variables are considered to be duplicates of a single case. 
* You then specify whether you
* want the primary case to be the first, last, or identified by a variable. Retained values
* will first be taken from the primary case. If the primary case has a missing value,
* it will take a non-missing value from one of the other cases, if it is available. If there
* are multiple alternative non-missing values, then one will be selected randomly.

**** Usage: resolveDuplicates(keyList, primary = "*LAST")
**** "keyList" is a list of strings indicating what rows should be considered duplicates of
* a single case, such that those with the same values on all of the variables in the key
* list are considered to be duplicates of a single case. In the final version of the data 
* set, there will be a single row for each unique combination of values across the
* key variables.
**** "primary" is a string indicating which cases should be considered the primary rows
* when determining the values that will be retained in the final data set. Retained values
* will first be taken from the primary row, and then from other rows for that case if the 
* primary row has a missing value. There should be one primary row for each case. 
* If the value of primary is "*FIRST", the macro will automatically make the first row
* for each case the primary row. If the value of primary is "*LAST", the macro will
* automatically make the last row for each case the primary row. If you specify anything
* else, the macro will assume that you have created your own variable by that name
* that indicates the primary row for each case. If a primary row is not identified for
* a case, then that case will not be included in the final data set.

**** Example
resolveDuplicates(keyList = ["LastName", "FirstName"],
primary = "*LAST")
**** This would consolidate all rows in the data set that had the same lastname and
* firstname, so that there was only one row in the final data set for each common pair
* of names. The macro would identify the last row for each last name/first name 
* combination and use that as the primary row. 

*********
* Version History
*********
* 2015-09-16 Created
* 2015-09-17 Split off cases with duplicates 
* 2015-09-19 Replaced missing values
* 2015-09-21 Modified case data using spss.StartDataStep()

BEGIN PROGRAM PYTHON3.
import spss, random

def resolveDuplicates(keyList, primary):
# Obtain list of variables in data set
    SPSSvariables = []
    SPSSvariablesCaps = []
    for varnum in range(spss.GetVariableCount()):
        SPSSvariables.append(spss.GetVariableName(varnum))
        SPSSvariablesCaps.append(spss.GetVariableName(varnum).upper())

# Check if variables are in data set
    variableError = 0
    for var in keyList:
        if var.upper() not in SPSSvariablesCaps:
            print(("Error: Variable {0} in keyList not in data set".format(var)))
            variableError = 1
    if (primary.upper() not in SPSSvariablesCaps 
    and primary.upper() != "*FIRST"
    and primary.upper() != "*LAST"):
        print(("Error: primary variable {0} not in data set".format(var)))
        variableError = 1
    if (variableError == 1):
        return 0

# Create primary variable if FIRST or LAST selected
    if (primary.upper() == "*FIRST" or primary.upper() == "*LAST"):
        submitstring = "SORT CASES BY" 
        for var in keyList:
            submitstring += "\n" + var + "(A)"
        submitstring += """.
MATCH FILES
  /FILE=*
  /BY"""
        for var in keyList:
            submitstring += "\n" + var
        submitstring += """\n/FIRST=PrimaryFirst7663804
  /LAST=PrimaryLast7663804.
DO IF (PrimaryFirst7663804).
COMPUTE  MatchSequence=1-PrimaryLast7663804.
ELSE.
COMPUTE  MatchSequence=MatchSequence+1.
END IF.
LEAVE  MatchSequence.
FORMATS  MatchSequence (f7).
COMPUTE  InDupGrp=MatchSequence>0.
SORT CASES InDupGrp(D).
MATCH FILES
  /FILE=*
  /DROP=InDupGrp MatchSequence.
VARIABLE LEVEL  PrimaryFirst7663804 PrimaryLast7663804 (ORDINAL).
EXECUTE."""
        spss.Submit(submitstring)
        if (primary.upper() == "*FIRST"):
            primary = "PrimaryFirst7663804"
        else:
            primary = "PrimaryLast7663804"

# Determine locations of keys in data set
    keyNums = []
    for var in keyList:
        count = 0
        for SPSSvar in SPSSvariablesCaps:
            if var.upper() == SPSSvar:
                keyNums.append(count)
            count += 1

# Determine which cases have duplicates
    submitstring = """AGGREGATE
  /OUTFILE=* MODE=ADDVARIABLES
  /BREAK="""
    for var in keyList:
        submitstring += "\n" + var
    submitstring += "\n/N7663804=N."
    spss.Submit(submitstring)

# Split duplicated and not duplicated cases
    activeName = spss.ActiveDataset()
    submitstring = """dataset copy dup7663804.
dataset copy nodup7663804.
dataset activate dup7663804.
FILTER OFF.
USE ALL.
SELECT IF (n7663804 >1).
EXECUTE.
dataset activate nodup7663804.
FILTER OFF.
USE ALL.
SELECT IF (n7663804 =1).
EXECUTE."""
    spss.Submit(submitstring)

# Restructure duplicate data set
# Primary case is sorted to be the first
    submitstring = """dataset activate dup7663804.
SORT CASES BY"""
    for var in keyList:
        submitstring += "\n" + var + "(A)"
    submitstring += "\n" + primary + "(D)."
    spss.Submit(submitstring)
    if (primary.upper() == "PRIMARYFIRST7663804" or 
        primary.upper() == "PRIMARYLAST7663804"):
        submitstring = """delete variables 
PRIMARYFIRST7663804 PRIMARYLAST7663804"""
        spss.Submit(submitstring)
    submitstring = """CASESTOVARS
  /autofix = NO
  /ID="""
    for var in keyList:
        submitstring += "\n" + var
    submitstring += "\n  /GROUPBY=VARIABLE."
    spss.Submit(submitstring)
    lastVar = spss.GetVariableName(spss.GetVariableCount()-1)
    maxDup = int(lastVar[len(lastVar)-1])

# Obtain list of variables in restructured data set
    SPSSvariablesDup = []
    SPSSvariablesDupCaps = []
    for varnum in range(spss.GetVariableCount()):
        SPSSvariablesDup.append(spss.GetVariableName(varnum))
        SPSSvariablesDupCaps.append(spss.GetVariableName(varnum).upper())

# Resolve missing values
    keyListCaps = []
    for var in keyList:
        keyListCaps.append(var.upper())
    spss.StartDataStep()
    ds = spss.Dataset()
    for child in range(len(ds.cases)):
        for var in range(len(SPSSvariablesDupCaps)):
            if SPSSvariablesDupCaps[var] [-2:] == ".1":
                entry = ds.cases[child, var] [0]
                if isinstance(entry, str):
                    entry = entry.strip()
                    if len(entry) == 0:
                        entry = None
                if entry == None:
                    validList = []
                    for t in range(maxDup-1):
                        entry = ds.cases[child, var + t + 1] [0]
                        if isinstance(entry, str):
                            entry = entry.strip()
                            if len(entry) == 0:
                                entry = None
                        if entry != None:
                            validList.append(entry)
                    if validList != []:
                        ds.cases[child, var] = random.choice(validList)
    spss.EndDataStep()

# Rename final variables
    for var in SPSSvariables:
        if (var.upper() not in keyListCaps and var.upper() != primary.upper()):
            submitstring = "rename variables ({0}.1 = {0}).".format(var)
            spss.Submit(submitstring)

# Remove variable duplicates
    submitstring = """match files /file=*
    /keep = """
    for var in SPSSvariables:
        submitstring += "\n" + var
    submitstring += """.
execute."""
    spss.Submit(submitstring)

# Merge resolved duplicates with non duplicates
    submitstring = """dataset activate nodup7663804.
delete variables PrimaryFirst7663804
PrimaryLast7663804
N7663804.
ADD FILES /FILE=*
  /FILE='dup7663804'
.
EXECUTE."""
    spss.Submit(submitstring)

# Rename merged data set to original name
    submitstring = """dataset close dup7663804.
dataset close {0}.
dataset name {0}""".format(activeName)
    spss.Submit(submitstring)

# Sort by key variables
    submitstring = "SORT CASES BY"
    for var in keyList:
        submitstring += "\n" + var + "(A)"
    submitstring += "."
end program python.
