# Functions

Every new function must have a short description header similar to the doxygen
header.

Example:
    #
    # @brief short description of the function's purpose
    #
    # Detailed description (optional)
    #
    # @param (description of the parameter)
    # @return (description of return value)
    #

Don't use bash's _function_ keyword in function declarations. It's completely
unnecessary and may cause portability problems.

## Function names

1. Private functions (not to be used outside) should be prefixed with \_
(underscore).
2. The function name convention for libraries is following:

    [_]<LibraryPrefix_>functionNameInCamelCase[_ReturnValueIndicator]()

Output Indicators:
- `SO` - function returns data through standard output
- `SE` - function return data through standard error
- `GV` - function modifies non-private global variables

Examples:

* A private function from system library returning data through standard output

    _system_PrintSomething_SO

# Variables

If not absolutely necessary, avoid global variables. If shared state is needed
and you need more than one global variable, think about using an array - just
to minimize global namespace pollution.

Usage of global variables in functions is permitted if they belong to the same
module/library. Otherwise - they should be passed as positional arguments.

## Variable names

First of all, variable names should be in *English* only!.

All variables should maintain the `camelCase` naming convention.

Examples:

    myVar=123
    counter=0
    myString="someString"

Global variables should be prefixed with a "g\_" prefix.

All module private global variables should be prefixed with triple \_
(underscore)

All variables that are exported to environment additionally should be ALL CAPS.

    [___][(g|G)_]<variableName|VARIABLENAME>

Examples:

    g_myGlobalVariable
    g_someVar
    g_array=( 1 2 3 )
    ___g_privateVariable
    G_EXPORTEDGLOBALVARIABLE

Illegal (logically incorrect):

    ___G_EXPORTEDVARIABLE

All static string values should be prefixed with a dollar sign $. That's for
translation purposes. Read more about localization in
[BashFAQ](http://mywiki.wooledge.org/BashFAQ/098)

# Indendation

All new files should include the vim formatting auto configuration:

    # vim: ts=4 shiftwidth=4 expandtab

Quick summary:
- Spaces over tabs.
- An indent is 4 spaces wide.
- K&R braces style is preferred.
- No trailing white characteres.
- *Only* UNIX line ends.

# Bash

## Syntax

Check the code with [shellcheck](https://www.shellcheck.net/) whenever
possible, especially if the change is big.
