**Bashnapi** is an open project. I accept the pull requests gladly. Please feel
free to contact me if you would like to collaborate or post a patch for this
project.

Rules of thumb:
===============

0. Most importantly, before writing the code, read CodingRules.md.

1. Always fork the *dev* branch (your changes before merged to *master* will be
merged there). *dev* represents current development state of the project and
contains the newest code.

2. Before posting a patch **TEST** it. Perform some manual verification first
and use bashnapi test environment to verify if your delivery didn't brake
anything else.

3. Write tests for your code (refer to test suite's README.md under tests/
subdirectory for more details).

4. Don't duplicate the code. Bash itself is not very well suited for large
projects and this one starts to big (for a shell script). Cross check the
sources before adding new functions.
