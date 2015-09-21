# resolveDuplicates
SPSS Python macro to resolve duplicate cases

This macro is designed to resolve duplicate cases in a data set. It asks you to specify a list of key variables that will be used to identify duplicates, such that rows with the same values on all of the key variables are considered to be duplicates of a single case. You then specify whether you want the primary case to be the first, last, or identified by a variable. Retained values will first be taken from the primary case. If the primary case has a missing value, it will take a non-missing value from one of the other cases, if it is available. If there are multiple alternative non-missing values, then one will be selected randomly.

## Usage 
resolveDuplicates(keyList, primary = "*LAST")
* "keyList" is a list of strings indicating what rows should be considered duplicates of a single case, such that those with the same values on all of the variables in the key list are considered to be duplicates of a single case. In the final version of the data set, there will be a single row for each unique combination of values across the key variables.
* "primary" is a string indicating which cases should be considered the primary rows when determining the values that will be retained in the final data set. Retained values will first be taken from the primary row, and then from other rows for that case if the primary row has a missing value. There should be one primary row for each case. If the value of primary is "*FIRST", the macro will automatically make the first row for each case the primary row. If the value of primary is "*LAST", the macro will automatically make the last row for each case the primary row. If you specify anything else, the macro will assume that you have created your own variable by that name that indicates the primary row for each case. If a primary row is not identified for a case, then that case will not be included in the final data set.

## Example
resolveDuplicates(keyList = ["LastName", "FirstName"],
primary = "*LAST")
* This would consolidate all rows in the data set that had the same lastname and firstname, so that there was only one row in the final data set for each common pair of names. The macro would identify the last row for each last name/first name combination and use that as the primary row. 

